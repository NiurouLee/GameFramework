--[[
    剧情元素类 
    包括：对话框 spine 图片 特效 音效 
    其中：spine 图片 特效 继承于通用可控制运动的剧情元素
]]
_class("StoryEntity", Object)
---@class StoryEntity:Object
StoryEntity = StoryEntity

function StoryEntity:Constructor(ID, gameObject, resRequest, storyManager)
    ---@type number EntityID
    self._ID = ID
    ---@type UnityEngine.GameObject 元素的unity对象
    self._gameObject = gameObject
    ---@type ResRequest 资源句柄
    self._resRequest = resRequest
    ---@type StoryManager 剧情管理器
    self._storyManager = storyManager
    ---@type number StoryEntityType
    self._Type = StoryEntityType.Invalid
    ---@type table 当前小节轨道数据
    self._currentTrackData = nil
    ---@type table<int, boolean> 关键帧执行情况
    self._keyframeDone = {}
end

---@return StoryEntityType
function StoryEntity:GetEntityType()
    return self._type
end

function StoryEntity:GetID()
    return self._ID
end

---@param keyframeData table
function StoryEntity:_TriggerKeyframe(keyframeData)
end

---@param time number
---@return boolean 是否已经播放完全部的轨道动画
function StoryEntity:_UpdateAnimation(time)
    return true
end

---更新动画
---@param time number 当前小节时间
---@return boolean 当前track动画是否结束
function StoryEntity:Update(time)
    local allTrackEnd = true
    if self._currentTrackData and self._currentTrackData.KeyFrames then
        for index, keyframe in ipairs(self._currentTrackData.KeyFrames) do
            if not self._keyframeDone[keyframe] then
                if time >= keyframe.Time then
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

---小节开始
function StoryEntity:SectionStart(trackData)
    self._currentTrackData = trackData
end

---小节结束
function StoryEntity:SectionEnd()
    self._currentTrackData = nil    
    self._keyframeDone = {}
end

---资源销毁
function StoryEntity:Destroy()
    if self._resRequest ~= nil then
        self._resRequest:Dispose()
        self._resRequest = nil
    end
end