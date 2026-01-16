--[[
    刷新血量上自爆层数的显示
]]
_class("BuffLogicHPBombLayer", BuffLogicBase)
BuffLogicHPBombLayer = BuffLogicHPBombLayer

function BuffLogicHPBombLayer:Constructor(buffInstance, logicParam)
end

function BuffLogicHPBombLayer:DoLogic(notify)
    local e = self._buffInstance:Entity()
    local newLayer = self._buffInstance:GetLayerCount()
    local buffResult = BuffResultHPBombLayer:New(e:GetID(), newLayer)
    return buffResult
end
