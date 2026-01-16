--[[
    控制UI上ActivatePassive显隐
    
]]
_class("BuffViewChangeActivatePassive", BuffViewBase)
BuffViewChangeActivatePassive = BuffViewChangeActivatePassive
function BuffViewChangeActivatePassive:IsNotifyMatch(notify)
    ---@type BuffResultCastSkill
    local result = self._buffResult
    if notify and notify:GetNotifyType() == NotifyType.NotifyLayerChange then
        ---@type NTNotifyLayerChange
        local n = notify
        if notify:GetLayerName() ~= result:GetLayerName() then
            return false
        end
        return result:GetLayer() == n:GetLayer()
    end
    return true
end
function BuffViewChangeActivatePassive:PlayView(TT)
    local light = self._buffResult:GetLight()
    local bForceInit = self._buffResult:GetForceInit() --妮娜 米洛斯
    if bForceInit then
        local forceInitType = self._buffResult:GetForceInitType()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ForceInitPassiveIcon, self._entity:PetPstID():GetPstID(),forceInitType)
    end
	GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, self._entity:PetPstID():GetPstID(), light)
end