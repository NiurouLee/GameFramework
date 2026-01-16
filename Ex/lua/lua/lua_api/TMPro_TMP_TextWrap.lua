---@class TMPro.TMP_Text : UnityEngine.UI.MaskableGraphic
---@field text string
---@field textPreprocessor TMPro.ITextPreprocessor
---@field isRightToLeftText bool
---@field font TMPro.TMP_FontAsset
---@field fontSharedMaterial UnityEngine.Material
---@field fontSharedMaterials table
---@field fontMaterial UnityEngine.Material
---@field fontMaterials table
---@field color UnityEngine.Color
---@field alpha float
---@field enableVertexGradient bool
---@field colorGradient TMPro.VertexGradient
---@field colorGradientPreset TMPro.TMP_ColorGradient
---@field spriteAsset TMPro.TMP_SpriteAsset
---@field tintAllSprites bool
---@field styleSheet TMPro.TMP_StyleSheet
---@field textStyle TMPro.TMP_Style
---@field overrideColorTags bool
---@field faceColor UnityEngine.Color32
---@field outlineColor UnityEngine.Color32
---@field outlineWidth float
---@field fontSize float
---@field fontScale float
---@field fontWeight TMPro.FontWeight
---@field pixelsPerUnit float
---@field enableAutoSizing bool
---@field fontSizeMin float
---@field fontSizeMax float
---@field fontStyle TMPro.FontStyles
---@field isUsingBold bool
---@field horizontalAlignment TMPro.HorizontalAlignmentOptions
---@field verticalAlignment TMPro.VerticalAlignmentOptions
---@field alignment TMPro.TextAlignmentOptions
---@field characterSpacing float
---@field wordSpacing float
---@field lineSpacing float
---@field lineSpacingAdjustment float
---@field paragraphSpacing float
---@field characterWidthAdjustment float
---@field enableWordWrapping bool
---@field wordWrappingRatios float
---@field overflowMode TMPro.TextOverflowModes
---@field isTextOverflowing bool
---@field firstOverflowCharacterIndex int
---@field linkedTextComponent TMPro.TMP_Text
---@field isTextTruncated bool
---@field enableKerning bool
---@field extraPadding bool
---@field richText bool
---@field parseCtrlCharacters bool
---@field isOverlay bool
---@field isOrthographic bool
---@field enableCulling bool
---@field ignoreVisibility bool
---@field horizontalMapping TMPro.TextureMappingOptions
---@field verticalMapping TMPro.TextureMappingOptions
---@field mappingUvLineOffset float
---@field renderMode TMPro.TextRenderFlags
---@field geometrySortingOrder TMPro.VertexSortingOrder
---@field isTextObjectScaleStatic bool
---@field vertexBufferAutoSizeReduction bool
---@field firstVisibleCharacter int
---@field maxVisibleCharacters int
---@field maxVisibleWords int
---@field maxVisibleLines int
---@field useMaxVisibleDescender bool
---@field pageToDisplay int
---@field margin UnityEngine.Vector4
---@field textInfo TMPro.TMP_TextInfo
---@field havePropertiesChanged bool
---@field isUsingLegacyAnimationComponent bool
---@field transform UnityEngine.Transform
---@field rectTransform UnityEngine.RectTransform
---@field autoSizeTextContainer bool
---@field mesh UnityEngine.Mesh
---@field isVolumetricText bool
---@field bounds UnityEngine.Bounds
---@field textBounds UnityEngine.Bounds
---@field flexibleHeight float
---@field flexibleWidth float
---@field minWidth float
---@field minHeight float
---@field maxWidth float
---@field maxHeight float
---@field preferredWidth float
---@field preferredHeight float
---@field renderedWidth float
---@field renderedHeight float
---@field layoutPriority int
local m = {}
---@param ignoreActiveState bool
---@param forceTextReparsing bool
function m:ForceMeshUpdate(ignoreActiveState, forceTextReparsing) end
---@param mesh UnityEngine.Mesh
---@param index int
function m:UpdateGeometry(mesh, index) end
---@overload fun():void
---@param flags TMPro.TMP_VertexDataUpdateFlags
function m:UpdateVertexData(flags) end
---@param vertices table
function m:SetVertices(vertices) end
function m:UpdateMeshPadding() end
---@param targetColor UnityEngine.Color
---@param duration float
---@param ignoreTimeScale bool
---@param useAlpha bool
function m:CrossFadeColor(targetColor, duration, ignoreTimeScale, useAlpha) end
---@param alpha float
---@param duration float
---@param ignoreTimeScale bool
function m:CrossFadeAlpha(alpha, duration, ignoreTimeScale) end
---@overload fun(text:string, arg0:float):void
---@overload fun(text:string, arg0:float, arg1:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float, arg3:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float, arg3:float, arg4:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float, arg3:float, arg4:float, arg5:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float, arg3:float, arg4:float, arg5:float, arg6:float):void
---@overload fun(text:string, arg0:float, arg1:float, arg2:float, arg3:float, arg4:float, arg5:float, arg6:float, arg7:float):void
---@overload fun(text:System.Text.StringBuilder):void
---@overload fun(text:table):void
---@overload fun(text:table, start:int, length:int):void
---@param text string
---@param syncTextInputBox bool
function m:SetText(text, syncTextInputBox) end
---@overload fun(sourceText:table, start:int, length:int):void
---@overload fun(sourceText:table, start:int, length:int):void
---@param sourceText table
function m:SetCharArray(sourceText) end
---@overload fun(width:float, height:float):UnityEngine.Vector2
---@overload fun(text:string):UnityEngine.Vector2
---@overload fun(text:string, width:float, height:float):UnityEngine.Vector2
---@return UnityEngine.Vector2
function m:GetPreferredValues() end
---@overload fun(onlyVisibleCharacters:bool):UnityEngine.Vector2
---@return UnityEngine.Vector2
function m:GetRenderedValues() end
---@param text string
---@return TMPro.TMP_TextInfo
function m:GetTextInfo(text) end
function m:ComputeMarginSize() end
---@overload fun(uploadGeometry:bool):void
function m:ClearMesh() end
---@return string
function m:GetParsedText() end
TMPro = {}
TMPro.TMP_Text = m
return m