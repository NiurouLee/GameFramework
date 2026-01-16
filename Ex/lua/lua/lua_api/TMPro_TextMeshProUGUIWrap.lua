---@class TMPro.TextMeshProUGUI : TMPro.TMP_Text
---@field materialForRendering UnityEngine.Material
---@field autoSizeTextContainer bool
---@field mesh UnityEngine.Mesh
---@field canvasRenderer UnityEngine.CanvasRenderer
---@field maskOffset UnityEngine.Vector4
local m = {}
function m:CalculateLayoutInputHorizontal() end
function m:CalculateLayoutInputVertical() end
function m:SetVerticesDirty() end
function m:SetLayoutDirty() end
function m:SetMaterialDirty() end
function m:SetAllDirty() end
---@param update UnityEngine.UI.CanvasUpdate
function m:Rebuild(update) end
---@param baseMaterial UnityEngine.Material
---@return UnityEngine.Material
function m:GetModifiedMaterial(baseMaterial) end
function m:RecalculateClipping() end
---@param clipRect UnityEngine.Rect
---@param validRect bool
function m:Cull(clipRect, validRect) end
function m:UpdateMeshPadding() end
---@param ignoreActiveState bool
---@param forceTextReparsing bool
function m:ForceMeshUpdate(ignoreActiveState, forceTextReparsing) end
---@param text string
---@return TMPro.TMP_TextInfo
function m:GetTextInfo(text) end
function m:ClearMesh() end
---@param mesh UnityEngine.Mesh
---@param index int
function m:UpdateGeometry(mesh, index) end
---@overload fun():void
---@param flags TMPro.TMP_VertexDataUpdateFlags
function m:UpdateVertexData(flags) end
function m:UpdateFontAsset() end
function m:ComputeMarginSize() end
TMPro = {}
TMPro.TextMeshProUGUI = m
return m