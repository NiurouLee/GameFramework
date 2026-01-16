---@class SmokingTestAgent : UnityEngine.MonoBehaviour
---@field IsWorking bool
---@field IsActive bool
local m = {}
function m:Awake() end
function m:Start() end
function m:OnDestroy() end
---@return System.Collections.IEnumerator
function m:Launcher() end
SmokingTestAgent = m
return m