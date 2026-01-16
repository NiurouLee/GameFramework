---@class RawImageLoader : UnityEngine.MonoBehaviour
---@field m_auto_load bool
---@field m_type ELocalTexType
---@field m_rawimage_name string
---@field m_async_load bool
---@field m_only_load_image bool
---@field OnAsyncLoad System.Action
local m = {}
function m:Refresh() end
function m:InitEditor() end
function m:UnInitEditor() end
---@param color UnityEngine.Color
function m:SetColor(color) end
function m:InitImage() end
---@param rawimagename string
---@param onAsyncLoad System.Action
function m:AsyncLoadImage(rawimagename, onAsyncLoad) end
---@param rawimagename string
function m:LoadImage(rawimagename) end
---@param matName string
---@param mat UnityEngine.Material
---@param bneeddestory bool
function m:SetMat(matName, mat, bneeddestory) end
function m:DestoryLastImage() end
---@param rawimagename string
---@param onAsyncLoad System.Action
function m:AsyncLoadImageOnly(rawimagename, onAsyncLoad) end
---@param rawimagename string
function m:LoadImageOnly(rawimagename) end
RawImageLoader = m
return m