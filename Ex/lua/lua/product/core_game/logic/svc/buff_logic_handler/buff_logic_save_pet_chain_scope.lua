--[[
    保存星灵连锁技范围
]]
--
_class("BuffLogicSavePetChainScope", BuffLogicBase)
BuffLogicSavePetChainScope = BuffLogicSavePetChainScope

function BuffLogicSavePetChainScope:Constructor(buffInstance, logicParam)
end

function BuffLogicSavePetChainScope:DoLogic()
    ---@type BuffComponent
    local buffComponent = self._entity:BuffComponent()
    buffComponent:SetBuffValue("SavePetChainScope", 0)
end
