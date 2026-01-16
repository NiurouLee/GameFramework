--[[------------------
    Spine切片剧情元素
--]]------------------

_class("StoryEntitySpineSlice", StoryEntityMovable)
---@class StoryEntitySpineSlice:Object
StoryEntitySpineSlice = StoryEntitySpineSlice

---@param gameObject UnityEngine.GameObject
function StoryEntitySpineSlice:Constructor(ID, gameObject, resRequest, storyManager, entityConfig)
    StoryEntitySpineSlice.super.Constructor(self, ID, gameObject, resRequest, storyManager)
    ---@type number StoryEntityType
    self._type = StoryEntityType.SpineSlice
    ---@type UnityEngine.GameObject spine节点
    self._spineGameObject = gameObject
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
    
    if self._spineSke then
        self._spineSke.material = UnityEngine.Material:New(self._spineSke.material)

        if entityConfig.Effect == "EMI" then
            self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("spine_graphic_dc.mat", LoadType.Mat)
            self._EMIMat = self._EMIMatResRequest.Obj
            self._spineSke.material.shader = self._EMIMat.shader
            self._spineSke.material:SetTexture("_NoiseTex", self._EMIMat:GetTexture("_NoiseTex"))
        end

        self._spineSke.material:SetFloat("_StencilComp", 3)
        self._matInsList[1] = self._spineSke.material
        self._spineColor = self._spineSke.color
        self._spineSke.AnimationState:SetAnimation(0, "Story_norm", true)
    elseif self._spineSkeMultipleTex then
        self._spineSkeMultipleTex.UseInstanceMaterials = true

        if entityConfig.Effect == "EMI" then
            self._EMIMatResRequest = ResourceManager:GetInstance():SyncLoadAsset("spine_dc.mat", LoadType.Mat)
            self._EMIMat = self._EMIMatResRequest.Obj
        end

        self._spineSkeMultipleTex.OnInstanceMaterialCreated = function(material)
            self:HandleMultipleTexSpineMatCreated(material)
        end

        self._spineSkeMultipleTex:UpdateMesh()

        if self._spineSkeMultipleTex.Skeleton then
            self._spineColor = Color(
                self._spineSkeMultipleTex.Skeleton.R,
                self._spineSkeMultipleTex.Skeleton.G,
                self._spineSkeMultipleTex.Skeleton.B,
                self._spineSkeMultipleTex.Skeleton.A
            )
        else
            self._spineColor = Color.white
        end
        self._spineSkeMultipleTex.AnimationState:SetAnimation(0, "Story_norm", true)
    end
    
    if not self._spineColor then
        self._spineColor = Color.white
    end

    ---@type number 切片宽度 默认350
    self._defaultSliceWidth = 350
    self._sliceWidth = 350
    ---@type number 切片高度 默认1438
    self._sliceHeight = 1438
    
    ---空父节点 一级子节点是mask节点 二级子节点是原始spine节点
    local rootGO = UnityEngine.GameObject:New(gameObject.name)
    rootGO.transform:SetParent(gameObject.transform.parent, false)
    rootGO.transform.localPosition = gameObject.transform.localPosition
    rootGO:SetActive(gameObject.activeSelf)
    self._gameObject = rootGO

    ---@type UnityEngine.GameObject Mask节点
    self._maskObject = UnityEngine.GameObject.Instantiate(storyManager:GetSpineSliceMaskTemplate(), rootGO.transform)
    self._maskObject:SetActive(true)
    self._maskObject.transform.localPosition = Vector3.zero
    gameObject.transform:SetParent(self._maskObject.transform, false)
    gameObject:SetActive(true)
end

function StoryEntitySpineSlice:HandleMultipleTexSpineMatCreated(material)
    material:SetFloat("_StencilComp", 3)
    
    if self._entityConfig.Effect == "EMI" then
        material.shader = self._EMIMat.shader
        material:SetTexture("_NoiseTex", self._EMIMat:GetTexture("_NoiseTex"))
    end
end

---资源销毁
function StoryEntitySpineSlice:Destroy()
    StoryEntitySpineSlice.super.Destroy(self)
    for i = 1, #self._matInsList do
        UnityEngine.Object.Destroy(self._matInsList[i])
    end
    self._matInsList = {}

    if self._EMIMatResRequest then
        self._EMIMat = nil
        self._EMIMatResRequest:Dispose()
        self._EMIMatResRequest = nil
    end
end

---@param keyframeData table
function StoryEntitySpineSlice:_TriggerKeyframe(keyframeData)
    StoryEntitySpineSlice.super._TriggerKeyframe(self, keyframeData)

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

    if keyframeData.SpineOffset then
        self:_SetSpinePosition(Vector3(keyframeData.SpineOffset[1],keyframeData.SpineOffset[2],0))
    end

    if keyframeData.SliceWidthScale then
        self._sliceWidth = self._defaultSliceWidth * keyframeData.SliceWidthScale
    end    

    if keyframeData.SpineSkin ~= nil then
        spineSke.Skeleton:SetSkin(keyframeData.SpineSkin)
    end

    if keyframeData.Scroll ~= nil then
        self._inScrolling = true
        self._scrollStartFromCover = keyframeData.Scroll.StartFromCover
        self._scrollType = StoryPictureScrollType[keyframeData.Scroll.Toward]
        self._scrollStartTime = keyframeData.Time
        self._scrollDuration = keyframeData.Scroll.Duration
        
        local maskRect = self._maskObject:GetComponent("RectTransform")
        local spineRect = self._spineGameObject:GetComponent("RectTransform")
        ---卷轴动画初始化处理
        if self._scrollStartFromCover then
            if self._scrollType == StoryPictureScrollType.LeftToRight or self._scrollType == StoryPictureScrollType.RightToLeft or self._scrollType == StoryPictureScrollType.HorizontalSpread  then
                maskRect.sizeDelta = Vector2(0, self._sliceHeight)
             elseif self._scrollType == StoryPictureScrollType.UpToDown or self._scrollType == StoryPictureScrollType.DownToUp or self._scrollType == StoryPictureScrollType.VerticalSpread then
                maskRect.sizeDelta = Vector2(self._sliceWidth, 0)
            elseif self._scrollType == StoryPictureScrollType.Spread then
                maskRect.sizeDelta = Vector2.zero
            end
        else
            maskRect.sizeDelta = Vector2(self._sliceWidth, self._sliceHeight)
        end

        if (self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.LeftToRight) or (not self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.RightToLeft) then
            maskRect.pivot = Vector2(0, 0.5)
            maskRect.transform.localPosition = Vector3( -self._sliceWidth / 2, maskRect.transform.localPosition.y, maskRect.transform.localPosition.z )
            spineRect.anchorMin = Vector2(0, 0.5)
            spineRect.anchorMax = Vector2(0, 0.5)
            if self._scrollStartFromCover then
                spineRect.transform.localPosition = Vector3(spineRect.transform.localPosition.x+self._sliceWidth / 2, spineRect.transform.localPosition.y, spineRect.transform.localPosition.z )
            end
        elseif (self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.RightToLeft) or (not self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.LeftToRight) then
            maskRect.pivot = Vector2(1, 0.5)
            maskRect.transform.localPosition = Vector3(self._sliceWidth / 2, maskRect.transform.localPosition.y, maskRect.transform.localPosition.z)
            spineRect.anchorMin = Vector2(1, 0.5)
            spineRect.anchorMax = Vector2(1, 0.5)
            if self._scrollStartFromCover then
                spineRect.transform.localPosition = Vector3(spineRect.transform.localPosition.x-self._sliceWidth / 2, spineRect.transform.localPosition.y, spineRect.transform.localPosition.z)
            end
        elseif (self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.UpToDown) or (not self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.DownToUp) then
            maskRect.pivot = Vector2(0.5, 1)
            maskRect.transform.localPosition = Vector3(maskRect.transform.localPosition.x, self._sliceHeight / 2, maskRect.transform.localPosition.z )
            local offset = 0
            if spineRect.anchorMin == Vector2(0.5, 1) then
                offset = 0
            elseif spineRect.anchorMin == Vector2(0.5, 0) then
                offset = self._sliceHeight
            else
                offset = self._sliceHeight / 2
            end
            spineRect.anchorMin = Vector2(0.5, 1)
            spineRect.anchorMax = Vector2(0.5, 1)
            if self._scrollStartFromCover then
                spineRect.transform.localPosition = Vector3( spineRect.transform.localPosition.x, spineRect.transform.localPosition.y - offset, spineRect.transform.localPosition.z )
            end
        elseif (self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.DownToUp) or (not self._scrollStartFromCover and self._scrollType == StoryPictureScrollType.UpToDown) then
            maskRect.pivot = Vector2(0.5, 0)
            maskRect.transform.localPosition = Vector3( maskRect.transform.localPosition.x, -self._sliceHeight / 2, maskRect.transform.localPosition.z )
            local offset = 0
            if spineRect.anchorMin == Vector2(0.5, 0) then
                offset = 0
            elseif spineRect.anchorMin == Vector2(0.5, 1) then
                offset = self._sliceHeight
            else
                offset = self._sliceHeight / 2
            end
            spineRect.anchorMin = Vector2(0.5, 0)
            spineRect.anchorMax = Vector2(0.5, 0)
            if self._scrollStartFromCover then
                spineRect.transform.localPosition = Vector3( spineRect.transform.localPosition.x, spineRect.transform.localPosition.y + offset, spineRect.transform.localPosition.z)
            end
        elseif self._scrollType == StoryPictureScrollType.Spread then
        elseif self._scrollType == StoryPictureScrollType.HorizontalSpread then
        elseif self._scrollType == StoryPictureScrollType.VerticalSpread then
        end
    end
end

---设置spine说话状态，如果进入说话状态，则表情动作更换为说话的表情动作，并且后续表情变化也是根据这个状态来设置动作
---@param speaking boolean
function StoryEntitySpineSlice:SetSpeak(speaking)

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

---Spine位置
---@param pos Vector3
function StoryEntitySpineSlice:_SetSpinePosition(pos)
    self._spineGameObject.transform.localPosition = pos
end

---override----
---动画处理----
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryEntitySpineSlice:_UpdateAnimation(time)
    local baseAllEnd = StoryEntitySpineSlice.super._UpdateAnimation(self, time)
    --[[
    local allEnd = true
    for aniData, aniInfo in pairs(self._animationData) do
        allEnd = false
        local t = 1
        if aniData.Duration > 0 then
            t = (time - aniInfo[2]) / aniData.Duration
        end
        if t > 1 then 
            t = 1
        end 

        if aniInfo[1] == StoryEntityAnimationType.AlphaChange then
            self:_SetAlpha(lmathext.lerp(aniInfo[3], aniInfo[4], t))
        end

        if t >= 1 then
            self._animationData[aniData] = nil
        end
    end]]

    if self._inScrolling and self._scrollType then
        local t = 1
        if self._scrollDuration > 0 then
            t = (time - self._scrollStartTime) / self._scrollDuration
        end
        if t > 1 then
            t = 1
        end

        if not self._maskRect then
            self._maskRect = self._maskObject:GetComponent("RectTransform")
        end

        local effectT = t
        if not self._scrollStartFromCover then
            effectT = 1 - effectT
        end

        if
            self._scrollType == StoryPictureScrollType.LeftToRight or
                self._scrollType == StoryPictureScrollType.RightToLeft or
                self._scrollType == StoryPictureScrollType.HorizontalSpread
         then
            self._maskRect.sizeDelta = Vector2(lmathext.lerp(0, self._sliceWidth, effectT), self._sliceHeight)
        elseif
            self._scrollType == StoryPictureScrollType.UpToDown or self._scrollType == StoryPictureScrollType.DownToUp or
                self._scrollType == StoryPictureScrollType.VerticalSpread
         then
            self._maskRect.sizeDelta = Vector2(self._sliceWidth, lmathext.lerp(0, self._sliceHeight, effectT))
        elseif self._scrollType == StoryPictureScrollType.Spread then
            self._maskRect.sizeDelta =
                Vector2(lmathext.lerp(0, self._sliceWidth, effectT), lmathext.lerp(0, self._sliceHeight, effectT))
        end

        if t >= 1 then
            self._inScrolling = false
        end
        return false
    else
        return baseAllEnd
    end
end

---透明度设置
---@param alpha number
function StoryEntitySpineSlice:_SetAlpha(alpha)
    self._spineColor.a = alpha
    if self._spineSke then
        self._spineSke.color = self._spineColor
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.A = alpha
    end
end

---明暗度设置
---@param brightness number
function StoryEntitySpineSlice:_SetBrightness(brightness)
    self._spineColor:Set(brightness, brightness, brightness, self._spineColor.a)
    if self._spineSke then
        self._spineSke.color = self._spineColor
    elseif self._spineSkeMultipleTex and self._spineSkeMultipleTex.Skeleton then
        self._spineSkeMultipleTex.Skeleton.R = brightness
        self._spineSkeMultipleTex.Skeleton.G = brightness
        self._spineSkeMultipleTex.Skeleton.B = brightness
    end
end

---旋转
---@param pos Quaternion
function StoryEntitySpineSlice:_SetRotation(rot)
    self._spineGameObject.transform.localRotation = rot
end

---缩放
---@param pos Vector3
function StoryEntitySpineSlice:_SetScaling(scale)
    self._spineGameObject.transform.localScale = scale
end

function StoryEntitySpineSlice:GetMaterial()
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