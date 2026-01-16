---@class Spine.Unity.Modules.SkeletonGraphicMultiObject : UnityEngine.MonoBehaviour
---@field SkeletonDataAsset Spine.Unity.SkeletonDataAsset
---@field Skeleton Spine.Skeleton
---@field AnimationState Spine.AnimationState
---@field MeshGenerator Spine.Unity.MeshGenerator
---@field IsValid bool
---@field Canvas UnityEngine.Canvas
---@field UseInstanceMaterials bool
---@field initialSkinName string
---@field startingAnimation string
---@field startingLoop bool
---@field timeScale float
---@field unscaledTime bool
---@field freeze bool
---@field color UnityEngine.Color
---@field material UnityEngine.Material
---@field canvasRenderers table
---@field OnInstanceMaterialCreated System.Action
local m = {}
---@return table
function m:GetMeshs() end
---@return UnityEngine.Bounds
function m:GetMeshBounds() end
function m:Clear() end
function m:TrimRenderers() end
---@overload fun(deltaTime:float):void
function m:Update() end
function m:LateUpdate() end
---@param overwrite bool
function m:Initialize(overwrite) end
function m:UpdateMesh() end
Spine = {}
Spine.Unity = {}
Spine.Unity.Modules = {}
Spine.Unity.Modules.SkeletonGraphicMultiObject = m
return m