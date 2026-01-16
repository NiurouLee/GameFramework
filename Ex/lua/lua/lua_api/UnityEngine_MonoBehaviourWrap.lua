---@class UnityEngine.MonoBehaviour : UnityEngine.Behaviour
---@field useGUILayout bool
local m = {}
---@overload fun(methodName:string):bool
---@return bool
function m:IsInvoking() end
---@overload fun(methodName:string):void
function m:CancelInvoke() end
---@param methodName string
---@param time float
function m:Invoke(methodName, time) end
---@param methodName string
---@param time float
---@param repeatRate float
function m:InvokeRepeating(methodName, time, repeatRate) end
---@overload fun(methodName:string, value:object):UnityEngine.Coroutine
---@overload fun(routine:System.Collections.IEnumerator):UnityEngine.Coroutine
---@param methodName string
---@return UnityEngine.Coroutine
function m:StartCoroutine(methodName) end
---@overload fun(routine:UnityEngine.Coroutine):void
---@overload fun(methodName:string):void
---@param routine System.Collections.IEnumerator
function m:StopCoroutine(routine) end
function m:StopAllCoroutines() end
---@param message object
function m.print(message) end
UnityEngine = {}
UnityEngine.MonoBehaviour = m
return m