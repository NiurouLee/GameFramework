---@class SeasonCameraManager:Object
_class("SeasonCameraManager", Object)
SeasonCameraManager = SeasonCameraManager

function SeasonCameraManager:Constructor()
end

function SeasonCameraManager:OnInit(seasonID)
    if EDITOR or IsPc() then
        self._seasonCamera = SeasonCameraPc:New(seasonID)
    else
        self._seasonCamera = SeasonCameraMobile:New(seasonID)
    end
    self._seasonCamera:SetPositionForce()
end

function SeasonCameraManager:Update(deltaTime, inputMode)
    self._seasonCamera:Update(deltaTime, inputMode)
end

function SeasonCameraManager:Dispose()
    self._seasonCamera:Dispose()
    self._seasonCamera = nil
end

---@param mode SeasonCameraMode
function SeasonCameraManager:SwitchMode(mode)
    self._seasonCamera:SwitchMode(mode)
end

---@return SeasonCameraBase
function SeasonCameraManager:SeasonCamera()
    return self._seasonCamera
end

function SeasonCameraManager:Camera()
    return self._seasonCamera:Camera()
end

--相机入场动效 镜头拉近效果
function SeasonCameraManager:DoEnterAnim()
    local camera = self:Camera()
    local curSize = camera.orthographicSize
    local fromSize = curSize + 0.4
    camera.orthographicSize = fromSize
    camera:DOOrthoSize(curSize, 1.2)
end
