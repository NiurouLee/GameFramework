--[[
    增加反伤层数表现
]]
_class("BuffViewAddReflexiveDamageLayer", BuffViewBase)
BuffViewAddReflexiveDamageLayer = BuffViewAddReflexiveDamageLayer

function BuffViewAddReflexiveDamageLayer:PlayView(TT)
    if not self._entity:PetPstID() then
        return
    end

    ---@type BuffResultLayer
    local res = self:GetBuffResult()
    local layer = res:GetLayer()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, self._entity:PetPstID():GetPstID(), layer)
end
