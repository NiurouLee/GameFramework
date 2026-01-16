--[[------------------------------------------------------------------------------------------
    L2R_ChainAttackResult : 连锁技播放使用的结果数据
]] --------------------------------------------------------------------------------------------

---@class L2R_ChainAttackResult: Object
_class("L2R_ChainAttackResult", Object)
L2R_ChainAttackResult = L2R_ChainAttackResult

function L2R_ChainAttackResult:Constructor(dataList)
    ---所有宝宝本体连锁技的攻击结果，key是EntityID,value是数组DataChainAttackResult
    self._chainAtkResultList = dataList
end

function L2R_ChainAttackResult:GetPetChainSkillDataList(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return nil
    end

    return chainResData:GetChainAttackResultAtkDataList()
end

function L2R_ChainAttackResult:GetPetShadowChainSkillDataList(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return nil
    end

    return chainResData:GetChainAttackResultShadowAtkDataList()
end

function L2R_ChainAttackResult:GetPetAgentChainSkillDataList(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return nil
    end

    return chainResData:GetChainAttackResultAgentAtkDataList()
end

function L2R_ChainAttackResult:GetPetHasCastChainSkill(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return false
    end
    return chainResData:GetChainAttackResultCastSkillFlag()
end

function L2R_ChainAttackResult:GetPetCastChainSkillID(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return -1
    end

    return chainResData:GetChainAttackResultSkillID()
end

function L2R_ChainAttackResult:ChainAttackResultHasDamage(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return false
    end

    local effectResList = chainResData:GetChainAttackResultAtkDataList()
    for i, v in ipairs(effectResList) do
        ---@type SkillChainAttackData
        local chainAttackData = v
        if chainAttackData:GetEffectResultByArray(SkillEffectType.Damage) then
            return true
        end
    end
    return false
end

function L2R_ChainAttackResult:GetDeadEntityIDListByPet(entityID)
    ---@type DataChainAttackResult
    local chainResData = self._chainAtkResultList[entityID]
    if chainResData == nil then
        return nil
    end
    return chainResData:GetDeadEntityIDList()
end

function L2R_ChainAttackResult:GetChainTeamResult()
    return self._chainTeamResult
end

function L2R_ChainAttackResult:SetChainTeamResult(team)
    self._chainTeamResult = team
end
