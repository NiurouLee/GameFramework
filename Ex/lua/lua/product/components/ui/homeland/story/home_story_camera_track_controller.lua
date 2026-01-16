--[[-------------------
    相机动画轨道播放控制
--]] -------------------

_class("HomeStoryCameraTrackController", Object)
---@class HomeStoryCameraTrackController:Object
HomeStoryCameraTrackController = HomeStoryCameraTrackController

---@param storyManager HomeStoryManager
function HomeStoryCameraTrackController:Constructor(storyManager)
    ---@type HomeStoryManager 剧情管理器
    self._storyManager = storyManager
    ---@type UnityEngine.RectTransform
    self._cameraTr = storyManager:GetStoryCamera()

    self:SetSceneCameraTr()

    ---@type table 当前小节轨道数据
    self._currentTrackData = nil
    ---@type table<int, boolean> 关键帧执行情况
    self._keyframeDone = {}
    ---@type table<table,number> 运行时动画数据
    self._animationData = {}

    -------------------------------
    --当前的虚拟机
    ---@type HomeStoryEntityCameraVC
    self._currentVC = nil
    ---@type Cinemachine.CinemachineBrain
    self._brain = self._cameraTr.gameObject:GetComponent(typeof(Cinemachine.CinemachineBrain))
    if not self._brain then
        self._brain = self._cameraTr.gameObject:AddComponent(typeof(Cinemachine.CinemachineBrain))
    end

    self._fiexdUpdateSetting = self._brain.m_BlendUpdateMethod

    self._cameraUpdateGo = UnityEngine.GameObject:New("test_camera_update_go")
    self._lateUpdatebBrain = self._cameraUpdateGo:AddComponent(typeof(Cinemachine.CinemachineBrain))
    self._lateUpdateSetting = self._lateUpdatebBrain.m_BlendUpdateMethod

    self._isFixedUpdate = true
end
function HomeStoryCameraTrackController:SetSceneCameraTr()
    if self._cameraTr then
        local dir = self._cameraTr:Find("ActorDir")
        ---@type UIHomelandModule
        local uiModule = GameGlobal.GetUIModule(HomelandModule)
        if uiModule then
            local homelandClient = uiModule:GetClient()
            if homelandClient then
                self._sceneMgr = homelandClient:SceneManager()
                self._sceneMgr:SetCustomLightTransform(dir)
            end
        end
    end
end
--设置虚拟机
function HomeStoryCameraTrackController:SetVCEntity(vce)
    if self._currentVC then
        self._currentVC:ActiveVC(false)
    end
    self._currentVC = vce
    if self._currentVC then
        self._currentVC:ActiveVC(true)
    end
end
---小节开始
function HomeStoryCameraTrackController:SectionStart(trackData)
    self._currentTrackData = trackData
end

---小节结束
function HomeStoryCameraTrackController:SectionEnd()
    self._currentTrackData = nil
    self._keyframeDone = {}
end

---更新轨道数据
---@param time number 当前小节时间
---@return boolean 当前track动画是否结束
function HomeStoryCameraTrackController:Update(time)
    if self._sceneMgr then
        self._sceneMgr:UpdateH3DRenderSetting()
    end
    if not self._currentTrackData then
        return true
    end

    local allTrackEnd = true
    if self._currentTrackData and self._currentTrackData.KeyFrames then
        for index, keyframe in ipairs(self._currentTrackData.KeyFrames) do
            if not self._keyframeDone[keyframe] then
                if time > keyframe.Time then
                    self:_TriggerKeyframe(keyframe)
                    self._keyframeDone[keyframe] = true
                else
                    allTrackEnd = false
                end
            end
        end
        allTrackEnd = self:_UpdateAnimation(time) and allTrackEnd
        return allTrackEnd
    else
        return true
    end
end
--
function HomeStoryCameraTrackController:DOShakeCamera(shakeData)
    
end
---@param keyframeData table
function HomeStoryCameraTrackController:_TriggerKeyframe(keyframeData)
    if keyframeData.Shake ~= nil then
        if DG.Tweening.DOTween.IsTweening(self._cameraTr) then
            Log.fatal("[Story] camera is shaking!")
        end

        local shakeData = keyframeData.Shake
        local tweener = self:DOShakeCamera()
            self._cameraTr:DOShakePosition(
            shakeData.Duration,
            Vector3(shakeData.Strength[1],shakeData.Strength[2],shakeData.Strength[3]),
            shakeData.Vibrato,
            0,
            false,
            shakeData.FadeOut
        )

        local aniInfo = {
            HomeStoryEntityAnimationType.Shake,
            keyframeData.Time,
            tweener
        }
        self._animationData[keyframeData.Shake] = aniInfo
    elseif keyframeData.StartShake then
        --循环震动需要修改，不放在mgr处理了，放在相机里

        --相机循环震动的开启与结束只在关键帧中触发，具体的更新逻辑在manager中，与普通的Shake互斥
        self._storyManager:StartLoopShake(keyframeData.StartShake)
    elseif keyframeData.StopShake then
        self._storyManager:StopLoopShake(keyframeData.StopShake)
    end

    if keyframeData.Position3D ~= nil then
        self:_SetPosition(Vector3(keyframeData.Position3D[1], keyframeData.Position3D[2], keyframeData.Position3D[3]))
    end

    if keyframeData.Rotation3D ~= nil then
        self:_SetRotation(Quaternion.Euler(keyframeData.Rotation3D[1], keyframeData.Rotation3D[2], keyframeData.Rotation3D[3]))
    end

    if keyframeData.Scaling3D ~= nil then
        self:_SetScaling(Vector3(keyframeData.Scaling3D, keyframeData.Scaling3D, keyframeData.Scaling3D))
    end

    if keyframeData.Translate3D then
        local aniInfo = {
            HomeStoryEntityAnimationType.Translate,
            keyframeData.Time,
            Vector3(keyframeData.Translate3D.StartValue[1], keyframeData.Translate3D.StartValue[2], keyframeData.Translate3D.StartValue[3]),
            Vector3(keyframeData.Translate3D.EndValue[1], keyframeData.Translate3D.EndValue[2], keyframeData.Translate3D.EndValue[3])
        }
        self._animationData[keyframeData.Translate3D] = aniInfo
    end

    if keyframeData.Rotate3D then
        local aniInfo = {
            HomeStoryEntityAnimationType.Rotate,
            keyframeData.Time,
            Quaternion.Euler(keyframeData.Rotate3D.StartValue[1], keyframeData.Rotate3D.StartValue[2], keyframeData.Rotate3D.StartValue[3]),
            Quaternion.Euler(keyframeData.Rotate3D.EndValue[1], keyframeData.Rotate3D.EndValue[2], keyframeData.Rotate3D.EndValue[3])
        }
        self._animationData[keyframeData.Rotate3D] = aniInfo
    end

    if keyframeData.Scale3D then
        local aniInfo = {
            HomeStoryEntityAnimationType.Scale,
            keyframeData.Time,
            Vector3(keyframeData.Scale3D.StartValue, keyframeData.Scale3D.StartValue, keyframeData.Scale3D.StartValue),
            Vector3(keyframeData.Scale3D.EndValue, keyframeData.Scale3D.EndValue, keyframeData.Scale3D.EndValue)
        }
        self._animationData[keyframeData.Scale3D] = aniInfo
    end

    --切换镜头
    if keyframeData.VC then
        self:SetVC(keyframeData.VC)
    end

    if keyframeData.LateUpdate then
        self:SetUpdateType(true)
    else
        self:SetUpdateType(false)
    end
end
function HomeStoryCameraTrackController:SetUpdateType(lateUpdate)
    if lateUpdate then
        if self._isFixedUpdate then
            self._brain.m_BlendUpdateMethod = self._lateUpdateSetting
            self._isFixedUpdate = false
        end
    else
        if not self._isFixedUpdate then
            self._brain.m_BlendUpdateMethod = self._fiexdUpdateSetting
            self._isFixedUpdate = true
        end
    end
end
--切换镜头
function HomeStoryCameraTrackController:SetVC(vcData)
    local vcEntityID = vcData.EntityID
    if vcEntityID == -1 then
        self:SetVCEntity(nil)
    else
        local vcEntity = self._storyManager:GetEntity(vcEntityID)
        --设置过度状态
        ---@type Cinemachine.CinemachineBlendDefinition
        local style = Cinemachine.CinemachineBlendDefinition.Style.Cut
        if vcData.Style == 0 then
            style = Cinemachine.CinemachineBlendDefinition.Style.Cut
        elseif vcData.Style == 1 then
            style = Cinemachine.CinemachineBlendDefinition.Style.EaseInOut
        elseif vcData.Style == 2 then
            style = Cinemachine.CinemachineBlendDefinition.Style.EaseIn
        elseif vcData.Style == 3 then
            style = Cinemachine.CinemachineBlendDefinition.Style.EaseOut
        elseif vcData.Style == 4 then
            style = Cinemachine.CinemachineBlendDefinition.Style.HardIn
        elseif vcData.Style == 5 then
            style = Cinemachine.CinemachineBlendDefinition.Style.HardOut
        elseif vcData.Style == 6 then
            style = Cinemachine.CinemachineBlendDefinition.Style.Linear
        elseif vcData.Style == 7 then
            style = Cinemachine.CinemachineBlendDefinition.Style.Custom
        end
        local duration = vcData.Duration
        
        local info = Cinemachine.CinemachineBlendDefinition:New(style,duration)

        self._brain.m_DefaultBlend = info

        self:SetVCEntity(vcEntity)
    end
end
---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function HomeStoryCameraTrackController:_UpdateAnimation(time)
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

        if aniInfo[1] == HomeStoryEntityAnimationType.Shake then
            if not aniInfo[3]:IsComplete() then
                allEnd = false
            end
        elseif aniInfo[1] == HomeStoryEntityAnimationType.Translate then
            self:_SetPosition(Vector3.Lerp(aniInfo[3], aniInfo[4], t))
        elseif aniInfo[1] == HomeStoryEntityAnimationType.Rotate then
            self:_SetRotation(Quaternion.Lerp(aniInfo[3], aniInfo[4], t))
        elseif aniInfo[1] == HomeStoryEntityAnimationType.Scale then
            self:_SetScaling(Vector3.Lerp(aniInfo[3], aniInfo[4], t))
        end

        if t >= 1 then
            self._animationData[aniData] = nil
        end
    end
    return allEnd
end

---位置
---@param pos Vector3
function HomeStoryCameraTrackController:_SetPosition(pos)
    self._cameraTr.localPosition = pos
end

---旋转
---@param pos Quaternion
function HomeStoryCameraTrackController:_SetRotation(rot)
    self._cameraTr.localRotation = rot
end

---缩放
---@param pos Vector3
function HomeStoryCameraTrackController:_SetScaling(scale)
    self._cameraTr.localScale = scale
end
--脱离小节的update，为了做轨道和fov动画添加
--在这里update虚拟机位的entity的动画update
function HomeStoryCameraTrackController:OnUpdate(dms)
    if self._currentVC then
        self._currentVC:OnUpdate(dms)
    end
end

_class("HomeStoryCameraShake", Object)
---@class HomeStoryCameraShake:Object
HomeStoryCameraShake = HomeStoryCameraShake
---@param vc Cinemachine.CinemachineVirtualCamera
function HomeStoryCameraShake:Constructor(vc,shakeData)
    ---@type Cinemachine.CinemachineVirtualCamera
    self._vc = vc
    self._vc.enabled = nil
end