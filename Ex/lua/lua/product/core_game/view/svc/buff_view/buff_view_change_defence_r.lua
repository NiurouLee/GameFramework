--[[
    加防御表现
]]
---@class BuffViewChangeDefence:BuffViewBase
_class("BuffViewChangeDefence", BuffViewBase)
BuffViewChangeDefence = BuffViewChangeDefence

function BuffViewChangeDefence:PlayView(TT)
    ---@type Entity
    local entity = self._entity
    if entity:HasMaterialAnimationComponent() then
        entity:MaterialAnimationComponent():PlayDefup()
    end
    local cfg = self._viewInstance:BuffConfigData()
    local effectID = cfg:GetExecEffectID()
    if effectID then
        self._world:GetService("Effect"):CreateEffect(effectID, self._entity)
    end

    if self._buffResult:GetLight() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), true)
    end
end

_class("BuffViewChangeDefenceUndo", BuffViewBase)
---@class BuffViewChangeDefenceUndo: BuffViewBase
BuffViewChangeDefenceUndo = BuffViewChangeDefenceUndo

function BuffViewChangeDefenceUndo:PlayView(TT)
    if self._buffResult:GetBlack() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), false)
    end
end
