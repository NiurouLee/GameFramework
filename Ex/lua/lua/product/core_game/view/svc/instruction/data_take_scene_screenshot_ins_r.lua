require('base_ins_r')

---@class DataTakeSceneScreenshotInstruction : BaseInstruction
_class("DataTakeSceneScreenshotInstruction", BaseInstruction)
DataTakeSceneScreenshotInstruction = DataTakeSceneScreenshotInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataTakeSceneScreenshotInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local cMainCamera = world:MainCamera()
    ---@type UnityEngine.Camera
    local csCamera = cMainCamera:Camera()
    ---@type UnityEngine.RenderTexture
    local csRT = UnityEngine.RenderTexture:New(
        UnityEngine.Screen.width, 
        UnityEngine.Screen.height, 
        16
    )
    csCamera.targetTexture = csRT
    csCamera:Render()
    UnityEngine.RenderTexture.active = csRT
    --[[
        Texture2D构造的第三个参数省略了，因为那个枚举没有被wrap到lua。手册上看这个参数是可以省的。
        The texture will be width by height size, with an RGBA32 TextureFormat, with mipmaps and in sRGB color space.
        FYI: https://docs.unity.cn/2018.4/Documentation/ScriptReference/Texture2D-ctor.html
    ]]
    local csTex2d = UnityEngine.Texture2D:New(
        UnityEngine.Screen.width,
        UnityEngine.Screen.height
    )
    csTex2d:ReadPixels(UnityEngine.Rect:New(0, 0, UnityEngine.Screen.width, UnityEngine.Screen.height), 0, 0, false)
    csTex2d:Apply()

    -- revert changes to camera
    csCamera.targetTexture = nil
    UnityEngine.RenderTexture.active = nil
    csRT:Destroy()

    cMainCamera:SetScreenCameraScreenshot(csTex2d)
end
