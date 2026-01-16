---@class SeasonManager:Object
_class("SeasonManager", Object)
SeasonManager = SeasonManager

function SeasonManager:Constructor()
    self._seasonSceneManager = SeasonSceneManager:New()
    self._seasonPlayerManager = SeasonPlayerManager:New()
    self._seasonCameraManager = SeasonCameraManager:New()
    self._seasonInputManager = SeasonInputManager:New()
    self._seasonMapManager = SeasonMapManager:New()
    self._seasonAudioManager = SeasonAudioManager:New()
    self._seasonUIManager = SeasonUIManager:New()
end

function SeasonManager:Init(seasonID, params)
    self._locks = {}
    self._inputMode = SeasonInputMode.Input
    self._seasonSceneManager:OnInit(seasonID, params)
    self._seasonPlayerManager:OnInit(seasonID, params)
    self._seasonCameraManager:OnInit(seasonID, params)
    self._seasonInputManager:OnInit(seasonID, params)
    self._seasonMapManager:OnInit(seasonID, params)
    self._seasonAudioManager:OnInit(seasonID, params)
    self._seasonUIManager:OnInit(seasonID)
end

function SeasonManager:Update(deltaTime)
    self._inputMode = self:GetInputMode()
    self._seasonSceneManager:Update(deltaTime)
    self._seasonPlayerManager:Update(deltaTime)
    self._seasonCameraManager:Update(deltaTime, self._inputMode)
    if self._inputMode == SeasonInputMode.Input then
        self._seasonInputManager:Update(deltaTime)
    end
    self._seasonMapManager:Update(deltaTime)
    self._seasonAudioManager:Update(deltaTime)
    self._seasonUIManager:Update(deltaTime)
end

function SeasonManager:Dispose()
    self._seasonSceneManager:Dispose()
    self._seasonPlayerManager:Dispose()
    self._seasonCameraManager:Dispose()
    self._seasonInputManager:Dispose()
    self._seasonMapManager:Dispose()
    self._seasonAudioManager:Dispose()
    self._seasonUIManager:Dispose()
    table.clear(self._locks)
end

---@return SeasonSceneManager
function SeasonManager:SeasonSceneManager()
    return self._seasonSceneManager
end

---@return SeasonPlayerManager
function SeasonManager:SeasonPlayerManager()
    return self._seasonPlayerManager
end

---@return SeasonCameraManager
function SeasonManager:SeasonCameraManager()
    return self._seasonCameraManager
end

---@return SeasonInputManager
function SeasonManager:SeasonInputManager()
    return self._seasonInputManager
end

---@return SeasonMapManager
function SeasonManager:SeasonMapManager()
    return self._seasonMapManager
end

---@return SeasonAudioManager
function SeasonManager:SeasonAudioManager()
    return self._seasonAudioManager
end

---@return SeasonUIManager
function SeasonManager:SeasonUIManager()
    return self._seasonUIManager
end

---@return SeasonInputMode
function SeasonManager:GetInputMode()
    if table.count(self._locks) > 0 then
        return SeasonInputMode.LockInput
    else
        return SeasonInputMode.Input
    end
end

function SeasonManager:Lock(name)
    if self._locks[name] then
        Log.error("SeasonManager lock exist.", name)
    end
    self._locks[name] = true
    Log.debug("SeasonManager add lock", name)
end

function SeasonManager:UnLock(name)
    if self._locks[name] then
        self._locks[name] = nil
        Log.debug("SeasonManager remove lock", name)
    else
        Log.error("SeasonManager UnLock not exist.", name)
    end
end

function SeasonManager:ClearLocks()
    self._locks = {}
end

---@param diff UISeasonLevelDiff
function SeasonManager:SwitchDiff(diff)
    self._seasonMapManager:SwitchDiff(diff)
    self._seasonUIManager:SwitchDiff(diff)
end

--自动移动到事件点
---@param id number 事件点id
function SeasonManager:AutoMoveToEventPoint(id)
    local eventPoint = self._seasonMapManager:GetEventPoint(id)
    if eventPoint then
        self._seasonCameraManager:SeasonCamera():Focus(eventPoint:Position()) --聚焦
        if eventPoint:IsUnLock() then
            self._seasonInputManager:GetInput():SetClickUnLockZone(true) --点击在解锁区域了
        else
            self._seasonInputManager:GetInput():SetClickUnLockZone(false) --点击在未解锁区域了
        end
        self._seasonInputManager:GetInput():GetClickEffect():Click() --模拟一次点击效果
        self._seasonInputManager:GetInput():SetCurClickEventPoint(eventPoint) --设置点击对象
        eventPoint:AutoMoveToMe()
    end
end

function SeasonManager:LockUI()
    return self._seasonMapManager:EventPointPlaying() and self:GetInputMode() == SeasonInputMode.LockInput
end