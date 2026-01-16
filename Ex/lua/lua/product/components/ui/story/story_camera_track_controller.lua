--[[-------------------
    相机动画轨道播放控制
--]] -------------------

_class("StoryCameraTrackController", Object)
---@class StoryCameraTrackController:Object
StoryCameraTrackController = StoryCameraTrackController

function StoryCameraTrackController:Constructor(storyManager)
    ---@type StoryManager 剧情管理器
    self._storyManager = storyManager
    ---@type UnityEngine.Transform 剧情UI根节点的transform
    self._storyUIRootTrans = storyManager:GetStoryUIRoot().transform
    ---@type table 当前小节轨道数据
    self._currentTrackData = nil
    ---@type table<int, boolean> 关键帧执行情况
    self._keyframeDone = {}
    ---@type table<table,number> 运行时动画数据
    self._animationData = {}
end

---小节开始
function StoryCameraTrackController:SectionStart(trackData)
    self._currentTrackData = trackData
end

---小节结束
function StoryCameraTrackController:SectionEnd()
    self._currentTrackData = nil
    self._keyframeDone = {}
end

---更新轨道数据
---@param time number 当前小节时间
---@return boolean 当前track动画是否结束
function StoryCameraTrackController:Update(time)
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

---@param keyframeData table
function StoryCameraTrackController:_TriggerKeyframe(keyframeData)
    if keyframeData.Shake ~= nil and not self._storyManager:IsJumping() then
        if DG.Tweening.DOTween.IsTweening(self._storyUIRootTrans) then
            Log.fatal("[Story] camera is shaking!")
        end

        local shakeData = keyframeData.Shake
        local tweener =
            self._storyUIRootTrans:DOShakePosition(
            shakeData.Duration,
            Vector3(shakeData.Strength[1], shakeData.Strength[2], 0),
            shakeData.Vibrato,
            0,
            false,
            shakeData.fadeOut
        )

        local aniInfo = {
            StoryEntityAnimationType.Shake,
            keyframeData.Time,
            tweener
        }
        self._animationData[keyframeData.Shake] = aniInfo
    elseif keyframeData.StartShake then
        --相机循环震动的开启与结束只在关键帧中触发，具体的更新逻辑在manager中，与普通的Shake互斥
        self._storyManager:StartLoopShake(keyframeData.StartShake)
    elseif keyframeData.StopShake then
        self._storyManager:StopLoopShake(keyframeData.StopShake)
    end

    if keyframeData.Position ~= nil then
        self:_SetPosition(Vector3(-keyframeData.Position[1], -keyframeData.Position[2], 0))
    end

    if keyframeData.Rotation ~= nil then
        self:_SetRotation(Quaternion.Euler(0, 0, -keyframeData.Rotation))
    end

    if keyframeData.Scaling ~= nil then
        self:_SetScaling(Vector3(1 / keyframeData.Scaling, 1 / keyframeData.Scaling, 1))
    end

    if keyframeData.Translate then
        local aniInfo = {
            StoryEntityAnimationType.Translate,
            keyframeData.Time,
            Vector3(-keyframeData.Translate.StartValue[1], -keyframeData.Translate.StartValue[2], 0),
            Vector3(-keyframeData.Translate.EndValue[1], -keyframeData.Translate.EndValue[2], 0)
        }
        self._animationData[keyframeData.Translate] = aniInfo
    end

    if keyframeData.Rotate then
        local aniInfo = {
            StoryEntityAnimationType.Rotate,
            keyframeData.Time,
            Quaternion.Euler(0, 0, -keyframeData.Rotate.StartValue),
            Quaternion.Euler(0, 0, -keyframeData.Rotate.EndValue)
        }
        self._animationData[keyframeData.Rotate] = aniInfo
    end

    if keyframeData.Scale then
        local aniInfo = {
            StoryEntityAnimationType.Scale,
            keyframeData.Time,
            Vector3(1 / keyframeData.Scale.StartValue, 1 / keyframeData.Scale.StartValue, 1),
            Vector3(1 / keyframeData.Scale.EndValue, 1 / keyframeData.Scale.EndValue, 1)
        }
        self._animationData[keyframeData.Scale] = aniInfo
    end
end

---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryCameraTrackController:_UpdateAnimation(time)
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

        if aniInfo[1] == StoryEntityAnimationType.Shake then
            if not aniInfo[3]:IsComplete() then
                allEnd = false
            end
        elseif aniInfo[1] == StoryEntityAnimationType.Translate then
            self:_SetPosition(Vector3.Lerp(aniInfo[3], aniInfo[4], t))
        elseif aniInfo[1] == StoryEntityAnimationType.Rotate then
            self:_SetRotation(Quaternion.Lerp(aniInfo[3], aniInfo[4], t))
        elseif aniInfo[1] == StoryEntityAnimationType.Scale then
            self:_SetScaling(Vector3.Lerp(aniInfo[3], aniInfo[4], t))
        elseif aniInfo[1] == StoryEntityAnimationType.Shake then
            if self._storyManager:IsJumping() then
                aniInfo[3]:Kill(true)
                self._animationData[aniData] = nil
            end
        end

        if t >= 1 then
            self._animationData[aniData] = nil
        end
    end
    return allEnd
end

---位置
---@param pos Vector3
function StoryCameraTrackController:_SetPosition(pos)
    self._storyUIRootTrans.localPosition = pos
end

---旋转
---@param pos Quaternion
function StoryCameraTrackController:_SetRotation(rot)
    self._storyUIRootTrans.localRotation = rot
end

---缩放
---@param pos Vector3
function StoryCameraTrackController:_SetScaling(scale)
    self._storyUIRootTrans.localScale = scale
end
