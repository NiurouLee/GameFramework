--[[
    眩晕buff
]]

--添加眩晕
_class("BuffLogicSetStun", BuffLogicBase)
BuffLogicSetStun = BuffLogicSetStun

function BuffLogicSetStun:Constructor(buffInstance, logicParam)
end

function BuffLogicSetStun:DoLogic()
    local e = self._buffInstance:Entity()
    --眩晕是状态buff
    e:BuffComponent():SetFlag(BuffFlags.SkipTurn)
    return true
end

--取消眩晕
_class("BuffLogicResetStun", BuffLogicBase)
BuffLogicResetStun = BuffLogicResetStun

function BuffLogicResetStun:Constructor(buffInstance, logicParam)
end

function BuffLogicResetStun:DoLogic()
    local e = self._buffInstance:Entity()
    --眩晕是状态buff
    e:BuffComponent():ResetFlag(BuffFlags.SkipTurn)
    return true
end
