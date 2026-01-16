---@class ShowLuaSkillResult : UnityEngine.MonoBehaviour
---@field scopeResult SkillScopeResultForEditor
---@field skillResult SkillEffectResultForEditor
local m = {}
---@param pos UnityEngine.Vector2
function m:SetCenterPos(pos) end
---@param idList table
function m:SetTargetIDList(idList) end
---@param posList table
function m:SetScopeRange(posList) end
---@param effectType int
---@param effectResIndex int
---@param key string
---@param objValue object
function m:AddEffectResultData(effectType, effectResIndex, key, objValue) end
ShowLuaSkillResult = m
return m