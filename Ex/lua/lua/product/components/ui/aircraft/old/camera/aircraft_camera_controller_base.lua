--风船相机类型
AircraftCameraType = {
    FixedField = 1, --固定视野相机，风船主界面
    BezierPath = 2, --贝塞尔曲线路径
    Sphere = 3, --球面移动
    Strange = 4 --奇怪的移动方式，水平平移，竖直旋转
}
_enum("AircraftCameraType", AircraftCameraType)

---@class AircraftCameraControllerBase:Object  风船相机控制器基类
_class("AircraftCameraControllerBase", Object)
AircraftCameraControllerBase = AircraftCameraControllerBase

function AircraftCameraControllerBase:Constructor()
    self._pos = nil
    self._rot = nil
    ---@type AircraftInputManager
    self._input = nil
end
function AircraftCameraControllerBase:Init(camera, input)
end
function AircraftCameraControllerBase:GetType()
end
function AircraftCameraControllerBase:Update(deltaTimeMS)
end
function AircraftCameraControllerBase:GetPos()
    return self._pos
end
function AircraftCameraControllerBase:GetRot()
    return self._rot
end
function AircraftCameraControllerBase:Dispose()
end
function AircraftCameraControllerBase:Reset()
end
