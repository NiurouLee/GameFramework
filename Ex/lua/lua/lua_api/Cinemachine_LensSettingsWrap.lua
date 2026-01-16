---@class Cinemachine.LensSettings
---@field Orthographic bool
---@field SensorSize UnityEngine.Vector2
---@field Aspect float
---@field IsPhysicalCamera bool
---@field Default Cinemachine.LensSettings
---@field FieldOfView float
---@field OrthographicSize float
---@field NearClipPlane float
---@field FarClipPlane float
---@field Dutch float
---@field ModeOverride Cinemachine.LensSettings.OverrideModes
---@field LensShift UnityEngine.Vector2
---@field GateFit UnityEngine.Camera.GateFitMode
local m = {}
---@param fromCamera UnityEngine.Camera
---@return Cinemachine.LensSettings
function m.FromCamera(fromCamera) end
---@overload fun(lens:Cinemachine.LensSettings):void
---@param camera UnityEngine.Camera
function m:SnapshotCameraReadOnlyProperties(camera) end
---@param lensA Cinemachine.LensSettings
---@param lensB Cinemachine.LensSettings
---@param t float
---@return Cinemachine.LensSettings
function m.Lerp(lensA, lensB, t) end
function m:Validate() end
Cinemachine = {}
Cinemachine.LensSettings = m
return m