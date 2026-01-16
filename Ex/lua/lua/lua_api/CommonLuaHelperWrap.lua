---@class CommonLuaHelper : object
local m = {}
---@param key string
---@param default_value string
---@return string
function m:GetConfig(key, default_value) end
---@return string
function m:GetLanguage() end
---@return bool
function m:IsDebug() end
---@return bool
function m.UseLogWrapper() end
---@param path string
---@param bgColor UnityEngine.Color
---@param controlMode int
---@param scalingMode int
function m:PlayMovie(path, bgColor, controlMode, scalingMode) end
function m:InitCameraShake() end
function m:CameraShakeDispose() end
---@param active bool
function m:SetShadowSettingActive(active) end
---@return int
function m:GetTick() end
---@return long
function m:GetMicrosecond() end
function m:GCCollect() end
---@param anim UnityEngine.Animation
---@return table
function m:GetAllAnimationClip(anim) end
---@param from UnityEngine.Animation
---@param to UnityEngine.Animation
function m:AddAnimTo(from, to) end
---@param from UnityEngine.Animation
---@param to UnityEngine.Animation
function m:RemoveAnimTo(from, to) end
---@param anim UnityEngine.Animation
---@param clip string
---@param time float
function m:TriggerAircraftAnimationEvent(anim, clip, time) end
---@return table
function m:NewStringList() end
---@return bool
function m:UseGoogleObb() end
---@param resName string
---@return string
function m:GetAssetLongName(resName) end
---@param assetLongName string
---@return string
function m:GetObbAccessPath(assetLongName) end
---@param idx int
---@return int
function m:GetNavAgentID(idx) end
---@param text string
function m:CopeTextToClipboard(text) end
---@param level int
function m:SetRoleShaderLodLevel(level) end
function m:AddFpsTools() end
---@param exceptionMsg string
---@param exceptionStack string
function m:ReportException(exceptionMsg, exceptionStack) end
CommonLuaHelper = m
return m