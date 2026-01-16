--[[
    根据怪物Buff效果类型触发Buff效果
]]
_class("BuffViewBuffEffectTrigger", BuffViewBase)
BuffViewBuffEffectTrigger = BuffViewBuffEffectTrigger

function BuffViewBuffEffectTrigger:Constructor()
end

function BuffViewBuffEffectTrigger:PlayView(TT)
    ---@type BuffResultBuffEffectTrigger
    local result = self._buffResult
    if result:GetSuccess() then
        self._world:GetService("PlayBuff"):PlayBuffView(TT,NTNotifyTriggerBuff:New(self._entity))
    end
    local count = result:GetBuffCount()
    if not count then
        count = 0
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, self._entity:PetPstID():GetPstID(), count)
end
