--恐惧逻辑
---@class BuffLogicSetFear:BuffLogicBase
_class("BuffLogicSetFear", BuffLogicBase)
BuffLogicSetFear = BuffLogicSetFear

function BuffLogicSetFear:Constructor(buffInstance, logicParam)
end

function BuffLogicSetFear:DoLogic(notify)
    return true
end

--去除恐惧
---@class BuffLogicResetFear:BuffLogicBase
_class("BuffLogicResetFear", BuffLogicBase)
BuffLogicResetFear = BuffLogicResetFear

function BuffLogicResetFear:Constructor(buffInstance, logicParam)
end

function BuffLogicResetFear:DoLogic(notify)
    return true
end
