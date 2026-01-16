---@class UISeasonLevelStagePanelMode:Object
local UISeasonLevelStagePanelMode = {
    AwardsInfo = 1, --关卡详情（奖励、三星）
    BattleInfo = 2, --战场信息
}
_enum("UISeasonLevelStagePanelMode", UISeasonLevelStagePanelMode)

--[[
    UISeasonLevelStage
]]
---@class UISeasonLevelStage:UIController
_class("UISeasonLevelStage", UIController)
UISeasonLevelStage = UISeasonLevelStage

function UISeasonLevelStage:_GetComponents()
    --UI
    --region chapter
    ---@type UISelectObjectPath
    -- UIStage
    self._chapter_normal = self:GetUIComponent("UISelectObjectPath", "chapter_normal")

    self._chapterPool = self._chapter_normal
    --endregion

    --region enemy
    ---@type UISelectObjectPath
    -- UIStage
    self._enemy_normal = self:GetUIComponent("UISelectObjectPath", "enemy_normal")
    -- UIActivityStage
    self._enemy_hard = self:GetUIComponent("UISelectObjectPath", "enemy_hard")

    self._enemyPool = self._enemy_normal
    --endregion

    ---@type UISelectObjectPath
    self._sop = self:GetUIComponent("UISelectObjectPath", "conditions")
    self._conditionsGo = self:GetGameObject("conditions")
    self._conditionNo = self:GetGameObject("conditionNo")
    ---@type UnityEngine.UI.ScrollRect
    self._sr = self:GetUIComponent("ScrollRect", "ScrollView")

    self._txtCost = self:GetUIComponent("UILocalizationText", "txtCost")
    self._bgImg = self:GetUIComponent("RawImageLoader", "bgImg")
    self._unKnowImg = self:GetUIComponent("Image", "btnUnknown")

    self:AttachEvent(GameEventType.DiscoveryInitUIStage, self.Init)
    --Tips
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    local s = self:GetUIComponent("UISelectObjectPath", "itemTips")
    self._tips = s:SpawnObject("UISelectInfo")

    self._topTips = self:GetUIComponent("UISelectObjectPath", "TopTipInfo")
    self._topTipIcon = self:GetUIComponent("Image", "PowerTipsIcon")
    local aircraftModule = self:GetModule(AircraftModule)
    local room = aircraftModule:GetResRoom()
    local topIDList = {}
    if room then
        table.insert(topIDList, RoleAssetID.RoleAssetDoubleRes)
    end
    table.insert(topIDList, RoleAssetID.RoleAssetPhyPoint)
    if self._hideTopMenu then
        self:GetGameObject("stageTopPool"):SetActive(false)
    else
    end

    local itemCount = #topIDList
    --根据顶条设位置
    -- self._doublePos = self:GetUIComponent("RectTransform", "DoublePos")
    -- if itemCount <= 1 then
    --     self._doublePos.anchoredPosition = Vector2(513, 305)
    -- else
    --     self._doublePos.anchoredPosition = Vector2(157.5, 305)
    -- end

    -- 双倍自动掉落 活动关卡不显示
    local doubleDropTips = self:GetGameObject("DoubleDropTips")
    doubleDropTips:SetActive(false)

    --sprite
    self._conditionTitleBg2 = self:GetUIComponent("Image", "conditionTitleBg2")

    self._awardTitleBg2 = self:GetUIComponent("Image", "awardTitleBg2")

    self._awardTitleTex = self:GetUIComponent("UILocalizationText", "awardTitleTex")
    self._conditionTitleTex = self:GetUIComponent("UILocalizationText", "conditionTitleTex")

    local buffTips = self:GetUIComponent("UISelectObjectPath", "BuffTips")
    self._buffTips = buffTips:SpawnObject("UIResBuffDetail")

    -- ---@type UISelectObjectPath
    -- local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    -- ---@type UICommonTopButton
    -- self._backBtn = btns:SpawnObject("UICommonTopButton")
    -- self._backBtn:SetData(
    --     function()
    --         self:Close()
    --     end,nil,nil,false
    -- )
    ---@type UISeasonModule
    self._uiSeasonModule = GameGlobal.GetUIModule(SeasonModule)
    ---@type UISeasonTopBtn
    self._backBtn = UIWidgetHelper.SpawnObject(self, "btns", "UISeasonTopBtn")
    self._backBtn:SetData(
        function()
            self:Close()
        end,
        nil,
        nil,
        nil
    )
    local isTeamRecord = false --self._campComp.IsTeamRecord and self._campComp:IsTeamRecord(self._missionID)
    if isTeamRecord then
        local params = {
            {
                "TeamRecordBtn",
                function()
                    self:ShowDialog("UIActivityLevelRecordController", self._campComp, self._missionID)
                end
            }
        }
        self._backBtn:SetData_Extra(params)
    end

    self.costGo = self:GetGameObject("cost")
    self.fightBtnTextTr = self:GetUIComponent("RectTransform", "fightBtnText")
    self._backgroundObj = self:GetGameObject("Background")

    self._noDiffAwardGo = self:GetGameObject("NoDiffAward")
    self._seasonAwardGo = self:GetGameObject("SeasonAward")
    self._seasonNormalAwardGo = self:GetGameObject("MultiAwardGroup1")
    self._seasonHardAwardGo = self:GetGameObject("MultiAwardGroup2")
    self._wordAndElem = self:GetUIComponent("UISelectObjectPath", "wordAndElem")
    self._btnIcon = self:GetUIComponent("Image", "powerIcon")
    ---@type UICustomWidgetPool
    self.buffLevelGen = self:GetUIComponent("UISelectObjectPath", "BuffLevelArea")
    self.btnWord = self:GetGameObject("btnUnknown")
    self.panelBattleInfoGo = self:GetGameObject("PanelBattleInfo")
    self.panelAwardsInfoGo = self:GetGameObject("PanelAwardsInfo")
    self.wordsContentNormal = self:GetUIComponent("UISelectObjectPath", "WordsNormalContent")
    self.wordsContentHard = self:GetUIComponent("UISelectObjectPath", "WordsHardContent")
    self.wordsNormalGo = self:GetGameObject("WordsNormalScroll")
    self.wordsHardGo = self:GetGameObject("WordsHardScroll")

    self._normalBtnText = self:GetUIComponent("UILocalizationText", "normal")
    self._hardBtnText = self:GetUIComponent("UILocalizationText", "hard")
    -- self._switchDiffSliderRect = self:GetUIComponent("RectTransform", "Slider")
    self._switchDiffSliderNormalGo = self:GetGameObject("SliderNormal")
    self._switchDiffSliderHardGo = self:GetGameObject("SliderHard")
    -- self._deSelectColor = Color(53 / 255, 32 / 255, 9 / 255)
    -- self._selectColor = Color(247 / 255, 233 / 255, 217 / 255)
    self._chapterNormalNameText = self:GetUIComponent("UILocalizedTMP", "ChapterNameNormal")
    self._chapterHardNameText = self:GetUIComponent("UILocalizedTMP", "ChapterNameHard")
    self._chapterNameNormalGo = self:GetGameObject("ChapterNameNormal")
    self._chapterNameHardGo = self:GetGameObject("ChapterNameHard")
    self._awardsPanelBtnText = self:GetUIComponent("UILocalizationText", "AwardsPanelBtnText")
    self._battleInfoPanelBtnText = self:GetUIComponent("UILocalizationText", "BattleInfoPanelBtnText")
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnAfterUILayerChanged)
    self._anim = self:GetUIComponent("Animation", "UICanvas")

    self._battleInfoBtn = self:GetGameObject("BattleInfoPanelBtn")
    self._recordGo = self:GetGameObject("Record")

    self._hardMask = self:GetGameObject("hardMask")
    self._normalMask = self:GetGameObject("normalMask")
    self._hardShadow = self:GetUIComponent("Shadow", "hard")
    self._normalShadow = self:GetUIComponent("Shadow", "normal")
    self._hardBtnTr = self:GetUIComponent("RectTransform", "SliderHard")
    self._normalBtnTr = self:GetUIComponent("RectTransform", "SliderNormal")
    self._hardEft = self:GetGameObject("effect")
end

function UISeasonLevelStage:OnShow(uiParams)
    GameGlobal.EngineInput().multiTouchEnabled = false
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIStage.spriteatlas", LoadType.SpriteAtlas)
    self._gradeAtlas = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)
    ---@type MissionModule
    self._module = self:GetModule(MissionModule)
    self._missionID = uiParams[1]        --点击的关卡id
    self._rawMissionID = self._missionID --进入关卡详情的原始关卡id
    --日常关逻辑
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    self._isDailyLevel = missionCfg.IsDailylevel == 1

    ---@type UISeasonObj
    self._seasonObj = uiParams[2]
    if not self._seasonObj then
        ---@type SeasonModule
        local seasonModule = self:GetModule(SeasonModule)
        if seasonModule then
            self._seasonObj = seasonModule:GetCurSeasonObj()
        end
    end
    ---@type SeasonMissionComponent
    self._component = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._seasonObj:GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
    self._allPassMissionInfo = self._componentInfo.m_pass_mission_info
    ---@type ActionPointComponent
    self._pointComp = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.ACTION_POINT)

    self._curLevelProgress = 1 --当前进度 用于读配置 普通关为1
    if self._isDailyLevel then
        self._curLevelProgress = self._componentInfo.m_daily_info.m_progress
    end

    ---@type MissionModule
    local missionModule = self:GetModule(MissionModule)
    local ctx = missionModule:TeamCtx()
    ctx:InitSeasonTeam(self._componentInfo.m_formation_list)

    self._campType = ECampaignType.CAMPAIGN_TYPE_INLAND_SEASON
    self._autoFightShow = true
    self._hideTopMenu = true --隐藏顶条
    self._hideCost = false   --隐藏挑战按钮上的体力图标

    self._curPanel = UISeasonLevelStagePanelMode.AwardsInfo
    self:_GetComponents()
    self:Init()

    self:_SetStoryBtn()

    --自动战斗
    self:InitAutoBtnState()

    if self._hideCost then
        self.costGo:SetActive(false)
        --self.fightBtnTextTr.anchoredPosition = Vector2(0, 6)
    else
        self.costGo:SetActive(true)
        --self.fightBtnTextTr.anchoredPosition = Vector2(-71, 6)
    end
    self:InitBuffLevelArea()
    self:ShowMainUI(false)

    self._battleInfoBtn:SetActive(not self._isDailyLevel)

    if self._hasMultiDiff and self._missionDiff == UISeasonLevelDiff.Hard then
        self:DispatchEvent(GameEventType.OnSeasonMainBottomEftPlay, true)
        self._hardEft:SetActive(true)
    else
        self._hardEft:SetActive(false)
    end
end

function UISeasonLevelStage:LoadDataOnEnter(TT, res) --sjs_todo 挪位置，改用season相关接口
    -- ---@type UIActivityCampaign
    -- self._campaign = UIActivityCampaign:New()
    -- self._campaign:LoadCampaignInfo(
    --     TT,
    --     res,
    --     ECampaignType.CAMPAIGN_TYPE_INLAND_SEASON,
    --     ECCampaignSeasonComponentID.SEASON_MISSION,
    --     ECCampaignSeasonComponentID.ACTION_POINT
    -- )
    -- ---@type SeasonMissionComponent
    -- self._component = self._campaign:GetComponent(ECCampaignSeasonComponentID.SEASON_MISSION)
    -- ---@type SeasonMissionComponentInfo
    -- self._componentInfo = self._campaign:GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
    -- self._pointComp = self._campaign:GetComponent(ECCampaignSeasonComponentID.ACTION_POINT)
    -- ---@type MissionModule
    -- local missionModule = self:GetModule(MissionModule)
    -- local ctx = missionModule:TeamCtx()
    -- ctx:InitSeasonTeam(self._componentInfo.m_formation_list)
end

--region AutoOpenState
---@param stageId number 关卡id
function UISeasonLevelStage.GetAutoOpenState(matchType, stageId)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local playerPrefsKey = pstId .. "AutoOpenState" .. matchType --XXXXXXXXAutoOpenState1_4006050
    if stageId then
        playerPrefsKey = playerPrefsKey .. "_" .. stageId
    end
    return UnityEngine.PlayerPrefs.HasKey(playerPrefsKey)
end

---@param isOpen boolean 是否开启
function UISeasonLevelStage.SetAutoOpenState(matchType, stageId, isOpen)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local playerPrefsKey = pstId .. "AutoOpenState" .. matchType --XXXXXXXXAutoOpenState1_4006050
    if stageId then
        playerPrefsKey = playerPrefsKey .. "_" .. stageId
    end
    if isOpen then
        UnityEngine.PlayerPrefs.SetInt(playerPrefsKey, 1)
    else
        UnityEngine.PlayerPrefs.DeleteKey(playerPrefsKey)
    end
end

--endregion
--检查可开启连续自动战斗
function UISeasonLevelStage:_CanAutoFight()
    local tipsStr = ""
    local cfg = Cfg.cfg_global["auto_fight_need_3_star"]
    if cfg and cfg.StrValue then
        tipsStr = cfg.StrValue
    end
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    if not missionCfg then
        return false, tipsStr
    end
    local enableParam = missionCfg.EnableSerialAutoFight
    if not enableParam then
        return false
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
        return false, tipsStr
        --不应该显示
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE then
        return true
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK then
        if self._allPassMissionInfo[self._missionID] then
            if self:HasPassThreeStar(missionCfg) then --需要三星通过
                return true
            else
                return false, tipsStr
            end
        else
            return false, tipsStr
        end
    end
    return false
end

function UISeasonLevelStage:_CanShowAutoFight()
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    if not missionCfg then
        return false
    end
    local enableParam = missionCfg.EnableSerialAutoFight
    if not enableParam then
        return false
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
        return false
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE then
        return true
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK then
        return true
    end
end

function UISeasonLevelStage:InitAutoBtnState()
    local enable, msg = self:_CanAutoFight()
    local canShow = self:_CanShowAutoFight()
    self._autoFightShow = canShow
    self._autoBtnEnable = enable
    self._autoBtnMsg = msg

    local autoFight_root = self:GetGameObject("autoFightRoot")
    local autoFight_lock = self:GetGameObject("lock")
    local autoFight_unlock = self:GetGameObject("unlock")
    --显隐
    autoFight_root:SetActive(self._autoFightShow and self._autoBtnEnable)
    ---@type AircraftModule
    local aircraftModule = self:GetModule(AircraftModule)
    local room = aircraftModule:GetResRoom()
    local textId = room and "str_season_mission_info_auto_sweep" or "str_season_mission_info_auto"
    UIWidgetHelper.SetLocalizationText(self, "AutoFightText", StringTable.Get(textId))
    --置灰
    --autoFight_lock:SetActive(not self._autoBtnEnable)
    autoFight_lock:SetActive(false)
    --autoFight_unlock:SetActive(self._autoBtnEnable)
end

--检查显示熟练的智慧按钮
function UISeasonLevelStage:_CheckShowWordBuff()
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    if not missionCfg then
        return false
    end
    if missionCfg.WordBuff and missionCfg.WordBuff > 0 then
    else
        return false
    end
    --当前难度或更高难度三星通过，解锁熟练指挥
    local checkMissionCfgs = {}
    local missionGroupId = missionCfg.GroupID
    local missionGroupCfgs = Cfg.cfg_season_mission { GroupID = missionGroupId }
    if #missionGroupCfgs > 0 then
        for index, value in ipairs(missionGroupCfgs) do
            if value.OrderID >= missionCfg.OrderID then
                table.insert(checkMissionCfgs, value)
            end
        end
    end
    for index, checkMissionCfgs in ipairs(checkMissionCfgs) do
        if self:HasPassThreeStar(checkMissionCfgs) then --三星通关
            return true
        end
    end
    return false
end

function UISeasonLevelStage:AutoFightBtnOnClick()
    if self._autoBtnEnable then
        --连续自动战斗
        local id = self._missionID
        local power = self._needPower
        local unlock = true
        --local titleState = 1--只显示自动战斗
        local campParams = UISerialAutoFightOptionCampParams:New(
            self._pointComp, self._campType, nil, 0,
            self._component:GetCampaignMissionComponentId(),
            self._component:GetCampaignMissionParamKeyMap()
        )
        self:ShowDialog("UISerialAutoFightOption",
            MatchType.MT_Season, id, power, nil, unlock, nil, campParams, nil)
    else
        ToastManager.ShowToast(StringTable.Get(self._autoBtnMsg))
    end
end

function UISeasonLevelStage:OnHide()
    GameGlobal.EngineInput().multiTouchEnabled = true
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self:DetachEvent(GameEventType.DiscoveryInitUIStage, self.Init)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryShowHideChapter, true)
    if self._refreshPowerTimer then
        GameGlobal.Timer():CancelEvent(self._refreshPowerTimer)
        self._refreshPowerTimer = nil
    end
    if self._refreshPowerTask then
        GameGlobal.TaskManager():KillTask(self._refreshPowerTask)
        self._refreshPowerTask = nil
    end
    if self._hasMultiDiff and self._missionDiff == UISeasonLevelDiff.Hard then
        self:DispatchEvent(GameEventType.OnSeasonMainBottomEftPlay, false)
    end
end

function UISeasonLevelStage:HasPassThreeStar(missionCfg)
    local missionId = missionCfg.ID
    if not self._allPassMissionInfo[missionId] then
        return false
    end
    local missionFinishInfo = self._allPassMissionInfo[missionId]
    if missionCfg.ThreeStarCondition1 and (missionFinishInfo.star & 1) == 0 then
        return false
    end

    if missionCfg.ThreeStarCondition2 and (missionFinishInfo.star & 2) == 0 then
        return false
    end

    if missionCfg.ThreeStarCondition3 and (missionFinishInfo.star & 4) == 0 then
        return false
    end

    return true
end

function UISeasonLevelStage:GetSortedArr(awardType, cfg, stageAwardType)
    local list = UICommonHelper:GetInstance():GetDropByAwardType(awardType, cfg)
    local vecSort = SortedArray:New(Algorithm.COMPARE_CUSTOM, DiscoveryStage._LessComparer)
    if list then
        for i, v in ipairs(list) do
            local award = Award:New()
            award:InitWithCount(v.ItemID, v.Count, v.Type)
            award:FlushType(stageAwardType)
            vecSort:Insert(award)
        end
    end
    return vecSort.elements
end

function UISeasonLevelStage:ProcessAward(missionCfg, noNormal)
    local missionId = missionCfg.ID
    local awards = {}
    --赛季新增日常关后所有奖励字段变为数组 与其他配置格式不同 这里构建出相同的结构
    local progress = self._curLevelProgress
    local awardCfg = {
        FirstDropId = missionCfg.FirstDropId and missionCfg.FirstDropId[progress],
        PassFixDropId = missionCfg.PassFixDropId and missionCfg.PassFixDropId[progress],
        CPassRandomAward = nil,
        ThreeStarDropId = missionCfg.ThreeStarDropId and missionCfg.ThreeStarDropId[progress]
    }
    if not self:HasPassThreeStar(missionCfg) then
        local awardsStar = self:GetSortedArr(AwardType.ThreeStar, awardCfg, StageAwardType.Star)
        if awardsStar then
            for i, v in ipairs(awardsStar) do
                awards[#awards + 1] = v
            end
        end
    end
    if not self._allPassMissionInfo[missionId] then
        local awardsFirst = self:GetSortedArr(AwardType.First, awardCfg, StageAwardType.First)
        if awardsFirst then
            for i, v in ipairs(awardsFirst) do
                awards[#awards + 1] = v
            end
        end
    end
    if not noNormal then
        local normalArr = self:GetSortedArr(AwardType.Pass, awardCfg, StageAwardType.Normal)
        if normalArr then
            for i, v in ipairs(normalArr) do
                awards[#awards + 1] = v
            end
        end
    end
    return awards
end

function UISeasonLevelStage:RefreshAwardsShowState()
    self._noDiffAwardGo = self:GetGameObject("NoDiffAward")
    self._seasonAwardGo = self:GetGameObject("SeasonAward")
    self._seasonNormalAwardGo = self:GetGameObject("MultiAwardGroup1")
    self._seasonHardAwardGo = self:GetGameObject("MultiAwardGroup2")
    --self._noDiffAwardGo:SetActive(not self._hasMultiDiff)
    self._noDiffAwardGo:SetActive(false) --统一样式
    --self._seasonAwardGo:SetActive(self._hasMultiDiff)
    self._seasonAwardGo:SetActive(true)
    if self._hasMultiDiff then
        self._seasonNormalAwardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Normal)
        self._seasonHardAwardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Hard)
    else --统一样式
        self._seasonNormalAwardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Normal)
        self._seasonHardAwardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Hard)
    end
    if self._sr then
        self._sr.horizontalNormalizedPosition = 0
    end
    if self._normalMultiAwardList then
        self._normalMultiAwardList:ResetScrollPos()
    end
    if self._hardMultiAwardList then
        self._hardMultiAwardList:ResetScrollPos()
    end
end

function UISeasonLevelStage:RefreshWordsArea()
    if self._hasMultiDiff then
        self.wordsNormalGo:SetActive(self._missionDiff == UISeasonLevelDiff.Normal)
        self.wordsHardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Hard)
    else
        self.wordsNormalGo:SetActive(true)
        self.wordsHardGo:SetActive(false)
    end
end

function UISeasonLevelStage:InitWords()
    if self._hasMultiDiff then
        local normalMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Normal]
        local hardMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Hard]
        self:_InitWords(self.wordsContentNormal, normalMissionId)
        self:_InitWords(self.wordsContentHard, hardMissionId)
    else
        self:_InitWords(self.wordsContentNormal, self._missionID)
    end
    self:RefreshWordsArea()
end

function UISeasonLevelStage:_InitWords(sop, missionId)
    local missionCfg = Cfg.cfg_season_mission[missionId]
    local wordsTb = {}
    local usedWordIDList = {}
    local buff = missionCfg.BaseWordBuff
    if buff then
        local words = type(buff) == "table" and buff or { buff }
        for _, wordId in ipairs(buff) do
            if not table.icontains(usedWordIDList, wordId) then
                table.insert(wordsTb, self:_GetWordDesc(missionCfg.ID, wordId))
                table.insert(usedWordIDList, wordId)
            end
        end
    end
    local data = wordsTb
    local count = #data
    sop:SpawnObjects("UIStageWordItem", count)
    local pools = sop:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]
        local tex = data[i]
        item:SetData(tex)
    end
end

function UISeasonLevelStage:_GetWordDesc(levelId, wordId)
    local word = Cfg.cfg_word_buff[wordId]
    if not word then
        Log.exception("cfg_word_buff 中找不到词缀:", wordId, "levelId:", levelId)
    end

    local name = StringTable.Get(word.Word[1])
    local desc = StringTable.Get(word.Desc)
    local tex = "【" .. name .. "】 " .. desc
    return tex
end

function UISeasonLevelStage:RefreshBtnUnknown()
    local show = self:_CheckShowWordBuff()
    self.btnWord:SetActive(show)
end

function UISeasonLevelStage:InitForMultiDiff()
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    self._hasMultiDiff = false
    self._diffMissonIdMap = {}
    if self._isDailyLevel then
        --日常关没有难度
        self._missionDiff = UISeasonLevelDiff.Normal
        self._hasMultiDiff = false
        self._diffMissonIdMap[UISeasonLevelDiff.Normal] = self._missionID
    else
        self._missionDiff = missionCfg.OrderID
        local missionGroupId = missionCfg.GroupID
        self._missionGroupCfgs = Cfg.cfg_season_mission { GroupID = missionGroupId }
        if #self._missionGroupCfgs > 1 then
            self._hasMultiDiff = true
        end
    end
    if self._hasMultiDiff then
        for index, value in ipairs(self._missionGroupCfgs) do
            if value.OrderID == UISeasonLevelDiff.Normal then   --普通难度
                self._diffMissonIdMap[UISeasonLevelDiff.Normal] = value.ID
            elseif value.OrderID == UISeasonLevelDiff.Hard then --困难难度
                self._diffMissonIdMap[UISeasonLevelDiff.Hard] = value.ID
            end
        end
    end
    -- self._diffAreaGo:SetActive(self._hasMultiDiff)
    self._switchDiffSliderNormalGo:SetActive(self._hasMultiDiff)
    self._switchDiffSliderHardGo:SetActive(self._hasMultiDiff)

    self:RefreshDiffArea()
end

function UISeasonLevelStage:RefreshPanelShow()
    self.panelAwardsInfoGo:SetActive(self._curPanel == UISeasonLevelStagePanelMode.AwardsInfo)
    self.panelBattleInfoGo:SetActive(self._curPanel == UISeasonLevelStagePanelMode.BattleInfo)
end

function UISeasonLevelStage:RefreshPanelBg()
    local bgName = "exp_s1_map_di31"
    if self._missionDiff == UISeasonLevelDiff.Normal then
        if self._curPanel == UISeasonLevelStagePanelMode.AwardsInfo then
            bgName = "exp_s1_map_di31"
        else
            bgName = "exp_s1_map_di32"
        end
    else
        if self._curPanel == UISeasonLevelStagePanelMode.AwardsInfo then
            bgName = "exp_s1_map_di33"
        else
            bgName = "exp_s1_map_di34"
        end
    end
    self._bgImg:LoadImage(bgName)
end

function UISeasonLevelStage:RefreshPanelText()
    if self._missionDiff == UISeasonLevelDiff.Normal then
        if self._curPanel == UISeasonLevelStagePanelMode.AwardsInfo then
            self._awardsPanelBtnText.color = Color(107 / 255, 67 / 255, 30 / 255, 1)
            self._battleInfoPanelBtnText = Color(111 / 255, 95 / 255, 62 / 255, 1)
        else
            self._awardsPanelBtnText.color = Color(111 / 255, 95 / 255, 62 / 255, 1)
            self._battleInfoPanelBtnText = Color(107 / 255, 67 / 255, 30 / 255, 1)
        end
    else
        if self._curPanel == UISeasonLevelStagePanelMode.AwardsInfo then
            self._awardsPanelBtnText.color = Color(107 / 255, 67 / 255, 30 / 255, 1)
            self._battleInfoPanelBtnText = Color(108 / 255, 69 / 255, 51 / 255, 1)
        else
            self._awardsPanelBtnText.color = Color(108 / 255, 69 / 255, 51 / 255, 1)
            self._battleInfoPanelBtnText = Color(107 / 255, 67 / 255, 30 / 255, 1)
        end
    end
end

function UISeasonLevelStage:RefreshDiffArea()
    if self._missionDiff == UISeasonLevelDiff.Normal then
        -- self._normalBtnText.color = self._selectColor
        -- self._hardBtnText.color = self._deSelectColor
        -- self._switchDiffSliderRect.anchoredPosition = Vector2(-55, -1)
        -- self._switchDiffSliderNormalGo:SetActive(true)
        -- self._switchDiffSliderHardGo:SetActive(false)
        self._normalBtnTr:SetAsLastSibling()
        self._normalBtnTr.anchoredPosition = Vector2(0, 68)
        self._normalShadow.enabled = true
        self._normalMask:SetActive(false)
        self._hardBtnTr:SetAsFirstSibling()
        self._hardBtnTr.anchoredPosition = Vector2(10, -68)
        self._hardShadow.enabled = false
        self._hardMask:SetActive(true)
    elseif self._missionDiff == UISeasonLevelDiff.Hard then
        -- self._normalBtnText.color = self._deSelectColor
        -- self._hardBtnText.color = self._selectColor
        -- self._switchDiffSliderRect.anchoredPosition = Vector2(55, -1)
        -- self._switchDiffSliderNormalGo:SetActive(false)
        -- self._switchDiffSliderHardGo:SetActive(true)
        self._hardBtnTr:SetAsLastSibling()
        self._hardBtnTr.anchoredPosition = Vector2(0, 68)
        self._hardShadow.enabled = true
        self._hardMask:SetActive(false)
        self._normalBtnTr:SetAsFirstSibling()
        self._normalBtnTr.anchoredPosition = Vector2(10, -68)
        self._normalShadow.enabled = false
        self._normalMask:SetActive(true)
    end
end

function UISeasonLevelStage:InitAllAwards()
    --有多种难度的关卡，奖励用专属样式
    if self._hasMultiDiff then
        local normalRewards = self:_ProcessLevelDiffAwards(self._diffMissonIdMap[UISeasonLevelDiff.Normal],
            UISeasonLevelDiff.Normal)
        local normalRewardsWithOutPass = self:_ProcessLevelDiffAwards(self._diffMissonIdMap[UISeasonLevelDiff.Normal],
            UISeasonLevelDiff.Normal, true) --困难模式下排除普通难度的通关奖励
        local hardRewards = self:_ProcessLevelDiffAwards(self._diffMissonIdMap[UISeasonLevelDiff.Hard],
            UISeasonLevelDiff.Hard)

        local normalMultiAwards = { normalRewards }
        ---@type UISelectObjectPath
        local normalAwardGen = self:GetUIComponent("UISelectObjectPath", "MultiAwardGroup1")
        self._normalMultiAwardList = normalAwardGen:SpawnObject("UISeasonStageMultiAwardList")
        self._normalMultiAwardList:SetData(normalMultiAwards)

        local hardMultiAwards = { hardRewards }
        if normalRewardsWithOutPass and #normalRewardsWithOutPass > 0 then
            table.insert(hardMultiAwards, normalRewardsWithOutPass)
        end
        ---@type UISelectObjectPath
        local hardAwardGen = self:GetUIComponent("UISelectObjectPath", "MultiAwardGroup2")
        self._hardMultiAwardList = hardAwardGen:SpawnObject("UISeasonStageMultiAwardList")
        self._hardMultiAwardList:SetData(hardMultiAwards)
    else
        local rewards = self:_ProcessLevelDiffAwards(self._missionID, self._missionDiff)

        local multiAwards = { rewards }
        if self._missionDiff == UISeasonLevelDiff.Normal then
            ---@type UISelectObjectPath
            local normalAwardGen = self:GetUIComponent("UISelectObjectPath", "MultiAwardGroup1")
            self._normalMultiAwardList = normalAwardGen:SpawnObject("UISeasonStageMultiAwardList")
            self._normalMultiAwardList:SetData(multiAwards)
        elseif self._missionDiff == UISeasonLevelDiff.Hard then
            ---@type UISelectObjectPath
            local hardAwardGen = self:GetUIComponent("UISelectObjectPath", "MultiAwardGroup2")
            self._hardMultiAwardList = hardAwardGen:SpawnObject("UISeasonStageMultiAwardList")
            self._hardMultiAwardList:SetData(multiAwards)
        else
            ---@type UISelectObjectPath
            local normalAwardGen = self:GetUIComponent("UISelectObjectPath", "MultiAwardGroup1")
            self._normalMultiAwardList = normalAwardGen:SpawnObject("UISeasonStageMultiAwardList")
            self._normalMultiAwardList:SetData(multiAwards)
        end
    end
    -- else
    --     local missionCfg = Cfg.cfg_season_mission[self._missionID]
    --     ---@type table<int, Award>
    --     local awards = self:ProcessAward(missionCfg)
    --     if not awards then
    --         return
    --     end
    --     local count = table.count(awards)
    --     ---@type UnityEngine.UI.GridLayoutGroup
    --     local grid = self:GetUIComponent("GridLayoutGroup", "Content")
    --     --local awardScrollView = self:GetUIComponent("ScrollRect", "ScrollView")
    --     local contentSizeFilter = self:GetUIComponent("ContentSizeFitter", "Content")
    --     ---@type UnityEngine.RectTransform
    --     local contentRect = self:GetUIComponent("RectTransform", "Content")
    --     if count > 4 then
    --         grid.childAlignment = UnityEngine.TextAnchor.MiddleLeft
    --         contentSizeFilter.enabled = true
    --     else
    --         grid.childAlignment = UnityEngine.TextAnchor.MiddleCenter
    --         contentSizeFilter.enabled = false
    --     end
    --     contentRect.localPosition = Vector3(0, 0, 0)

    --     ---@type UISelectObjectPath
    --     local sop = self:GetUIComponent("UISelectObjectPath", "Content")
    --     sop:SpawnObjects("UIAwardItem", count)
    --     ---@type UIAwardItem[]
    --     local list = sop:GetAllSpawnList()
    --     for i, v in ipairs(list) do
    --         v:Flush(awards[i])
    --     end
    -- end
    self:RefreshAwardsShowState()
    local awardAnimDelay = 0
    self:PlayAnimAwardList(awardAnimDelay)
end

function UISeasonLevelStage:PlayAnimAwardList(totalAnimDelay)
    local multiAwardList = nil
    if self._missionDiff == UISeasonLevelDiff.Normal then
        multiAwardList = self._normalMultiAwardList
    elseif self._missionDiff == UISeasonLevelDiff.Hard then
        multiAwardList = self._hardMultiAwardList
    else
        multiAwardList = self._normalMultiAwardList
    end
    if multiAwardList then
        multiAwardList:SetWaitAnim()
        multiAwardList:PlayAnim(totalAnimDelay)
    end
end

function UISeasonLevelStage:_ProcessLevelDiffAwards(missionId, levelDiff, noNormal)
    if missionId then
        local useMissionCfg = Cfg.cfg_season_mission[missionId]
        if useMissionCfg then
            ---@type table<int, Award>
            local useAwards = self:ProcessAward(useMissionCfg, noNormal)
            if useAwards then
                useAwards.levelDiff = levelDiff
                return useAwards
            end
        end
    end
end

---初始化
function UISeasonLevelStage:Init()
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    self:InitForMultiDiff()
    self._reach = true

    --体力默认是棱镜
    self._powerID = RoleAssetID.RoleAssetPhyPoint
    self._needPower = missionCfg.NeedPower
    --体力是棱镜或者活动里的行动点
    if missionCfg.NeedAP then
        --本关卡消耗行动点，而不是棱镜
        self._powerID = missionCfg.NeedAP[1]
        self._needPower = missionCfg.NeedAP[2]
    end
    local needPowerText = self._needPower

    ---初始化体力相关ui
    --按钮图标
    if self._powerID == RoleAssetID.RoleAssetPhyPoint then
        -- self._powerPool = self:GetUIComponent("UISelectObjectPath", "powerpool")
        -- ---@type UIPowerInfo
        -- local powerPool = self._powerPool:SpawnObject("UIPowerInfo")
        -- powerPool:SetData(self._power)
    else
        if not self._pointComp then
            Log.exception("关卡体力为行动点,但没有活动的行动点组件")
        end
        local cmpID = self._pointComp:GetComponentCfgId()
        local pointCfg = self._pointComp:GetActionPointConfig()
        local itemCfg = Cfg.cfg_top_tips[pointCfg.ItemID]
        self._btnIcon.sprite = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas):GetSprite(itemCfg.Icon)
        self._topTipIcon.sprite = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas):GetSprite(itemCfg.Icon)
        local cur, ceil = self._pointComp:GetItemCount()
        if cur < self._needPower then
            needPowerText = "<color=#FF0000>" .. self._needPower .. "</color>"
        end
    end

    self._txtCost:SetText(needPowerText)

    --self._txtCost.text = tostring(needPowerText)

    -- 背景图
    -- self._backgroundObj:SetActive(false)
    self:RefreshPanelShow()
    self:RefreshPanelBg()
    self:RefreshPanelText()
    self:InitChapterName()
    self:RefreshThreeStarArea(true, 0)
    self:InitAllAwards()

    self._reachGo = self:GetGameObject("reachGo")
    self._reachGo:SetActive(not self._reach)
    self:InitEnemys()
    self:InitWords()
    self:RefreshRecommendLv()
    self:RefreshAreasTitleStyle()
    self:RefreshWordsArea()
    self:RefreshBtnUnknown()
    self:RefreshPowerTips()
    self:InitAutoBtnState()
    self:_SetStoryBtn()

    self._refreshPowerTargetTime = self._pointComp:GetRegainEndTime()
    self._refreshPowerTimer = GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:_Countdown()
        end
    )
    self:_Countdown()
    -- missionCfg.TeamRecord and missionCfg.TeamRecord == 1
    self._recordGo:SetActive(missionCfg.TeamRecord and missionCfg.TeamRecord == 1)
end

function UISeasonLevelStage:UpdateCondition(three_star_condition, conditions)
    local l_cur_star_num = 0
    for index, value in ipairs(three_star_condition) do
        if value.satisfy == true then
            l_cur_star_num = l_cur_star_num + 1
        end
    end
    local l_finish_star_num = #conditions

    for index, value in ipairs(three_star_condition) do
        if l_finish_star_num == l_cur_star_num then
            value:FlushSatisfy(false)
        end
        for i, v in ipairs(conditions) do
            if v == index then
                value:FlushSatisfy(true)
            end
        end
    end
end

function UISeasonLevelStage:BtnFightOnClick(go)
    if self._reach == false then
        return
    end
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    local enough = false
    local roleModule = self:GetModule(RoleModule)
    --local leftPower = roleModule:GetAssetCount(self._powerID)
    local cur, ceil = self._pointComp:GetItemCount()
    local leftPower = cur
    local enough = (leftPower >= self._needPower)
    if not enough then
        if self._powerID == RoleAssetID.RoleAssetPhyPoint then
            self:ShowDialog("UIGetPhyPointController")
        else
            local itemName = StringTable.Get(Cfg.cfg_item[self._powerID].Name)
            ToastManager.ShowToast(StringTable.Get("str_mission_error_power_not_enough", itemName))
        end
        return
    end
    ---@type TeamsContext
    local ctx = self._module:TeamCtx()
    ctx:Init(
        TeamOpenerType.Season,
        {
            self._missionID,
            self._component:GetCampaignMissionComponentId(),
            self._component:GetCampaignMissionParamKeyMap(),
            nil,
            self._curLevelProgress
        }
    )
    self:Lock("DoEnterTeam")
    ctx:ShowDialogUITeams()
end

function UISeasonLevelStage:IsPowerEnough()
    if self._curStage then
        local roleModule = self:GetModule(RoleModule)
        local leftPower = roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
        local enough = (leftPower >= self._curStage.need_power)
        if not enough then
            ----临时处理前三章 前三章如果没通关 进局可以不要体力
            if
                self._module:IsFirstPassMission(self._curStage.id) and
                self._module:IsMissionFirstPassCanIgnorPower(self._curStage.id)
            then
                enough = true
            end
        end
        return enough
    end
end

function UISeasonLevelStage:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end

function UISeasonLevelStage:BgOnClick()
    self:Close()
end

function UISeasonLevelStage:ThreeStarTipsBtnOnClick(go)
    self:ShowDialog("UIThreeStarTips")
end

function UISeasonLevelStage:BtnUnknownOnClick(go)
    local buffData = {}
    buffData.name = ""
    buffData.des = ""
    local word = Cfg.cfg_word_buff[BattleConst.WordBuffForMission]
    if word then
        if word.BuffID and word.BuffID[1] then
            local buff = Cfg.cfg_buff[word.BuffID[1]]
            if buff then
                buffData.name = StringTable.Get(buff.Name)
                buffData.des = StringTable.Get(buff.Desc)
            end
        end
    end
    local pos = go.transform.position
    self._buffTips:SetData(buffData, pos, Vector3(-250, 160, 0))
    local buffTips = self:GetUIComponent("UISelectObjectPath", "BuffTips")
    self._buffTips = buffTips:SpawnObject("UIResBuffDetail")
end

--region UISeasonLevelStage 剧情回顾
function UISeasonLevelStage:_SetStoryBtn()
    self._activityGroupObj = self:GetGameObject("ActivityGroup")
    self._imgBlack = self:GetGameObject("imgBlack")

    local checkPassMissionId = self._missionID
    local storyList = DiscoveryStoryList:New()
    if self._hasMultiDiff then --多难度下剧情相同
        checkPassMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Normal]
    end
    storyList:Init(self._missionID)
    local flag = self._allPassMissionInfo[checkPassMissionId] and storyList:Count() ~= 0 and true or false
    self._activityGroupObj:SetActive(flag)
end

function UISeasonLevelStage:BtnPlotOnClick()
    local storyList = DiscoveryStoryList:New()
    storyList:Init(self._missionID)

    if storyList then
        if storyList:Count() == 1 then
            local story = storyList.list[1]
            UISeasonHelper.PlayStoryInSeasonScence(story.id)
        else
            local before = storyList:GetStoryByStoryType(StoryTriggerType.BeforeFight)
            local after = storyList:GetStoryByStoryType(StoryTriggerType.AfterFight)
            if not before and not after then
                Log.warn("### no story in curStage", storyList.stageId)
            end
            if before and after then
                self._imgBlack:SetActive(true)
                UISeasonHelper.PlayStoryInSeasonScence(
                    before.id,
                    function()
                        self:StartTask(
                            function(TT)
                                YIELD(TT)
                                UISeasonHelper.PlayStoryInSeasonScence(
                                    after.id,
                                    function()
                                        self._imgBlack:SetActive(false)
                                    end)
                            end
                        )
                    end)
            else
                local story = storyList.list[1]
                UISeasonHelper.PlayStoryInSeasonScence(story.id)
            end
        end
    end
end

function UISeasonLevelStage:SliderHardOnClick()
    if self._hasMultiDiff then
        if self._missionDiff == UISeasonLevelDiff.Hard then
            return
        end
        self:_SwitchDiff()
    end
end

function UISeasonLevelStage:SliderNormalOnClick()
    if self._hasMultiDiff then
        if self._missionDiff == UISeasonLevelDiff.Normal then
            return
        end
        self:_SwitchDiff()
    end
end

function UISeasonLevelStage:_SwitchDiff()
    if self._hasMultiDiff then
        if self._missionDiff == UISeasonLevelDiff.Normal then
            self._missionDiff = UISeasonLevelDiff.Hard
            self._missionID = self._diffMissonIdMap[UISeasonLevelDiff.Hard]
        elseif self._missionDiff == UISeasonLevelDiff.Hard then
            self._missionDiff = UISeasonLevelDiff.Normal
            self._missionID = self._diffMissonIdMap[UISeasonLevelDiff.Normal]
        end
        self._uiSeasonModule:SetCurrentSeasonLevelDiff(self._missionDiff)
        if self._anim then
            local animName = "uieff_Stage_switch_hard"
            if self._missionDiff == UISeasonLevelDiff.Normal then
                animName = "uieff_Stage_switch_normal"
            elseif self._missionDiff == UISeasonLevelDiff.Hard then
                animName = "uieff_Stage_switch_hard"
            end
            self._anim:Play(animName)
        end
        self:RefreshDiffArea()
        self:RefreshPanelShow()
        self:RefreshPanelBg()
        self:RefreshPanelText()
        self:RefreshAwardsShowState()
        local awardAnimDelay = 200
        self:PlayAnimAwardList(awardAnimDelay)
        self:RefreshWordsArea()
        self:RefreshBtnUnknown()
        self:RefreshChapter()
        local threeStarAnimTotalDelay = 200
        self:RefreshThreeStarArea(true, threeStarAnimTotalDelay) --延迟播动画
        self:RefreshEnemyArea()
        self:RefreshRecommendLv()
        self:RefreshAreasTitleStyle()
        self:RefreshPowerTips()
        self:RefreshPowerCost()
        self:RefreshBuffArea()
        self:InitAutoBtnState()
        self:_SetStoryBtn()
    end
end

function UISeasonLevelStage:DiffInfoBtnOnClick(go)
    self:ShowDialog("UISeasonStageDiffTips")
end

function UISeasonLevelStage:RefreshPowerTips()
    local contentText = self:GetUIComponent("UILocalizationText", "PowerTipsText")
    --活动id
    local componentInfo = self._pointComp:ComponentInfo()
    local compID = self._pointComp:GetComponetCfgId(componentInfo.m_campaign_id, componentInfo.m_component_id)
    local cfg = self._pointComp:GetActionPointConfig()
    if cfg == nil then
        Log.exception("cfg_component_action_point中找不到组件ID:", compID)
    end
    local cur, ceil = self._pointComp:GetItemCount()
    contentText:SetText(string.format("<color=#ff9d32>%s</color>/%s", cur, ceil))
end

function UISeasonLevelStage:RefreshPowerCost()
    --按钮图标
    local needPowerText = self._needPower
    if self._powerID == RoleAssetID.RoleAssetPhyPoint then
    else
        if not self._pointComp then
            Log.exception("关卡体力为行动点,但没有活动的行动点组件")
        end
        local cur, ceil = self._pointComp:GetItemCount()
        if cur < self._needPower then
            needPowerText = "<color=#FF0000>" .. self._needPower .. "</color>"
        end
    end

    self._txtCost:SetText(needPowerText)
end

function UISeasonLevelStage:InitChapterName()
    if self._hasMultiDiff then
        local normalMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Normal]
        local hardMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Hard]
        self:_InitChapterName(self._chapterNormalNameText, normalMissionId)
        self:_InitChapterName(self._chapterHardNameText, hardMissionId)
    else
        self:_InitChapterName(self._chapterNormalNameText, self._missionID)
    end
    self:RefreshChapter()
end

function UISeasonLevelStage:_InitChapterName(text, missionId)
    local missionCfg = Cfg.cfg_season_mission[missionId]
    if text and missionCfg then
        text:SetText(StringTable.Get(missionCfg.Name))
    end
end

function UISeasonLevelStage:RefreshChapter()
    if self._hasMultiDiff then
        self._chapterNameNormalGo:SetActive(self._missionDiff == UISeasonLevelDiff.Normal)
        self._chapterNameHardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Hard)
    else
        self._chapterNameNormalGo:SetActive(true)
        self._chapterNameHardGo:SetActive(false)
    end
end

function UISeasonLevelStage:RefreshThreeStarArea(playAnim, animDelay)
    local missionCfg = Cfg.cfg_season_mission[self._missionID]
    local threeStarConditions = {}
    --if missionCfg.IgnoreThreeStar == 0 then
    if missionCfg.ShowCondition and missionCfg.ShowCondition == 1 then
        --三星条件
        local ids = {
            missionCfg.ThreeStarCondition1,
            missionCfg.ThreeStarCondition2,
            missionCfg.ThreeStarCondition3
        }
        for i, v in ipairs(ids) do
            local cond = StageCondition:New()
            cond:Init(i, v)
            table.insert(threeStarConditions, cond)
        end
        if self._allPassMissionInfo[self._missionID] then
            local starCount, completeStarList = self._module:ParseStarInfo(self._allPassMissionInfo[self._missionID]
                .star)
            self:UpdateCondition(threeStarConditions, completeStarList)
        end
    end

    --条件
    if #threeStarConditions > 0 then
        --self._conditionGo:SetActive(true)
        self._conditionsGo:SetActive(true)
        self._conditionNo:SetActive(false)
        self._sop:SpawnObjects("UISeasonConditionItem", #threeStarConditions)
        ---@type UISeasonConditionItem[]
        self._conditions = self._sop:GetAllSpawnList()
        for i, v in ipairs(self._conditions) do
            if v:IsEnable() then
                v:Flush(threeStarConditions[i], i)
                if playAnim then
                    v:SetWaitAnim()
                end
            end
        end
        if playAnim then
            self:PlayAnimThreeStarArea(animDelay)
        end
    else
        self._conditionsGo:SetActive(false)
        self._conditionNo:SetActive(true)
    end
end

function UISeasonLevelStage:PlayAnimThreeStarArea(totalAnimDelay)
    if self._conditions then
        local eachCellAnimDelay = 50
        local cellDelay = 50
        if totalAnimDelay then
            cellDelay = cellDelay + totalAnimDelay
        end
        for i, v in ipairs(self._conditions) do
            if v:IsEnable() then
                v:PlayAnim(cellDelay)
                cellDelay = cellDelay + eachCellAnimDelay
            end
        end
    end
end

function UISeasonLevelStage:InitEnemys()
    if self._hasMultiDiff then
        local normalMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Normal]
        local hardMissionId = self._diffMissonIdMap[UISeasonLevelDiff.Hard]
        self:_InitEnemy(self._enemy_normal, normalMissionId)
        self:_InitEnemy(self._enemy_hard, hardMissionId)
    else
        self:_InitEnemy(self._enemy_normal, self._missionID)
    end
    self:RefreshEnemyArea()
end

function UISeasonLevelStage:_InitEnemy(sop, missionId)
    local missionCfg = Cfg.cfg_season_mission[missionId]
    local progress = self._curLevelProgress
    ---@type UIStageEnemy
    local enemyObj = sop:SpawnObject("UIStageEnemy")
    local recommendAwaken = missionCfg.RecommendAwaken[progress] and missionCfg.RecommendAwaken[progress] or 0
    local recommendLV = missionCfg.RecommendLV[progress] and missionCfg.RecommendLV[progress] or 0

    local color = Color(1, 1, 1, 1)
    local enemyTitleBgSprite = nil
    local enemyTitleBg2Sprite = nil
    -- if missionCfg.Type == ActivityMissionType.FightBoss then
    --     color = Color(54 / 255, 54 / 255, 54 / 255, 1)
    --     --self._awardTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     --self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     enemyTitleBgSprite = self._atlas:GetSprite("map_guanqia_tiao3")
    --     enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")
    -- else
    --     color = Color(54 / 255, 54 / 255, 54 / 255, 1)
    --     --self._awardTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     --self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     enemyTitleBgSprite = self._atlas:GetSprite("map_bantou4_frame")
    --     enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")
    -- end

    enemyObj:Flush(
        recommendAwaken,
        recommendLV,
        missionCfg.FightLevel[progress] or missionCfg.LevelID,
        color,
        enemyTitleBgSprite,
        enemyTitleBg2Sprite,
        true,
        true,
        true
    )
end

function UISeasonLevelStage:RefreshEnemyArea()
    self._enemyNormalGo = self:GetGameObject("enemy_normal")
    self._enemyHardGo = self:GetGameObject("enemy_hard")
    if self._hasMultiDiff then
        self._enemyNormalGo:SetActive(self._missionDiff == UISeasonLevelDiff.Normal)
        self._enemyHardGo:SetActive(self._missionDiff == UISeasonLevelDiff.Hard)
    else
        self._enemyNormalGo:SetActive(true)
        self._enemyHardGo:SetActive(false)
    end
end

function UISeasonLevelStage:RefreshRecommendLv()
    --觉醒
    local imgGrade = self:GetUIComponent("Image", "imgGrade")
    local lvText = self:GetUIComponent("UILocalizationText", "RecommendLvText")
    local buffLvText = self:GetUIComponent("UILocalizationText", "RecommendBuffLvText")
    local cfg = Cfg.cfg_season_mission[self._missionID]
    local progress = self._curLevelProgress
    local recommendAwaken = cfg.RecommendAwaken[progress] and cfg.RecommendAwaken[progress] or 0
    local recommendLV = cfg.RecommendLV[progress] and cfg.RecommendLV[progress] or 0
    local recommendBuffLV = cfg.RecommendSeasonBuffLV[progress] and cfg.RecommendSeasonBuffLV[progress] or 0
    imgGrade.sprite = self._gradeAtlas:GetSprite(UIPetModule.GetAwakeSpriteNameByParam(3, recommendAwaken))
    local lvStr = tostring(recommendLV)
    lvText:SetText(lvStr)
    local buffLvStr = tostring(recommendBuffLV)
    buffLvText:SetText(buffLvStr)
    -- self._reLv = self:GetUIComponent("UILocalizationText", "ReLv")
    -- local tex = StringTable.Get("str_discovery_node_recommend_lv")
    -- if recommendAwaken and recommendAwaken > 0 then
    --     tex = tex .. " " .. StringTable.Get("str_pet_config_common_advance") .. recommendAwaken
    -- end
    -- if recommendLV then
    --     tex = tex .. " LV." .. recommendLV
    -- end
    -- if recommendBuffLV and recommendBuffLV > 0 then
    --     tex = tex .. " " .. StringTable.Get("str_season_recommend_buff_lv",recommendBuffLV)
    -- end
    -- self._reLv:SetText(tex)
end

function UISeasonLevelStage:RefreshAreasTitleStyle()
    -- local missionCfg = Cfg.cfg_season_mission[self._missionID]
    -- local color = Color(1, 1, 1, 1)
    -- local enemyTitleBgSprite = nil
    -- local enemyTitleBg2Sprite = nil
    -- if missionCfg.Type == ActivityMissionType.FightBoss then
    --     color = Color(54 / 255, 54 / 255, 54 / 255, 1)
    --     self._awardTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     enemyTitleBgSprite = self._atlas:GetSprite("map_guanqia_tiao3")
    --     enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")
    -- else
    --     color = Color(54 / 255, 54 / 255, 54 / 255, 1)
    --     self._awardTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")
    --     enemyTitleBgSprite = self._atlas:GetSprite("map_bantou4_frame")
    --     enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")
    -- end
    -- self._awardTitleTex.color = color
    -- self._conditionTitleTex.color = color
end

function UISeasonLevelStage:InitBuffLevelArea()
    ---@type UISeasonBuffStageArea
    self._buffLevelArea = self.buffLevelGen:SpawnObject("UISeasonBuffStageArea")
    if self._buffLevelArea then
        self._buffLevelArea:SetData(self._seasonObj)
    end
end

function UISeasonLevelStage:RefreshBuffArea()
    if self._buffLevelArea then
        self._buffLevelArea:RefreshInfo()
    end
end

function UISeasonLevelStage:Close()
    self:_CloseDialogWithAnim()
end

function UISeasonLevelStage:_CloseDialogWithAnim(callback)
    UIWidgetHelper.PlayAnimation(self, "UICanvas", "uieff_Stage_out", 433, function()
        if callback then
            callback()
        end
        self:_Resume()
        self:ShowMainUI(true)
        self:CloseDialog()
    end)
end

--关闭关卡界面的时候处理赛季地图相关的表现
function UISeasonLevelStage:_Resume()
    ---@type SeasonMapEventPoint
    local eventPoint = self._uiSeasonModule:SeasonManager():SeasonMapManager():GetEventPoint(self._rawMissionID)
    if eventPoint then
        eventPoint:InterruptExpress() --如果不是进局内的方式关闭界面，要中断当前事件点的表现
    end
    local mgr = self._uiSeasonModule:SeasonManager()
    local player = mgr:SeasonPlayerManager():GetPlayer()
    player:PlayAnimation(SeasonPlayerAnimation.Stand)
    local seasonAudio = mgr:SeasonAudioManager():GetSeasonAudio()
    if seasonAudio then
        seasonAudio:PlayVoice(false)
    end
    local recordSize = mgr:SeasonCameraManager():SeasonCamera():GetRecordSize()
    if recordSize then
        mgr:SeasonCameraManager():SeasonCamera():SetSize(recordSize)
        mgr:SeasonCameraManager():SeasonCamera():SetRecordSize(nil)
        mgr:SeasonCameraManager():SeasonCamera():Focus(Vector3(player:Position().x, 0, player:Position().z))
    end
    mgr:ClearLocks()
    self:GetModule(SeasonModule):ClearLevelExpress()
end

function UISeasonLevelStage:BattleInfoPanelBtnOnClick()
    self._curPanel = UISeasonLevelStagePanelMode.BattleInfo
    self:RefreshPanelShow()
    self:RefreshPanelBg()
    self:RefreshPanelText()
end

function UISeasonLevelStage:AwardsPanelBtnOnClick()
    self._curPanel = UISeasonLevelStagePanelMode.AwardsInfo
    self:RefreshPanelShow()
    self:RefreshPanelBg()
    self:RefreshPanelText()
end

function UISeasonLevelStage:PowerTopTipsOnClick(go)
    -- if not self._topTipsInfo then
    --     ---@type UITopTipsContext
    --     self._topTipsInfo = self._topTips:SpawnObject("UITopTipsContext")
    -- end
    -- self._topTipsInfo:SetData(self._pointComp:GetItemId(), go)
    self:ShowDialog("UISeasonActionPointTip", self._pointComp, go.transform.anchoredPosition)
end

function UISeasonLevelStage:_Countdown()
    local now = GetSvrTimeNow()
    local time = self._refreshPowerTargetTime - now
    if time <= 0 then
        if self._refreshPowerTask then
            GameGlobal.TaskManager():KillTask(self._refreshPowerTask)
            self._refreshPowerTask = nil
        end
        self._refreshPowerTask = self:StartTask(self._ReqFlushPower, self)
    end
end

function UISeasonLevelStage:_ReqFlushPower(TT)
    local res = AsyncRequestRes:New()
    self._pointComp:HandleActionPointData(TT, res)
    if res:GetSucc() then
        self:RefreshPowerTips()
        self:RefreshPowerCost()
    else
        if self._refreshPowerTimer then
            GameGlobal.Timer():CancelEvent(self._refreshPowerTimer) --失败了就不更新了
            self._refreshPowerTimer = nil
        end
        Log.exception("请求刷新行动点失败:", res:GetResult())
    end
end

function UISeasonLevelStage:OnAfterUILayerChanged()
    local topui = GameGlobal.UIStateManager():IsTopUI(self:GetName())
    if topui then
        if self._refreshPowerTask then
            GameGlobal.TaskManager():KillTask(self._refreshPowerTask)
            self._refreshPowerTask = nil
        end
        self._refreshPowerTask = self:StartTask(self._ReqFlushPower, self)
    end
end

function UISeasonLevelStage:ShowMainUI(show)
    ---@type UISeasonMain
    local controller = GameGlobal.UIStateManager():GetController("UISeasonMain")
    if controller then
        controller:SetShow(show)
    end
end

function UISeasonLevelStage:RecordOnClick(go)
    self:ShowDialog("UIActivityLevelRecordController", self._component, self._missionID)
end
