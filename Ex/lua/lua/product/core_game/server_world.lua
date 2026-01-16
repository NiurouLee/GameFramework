--[[------------------------------------------------------------------------------------------
    服务端消除游戏世界
]] --------------------------------------------------------------------------------------------
require "main_world"

---@class ServerWorld:MainWorld
_class("ServerWorld", MainWorld)
ServerWorld = ServerWorld

---@param worldInfo WorldCreationContext
---@param coreGameLogic CoreGameLogic
function ServerWorld:Constructor(worldInfo, coreGameLogic)
    ---@type CoreGameLogic
    self._coreGameLogic = coreGameLogic

    ---@type WorldRunPostion
    self._runningPosition = WorldRunPostion.AtServer

    ---@type GameEventDispatcher
    self._gameEventDispatcher = GameEventDispatcher:New()

    self._gameEventListenerIDGenerator = IDGenerator:New(IDGeneratorType.GAME_EVENT_LISTENER_FIRST_ID)
end

function ServerWorld:GetCoreGameLogic()
    return self._coreGameLogic
end

function ServerWorld:IsDevelopEnv()
    --return Log.loglevel < ELogLevel.None
    --return self._coreGameLogic:GetServerLuaGMConfig()
    return self._coreGameLogic:GetServerLuaLogConfig()
end

--服务端环境下用的eventdispatcher是world自己创建的
---@return GameEventDispatcher
function ServerWorld:EventDispatcher()
    return self._gameEventDispatcher
end

function ServerWorld:HandleCommand(cmd)
    ---@type Entity
    local e = self:GetEntityByID(cmd.EntityID)
    if e then
        e:ReceiveCommand(cmd)
    else
        Log.fatal("ServerWorld:HandleCommand can not find entity ID=", cmd.EntityID)
    end
end

function ServerWorld:IDGenerator()
    return self._gameEventListenerIDGenerator
end

function ServerWorld:HandleSyncFailed(failedType, failedMsg)
    if self._coreGameLogic then
        ---@type BattleService
        local battleServer = self:GetService("Battle")
        ---@type MatchResult
        local result = battleServer:CalcBattleResultLogic(self._coreGameLogic._matchType, false)
        
        result.exception = true
        if failedType then
            result.exception_code = failedType
        end
        if failedMsg then
            result.exception_msg = failedMsg
        end
        self._coreGameLogic:SetResult(result)
        self._coreGameLogic:GameOver()
    end
end

------------------------------------------------------------------------------------------
---下面是测试用的代码
------------------------------------------------------------------------------------------

---@return CehuaMatchLogic
function ServerWorld:FindCehuaMatch()
    ---@type CoreGameLogic
    local pCoreGameLogic = self:GetCoreGameLogic()
    if nil == pCoreGameLogic then
        return nil
    end
    ---@type CoreGameManager
    local pCoreGameManager = pCoreGameLogic:GetCoreGameMng()
    if nil == pCoreGameManager then
        return nil
    end
    local nMatchID = pCoreGameLogic:GetMatchID()
    return pCoreGameManager:FindCehuaMatch(nMatchID)
end
