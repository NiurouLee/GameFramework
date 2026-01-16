---@class AircraftInteractiveCameraController:Object
_class("AircraftInteractiveCameraController", Object)
AircraftInteractiveCameraController = AircraftInteractiveCameraController

function AircraftInteractiveCameraController:Constructor()
    ---@type UnityEngine.Camera 场景内主相机
    self._mainCamera = nil
    ---@type AircraftPet 目标pet
    self._targetPet = nil
    ---@type Quaternion
    self._initCamRot = nil
    ---@type Vector3
    self._initCamPos = nil

    ---@type float
    self._initCamOffsetY = nil
    ---@type float
    self._initCamOffsetZ = nil
end

function AircraftInteractiveCameraController:Init(camera, aircraft3DManager)
    self._mainCamera = camera
    ---@type UIAircraft3DManager
    self._aircraft3DManager = aircraft3DManager
    self._cameraMng = self._aircraft3DManager:CameraManager()
end

function AircraftInteractiveCameraController:SetActive(active)
end

---@param deltaTimeMS number
function AircraftInteractiveCameraController:Update(deltaTimeMS)
    ---处理点击操作
    local clicked, clickPos = self._aircraft3DManager:InputManager():GetClick()
    if clicked then
        local clickRay = self._mainCamera:ScreenPointToRay(clickPos)
        local castRes, hitInfo = UnityEngine.Physics.Raycast(clickRay, nil)
        if castRes and self._targetPet then
            if hitInfo.transform.gameObject == self._targetPet:PetGameObject() then
                self._targetPet:InteractiveClick()
            end
        end
    end

    ---处理拖拽操作
    local dragging, dragStartPos, dragEndPos = self._aircraft3DManager:InputManager():GetDrag()
    if dragging then
        self:HandleDragCamera(dragStartPos, dragEndPos)
    end

    self:HandleFadeObjects()

    self._cameraMng:HandleWallFade(deltaTimeMS, self.targetPos)
end

function AircraftInteractiveCameraController:HandleDragCamera(dragStartPos, dragEndPos)
    local rotVec = (dragEndPos - dragStartPos) * self.rotateSpeed

    local x = self.x + rotVec.x
    local y = self.y - rotVec.y

    x = self:_HandleX(x)

    if y > self.maxAngleY then
        y = self.maxAngleY
    end

    local rotation = Quaternion.Euler(y, x, 0)
    local target = self.targetPos + rotation * Vector3(0, 0, -self.distance)

    if --[[target.y > self.ceilingY or]] target.y < self.bottomY then
        y = self.y
        rotation = Quaternion.Euler(y, x, 0)
        target = self.targetPos + rotation * Vector3(0, 0, -self.distance)
    end
    self.x = x
    self.y = y
    self._mainCamera.transform.position = target
    self._mainCamera.transform.rotation = rotation
end

--处理x，在不同的情况下选择映射到-180-180或者0-360，并限制x的范围
function AircraftInteractiveCameraController:_HandleX(x)
    if self.minAngle < self.maxAngle then
        if x > 180 then
            x = x - 360
        elseif x < -180 then
            x = x + 360
        end
        x = Mathf.Clamp(x, self.minAngle, self.maxAngle)
    elseif self.minAngle > self.maxAngle then
        if x < 0 then
            x = x + 360
        elseif x > 360 then
            x = x - 360
        end
        x = Mathf.Clamp(x, self.minAngle, self.maxAngle + 360)
    else
        x = self.minAngle
    end
    return x
end

function AircraftInteractiveCameraController:FadeIn(TT)
    local totalTime = Cfg.cfg_aircraft_camera["translateTime"].Value * 1000
    local duration = 0
    local startTime = GameGlobal:GetInstance():GetCurrentTime()
    local camOrgPos = self._mainCamera.transform.position
    local camOrgRot = self._mainCamera.transform.rotation

    while duration < totalTime do
        duration = GameGlobal:GetInstance():GetCurrentTime() - startTime
        if duration > totalTime then
            duration = totalTime
        end

        self._mainCamera.transform.position = Vector3.Lerp(camOrgPos, self._initCamPos, duration / totalTime)
        self._mainCamera.transform.rotation = Quaternion.Lerp(camOrgRot, self._initCamRot, duration / totalTime)
        self:HandleFadeObjects()
        YIELD(TT)
    end
end

---@param room AircraftRoom
function AircraftInteractiveCameraController:SetTargetPet(room, pet)
    self._targetPet = pet
    self.targetPos = pet:PetGameObject().transform.position + Vector3(0, 0.8, 0)
    local dir = Vector3.Normalize(self._mainCamera.transform.position - self.targetPos)
    local cfg = Cfg.cfg_aircraft_room_camera[room:GetRoomLogicData():SpaceId()]
    local distance = cfg.InteractDistance
    self._initCamPos = self.targetPos + dir * distance
    self._initCamRot = Quaternion.LookRotation(self.targetPos - self._initCamPos, Vector3.up)
    self.distance = Vector3.Distance(self.targetPos, self._initCamPos)
    self.x = self._initCamRot.eulerAngles.y
    self.y = self._initCamRot.eulerAngles.x
    local minHeight = 0
    self.bottomY = self.targetPos.y + minHeight
    -- self.ceilingY = 20
    self.maxAngleY = Cfg.cfg_aircraft_camera["interCameraMaxX"].Value
    self.rotateSpeed = Cfg.cfg_aircraft_camera["interCameraRotateSpeed"].Value
    self.angleRange = Cfg.cfg_aircraft_camera["interCameraAngleRange"].Value
    local _y = self._initCamRot.eulerAngles.y

    if _y > 180 then
        _y = _y - 360
    end

    --将最大与最小映射到-180~180
    self.minAngle = _y - self.angleRange / 2
    if self.minAngle < -180 then
        self.minAngle = self.minAngle + 360
    end
    self.maxAngle = _y + self.angleRange / 2
    if self.maxAngle > 180 then
        self.maxAngle = self.maxAngle - 360
    end

    ---某些物体在摄像机靠近时的参数
    local fadeObjects = {}
    if cfg.FadeObjects then
        for i = 1, #cfg.FadeObjects do
            local data = cfg.FadeObjects[i]
            local fo = {}
            fo.position = Vector3(data.pos[1], data.pos[2], data.pos[3])
            fo.minRadius = data.radius[1]
            fo.maxRadius = data.radius[2]
            fadeObjects[i] = fo
        end
    end
    self.fadeObjectsCfg = fadeObjects
    local objs = room:GetFadeObjects()
    ---@type table<FadeComponent>
    self.fadeObjects = {}
    if objs then
        for idx, obj in pairs(objs) do
            self.fadeObjects[idx] = obj:AddComponent(typeof(FadeComponent))
        end
    end
    ---end---
end

function AircraftInteractiveCameraController:HandleFadeObjects()
    if self.fadeObjectsCfg then
        local pos = self._mainCamera.transform.position
        for idx, fadeCpt in pairs(self.fadeObjects) do
            local cfg = self.fadeObjectsCfg[idx]
            local min = cfg.minRadius ^ 2
            local max = cfg.maxRadius ^ 2
            local sqrMagnitude = (pos - cfg.position).sqrMagnitude
            if sqrMagnitude > max and fadeCpt.Alpha < 1 then
                fadeCpt.Alpha = 1
            elseif sqrMagnitude < min and fadeCpt.Alpha > 0 then
                fadeCpt.Alpha = 0
            elseif sqrMagnitude > min and sqrMagnitude < max then
                fadeCpt.Alpha = (sqrMagnitude - min) / (max - min)
            end
        end
    end
end
