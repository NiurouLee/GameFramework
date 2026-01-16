--[[------------------------------------------------------------------------------------------
    PopStarBattleResultSystem_Logic：服务端重写部分战斗结算逻辑
]]
--------------------------------------------------------------------------------------------

require "pop_star_battle_result_system"

---@class PopStarBattleResultSystem_Logic:PopStarBattleResultSystem
_class("PopStarBattleResultSystem_Logic", PopStarBattleResultSystem)
PopStarBattleResultSystem_Logic = PopStarBattleResultSystem_Logic

function PopStarBattleResultSystem_Logic:_DoLogicBattleResult()
    ---服务器会计算出结果，放到某个地方，然后同步给客户端
    self._world:BattleStat():SetBattleMatchResult(self.battleMatchResult)


    ---根据条件确定是否再次启动一次“测试局内”
    ---@type ServerWorld
    local serverWorld = self._world
    ---@type CoreGameLogic
    local pCoreGameLogic = serverWorld:GetCoreGameLogic()
    pCoreGameLogic:OnServerMatchEnd()
end
