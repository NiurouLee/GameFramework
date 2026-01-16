---@class SeasonInputManager:Object
_class("SeasonInputManager", Object)
SeasonInputManager = SeasonInputManager

function SeasonInputManager:Constructor()
end

function SeasonInputManager:OnInit(seasonID)
    if EDITOR or IsPc() then
        self._seasonInput = SeasonInputPc:New(seasonID)
    else
        self._seasonInput = SeasonInputMobile:New(seasonID)
    end
end

function SeasonInputManager:Update(deltaTime)
    self._seasonInput:Update(deltaTime)
end

function SeasonInputManager:Dispose()
    self._seasonInput:Dispose()
    self._seasonInput = nil
end

---@return SeasonInputBase
function SeasonInputManager:GetInput()
    return self._seasonInput
end

---@return boolean
function SeasonInputManager:GetClickUnLockZone()
    return self._seasonInput:GetClickUnLockZone()
end