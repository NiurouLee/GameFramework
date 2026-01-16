---@class SeasonMapExpressLockInput:SeasonMapExpressBase
_class("SeasonMapExpressLockInput", SeasonMapExpressBase)
SeasonMapExpressLockInput = SeasonMapExpressLockInput

function SeasonMapExpressLockInput:Constructor(cfg, eventPoint)
    self._content = self._cfg.LockInput
end

function SeasonMapExpressLockInput:Update(deltaTime)
end

function SeasonMapExpressLockInput:Dispose()
end

--播放表现内容
function SeasonMapExpressLockInput:Play(param)
    SeasonMapExpressLockInput.super.Play(self, param)
    if self._content ~= nil then
        ---@type SeasonManager
        local seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
        if self._content == true then
            seasonManager:Lock("LockInput")
        elseif self._content == false then
            seasonManager:UnLock("LockInput")
        end
        self._state = SeasonExpressState.Over
        self:_Next()
    end
end