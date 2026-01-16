--[[
    仲胥 清除MoveScopeRecord 组件
]]
_class("BuffLogicRemoveMoveScopeRecordCmpt", BuffLogicBase)
---@class BuffLogicRemoveMoveScopeRecordCmpt:BuffLogicBase
BuffLogicRemoveMoveScopeRecordCmpt = BuffLogicRemoveMoveScopeRecordCmpt

function BuffLogicRemoveMoveScopeRecordCmpt:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveMoveScopeRecordCmpt:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    if e:HasMoveScopeRecord() then
        e:RemoveMoveScopeRecord()
        Log.debug("BuffLogicRemoveMoveScopeRecordCmpt remove moveScopeRecord cmpt , entity=", e:GetID())
    end
end
