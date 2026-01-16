--[[------------------
    Spine剧情元素
--]] ------------------

_class("StoryEntitySpine", StoryEntityMovable)
---@class StoryEntitySpine:StoryEntityMovable
StoryEntitySpine = StoryEntitySpine

---@class StorySpineEntityAnimationType
local StorySpineEntityAnimationType = {
    Dissolve = 1
}
_enum("StorySpineEntityAnimationType", StorySpineEntityAnimationType)

function StoryEntitySpine:Constructor(ID, gameObject, resRequest, storyManager, entityConfig)
    StoryEntitySpine.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    ---@type number StoryEntityType
    self._type = StoryEntityType.Spine
    ---@type Spine.Unity.SkeletonGraphic spine骨骼
    self._spineSke = gameObject:GetComponentInChildren(typeof(Spine.Unity.SkeletonGraphic))
    ---@type Spine.Unity.Modules.SkeletonGraphicMultiObject
    self._spineSkeMultipleTex = gameObject:GetComponentInChildren(typeof(Spine.Unity.Modules.SkeletonGraphicMultiObject))
    ---@type table<string, string> config
    self._entityConfig = entityConfig
    ---@type boolean 是否是说话状态
    self._isSpeaking = false
    ---@type color spine颜色 用于控制透明和明暗
    self._spineColor = nil
    ---@type table<int, UnityEngine.Material> 实例化的材质
    self._matInsList = {}

    ---@type ResRequest EMI效果shader及所需贴图所在材质的resRequest
    self._EMIMatResRequest = nil
    ---@type UnityEngine.Material EMI效果材质
    self._EMIMat = nil

    ---@type ResRequest Dissolve效果shader及所需贴图所在材质的resRequest
    self._DissolveMatResRequest = nil

    ---@type UnityEngine.Material Dissolve效果材质
    self._DissolveMat = nil

    ---@type table<table,number> 运行时动画数据
    self._spineAnimationData = {}

    ---@type OutlineComponent 描边
    self._outLine = nil
    self._outLineIntensity = 2.5
    if self._spineSke then
        --self._spineSke.AnimationState.Data.DefaultMix = 0
        if entityConfig.Effect == "EMI" then
            self._spineSke.material = UnityEngine.Material:New(self._spineSke.material)

            self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("spine_graphic_dc.mat", LoadType.Mat)
            self._EMIMat = self._EMIMatResRequest.Obj
            self._spineSke.material.shader = self._EMIMat.shader
            self._spineSke.material:SetTexture("_NoiseTex", self._EMIMat:GetTexture("_NoiseTex"))
        elseif entityConfig.Effect == "DISSOLVE" then
            self._spineSke.material = UnityEngine.Material:New(self._spineSke.material)

            self._DissolveMatResRequest =
                ResourceManager:GetInstance():SyncLoadAsset("spine_graphic_dissolve.mat", LoadType.Mat)
            self._DissolveMat = self._DissolveMatResRequest.Obj
            self._spineSke.material.shader = self._DissolveMat.shader
            self._spineSke.material:SetTexture("_MaskTex", self._DissolveMat:GetTexture("_MaskTex"))
        end

        self._spineColor = self._spineSke.color
        self._spineSke.AnimationState:SetAnimation(0, "Story_norm", true)
    elseif self._spineSkeMultipleTex then
        if entityConfig.Effect == "EMI" then
            self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("spine_dc.mat", LoadType.Mat)
            self._EMIMat = self._EMIMatResRequest.Obj

            self._spineSkeMultipleTex.UseInstanceMaterials = true
            self._spineSkeMultipleTex.OnInstanceMaterialCreated = function(material)
                self:HandleMultipleTexSpineMatCreated(material)
            end
            self._spineSkeMultipleTex:UpdateMesh()
        end

        if self._spineSkeMultipleTex.Skeleton then
            self._spineColor =
                Color(
                self._spineSkeMultipleTex.Skeleton.R,
                self._spineSkeMultipleTex.Skeleton.G,
                self._spineSkeMultipleTex.Skeleton.B,
                self._spineSkeMultipleTex.Skeleton.A
            )
        else
            self._spineColor = Color.white
        end
        self._spineSkeMultipleTex.AnimationState:SetAnimation(0, "Story_norm", true)
    --self._spineSkeMultipleTex.AnimationState.Data.DefaultMix = 0
    end

    if not self._spineColor then
        self._spineColor = Color.white
    end
end

function StoryEntitySpine:HandleMultipleTexSpineMatCreated(material)
    if self._entityConfig.Effect == "EMI" then
        material.shader = self._EMIMat.shader
        material:SetTexture("_NoiseTex", self._EMIMat:GetTexture("_NoiseTex"))
    end
end

---资源销毁
function StoryEntitySpine:Destroy()
    StoryEntitySpine.super.Destroy(self)
    for i = 1, #self._matInsList do
        UnityEngine.Object.Destroy(self._matInsList[i])
    end
    self._matInsList = {}

    if self._EMIMatResRequest then
        self._EMIMat = nil
        self._EMIMatResRequest:Dispose()
        self._EMIMatResRequest = nil
    end

    if self._DissolveMatResRequest then
        self._DissolveMat = nil
        self._DissolveMatResRequest:Dispose()
        self._DissolveMatResRequest = nil
    end
    if self._spineSkeMultipleTex then
        self._spineSkeMultipleTex.OnInstanceMaterialCreated = nil
    end
end

---@param keyframeData table
function StoryEntitySpine:_TriggerKeyframe(keyframeData)
    StoryEntitySpine.super._TriggerKeyframe(self, keyframeData)

    local spineSke = nil
    if self._spineSke then
        spineSke = self._spineSke
    elseif self._spineSkeMultipleTex then
        spineSke = self._spineSkeMultipleTex
    else
        return
    end
    
    if not spineSke.AnimationState then
        return
    end

    if keyframeData.LoopAnimation ~= nil then
        if spineSke then
            spineSke.AnimationState:SetAnimation(0, keyframeData.LoopAnimation, true)
        end
    end

    if keyframeData.Animation ~= nil then
        if spineSke then
            spineSke.AnimationState:SetAnimation(0, keyframeData.Animation, false)
        end
    end

    if keyframeData.Dissolve ~= nil and self._entityConfig.Effect == "DISSOLVE" then
        local aniInfo = {
            StorySpineEntityAnimationType.Dissolve,
            keyframeData.Time,
            keyframeData.Dissolve.StartValue,
            keyframeData.Dissolve.EndValue
        }
        self._spineAnimationData[keyframeData.Dissolve] = aniInfo

    end

    if keyframeData.TilingSize ~= nil then
        self:_SetTilingSize(keyframeData.TilingSize)
    end
    
    if keyframeData.FullScreen ~= nil then
        if keyframeData.FullScreen then
            self:_SetSpineFullScreen()
        else
            self._storyManager:SetUIBlackSideSize(0, 0)
        end
    end

    if keyframeData.OutLine ~= nil then
        self:_AddOutLineComponent()
    end

    if keyframeData.SpineSkin ~= nil then
        spineSke.Skeleton:SetSkin(keyframeData.SpineSkin)
    end
end

function StoryEntitySpine:_SetSpineFullScreen()
    if not self._gameObject then
        return
    end

    ---@type UnityEngine.Transform
    local transfrom = self._gameObject.transform

    -- 全屏spine资源固定长宽为2532/1170
    local fullPicWidth = 2532
    local fullPicHeight = 1170

    local screenWidth, screenHeight = self._storyManager:GetUICanvasSize()

    local spineAspect = fullPicWidth / fullPicHeight
    local screenAspect = screenWidth / screenHeight

    local spineScale = 1
    local blackSideHeight = 0
    local blackSideWidth = 0

    if screenAspect < spineAspect then
        spineScale = screenWidth / fullPicWidth
        local picHeight = fullPicHeight * screenWidth / fullPicWidth
        blackSideHeight = math.abs(screenHeight - picHeight) / 2
    elseif screenAspect > spineAspect then
        spineScale = screenHeight / fullPicHeight
        local picWidth = fullPicWidth * screenHeight / fullPicHeight
        blackSideWidth = math.abs(screenWidth - picWidth) / 2
    else
        spineScale = screenHeight / fullPicHeight
    end

    transfrom.localScale = Vector3(spineScale, spineScale, 1)
    self._storyManager:SetUIBlackSideSize(blackSideWidth, blackSideHeight)
end

---动画处理----
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryEntitySpine:_UpdateAnimation(time)
    local baseEnd = StoryEntitySpine.super._UpdateAnimation(self, time)

    local allEnd = true
    for aniData, aniInfo in pairs(self._spineAnimationData) do
        allEnd = false
        local t = 1
        if aniData.Duration > 0 then
            t = (time - aniInfo[2]) / aniData.Duration
        end
        if t > 1 then
            t = 1
        end

        if aniInfo[1] == StorySpineEntityAnimationType.Dissolve then
            self:_SetDissolve(lmathext.lerp(aniInfo[3], aniInfo[4], t))
        end

        if t >= 1 then
            self._spineAnimationData[aniData] = nil
        end
    end
    return allEnd and baseEnd
end

---设置spine说话状态，如果进入说话状态，则表情动作更换为说话的表情动作，并且后续表情变化也是根据这个状态来设置动作
---@param speaking boolean
function StoryEntitySpine:SetSpeak(speaking)
    local spineSke = nil
    if self._spineSke then
        spineSke = self._spineSke
    elseif self._spineSkeMultipleTex then
        spineSke = self._spineSkeMultipleTex
    else
        return
    end

    self._isSpeaking = speaking

    ---缺省表情动作名和循环设置
    local curAnimName = "normal"
    local loop = true
    local track = spineSke.AnimationState:GetCurrent(1)
    if track then
        curAnimName = track.Animation.Name
        loop = track.Loop
    end

    --临时测试代码 因为没有合适的spine资源
    if self._isSpeaking ~= string.equal_with_ignorecase(curAnimName, "shoot") then
        if self._isSpeaking then
            spineSke.AnimationState:SetAnimation(1, "shoot", loop)
        else
            spineSke.AnimationState:SetAnimation(1, "aim", loop)
        end
    end

    --[[ 正式代码
    if self._isSpeaking ~= string.endwith(curAnimName, "_speak") then
        if self._isSpeaking then
            spineSke.AnimationState:SetAnimation(1, curAnimName.."_speak", loop)
        else
            spineSke.AnimationState:SetAnimation(1, string.sub(curAnimName, 1, string.len(curAnimName) - 6), loop)
        end
    end]]
end

function StoryEntitySpine:_SetDissolve(value)
    self._spineSke.material:SetFloat("_Dissovle", value)
end
function StoryEntitySpine:_SetTilingSize(value)
    self._spineSke.material:SetFloat("_TilingSize", value)
end
---override----
---透明度设置
---@param alpha number
function StoryEntitySpine:_SetAlpha(alpha)
    self._spineColor.a = alpha
    if self._spineSke then
        self._spineSke.color = self._spineColor
        if self._outLine then
            self._outLine.intensity = self._outLineIntensity
        end
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.A = alpha
        if self._outLine then
            self._outLine.intensity = self._outLineIntensity * alpha
        end
    end
end

---明暗度设置
---@param brightness number
function StoryEntitySpine:_SetBrightness(brightness)
    self._spineColor:Set(brightness, brightness, brightness, self._spineColor.a)
    if self._spineSke then
        self._spineSke.color = self._spineColor
        if self._outLine then
            self._outLine.intensity = self._outLineIntensity
        end
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.R = brightness
        self._spineSkeMultipleTex.Skeleton.G = brightness
        self._spineSkeMultipleTex.Skeleton.B = brightness
        if self._outLine then
            self._outLine.intensity = self._outLineIntensity * brightness
        end
    end
end
---------------
function StoryEntitySpine:_AddOutLineComponent()
    if APPVER125 then
        self._outLine = self._gameObject:GetComponent(typeof(OutlineComponent))
        if not self._outLine then
            self._outLine = self._gameObject:AddComponent(typeof(OutlineComponent))
        end
        local camera = GameGlobal.UIStateManager():GetControllerCamera("UIStoryController")
        if camera then
            self._outLine.blurNum = 3
            self._outLine.intensity = self._outLineIntensity
            self._outLine.outlineSize = 1
            self._outLine.blendType = OutlineComponent.BlendType.Blend
            self._outLine.m_CustomCamera = camera
        else
            self._outLine.enabled = false
        end
    end
end

function StoryEntitySpine:GetMaterial()
    if self._spineSke then
        return self._spineSke.material
    end
    if self._spineSkeMultipleTex then
        if self._spineSkeMultipleTex.material then
            return self._spineSkeMultipleTex.material
        else
            if self._spineSkeMultipleTex.canvasRenderers.Count > 0 then
                local materials = {}
                for i = 0, self._spineSkeMultipleTex.canvasRenderers.Count - 1 do
                    local material = self._spineSkeMultipleTex.canvasRenderers[i]:GetMaterial()
                    if material then
                        table.insert(materials, material)
                    end
                end
                if #materials > 0 then
                    return materials
                end
            end
        end
    end
    return nil
end