---@class SeasonMapExpressSign:SeasonMapExpressBase
_class("SeasonMapExpressSign", SeasonMapExpressBase)
SeasonMapExpressSign = SeasonMapExpressSign

function SeasonMapExpressSign:Constructor(cfg, eventPoint)
    self._content = self._cfg.Sign
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
end

function SeasonMapExpressSign:Update(deltaTime)
end

function SeasonMapExpressSign:Dispose()
end

--播放表现内容
function SeasonMapExpressSign:Play(param)
    SeasonMapExpressSign.super.Play(self, param)
    if self._content then
        ---@type SeasonSignType
        local signType = self._content.type
        if signType == SeasonSignType.Play then
            local seasonUI = self._seasonManager:SeasonUIManager():UI()
            local show = self._content.show
            if show then
                seasonUI:AddSign(self._eventPoint, self)
            else
                seasonUI:RemoveSign(self._eventPoint)
            end
        end
        self._state = SeasonExpressState.Over
        self:_Next()
    end
end