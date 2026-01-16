--[[------------------------------------------------------------------------------------------
    DataChainAttackResult : 连锁技攻击结果
]] --------------------------------------------------------------------------------------------

_class("DataChainAttackResult", Object)
---@class DataChainAttackResult: Object
DataChainAttackResult = DataChainAttackResult

function DataChainAttackResult:Constructor()
    self._chainSkillID = -1

    ---@type SkillChainAttackData[]
    self._attackDataList = {}

    ---@type SkillChainAttackData[]
    self._shadowAtkDataList = {}

    ---@type SkillChainAttackData[]
    self._agentAtkDataList = {}

    self._hasCastSkill = false

    self._deadEntityIDList = {}
end

function DataChainAttackResult:SetChainAttackResultSkillID(skillID)
    self._chainSkillID = skillID
end

function DataChainAttackResult:SetChainAttackResultAtkDataList(dataList)
    self._attackDataList = dataList
end

function DataChainAttackResult:SetChainAttackResultShadowAtkDataList(dataList)
    self._shadowAtkDataList = dataList
end

function DataChainAttackResult:SetChainAttackResultAgentAtkDataList(dataList)
    self._agentAtkDataList = dataList
end

function DataChainAttackResult:SetChainAttackResultCastSkillFlag(flag)
    self._hasCastSkill = flag
end

function DataChainAttackResult:SetDeadEntityIDList(ids)
    self._deadEntityIDList = ids
end

function DataChainAttackResult:GetChainAttackResultSkillID()
    return self._chainSkillID
end

function DataChainAttackResult:GetChainAttackResultAtkDataList()
    return self._attackDataList
end

function DataChainAttackResult:GetChainAttackResultShadowAtkDataList()
    return self._shadowAtkDataList
end

function DataChainAttackResult:GetChainAttackResultAgentAtkDataList()
    return self._agentAtkDataList
end

function DataChainAttackResult:GetChainAttackResultCastSkillFlag()
    return self._hasCastSkill
end

function DataChainAttackResult:GetDeadEntityIDList()
    return self._deadEntityIDList
end
