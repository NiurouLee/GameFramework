--[[
    加攻击表现
]]
---@class BuffViewChangeAttack:BuffViewBase
_class("BuffViewChangeAttack", BuffViewBase)
BuffViewChangeAttack = BuffViewChangeAttack

function BuffViewChangeAttack:PlayView(TT)
    ---@type Entity
    local entity = self._entity
    if entity:HasMaterialAnimationComponent() then
        entity:MaterialAnimationComponent():PlayAtkup()
    end
    local cfg = self._viewInstance:BuffConfigData()
    local effectID = cfg:GetExecEffectID()
    if effectID then
        self._world:GetService("Effect"):CreateEffect(effectID, self._entity)
    end

    ---@type BuffResultChangeAttack
    local result = self._buffResult
    if result:GetIsLight() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), true)
    end
end

--[[
    卸[加攻击]表现
]]
---@class BuffViewChangeAttackUndo:BuffViewBase
_class("BuffViewChangeAttackUndo", BuffViewBase)
BuffViewChangeAttackUndo = BuffViewChangeAttackUndo

function BuffViewChangeAttackUndo:PlayView(TT)
    ---@type  BuffResultChangeAttackUndo
    local result = self._buffResult
    if result:GetIsBlack() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), false)
    end

    local casterId =result:GetCasterID()
    local caster = self._world:GetEntityByID(casterId)
    if result:GetCasterBlack() and caster and caster:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, caster:PetPstID():GetPstID(), false)
    end
end
