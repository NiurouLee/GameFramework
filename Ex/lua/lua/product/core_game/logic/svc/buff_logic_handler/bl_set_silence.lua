--[[
    沉默 无法使用主动技
]]
require("buff_logic_base")

_class("BuffLogicSetSilence", BuffLogicBase)
---@class BuffLogicSetSilence : BuffLogicBase
BuffLogicSetSilence = BuffLogicSetSilence

function BuffLogicSetSilence:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.Silence)
end

_class("BuffLogicResetSilence", BuffLogicBase)
---@class BuffLogicResetSilence : BuffLogicBase
BuffLogicResetSilence = BuffLogicResetSilence

function BuffLogicResetSilence:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.Silence)
end
