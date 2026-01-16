---@class UIHelper
local m = {}
---@return EGameStartType
function m.GameStartType() end
---@return string
function m.GetActiveSceneName() end
---@overload fun(cmp:UnityEngine.Component, active:bool):void
---@param go UnityEngine.GameObject
---@param active bool
function m.SetActive(go, active) end
---@overload fun(bActive:bool, tfs:table):void
---@overload fun(bActive:bool, objs:table):void
---@param go UnityEngine.GameObject
---@param active bool
function m.SetActiveRecursively(go, active) end
---@param obj UnityEngine.GameObject
---@return table
function m.GetAllTransitionComponents(obj) end
---@param ui_name string
---@return UI3DModule
function m.CreateUI3DModule(ui_name) end
function m.RemoveAllUI3DModules() end
---@param name string
---@return UnityEngine.GameObject
function m.GetGameObject(name) end
---@overload fun(o:UnityEngine.Component):void
---@param o UnityEngine.GameObject
function m.DestroyGameObject(o) end
---@return string
function m.GetDeviceModel() end
---@param uiBangWith int
function m.InvokeBangWidthChangeListeners(uiBangWith) end
---@param rt UnityEngine.RectTransform
function m.SetRectTransformToFillFullScreen(rt) end
---@return table
function m.CreateEventSystemRaycastResultList() end
---@return UIInputFieldValidatorTMP
function m.CreateTMPInputValidator() end
---@overload fun(o:UnityEngine.GameObject):void
---@param o UnityEngine.Transform
function m.SetAsLastSibling(o) end
---@param rectTrans UnityEngine.RectTransform
function m.RefreshLayout(rectTrans) end
---@param rect UnityEngine.RectTransform
---@param screenPoint UnityEngine.Vector2
---@param cam UnityEngine.Camera
---@return UnityEngine.Vector3
function m.ScreenPointToWorldPointInRectangle(rect, screenPoint, cam) end
---@param rect UnityEngine.RectTransform
---@return UnityEngine.Bounds
function m.GetBounds(rect) end
---@param camera UnityEngine.Camera
---@param scopeTextureName string
---@param safeAreaWidth int
---@param iterations int
---@param blurSpread float
---@param downSample int
function m.AddCameraBlur(camera, scopeTextureName, safeAreaWidth, iterations, blurSpread, downSample) end
---@param camera UnityEngine.Camera
function m.RemoveCameraBlur(camera) end
---@param camera UnityEngine.Camera
---@param isEnable bool
function m.EnableCameraBlur(camera, isEnable) end
---@param camera UnityEngine.Camera
---@param alpha float
function m.UpdateCameraBlurAlpha(camera, alpha) end
UIHelper = m
return m