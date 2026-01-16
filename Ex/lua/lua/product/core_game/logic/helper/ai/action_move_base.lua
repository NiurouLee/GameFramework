--[[-------------------------------------
    ActionMoveBase 移动节点基类: 逻辑是先选择移动目标位置，再在自己周围找到行动步点
--]] -------------------------------------
require "ai_node_new"

_class("ActionMoveBase", AINewNode)
---@class ActionMoveBase:AINewNode
ActionMoveBase = ActionMoveBase

function ActionMoveBase:Constructor()
    ---@type Vector2    移动目的地，每走一步，m_nRemainMobility要减1
    self.m_posMoveTarget = nil
    ---@type Vector2
    self.m_posTarget = Vector2.New(0, 0) ---选中的移动目的坐标
end

---@param cfg table
---@param context CustomNodeContext
function ActionMoveBase:InitializeNode(cfg, context, parentNode, configData)
    ActionMoveBase.super.InitializeNode(self, cfg, context, parentNode, configData)
end

function ActionMoveBase:Reset()
    ActionMoveBase.super.Reset(self)
    ---@type SortedArray
    self.m_posTarget = Vector2.New(0, 0)
end

function ActionMoveBase:OnBegin()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    if AIMoveState.MoveEnd == aiCmpt:GetMoveState() then
        self:PrintLog("移动结束等待中")
        return
    end
    if false == aiCmpt:CanMove() then
        aiCmpt:SetMoveState(AIMoveState.MoveEnd)
        self:PrintLog("启动移动<不允许>")
        return
    end
    ---@type TrapComponent
    local trapCmpt = self.m_entityOwn:Trap()
    if trapCmpt then
        aiCmpt:SetMoveState(AIMoveState.MoveEnd)
        self:PrintLog("机关不能以AI移动")
        return
    end

    aiCmpt:SetMoveState(AIMoveState.Moving)
    local targetEntity = aiCmpt:GetTargetEntity()
    if targetEntity and targetEntity:HasGridLocation() then
        local listPosTarget = targetEntity:GetCoverAreaList()
        local targetEntityPosCenter = targetEntity:GridLocation():Center()
        local posSelf = self.m_entityOwn:GetGridPosition()
        self:InitTargetPosList(listPosTarget, targetEntityPosCenter)
    else
        self:PrintLog("没有找到目标")
    end
end

function ActionMoveBase:OnUpdate()
    ---@type Entity
    local entityWork = self.m_entityOwn
    ---@type AIComponentNew
    local aiComponent = entityWork:AI()
    if AIMoveState.MoveEnd == aiComponent:GetMoveState() then
        self:PrintLog("移动结束等待中")
        return AINewNodeStatus.Success
    end
    if false == aiComponent:CanMove() then
        return AINewNodeStatus.Success
    end
    ---角色死亡，直接返回
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        return AINewNodeStatus.Success
    end

    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")

    ---计算可移动到的目标点
    local posWalk = self:_CalcMovePos(entityWork)

    ---@type AIRecorderComponent
    local aiRecorderCmpt = self._world:GetBoardEntity():AIRecorder()
    ---@type MonsterWalkResult
    local walkRes = MonsterWalkResult:New()
    if posWalk ~= nil then
        ---存在可移动的点
        local posSelf = entityWork:GetGridPosition()

        ---保存上一次移动点
        aiComponent:SetLastMovePos(posSelf)

        sBoard:UpdateEntityBlockFlag(entityWork, posSelf, posWalk)
        entityWork:SetGridPosition(posWalk)
        entityWork:SetGridDirection(posWalk - posSelf)

        local entityID = entityWork:GetID()

        walkRes:SetWalkPos(posWalk)
        aiRecorderCmpt:AddWalkResult(entityID, walkRes)
        ---处理到达一个格子的处理
        self:_OnArrivePos(walkRes)

        self._world:GetSyncLogger():Trace(
            {
                key = "AIMove",
                aiNode = self._className,
                entityID = entityWork:GetID(),
                fromTo = tostring(posSelf) .. "->" .. tostring(posWalk),
                target = tostring(self.m_posTarget)
            }
        )

        self:PrintLog(
            "移动位置 " .. self:_MakePosString(posSelf) .. "=>",
            self:_MakePosString(posWalk),
            ", 选择目标",
            self:_MakePosString(self.m_posTarget)
        )
        self:PrintDebugLog("移动位置 " .. self:_MakePosString(posSelf) .. "=>",
            self:_MakePosString(posWalk),
            ", 选择目标",
            self:_MakePosString(self.m_posTarget))
    end

    local nMobilityToalRemain = aiComponent:GetMobilityValid()

    if AINewNode.IsEntityDead(self.m_entityOwn) then
        aiComponent:SetMoveState(AIMoveState.MoveEnd)
        return AINewNodeStatus.Success
    else
        if nMobilityToalRemain > 1 then
            return AINewNodeStatus.Failure
        else
            aiComponent:SetMoveState(AIMoveState.MoveEnd)
            return AINewNodeStatus.Success
        end
    end
end

---计算本次要移动到的目标位置
---@param entityWork Entity
function ActionMoveBase:_CalcMovePos(entityWork)
    ---@type AIComponentNew
    local aiComponent = entityWork:AI()
    local posSelf = entityWork:GridLocation().Position

    ---找到距离自己最远的移动目标格子
    local posTarget = self:FindNewTargetPos()
    self.m_posTarget = posTarget

    ---已经到目标点了
    if posSelf == posTarget then
        self:PrintLog("不需要移动，当前就是目标坐标", self:_MakePosString(posSelf))
        self:PrintDebugLog("不需要移动，当前就是目标坐标", self:_MakePosString(posSelf))
        return nil
    end

    --找到最近的可停留的攻击格子 *此处如果所有攻击格子都不可用 则直接返回目标位置
    local nWalkTotal = aiComponent:GetMobilityValid()
    local posWalkList = self:ComputeWalkRange(posSelf, nWalkTotal, true)
    local posWalk = self:FindNewWalkPos(posWalkList, posTarget, posSelf)
    ---最近可移动点是自己的位置，不需要移动
    if posWalk and posWalk == posSelf then
        self:PrintLog("不需要移动 ", self:_MakePosString(posSelf), ">===>", self:_MakePosString(posWalk))
        self:PrintDebugLog("不需要移动 ", self:_MakePosString(posSelf), ">===>", self:_MakePosString(posWalk))
        return nil
    end
    self:PrintDebugLog("移动到",self:_MakePosString(posWalk))
    return posWalk
end

function ActionMoveBase:OnEnd()
end

--------------------------------
---返回使用nSkillID能打到posCenter的所有坐标点
---@param nSkillID number    注意这里的排序函数，不同需求应当不同
---@param posCenter Vector2
function ActionMoveBase:_ComputeSkillRange(nSkillID, posCenter, bodyArea, dir)
    if nSkillID == 0 then
        return {}
    end
    --在目标的周围查找
    local workCenter = posCenter
    --多格怪要求把目标坐标移动到多格的左下角：posCenter被作为右上角坐标计算
    if 4 == #bodyArea then
        workCenter = workCenter + Vector2(-1, -1)
    elseif 9 == #bodyArea then
        workCenter = workCenter + Vector2(-2, -2)
    end
    return self:CalculateSkillRange(nSkillID, workCenter, dir, bodyArea)
end

-------------------------------------派生类可能要实现的三个函数--------------------------------
---初始化战略目标候选列表： ActionMoveBase 默认的排序规则是：距离自己最近的攻击位置排在最前面
---@param listPosTarget Vector2[]
function ActionMoveBase:InitTargetPosList(listPosTarget)
end

---返回目标位置
function ActionMoveBase:FindNewTargetPos()
    local posDefault = self.m_entityOwn:GetGridPosition()
    return posDefault
end

---查找战术行动坐标：返回距离战略目标最近的点，找不到会返回自己的位置（不移动）
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
function ActionMoveBase:FindNewWalkPos(walkRange, posCenter, posDef)
    return self:FindPosByNearCenter(walkRange, posCenter, posDef, 1)
end

---查找距离圆心最近的位置
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
---@param posDef Vector2 默认的返回值
function ActionMoveBase:FindPosByNearCenter(listPlanPos, posCenter, posDef, nCheckStep)
    if nil == listPlanPos or table.count(listPlanPos) <= 0 then
        return posDef
    end
    local listWalk = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    listWalk:AllowDuplicate()
    ---2019-12-09 策划需求：所有怪都要移动起来
    ---AINewNode.InsertSortedArray(listWalk, posTarget, posDef, 0);

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local lastMovePos = aiCmpt:GetLastMovePos()

    for i = 1, #listPlanPos do
        ---@type ComputeWalkPos
        local posData = listPlanPos[i]
        local posWalk = posData:GetPos()
        if posWalk ~= posDef and (nil == nCheckStep or nCheckStep == posData:GetStep()) then
            if posWalk ~= lastMovePos then
                AINewNode.InsertSortedArray(listWalk, posCenter, posWalk, i)
            else
                --Log.fatal("this pos is last move pos:",posWalk)
            end
        end
    end
    return self:FindPosValid(listWalk, posDef)
end

--------------------------------
---@param walkRes MonsterWalkResult
function ActionMoveBase:_OnArrivePos(walkRes)
    ---@type MainWorld
    local world = self.m_entityOwn:GetOwnerWorld()

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = world:GetService("TrapLogic")
    local pos = self.m_entityOwn:GetGridPosition()

    ---触发并播放机关技能：服务器端不播放
    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(self.m_entityOwn, TrapTriggerOrigin.Move)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)

        local scopeRes = skillEffectResultContainer:GetScopeResult()
        Log.debug(
            "[AIMove] OnArrivePos() monster=",
            self.m_entityOwn:GetID(),
            " pos=",
            pos,
            " trigger trapid=",
            trapEntity:GetID(),
            " defender=",
            scopeRes:GetTargetIDs()[1]
        )
        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    local nTrapCount = table.count(listTrapWork)

    --本次移动经过的格子
    local passGrids = {}
    local bodyArea = self.m_entityOwn:BodyArea():GetArea()
    local dir = self.m_entityOwn:GridLocation():GetGridDir()
    local curPos = self.m_entityOwn:GetGridPosition()
    for _, value in ipairs(bodyArea) do
        local pos = curPos + value - dir
        if not table.Vector2Include(passGrids,pos) then
            passGrids[#passGrids + 1] = pos
        end
    end
    local nt = NTMonsterMoveOneFinish:New(self.m_entityOwn, passGrids, walkRes:GetWalkPos(), curPos)
    world:GetService("Trigger"):Notify(nt)

    ---传给表现用，这个参数，逻辑侧如果改了，表现可就播不出来了
    walkRes:SetWalkPassedGrid(passGrids)
end

function ActionMoveBase:isDuplicate(pos,passGrids)
    for _, value in ipairs(passGrids) do
        if value.x == pos.x and value.y == pos.y then
            return true
        end
    end
    return false
end