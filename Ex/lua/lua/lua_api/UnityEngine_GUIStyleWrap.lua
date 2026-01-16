---@class UnityEngine.GUIStyle : object
---@field name string
---@field font UnityEngine.Font
---@field imagePosition UnityEngine.ImagePosition
---@field alignment UnityEngine.TextAnchor
---@field wordWrap bool
---@field clipping UnityEngine.TextClipping
---@field contentOffset UnityEngine.Vector2
---@field fixedWidth float
---@field fixedHeight float
---@field stretchWidth bool
---@field stretchHeight bool
---@field fontSize int
---@field fontStyle UnityEngine.FontStyle
---@field richText bool
---@field normal UnityEngine.GUIStyleState
---@field hover UnityEngine.GUIStyleState
---@field active UnityEngine.GUIStyleState
---@field onNormal UnityEngine.GUIStyleState
---@field onHover UnityEngine.GUIStyleState
---@field onActive UnityEngine.GUIStyleState
---@field focused UnityEngine.GUIStyleState
---@field onFocused UnityEngine.GUIStyleState
---@field border UnityEngine.RectOffset
---@field margin UnityEngine.RectOffset
---@field padding UnityEngine.RectOffset
---@field overflow UnityEngine.RectOffset
---@field lineHeight float
---@field none UnityEngine.GUIStyle
---@field isHeightDependantOnWidth bool
local m = {}
---@overload fun(position:UnityEngine.Rect, text:string, isHover:bool, isActive:bool, on:bool, hasKeyboardFocus:bool):void
---@overload fun(position:UnityEngine.Rect, image:UnityEngine.Texture, isHover:bool, isActive:bool, on:bool, hasKeyboardFocus:bool):void
---@overload fun(position:UnityEngine.Rect, content:UnityEngine.GUIContent, isHover:bool, isActive:bool, on:bool, hasKeyboardFocus:bool):void
---@overload fun(position:UnityEngine.Rect, content:UnityEngine.GUIContent, controlID:int):void
---@overload fun(position:UnityEngine.Rect, content:UnityEngine.GUIContent, controlID:int, on:bool):void
---@param position UnityEngine.Rect
---@param isHover bool
---@param isActive bool
---@param on bool
---@param hasKeyboardFocus bool
function m:Draw(position, isHover, isActive, on, hasKeyboardFocus) end
---@param position UnityEngine.Rect
---@param content UnityEngine.GUIContent
---@param controlID int
---@param character int
function m:DrawCursor(position, content, controlID, character) end
---@param position UnityEngine.Rect
---@param content UnityEngine.GUIContent
---@param controlID int
---@param firstSelectedCharacter int
---@param lastSelectedCharacter int
function m:DrawWithTextSelection(position, content, controlID, firstSelectedCharacter, lastSelectedCharacter) end
---@param str string
---@return UnityEngine.GUIStyle
function m.op_Implicit(str) end
---@param position UnityEngine.Rect
---@param content UnityEngine.GUIContent
---@param cursorStringIndex int
---@return UnityEngine.Vector2
function m:GetCursorPixelPosition(position, content, cursorStringIndex) end
---@param position UnityEngine.Rect
---@param content UnityEngine.GUIContent
---@param cursorPixelPosition UnityEngine.Vector2
---@return int
function m:GetCursorStringIndex(position, content, cursorPixelPosition) end
---@param content UnityEngine.GUIContent
---@return UnityEngine.Vector2
function m:CalcSize(content) end
---@param contentSize UnityEngine.Vector2
---@return UnityEngine.Vector2
function m:CalcScreenSize(contentSize) end
---@param content UnityEngine.GUIContent
---@param width float
---@return float
function m:CalcHeight(content, width) end
---@param content UnityEngine.GUIContent
---@param minWidth float
---@param maxWidth float
function m:CalcMinMaxWidth(content, minWidth, maxWidth) end
---@return string
function m:ToString() end
UnityEngine = {}
UnityEngine.GUIStyle = m
return m