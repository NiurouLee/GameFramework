---@class SeasonMapExpressShow:SeasonMapExpressBase
_class("SeasonMapExpressShow", SeasonMapExpressBase)
SeasonMapExpressShow = SeasonMapExpressShow

function SeasonMapExpressShow:Constructor(cfg, eventPoint)
    self._content = self._cfg.Show
end

function SeasonMapExpressShow:Update(deltaTime)
end

function SeasonMapExpressShow:Dispose()
end

--播放表现内容
function SeasonMapExpressShow:Play(param)
    SeasonMapExpressShow.super.Play(self, param)
    if self._content ~= nil then
        self._eventPoint:ExpressShow(self._content)
        self._state = SeasonExpressState.Over
        self:_Next()
    end
end