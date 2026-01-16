--[[
    
]]
_class("BuffViewPlayBGM", BuffViewBase)
---@class BuffViewPlayBGM : BuffViewBase
BuffViewPlayBGM = BuffViewPlayBGM

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function BuffViewPlayBGM:PlayView(TT, notify)
    ---@type BuffResultPlayBGM
    local result = self._buffResult
    local bgmID = result:GetBGMID()
    local useLevelBGM = result:GetuseLevelBGM()

    if useLevelBGM and useLevelBGM == 1 then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type LevelConfigData
        local levelConfigData = configService:GetLevelConfigData()
        bgmID = levelConfigData:GetBgmID()
    end

    AudioHelperController.PlayBGMById(bgmID, AudioConstValue.BGMCrossFadeTime)
end

--是否匹配参数
function BuffViewPlayBGM:IsNotifyMatch(notify)
    return true
end
