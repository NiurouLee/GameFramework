---@class HomelandFishMatchManager:Singleton
_class("HomelandFishMatchManager", Singleton)
HomelandFishMatchManager = HomelandFishMatchManager

-- 钓鱼比赛类型
--- @enum HomelandFishingGameType
local HomelandFishingGameType = {
    Pet = 5, --光灵
    TaskNpc = 3, -- 任务Npc
}
_enum("HomelandFishingGameType", HomelandFishingGameType)

function HomelandFishMatchManager:Constructor()
    ---@type  HomelandFishMatch
    self._fishmatch = nil
end

function HomelandFishMatchManager:GetMatchItem(cfg,pet,istask)
    local match = HomelandFishMatch:New(cfg,pet,istask)
    return match
end

function HomelandFishMatchManager:GetCurFishMatch()
    return self._fishmatch
end

function HomelandFishMatchManager:ChangeMatch(match)
    if self._fishmatch then 
        self._fishmatch:PetMatchCancel()
        if self._fishmatch:IsTask() then
        else 
            self._fishmatch:PetSetBornPos()
        end 
        self._fishmatch:Dispose()
        self._fishmatch = nil 
    end 
    self._fishmatch = match
end

function HomelandFishMatchManager:Dispose()
    if self._fishmatch then 
        self._fishmatch:Dispose()
        self._fishmatch = nil 
    end 
end

function HomelandFishMatchManager:IsInTaskMatchState()
    if not self._fishmatch then 
        return false 
    end 
    if self._fishmatch:IsTask() then
       return true
    end 
    return false 
end