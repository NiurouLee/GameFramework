--[[
    风船内奇奇怪怪的相机控制器，横向位移，纵向旋转
]]
---@class AircraftCameraStrange:AircraftCameraControllerBase
_class("AircraftCameraStrange", AircraftCameraControllerBase)
AircraftCameraStrange = AircraftCameraStrange

function AircraftCameraStrange:Constructor()
end

---@param _3dManager UIAircraft3DManager
function AircraftCameraStrange:Init(camera, _3dManager, roomData)
    self._input = _3dManager:InputManager()
    ---@type AircraftRoom
    local room = roomData

    ---@type UnityEngine.Transform
    self.transform = camera.transform

    ---cfg---
    local cfg = Cfg.cfg_aircraft_room_camera[room:GetRoomLogicData():SpaceId()]
    self._zoomParam = cfg.CamZoomParam
    self._dragParam = cfg.CamDragParam
    self._dragRotParam = cfg.CamRotateParam
    ---end cfg---

    local groundPos = room:GetGroundPos()
    ---@type Vector3
    self._center = groundPos + Vector3(cfg.CameraCubeOffset[1], cfg.CameraCubeOffset[2], cfg.CameraCubeOffset[3])
    ---@type Vector3
    self._size = Vector3(cfg.CameraCubeSize[1], cfg.CameraCubeSize[2], cfg.CameraCubeSize[3])

    ---@type Vector3
    self._pos = groundPos + Vector3(cfg.CamDeltaPos[1], cfg.CamDeltaPos[2], cfg.CamDeltaPos[3])

    self._minAngle = cfg.CameraAngle[1]
    self._maxAngle = cfg.CameraAngle[2]

    ---@type Vector3
    self._rot = Quaternion.Euler(Vector3(cfg.CamInitRot[1], cfg.CamInitRot[2], cfg.CamInitRot[3]))

    self._min = self._center - self._size / 2
    self._max = self._center + self._size / 2
end

function AircraftCameraStrange:GetType()
    return AircraftCameraType.Strange
end

function AircraftCameraStrange:Update(deltaTimeMS)
    ---处理缩放操作
    local scaling, scaleLength, scaleCenterPos = self._input:GetScale()
    if scaling then
        local pos = self._pos + self.transform.forward * (scaleLength * self._zoomParam)
        if pos.y < self._min.y or pos.y > self._max.y or pos.z < self._min.z or pos.z > self._max.z then
        else
            self._pos = pos
        end
    end

    ---处理拖拽操作
    local dragging, dragStartPos, dragEndPos = self._input:GetDrag()
    if dragging then
        local delta = dragEndPos - dragStartPos
        self._pos = self._pos - Vector3(delta.x, 0, 0) * self._dragParam
        self._pos.x = Mathf.Clamp(self._pos.x, self._min.x, self._max.x)

        local angle = delta.y * self._dragRotParam
        local rot = self._rot * Quaternion.AngleAxis(angle, Vector3(1, 0, 0))
        local euler = rot.eulerAngles
        if euler.x < 180 then
            local min = 0
            if self._minAngle > 0 then
                min = self._minAngle
            end
            euler.x = Mathf.Clamp(euler.x, min, self._maxAngle)
        else
            euler.x = Mathf.Clamp(euler.x, 360 + self._minAngle, 360)
        end
        self._rot = Quaternion.Euler(euler)
    end
end

function AircraftCameraStrange:Dispose()
end
function AircraftCameraStrange:Reset()
end
