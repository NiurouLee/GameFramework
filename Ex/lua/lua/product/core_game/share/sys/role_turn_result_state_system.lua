--[[------------------------------------------------------------------------------------------
    主状态机：普攻结算状态阶段处理system
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class RoleTurnResultStateSystem:MainStateSystem
_class("RoleTurnResultStateSystem", MainStateSystem)
RoleTurnResultStateSystem = RoleTurnResultStateSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function RoleTurnResultStateSystem:_GetMainStateID()
    return GameStateID.RoleTurnResult
end

---@param TT token 协程识别码，服务端是nil
function RoleTurnResultStateSystem:_OnMainStateEnter(TT)
    self:_DoLogicNotify()
    self:_DoRenderPlayNotify(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    self:_DoLogicNormalAttackMonsterDead() ---连锁技开始前要刷新一次普攻导致的怪物死亡
    self:_DoRenderNormalAttackMonsterDead(TT) --表现
    --如果普攻致死后有要必须等待的表现
    self:_WaitBeHitSkillFinish(TT)

    --还原普攻连线中临时设置的队长
    self:_DoRestoreTeamLeader(teamEntity)

    self:_DoRenderGuideSkill(TT) ---新手引导，连线结束
    -- 不等普攻致死的怪物死亡动画
    -- self:_DoRenderWaitDeathEnd(TT) ---先等待所有动画结束
    self:_DoRoleTurnResultEnd(teamEntity)
end

---------------------------------逻辑接口---------------------------
function RoleTurnResultStateSystem:_DoLogicNotify()
    self._world:GetService("Trigger"):Notify(NTRoleTurnResultState:New())
end
function RoleTurnResultStateSystem:_DoLogicNormalAttackMonsterDead()
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    sMonsterShowLogic:DoAllMonsterDeadLogic()

    ---统计本次普攻杀死的目标数量
    local deadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    local normalSkillKillCount = #deadGroup:GetEntities()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetNormalAttackKillCount(normalSkillKillCount)
end

function RoleTurnResultStateSystem:_DoRoleTurnResultEnd(teamEntity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local isTriggerDimension = boardServiceLogic:IsPlayerOnDimension(teamEntity)
    if isTriggerDimension then
        self._world:BattleStat():SetTriggerDimensionFlag(TriggerDimensionFlag.ChainAttack)
        self._world:EventDispatcher():Dispatch(GameEventType.RoleTurnResultFinish, 2)
    else
        self._world:EventDispatcher():Dispatch(GameEventType.RoleTurnResultFinish, 1)
    end
end

---还原普攻连线中临时设置的队长
function RoleTurnResultStateSystem:_DoRestoreTeamLeader(teamEntity)
    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    local teamLeaderEntityID = teamCmpt:GetOriginalTeamLeaderID()
    if teamLeaderEntityID then
        local teamLeaderEntity = self._world:GetEntityByID(teamLeaderEntityID)
        teamEntity:SetTeamLeaderPetEntity(teamLeaderEntity)
        teamCmpt:SetOriginalTeamLeaderID(nil)
    end
end

---------------------------------表现接口---------------------------
function RoleTurnResultStateSystem:_DoRenderPlayNotify(TT)
end
function RoleTurnResultStateSystem:_DoRenderNormalAttackMonsterDead(TT)
end

function RoleTurnResultStateSystem:_DoRenderGuideSkill(TT)
end

function RoleTurnResultStateSystem:_DoRenderWaitDeathEnd(TT)
end

function RoleTurnResultStateSystem:_WaitBeHitSkillFinish(TT)
end
