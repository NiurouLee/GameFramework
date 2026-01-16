--[[------------------------------------------------------------------------------------------
    ServerBattleResultSystem_Logic：服务端重写部分战斗结算逻辑
]] --------------------------------------------------------------------------------------------

require "battle_result_system"

---@class ServerBattleResultSystem_Logic:BattleResultSystem
_class("ServerBattleResultSystem_Logic", BattleResultSystem)
ServerBattleResultSystem_Logic = ServerBattleResultSystem_Logic

function ServerBattleResultSystem_Logic:_DoLogicBattleResult()
    ---服务器会计算出结果，放到某个地方，然后同步给客户端
    self._world:BattleStat():SetBattleMatchResult(self.battleMatchResult)

    
    ---根据条件确定是否再次启动一次“测试局内”
    ---@type ServerWorld
    local serverWorld = self._world
    ---@type CoreGameLogic
    local pCoreGameLogic = serverWorld:GetCoreGameLogic()
    pCoreGameLogic:OnServerMatchEnd()
end
