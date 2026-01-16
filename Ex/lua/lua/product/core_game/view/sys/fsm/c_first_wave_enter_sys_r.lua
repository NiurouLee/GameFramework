--[[------------------------------------------------------------------------------------------
    ClientFirstWaveEnterSystem_Render：客户端实现的等待输入表现
]] --------------------------------------------------------------------------------------------

require "first_wave_enter_system"

---@class ClientFirstWaveEnterSystem_Render:FirstWaveEnterSystem
_class("ClientFirstWaveEnterSystem_Render", FirstWaveEnterSystem)
ClientFirstWaveEnterSystem_Render = ClientFirstWaveEnterSystem_Render

--region UIBattleStart
function ClientFirstWaveEnterSystem_Render:Constructor(world)
    self._onClickUIBonusInfo = GameHelper:GetInstance():CreateCallback(self.OnClickUIBonusInfo, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnClickUIBonusInfo, self._onClickUIBonusInfo)
end

function ClientFirstWaveEnterSystem_Render:TearDown()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnClickUIBonusInfo, self._onClickUIBonusInfo)
end

function ClientFirstWaveEnterSystem_Render:OnClickUIBonusInfo()
    self._isShowBonusInfo = false
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowBonusInfo, false)
end

--endregion
function ClientFirstWaveEnterSystem_Render:_DoRenderShowUIBattleStart(TT, teamEntity)
    if self._world._matchType == MatchType.MT_Conquest then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIInitN5Score)
    end
    self._isShowBonusInfo = false
    --三星条件展示
    if not GuideHelper.DontShowThreeMission() then
        self._isShowBonusInfo = true
        local match = GameGlobal.GetModule(MatchModule)
        local enterData = match:GetMatchEnterData()
        if enterData._match_type == MatchType.MT_Mission then --主线
            local missionID = enterData:GetMissionCreateInfo().mission_id
            GameGlobal.UAReportForceGuideEvent(
                "MissionPopStarInfo",
                {
                    missionID
                }
            )
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowBonusInfo, true)
    end
    --如果不点击会展示3s  在展示1s后可以点击关闭
    while self._isShowBonusInfo do
        YIELD(TT)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideUIBattle, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    YIELD(TT)
    self:_RefreshTeamHP(teamEntity)
end

function ClientFirstWaveEnterSystem_Render:_DoRenderAutoAddBuff(TT, buffseqs)
    
    ---@type PlayBuffService
    local svc = self._world:GetService("PlayBuff")
    --秘境存档恢复
    --处理怪物血条显示
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local isArchived = utilDataSvc:IsArchivedBattle()
    if isArchived then
        svc:LoadArchivedLockHPView(TT)
    end
    --被动buff出场效果
    svc:PlayBuffSeqs(TT,buffseqs)
    svc:PlayAutoAddBuff(TT)
    svc:PlayBuffView(TT, NTGameStart:New())
end

function ClientFirstWaveEnterSystem_Render:_DoRendeDestroyBattleEnterResource(TT)
    self:UnloadEffect(GameResourceConst.EffRuchangKaichang)
    self:UnloadEffect(GameResourceConst.EffRuchangGeziglow)
    self:UnloadEffect(GameResourceConst.EffRuchuangPetBao)
    self:UnloadEffect(GameResourceConst.EffRuchuangHeti)
    self:UnloadEffect(GameResourceConst.MonsterAppearEffBoss)

    self:UnloadEffect(GameResourceConst.EffRuchangBlackboard)
    self:UnloadEffect(GameResourceConst.EffBoardShowLine)
    --[[
    for k, v in pairs(GameResourceConst.MonsterAppearEffSingleBodyArea) do
        self:UnloadEffect(v)
    end

    for k, v in pairs(GameResourceConst.MonsterAppearEffMultiBodyArea) do
        self:UnloadEffect(v)
    end
--]]
    for k, v in pairs(GameResourceConst.PetAppearEff) do
        self:UnloadEffect(v)
    end
end

---这个函数可以拆到svc里
function ClientFirstWaveEnterSystem_Render:UnloadEffect(effectid)
    ---@type ResourcesPoolService
    local poolSvc = self._world:GetService("ResourcesPool")
    ---@type EffectService
    local effSvc = self._world:GetService("Effect")

    local effResPath = effSvc:GetEffectResPath(effectid)
    if effResPath then
        poolSvc:DestroyCache(effResPath)
    end
end

function ClientFirstWaveEnterSystem_Render:_RefreshTeamHP(teamEntity)
    if teamEntity == nil then 
        return
    end

    ---@type HPComponent
    local hpCmpt = teamEntity:HP()

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.TeamHPChange,
        {
            isLocalTeam = true,
            currentHP = hpCmpt:GetRedHP(),
            maxHP = hpCmpt:GetMaxHP(),
            hitpoint = hpCmpt:GetRedHP(),
            shield = 0,
            entityID=teamEntity:GetID(),
            showCurseHp = hpCmpt:GetShowCurseHp(),
            curseHpVal = hpCmpt:GetCurseHpValue()
        }
    )
end
