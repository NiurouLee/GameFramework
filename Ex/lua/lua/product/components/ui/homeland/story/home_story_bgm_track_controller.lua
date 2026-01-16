--[[-------------------
    剧情Bgm轨道播放控制
--]]-------------------

_class("HomeStoryBgmTrackController", Object)
---@class HomeStoryBgmTrackController:Object
HomeStoryBgmTrackController = HomeStoryBgmTrackController

function HomeStoryBgmTrackController:Constructor(storyManager)
    ---@type HomeStoryManager 剧情管理器
    self._storyManager = storyManager
    ---@type table 当前小节轨道数据
    self._currentTrackData = nil
    ---@type table<int, boolean> 关键帧执行情况
    self._keyframeDone = {}
    
    ---配置内容
    ---@type number bgm过渡时间 (秒)
    self._bgmFadeTime = 0.5
end

---小节开始
function HomeStoryBgmTrackController:SectionStart(trackData)
    self._currentTrackData = trackData
end

---小节结束
function HomeStoryBgmTrackController:SectionEnd()
    self._currentTrackData = nil    
    self._keyframeDone = {}
end

---更新轨道数据
---@param time number 当前小节时间
---@return boolean 当前track动画是否结束
function HomeStoryBgmTrackController:Update(time)
    if not self._currentTrackData then
        return true
    end

    for index, keyframe in ipairs(self._currentTrackData.KeyFrames) do
        if not self._keyframeDone[keyframe] then
            if time > keyframe.Time then
                if keyframe.StartBgm ~= nil then
                    self._storyManager:PlayBgm(keyframe.StartBgm, keyframe.FadeTime or self._bgmFadeTime)
                end
                if keyframe.StopBgm ~= nil then
                    AudioHelperController.StopBGM(keyframe.FadeTime or self._bgmFadeTime)
                end
                self._keyframeDone[keyframe] = true
            end
        end
    end
    
    return true
end