--[[------------------
    Sound剧情元素
--]]------------------

_class("HomeStoryEntitySound", HomeStoryEntity)
---@class HomeStoryEntitySound:HomeStoryEntity
HomeStoryEntitySound = HomeStoryEntitySound

function HomeStoryEntitySound:Constructor(ID, resourceName, storyManager) --audioClip, resRequest, storyManager)
    HomeStoryEntitySound.super.Constructor(self, ID, nil, nil, storyManager)
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
    ---@type HomeStoryEntityType
    self._type = HomeStoryEntityType.Sound

    ---@type number 播放索引
    self._soundPlayingID = -1
    ---@type boolean 循环
    self._loop = false

    ---注册音效资源
    AudioHelperController.RequestUISoundSync(tonumber(resourceName))
end

function HomeStoryEntitySound:PlaySound()
    self._soundPlayingID = AudioHelperController.PlayUISoundResource(self._resName, self._loop)
end

function HomeStoryEntitySound:StopSound()
    AudioHelperController.StopUISound(self._soundPlayingID)
end

function HomeStoryEntitySound:PlayBgm(bgmFadeTime)
    AudioHelperController.PlayBGM(self._resName, bgmFadeTime)
end

---关键帧处理---
---@param keyframeData table
function HomeStoryEntitySound:_TriggerKeyframe(keyframeData)

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
function HomeStoryEntitySound:Destroy()
    HomeStoryEntitySound.super.Destroy(self)
    AudioHelperController.StopUISound(self._soundPlayingID)
    AudioHelperController.ReleaseUISoundResource(self._resName)
end