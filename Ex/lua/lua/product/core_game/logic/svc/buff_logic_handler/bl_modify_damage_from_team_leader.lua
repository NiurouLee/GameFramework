_class("BuffLogicDoModifyDamageFromTeamLeader", BuffLogicBase)
---@class BuffLogicDoModifyDamageFromTeamLeader : BuffLogicBase
BuffLogicDoModifyDamageFromTeamLeader = BuffLogicDoModifyDamageFromTeamLeader

function BuffLogicDoModifyDamageFromTeamLeader:Constructor(_buffIns, logicParam)
    self._modifyValue = logicParam.modifyValue
end

function BuffLogicDoModifyDamageFromTeamLeader:DoLogic()
    local val = self._modifyValue
    self._buffLogicService:ChangeFinalBehitByTeamLeaderDamageParam(self._entity, self:GetBuffSeq(), val)
end

function BuffLogicDoModifyDamageFromTeamLeader:DoOverlap(logicParam)
    self._modifyValue = logicParam.modifyValue
    self:DoLogic()
end

_class("BuffLogicRemoveModifyDamageFromTeamLeader", BuffLogicBase)
---@class BuffLogicRemoveModifyDamageFromTeamLeader : BuffLogicBase
BuffLogicRemoveModifyDamageFromTeamLeader = BuffLogicRemoveModifyDamageFromTeamLeader

function BuffLogicRemoveModifyDamageFromTeamLeader:DoLogic()
    self._buffLogicService:RemoveFinalBehitByTeamLeaderDamageParam(self._entity, self:GetBuffSeq())
end
