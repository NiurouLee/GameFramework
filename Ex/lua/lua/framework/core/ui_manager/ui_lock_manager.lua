--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    UI锁管理器
    1、普通锁，需要加锁(Lock)、解锁(UnLock)成对调用
    2、时限锁，等待一段时间自动解锁，可以被取消
**********************************************************************************************
]] --------------------------------------------------------------------------------------------
_class("UILockManager", Object)

function UILockManager:Constructor(uiLayerManager)
    --命名锁，不计数
    self.nameLocks = FastArray:New()
    self.lockName2Event = {}
    --时限锁的事件table

    self.showBusyCount = 0
    self.lockManagerHelper = UILockManagerHelper:New(uiLayerManager.layerManagerHelper)
end

function UILockManager:Dispose()
    self.lockManagerHelper:Dispose()
end

--region UI锁
function UILockManager:IsLocked()
    return self.nameLocks:Size() ~= 0
end

function UILockManager:HasLock(name)
    return self.nameLocks:Find(name) ~= -1
end

function UILockManager:LockedSize()
    return self.nameLocks:Size()
end

---加锁
---@param name string
---@return boolean
function UILockManager:Lock(name)
    if string.isnullorempty(name) then
        Log.fatal("[UI] [Lock] lock_name is empty")
        return false
    end
    if self:HasLock(name) then
        Log.fatal("[UI] [Lock] lock name already exist '", name, "'")
        return false
    end

    self.nameLocks:Insert(name)
    Log.debug("[UI] [Lock] '", name, "' lock count: ", self.nameLocks:Size())

    self.lockManagerHelper:Lock()
    return true
end
---解锁
---@param name string
function UILockManager:UnLock(name)
    if string.isnullorempty(name) then
        Log.fatal("[UI] [UnLock] lock_name is empty")
        return
    end

    local index = self.nameLocks:Find(name)
    if index ~= -1 then
        self.nameLocks:RemoveByIndex(index)
        Log.debug("[UI] [UnLock] '", name, "' lock count: ", self.nameLocks:Size())
    end

    if self.nameLocks:Size() == 0 then
        self.lockManagerHelper:UnLock()
    end
end

---时限锁
---@param name string
---@param lockMs number
function UILockManager:ExpirationLock(name, lockMs)
    if type(lockMs) ~= "number" or lockMs <= 0 then
        Log.fatal("[UI] [ExpirationLock] lockMs is empty or <=0")
        return
    end

    if self:Lock(name) == true then
        local event = GameGlobal.Timer():AddEvent(lockMs, UILockManager.UnLockAfterTime, self, name)
        self.lockName2Event[name] = event
    end
end
---取消时限锁
---@param name string
function UILockManager:CancelExpirationLock(name)
    if string.isnullorempty(name) then
        Log.fatal("[UI] [CancelExpirationLock] lock_name is empty")
        return
    end

    local expirationEvent = self.lockName2Event[name]
    if expirationEvent == nil then
        return
    end

    GameGlobal.Timer():CancelEvent(expirationEvent)
    self.lockName2Event[name] = nil
    self:UnLock(name)
end

function UILockManager:UnLockAll()
    Log.debug("[UI] [UnLockAll] Done")
    self.nameLocks:Clear()
    self.lockManagerHelper:UnLockAll()

    for _, event in pairs(self.lockName2Event) do
        GameGlobal.Timer():CancelEvent(event)
    end
    table.clear(self.lockName2Event)
end

---@private
function UILockManager:UnLockAfterTime(name)
    if name then
        self:UnLock(name)
        self.lockName2Event[name] = nil
        Log.debug("[UI] [ExpirationLock] event callback '", name, "'")
    else
        Log.fatal("UILockManager:UnLockAfterTime params error")
    end
end
--endregion

--region 转圈
function UILockManager:ShowBusy(flag)
    if flag then
        self.showBusyCount = self.showBusyCount + 1
        if self.showBusyCount == 1 then
            self:Lock("showbusy")
            self.lockManagerHelper:SetHighDepthObjectActive(true)
        end
    else
        if self.showBusyCount > 0 then
            self.showBusyCount = self.showBusyCount - 1
        end
        if self.showBusyCount == 0 then
            self:UnLock("showbusy")
            self.lockManagerHelper:SetHighDepthObjectActive(false)
        end
    end
end
function UILockManager:ClearBusy()
    self:UnLock("showbusy")
    self.lockManagerHelper:SetHighDepthObjectActive(false)
    self.showBusyCount = 0
end
--endregion


function UILockManager:GetLocksNameString()
    local retString = " : "
    self.nameLocks:ForEach(function(ele)
        retString = retString .. ele .. " ; "
    end)
    return retString
end