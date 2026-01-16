---@class CriWare.CriMonoBehaviour : UnityEngine.MonoBehaviour
---@field guid System.Guid
local m = {}
function m:CriInternalUpdate() end
function m:CriInternalLateUpdate() end
CriWare = {}
CriWare.CriMonoBehaviour = m
return m