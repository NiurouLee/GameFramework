---@class UnityEngine.SceneManagement.Scene
---@field handle int
---@field path string
---@field name string
---@field isLoaded bool
---@field buildIndex int
---@field isDirty bool
---@field rootCount int
local m = {}
---@return bool
function m:IsValid() end
---@overload fun(rootGameObjects:table):void
---@return table
function m:GetRootGameObjects() end
---@param lhs UnityEngine.SceneManagement.Scene
---@param rhs UnityEngine.SceneManagement.Scene
---@return bool
function m.op_Equality(lhs, rhs) end
---@param lhs UnityEngine.SceneManagement.Scene
---@param rhs UnityEngine.SceneManagement.Scene
---@return bool
function m.op_Inequality(lhs, rhs) end
---@return int
function m:GetHashCode() end
---@param other object
---@return bool
function m:Equals(other) end
UnityEngine = {}
UnityEngine.SceneManagement = {}
UnityEngine.SceneManagement.Scene = m
return m