--[[------------------------------------------------------------------------------------------
    BaseService 局内service的基类
]] --------------------------------------------------------------------------------------------

_class("BaseService", Object)
---@class BaseService:Object
BaseService = BaseService

function BaseService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type MathService
    self._mathService = self._world:GetService("Math")

    ---@type WorldRunPostion
    local runPos = self._world:GetRunningPosition()
    if runPos == WorldRunPostion.AtServer then
        ---@type ServerWorld
        local serverWorld = self._world
        self._eventDispatcher = serverWorld:EventDispatcher()
    else
        self._eventDispatcher = GameGlobal.EventDispatcher()
    end
end

---@return BattleStatComponent
function BaseService:_GetBattleStatComponent()
    return self._world:BattleStat()
end

---@return GameEventDispatcher
function BaseService:_GetEventDispatcher()
    return self._eventDispatcher
end

function BaseService:_GetRandomNumber(m, n)
    ---@type RandomServiceLogic
    local randomService = self._world:GetService("RandomLogic")
    return randomService:LogicRand(m, n)
end

function BaseService:GetBoardRandomNumber(m, n)
    ---@type RandomServiceLogic
    local randomService = self._world:GetService("RandomLogic")
    return randomService:BoardLogicRand(m, n)
end

function BaseService:GetService(name)
    return self._world:GetService(name)
end

function BaseService:GetMatchType()
    return self._world:MatchType()
end

function BaseService:LogNotice(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.debug(self._className, " ", ...)
    end
end

function BaseService:LogWarn(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.warn(self._className, " ", ...)
    end
end

function BaseService:LogError(...)
    Log.error(self._className, " ", ...)
end

function BaseService:ThrowException(...)
    Log.exception(self._className, " ", ...)
end
