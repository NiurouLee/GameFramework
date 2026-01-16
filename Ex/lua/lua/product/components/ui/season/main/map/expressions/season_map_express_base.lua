---@class SeasonMapExpressBase:Object
_class("SeasonMapExpressBase", Object)
SeasonMapExpressBase = SeasonMapExpressBase

function SeasonMapExpressBase:Constructor(cfg, eventPoint)
    ---@type cfg_season_map_express
    self._cfg = cfg
    ---@type SeasonMapEventPoint
    self._eventPoint = eventPoint
    ---@type SeasonExpressState
    self._state = SeasonExpressState.NotStart
    self._content = nil
    self._param = nil
end

---@return SeasonExpressType
function SeasonMapExpressBase:ExpressType()
    return self._cfg.ExpressType
end

function SeasonMapExpressBase:Content()
    return self._content
end

function SeasonMapExpressBase:Update(deltaTime)
end

function SeasonMapExpressBase:Dispose()
    self._param = nil
end

function SeasonMapExpressBase:Play(param)
    self._param = param
end

function SeasonMapExpressBase:_Next()
    self._eventPoint:PlayNextExpress(self._param)
end

function SeasonMapExpressBase:Reset()
    self._state = SeasonExpressState.NotStart
end

---@return SeasonExpressState
function SeasonMapExpressBase:State()
    return self._state
end