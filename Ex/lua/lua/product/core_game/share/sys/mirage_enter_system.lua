--[[------------------------------------------------------------------------------------------
    MirageEnterSystem：主状态机进入幻境阶段的流程
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class MirageEnterSystem:MainStateSystem
_class("MirageEnterSystem", MainStateSystem)
MirageEnterSystem = MirageEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MirageEnterSystem:_GetMainStateID()
    return GameStateID.MirageEnter
end

---@param TT token 协程识别码，服务端是nil
function MirageEnterSystem:_OnMainStateEnter(TT)
    Log.info("MirageEnter:Begin")
    ---UI变化
    local initStepNum = self:_DoLogicMirageEnter()
    self:_DoRenderMirageEnterUI(TT, initStepNum)

    ---生成子弹机关
    local traps = self:_DoLogicMirageCreateTraps()

    ---显示子弹机关
    self:_DoRenderMirageShowTraps(TT, traps)

    ---计算子弹机关预警技能
    local warningTraps = self:_DoLogicMirageCastTrapWarningSkill()

    ---表现子弹机关预警技能
    self:_DoRenderMiragePlayTrapWarningSkill(TT, warningTraps)

    ---切换主状态机状态
    Log.info("MirageEnter:End")
    self:_DoLogicSwitchMainFsmState()
end

---获取幻境的初始步数
function MirageEnterSystem:_DoLogicMirageEnter()
    self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, true)
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    ---@type MirageComponent
    local mirageCmpt = mirageSvc:GetMirageComponent()

    return mirageCmpt:GetRemainRoundCount()
end

function MirageEnterSystem:_DoLogicMirageCreateTraps()
    local eTraps = {}

    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    eTraps = mirageSvc:DoMirageCreateTraps()

    return eTraps
end

function MirageEnterSystem:_DoLogicMirageCastTrapWarningSkill()
    ---@type MirageServiceLogic
    local mirageSvc = self.world:GetService("MirageLogic")
    return mirageSvc:DoMirageCastTrapWarningSkill()
end

---切换主状态
function MirageEnterSystem:_DoLogicSwitchMainFsmState()
    self._world:EventDispatcher():Dispatch(GameEventType.MirageEnterFinish, 1)
end

----------------------------------------------------------------------

---客户端的表现函数
function MirageEnterSystem:_DoRenderMirageEnterUI(TT, initStepNum)
end

function MirageEnterSystem:_DoRenderMirageShowTraps(TT, traps)
end

function MirageEnterSystem:_DoRenderMiragePlayTrapWarningSkill(TT, traps)
end
