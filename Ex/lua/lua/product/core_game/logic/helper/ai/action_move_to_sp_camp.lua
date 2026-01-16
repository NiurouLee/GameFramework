require "action_move_base"


_class("ActionMoveToSpCamp", ActionMoveBase)
---@class ActionMoveToSpCamp : ActionMoveBase
ActionMoveToSpCamp = ActionMoveToSpCamp

function ActionMoveToSpCamp:FindNewTargetPos()
    ---@type MonsterCampType
    local campType = self:GetLogicData(-1)
    if campType == nil then
        self:PrintLog("[ActionMoveToSpCamp] Can not find campType,move failed",self.m_entityOwn:GetID())
        return
    end

    local posSelf = self.m_entityOwn:GetGridPosition()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    local fullScreenCalc = SkillScopeCalculator_FullScreen:New(skillCalculater)
    ---@type SkillScopeResult
    local scopeResult =
    fullScreenCalc:CalcRange(
            SkillScopeType.FullScreen,
            1, -- bExcludeSelf
            posSelf,
            self.m_entityOwn:BodyArea():GetArea(),
            self.m_entityOwn:GetGridDirection(),
            nil,
            posSelf
    )
    local nWalkTotal = aiComponent:GetMobilityValid()
    local selfBodyArea = self.m_entityOwn:BodyArea():GetArea()

    ---@type SkillScopeTargetSelector
    local targetSelector = SkillScopeTargetSelector:New(self._world)
    local targetIDArray = targetSelector:DoSelectSkillTarget(self.m_entityOwn, SkillTargetType.SelectMonsterCamp,scopeResult,nil,{campType})

    if #targetIDArray == 0 then
        self:PrintDebugLog("No Camp In Board")
        return posSelf
    end

    ---@type ActionMoveToSpCamp[]
    local candidates = {}
    local lastDistance = 9999
    local targetPos = {}
    for i, id in ipairs(targetIDArray) do
        ---@type Entity
        local entity = self._world:GetEntityByID(id)
        local bodyArea =entity:BodyArea():GetArea()
        local gridPos = entity:GetGridPosition()
        for i, area in ipairs(bodyArea) do
            local posWork = gridPos + area
            local distance = Vector2.Distance(posSelf, posWork)
            if distance < lastDistance then
                lastDistance = distance
                targetPos = posWork
            end
        end
    end
    return targetPos
end

--function ActionMoveToSpCamp:FindNewWalkPos(posWalkList, posTarget, posSelf)
--    return posTarget
--end

