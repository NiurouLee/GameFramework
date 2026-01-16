---@class TowerScrollView : UnityEngine.MonoBehaviour
local m = {}
---@param totalHeight int
---@param itemHeigh int
---@param onShow System.Action
function m:Init(totalHeight, itemHeigh, onShow) end
---@param posY float
---@param anim bool
function m:FocusPosY(posY, anim) end
TowerScrollView = m
return m