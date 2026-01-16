--[[-------------------------------------
    ActionIsEntityInTargetRange 目标范围内是否存在指定实体（机关或怪物）
--]] -------------------------------------
require "ai_node_new"

---@class ActionIsEntityInTargetRange : AINewNode
_class("ActionIsEntityInTargetRange", AINewNode)
ActionIsEntityInTargetRange = ActionIsEntityInTargetRange

function ActionIsEntityInTargetRange:OnBegin()
    --指定的机关ID
    self._trapID = self:GetLogicData(-1)
    --指定的怪物Class ID
    self._monsterClassID = self:GetLogicData(-2)

    --目标类型及范围相关
    self._targetType = self:GetLogicData(-3)
    self._targetTypeParam = self:GetLogicData(-4)
    self._scopeCenterType = self:GetLogicData(-5)
    self._scopeType = self:GetLogicData(-6)
    self._scopeTypeParam = self:GetLogicData(-7)
end

function ActionIsEntityInTargetRange:OnUpdate()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local petEntity = aiComponent:GetTargetEntity()
    local petDir = petEntity:GridLocation():GetGridDir()
    local petBodyArea = petEntity:BodyArea():GetArea()
    local petPos = petEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()
    local centerPos, bodyArea = skillCalc._gridFilter:CalcCenterPosAndBodyArea(self._scopeCenterType, petPos,
        petBodyArea, self._scopeTypeParam)
    ---@type SkillScopeResult
    local skillScopeResult = skillCalc:ComputeScopeRange(self._scopeType, self._scopeTypeParam, centerPos,
        bodyArea, petDir, self._targetType, petPos, petEntity)
    --先选目标
    local targetEntityIDList = utilScopeSvc:SelectSkillTarget(self.m_entityOwn, self._targetType, skillScopeResult,
        nil, self._targetTypeParam)


    local trapEntityIDs = {}
    for _, entityID in ipairs(targetEntityIDList) do
        ---@type Entity
        local entity = self._world:GetEntityByID(entityID)

        --查找技能目标中是否存在指定的机关
        if entity:HasTrapID() and entity:TrapID():GetTrapID() == self._trapID then
            table.insert(trapEntityIDs, entity:GetID())
            --检查骑乘状态
            if entity:HasRide() and entity:Ride():GetRiderID() == self.m_entityOwn:GetID() then
                return AINewNodeStatus.Other + AIEntityInTargetRangeType.RideOnTrapInRange
            end
        end

        --查找技能目标中是否存在指定怪物
        if entity:HasMonsterID() and entity:MonsterID():GetMonsterClassID() == self._monsterClassID then
            --检查骑乘状态
            if entity:HasRide() and entity:Ride():GetRiderID() == self.m_entityOwn:GetID() then
                return AINewNodeStatus.Other + AIEntityInTargetRangeType.RideOnMonsterInRange
            end
        end
    end

    if #trapEntityIDs > 0 then
        return AINewNodeStatus.Other + AIEntityInTargetRangeType.NoRideInRange
    end

    return AINewNodeStatus.Other + AIEntityInTargetRangeType.NotInRange
end
