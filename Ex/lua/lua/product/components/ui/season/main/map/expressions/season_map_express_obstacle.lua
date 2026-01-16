---@class SeasonMapExpressObstacle:SeasonMapExpressBase
_class("SeasonMapExpressObstacle", SeasonMapExpressBase)
SeasonMapExpressObstacle = SeasonMapExpressObstacle

function SeasonMapExpressObstacle:Constructor(cfg, eventPoint)
    self._content = self._cfg.Obstacle
end

function SeasonMapExpressObstacle:Update(deltaTime)
end

function SeasonMapExpressObstacle:Dispose()
end

--播放表现内容
function SeasonMapExpressObstacle:Play(param)
    SeasonMapExpressObstacle.super.Play(self, param)
    if self._content ~= nil then
        self._eventPoint:OpenObstacle(self._content)
        self._state = SeasonExpressState.Over
        self:_Next()
    end
end