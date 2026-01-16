--[[-------------------------------------
    ActionMove_HitBack 往能击飞目标(判断三点一线)的地点移动
    2020-07-03 韩玉信 击飞小怪使用的移动AI
--]] -------------------------------------
require "action_move_base"
---@class ActionMove_HitBack:ActionMoveBase
_class("ActionMove_HitBack", ActionMoveBase)
ActionMove_HitBack = ActionMove_HitBack

--------------------------------
function ActionMove_HitBack:Constructor()
    self:_Reset()
end
function ActionMove_HitBack:Reset()
    ActionMove_HitBack.super.Reset(self)
    self:_Reset()
end
function ActionMove_HitBack:_Reset()
    self.m_listPos_BombToPlayer = nil ---绑定炸弹周边的“有效”位置：把炸弹击退到玩家
    self.m_listPos_PlayerToBomb = nil ---把玩家击退到任意一个炸弹上的“有效”位置
    self.m_listPos_HitPlayer = nil ---移动到玩家周围的可选位置：无论是否有“有效”位置，都会击飞玩家
    self.m_listPos_MoveToPlayer = nil ---移动到玩家周围的可选位置
    self.m_listPos_MoveToBomb = nil ---移动到炸弹周围的可选位置
end
function ActionMove_HitBack:OnBegin()
    ---@type Entity
    local entityCaster = self.m_entityOwn
    ---@type AIComponentNew
    local aiCmpt = entityCaster:AI()
    if false == aiCmpt:CanMove() then
        self:PrintLog("启动移动<不允许>")
        return
    end
    local targetEntity = aiCmpt:GetTargetEntity()
    if targetEntity and targetEntity:HasGridLocation() then

        local nSkillID = self:GetLogicData(1)
        if nSkillID == 0 then
            return
        end
        local posSelf = entityCaster:GetGridPosition()
        local selfBodyArea = entityCaster:BodyArea():GetArea()
        local nValidMobility = aiCmpt:GetMobilityValid()
        ---@type ComputeWalkPos[]
        local listWalkRange = self:ComputeWalkRange(posSelf, nValidMobility, true) ---这里的行动范围是不包含体型数据的
        ---@type Entity
        local entityPlayer = aiCmpt:GetTargetDefault()
        local posPlayer = entityPlayer:GetGridPosition()
        local posTarget = aiCmpt:GetTargetPos()
        ---击飞炸弹到玩家
        if targetEntity ~= entityPlayer then
            self.m_listPos_BombToPlayer =
                self:_InitBestPos_BombToPlayer(listWalkRange, selfBodyArea, nSkillID, posPlayer, posTarget)
            self.m_listPos_MoveToBomb = self:_InitBestPos_Target(selfBodyArea, nSkillID, posTarget)
        end
        self.m_listPos_PlayerToBomb = self:_InitBestPos_PlayerToBomb(listWalkRange, selfBodyArea, nSkillID, posPlayer)
        self.m_listPos_HitPlayer = self:_InitBestPos_HitPlayer(listWalkRange, selfBodyArea, nSkillID, posPlayer)
        self.m_listPos_MoveToPlayer = self:_InitBestPos_Target(selfBodyArea, nSkillID, posPlayer)
    else
        self:PrintLog("没有找到目标")
    end
end
--------------------------------    ---派生类可能要实现的三个函数
---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMove_HitBack:FindNewTargetPos()
    local entityOwn = self.m_entityOwn
    local posSelf = entityOwn:GetGridPosition()
    ---@type AIComponentNew
    local aiCmpt = entityOwn:AI()
    local posFind = nil
    posFind = self:FindPosByNearCenter(self.m_listPos_BombToPlayer, posSelf, nil, nil)
    if posFind then
        self:PrintLog("击退炸弹到玩家" ,self:_MakePosString(posFind))
        return posFind
    end
    posFind = self:FindPosByNearCenter(self.m_listPos_PlayerToBomb, posSelf, nil, nil)
    if posFind then
        self:PrintLog("击退玩家到炸弹" ,self:_MakePosString(posFind))
        return posFind
    end
    posFind = self:FindPosByNearCenter(self.m_listPos_HitPlayer, posSelf, nil, nil)
    if posFind then
        self:PrintLog("击退玩家" ,self:_MakePosString(posFind))
        return posFind
    end
    posFind = self:FindPosByNearCenter(self.m_listPos_MoveToPlayer, posSelf, nil, nil)
    if posFind then
        self:PrintLog("移动到玩家" ,self:_MakePosString(posFind))
        return posFind
    end
    posFind = self:FindPosByNearCenter(self.m_listPos_MoveToBomb, posSelf, nil, nil)
    if posFind then
        self:PrintLog("移动到炸弹" ,self:_MakePosString(posFind))
        return posFind
    end
    local posTarget = aiCmpt:GetTargetPos()
    return posTarget
end
--------------------------------
---@return ComputeWalkPos
function ActionMove_HitBack:_FindWalkPosData(listWalkRange, posBaseWalk)
    ---@param value ComputeWalkPos
    for key, value in ipairs(listWalkRange) do
        if value.m_nPos == posBaseWalk then
            return value
        end
    end
    return nil
end
---查找从撞击点周围4格子（必须本次移动可达）是否有能跟目标点同一条线的点
function ActionMove_HitBack:_FindHitStartPos(listWalkRange, listBodyArea, nSkillID, posHit, listTargetPos)
    -- local listWalkPlan = SortedArray:New(Algorithm.COMPARE_CUSTOM, PosSortByDir._ComparerByDir)
    local listPosPlan = {}
    local listPosAttack = self:_ComputeSkillRange(nSkillID, posHit, listBodyArea)
    for _, posBaseWalk in ipairs(listPosAttack) do
        for j, posTarget in ipairs(listTargetPos) do ---
            for i = 1, #listBodyArea do ---多个怪
                local posWork = posBaseWalk + listBodyArea[i]
                if posWork.x == posHit.x or posWork.y == posHit.y then ---四方向校验
                    if self:_IsOneLine(posWork, posHit, posTarget) then
                        local posDataWalk = self:_FindWalkPosData(listWalkRange, posBaseWalk)
                        if posDataWalk then
                            table.insert(listPosPlan, posDataWalk)
                        end
                    end
                    break
                end
            end
        end
    end
    return listPosPlan
end
---把炸弹击退到玩家时： 查找最优
function ActionMove_HitBack:_InitBestPos_BombToPlayer(listWalkRange, selfBodyArea, nSkillID, posPlayer, posBomb)
    return self:_FindHitStartPos(listWalkRange, selfBodyArea, nSkillID, posBomb, {posPlayer})
end
---把玩家击退到炸弹时： 查找最优
function ActionMove_HitBack:_InitBestPos_PlayerToBomb(listWalkRange, selfBodyArea, nSkillID, posPlayer)
    ---@type TrapServiceLogic
    local utilSvc = self._world:GetService("TrapLogic")
    local listBomb = utilSvc:FindTrapByType(TrapType.BombByHitBack)
    local listBombPos = {}
    for i = 1, #listBomb do
        local posBomb = listBomb[i]:GetGridPosition()
        table.insert(listBombPos, posBomb)
    end
    return self:_FindHitStartPos(listWalkRange, selfBodyArea, nSkillID, posPlayer, listBombPos)
end
function ActionMove_HitBack:_InitBestPos_HitPlayer(listWalkRange, listBodyArea, nSkillID, posPlayer)
    local listPosPlan = {}
    local listPosAttack = self:_ComputeSkillRange(nSkillID, posPlayer, listBodyArea)
    for _, posBaseWalk in ipairs(listPosAttack) do
        local posDataWalk = self:_FindWalkPosData(listWalkRange, posBaseWalk)
        if posDataWalk then
            table.insert(listPosPlan, posDataWalk)
        end
    end
    return listPosPlan
end
function ActionMove_HitBack:_InitBestPos_Target(listBodyArea, nSkillID, posTarget)
    local listPosPlan = {}
    local listPosAttack = self:_ComputeSkillRange(nSkillID, posTarget, listBodyArea)
    for _, posBaseWalk in ipairs(listPosAttack) do
        local posData = ComputeWalkPos:New(posBaseWalk, 1)
        table.insert(listPosPlan, posData)
    end
    return listPosPlan
end
--------------------------------
---按照方向排序： 使用点积降序
_class("PosSortByDir", Object)
---@class PosSortByDir : Object
PosSortByDir = PosSortByDir
function PosSortByDir:Constructor(posBase, posTarget, posWork, nIndex)
    ---要把所有的坐标都变更成posBase为圆心的坐标系内的坐标
    self.m_dirBase = self.ComputeDir_Normalize(posTarget, posBase)
    self.m_dirWork = self.ComputeDir_Normalize(posBase, posWork)
    self.m_angle = self.ComputeAngle(self.m_dirBase, self.m_dirWork)
    self.m_posWork = posWork
    self.m_nIndex = nIndex
end
---求方向： 非单位向量
function PosSortByDir.ComputeDir_Normalize(posA, posB)
    ---@type Vector2
    local posDir = posA - posB
    return posDir.normalized
end
function PosSortByDir.ComputeAngle(dirA, dirB)
    return dirA.x * dirB.x + dirA.y * dirB.y
end
function PosSortByDir:GetPosWork()
    return self.m_posWork
end
---@param dataNew PosSortByDir
---@param dataOld PosSortByDir
PosSortByDir._ComparerByDir = function(dataA, dataB)
    local nDistanceA = dataA.m_angle
    local nDistanceB = dataB.m_angle
    if nDistanceA > nDistanceB then
        return 1
    elseif nDistanceA < nDistanceB then
        return -1
    else ---m_nIndex小的在前面
        return dataB.m_nIndex - dataA.m_nIndex
    end
end
