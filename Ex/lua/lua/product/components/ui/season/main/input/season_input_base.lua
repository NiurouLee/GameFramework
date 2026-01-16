---@class SeasonInputBase:Object
_class("SeasonInputBase", Object)
SeasonInputBase = SeasonInputBase

function SeasonInputBase:Constructor(seasonID)
    ---@type SeasonManager
    self._seasonManger = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonPlayer
    self._player = self._seasonManger:SeasonPlayerManager():GetPlayer()
    ---@type UnityEngine.Camera
    self._camera = self._seasonManger:SeasonCameraManager():Camera()
    ---@type SeasonCameraBase
    self._seasonCamera = self._seasonManger:SeasonCameraManager():SeasonCamera()
    ---@type SeasonSceneLayerZoneFlag
    self._zoneFlagLayer = self._seasonManger:SeasonSceneManager():GetLayer(SeasonSceneLayer.ZoneFlag)
    ---@type UnityEngine.Input
    self._input = GameGlobal.EngineInput()
    self._clickTime = 0.2 --用于区分点击还是长按
    self._clickDownTime = 0
    ---@type SeasonMapEventPoint
    self._curClickEventPoint = nil
    self._clickPositionInUnlockZone = false --点击位置是否在解锁区域
    self._clickEffect = SeasonInputEffect:New(seasonID)
end

function SeasonInputBase:Update(deltaTime)
    self._clickEffect:Update(deltaTime)
end

function SeasonInputBase:Dispose()
    self._player = nil
    self._clickEffect:Dispose()
end

---@return SeasonMapEventPoint
function SeasonInputBase:GetCurClickEventPoint()
    return self._curClickEventPoint
end

---@param eventPoint SeasonMapEventPoint
function SeasonInputBase:SetCurClickEventPoint(eventPoint)
    self._curClickEventPoint = eventPoint
end

---@return boolean
function SeasonInputBase:GetClickUnLockZone()
    return self._clickPositionInUnlockZone
end

---@param clickUnlock boolean 是否点击在了解锁区域
function SeasonInputBase:SetClickUnLockZone(clickUnlock)
    self._clickPositionInUnlockZone = clickUnlock
end

---@return SeasonInputEffect
function SeasonInputBase:GetClickEffect()
    return self._clickEffect
end