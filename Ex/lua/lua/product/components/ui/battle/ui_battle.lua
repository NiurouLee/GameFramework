---@class UIBattle : UIController
_class("UIBattle", UIController)
UIBattle = UIBattle

function UIBattle:OnShow(uiParams)
    ---关闭多点触控
    ---EnterCoreGame时关闭，会被UIState切换时重新打开；例如UISeasonLevelStage
    ---Bug：MSG71995
    UnityEngine.Input.multiTouchEnabled = false

    self._dbgAutoFightInfo = {}

    ---@type UILeaveMatchHandler
    self._uiLeaveMatchHandler = UILeaveMatchHandler:New(self)

    ---@type UIBattleFinishHandler
    if self._uiBattleFinishHandler then
        self._uiBattleFinishHandler:Dispose()
        self._uiBattleFinishHandler = nil
    end
    self._uiBattleFinishHandler = UIBattleFinishHandler:New(self)

    local collector = GameGlobal:GetInstance():GetCollector("CoreGameLoading")
    collector:Sample("UIBattle:OnShow() begin")
    --self.autoParam = self:CheckAutoEnable()
    self._safeAreaCanvasGroup = self:GetUIComponent("CanvasGroup", "SafeArea")
    self._graphicRaycaster = self:GetUIComponent("GraphicRaycaster", "UICanvas")
    self._graphicRaycaster.enabled = true

    self._showDebugInfo = true

    ---自动按钮和加速按钮----------
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)

    ---宝宝相关-----------------
    ---@type UICustomWidgetPool
    self._petAreaGen = self:GetUIComponent("UISelectObjectPath", "PetInfo")
    ---@type UIWidgetPetArea
    self._petAreaWidget = self._petAreaGen:SpawnObject("UIWidgetPetArea")
    self._petAreaWidget:SetData(self)
    --pet数据来自petmodule
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    ---@type LuaMatchPlayerInfo
    local localPlayerInfo = matchEnterData:GetLocalPlayerInfo()

    self.enemyPetInfoGo = self:GetGameObject("EnemyPetInfo")
    if matchEnterData:GetMatchType() ~= MatchType.MT_BlackFist then
        self.enemyPetInfoGo:SetActive(false)
    else
        --黑拳赛 敌方队伍
        self.enemyPetInfoGo:SetActive(true)
        local enemyPetInfoSop = self:GetUIComponent("UISelectObjectPath", "EnemyPetInfo")
        ---@type UIWidgetBattleEnemyPetInfo
        self.enemyPetInfo = enemyPetInfoSop:SpawnObject("UIWidgetBattleEnemyPetInfo")
        self.enemyPetInfo:SetData(matchEnterData)
    end

    self._skillAreaGen = self:GetUIComponent("UISelectObjectPath", "SkillArea")
    ---@type UIWidgetSkillArea
    self._skillAreaWidget = self._skillAreaGen:SpawnObject("UIWidgetSkillArea")
    self._skillAreaWidget:SetData(self)

    self._mirageUIGen = self:GetUIComponent("UISelectObjectPath", "MirageUI")
    ---@type UIWidgetMirageUI
    self._mirageUIWidget = self._mirageUIGen:SpawnObject("UIWidgetMirageUI")

    ---@type UnityEngine.GameObject 取消主动技的全屏按钮
    self.cancelActiveSkillBtn = self:GetGameObject("CancelActiveSkillBtn")

    --队伍buff列表，BuffEffectType作为关键字，比如Burn就代表灼烧
    self._teamBuffList = {}
    ---初始化队伍，战棋不需要
    if matchEnterData:GetMatchType() ~= MatchType.MT_Chess then
        ---@type UICustomWidgetPool
        local teamState = self:GetUIComponent("UISelectObjectPath", "teamState")
        ---@type UIBattleTeamStateEnter
        self._teamState = teamState:SpawnObject("UIBattleTeamStateEnter")
        self._teamState:Init(
            localPlayerInfo.pet_list,
            self._teamBuffList
        )
    end

    ---低血量预警
    ---@type UIBattleLowHPWarning
    self._lowHpWarning = self:GetUIComponent("UISelectObjectPath", "LowHpWarning"):SpawnObject("UIBattleLowHPWarning")
    ---@type UIBattleOutOfRoundDamageWarning
    self._outOfRoundWarning = self:GetUIComponent("UISelectObjectPath", "OutOfRoundContainer"):SpawnObject("UIBattleOutOfRoundDamageWarning")

    self._combo = self:GetUIComponent("UISelectObjectPath", "ComboContainer"):SpawnObject("UIBattleCombo")

    --全屏特效挂点
    self._fullScreenEffect = self:GetGameObject("FullScreenEffect")
    self._auroraTimeEff = self:GetUIComponent("UISelectObjectPath", "auroraTimeEff"):SpawnObject("UIBattleAuroraTime")

    ---@type EffectLoader
    self._effectLoader = self:GetUIComponent("EffectLoader", "UIEffRoot")

    ---生成连线取消感应区
    self:SpawnCancelArea()

    self._isFromMaze = (matchEnterData:GetMatchType() == MatchType.MT_Maze)
    self._isFromMiniMaze = (matchEnterData:GetMatchType() == MatchType.MT_MiniMaze)
    local isShowMazeBackpackBtn = (self._isFromMaze or self._isFromMiniMaze)
    --秘境商店
    self.mazeBackpackBtn = self:GetGameObject("mazeBackpackBtn")
    self.mazeBackpackBtn:SetActive(isShowMazeBackpackBtn)
    local sop = self:GetUIComponent("UISelectObjectPath", "turnInfo")
    if self._isFromMaze then
        --
        sop.dynamicInfoOfEngine:SetObjectName("UIBattleMazeLightInfo.prefab")
        ---@type UIBattleMazeLightInfo 迷宫对局回合数显示为光盏数，使用同样的prefab，逻辑略有不同
        self._turnInfo = sop:SpawnObject("UIBattleMazeLightInfo")
    else
        ---@type UIBattleTurnInfo
        self._turnInfo = sop:SpawnObject("UIBattleTurnInfo")
    end

    ---生成模块系统UI
    self:SpawnFeature()

    self:RegisterEvent()

    --词缀提取到通用
    local affixSop = self:GetUIComponent("UISelectObjectPath", "mazeAffix")
    if affixSop then
        ---@type UIWidgetBattleAffix
        self._affixWidget = affixSop:SpawnObject("UIWidgetBattleAffix")
        self._affixWidget:SetData(matchEnterData)
    end

    ---初始化回合数
    ---@type LevelConfigData
    local levelConfigData = ConfigServiceHelper.GetLevelConfigData()
    self.levelId = levelConfigData:GetLevelID()
    --获取第一波的回合数
    local levelRoundCount = levelConfigData:GetLevelRoundCount()
    --获取全部波次数
    self._turnInfo:InitRoundCount(levelRoundCount)

    ---转场黑屏
    self._transitionEffectImg = self:GetUIComponent("Image", "TransitionEffect")
    self._transitionEffectImg:DOFade(0, 0.01)
    -- ---收集的掉落信息
    local eptRect = self:GetUIComponent("RectTransform", "UIBattleProgressInfoEpt")
    if matchEnterData:GetMatchType() == MatchType.MT_BlackFist then--黑拳赛 wave 上移
        eptRect.anchoredPosition = Vector2(eptRect.anchoredPosition.x, 23.2)
    else
        eptRect.anchoredPosition = Vector2(eptRect.anchoredPosition.x, 0)
    end
    local ept = self:GetUIComponent("UISelectObjectPath", "UIBattleProgressInfoEpt")
    ---@type UIBattleProgressInfo
    self._progressInfo = ept:SpawnObject("UIBattleProgressInfo")

    --机关的技能显示
    ---@type UICustomWidgetPool
    local trapSkillInfoPath = self:GetUIComponent("UISelectObjectPath", "trapSkillInfo")
    ---@type UIWidgetTrapSkill
    self._trapSkillUI = trapSkillInfoPath:SpawnObject("UIWidgetTrapSkill")
    self:_OnUITrapSkillVisible(false)

    -- 新手引导 start
    self._guideMask = self:GetGameObject("GuideMask")
    self._guideWeakMaskGO = self:GetGameObject("guideWeakMask")
    self._guideWeakMaskGO:SetActive(false)
    --self._guideWidgetPetIndex = -1
    self._guideWarnTurn = self:GetUIComponent("RectTransform", "GuideWarnTurn")
    self._guideWarnTurnGO = self:GetGameObject("GuideWarnTurn")
    self._guideWarnTurnGO:SetActive(false)
    self._guideWarnTurnY = self._guideWarnTurn.anchoredPosition.y
    self._guideWarnDescTxt = self:GetUIComponent("UILocalizationText", "guidewarndesc")
    self._guideWarnIcon = self:GetUIComponent("Image", "guidewarnicon")
    self._guideWarnIconGO = self:GetGameObject("guidewarnicon")
    self._guideWarnCanvasGroup = self:GetUIComponent("CanvasGroup", "GuideWarnTurn")
    self._guideWarnCanvasGroup.alpha = 0.7
    self._guideConditionGO = self:GetGameObject("GuideCondition")
    self._guideConditionGO:SetActive(false)
    self._guideConditionDescTxt = self:GetUIComponent("UILocalizationText", "guideconditiondesc")
    self._guideConditionFinishTxt = self:GetUIComponent("UILocalizationText", "guideconditionfinish")
    self._guideConditionAnim = self:GetUIComponent("Animation", "GuideCondition")

    -- 新手引导 end

    self._playerTurn = self:GetUIComponent("RectTransform", "PlayerTurn")
    self._auroraTime = self:GetUIComponent("RectTransform", "AuroraTime")
    self._enemyTurn = self:GetUIComponent("RectTransform", "EnemyTurn")

    -- MSG23719	【现网】【必现】（测试_常舟)日文版本局内技能冷却后日文显示不全，需要ui拉长 附截图	4	缺陷_修复中	李学森, 1958	05/25/2021

    self.pTurnLayout = self:GetUIComponent("RectTransform", "pTurnLayout")
    self.eTurnLayout = self:GetUIComponent("RectTransform", "eTurnLayout")

    self.pTurnTex = self:GetUIComponent("UILocalizationText", "pTurnTex")
    self.eTurnTex = self:GetUIComponent("UILocalizationText", "eTurnTex")

    self.pTurnTex:SetText(StringTable.Get("str_battle_player_turn_1"))
    self.eTurnTex:SetText(StringTable.Get("str_battle_enemy_turn_1"))

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.pTurnLayout)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.eTurnLayout)

    self.pTurnLayoutLeftX = -1 * (self.pTurnLayout.sizeDelta.x - 17.8 + 103.8)
    self.eTurnLayoutLeftX = -1 * (self.eTurnLayout.sizeDelta.x - 17.8 + 103.8)

    self._playerTurn.anchoredPosition = Vector2(self.pTurnLayoutLeftX, -60)
    self._enemyTurn.anchoredPosition = Vector2(self.eTurnLayoutLeftX, -60)

    --麻痹
    self._benumbTips = self:GetUIComponent("RectTransform", "UIBenumbTips")
    --self._txtBenumbTips = self:GetUIComponent("UILocalizationText",'txtBenumbTips')

    --被围提示双击原地
    self._besiegedTips = self:GetUIComponent("RectTransform", "UIBesiegedTips")

    self.uiPetInfoCanvasGroup = self:GetUIComponent("CanvasGroup", "PetInfo")

    self._mainStateTxt = self:GetUIComponent("UILocalizationText", "MainState")
    self._LevelName = self:GetUIComponent("UILocalizationText", "LevelName")
    self._fpsTxt = self:GetUIComponent("UILocalizationText", "fpstext")
    self._mvpTxt = self:GetUIComponent("UILocalizationText", "mvptext")
    self._cheatBtn = self:GetGameObject("btnTemp")

    self:SwitchDebugInfo(true)

    self.btnSettingGO = self:GetGameObject("btnSetting")
    local targetMission = Cfg.cfg_guide_const["guide_battle_quit_hide"].IntValue
    local mission = self:GetModule(MissionModule)
    if NOGUIDE then
        self.btnSettingGO:SetActive(true)
    else
        self.btnSettingGO:SetActive(mission:GetCurMissionID() >= targetMission)
    end

    --region 连锁预览
    ---@type UICustomWidgetPool
    local goChainPreview = self:GetUIComponent("UISelectObjectPath", "goChainPreview")
    ---@type UIChainSkillPreview
    self.goChainPreview = goChainPreview:SpawnObject("UIChainSkillPreview")
    --endregion

    collector:Sample("UIBattle:OnShow() end")

    self:_ShowHideUIBattle(false)

    self._autoBtnPool = self:GetUIComponent("UISelectObjectPath", "auto")
    self._manualBtns = self:GetGameObject("manual")

    local talePetMissionInfo = matchEnterData:GetTalePetMissionInfo()
    local isTrial = true
    if talePetMissionInfo then
        local cfg = Cfg.cfg_tale_stage[talePetMissionInfo.nId]
        if cfg and cfg.Type ~= 1 then
            isTrial = false
        end
    end

    self._taleBuffInfoBtn = self:GetGameObject("taleBuffInfoBtn")
    self._taleBuffInfoBtn:SetActive(matchEnterData:GetMatchType() == MatchType.MT_TalePet and (not isTrial))
    self:_CheckAffixEntryBtn(matchEnterData)

    self._seasonBuffEntryBtn = self:GetGameObject("SeasonBuffEntryBtn")
    self._seasonBuffEntryBtn:SetActive(matchEnterData:GetMatchType() == MatchType.MT_Season)
    self:_CheckSeasonBuffEntryBtn(matchEnterData)

    ---是否退出过局内
    self._hasHandleBattleEnd = false

    self._chessPanelPool = self:GetUIComponent("UISelectObjectPath", "ChessPanelPool")
    if matchEnterData:GetMatchType() == MatchType.MT_Chess and (self._chessPanelPool--[[FIXME:打过整包更新ab后应该删除这个条件]]) then
        --region boss血条
        ---@type UICustomWidgetPool
        local bossHP = self:GetUIComponent("UISelectObjectPath", "chessHP")
        ---@type UIBattleTeamStateEnter
        bossHP:SpawnObject("UIBattleChessHPInfo")
        --endregion

        self._goChessPanel = self._chessPanelPool:SpawnObject("UIBattleWidgetChess")
        self:GetGameObject("RightAnchor2"):SetActive(false)
        self:GetGameObject("RightUpAnchor"):SetActive(false)
    else
        --region boss血条
        ---@type UICustomWidgetPool
        local bossHP = self:GetUIComponent("UISelectObjectPath", "bossHP")
        ---@type UIBattleTeamStateEnter
        bossHP:SpawnObject("UIBattleBossHP")
        --endregion

        self:GetGameObject("RightAnchor2"):SetActive(true)
        self:GetGameObject("RightUpAnchor"):SetActive(true)
    end
    
    --自动战斗部分
    ---@type UICustomWidgetPool
    local autoGen = self:GetUIComponent("UISelectObjectPath", "SerialAutoFight")
    ---@type UIWidgetAutoFight
    self._widgetAutoFight = autoGen:SpawnObject("UIWidgetAutoFight")
    self._widgetAutoFight:SetData(matchEnterData, self._chessPanelPool)
    
    self:_RefreshUIBattleForMatchType()

    ---局内gm用
    self._cheatHideUIRecord = {}
end

---消灭星星玩法需要隐藏某些UI
function UIBattle:_RefreshUIBattleForMatchType()
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    if matchEnterData:GetMatchType() ~= MatchType.MT_PopStar then
        return
    end

    ---波次进度
    self._progressInfo:GetGameObject():SetActive(false)

    ---队伍信息
    self:GetGameObject("RightUpAnchor"):SetActive(false)

    ---自动战斗及倍速
    self._widgetAutoFight:GetGameObject():SetActive(false)

    ---消除数显示
    ---@type UICustomWidgetPool
    local popStarNumPath = self:GetUIComponent("UISelectObjectPath", "popStarNum")
    ---@type UIWidgetPopStarNum
    self._popStarNum = popStarNumPath:SpawnObject("UIWidgetPopStarNum")
    self._popStarNum:GetGameObject():SetActive(false)

    ---消除进度
    ---@type UICustomWidgetPool
    local popStarProgressPath = self:GetUIComponent("UISelectObjectPath", "popStarProgress")
    ---@type UIWidgetPopStarProgressInfo
    self._popStarProgressInfo = popStarProgressPath:SpawnObject("UIWidgetPopStarProgressInfo")
    self._popStarProgressInfo:SetActive(true)
end

--间隔触发多词条滚动
function UIBattle:_UpdateMultiMazeAffix(deltaTimeMS)
    if self._affixWidget then
        self._affixWidget:_OnUpdate(deltaTimeMS)
    end
end

---@param matchEnterData MatchEnterData
function UIBattle:_CheckAffixEntryBtn(matchEnterData)
    local affixBtn = self:GetGameObject("AffixEntryBtn")
    local affixBtnImg = self:GetUIComponent("Image", "AffixEntryBtn")
    self._curAffixCampaignType = nil
    local show = false
    ---@type CampaignModule
    local campaignModule = self:GetModule(CampaignModule)
    local missionInfo = matchEnterData:GetMissionCreateInfo()
    if matchEnterData:GetMatchType() == MatchType.MT_Campaign then
        local campId, comId, comType = campaignModule:ParseCampaignMissionParams(missionInfo.CampaignMissionParams)
        local campConfig = Cfg.cfg_campaign[campId]
        if campConfig then
            self._curAffixCampaignType = campConfig.CampaignType
            if self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_SUMMER_II then --夏活2
                if comType == CampaignComType.E_CAMPAIGN_COM_SUM_II_MISSION then
                    local cfgs =
                    Cfg.cfg_component_summer_ii_mission {
                        CampaignMissionId = missionInfo.nCampaignMissionId,
                        ComponentID = missionInfo.CampaignMissionParams[1]
                    }
                    if cfgs and #cfgs > 0 then
                        if cfgs[1].LevelType ~= UISummerActivity2LevelType.Normal then
                            show = true
                        end
                    end
                end
            elseif self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N12 then --N12
                if comType == CampaignComType.E_CAMPAIGN_COM_DAILY_MISSION or
                    comType == CampaignComType.E_CAMPAIGN_COM_CHALL_MISSION
                then
                    show = true
                end
            elseif self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE then
                if comType == CampaignComType.E_CAMPAIGN_COM_CHALL_MISSION then
                    show = true
                end
            end
        end
    end
    affixBtn:SetActive(show)
    if show then
        local spriteAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
        local spriteName = "summer_junei_btn1"
        if self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N12 then --N12
            spriteAtlas = self:GetAsset("UIN12.spriteatlas", LoadType.SpriteAtlas)
            spriteName = "n12_juenei_btn_citiao"
        elseif self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE then
            spriteName = "n21_wjyz_jnct_di15"
        end
        affixBtnImg.sprite = spriteAtlas:GetSprite(spriteName)
    end
end

function UIBattle:SwitchDebugInfo(show)
    local isDevelopmentBuild = false
    if (HelperProxy:GetInstance():IsDebug() or EDITOR) then
        isDevelopmentBuild = true
    end

    local bshowfps = HelperProxy:GetInstance():GetConfig("ShowFps", "false")
    local bshowcheatbtn = HelperProxy:GetInstance():GetConfig("ShowCheatBtn", "false")
    if isDevelopmentBuild == true and show then
        self._mainStateTxt.gameObject:SetActive(true)
        self._LevelName.gameObject:SetActive(true)
        self._LevelName:SetText("LevelID:" .. tostring(self.levelId))
        self._cheatBtn:SetActive(true)
        self._fpsTxt.gameObject:SetActive(true)
        self._mvpTxt.gameObject:SetActive(true)
    else
        if (bshowcheatbtn == "true" and show) then
            self._cheatBtn:SetActive(true)
        else
            self._cheatBtn:SetActive(false)
        end
        if (bshowfps == "true" and show) then
            self._mainStateTxt.gameObject:SetActive(true)
            self._LevelName.gameObject:SetActive(true)
            self._fpsTxt.gameObject:SetActive(true)
            self._mvpTxt.gameObject:SetActive(true)
        else
            self._mainStateTxt.gameObject:SetActive(false)
            self._LevelName.gameObject:SetActive(false)
            self._fpsTxt.gameObject:SetActive(false)
            self._mvpTxt.gameObject:SetActive(false)
        end
    end
end

function UIBattle:Dispose()
    self._hasHandleBattleEnd = false

    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end

    if self._uiLeaveMatchHandler then
        self._uiLeaveMatchHandler:Dispose()
    end

    if self._uiBattleFinishHandler then
        self._uiBattleFinishHandler:Dispose()
    end

    UIBattle.super:Dispose()
end

function UIBattle:ShotBattleResult()
    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    if not self._shot then
        return
    end
    local shotRect = self:GetUIComponent("RectTransform", "screenShot")
    shotRect.gameObject:SetActive(true)
    self._shot.width = shotRect.rect.width
    self._shot.height = shotRect.rect.height
    self._shot.blurTimes = 0
    self._shot:CleanRenderTexture()
    self._battleResultRt = self._shot:RefreshBlurTexture()
end

function UIBattle:AffixEntryBtnOnClick()
    if not self._curAffixCampaignType then
        return
    end
    if self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_SUMMER_II then --夏活2
        self:ShowDialog("UISummerActivityTwoEntryController")
    elseif self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N12 then --N12
        self:ShowDialog("UIN12BattleAffix")
    elseif self._curAffixCampaignType == ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE then --危机合约
        self:ShowDialog("UIActivityN21CCAffixDetail")
    end
end

function UIBattle:OnUpdate(deltaTimeMS)
    --多词缀的滚动
    self:_UpdateMultiMazeAffix(deltaTimeMS)

    if self._mirageUIWidget then
        self._mirageUIWidget:OnUpdate(deltaTimeMS)
    end

    if (IsPc() or IsUnityEditor()) and GameGlobal.EngineInput().GetKeyDown(UnityEngine.KeyCode.BackQuote) then
        self._showDebugInfo = not self._showDebugInfo
        self:SwitchDebugInfo(self._showDebugInfo)
    end

end

--增加星灵的攻防血
function UIBattle:_AddPetAtkDefHp(petId, addAtk, addDef, addHp)
    --sjs_todo
    local petList = self._petAreaWidget:_AddPetAtkDefHp(petId, addAtk, addDef, addHp)
    if petList then
        if self._teamState then
            self._teamState:Init(petList, self._teamBuffList)
        end
    end
end

---@protected

function UIBattle:OnHide()
    if self._effectEvent then
        self._effectLoader:DestroyCurrentEffect()
        GameGlobal.Timer():CancelEvent(self._effectEvent)
        self._effectEvent = nil
    end
    self:UnRegisterEvent()
end

function UIBattle:_ShowHideUIBattle(isShow)
    local go = self:GetGameObject()
    if go then
        go:SetActive(isShow)
    end
end

--region Event
function UIBattle:RegisterEvent()
    self:AttachEvent(GameEventType.OnSetGraphicRaycaster, self.OnSetGraphicRaycaster)
    self:AttachEvent(GameEventType.UIShowPetInfo, self.HandleUIShowPetInfo)
    self:AttachEvent(GameEventType.ShowHideSuperChain, self.ShowHideSuperChain)
    self:AttachEvent(GameEventType.ShowHideBossComing, self.ShowHideBossComing)
    self:AttachEvent(GameEventType.ShowHideWaveWarning, self.ShowHideWaveWarning)
    self:AttachEvent(GameEventType.ShowBonusInfo, self.ShowBonusInfo)
    self:AttachEvent(GameEventType.WaveSwitch, self._OnWaveSwitch)
    self:AttachEvent(GameEventType.ShowZeroRoundWarning, self.ShowZeroRoundWarning)
    self:AttachEvent(GameEventType.ShowHideOutOfRoundPunishWarn, self.ShowOutOfRoundPunishWarn)
    self:AttachEvent(GameEventType.ShowWaveSwitch, self.ShowWaveSwitch)
    self:AttachEvent(GameEventType.ChangeTeamBuff, self.OnChangeBuff)
    self:AttachEvent(GameEventType.ShowTransitionEffect, self.ShowTransitionEffect)
    self:AttachEvent(GameEventType.ShowGuideFailed, self.ShowGuideFailed)
    self:AttachEvent(GameEventType.ShowGuideMask, self._ShowGuideMask)
    self:AttachEvent(GameEventType.ShowHideUIBattle, self._ShowHideUIBattle)
    self:AttachEvent(GameEventType.ShowStoryBanner, self._ShowStoryBanner)
    self:AttachEvent(GameEventType.PlayBattleUIEffect, self.ShowUIEffect)
    self:AttachEvent(GameEventType.ShowTurnTips, self._ShowTurnTipsOut)
    self:AttachEvent(GameEventType.ShowGuideWarn, self._ShowGuideWarnOut)
    self:AttachEvent(GameEventType.ShowGuideCondition, self._ShowGuideCondition)
    self:AttachEvent(GameEventType.ShowPetInfo, self._ShowPetInfo)
    self:AttachEvent(GameEventType.RefreshMainState, self._RefreshMainState)
    self:AttachEvent(GameEventType.UiBattleVisible, self.OnUiBattleVisible)
    self:AttachEvent(GameEventType.ShowHideBenumbTips, self.ShowHideBenumbTips)
    self:AttachEvent(GameEventType.ShowHideBesiegedTips, self.ShowHideBesiegedTips)
    self:AttachEvent(GameEventType.ChangePetAtkDefHp, self._AddPetAtkDefHp)
    self:AttachEvent(GameEventType.UITrapSkillVisible, self._OnUITrapSkillVisible)
    self:AttachEvent(GameEventType.RefreshMVPText, self.OnRefreshMVPText)
    self:AttachEvent(GameEventType.SetCurPickExtraParam, self._OnSetCurPickExtraParam)
    self:AttachEvent(GameEventType.UIShowHideCancelActiveSkillBtn, self.ShowHideCancelActiveSkillBtn)
    self:AttachEvent(GameEventType.UISetTeamStateTeamLeader, self.SetTeamStateTeamLeader)
    self:AttachEvent(GameEventType.ShowChoosePartnerUI, self.ShowChoosePartnerUI)
    self:AttachEvent(GameEventType.UIShowBossSpeak, self.UIShowBossSpeak)
    self:AttachEvent(GameEventType.PopStarShowPopNum, self._OnUIPopStarNumVisible)
    self:AttachEvent(GameEventType.UICheatHideArea, self.UICheatHideArea)
end

function UIBattle:UnRegisterEvent()

end

--endregion

function UIBattle:_CloseAllDialogs(hide)
    local uiStateManager = GameGlobal.UIStateManager()
    if uiStateManager:IsShow("UIBattleInfo") then
        uiStateManager:CloseDialog("UIBattleInfo")
    end
    if uiStateManager:IsShow("UIBattleQuit") and hide then
        uiStateManager:CloseDialog("UIBattleQuit")
    end
    if uiStateManager:IsShow("UIBattleTeamState") then
        uiStateManager:CloseDialog("UIBattleTeamState")
    end
end

function UIBattle:_OnWaveSwitch()
    self:_CloseAllDialogs(true)
end

function UIBattle:ShowBonusInfo(isShow)
    if isShow == true then
        self:ShowDialog("UIBattleBonus")
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattleBonus")
    end
end

------------功能按钮-------------------------------------
function UIBattle:btnSettingOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattle", input = "btnSettingOnClick", args = {} }
    )

    GameGlobal.UAReportForceGuideEvent(
        "FightClick",
        {
            "btnSettingOnClick",
            0
        },
        false,
        true
    )

    if self:IsAutoFighting() then
        self:ShowAutoFightForbiddenMsg()
        return
    end

    self:ShowDialog("UIBattleInfo")
end

function UIBattle:btnTempOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattle", input = "btnTempOnClick", args = {} }
    )
    self:ShowDialog("UIBattleCheat",nil,self._cheatHideUIRecord)
end

--endregion
------------功能按钮end-------------------------------------
function UIBattle:GetPetWidgetByPstID(petPstID)
    return self._petAreaWidget:GetPetWidgetByPstID(petPstID)
end

function UIBattle:GetPreviewPetId()
    return self._skillAreaWidget:GetPreviewPetId()--sjs_todo
end
function UIBattle:GetCurPetActiveSkillId()
    return self._skillAreaWidget:GetCurPetActiveSkillId()--sjs_todo
end
function UIBattle:CancelActiveSkillBtnOnClick(go)
    self._skillAreaWidget:OnCancelActiveSkillBtnOnClick(go)
end
------------点击宝宝end---------------------------------------------

---------局内消息处理---------------------------------------------

---关闭UIBattle界面点击
function UIBattle:OnSetGraphicRaycaster(enable)
    self._graphicRaycaster.enabled = enable
end

function UIBattle:HideUIBattleQuit(enterData, victory)
    if MatchType.MT_Conquest == enterData._match_type then
        local gameMatchModule = self:GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.m_vecAwardNormal.count <= 0 and victory then
            return false
        end
    elseif MatchType.MT_WorldBoss == enterData._match_type then
        local gameMatchModule = self:GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.m_damage <= 0 and victory then
            return false
        end
    elseif MatchType.MT_MiniMaze == enterData._match_type then
        local gameMatchModule = self:GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult.wave <= 0 and victory then
            return false
        end
    elseif MatchType.MT_PopStar == enterData._match_type then
        local gameMatchModule = self:GetModule(GameMatchModule)
        local matchResult = gameMatchModule:GetMachResult()
        if matchResult._starNum <= 0 and victory then
            return false
        end
    end
    return true
end

function UIBattle:OnShowPetInfoInish()
    self._petAreaWidget:OnShowPetInfoInish()--sjs_todo
    if self.enemyPetInfo then
        self.enemyPetInfo:OnShowPetInfoInish()
    end
end

--------------局内消息处理end-------------------------------------

function UIBattle:ShowHideSuperChain(isShow, pos)
    if isShow then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUISuperChain)
        GameGlobal.UIStateManager():ShowDialog("UISuperChainSkill", pos)
    else
        GameGlobal.UIStateManager():CloseDialog("UISuperChainSkill")
    end
end

function UIBattle:ShowHideBossComing(isShow, bossId)
    if isShow then
        if not bossId then
            Log.fatal("### [boss coming] bossId is null.")
            return
        end
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIBossAlarm)
        GameGlobal.UIStateManager():ShowDialog("UIBattleBossWarning", bossId)
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattleBossWarning")
    end
end

function UIBattle:ShowHideWaveWarning(isShow, levelId)
    if isShow then
        if not levelId then
            Log.fatal("### [boss coming] levelId is null.")
            return
        end
        AudioHelper.PlayUISoundAutoReleaseBylevelId(levelId)
        GameGlobal.UIStateManager():ShowDialog("UIHarvestTime")
    else
        GameGlobal.UIStateManager():CloseDialog("UIHarvestTime")
    end
end

function UIBattle:ShowZeroRoundWarning(isShow)
    if isShow then
        GameGlobal.UIStateManager():ShowDialog("UIBattleZeroRoundWarning")
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattleZeroRoundWarning")
    end
end

function UIBattle:ShowOutOfRoundPunishWarn(isShow)
    if isShow then
        GameGlobal.UIStateManager():ShowDialog("UIBattleOutOfRoundPunishWarn")
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattleOutOfRoundPunishWarn")
    end
end

function UIBattle:ShowWaveSwitch(isShow, waveNum)
    if isShow then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIWaveSwitch)
        GameGlobal.UIStateManager():ShowDialog("UIBattleWaveSwitch", waveNum)
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattleWaveSwitch")
    end
end

--通知 UIBattleTeamStateEnter 右上角刷新BUFF状态
function UIBattle:OnChangeBuff(buffList)
    self._teamBuffList = buffList
    self._teamState:OnChangeBuff(buffList)
end

function UIBattle:ShowTransitionEffect()
    self.rt = self:Shot()
    ---转场时间，临时配在这
    local transitionTime = 1
    self._transitionEffectImg:DOFade(1, transitionTime)
end

function UIBattle:ShowGuideFailed()
    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()
    local matchType = enterData._match_type
    local missionId
    if MatchType.MT_Mission == matchType then
        local data = enterData:GetMissionCreateInfo()
        missionId = data.mission_id
    end
    self:ShowDialog("UIGuideFailedController", missionId, matchType)
end

function UIBattle:_GetMatchResult()
    local gameMatchModule = self:GetModule(GameMatchModule)
    local matchResult = UI_MatchResult:New()
    matchResult = gameMatchModule:GetMachResult()
    return matchResult
end

function UIBattle:_ShowGuideMask(isShow)
    self._guideMask:SetActive(isShow)
end

function UIBattle:_ShowPetInfo(addalpha)
    local srcalpha = self.uiPetInfoCanvasGroup.alpha
    local dstalpha = srcalpha + addalpha
    if (srcalpha < 1 and dstalpha >= 1) then
        self.uiPetInfoCanvasGroup.alpha = dstalpha
    elseif (srcalpha > 0 and dstalpha <= 0) then
        self.uiPetInfoCanvasGroup.alpha = dstalpha
    else
        self.uiPetInfoCanvasGroup.alpha = dstalpha
    end

    if dstalpha < 1 then
        self.uiPetInfoCanvasGroup.blocksRaycasts = false
    else
        self.uiPetInfoCanvasGroup.blocksRaycasts = true
        self:OnShowPetInfoInish()
    end
end

function UIBattle:_ShowStoryBanner(bannerID, bannerType)
    GameGlobal.UIStateManager():ShowDialog("UIStoryBanner", bannerID, bannerType)
end

function UIBattle:_ShowTurnTipsOut(isPlayerTurn, isAuroraTime)
    local duration = UIConst.TurnTipsOutTick / 1000.0
    local stay = UIConst.TurnTipsStayTick / 1000.0
    local offsetEndX = 0

    if isPlayerTurn then
        if isAuroraTime then
            --暂时去掉极光时刻tips，如果策划不改回来就删除
            -- self._auroraTime:DOAnchorPosX(offsetEndX, duration):OnComplete(
            --     function()
            --         self._auroraTime:DOAnchorPosX(offsetEndX, stay):OnComplete(
            --             function()
            --                 self:_ShowTurnTipsIn(isPlayerTurn, isAuroraTime)
            --             end
            --         )
            --     end
            -- )
        else
            self._playerTurn:DOAnchorPosX(offsetEndX, duration):OnComplete(
                function()
                    self._playerTurn:DOAnchorPosX(offsetEndX, stay):OnComplete(
                        function()
                            self:_ShowTurnTipsIn(isPlayerTurn, isAuroraTime)
                        end
                    )
                end
            )
        end
    else
        self._enemyTurn:DOAnchorPosX(offsetEndX, duration):OnComplete(
            function()
                self._enemyTurn:DOAnchorPosX(offsetEndX, stay):OnComplete(
                    function()
                        self:_ShowTurnTipsIn(isPlayerTurn)
                    end
                )
            end
        )
    end
end

function UIBattle:_ShowTurnTipsIn(isPlayerTurn, isAuroraTime)
    local duration = UIConst.TurnTipsInTick / 1000.0
    local offsetEndX
    if isPlayerTurn then
        if isAuroraTime then
            --self._auroraTime:DOAnchorPosX(offsetEndX, duration)
        else
            offsetEndX = self.pTurnLayoutLeftX
            self._playerTurn:DOAnchorPosX(offsetEndX, duration)
        end
    else
        offsetEndX = self.eTurnLayoutLeftX
        self._enemyTurn:DOAnchorPosX(offsetEndX, duration)
    end
end

function UIBattle:_ShowGuideWarnOut(guideWarnId)
    local cfg = Cfg.cfg_guide_warn[guideWarnId]
    if not self.guideAtlas then
        self.guideAtlas = self:GetAsset("UIGuide.spriteatlas", LoadType.SpriteAtlas)
    end
    if cfg then
        self._guideWarnIconGO:SetActive(true)
        self._guideWarnIcon.sprite = self.guideAtlas:GetSprite(cfg.icon)
        self._guideWarnDescTxt:SetText(StringTable.Get(cfg.describe))
        if cfg.audio then
            AudioHelperController.RequestAndPlayUIVoiceAutoRelease(cfg.audio)
        end
    else
        self._guideWarnTurnGO:SetActive(false)
        return
    end
    self._guideWarnTurnGO:SetActive(true)
    local moveTime = 0.5
    local waitTime = 5
    -- 需要移动的
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Warn)
    self._guideWarnTurn.anchoredPosition = Vector2(-700, self._guideWarnTurnY)
    self._guideWarnCanvasGroup:DOFade(1.0, moveTime)
    self._guideWarnTurn:DOAnchorPosX(0, moveTime):OnComplete(
        function()
            self._guideWarnTurn:DOAnchorPosX(0, waitTime):OnComplete(
                function()
                    self._guideWarnTurn.anchoredPosition = Vector2(-700, self._guideWarnTurnY)
                    self._guideWarnCanvasGroup.alpha = 0.7
                    self._guideWarnTurnGO:SetActive(false)
                end
            )
        end
    )
end

function UIBattle:_RefreshMainState(stateID, stateName)
    self._mainStateID = stateID
    self._mainStateTxt:SetText(stateName)
end

function UIBattle:OnRefreshMVPText(value)
    self._mvpTxt:SetText(value)
end
function UIBattle:ShowHideCancelActiveSkillBtn(bShow)
    self.cancelActiveSkillBtn:SetActive(bShow)
end

function UIBattle:ShowHideBenumbTips(isShow)
    if isShow then
        self._benumbTipsQueue = DG.Tweening.DOTween.Sequence()
        self._benumbTipsQueue:Append(self._benumbTips:DOAnchorPosY(46, 0.5))
        self._benumbTipsQueue:Append(self._benumbTips:DOShakeAnchorPos(0.5, 10, 10, 10, false, true))
    else
        if self._benumbTipsQueue then
            self._benumbTipsQueue:Complete()
        end
        self._benumbTips:DOAnchorPosY(-26, 0.5)
    end
end

function UIBattle:ShowHideBesiegedTips(isShow)
    if isShow then
        local cfgLimitCount = Cfg.cfg_global["ui_besieged_tips_count"].IntValue
        ---@type RoleModule
        local roleModule = GameGlobal.GetModule(RoleModule)
        local pstId = roleModule:GetPstId()
        --玩家周围被围住，不能走的提示（跟随帐号）
        local dbKey = "UI_BESIEGED_TIPS_COUNT" .. pstId
        local dbCount = LocalDB.GetInt(dbKey)
        if dbCount < cfgLimitCount then
            self._besiegedTips:DOAnchorPosY(46, 0)
            LocalDB.SetInt(dbKey, dbCount + 1)
        end
    else
        self._besiegedTips:DOAnchorPosY(-26, 0)
    end
end

--------------------------- 新手引导三星条件 ↓-----------------------------------
function UIBattle:_ShowGuideCondition(matchResult)
    if not matchResult then
        return
    end
    local match = GameGlobal.GetModule(MatchModule)
    ---@type MatchEnterData
    local enterData = match:GetMatchEnterData()
    if MatchType.MT_Mission ~= enterData._match_type then
        return
    end
    local mission = GameGlobal.GameLogic():GetModule(MissionModule)
    local missionId = enterData:GetMissionCreateInfo().mission_id
    local targetMission = Cfg.cfg_guide_const["guide_condition_mission"].IntValue
    if missionId < targetMission then
        return
    end
    if not self.guideMatchResult then
        self.guideMatchResult = {}
    end
    local desc = ""
    local cur3StarProgress = ""
    ---@type MatchModule

    for i, id in ipairs(matchResult) do
        if not table.icontains(self.guideMatchResult, id) then
            desc = mission:Get3StarConditionDesc(id, "FFFFFF")
            cur3StarProgress = BattleStatHelper.Get3StarProgress(id)
            table.insert(self.guideMatchResult, id)
            local cfg = Cfg.cfg_threestarcondition[id]
            if not cfg or cfg.GuideShow == false then
                self._guideConditionGO:SetActive(false)
            else
                self:StartTask(
                    function(TT)
                        self._guideConditionGO:SetActive(true)
                        -- self._guideConditionAnim.normalizedTime = 1
                        self._guideConditionAnim:Play()
                        self._guideConditionDescTxt:SetText(desc)
                        local temp = cur3StarProgress
                        temp = string.sub(temp, 2, -2)
                        local params = string.split(temp, "/")
                        local str = ""
                        if params and params[1] and params[2] and tonumber(params[1]) < tonumber(params[2]) then
                            str = string.format(StringTable.Get("str_guide_condition_nofinish"), cur3StarProgress)
                        else
                            str = string.format(StringTable.Get("str_guide_condition_finish"), cur3StarProgress)
                        end
                        self._guideConditionFinishTxt:SetText(str)
                        YIELD(TT, 5000)
                        if not GameGlobal:GetInstance():IsCoreGameRunning() then
                            return
                        end
                        self._guideConditionGO:SetActive(false)
                    end,
                    self
                )
            end
        end
    end
end

--------------------------- 新手引导三星条件 ↑-----------------------------------

function UIBattle:GetPetBattleBtnByPetTempId(petTempId)
    return self._petAreaWidget:GetPetBattleBtnByPetTempId(petTempId)
end

function UIBattle:GetPetBattleBtnHp(_index)
    return self._petAreaWidget:GetPetBattleBtnHp(_index)
end

function UIBattle:GetPetSkillBtn()
    return self._skillAreaWidget:GetPetSkillBtn()
end

function UIBattle:GetTeamStateBtn()
    return self._teamState and self._teamState:GetGameObject("TeamState")
end

function UIBattle:GetChangeLeaderBtn()
    return self._teamState and self._teamState:GetGameObject("ChangeTeamLeader")
end

function UIBattle:GetTurnInfoBg()
    return self._turnInfo:GetGameObject("BG")
end

function UIBattle:GetUIBattleCollect()
    return self._progressInfo and self._progressInfo:GetGameObject("BG")
end

function UIBattle:GetUIBattleLimitRound()
    return self._progressInfo and self._progressInfo:GetGameObject("limitbg")
end

function UIBattle:GetUITrapSkillIcon(index)
    return self._trapSkillUI and self._trapSkillUI:GetTrapSkillIcon(index)
end

function UIBattle:GetUITrapSkillBtn()
    return self._trapSkillUI and self._trapSkillUI:GetGameObject("btnGo")
end

function UIBattle:GetChainPreviewGOBtn()
    return self.goChainPreview and self.goChainPreview:GetGameObject("btnOK")
end

function UIBattle:GetSpeedBtn()
    if self._widgetAutoFight then
        return self._widgetAutoFight:GetSpeedBtn()
    end
    -- if self.timeSpeed then
    --     self.timeSpeed:ForceDefaultSpeed()
    --     return self.timeSpeed:GetGameObject("img")
    -- end
end
function UIBattle:GetPetMultiSkillIndexBtn(index)
    return self._skillAreaWidget:GetPetMultiSkillIndexBtn(index)
end

--------------------------- 新手引导相关----------------------------------
---
function UIBattle:OnUiBattleVisible(visible)
    self._safeAreaCanvasGroup.alpha = visible
    self._safeAreaCanvasGroup.blocksRaycasts = (visible == 1) and true or false
end

function UIBattle:_OnUITrapSkillVisible(visible, trapEntityID)
    if visible then
        self._trapSkillUI:Init(trapEntityID)
    else
        self._trapSkillUI:GetGameObject():SetActive(false)
    end
end

function UIBattle:Shot()
    local shot = self:GetUIComponent("H3DUIBlurHelper", "shot")
    local shotRect = self:GetUIComponent("RectTransform", "shot")
    shotRect.gameObject:SetActive(true)
    local rt = shot:RefreshBlurTexture()
    return rt
end

function UIBattle:OnPetResurgence(petID)
end

function UIBattle:ResetLayout(TT)
    self._combo:HideCombo()
    self._petAreaWidget:ResetLayout(TT)
end

--圣物背包，应该用matchEnterData里的数据
function UIBattle:mazeBackpackBtnOnClick()
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    local relicCount = 0
    if self._isFromMiniMaze then
        local relicList = BattleStatHelper.GetAllMiniMazeRelic()
        relicCount = #relicList
    else
        local mazeCreateInfo = enterData:GetMazeCreateInfo()
        relicCount = #mazeCreateInfo.relics
    end

    if relicCount <= 0 then
        ToastManager.ShowToast(StringTable.Get("str_maze_no_relics"))
        return
    end
    self:ShowDialog("UIRugueLikeBackpackController", true, self._isFromMiniMaze)
end

function UIBattle:ShowUIEffect(name, duaration)
    self._effectLoader:LoadEffect(name)
    if self._effectEvent then
        --同时只有一个在播
        self._effectLoader:DestroyCurrentEffect()
        self._effectEvent = nil
    end
    self._effectEvent = GameGlobal.Timer():AddEvent(
        duaration,
        function()
            self._effectLoader:DestroyCurrentEffect()
            self._effectEvent = nil
        end
    )
end

function UIBattle:taleBuffInfoBtnOnClick()
    self:ShowDialog("UIBattleTaleBuffDesc")
end

function UIBattle:ShowAutoTestLogs()
    if EDITOR then
        self:ShowDialog("UIBattleAutoTest")
    end
end

--当前预览点选 触发的额外参数（罗伊 是否点选到机关 能量消耗不同）
---@param skillID number
function UIBattle:_OnSetCurPickExtraParam(skillID, extraParam)
    if not self._curPickExtraParam then
        self._curPickExtraParam = {}
    end
    self._curPickExtraParam[skillID] = extraParam
end
---取当前点选的额外参数
function UIBattle:GetCurPickExtraParam(skillID)
    if self._curPickExtraParam then
        return self._curPickExtraParam[skillID]
    end
end

function UIBattle:HandleBattleEnd(enterData, victory)
    --self._turnInfo:CancelRoundWarningState()
    self:_CloseAllDialogs(self:HideUIBattleQuit(enterData, victory))
    self._lowHpWarning:ShowHideLowHpWarning(false)
end

function UIBattle:SpawnCancelArea()
    ---取消连线功能的感应区
    local cancelAreaRoot = self:GetUIComponent("UISelectObjectPath", "CancelAreaRoot")
    ---@type UIWidgetCancelArea
    self._cancelAreaWidget = cancelAreaRoot:SpawnObject("UIWidgetCancelArea")
end

function UIBattle:SpawnFeature()
    local featureListSop = self:GetUIComponent("UISelectObjectPath", "featureList")
    ---@type UIWidgetFeatureList
    self._featureList = featureListSop:SpawnObject("UIWidgetFeatureList")
    self._featureList:SetUIBattle(self)
    local featureDayNightSop = self:GetUIComponent("UISelectObjectPath", "featureDayNight")
    self._featureDayNight = featureDayNightSop:SpawnObject("UIWidgetFeatureDayNight")
    local featureTrapCountSop = self:GetUIComponent("UISelectObjectPath", "featureTrapCount")
    self._featureTrapCount = featureTrapCountSop:SpawnObject("UIWidgetFeatureTrapCount")
    --local cardInfoGen = self:GetUIComponent("UISelectObjectPath", "CardInfoGen")
    ---@type UIWidgetFeatureCardInfo 技能UI
    --self._featureCardUI = cardInfoGen:SpawnObject("UIWidgetFeatureCardInfo")
    ---@type UnityEngine.GameObject
    self._featureCardInfoGenGo = self:GetGameObject("CardInfoGen")
    self._featureCardInfoGenGo:SetActive(false)
end
function UIBattle:GetFeatureCardUI(uiType)
    if not self._featureCardUI then
        local cardInfoGen = self:GetUIComponent("UISelectObjectPath", "CardInfoGen")
        local widgetName = "UIWidgetFeatureCardInfo"
        if uiType then--时装改ui表现
            if uiType == FeatureCardUiType.Skin1 then
                cardInfoGen:Engine():SetObjectName("UIWidgetFeatureCardInfo_l.prefab")
                widgetName = "UIWidgetFeatureCardInfo_L"
            end
        end
        ---@type UIWidgetFeatureCardInfo 技能UI
        self._featureCardUI = cardInfoGen:SpawnObject(widgetName)
        self._featureCardUI:SetUIBattle(self)
    end
    return self._featureCardUI
end
function UIBattle:ShowFeatureCardInfo(bShow)
    self._featureCardInfoGenGo:SetActive(bShow)
end

function UIBattle:FeatureOnChooseTargetConfirm()
    if self._featureList then
        self._featureList:OnChooseTargetConfirm()
    end
end

---处理长按头像时的情况
function UIBattle:HandleUIShowPetInfo(petPstID,isShow)
    --如果主动技弹窗处于显示状态先关闭弹窗
    -- if isShow and self.cancelActiveSkillBtn.activeSelf then
    --     self:CancelActiveSkillBtnOnClick(self.cancelActiveSkillBtn)
    -- end
end

function UIBattle:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIBattle:ShowAutoFightForbiddenMsg()
    return GameGlobal.GetUIModule(MatchModule):ShowAutoFightForbiddenMsg()
end

function UIBattle:GetBattleResultCompleteRT()
    return self.rt
end
function UIBattle:GetUITeamLeaderPstID()
    return self._petAreaWidget:GetUITeamLeaderPstID()
end
function UIBattle:GetUITeamLeaderName()
    return self._petAreaWidget:GetUITeamLeaderName()
end
function UIBattle:GetUITeamTailName()
    return self._petAreaWidget:GetUITeamTailName()
end
function UIBattle:GetUIFeatureCardBuffEffBeginScreenPos()
    return self._featureCardUI:GetCardBuffEffBeginScreenPos()
end
function UIBattle:GetUIFeatureCardBuffEffBeginPos()
    return self._featureCardUI:GetCardBuffEffBeginPos()
end
function UIBattle:SetTeamStateTeamLeader(data)
    self._teamState:SetTeamLeader(data)
end
function UIBattle:ShowChoosePartnerUI(bShow, choosePartners, choosenRelicID)
    if bShow then
        self:ShowDialog("UIMiniMazeChoosePartnerController", choosePartners, choosenRelicID)
    else
        GameGlobal.UIStateManager():CloseDialog("UIMiniMazeChoosePartnerController")
    end
end

function UIBattle:UIShowBossSpeak(animNames, bossImage, bossName, bossSpeak, duration, outAnim)
    GameGlobal.UIStateManager():ShowDialog("UIBattleBossSpeakDialog", animNames, bossImage, bossName, bossSpeak, duration,
        outAnim)
end

function UIBattle:_OnUIPopStarNumVisible(visible, gridNum, superGridNum)
    if visible then
        self._popStarNum:Init(gridNum, superGridNum)
    else
        self._popStarNum:HideNum()
    end
end
function UIBattle:UICheatHideArea(hidePart,bHide)
    self._cheatHideUIRecord[hidePart] = bHide
    if hidePart == UIBattleCheatHideUIArea.LeftUp then
        if self.btnSettingGO then
            self.btnSettingGO:SetActive(not bHide)
        end
        local eptGo = self:GetGameObject("UIBattleProgressInfoEpt")
        if eptGo then
            eptGo:SetActive(not bHide)
        end
    elseif hidePart == UIBattleCheatHideUIArea.LeftDown then
        local turnGo = self:GetGameObject("turnInfo")
        if turnGo then
            turnGo:SetActive(not bHide)
        end
        local affixGo = self:GetGameObject("mazeAffix")
        if affixGo then
            affixGo:SetActive(not bHide)
        end
        local featureGo = self:GetGameObject("featureList")
        if featureGo then
            featureGo:SetActive(not bHide)
        end
    elseif hidePart == UIBattleCheatHideUIArea.AutoArea then
        local autoGo = self:GetGameObject("SerialAutoFight")
        if autoGo then
            autoGo:SetActive(not bHide)
        end
    elseif hidePart == UIBattleCheatHideUIArea.StateArea then
        local rightUpGo = self:GetGameObject("RightUpAnchor")
        if rightUpGo then
            rightUpGo:SetActive(not bHide)
        end
    elseif hidePart == UIBattleCheatHideUIArea.DebugInfo then
        self._showDebugInfo = not self._showDebugInfo
        self:SwitchDebugInfo(self._showDebugInfo)
        self._cheatBtn:SetActive(true)
    elseif hidePart == UIBattleCheatHideUIArea.CheatBtn then
        ---@type UnityEngine.UI.Image
        local tempImage = self:GetUIComponent("Image", "btnTemp")
        if tempImage then
            if bHide then
                tempImage.color = Color(tempImage.color.r,tempImage.color.g,tempImage.color.b,0)
            else
                tempImage.color = Color(tempImage.color.r,tempImage.color.g,tempImage.color.b,1)
            end
        end
    end
end

---@param matchEnterData MatchEnterData
function UIBattle:_CheckSeasonBuffEntryBtn(matchEnterData)
    local seasonBuffEntryBtn = self:GetGameObject("SeasonBuffEntryBtn")
    local seasonBuffEntryBtnImg = self:GetUIComponent("Image", "SeasonBuffEntryBtn")
    self._curAffixCampaignType = nil
    local show = false
    ---@type CampaignModule
    local campaignModule = self:GetModule(CampaignModule)
    local missionInfo = matchEnterData:GetMissionCreateInfo()
    if matchEnterData:GetMatchType() == MatchType.MT_Season then
        show = true
    end
    seasonBuffEntryBtn:SetActive(show)
end

function UIBattle:SeasonBuffEntryBtnOnClick()
    self:ShowDialog("UISeasonBuffInnerGameInfo")
end