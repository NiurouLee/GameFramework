--[[------------------------------------------------------------------------------------------
    MirageEndSystem：幻境结束
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class MirageEndSystem:MainStateSystem
_class("MirageEndSystem", MainStateSystem)
MirageEndSystem = MirageEndSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MirageEndSystem:_GetMainStateID()
    return GameStateID.MirageEnd
end

---@param TT token 协程识别码，服务端是nil
function MirageEndSystem:_OnMainStateEnter(TT)
    ---此处查看一下是否结束战斗
    local battleResult = self:_IsBattleEnd()
    if battleResult then
        self:_DoLogicSwitchMainFsmState()
        return
    end

    ---恢复对局UI
    self:_DoRenderMirageEndUI(TT)

    ---删除常驻子弹机关预警区
    self:_DoRenderMirageClearWarningArea(TT)

    ---检查是否需要进入强制结算
    local isForceEnd = self:_IsMirageForceEnd()
    if isForceEnd then
        ---@type Entity[]
        local eTraps = self:_DoLogicForceCastTrapSkill()
        self:_DoRenderForceCastTrapSkill(TT, eTraps)
    end

    ---此处查看一下是否结束战斗
    local battleResult = self:_IsBattleEnd()
    if battleResult then
        self:_DoLogicSwitchMainFsmState()
        return
    end

    ---释放子弹机关死亡技（销毁自身并在原位置召唤字符怪）
    ---@type Entity[]
    local eTraps = self:_DoLogicMirageCastTrapDieSkill()
    self:_DoRenderMiragePlayTrapDieSkill(TT, eTraps)

    ---幻境Boss进场
    ---@type Entity
    local bossEntity = self:_DoLogicMirageBossReturn()
    self:_DoRenderMirageBossReturn(TT, bossEntity)

    self:_DoLogicSwitchMainFsmState()
end

function MirageEndSystem:_IsMirageForceEnd()
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    return mirageSvc:IsMirageForceClose()
end

function MirageEndSystem:_DoLogicForceCastTrapSkill()
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    ---依旧调用机关的移动伤害技能，技能计算逻辑内使用剩余回合数*行动力去计算技能结果
    return mirageSvc:DoMirageCastTrapSkill()
end

function MirageEndSystem:_DoLogicSwitchMainFsmState()
    self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, false)
    self._world:EventDispatcher():Dispatch(GameEventType.MirageEndFinish, 1)
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    mirageSvc:SetMirageOver()
end

function MirageEndSystem:_DoLogicMirageCastTrapDieSkill()
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    return mirageSvc:DoMirageCastTrapDieSkill()
end

function MirageEndSystem:_DoLogicMirageBossReturn()
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    return mirageSvc:DoMirageBossReturn()
end

------------------------------------表现------------------------------------
function MirageEndSystem:_DoRenderMirageClearWarningArea(TT)
end

function MirageEndSystem:_DoRenderForceCastTrapSkill(TT, eTraps)
end

function MirageEndSystem:_DoRenderMiragePlayTrapDieSkill(TT, eTraps)
end

function MirageEndSystem:_DoRenderMirageBossReturn(TT, bossEntity)
end

function MirageEndSystem:_DoRenderMirageEndUI(TT)
end
