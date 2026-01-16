---@class UnityEngine.AnimatorStateInfo
---@field fullPathHash int
---@field shortNameHash int
---@field normalizedTime float
---@field length float
---@field speed float
---@field speedMultiplier float
---@field tagHash int
---@field loop bool
local m = {}
---@param name string
---@return bool
function m:IsName(name) end
---@param tag string
---@return bool
function m:IsTag(tag) end
UnityEngine = {}
UnityEngine.AnimatorStateInfo = m
return m