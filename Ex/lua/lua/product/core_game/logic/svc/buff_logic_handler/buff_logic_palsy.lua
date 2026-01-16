--[[
    瘫痪buff Palsy
]]
--添加瘫痪 SetPalsy
---@class BuffLogicSetPalsy:BuffLogicBase
_class("BuffLogicSetPalsy", BuffLogicBase)
BuffLogicSetPalsy = BuffLogicSetPalsy

function BuffLogicSetPalsy:Constructor(buffInstance, logicParam)
end

function BuffLogicSetPalsy:DoLogic()
    local e = self._buffInstance:Entity()
    return true
end

--取消瘫痪 ResetPalsy
---@class BuffLogicResetPalsy:BuffLogicBase
_class("BuffLogicResetPalsy", BuffLogicBase)
BuffLogicResetPalsy = BuffLogicResetPalsy

function BuffLogicResetPalsy:Constructor(buffInstance, logicParam)
end

function BuffLogicResetPalsy:DoLogic()
    local e = self._buffInstance:Entity()
    return true
end
