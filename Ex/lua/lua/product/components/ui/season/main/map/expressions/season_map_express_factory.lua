---@class SeasonMapExpressFactory:Singleton
_class("SeasonMapExpressFactory", Singleton)
SeasonMapExpressFactory = SeasonMapExpressFactory

function SeasonMapExpressFactory:Constructor()
    self._express = {}
    self:_Register()
end

---@param expressType SeasonExpressType
---@param express SeasonMapExpressBase
function SeasonMapExpressFactory:_RegistorExpress(expressType, express)
    ---@type SeasonMapExpressBase
    local e = self._express[expressType]
    if nil ~= e then
        Log.error("SeasonMapExpress is exist! expressType:", expressType)
        return
    end
    self._express[expressType] = express
end

---@param eventPoint SeasonMapEventPoint
---@param expressType SeasonExpressType
---@return SeasonMapExpressBase
function SeasonMapExpressFactory:CreateMapExpress(eventPoint, expressType, cfg)
    ---@type SeasonMapExpressBase
    local type = self._express[expressType]
    if not type then
        Log.error( "SeasonMapExpress is not exist! expressType:", expressType)
        return
    end
    local express = type:New(cfg, eventPoint)
    if not express then
        Log.error("SeasonMapExpress create fail! expressType:", expressType)
        return
    end
    return express
end

function SeasonMapExpressFactory:_Register()
    self:_RegistorExpress(SeasonExpressType.Level, SeasonMapExpressLevel)
    self:_RegistorExpress(SeasonExpressType.Animation, SeasonMapExpressAnimation)
    self:_RegistorExpress(SeasonExpressType.Effect, SeasonMapExpressEffect)
    self:_RegistorExpress(SeasonExpressType.Story, SeasonMapExpressStory)
    self:_RegistorExpress(SeasonExpressType.Bubble, SeasonMapExpressBubble)
    self:_RegistorExpress(SeasonExpressType.Reward, SeasonMapExpressReward)
    self:_RegistorExpress(SeasonExpressType.Show, SeasonMapExpressShow)
    self:_RegistorExpress(SeasonExpressType.Obstacle, SeasonMapExpressObstacle)
    self:_RegistorExpress(SeasonExpressType.Focus, SeasonMapExpressFocus)
    self:_RegistorExpress(SeasonExpressType.LockInput, SeasonMapExpressLockInput)
    self:_RegistorExpress(SeasonExpressType.Sign, SeasonMapExpressSign)
end
