---@class UnityEngine.Application : object
---@field isPlaying bool
---@field isFocused bool
---@field platform UnityEngine.RuntimePlatform
---@field buildGUID string
---@field isMobilePlatform bool
---@field isConsolePlatform bool
---@field runInBackground bool
---@field isBatchMode bool
---@field dataPath string
---@field streamingAssetsPath string
---@field persistentDataPath string
---@field temporaryCachePath string
---@field absoluteURL string
---@field unityVersion string
---@field version string
---@field installerName string
---@field identifier string
---@field installMode UnityEngine.ApplicationInstallMode
---@field sandboxType UnityEngine.ApplicationSandboxType
---@field productName string
---@field companyName string
---@field cloudProjectId string
---@field targetFrameRate int
---@field systemLanguage UnityEngine.SystemLanguage
---@field consoleLogPath string
---@field backgroundLoadingPriority UnityEngine.ThreadPriority
---@field internetReachability UnityEngine.NetworkReachability
---@field genuine bool
---@field genuineCheckAvailable bool
---@field isEditor bool
local m = {}
---@overload fun():void
---@param exitCode int
function m.Quit(exitCode) end
function m.Unload() end
---@overload fun(levelName:string):bool
---@param levelIndex int
---@return bool
function m.CanStreamedLevelBeLoaded(levelIndex) end
---@param obj UnityEngine.Object
---@return bool
function m.IsPlaying(obj) end
---@return table
function m.GetBuildTags() end
---@param buildTags table
function m.SetBuildTags(buildTags) end
---@return bool
function m.HasProLicense() end
---@param delegateMethod UnityEngine.Application.AdvertisingIdentifierCallback
---@return bool
function m.RequestAdvertisingIdentifierAsync(delegateMethod) end
---@param url string
function m.OpenURL(url) end
---@param logType UnityEngine.LogType
---@return UnityEngine.StackTraceLogType
function m.GetStackTraceLogType(logType) end
---@param logType UnityEngine.LogType
---@param stackTraceType UnityEngine.StackTraceLogType
function m.SetStackTraceLogType(logType, stackTraceType) end
---@param mode UnityEngine.UserAuthorization
---@return UnityEngine.AsyncOperation
function m.RequestUserAuthorization(mode) end
---@param mode UnityEngine.UserAuthorization
---@return bool
function m.HasUserAuthorization(mode) end
UnityEngine = {}
UnityEngine.Application = m
return m