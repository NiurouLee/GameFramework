--[[
    ModifyBuffValue = 77, --修改某target身上某buff的某value
]]
---@class SkillEffectCalc_ModifyBuffValue: Object
_class("SkillEffectCalc_ModifyBuffValue", Object)
SkillEffectCalc_ModifyBuffValue = SkillEffectCalc_ModifyBuffValue

function SkillEffectCalc_ModifyBuffValue:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ModifyBuffValue:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ModifyBuffValue:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    if skillEffectCalcParam.skillEffectParam:NeedKill() then
        local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
        ---@type SkillDamageEffectResult
        local skillResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
        local haveDeath = false
        local listTargetHp = {}
        if skillResultArray then
            for k, res in ipairs(skillResultArray) do
                local targetEntityID = res:GetTargetID()
                if targetEntityID > 0 then
                    local nCurHp = listTargetHp[targetEntityID]
                    if nil == nCurHp then
                        local targetEntity = self._world:GetEntityByID(targetEntityID)
                        if targetEntity:HasMonsterID() then
                            local nCurHp = targetEntity:Attributes():GetCurrentHP() ---获取的是逻辑层的值
                            listTargetHp[targetEntityID] = nCurHp
                            if nCurHp <= 0 then
                                haveDeath = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if haveDeath then
            return self:_ModifyBuffValue(skillEffectCalcParam, targetID)
        end
    else
        return self:_ModifyBuffValue(skillEffectCalcParam, targetID)
    end
end

function SkillEffectCalc_ModifyBuffValue:_ModifyBuffValue(skillEffectCalcParam, targetID)
    local buffID = skillEffectCalcParam.skillEffectParam:GetBuffID()
    if type(buffID) ~= "number" then
        return
    end
    local addValue = skillEffectCalcParam.skillEffectParam:GetAddValue()
    local certainValue = skillEffectCalcParam.skillEffectParam:GetCertainValue()
    if type(addValue) == "number" then
        local valueName = skillEffectCalcParam.skillEffectParam:GetValueName()

        local entityTarget = self._world:GetEntityByID(targetID)
        if entityTarget == nil then
            return
        end
        local buffCmp = entityTarget:BuffComponent()
        local buffInstance = buffCmp:GetBuffById(buffID)
        if buffInstance == nil then
            return
        end
        buffInstance:AddLayerCount(addValue)
        local layer = buffInstance:GetLayerCount()
        return SkillModifyBuffValueResult:New(targetID, buffInstance:BuffSeq(), layer)
    end

    if type(certainValue) == "number" then
        local valueName = skillEffectCalcParam.skillEffectParam:GetValueName()

        local entityTarget = self._world:GetEntityByID(targetID)
        local buffCmp = entityTarget:BuffComponent()
        local buffInstance = buffCmp:GetBuffById(buffID)
        if not buffInstance then
            return
        end
        buffInstance:SetLayerCount(certainValue)
        local layer = buffInstance:GetLayerCount()
        return SkillModifyBuffValueResult:New(targetID, buffInstance:BuffSeq(), layer)
    end
end
