---@class UIAnimationEvent : UnityEngine.MonoBehaviour
local m = {}
---@param func LuaInterface.LuaFunction
function m:SetCallBack(func) end
---@param type AnimType
function m:AnimCallBackEnum(type) end
UIAnimationEvent = m
return m