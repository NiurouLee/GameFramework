---@class AutoEventBinder:Object
_class("AutoEventBinder", Object)
AutoEventBinder = AutoEventBinder

function AutoEventBinder:Constructor(gameEventDispatcher)
    ---@type table<GameEventType, Callback>
    self.type2Callbacks = {}
    ---@type GameEventDispatcher
    self.eventDispatcher = gameEventDispatcher
end
function AutoEventBinder:Dispose()
    self:UnBindAllEvents()
    self.type2Callbacks = {}
    self.eventDispatcher = nil
end
function AutoEventBinder:BindEvent(gameEventType, obj, func)
    if (self.type2Callbacks[gameEventType] ~= nil) then
        Log.error("AutoEventBinder:BindEvent same eventtype ", gameEventType,",",debug.traceback())
        return false
    end
    local callback = self.eventDispatcher:RegisterEventCallBack(gameEventType, obj, func)
    self.type2Callbacks[gameEventType] = callback
    return true
end

function AutoEventBinder:UnBindEvent(gameEventType)
    if (self.type2Callbacks[gameEventType] ~= nil) then
        local callback = self.type2Callbacks[gameEventType]
        self.eventDispatcher:UnRegisterEventCallback(callback)
        self.type2Callbacks[gameEventType] = nil
        return true
    end
    return false
end

---释放所有+过的事件
function AutoEventBinder:UnBindAllEvents()
    for k, v in pairs(self.type2Callbacks) do
        self.eventDispatcher:UnRegisterEventCallback(v)
    end
    self.type2Callbacks = {}
end
