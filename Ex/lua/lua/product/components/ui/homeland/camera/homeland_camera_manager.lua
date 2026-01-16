---@class HomelandCameraManager:Object
_class("HomelandCameraManager", Object)
HomelandCameraManager = HomelandCameraManager

function HomelandCameraManager:Constructor()
    ---@type HomelandFollowCameraController
    self._followCameraController = HomelandFollowCameraController:New()
    ---@type HomelandGlobalCameraController
    self._globalCameraController = HomelandGlobalCameraController:New()
    ---@type HomelandMedalWallCameraController
    self._medalWallCameraController = HomelandMedalWallCameraController:New()

    self._mode = HomelandMode.Normal
end

---@param homelandClient HomelandClient
function HomelandCameraManager:Init(homelandClient)
    self._followCameraController:Init(homelandClient)
    self._globalCameraController:Init(homelandClient)
    self._medalWallCameraController:Init(homelandClient)
end

--设置是否锁定全局摄像机
function HomelandCameraManager:SetGlobalCameraLock(lock)
    self._globalCameraController:SetLockCamera(lock)
end

function HomelandCameraManager:Dispose()
    self._followCameraController:Dispose()
    self._globalCameraController:Dispose()
    self._medalWallCameraController:Dispose()
end

function HomelandCameraManager:Update(deltaTimeMS)
    self._followCameraController:Update()
end

function HomelandCameraManager:FollowCameraController()
    return self._followCameraController
end

function HomelandCameraManager:GlobalCameraController()
    return self._globalCameraController
end

function HomelandCameraManager:MedalWallCameraController()
    return self._medalWallCameraController
end

function HomelandCameraManager:OnModeChanged(mode)
    ---模式切换的相机过度如有需求在此处理
    self._mode = mode
    if mode == HomelandMode.Normal then
        self._globalCameraController:SetActive(false)
        self._followCameraController:SetActive(true)
    elseif mode == HomelandMode.Build then
        self._followCameraController:SetActive(false)
        self._globalCameraController:SetActive(true)
    elseif mode == HomelandMode.Story then
        self._followCameraController:SetActive(false)
        self._globalCameraController:SetActive(false)
    end
end

function HomelandCameraManager:Rotation()
    local cam
    if self._mode == HomelandMode.Normal then
        cam = self._followCameraController
    else
        cam = self._globalCameraController
    end
    return cam:Rotation()
end

---@return UnityEngine.Camera
function HomelandCameraManager:GetCamera()
    if self._mode == HomelandMode.Normal then
        return self._followCameraController:CameraCmp()
    elseif self._mode == HomelandMode.Build then
        return self._globalCameraController:CameraCmp()
    end
end

function HomelandCameraManager:SetMedalWallCameraActive(isActive)
    --只有在HomelandMode.Normal才能切换勋章墙相机，只处理followCameraController
    if isActive then
        self._followCameraController:SetActive(false)
        self._medalWallCameraController:SetActive(true)
    else
        self._medalWallCameraController:SetActive(false)
        self._followCameraController:SetActive(true)
    end
end
