---@class UISelectObjectPath : UnityEngine.MonoBehaviour
---@field m_ObjectName string
---@field selectType UISelectObjectPath.SelectType
local m = {}
---@param _name string
function m:SetObjectName(_name) end
---@param name string
---@return UnityEngine.GameObject
function m:SpawnOneObject(name) end
---@param name string
---@param luaReq ResRequest
---@return UnityEngine.GameObject
function m:CallAfterLoad(name, luaReq) end
UISelectObjectPath = m
return m