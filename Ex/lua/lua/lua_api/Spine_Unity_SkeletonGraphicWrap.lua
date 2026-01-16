---@class Spine.Unity.SkeletonGraphic : UnityEngine.UI.MaskableGraphic
---@field SkeletonDataAsset Spine.Unity.SkeletonDataAsset
---@field material UnityEngine.Material
---@field OverrideTexture UnityEngine.Texture
---@field mainTexture UnityEngine.Texture
---@field alphaTexture UnityEngine.Texture
---@field Skeleton Spine.Skeleton
---@field SkeletonData Spine.SkeletonData
---@field IsValid bool
---@field AnimationState Spine.AnimationState
---@field MeshGenerator Spine.Unity.MeshGenerator
---@field skeletonDataAsset Spine.Unity.SkeletonDataAsset
---@field initialSkinName string
---@field initialFlipX bool
---@field initialFlipY bool
---@field tintColor UnityEngine.Color
---@field startingAnimation string
---@field startingLoop bool
---@field timeScale float
---@field freeze bool
---@field unscaledTime bool
local m = {}
---@param skeletonDataAsset Spine.Unity.SkeletonDataAsset
---@param parent UnityEngine.Transform
---@param material UnityEngine.Material
---@return Spine.Unity.SkeletonGraphic
function m.NewSkeletonGraphicGameObject(skeletonDataAsset, parent, material) end
---@param gameObject UnityEngine.GameObject
---@param skeletonDataAsset Spine.Unity.SkeletonDataAsset
---@param material UnityEngine.Material
---@return Spine.Unity.SkeletonGraphic
function m.AddSkeletonGraphicComponent(gameObject, skeletonDataAsset, material) end
---@param update UnityEngine.UI.CanvasUpdate
function m:Rebuild(update) end
---@overload fun(deltaTime:float):void
function m:Update() end
function m:LateUpdate() end
---@return UnityEngine.Mesh
function m:GetLastMesh() end
function m:Clear() end
---@param overwrite bool
function m:Initialize(overwrite) end
function m:UpdateMesh() end
Spine = {}
Spine.Unity = {}
Spine.Unity.SkeletonGraphic = m
return m