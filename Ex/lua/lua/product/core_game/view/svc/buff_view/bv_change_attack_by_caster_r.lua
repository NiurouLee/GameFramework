--[[
    加攻击表现
]]
---@class BuffViewChangeAttackByCaster:BuffViewBase
_class("BuffViewChangeAttackByCaster", BuffViewBase)
BuffViewChangeAttackByCaster = BuffViewChangeAttackByCaster

function BuffViewChangeAttackByCaster:PlayView(TT)
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

    ---@type BuffResultChangeAttackByCaster
    local result = self._buffResult

    if result:GetLight() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, result:GetCasterPstID(), true) 
    end
end

--[[
    卸[加攻击]表现
]]
---@class BuffViewUndoChangeAttackByCaster:BuffViewBase
_class("BuffViewUndoChangeAttackByCaster", BuffViewBase)
BuffViewUndoChangeAttackByCaster = BuffViewUndoChangeAttackByCaster

function BuffViewUndoChangeAttackByCaster:PlayView(TT)
    ---@type BuffResultUndoChangeAttackByCaster
    local result = self._buffResult

    if result:GetBlack()  then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, result:GetCasterPstID(), false) 
    end
end
