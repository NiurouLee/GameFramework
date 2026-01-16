--[[------------------
    Sound剧情元素
--]]------------------

_class("StoryEntitySound", StoryEntity)
---@class StoryEntitySound:Object
StoryEntitySound = StoryEntitySound

function StoryEntitySound:Constructor(ID, resourceName, storyManager) --audioClip, resRequest, storyManager)
    StoryEntitySound.super.Constructor(self, ID, nil, nil, storyManager)
    ---@type number EntityID
    self._ID = ID
    --[[
    ---@type UnityEngine.AudioClip 元素的unity对象
    self._audioClip = audioClip
    ---@type ResRequest 资源句柄
    self._resRequest = resRequest
    ]]
    ---@type resName 资源名
    self._resName = resourceName
    ---@type StoryManager 剧情管理器
    self._storyManager = storyManager
    ---@type number StoryEntityType
    self._type = StoryEntityType.Sound

    ---@type number 播放索引
    self._soundPlayingID = -1
    ---@type boolean 循环
    self._loop = false

    ---注册音效资源
    AudioHelperController.RequestUISoundSync(tonumber(resourceName))
end

function StoryEntitySound:PlaySound()
    self._soundPlayingID = AudioHelperController.PlayUISoundResource(self._resName, self._loop)
end

function StoryEntitySound:StopSound()
    AudioHelperController.StopUISound(self._soundPlayingID)
end

function StoryEntitySound:PlayBgm(bgmFadeTime)
    AudioHelperController.PlayBGM(self._resName, bgmFadeTime)
end

---关键帧处理---
---@param keyframeData table
function StoryEntitySound:_TriggerKeyframe(keyframeData)

    if keyframeData.PlaySound ~= nil then
        if keyframeData.PlaySound == "Loop" then
            self._loop = true
        else
            self._loop = false
        end

        self:PlaySound()
    end

    if keyframeData.StopSound ~= nil then
        AudioHelperController.StopUISound(self._soundPlayingID)
    end
end

---资源销毁
function StoryEntitySound:Destroy()
    StoryEntitySound.super.Destroy(self)
    AudioHelperController.StopUISound(self._soundPlayingID)
    AudioHelperController.ReleaseUISoundResource(self._resName)
end