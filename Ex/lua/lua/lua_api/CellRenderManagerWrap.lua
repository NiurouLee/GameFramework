---@class CellRenderManager : UnityEngine.MonoBehaviour
local m = {}
---@param posArray table
function m.DrawRangeImmediate(posArray) end
---@param rect UnityEngine.Vector4
function m.SetClipRect(rect) end
function m.DisableCellClip() end
CellRenderManager = m
return m