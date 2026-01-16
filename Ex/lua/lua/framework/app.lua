---每帧更新
---@public
---@param e int deltaTimeMS
---@param unscaledE int  unscaledDeltaTimeMS
---@param timeMS int 当前毫秒时间
---@param unscaledTimeMS int 当前unscaled毫秒时间
AppLuaProxy.OnUpdate(function(e, unscaledE, timeMS, unscaledTimeMS)
	-- Log.fatal("App Update")
	GameGlobal:GetInstance():Update(e, unscaledE, timeMS, unscaledTimeMS)
end)
AppLuaProxy.OnLateUpdate(function()
	GameGlobal:GetInstance():LateUpdate()
end)

AppLuaProxy.OnFixedUpdate(function(e)
	GameGlobal:GetInstance():FixedUpdate(e)
end)

AppLuaProxy.OnPause(function(pauseStatus)
	GameGlobal:GetInstance():OnApplicationPause(pauseStatus)
end)

AppLuaProxy.OnFocus(function(hasFocus)
	GameGlobal:GetInstance():OnApplicationFocus(hasFocus)
end)

AppLuaProxy.OnQuit(function()
	GameGlobal.EventDispatcher():Dispatch(GameEventType.ApplicationQuit)
	GameGlobal:GetInstance():OnApplicationQuit()
end)


--region 输入事件
---双指缩小
---@param deltaPinch float
AppLuaProxy.OnPinchIn(function(deltaPinch)
	GameGlobal.EventDispatcher():Dispatch(GameEventType.PinchIn, deltaPinch)
end)

---双指放大
---@param deltaPinch float
AppLuaProxy.OnPinchOut(function(deltaPinch)
	GameGlobal.EventDispatcher():Dispatch(GameEventType.PinchOut, deltaPinch)
end)
--endregion
AppLuaProxy.OnLuaDestroy(function()
    GameGlobal:GetInstance():Dispose()
    ResourceManager:GetInstance():Dispose()
end)

AppLuaProxy.OnMonitor(function()
	GameGlobal.UIStateManager():ShowDialog("UIMonitorController")
end)
