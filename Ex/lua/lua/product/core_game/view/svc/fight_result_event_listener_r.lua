--[[------------------------------------------------------------------------------------------
**********************************************************************************************
    对局里负责监听gamematchmodule发过来的战斗结果事件
**********************************************************************************************
]] --------------------------------------------------------------------------------------------

---@class FightResultEventListenerRender : Object
_class("FightResultEventListenerRender",Object)
FightResultEventListenerRender = FightResultEventListenerRender

---@param world ClientWorld
---@param autoBinder AutoEventBinder
function FightResultEventListenerRender:Constructor(world,autoBinder)
    ---@type ClientWorld
    self._world = world

    autoBinder:BindEvent(GameEventType.MissionFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.ExtMissionFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.ResDungeonFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.TowerFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.MazeFightResult, self, self.OnCommonFightResult)
    --传说光灵
    autoBinder:BindEvent(GameEventType.TalePetFightResult, self, self.OnCommonFightResult)
    --迷失之地
    autoBinder:BindEvent(GameEventType.LostAreaFightResult, self, self.OnCommonFightResult)
    --活动
    autoBinder:BindEvent(GameEventType.CampaignFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.ConquestFightResult, self, self.OnCommonFightResult)
    autoBinder:BindEvent(GameEventType.BlackFistResult, self, self.OnCommonFightResult)
end

---@param result MissionResult
function FightResultEventListenerRender:OnCommonFightResult(result)
    if result == true then
        ---通知对局结束状态、并通知UI
        GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleResultFinish, result)
    else
        GameGlobal.TaskManager():CoreGameStartTask(self._WaitPlayerDeadTask, self, result)
    end
end

---等待玩家死亡
function FightResultEventListenerRender:_WaitPlayerDeadTask(TT, battleRes)
    local playerEntity = self._world:Player():GetLocalTeamEntity()
    if playerEntity then
        local teamLeaderEntity = playerEntity:GetTeamLeaderPetEntity()
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        --只有被打死才播放死亡动画。守护目标死亡 时间结束未达成目标 都不会播放死亡动画
        if utilData:PlayerIsDead(playerEntity) then
            local deadTriggerParam = "Death"
            local deadAnimName = "death"
            ---@type ViewComponent
            local viewCmpt = teamLeaderEntity:View()
            local playerObj = viewCmpt:GetGameObject()
            local animTimeLen = GameObjectHelper.GetActorAnimationLength(playerObj, deadAnimName)
            teamLeaderEntity:SetAnimatorControllerTriggers({ deadTriggerParam })
            YIELD(TT, animTimeLen * 1000)
            Log.debug("EventListenerServiceRender:_WaitPlayerDeadTask ", battleRes)
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleResultFinish, battleRes)
end