---@class GameObjectHelper : object
local m = {}
---@param goName string
---@return UnityEngine.GameObject
function m.Find(goName) end
---@param tf UnityEngine.Transform
---@param childName string
---@return UnityEngine.Transform
function m.FindChild(tf, childName) end
---@param rootObj UnityEngine.GameObject
---@return UnityEngine.SkinnedMeshRenderer
function m.FindFirstSkinedMeshRender(rootObj) end
---@param rootObj UnityEngine.GameObject
---@return UnityEngine.SkinnedMeshRenderer
function m.FindSecondSkinedMeshRender(rootObj) end
---@param rootObj UnityEngine.GameObject
---@return UnityEngine.Vector3
function m.FindFirstSkinedMeshRenderBoundsExtent(rootObj) end
---@param rootObj UnityEngine.GameObject
---@param lyaer int
function m.SetGameObjectLayer(rootObj, lyaer) end
---@param rootObj UnityEngine.GameObject
---@param animName string
---@return float
function m.GetActorAnimationLength(rootObj, animName) end
---@param name string
---@param parent UnityEngine.Transform
---@return UnityEngine.GameObject
function m.CreateEmpty(name, parent) end
---@param tex UnityEngine.UI.Text
---@param str string
---@param length int
---@return float
function m.GetTextScale(tex, str, length) end
---@param cameraGO UnityEngine.GameObject
---@param enable bool
function m.SetCameraPostProcessTiltShiftEnable(cameraGO, enable) end
---@param anim UnityEngine.Animator
---@param name string
---@return float
function m.GetAnimTimeInAnimator(anim, name) end
function m.UnLoadUnUsedAsset() end
---@param target UnityEngine.GameObject
function m.AddVolumeComponent(target) end
---@param cameraMain UnityEngine.Camera
---@param cameraHUD UnityEngine.Camera
---@param posWorld UnityEngine.Vector3
---@param viewPosEdgeL float
---@param viewPosEdgeR float
---@param viewPosEdgeD float
---@param viewPosEdgeU float
---@return UnityEngine.Vector3
function m.CalcGridHUDWorldPos(cameraMain, cameraHUD, posWorld, viewPosEdgeL, viewPosEdgeR, viewPosEdgeD, viewPosEdgeU) end
GameObjectHelper = m
return m