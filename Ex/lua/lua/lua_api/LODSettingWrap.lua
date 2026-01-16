---@class LODSetting : UnityEngine.ScriptableObject
---@field CurentLODLevel int
---@field meshSkinLODDistance float
---@field lowSkinQuality UnityEngine.SkinQuality
---@field highSkinQuality UnityEngine.SkinQuality
---@field isActorShowShadow bool
---@field isActorShowOutline bool
---@field isOpenImageProcess bool
---@field isOpenBloomImageProcess bool
---@field IsOpenToneMappingImageProcess bool
---@field isOpenDistortionImageProcess bool
---@field isOpenHDR bool
---@field isOpenFog bool
---@field IsOpenAntialiasing bool
---@field IsOpenVignette bool
---@field shadowItemRTSize int
---@field ShadowDistance float
---@field MaxResolution int
---@field PerformanceScore int
---@field m_AndroidDeviceNamesLOD0 table
---@field m_AndroidDeviceNamesLOD1 table
---@field m_AndroidDeviceNamesLOD2 table
---@field m_IOSDeviceNamesLOD0 table
---@field m_IOSDeviceNamesLOD1 table
---@field m_IOSDeviceNamesLOD2 table
local m = {}
---@param score float
---@return int
function m:GetLODLevelUsePerformanceScore(score) end
---@param name string
---@return int
function m:GetLODLevelUseDeviceName(name) end
LODSetting = m
return m