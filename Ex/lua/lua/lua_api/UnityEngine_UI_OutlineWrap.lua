---@class UnityEngine.UI.Outline : UnityEngine.UI.Shadow
local m = {}
---@param endValue UnityEngine.Color
---@param duration float
---@return DG.Tweening.Tweener
function m:DOColor(endValue, duration) end
---@param endValue float
---@param duration float
---@return DG.Tweening.Tweener
function m:DOFade(endValue, duration) end
---@param endValue UnityEngine.Vector2
---@param duration float
---@return DG.Tweening.Tweener
function m:DOScale(endValue, duration) end
---@param vh UnityEngine.UI.VertexHelper
function m:ModifyMesh(vh) end
UnityEngine = {}
UnityEngine.UI = {}
UnityEngine.UI.Outline = m
return m