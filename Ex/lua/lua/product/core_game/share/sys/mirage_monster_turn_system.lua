--[[------------------------------------------------------------------------------------------
    MirageMonsterTurnSystem 幻境子处理子弹机关行动state的system
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

_class("MirageMonsterTurnSystem", MainStateSystem)
---@class MirageMonsterTurnSystem:MainStateSystem
MirageMonsterTurnSystem = MirageMonsterTurnSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MirageMonsterTurnSystem:_GetMainStateID()
    return GameStateID.MirageMonsterTurn
end

---@param TT token 协程识别码，服务端是nil
function MirageMonsterTurnSystem:_OnMainStateEnter(TT)
    Log.info("MirageMonsterTurnSystem:Begin")

    ---显示怪物回合信息
    self:_DoRenderHidePetInfo(TT)

    ---删除常驻子弹机关预警区
    self:_DoRenderMirageClearWarningArea(TT)

    ---计算子弹机关技能伤害和位移
    local traps = self:_DoLogicMirageCastTrapSkill()
    ---表现子弹机关技能伤害和位移
    self:_DoRenderMiragePlayTrapSkill(TT, traps)

    ---此处查看一下是否结束战斗
    local battleResult = self:_IsBattleEnd()
    if battleResult then
        self:_SwitchToRoundResult()
        return
    end

    ---计算子弹机关预警技能
    local warningTraps = self:_DoLogicMirageCastTrapWarningSkill()
    ---表现子弹机关预警技能
    self:_DoRenderMiragePlayTrapWarningSkill(TT, warningTraps)

    Log.info("MirageMonsterTurnSystem:End")
    self:_DoLogicSwitchMainFsmState()
end

-----------------------------逻辑接口------------------------------

function MirageMonsterTurnSystem:_DoLogicSwitchMainFsmState()
    ---@type MirageServiceLogic
    local mirageSvc = self.world:GetService("MirageLogic")

    ---幻境倒计时是否结束（强制终止幻境）
    local isForceClose = mirageSvc:IsMirageForceClose()
    if isForceClose then
        self._world:EventDispatcher():Dispatch(GameEventType.MirageMonsterTurnFinish, 2)
        return
    end

    local IsMirageOpen = mirageSvc:IsMirageOpen()
    if IsMirageOpen then
        self._world:EventDispatcher():Dispatch(GameEventType.MirageMonsterTurnFinish, 1)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.MirageMonsterTurnFinish, 2)
    end
end

function MirageMonsterTurnSystem:_SwitchToRoundResult()
    self._world:EventDispatcher():Dispatch(GameEventType.MirageMonsterTurnFinish, 2)
end

function MirageMonsterTurnSystem:_DoLogicMirageCastTrapSkill()
    ---@type MirageServiceLogic
    local mirageSvc = self.world:GetService("MirageLogic")
    return mirageSvc:DoMirageCastTrapSkill()
end

function MirageMonsterTurnSystem:_DoLogicMirageCastTrapWarningSkill()
    ---@type MirageServiceLogic
    local mirageSvc = self.world:GetService("MirageLogic")
    return mirageSvc:DoMirageCastTrapWarningSkill()
end

------------------------------表现接口-------------------------------------
function MirageMonsterTurnSystem:_DoRenderHidePetInfo(TT)
end

function MirageMonsterTurnSystem:_DoRenderMirageClearWarningArea(TT)
end

function MirageMonsterTurnSystem:_DoRenderMiragePlayTrapSkill(TT, traps)
end

function MirageMonsterTurnSystem:_DoRenderMiragePlayTrapWarningSkill(TT, traps)
end
