--[[
    改变星灵连锁技能
]]
--region ChangePetChainSkillCondition
ChangePetChainSkillCondition = {
    None = 0, --无条件
    TargetInScope = 1, --目标是否在范围内
    BySkillID = 2, --根据技能ID
    San = 3 --San值
}
--endregion

---@class BuffLogicChangePetChainSkill:BuffLogicBase
_class("BuffLogicChangePetChainSkill", BuffLogicBase)
BuffLogicChangePetChainSkill = BuffLogicChangePetChainSkill

---@param buffInstance BuffInstance
function BuffLogicChangePetChainSkill:Constructor(buffInstance, logicParam)
    self._skillId = logicParam.skillId
    self._type = logicParam.type
    self._param = logicParam.param
    self._key = logicParam.key
    self._light = logicParam.light or 0 --表现 星灵头像的灯
end
---@param notify INotifyBase
function BuffLogicChangePetChainSkill:DoLogic(notify)
    local e = self._buffInstance:Entity()
    local cSkillInfo = e:SkillInfo()
    if not cSkillInfo then
        return
    end
    ---@type ChainSkillIDSelector
    local chainSkillIDSelector = cSkillInfo:GetChainSkillIDSelector()
    if self._type == ChangePetChainSkillCondition.TargetInScope then
        local rule = chainSkillIDSelector:GetRule()
        local newRule = table_to_class(rule)
        if not self:IsConditionSatisfyTargetInScope(e, notify:GetChainCount()) then
            newRule[1].Skill = self._skillId
        end
        chainSkillIDSelector:AddRule(self._key, newRule)
    elseif self._type == ChangePetChainSkillCondition.BySkillID then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        local rule = chainSkillIDSelector:GetRule()
        local newRule = table_to_class(rule)
        for i, v in ipairs(newRule) do
            local newSkillID = self._param[v.Skill]
            if newSkillID then
                v.Skill = newSkillID
                ---@type SkillConfigData
                local skillConfigData = configService:GetSkillConfigData(newSkillID)
                v.Chain = skillConfigData:GetSkillTriggerParam()
            end
        end
        chainSkillIDSelector:AddRule(self._key, newRule)
    elseif self._type == ChangePetChainSkillCondition.San then
        ---@type FeatureServiceLogic
        local featureLogicSvc = self._world:GetService("FeatureLogic")
        if not featureLogicSvc then
            return
        end
        if not featureLogicSvc:HasFeatureType(FeatureType.Sanity) then
            return
        end

        local skillList = {}
        for k, v in pairs(self._param) do --不能改ipairs
            local skill = {}
            skill.chainCount = k
            skill.skill = v
            table.insert(skillList, skill)
        end

        table.sort(
            skillList,
            function(e1, e2)
                return e1.chainCount < e2.chainCount
            end
        )

        local curSanValue = featureLogicSvc:GetSanValue()
        local newSkillList = {}
        for i, v in pairs(skillList) do
            if curSanValue < v.chainCount then
                newSkillList = v.skill
                break
            end
        end

        local rule = chainSkillIDSelector:GetRule()
        local newRule = table_to_class(rule)
        for i, v in ipairs(newRule) do
            local newSkillID = newSkillList[i]
            if newSkillID then
                v.Skill = newSkillID
            end
        end
        chainSkillIDSelector:AddRule(self._key, newRule)
    end

    local ret = BuffResultChangePetChainSkill:New(self._light)
    return ret
end

---@param e Entity
function BuffLogicChangePetChainSkill:IsConditionSatisfyTargetInScope(e, chainCount)
    ---@type Entity
    local teamEntiy = e:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntiy:LogicChainPath()
    local chainPosList = logicChainPathCmpt:GetLogicChainPath()

    local cSkillInfo = e:SkillInfo()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local chainExtraFix = utilData:GetEntityBuffValue(e, "ChangeExtraChainSkillReleaseFixForSkill")
    local chainSkillIdConfig = cSkillInfo:GetChainSkillConfigID(chainCount, chainExtraFix) --拿配置的连锁id
    if chainSkillIdConfig <= 0 then --未触发连锁
        return false
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local sConfig = self._world:GetService("Config")
    local skillConfigData = sConfig:GetSkillConfigData(chainSkillIdConfig)
    local targetType = skillConfigData:GetSkillTargetType()

    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, chainPosList[#chainPosList], e, Vector2(0, 1))
    local targetIDList = utilScopeSvc:SelectSkillTarget(e, targetType, scopeResult)
    if targetIDList and table.count(targetIDList) > 0 then
        return true
    end
    return false
end

---------------------------------------------------

---@class BuffLogicChangePetChainSkillUndo:BuffLogicBase
_class("BuffLogicChangePetChainSkillUndo", BuffLogicBase)
BuffLogicChangePetChainSkillUndo = BuffLogicChangePetChainSkillUndo

function BuffLogicChangePetChainSkillUndo:Constructor(buffInstance, logicParam)
    self._key = logicParam.key
    self._black = logicParam.black or 0
end

function BuffLogicChangePetChainSkillUndo:DoLogic()
    local e = self._buffInstance:Entity()
    local cSkillInfo = e:SkillInfo()
    ---@type ChainSkillIDSelector
    local chainSkillIDSelector = cSkillInfo:GetChainSkillIDSelector()
    chainSkillIDSelector:RemoveRule(self._key)

    local ret = BuffResultChangePetChainSkillUndo:New(self._black)
    return ret
end
