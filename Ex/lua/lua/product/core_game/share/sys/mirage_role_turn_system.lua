--[[------------------------------------------------------------------------------------------
    MirageRoleTurnSystem：幻境阶段的角色回合 用于处理角色移动
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class MirageRoleTurnSystem:MainStateSystem
_class("MirageRoleTurnSystem", MainStateSystem)
MirageRoleTurnSystem = MirageRoleTurnSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MirageRoleTurnSystem:_GetMainStateID()
    return GameStateID.MirageRoleTurn
end

---@param TT token 协程识别码，服务端是nil
function MirageRoleTurnSystem:_OnMainStateEnter(TT)
    Log.info("MirageRoleTurnSystem:Begin")
    self:_DoLogicMirageMove()
    self:_DoRenderMirageMove(TT)

    --状态切换
    self:_DoLogicSwitchMainFsmState()
end

function MirageRoleTurnSystem:_DoLogicMirageMove()
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    mirageSvc:DoMirageCalculateTeamMove()
end

function MirageRoleTurnSystem:_DoLogicSwitchMainFsmState()
    ---@type MirageServiceLogic
    local mirageSvc = self.world:GetService("MirageLogic")
    ---幻境倒计时是否结束（强制终止幻境）
    local isForceClose = mirageSvc:IsMirageForceClose()
    if isForceClose then
        self._world:EventDispatcher():Dispatch(GameEventType.MirageRoleTurnFinish, 2)
        return
    end

    self._world:EventDispatcher():Dispatch(GameEventType.MirageRoleTurnFinish, 1)
end

----------------------------表现接口--------------------------------------
function MirageRoleTurnSystem:_DoRenderMirageMove(TT)
end
