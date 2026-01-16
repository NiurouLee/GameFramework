---@class SeasonPlayerManager:Object
_class("SeasonPlayerManager", Object)
SeasonPlayerManager = SeasonPlayerManager

function SeasonPlayerManager:Constructor()
end

function SeasonPlayerManager:OnInit()
    ---@type SeasonPlayer
    self._seasonPlayer = SeasonPlayer:New()
end

function SeasonPlayerManager:Update(deltaTime)
    self._seasonPlayer:Update(deltaTime)
end

function SeasonPlayerManager:Dispose()
    self._seasonPlayer:Dispose()
    self._seasonPlayer = nil
end

---@return SeasonPlayer
function SeasonPlayerManager:GetPlayer()
    return self._seasonPlayer
end