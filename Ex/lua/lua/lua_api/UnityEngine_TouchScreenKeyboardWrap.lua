---@class UnityEngine.TouchScreenKeyboard : object
---@field isSupported bool
---@field text string
---@field hideInput bool
---@field active bool
---@field status UnityEngine.TouchScreenKeyboard.Status
---@field characterLimit int
---@field canGetSelection bool
---@field canSetSelection bool
---@field selection UnityEngine.RangeInt
---@field type UnityEngine.TouchScreenKeyboardType
---@field targetDisplay int
---@field area UnityEngine.Rect
---@field visible bool
local m = {}
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType, autocorrection:bool, multiline:bool, secure:bool, alert:bool, textPlaceholder:string):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType, autocorrection:bool, multiline:bool, secure:bool, alert:bool):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType, autocorrection:bool, multiline:bool, secure:bool):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType, autocorrection:bool, multiline:bool):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType, autocorrection:bool):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string, keyboardType:UnityEngine.TouchScreenKeyboardType):UnityEngine.TouchScreenKeyboard
---@overload fun(text:string):UnityEngine.TouchScreenKeyboard
---@param text string
---@param keyboardType UnityEngine.TouchScreenKeyboardType
---@param autocorrection bool
---@param multiline bool
---@param secure bool
---@param alert bool
---@param textPlaceholder string
---@param characterLimit int
---@return UnityEngine.TouchScreenKeyboard
function m.Open(text, keyboardType, autocorrection, multiline, secure, alert, textPlaceholder, characterLimit) end
UnityEngine = {}
UnityEngine.TouchScreenKeyboard = m
return m