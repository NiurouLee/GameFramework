---@class UIView : UnityEngine.MonoBehaviour
local m = {}
---@param b_show bool
---@param ui_table object
function m:SetShow(b_show, ui_table) end
---@param go UnityEngine.GameObject
---@param active bool
function m.SetActive(go, active) end
---@overload fun():UnityEngine.GameObject
---@param name string
---@return UnityEngine.GameObject
function m:GetGameObject(name) end
---@param type string
---@param name string
---@return UnityEngine.Component
function m:GetUIComponent(type, name) end
---@param go UnityEngine.GameObject
---@param ui LuaInterface.LuaTable
function m:AddGuideClick(go, ui) end
---@param go UnityEngine.GameObject
function m:RemoveGuideClick(go) end
UIView = m
return m