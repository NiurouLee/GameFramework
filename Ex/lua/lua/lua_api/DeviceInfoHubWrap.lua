---@class DeviceInfoHub : object
---@field Platform UnityEngine.RuntimePlatform
---@field Language UnityEngine.SystemLanguage
---@field OSVersion System.Version
---@field SDKVersion System.Version
---@field Model string
---@field PerfomanceLevel int
---@field Brand string
---@field RamSizeMB ulong
---@field RomSizeMB ulong
---@field SDCardSizeMB ulong
---@field AvailableRomSizeMB ulong
---@field NetworkType UnityEngine.NetworkReachability
---@field CpuInfo string
---@field GPUMemorySize ulong
---@field CPULogicCount int
---@field RuntimeCPUType string
---@field IsPowerSavingMode bool
---@field IsSupportAccelerometer bool
---@field SystemName string
local m = {}
DeviceInfoHub = m
return m