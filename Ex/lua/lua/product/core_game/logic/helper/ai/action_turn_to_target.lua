--[[-------------------------------------------
    ActionTurnToTarget 转向目标方向
    2020-07-18 增加转向非玩家方向
--]] -------------------------------------------
require "ai_node_new"
---@class ActionTurnToTarget:AINewNode
_class("ActionTurnToTarget", AINewNode)
ActionTurnToTarget = ActionTurnToTarget


function ActionTurnToTarget:OnBegin()
    local nTargetType = self:GetLogicData(-1)
    self:TurnToTarget(self._world, self.m_entityOwn, nTargetType)
end

---@param entityWork Entity
function ActionTurnToTarget:TurnToTarget(world, entityWork, nTargetType)
    ---@type AIComponentNew
    local aiComponent = entityWork:AI()
    if false == aiComponent:CanTurn() then
        self:PrintLog("转向: 转向玩家方向<不允许>")
        self:PrintDebugLog("转向: 转向<不允许>")
        return
    end

    ---@type Entity
    local targetEntity = nil
    if nTargetType and nTargetType > 0 then
        local nSkillID = self:GetLogicData(1)
        if nSkillID == 0 then
            self:PrintLog("转向: 转向使用的技能ID为0<不允许>")
            return
        end
        targetEntity = self:_GetTargetPosBySkillID(world, entityWork, nSkillID)
    else
        targetEntity = aiComponent:GetTargetEntity()
    end
    if not targetEntity or not entityWork:HasBodyArea() then
        self:PrintLog("转向: 转向玩家方向<允许>，目标没有BodyArea")
        self:PrintDebugLog("转向: 转向玩家方向<允许>，目标没有BodyArea")
        return
    end
    self:PrintLog("转向: 转向玩家方向<允许>")

    local posSelf = entityWork:GetGridPosition()
    local posTarget = self:_GetAITargetDamageCenter(targetEntity)
    local posDir = GameHelper.ComputeLogicDir(posTarget - posSelf)
    local nBodyAreaCount = entityWork:BodyArea():GetAreaCount()
    if 1 ~= nBodyAreaCount then
        posDir = self:GetDir(posTarget, entityWork)
    else
        ---先蛇这个怪物需要使用与坐标轴对齐的朝向
        local useAlign = self:GetLogicData("alignAxis")
        if useAlign == true then
            local attackPos = self:GetNeareastPos(targetEntity, entityWork)
            posDir = self:GetDir(attackPos, entityWork)
        end
    end
    self:PrintDebugLog("转向: <允许>，我的位置 = ",posSelf," 目标ID = ",targetEntity:GetID()," 目标位置=",posTarget," 转向方向：",posDir)
    entityWork:SetGridDirection(posDir)
    -- entityWork:SetDirection(posDir)
end

---获取距离entitywork最近的一个格子，只考虑entitywork是个单格怪的情况。
---需要处理多格的话，需要扩展
---@param targetEntity Entity 目标
---@param entityWork Entity 自己
function ActionTurnToTarget:GetNeareastPos(targetEntity, entityWork)
    ---@type GridLocationComponent
    local selfGridLocCmpt = entityWork:GridLocation()
    local selfPos = selfGridLocCmpt:GetGridPos()

    ---目标的中心点
    local posTarget = self:_GetAITargetDamageCenter(targetEntity)
    ---@type BodyAreaComponent
    local targetBodyAreaCmpt = targetEntity:BodyArea()
    ---目标是否是多格怪
    local targetAreaCount = targetBodyAreaCmpt:GetAreaCount()
    if targetAreaCount > 1 then
        local bodyAreaList = targetBodyAreaCmpt:GetArea()
        ---@type GridLocationComponent
        local gridLocCmpt = targetEntity:GridLocation()
        ---原点
        local gridPos = gridLocCmpt:GetGridPos()

        ---选择的最近点
        local neareastBodyPos = posTarget
        local curNearestDis = 100
        for _, bodyArea in ipairs(bodyAreaList) do
            local bodyPos = gridPos + bodyArea
            local distance = Vector2.Distance(bodyPos, selfPos)
            if distance < curNearestDis then
                curNearestDis = distance
                neareastBodyPos = bodyPos
            end
        end

        ---重置目标点
        posTarget = neareastBodyPos
    end
    --Log.fatal("targetPos is--------- ",posTarget,"---myPos:",selfPos)
    return posTarget
end

---@param entity Entity
function ActionTurnToTarget:GetDir(targetPos, entity)
    local gridLoc = entity:GridLocation()
    local center = gridLoc:Center()
    local vectors = {Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)}
    local minIdx, minAngle = 1, 180
    local vec = targetPos - center
    for i, v in ipairs(vectors) do
        local angle = Vector2.Angle(vec, v)
        if minAngle > angle then
            minAngle = angle
            minIdx = i
        end
    end
    return vectors[minIdx]
end
---@param world MainWorld
---@param castEntity Entity
function ActionTurnToTarget:_GetTargetPosBySkillID(world, castEntity, nSkillID)
    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(nSkillID)
    local targetType = skillConfigData:GetSkillTargetType()

    local casterPos = castEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, castEntity)

    local targetSelector = world:GetSkillScopeTargetSelector()
    local targetEntityIDArray = targetSelector:DoSelectSkillTarget(castEntity, targetType, scopeResult, nSkillID)
    if table.count(targetEntityIDArray) <= 0 then
        return nil
    end
    local nTargetID = targetEntityIDArray[1] ---只取第一目标
    return world:GetEntityByID(nTargetID)
end

---AI比较特殊，这里先单独拿出来算
---@param targetEntity Entity
function ActionTurnToTarget:_GetAITargetDamageCenter(targetEntity)
    ---@type GridLocationComponent
    local gridCmpt = targetEntity:GridLocation()
    if gridCmpt == nil then
        return
    end

    local gridPos = gridCmpt:GetGridPos()

    local posReturn = nil

    ---偏移量
    local posOffSet = gridCmpt:GetDamageOffset()
    posReturn = gridPos + posOffSet

    return posReturn
end
