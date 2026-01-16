--[[------------------------------------------------------------------------------------------
    FirstWaveEnterSystem：主状态机阶段
    第一波怪物刷出来后，玩家行动之前，也就是WaveEnterSystem之后，WaitInput之前
    所以AfterFirstWaveEnterSystem更合适
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class FirstWaveEnterSystem:MainStateSystem
_class("FirstWaveEnterSystem", MainStateSystem)
FirstWaveEnterSystem = FirstWaveEnterSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function FirstWaveEnterSystem:_GetMainStateID()
    return GameStateID.FirstWaveEnter
end

---@param TT token 协程识别码，服务端环境下是nil
function FirstWaveEnterSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    --开场UI
    self:_DoRenderShowUIBattleStart(TT, teamEntity)


    --开场buff
    local buffseqs = self:_DoLogicGameStart()

    --buff表现
    self:_DoRenderAutoAddBuff(TT, buffseqs)

    --怪物死亡处理，逻辑
    self:_DoLogicMonsterDead()

    --怪物死亡表现
    self:_DoRenderMonsterDead(TT)

    ---清理入场特效等资源
    self:_DoRendeDestroyBattleEnterResource(TT)

    self:_DologicGotoNextState()
end

function FirstWaveEnterSystem:_DoLogicGameStart()
    if not self._isGameStart then
        self._isGameStart = true
        --对局开始触发
        local GameStartBuffs={}
        self._world:GetService("Battle"):InitWordBuff(GameStartBuffs)
        self._world:GetService("Battle"):InitTalePetBuff(GameStartBuffs)
        self._world:GetService("Affix"):InitAffixBuff(GameStartBuffs)
        self._world:GetService("Talent"):InitTalentBuff(GameStartBuffs)
        self._world:GetService("Trigger"):Notify(NTGameStart:New())
        return GameStartBuffs
    end
end


function FirstWaveEnterSystem:_DologicGotoNextState()
    self._world:EventDispatcher():Dispatch(GameEventType.FirstWaveEnterFinish, 1)
end
----------------------------------表现接口-----------------------------------

---显示 UIBattleStart
function FirstWaveEnterSystem:_DoRenderShowUIBattleStart(TT, teamEntity)
end

function FirstWaveEnterSystem:_DoRenderAutoAddBuff(TT, buffseqs)
end

function FirstWaveEnterSystem:_DoRendeDestroyBattleEnterResource(TT)
end

