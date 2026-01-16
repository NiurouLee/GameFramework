_class("UIBattleResultComplete", UIController)
---@class UIBattleResultComplete:UIController
UIBattleResultComplete = UIBattleResultComplete

function UIBattleResultComplete:LoadDataOnEnter(TT, res, uiParams)
    ---@type MatchEnterData
    self._enterData = self:GetModule(MatchModule):GetMatchEnterData()
    if self._enterData == nil then
        res:SetSucc(false)
        return
    end

    res:SetSucc(true)
end

function UIBattleResultComplete:OnShow(uiParams)
    HelperProxy:GetInstance():SetGameTimeScale(1)

    self._bNeedPopActivityAward = false
    --是否需要弹出活动掉落物品弹窗
    self._popActivityAwardEnd = true
    self._bNeedShowLevelUp = false
    self._activityAwards = {}
    ---@type UILocalizationText
    self._dialogLeftGO = self:GetGameObject("DialogLeft")
    self._dialogRightGO = self:GetGameObject("DialogRight")

    self._dialogLeftTxt = self:GetUIComponent("UILocalizationText", "DialogTextLeft")
    self._dialogRightTxt = self:GetUIComponent("UILocalizationText", "DialogTextRight")

    ---@type UILocalizationText
    self._stageTitleTxt = self:GetUIComponent("UILocalizationText", "StageTitleText")
    self._stageTitle = self:GetGameObject("StageTitle")
    ---三星结果------
    ---@type UnityEngine.GameObject
    self._star1RootGO = self:GetGameObject("Condition1")
    self._star2RootGO = self:GetGameObject("Condition2")
    self._star3RootGO = self:GetGameObject("Condition3")
    ---@type UILocalizationText
    self._star1Txt = self:GetUIComponent("UILocalizationText", "ConditionText1")
    self._star2Txt = self:GetUIComponent("UILocalizationText", "ConditionText2")
    self._star3Txt = self:GetUIComponent("UILocalizationText", "ConditionText3")
    ---@type UnityEngine.GameObject
    self._starIcon1 = self:GetGameObject("StarIcon1")
    -- self._helpStarIcon1 = self:GetGameObject("helppetstar")
    -- self._helpStarIcon1:SetActive(false)
    self._starIcon2 = self:GetGameObject("StarIcon2")
    self._starIcon3 = self:GetGameObject("StarIcon3")
    ---@type table<int, UnityEngine.GameObject>
    self._starRootGOList = { self._star1RootGO, self._star2RootGO, self._star3RootGO }
    ---@type table<int, UILocalizationText>
    self._starTxtList = { self._star1Txt, self._star2Txt, self._star3Txt }
    ---@type table<int, UnityEngine.GameObject>
    self._starIconList = { self._starIcon1, self._starIcon2, self._starIcon3 }
    local stars = self:GetGameObject("stars")
    ---@type UnityEngine.UI.Image[]
    self._stars = stars:GetComponentsInChildren(typeof(UnityEngine.UI.Image))
    ---三星结果end---
    ---经验值 等级
    ---@type UnityEngine.GameObject
    self._levelIcon = self:GetGameObject("Level")
    ---@type UILocalizationText
    self._expTxt = self:GetUIComponent("UILocalizationText", "ExpNumberText")
    ---@type UILocalizationText
    self._txtExpAdd = self:GetUIComponent("UILocalizationText", "txtExpAdd")
    ---@type UILocalizationText
    self._levelTxt = self:GetUIComponent("UILocalizationText", "LevelNumberText")
    self._expParent = self:GetGameObject("Exp")
    self._awardParent = self:GetGameObject("ResultInfo")

    ---金币 道具奖励
    ---@type UICustomWidgetPool
    self._itemPool = self:GetUIComponent("UISelectObjectPath", "Items")
    self._itemPoolRect = self:GetUIComponent("RectTransform", "itemPoolRect")
    --赛季关卡 奖励用特殊样式
    self._normalItemsGo = self:GetGameObject("itemPoolRect")
    self._seasonItemsGo = self:GetGameObject("SeasonItems")
    if self._seasonItemsGo then
        self._seasonItemsGo:SetActive(false)
    end
    self._seasonItemsRect = self:GetUIComponent("RectTransform", "SeasonItems")

    self._isWin = uiParams[1] or false
    ---@type table<int, MatchPetInfo>
    self._petData = uiParams[2]
    ---@type table<int, MatchPet>
    self._matchPetData = {}
    for i = 1, #self._petData do
        self._matchPetData[i] = MatchPet:New(self._petData[i])
    end
    local rt = uiParams[3]
    if rt then
        local shot = self:GetUIComponent("RawImage", "shot")
        shot.texture = rt
    end
    self.autoParam = uiParams[4]
    if self._isWin then
        --队伍全员立绘
        ---@type table<int, RawImageLoader>
        self._imgRoleList = {}
        ---@type table<int, RawImageLoader>
        self._imgShadowList = {}
        for i = 1, 5 do
            self._imgRoleList[i] = self:GetUIComponent("RawImageLoader", "imgRole" .. i)
            self._imgShadowList[i] = self:GetUIComponent("RawImageLoader", "imgShadow" .. i)
        end
    else
        ---@type RawImageLoader
        self._imgRole = self:GetUIComponent("RawImageLoader", "imgRole1")
        ---@type RawImageLoader
        self._imgShadow = self:GetUIComponent("RawImageLoader", "imgShadow1")
    end

    ---@type UnityEngine.UI.Slider
    self._expSlider = self:GetUIComponent("Slider", "ExpSlider")
    ---@type UISelectObjectPath
    self._selectItemInfoPool = self:GetUIComponent("UISelectObjectPath", "ItemInfoPool")
    ---@type UISelectInfo
    self._selectItemInfo = self._selectItemInfoPool:SpawnObject("UISelectInfo")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIBattleResultComplete.spriteatlas", LoadType.SpriteAtlas)
    self._imgComplete = self:GetUIComponent("RawImageLoader", "imgComplete")
    self._imgCompleteGo = self:GetGameObject("imgComplete")

    self._imgCompleteTitle = self:GetUIComponent("RawImageLoader", "completetitle")
    self._imgCompleteEn = self:GetUIComponent("RawImageLoader", "completeen")
    self._completeen = self:GetGameObject("completeen")
    self._completeen:SetActive(not HelperProxy:GetInstance():IsInEnglish())

    self._starConditionGO = self:GetGameObject("StarCondition")
    self._resInstanceGO = self:GetGameObject("resinstance")
    self._resInsNameTxt = self:GetUIComponent("UILocalizationText", "fubenname")
    self._resInsDiffTxt = self:GetUIComponent("UILocalizationText", "difficuty")
    self._resInsDiffGood = self:GetUIComponent("Image", "good")

    --==================== 夏日活动二期 ========================
    self._summerLevelTypeToScoreColor = {
        [UISummerActivity2LevelType.Normal] = Color(136 / 255, 0, 0, 1),
        [UISummerActivity2LevelType.Boss] = Color(136 / 255, 0, 0, 1),
        [UISummerActivity2LevelType.Affix] = Color(136 / 255, 0, 0, 1)
    }

    self._summerTwoScore = self:GetGameObject("SummerTwoScore")
    self._summerTwoNameGo = self:GetGameObject("SummerTwoName")
    self._summerTwoNameBgImg = self:GetUIComponent("RawImageLoader", "SummerTwoNameBg")
    self._summerTwoAnim = self:GetUIComponent("Animation", "SummerTwoScoreBg")
    self._summerTwoStageNameLabel = self:GetUIComponent("UILocalizationText", "SummerTwoStageName")
    self._summerTwoScoreBgGo = self:GetGameObject("SummerTwoScoreBg")
    self._summerTwoScoreHistoryGo = self:GetGameObject("SummerTwoScoreHistory")
    self._summerTwoScoreIcon1Img = self:GetUIComponent("RawImageLoader", "SummerTwoScoreIcon1")
    self._summerTwoScore1Label = self:GetUIComponent("UILocalizationText", "SummerTwoScore1")
    self._summerTwoScoreShadown1Label = self:GetUIComponent("UILocalizationText", "SummerTwoScoreShadown1")
    self._summerTwoScoreCurrentGo = self:GetGameObject("SummerTwoScoreCurrent")
    self._summerTwoScoreIcon2Img = self:GetUIComponent("RawImageLoader", "SummerTwoScoreIcon2")
    self._summerTwoScore2Label = self:GetUIComponent("UILocalizationText", "SummerTwoScore2")
    self._summerTwoScoreShadown2Label = self:GetUIComponent("UILocalizationText", "SummerTwoScoreShadown2")

    --=========================================================

    --==================== 危机合约 ========================
    self._n21CCNameGo = self:GetGameObject("N21CCName")
    self._n21CCStageNameLabel = self:GetUIComponent("UILocalizationText", "N21CCStageName")
    self._n21CCScoreGo = self:GetGameObject("N21CCScore")
    self._n21CCHistoryScoreLabel = self:GetUIComponent("UILocalizationText", "N21CCHistoryScore")
    self._n21CCCurrentScoreLabel = self:GetUIComponent("UILocalizationText", "N21CCCurrentScore")
    self._n21CCNameGo:SetActive(false)
    self._n21CCScoreGo:SetActive(false)
    --=========================================================

    --=================== 大航海 ===================

    self._sailingLoader = self:GetUIComponent("UISelectObjectPath", "UISailingPanel")

    --==============================================

    --==================== 吸血鬼 ===================
    self._vampireLoader = self:GetUIComponent("UISelectObjectPath", "UIVampirePanel")
    --==============================================

    self._n5Right = self:GetGameObject("N5Right")
    self._n5RightAnimation = self:GetUIComponent("Animation", "N5Right")
    self._n5Left = self:GetGameObject("N5Left")
    self._militaryExploitLeftValue = self:GetUIComponent("UILocalizationText", "MilitaryExploitLeftValue")
    self._militaryExploitRightValue = self:GetUIComponent("UILocalizationText", "MilitaryExploitRightValue")
    self._n5StageName = self:GetUIComponent("UILocalizationText", "N5StageName")
    self._n5StageDifficulty = self:GetUIComponent("UILocalizationText", "N5StageDifficulty")
    self._difficultyImage = self:GetUIComponent("RawImageLoader", "DifficultyImage")

    self._tex1 = self:GetUIComponent("UILocalizationText", "Txt1")
    self._tex2 = self:GetUIComponent("UILocalizationText", "Txt2")

    self._arrowRect = self:GetUIComponent("RectTransform", "Arrow")
    self._worldBoss = self:GetGameObject("WorldBoss")
    self._worldBossAnimation = self:GetUIComponent("Animation", "WorldBoss")
    self._damgeLeftValue = self:GetUIComponent("UILocalizationText", "DamgeLeftValue")
    self._damageRightValue = self:GetUIComponent("UILocalizationText", "DamageRightValue")

    self._activityImage = self:GetUIComponent("RawImageLoader", "ActivityImage")
    self._activityImageObj = self:GetGameObject("ActivityImage")
    self._activityResultLeft = self:GetUIComponent("UISelectObjectPath", "ActivityResultLeft")
    self._activityResultRight = self:GetUIComponent("UISelectObjectPath", "ActivityResultRight")
    -- --助战功能---------------
    --助战QA_助战可获得3星_20210813
    -- self._helpPetGO = self:GetGameObject("helppet")
    -- self._helpPetGO:SetActive(false)
    -- local hpm = self:GetModule(HelpPetModule)
    -- if hpm then
    --     local helpPetKey = hpm:UI_GetHelpPetKey()
    --     self._helpPetGO:SetActive(helpPetKey and helpPetKey > 0)
    --     if helpPetKey and helpPetKey > 0 then
    --         self._helpStarIcon1:SetActive(self._isWin)
    --     else
    --         self._helpStarIcon1:SetActive(false)
    --     end
    -- end
    -- --助战功能---------------

    --diff
    self._diffRoot = self:GetUIComponent("UISelectObjectPath", "DiffRoot")

    ---@type UICustomWidgetPool
    self._autoBtnPool = self:GetUIComponent("UISelectObjectPath", "pool")

    self._blockMask = self:GetGameObject("blockMask")
    ---@type SerialAutoFightModule
    local md = GameGlobal.GetModule(SerialAutoFightModule)
    if md:IsRunning() then
        self._blockMask:SetActive(true)
        ---@type UIWidgetSerialButton
        self._autoBtn = self._autoBtnPool:SpawnObject("UIWidgetSerialButton")
    else
        self._blockMask:SetActive(false)
    end

    self:AttachEvent(GameEventType.CancelSerialAutoFight, self.OnCancelSerialAutoFight)

    self._taskIDList = {}
    self._3StarTaskID = -1
    self:FillInfo()
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowItemTips)

    --战斗胜利失败的队长语音
    if self._matchPetData[1] then
        self:StartTask(
            function(TT)
                YIELD(TT)
                local tplID = self._matchPetData[1]:GetTemplateID()
                local pm = GameGlobal.GetModule(PetAudioModule)
                if self._isWin then
                    pm:PlayPetAudio("BattleSucceed", tplID)
                else
                    pm:PlayPetAudio("BattleFail", tplID)
                end
            end
        )
    end

    --战斗胜利失败的bgm
    local bgmID = nil
    if self._isWin then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundBattleComplete)
        bgmID = CriAudioIDConst.BGMBattleSuccess
    else
        bgmID = CriAudioIDConst.BGMBattleFail
    end
    --bgm混音效果结束
    AudioHelperController.SetBGMMixerGroup(AudioConstValue.AuroralTimeMixerGroupName, AudioConstValue.DefaultMixerValue)
    AudioHelperController.PlayBGMById(bgmID, AudioConstValue.BGMCrossFadeTime)

    --获得经验增长的动画时长
    self._expIncreaseAnimTime = 1
    --经验获取动画是否结束
    self._expIncreaseAnimEnd = true

    if MatchType.MT_MiniMaze == self._enterData._match_type then
        ---@type ATransitionComponent
        local transCmp = self:GetUIComponent("ATransitionComponent", "UIBattleResultComplete")
        transCmp:ChangeAnim("uieff_UIBattleResultComplete_Lose01", 60)
    elseif MatchType.MT_Chess == self._enterData._match_type then
        ---@type ATransitionComponent
        local transCmp = self:GetUIComponent("ATransitionComponent", "UIBattleResultComplete")
        if MatchType.MT_SailingMission == self._enterData._match_type then
            --动作名及进入动画时长为美术配置 为支持动态控制UI进入播放不同动画 需要在此根据逻辑设置动画名及进入时长
            transCmp:ChangeAnim("uieff_UIBattleResultComplete_Lose01", 60)
        else
            --动作名及进入动画时长为美术配置 为支持动态控制UI进入播放不同动画 需要在此根据逻辑设置动画名及进入时长
            transCmp:ChangeAnim("uieff_UIBattleResultComplete_Lose", 96)
        end
    else
        ---@type ATransitionComponent
        local transCmp = self:GetUIComponent("ATransitionComponent", "UIBattleResultComplete")

        --战斗失败需要动态修改UI进入离开动画
        if not self._isWin then
            --动作名及进入动画时长为美术配置 为支持动态控制UI进入播放不同动画 需要在此根据逻辑设置动画名及进入时长
            transCmp:ChangeAnim("uieff_UIBattleResultComplete_Lose", 96)
        elseif MatchType.MT_EightPets == self._enterData._match_type then
            -- 八人有独特的胜利动画 -> 不显示队伍光灵立绘（8名光灵显示不下）
            transCmp:ChangeAnim("uieff_UIBattleResultComplete_Win_baren", 224)
        else
            -- 通用胜利动画
            transCmp:ChangeAnim("uieff_UIBattleResultComplete_Win", 190)
        end
    end

    --再次挑战按钮
    local againFightBtn = self:GetGameObject("againBtnRoot")
    local l_MissionCreateInfo = self._enterData:GetMissionCreateInfo()
    if l_MissionCreateInfo ~= nil then
        local missionID = l_MissionCreateInfo.mission_id
        GameGlobal.UAReportForceGuideEvent(
            "FightOverMatchResult",
            {
                "PlaySpeed",
                missionID
            }
        )
    end

    --助战提示
    --助战QA_助战可获得3星_20210813
    -- local helpWinTips = self:GetGameObject("HelpWinTips")
    -- local helpTipsShow = false
    -- if self._isWin then
    --     if self._enterData:IsHaveHelpPet() then
    --         helpTipsShow = true
    --     end
    -- end
    -- helpWinTips:SetActive(helpTipsShow)

    if self._isWin then
        --判断首次通关
        local firstPass = not self._enterData:LevelIsPass()
        if firstPass then
            -- 上报新手引导结束信息 1-3关卡结束（脱离强制引导）
            if l_MissionCreateInfo ~= nil then
                local missionID = l_MissionCreateInfo.mission_id
                if missionID and GameGlobal.IsUAReportCompleteTutorialMission(missionID) then
                    GameGlobal.UAReportChannelEvent("completed_tutorial", {})
                end
            end
        end
    end

    --优先检查level表
    local levelId = self._enterData._level_id
    local cfg_level = Cfg.cfg_level[levelId]
    --是否设置过
    local levelSet = false
    --显隐
    local btnActive = true
    if cfg_level then
        local fightAgainActive = cfg_level.FightAgainActive
        if fightAgainActive then
            if fightAgainActive == 1 then
                -- 首通隐藏
                local firstPass = not self._enterData:LevelIsPass()
                if firstPass and self._isWin then
                    levelSet = true
                    btnActive = false
                end
            elseif fightAgainActive == 2 then
                -- 直接隐藏
                levelSet = true
                btnActive = false
            elseif fightAgainActive == 3 then
                -- 直接显示
                levelSet = true
                btnActive = true
            end
        end
    end

    if not levelSet then
        btnActive = HelperProxy:GetInstance():AgainFightActive(self._enterData._match_type, self._isWin)
        againFightBtn:SetActive(btnActive)
    else
        againFightBtn:SetActive(btnActive)
    end
    --赛季玩法 关闭再次挑战
    if self._enterData._match_type == MatchType.MT_Season then
        againFightBtn:SetActive(false)
    end


    self:StartTask(
        function(TT)
            while not self:_IsAllTaskOver() or not self._expIncreaseAnimEnd or
                (self._bNeedPopActivityAward and not self._popActivityAwardEnd) do
                YIELD(TT)
            end
            md:SetBattleResultComplated()
        end
    )
end

---@param enterData MatchEnterData
function UIBattleResultComplete:IsSummerActivityTwo(enterData)
    local isSummerTwo = false
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local campId, comId, comType =
            campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo().CampaignMissionParams)
        local campConfig = Cfg.cfg_campaign[campId]
        if campConfig then
            local campType = campConfig.CampaignType
            if
                campType == ECampaignType.CAMPAIGN_TYPE_SUMMER_II and
                comType == CampaignComType.E_CAMPAIGN_COM_SUM_II_MISSION
            then
                isSummerTwo = true
            end
        end
    end
    return isSummerTwo
end

function UIBattleResultComplete:IsActivityReview(enterData)
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local campId, comId, comType =
            campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo().CampaignMissionParams)
        return campaignModule:IsActivityReview(campId)
    end
end

---@param enterData MatchEnterData
function UIBattleResultComplete:IsN21CC(enterData)
    local isNCC21 = false
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local campId, comId, comType =
            campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo().CampaignMissionParams)
        local campConfig = Cfg.cfg_campaign[campId]
        if campConfig then
            local campType = campConfig.CampaignType
            if
                campType == ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE and
                comType == CampaignComType.E_CAMPAIGN_COM_CHALL_MISSION
            then
                isNCC21 = true
            end
        end
    end
    return isNCC21
end

---@param enterData MatchEnterData
function UIBattleResultComplete:IsN28Errand(enterData)
    local isN28Errand = false
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local campId, comId, comType =
            campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo().CampaignMissionParams)
        local campConfig = Cfg.cfg_campaign[campId]
        if campConfig then
            local campType = campConfig.CampaignType
            if
                campType == ECampaignType.CAMPAIGN_TYPE_LINE_MISSION
            then
                isN28Errand = true
            end
        end
    end
    return isN28Errand
end

---@param enterData MatchEnterData
function UIBattleResultComplete:IsCampaignMissionHideExp(enterData)
    local bHide = false
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        -- local campaignModule = self:GetModule(CampaignModule)
        -- local campId, comId, comType =
        --     campaignModule:ParseCampaignMissionParams(enterData:GetMissionCreateInfo().CampaignMissionParams)
        -- local campConfig = Cfg.cfg_campaign[campId]
        -- if campConfig then
        --     local campType = campConfig.CampaignType
        --     if
        --         campType == ECampaignType.CAMPAIGN_TYPE_N9
        --      then
        --         bHide = true
        --     end
        -- end
        local missionID = enterData:GetCampaignMissionInfo().nCampaignMissionId

        local missionCfg = Cfg.cfg_campaign_mission[missionID]
        ---体力配置
        if missionCfg.NeedPower and missionCfg.NeedPower > 0 then
        else
            bHide = true
        end
    end
    return bHide
end

function UIBattleResultComplete:InitHighLight(effName, name1, name2)
    -- self:StartTask(
    -- function(TT)
    self._highLightResRequest = ResourceManager:GetInstance():SyncLoadAsset(effName .. ".prefab", LoadType.GameObject)
    self._highLightGO = self._highLightResRequest.Obj
    local title = GameObjectHelper.FindChild(self._highLightGO.transform, "completetitle")
    local en = GameObjectHelper.FindChild(self._highLightGO.transform, "completeen")
    self.tex1Req = ResourceManager:GetInstance():SyncLoadAsset(name1 .. ".mat", LoadType.Mat)
    self.tex2Req = ResourceManager:GetInstance():SyncLoadAsset(name2 .. ".mat", LoadType.Mat)
    local tex1 = self.tex1Req.Obj:GetTexture("_MainTex")
    local tex2 = self.tex2Req.Obj:GetTexture("_MainTex")

    title:GetComponent("RawImage").texture = tex1
    en:GetComponent("RawImage").texture = tex2

    local parent = self:GetGameObject("g_complete")
    self._highLightGO.transform:SetParent(parent.transform)
    self._highLightGO.transform.localPosition = Vector3(0, 0, 0)
    self._highLightGO.transform.localScale = Vector3(1, 1, 1)
    self._highLightGO.transform.localRotation = Quaternion(0, 0, 0, 0)
    self._highLightGO:SetActive(true)
    -- end
    -- )
end

function UIBattleResultComplete:OnHide()
    --清理助战信息
    local hpm = self:GetModule(HelpPetModule)
    hpm:UI_ClearHelpPet()
    --清理助战信息
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowItemTips)
    if self._highLightResRequest then
        self._highLightResRequest:Dispose()
        self._highLightResRequest = nil
    end
    if self.tex1Req then
        self.tex1Req:Dispose()
        self.tex1Req = nil
    end
    if self.tex2Req then
        self.tex2Req:Dispose()
        self.tex2Req = nil
    end
end

---@param vecItem RoleAsset
function UIBattleResultComplete:_GetItemCount(vecItem)
    local nItemCount = 0
    if vecItem then
        for i = 1, #vecItem do
            local roleAsset = vecItem[i]
            if roleAsset.assetid ~= RoleAssetID.RoleAssetExp then
                nItemCount = nItemCount + 1
            end
        end
    end
    return nItemCount
end

---@return UI_MatchResult
function UIBattleResultComplete:_GetMatchResult()
    local gameMatchModule = self:GetModule(GameMatchModule)
    local matchResult = gameMatchModule:GetMachResult()
    return matchResult
end

function UIBattleResultComplete:FillInfo()
    --结算动画播放时间
    local animationTime = (25 / 30) * 1000
    --星星动画播放时间
    local starEffTime = 400

    ---@type UI_MatchResult
    local matchRes = self:_GetMatchResult()
    if matchRes == nil then
        return
    end

    if matchRes.m_nMatchType == MatchType.MT_ResDungeon then
        self._resInstanceGO:SetActive(true)
        self._starConditionGO:SetActive(false)
        local module = self:GetModule(ResDungeonModule)
        local instanceId = module:GetEnterInstanceId()
        local clientResInstance = module:GetClientResInstance()
        local mainType = clientResInstance:GetMainTypeByInstanceId(instanceId)
        local entry = clientResInstance:GetEntryById(mainType)
        self._resInsNameTxt:SetText(entry and entry:GetEntryResultName() or "")
        local instance = entry and entry:GetInstanceById(instanceId)
        local str = instance and instance:GetDifficultyName() or ""
        self._resInsDiffTxt:SetText("-" .. str .. "-")

        local type = nil
        if instance then
            type = instance:GetMainType()
        end

        local type2sprite = {
            [DungeonType.DungeonType_Coin] = {
                [true] = "thread_shengli_stamp6",
                [false] = "thread_shengli_stamp5"
            },
            [DungeonType.DungeonType_Experience] = { [true] = "thread_shengli_stamp4", [false] = "thread_shengli_stamp3" },
            [DungeonType.DungeonType_AircraftMaterial] = {
                [true] = "thread_shengli_stamp2",
                [false] = "thread_shengli_stamp1"
            },
            [DungeonType.DungeonType_equip] = { [true] = "thread_shengli_stamp8", [false] = "thread_shengli_stamp7" },
            [DungeonType.DungeonType_Max] = { [true] = "thread_shengli_stamp2", [false] = "thread_shengli_stamp1" }
        }
        local type2logo = {
            [DungeonType.DungeonType_Coin] = {
                [true] = "thread_shengli_logo5",
                [false] = "thread_shengli_logo6"
            },
            [DungeonType.DungeonType_Experience] = { [true] = "thread_shengli_logo3", [false] = "thread_shengli_logo4" },
            [DungeonType.DungeonType_AircraftMaterial] = {
                [true] = "thread_shengli_logo1",
                [false] = "thread_shengli_logo2"
            },
            [DungeonType.DungeonType_equip] = { [true] = "thread_shengli_logo7", [false] = "thread_shengli_logo8" },
            [DungeonType.DungeonType_Max] = { [true] = "thread_shengli_logo1", [false] = "thread_shengli_logo2" }
        }

        if type then
            self._resInsDiffGood.sprite = self._atlas:GetSprite(type2logo[type][self._isWin])
            local spritePool = self:GetUIComponent("UISelectObjectPath", "resSpritePool")
            spritePool:SpawnObjects("UIBattleResultCompleteResSpriteItem", 4)
            local items = spritePool:GetAllSpawnList()
            for i = 1, #items do
                local sprite = self._atlas:GetSprite(type2sprite[i][type == i])
                items[i]:SetData(i, sprite, self._isWin)
            end
        end
    else
        self._resInstanceGO:SetActive(false)
        self._starConditionGO:SetActive(true)
    end
    ---@type TowerModule
    local towerModule = self:GetModule(TowerModule)
    --关卡名
    if matchRes.m_nMatchType == MatchType.MT_Tower then
        if self._isWin then
            self._stageTitle:SetActive(false)
        else
            self._stageTitle:SetActive(true)
            local towerCfg = Cfg.cfg_tower_detail[matchRes.m_nID]
            local name = towerModule:GetTowerName(towerCfg.Type)
            local title = StringTable.Get("str_tower_tower_layer", name, towerCfg.stage)
            self._stageTitleTxt:SetText(title)
        end
    elseif matchRes.m_nMatchType == MatchType.MT_TalePet then
        if self._isWin then
            self._stageTitle:SetActive(false)
        else
            self._stageTitle:SetActive(true)
            local cfg = Cfg.cfg_tale_stage[matchRes.m_nID]
            self._stageTitleTxt:SetText(StringTable.Get(cfg.Name))
        end
    else
        self._stageTitle:SetActive(true)
        self._stageTitleTxt:SetText(matchRes.m_stShowName)
    end

    --MSG23908	【需要测试】局内结算界面“探索完成”文字后面的黄色底板加回来		小开发任务-待开发	李学森, 1958	05/27/2021
    if self._isWin and #matchRes.m_vecCondition > 0 then
        self._imgCompleteGo:SetActive(false)
    else
        self._imgCompleteGo:SetActive(true)
    end

    if matchRes.m_nMatchType == MatchType.MT_ResDungeon then
        if self._isWin then
            self:InitHighLight("ui_eff_complete_exploer", "thread_shengli_chara3", "thread_shengli_chara4")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara3")
            self._imgCompleteEn:LoadImage("thread_shengli_chara4")
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara5")
            self._imgCompleteEn:LoadImage("thread_shengli_chara6")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_Tower then
        self:_SetNextFightBtn(matchRes)
        if self._isWin then
            self:InitHighLight("ui_eff_complete_exploer", "thread_shengli_chara3", "thread_shengli_chara4")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara3")
            self._imgCompleteEn:LoadImage("thread_shengli_chara4")
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara5")
            self._imgCompleteEn:LoadImage("thread_shengli_chara6")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_DifficultyMission then
        if self._isWin then
            self:InitHighLight("ui_eff_complete_mission", "world_tiaozhan_tu13", "world_tiaozhan_tu14")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("world_tiaozhan_tu13")
            self._imgCompleteEn:LoadImage("world_tiaozhan_tu14")
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
            self._imgCompleteEn:LoadImage("thread_shengli_chara8")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_TalePet then
        if self._isWin then
            self:InitHighLight("ui_eff_complete_exploer", "thread_shengli_chara3", "thread_shengli_chara4")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara3")
            self._imgCompleteEn:LoadImage("thread_shengli_chara4")
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara5")
            self._imgCompleteEn:LoadImage("thread_shengli_chara6")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_Conquest then
        local matchResult = self:_GetMatchResult()
        if matchResult.m_vecAwardNormal.count > 0 then
            self:InitHighLight("ui_eff_complete_mission", "thread_shengli_chara3", "thread_shengli_chara4")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara3")
            self._imgCompleteEn:LoadImage("thread_shengli_chara4")
            self._tex1:SetText(StringTable.Get("str_battle_end"))
            self._tex2:SetText(StringTable.Get("str_battle_end_en"))
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
            self._imgCompleteEn:LoadImage("thread_shengli_chara8")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_WorldBoss then
        local matchResult = self:_GetMatchResult()
        if matchResult.m_damage > 0 then
            self:InitHighLight("ui_eff_complete_mission", "world_tiaozhan_tu11", "world_tiaozhan_tu12")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("world_tiaozhan_tu11")
            self._imgCompleteEn:LoadImage("world_tiaozhan_tu12")
            self._tex1:SetText(StringTable.Get("str_battle_end"))
            self._tex2:SetText(StringTable.Get("str_battle_end_en"))
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
            self._imgCompleteEn:LoadImage("thread_shengli_chara8")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_BlackFist then
        --战斗模拟器
        local match = self:GetModule(MatchModule)
        local enterData = match:GetMatchEnterData()
        local isAir =
            self:GetModule(AircraftModule):IsAircraftCartridgeMission(enterData:GetBlackFistInfo().component_id)
        local isN8CombatSimulator = (self:_IsActivityN8(enterData) == 2)

        local localizationTitle_win_zh = "thread_shengli_chara3"
        local localizationTitle_win_en = "thread_shengli_chara4"
        if isAir or isN8CombatSimulator then
            localizationTitle_win_zh = "world_tiaozhan_tu13"
            localizationTitle_win_en = "world_tiaozhan_tu14"
        end

        if self._isWin then
            self:InitHighLight("ui_eff_complete_mission", localizationTitle_win_zh, localizationTitle_win_en)
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage(localizationTitle_win_zh)
            self._imgCompleteEn:LoadImage(localizationTitle_win_en)
            self._tex1:SetText(StringTable.Get("str_battle_end"))
            self._tex2:SetText(StringTable.Get("str_battle_end_en"))
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
            self._imgCompleteEn:LoadImage("thread_shengli_chara8")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_MiniMaze then
        ---@type UI_MatchResult
        local matchResult = self:_GetMatchResult()
        local cfg = Cfg.cfg_bloodsucker_mission[matchResult.m_nID]
        local isWin = matchResult.wave >= cfg.WaveCount
        if isWin then
            self:InitHighLight("ui_eff_complete_exploer", "world_tiaozhan_tu13", "world_tiaozhan_tu14")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("world_tiaozhan_tu13")
            self._imgCompleteEn:LoadImage("world_tiaozhan_tu14")
        else
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("world_tiaozhan_tu11")
            self._imgCompleteEn:LoadImage("world_tiaozhan_tu12")
        end
    elseif matchRes.m_nMatchType == MatchType.MT_PopStar then
        self._imgCompleteGo:SetActive(true)
        if self:IsPopStarChallengeLevel(matchRes) then --是挑战关
            self:InitHighLight("ui_eff_complete_mission", "world_tiaozhan_tu11", "world_tiaozhan_tu12")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("world_tiaozhan_tu11")
            self._imgCompleteEn:LoadImage("world_tiaozhan_tu12")
        else
            local localizationTitle_win_zh = "thread_shengli_chara1"
            local localizationTitle_win_en = "thread_shengli_chara2"
            if self._isWin then
                self:InitHighLight("ui_eff_complete_mission", localizationTitle_win_zh, localizationTitle_win_en)
                self._imgComplete:LoadImage("thread_shengli_frame16")
                self._imgCompleteTitle:LoadImage(localizationTitle_win_zh)
                self._imgCompleteEn:LoadImage(localizationTitle_win_en)
            else
                self._imgComplete:LoadImage("thread_shengli_frame17")
                self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
                self._imgCompleteEn:LoadImage("thread_shengli_chara8")
            end
        end
    elseif matchRes.m_nMatchType == MatchType.MT_Season then
        if self._isWin then
            self:InitHighLight("ui_eff_complete_exploer", "thread_shengli_chara3", "thread_shengli_chara4")
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara3")
            self._imgCompleteEn:LoadImage("thread_shengli_chara4")
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara5")
            self._imgCompleteEn:LoadImage("thread_shengli_chara6")
        end
    else
        local isAir = false
        if matchRes.m_nMatchType == MatchType.MT_Campaign then
            --战斗模拟器
            local match = self:GetModule(MatchModule)
            local enterData = match:GetMatchEnterData()
            isAir =
                self:GetModule(AircraftModule):IsAircraftCartridgeMission(
                    enterData:GetCampaignMissionInfo().nMissionComId
                )
        end
        local localizationTitle_win_zh = "thread_shengli_chara1"
        local localizationTitle_win_en = "thread_shengli_chara2"
        if isAir then
            localizationTitle_win_zh = "world_tiaozhan_tu13"
            localizationTitle_win_en = "world_tiaozhan_tu14"
        end
        if self._isWin then
            self:InitHighLight("ui_eff_complete_mission", localizationTitle_win_zh, localizationTitle_win_en)
            self._imgComplete:LoadImage("thread_shengli_frame16")
            self._imgCompleteTitle:LoadImage(localizationTitle_win_zh)
            self._imgCompleteEn:LoadImage(localizationTitle_win_en)
        else
            self._imgComplete:LoadImage("thread_shengli_frame17")
            self._imgCompleteTitle:LoadImage("thread_shengli_chara7")
            self._imgCompleteEn:LoadImage("thread_shengli_chara8")
        end
    end
    --三星条件达成情况
    local vecPassCondition = matchRes.m_vecCondition
    local passCount = 0
    if #vecPassCondition > 0 then
        for i = 1, #vecPassCondition do
            local desc = nil
            local go = self._starIconList[i]
            go:SetActive(false)
            if self._isWin then
                local hpm = self:GetModule(HelpPetModule)
                -- local key = hpm:UI_GetHelpPetKey()
                -- local extStr = ""
                -- if key and key > 0 and i == 1 then
                --     extStr = StringTable.Get("str_help_pet_syzz")
                -- end
                -- desc = matchRes.m_vecCondition[i].m_stDest .. extStr
                desc = matchRes.m_vecCondition[i].m_stDest
                desc = string.gsub(desc, "<color=#%x*>", "<color=#31AAFF>")
                local pass = matchRes.m_vecCondition[i].m_bPass
                if pass then
                    go:SetActive(true)
                    table.insert(self._taskIDList, self._3StarTaskID)
                    passCount = passCount + 1
                end
            else
                local str = string.gsub(matchRes.m_vecCondition[i].m_stDest, "<color=#%x*>", "")
                str = string.gsub(str, "</color>", "")

                desc = "<color=grey>" .. str .. "</color>"
                go:SetActive(false)
            end
            self._starTxtList[i]:SetText(desc)
        end
        for i = 1, #self._starRootGOList do
            self._starRootGOList[i]:SetActive(true)
        end
    else
        for i = 1, #self._starRootGOList do
            self._starRootGOList[i]:SetActive(false)
        end
    end
    --大星
    for i = 0, self._stars.Length - 1 do
        local go = self._stars[i].gameObject
        if self._isWin then
            go:SetActive(i + 1 <= passCount)
        else
            go:SetActive(false)
        end
    end
    local autoFightMd = GameGlobal.GetModule(SerialAutoFightModule)

    --奖励物品(包括经验 货币 道具等)
    local normalRewards = matchRes.m_vecAwardNormal
    local starRewards = matchRes.m_vecAwardPerfect
    local firstPassRawrds = matchRes.m_vecFirstPassAward
    local activityRewards = matchRes.m_activity_rewards
    local extStarRewards = matchRes.m_ext_star_rewards       --赛季关卡
    local extFirstPassRewards = matchRes.m_ext_first_rewards --赛季关卡
    --QA MSG26599 活动奖励单独弹窗(连续自动战斗中不单独弹)
    local extReward = matchRes.m_vecExtAward
    local doubleExtReward = matchRes.m_vecDoubleExtAward
    local backRewards = matchRes.m_back_rewards or {}
    --迷失之地推荐奖励
    local _recommendReward = matchRes.m_recommend_pet_rewards
    local recommendReward = {}
    if _recommendReward and #_recommendReward > 0 then
        local roleAsset = RoleAsset:New()
        local id = 0
        local count = 0
        for i = 1, #_recommendReward do
            local _roleAsset = _recommendReward[i]
            id = _roleAsset.assetid
            count = count + _roleAsset.count
        end
        roleAsset.assetid = id
        roleAsset.count = count
        recommendReward[1] = roleAsset
    end

    local itemCount =
        self:_GetItemCount(normalRewards) + #starRewards + #firstPassRawrds + #extReward + #doubleExtReward +
        #recommendReward +
        #backRewards +
        #extStarRewards +
        #extFirstPassRewards
    if autoFightMd:IsRunning() then --QA MSG26599 活动奖励单独弹窗(连续自动战斗中不单独弹)
        itemCount = itemCount + #activityRewards
    end
    if not self._isWin then
        if matchRes.m_nMatchType == MatchType.MT_BlackFist then --黑拳不返回棱镜
        else
            itemCount = itemCount + 1
            if matchRes.m_nMatchType == MatchType.MT_ResDungeon then -- 资源本 使用双倍卷 失败 返还
                local resModule = self:GetModule(ResDungeonModule)
                if resModule:IsOpenDoubleRes() then
                    itemCount = itemCount + 1
                end
            end
        end
    end
    self._itemPool:SpawnObjects("UIWidgetResultReward", itemCount)
    ---@type UIWidgetResultReward[]
    local items = self._itemPool:GetAllSpawnList()
    local itemCfg = Cfg.cfg_item
    local itemIndex = 1
    self._levelIcon:SetActive(false)
    local itemModule = GameGlobal.GetModule(ItemModule)

    local eraseIDList = {}

    if matchRes.m_nMatchType == MatchType.MT_Tower then --设置初始经验值，尖塔不显示经验条
        self._awardParent:SetActive(self._isWin)
        self._expParent:SetActive(false)
    elseif matchRes.m_nMatchType == MatchType.MT_TalePet then
        self._awardParent:SetActive(self._isWin)
        self._expParent:SetActive(false)
    elseif matchRes.m_nMatchType == MatchType.MT_LostArea then
        self._awardParent:SetActive(self._isWin)
        self._expParent:SetActive(false)
    elseif matchRes.m_nMatchType == MatchType.MT_DifficultyMission then
        self._awardParent:SetActive(self._isWin)
        self._expParent:SetActive(false)
    elseif matchRes.m_nMatchType == MatchType.MT_EightPets then
        self._awardParent:SetActive(self._isWin)
        self._expParent:SetActive(false)
    else
        local roleModule = GameGlobal.GetModule(RoleModule)
        local roleLv = roleModule:GetLevel()
        local curLvStartExp = HelperProxy:GetInstance():GetLevelExp(roleLv)
        local sliderStartValue = roleModule:GetRoleExp() - curLvStartExp
        local lvProp = Cfg.cfg_role_level[roleLv]
        self._expSlider.maxValue = lvProp.NeedExp
        self._expSlider.value = sliderStartValue
        self._expTxt:SetText(
            "<color=#D8D8D8>" ..
            math.floor(sliderStartValue) ..
            "</color><color=#00F8FF>/</color><color=#D8D8D8>" .. lvProp.NeedExp .. "</color>"
        )
    end

    local popStarScore = self:GetGameObject("PopStarScore")
    local popStarScoreLabel = self:GetUIComponent("UILocalizationText", "PopStarScore")
    local popStarScore2 = self:GetGameObject("PopStarScore2")
    local popStarScore2Label = self:GetUIComponent("UILocalizationText", "PopStarScore2")
    popStarScore2:SetActive(false)
    popStarScore:SetActive(false)
    if matchRes.m_nMatchType == MatchType.MT_PopStar then
        if self:IsPopStarChallengeLevel(matchRes) then --是挑战关
            for i = 0, self._stars.Length - 1 do
                local go = self._stars[i].gameObject
                go:SetActive(false)
            end
            popStarScore2:SetActive(true)
            self._expParent:SetActive(false)
            local items = self:GetGameObject("Items")
            items:SetActive(false)
            popStarScore2Label:SetText(StringTable.Get("str_n31_popstar_battle_result_score_tips",
                "<color=#f79c2e>" .. matchRes._starNum .. "</color>"))
            self._star1RootGO:SetActive(false)
            self._star2RootGO:SetActive(false)
            self._star3RootGO:SetActive(false)
        else
            self._expParent:SetActive(false)
            popStarScore:SetActive(true)
            popStarScoreLabel:SetText(StringTable.Get("str_n31_popstar_battle_result_score_tips", matchRes._starNum))
        end

        if matchRes.m_vecAwardNormal and #matchRes.m_vecAwardNormal > 0 then
            local rewards = matchRes.m_vecAwardNormal
            self:ShowDialog("UIGetItemController", rewards)
        end
    end

    --经验
    self._txtExpAdd.gameObject:SetActive(self._isWin)
    for i = 1, #normalRewards do
        ---@type RoleAsset
        local roleAsset = normalRewards[i]
        if roleAsset.assetid == RoleAssetID.RoleAssetExp then
            self._levelIcon:SetActive(true)
            local matchResRoleInfo = matchRes.m_matchResRolInfo
            local existingExp = matchResRoleInfo.exp_before
            local lv = HelperProxy:GetInstance():GetLvByExp(existingExp)
            self._levelTxt:SetText(lv)

            if lv < HelperProxy:GetInstance():GetMaxLevel() then
                --设置初始经验值
                local curLvStartExp = HelperProxy:GetInstance():GetLevelExp(lv)
                local sliderStartValue = existingExp - curLvStartExp
                local lvProp = Cfg.cfg_role_level[lv]
                self._expSlider.maxValue = lvProp.NeedExp
                self._expSlider.value = sliderStartValue
                self._expTxt:SetText(
                    "<color=#D8D8D8>" ..
                    math.floor(sliderStartValue) ..
                    "</color><color=#00F8FF>/</color><color=#D8D8D8>" .. lvProp.NeedExp .. "</color>"
                )

                self._txtExpAdd:SetText("+" .. roleAsset.count)
                self:_CheckNeedShowLevelUp(lv, existingExp, roleAsset.count)
                local taskID =
                    GameGlobal.TaskManager():StartTask(
                        self._DisplayExpUp,
                        self,
                        existingExp,
                        existingExp + roleAsset.count,
                        lv,
                        matchResRoleInfo
                    )
                table.insert(self._taskIDList, taskID)
            else
                self._expSlider.maxValue = 1
                self._expSlider.value = 1
            end
            table.insert(eraseIDList, roleAsset)
        end
    end

    for i, v in ipairs(eraseIDList) do
        table.removev(normalRewards, v)
    end

    --推荐奖励排序
    if #recommendReward > 1 then
        itemModule:BattleResultSortAsset(recommendReward)
    end
    --给双倍券额外奖励排序
    if #doubleExtReward > 1 then
        itemModule:BattleResultSortAsset(doubleExtReward)
    end
    --给三星奖励排序
    if #starRewards > 1 then
        itemModule:BattleResultSortAsset(starRewards)
    end
    --给赛季额外三星奖励排序
    if #extStarRewards > 1 then
        itemModule:BattleResultSortAsset(extStarRewards)
    end
    --给首通奖励排序
    if #firstPassRawrds > 1 then
        itemModule:BattleResultSortAsset(firstPassRawrds)
    end
    --给赛季额外首通奖励排序
    if #extFirstPassRewards > 1 then
        itemModule:BattleResultSortAsset(extFirstPassRewards)
    end
    --给普通物品排序
    if #normalRewards > 1 then
        self:BattleNormalResultSortAsset(normalRewards)
    end
    if #extReward > 1 then
        itemModule:BattleResultSortAsset(extReward)
    end
    --回流排序
    if #backRewards > 1 then
        itemModule:BattleResultSortAsset(backRewards)
    end
    --赛季关卡 奖励用特殊样式
    if matchRes.m_nMatchType == MatchType.MT_Season then
        if self._isWin then
            self._normalItemsGo:SetActive(false) --todo 后面的填充相关逻辑也屏蔽
            self._seasonItemsGo:SetActive(true)
            local matchModule = self:GetModule(MatchModule)
            local enterData = matchModule:GetMatchEnterData()
            ---@type SeasonMissionCreateInfo
            local seasonMissionInfo = enterData:GetSeasonMissionInfo()
            self:FillSeasonAwardsArea(matchRes, seasonMissionInfo)
        end
    end

    --QA MSG26599 活动奖励单独弹窗（连续自动战斗中不处理）
    --自动战斗中
    if #activityRewards > 0 then
        if autoFightMd:IsRunning() then
            self._bNeedPopActivityAward = false
            --活动奖励
            for i = 1, #activityRewards do
                local roleAsset = activityRewards[i]
                items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, false, false, false, true)
                itemIndex = itemIndex + 1
            end
        else
            for index, value in ipairs(activityRewards) do
                value.type = StageAwardType.Activity
            end
            self._bNeedPopActivityAward = true
            --是否需要弹出活动掉落物品弹窗
            self._popActivityAwardEnd = false
            self._activityAwards = activityRewards
            self:_CheckShowActivityAward()
        end
    end

    --回流奖励
    for i = 1, #backRewards do
        ---@type RoleAsset
        local roleAsset = backRewards[i]
        items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, false, false, false, false, true)
        itemIndex = itemIndex + 1
    end

    --推荐星灵额外奖励
    for i = 1, #recommendReward do
        ---@type RoleAsset
        local roleAsset = recommendReward[i]
        items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, false, false, true)
        itemIndex = itemIndex + 1
    end
    --双倍券额外奖励
    for i = 1, #doubleExtReward do
        ---@type RoleAsset
        local roleAsset = doubleExtReward[i]
        items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, false, false, true)
        itemIndex = itemIndex + 1
    end
    --三星奖励
    for i = 1, #starRewards do
        local roleAsset = starRewards[i]
        if MatchType.MT_Chess == self._enterData._match_type then
            items[itemIndex]:SetShotEffStartTime()
        end
        local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, true)
        table.insert(self._taskIDList, taskID)
        itemIndex = itemIndex + 1
    end
    --赛季 额外三星奖励
    for i = 1, #extStarRewards do
        local roleAsset = extStarRewards[i]
        local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, true)
        table.insert(self._taskIDList, taskID)
        itemIndex = itemIndex + 1
    end

    --首通奖励
    for i = 1, #firstPassRawrds do
        local roleAsset = firstPassRawrds[i]
        if MatchType.MT_Chess == self._enterData._match_type then
            items[itemIndex]:SetShotEffStartTime()
        end
        local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, true)
        table.insert(self._taskIDList, taskID)
        itemIndex = itemIndex + 1
    end
    --赛季 额外首通奖励
    for i = 1, #extFirstPassRewards do
        local roleAsset = extFirstPassRewards[i]
        local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, true)
        table.insert(self._taskIDList, taskID)
        itemIndex = itemIndex + 1
    end

    --其他奖励
    for i = 1, #normalRewards do
        ---@type RoleAsset
        local roleAsset = normalRewards[i]
        if roleAsset.assetid ~= RoleAssetID.RoleAssetExp then --按照首通奖励排序规则 金币不再特殊处理 and roleAsset.assetid ~= RoleAssetID.RoleAssetGold then
            items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false)
            itemIndex = itemIndex + 1
        end
    end

    for i = 1, #extReward do
        ---@type RoleAsset
        local roleAsset = extReward[i]
        items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, false, true)
        itemIndex = itemIndex + 1
    end

    ---返还体力↓
    if not self._isWin then
        if matchRes.m_nMatchType == MatchType.MT_BlackFist then --黑拳不返回棱镜
            local isAir =
                self:GetModule(AircraftModule):IsAircraftCartridgeMission(
                    self._enterData:GetBlackFistInfo().component_id
                )
            local isN8CombatSimulator = (self:_IsActivityN8(self._enterData) == 2)

            if isAir or isN8CombatSimulator then
                self._awardParent:SetActive(false)
                for i = 1, #self._starRootGOList do
                    self._starRootGOList[i]:SetActive(false)
                end
            end
        elseif matchRes.m_nMatchType == MatchType.MT_PopStar then
            self._awardParent:SetActive(false)
        else
            local bIsFirst = matchRes.m_firstFail
            local nNeedPower = 0
            local nCostPower = 0
            --返还的物品默认为棱镜,活动关可能是任意物品
            local nCostID = RoleAssetID.RoleAssetPhyPoint
            if MatchType.MT_Mission == self._enterData._match_type then
                local mission = self:GetModule(MissionModule)
                local missionID = self._enterData:GetMissionCreateInfo().mission_id
                ---扣除值的配置ID
                local costConfigID = 1
                ---体力配置
                nNeedPower = Cfg.cfg_mission[missionID].NeedPower
                nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
            elseif MatchType.MT_Campaign == self._enterData._match_type then
                local isAir =
                    self:GetModule(AircraftModule):IsAircraftCartridgeMission(
                        self._enterData:GetCampaignMissionInfo().nMissionComId
                    )
                local isN8CombatSimulator = (self:_IsActivityN8(self._enterData) == 2)
                if
                    self:IsN21CC(self._enterData) or self:IsSummerActivityTwo(self._enterData) or isAir or
                    isN8CombatSimulator or
                    not self:ShowAward(self._enterData) or
                    self:IsActivityReview(self._enterData)
                then
                    self._awardParent:SetActive(false)
                    if not self:ShowCondition(self._enterData) then
                        for i = 1, #self._starRootGOList do
                            self._starRootGOList[i]:SetActive(false)
                        end
                    end
                else
                    local module = self:GetModule(MissionModule)
                    local missionID = self._enterData:GetCampaignMissionInfo().nCampaignMissionId

                    local missionCfg = Cfg.cfg_campaign_mission[missionID]
                    ---体力配置
                    if missionCfg.NeedAP then
                        --不为nil则用行动点
                        nCostID = missionCfg.NeedAP[1]
                        nNeedPower = missionCfg.NeedAP[2]
                        --行动点完全返还
                        nCostPower = 0
                    else
                        nNeedPower = missionCfg.NeedPower
                        ---扣除值的配置ID
                        local costConfigID = 1
                        nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
                    end
                end

                if self:IsN28Errand(self._enterData) then
                    self._awardParent:SetActive(false)
                end
            elseif MatchType.MT_ExtMission == self._enterData._match_type then
                local createData = self._enterData:GetMissionCreateInfo()
                local workModule = self:GetModule(ExtMissionModule)
                local cfgExtTask = Cfg.cfg_extra_mission_task[createData.m_nExtTaskID]
                nNeedPower = cfgExtTask.ExpendPower
                nCostPower = cfgExtTask.MinCostPower
            elseif MatchType.MT_ResDungeon == self._enterData._match_type then
                local createData = self._enterData:GetResDungeonInfo()
                local module = self:GetModule(ResDungeonModule)
                local cfgExtTask = Cfg.cfg_res_instance_detail[createData.res_dungeon_id]
                nNeedPower = cfgExtTask.NeedPower
                nCostPower = cfgExtTask.MinCostPower
                if module:IsOpenDoubleRes() then
                    nNeedPower = nNeedPower * 3
                end
            elseif MatchType.MT_Chess == self._enterData._match_type then
                self._awardParent:SetActive(false)
            elseif MatchType.MT_MiniMaze == self._enterData._match_type then
                self._awardParent:SetActive(false)
            elseif MatchType.MT_Season == self._enterData._match_type then
                local module = self:GetModule(MissionModule)
                local missionID = self._enterData:GetSeasonMissionInfo().mission_id

                local missionCfg = Cfg.cfg_season_mission[missionID]
                if missionCfg.FailPassNeedCost and missionCfg.FailPassNeedCost == 1 then --配置了失败消耗道具
                else
                    ---体力配置
                    if missionCfg.NeedAP then
                        --不为nil则用行动点
                        nCostID = missionCfg.NeedAP[1]
                        nNeedPower = missionCfg.NeedAP[2]
                        --行动点完全返还
                        nCostPower = 0
                    else
                        nNeedPower = missionCfg.NeedPower
                        ---扣除值的配置ID
                        local costConfigID = 1
                        nCostPower = Cfg.cfg_mission_common[costConfigID].CostPower
                    end
                end
                if missionCfg.IsDailylevel == 1 and not self._isWin then
                    self._awardParent:SetActive(false) --日常关失败了不显示奖励
                end
            end
            ---显示体力返还情况
            if not bIsFirst then
                nNeedPower = nNeedPower - nCostPower
                if nNeedPower < 0 then
                    nNeedPower = 0
                end
            end
            if nCostID == RoleAssetID.RoleAssetPhyPoint then
                items[itemIndex]:Init(nNeedPower, RoleAssetID.RoleAssetPhyPoint, false, 1)
            else
                local itemName = StringTable.Get(Cfg.cfg_item[nCostID].Name)
                items[itemIndex]:Init(nNeedPower, nCostID, false, itemName)
            end
            itemIndex = itemIndex + 1
        end
    end
    ---返还体力↑

    -- ---返还双倍卷 失败 资源本↓
    if not self._isWin then
        if MatchType.MT_ResDungeon == self._enterData._match_type then
            local resModule = self:GetModule(ResDungeonModule)
            if resModule:IsOpenDoubleRes() then
                items[itemIndex]:Init(1, RoleAssetID.RoleAssetDoubleRes, false, 2)
                itemIndex = itemIndex + 1
            end
        end
    end
    -- ---失败 返还双倍卷↑
    if MatchType.MT_Chess == self._enterData._match_type then
        self._imgRole = self:GetUIComponent("RawImageLoader", "imgRole1")
        ---@type RawImageLoader
        self._imgShadow = self:GetUIComponent("RawImageLoader", "imgShadow1")
        local missionInfo = self._enterData:GetChessInfo()
        local missionId = missionInfo.mission_id
        local chessCfgs = Cfg.cfg_chess_mission {}
        local chessCfg = chessCfgs[missionId]
        self._imgRole:LoadImage(chessCfg.CG)
        self._imgRole.gameObject.transform.anchoredPosition = Vector2(chessCfg.Offset[1], chessCfg.Offset[2])
        self._imgRole.gameObject.transform.sizeDelta = Vector2(chessCfg.Size[1], chessCfg.Size[2])
        self._imgRole.gameObject.transform.localScale = Vector2(chessCfg.Scale[1], chessCfg.Scale[2])

        if self._isWin then
            local roleModule = GameGlobal.GetModule(RoleModule)
            local pstid = roleModule:GetPstId()
            local dbStr = "chess" .. missionInfo.mission_id .. pstid
            local count = LocalDB.GetInt(dbStr, 0)
            count = count + 1
            LocalDB.SetInt(dbStr, count)
        end
        local left = chessCfg.Dir == 0

        ---@type UILocalizationText
        local useDialogTxt = left and self._dialogLeftTxt or self._dialogRightTxt
        local pos = chessCfg.Pos
        if left then
            self._dialogLeftGO.transform.localPosition = Vector2(pos[1], pos[2])
        else
            self._dialogRightGO.transform.localPosition = Vector2(pos[1], pos[2])
        end
        self._dialogLeftGO:SetActive(left)
        self._dialogRightGO:SetActive(not left)

        local str = self._isWin and chessCfg.CompletePhrase or chessCfg.FailPhrase
        local trueStr = HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(str))
        useDialogTxt:SetText(trueStr)
        ---@type UnityEngine.UI.ContentSizeFitter
        local csf = useDialogTxt.transform.parent:GetComponent("ContentSizeFitter")
        local rect = useDialogTxt.rectTransform.parent:GetComponent("RectTransform")
        local textWidth = 570
        if useDialogTxt.preferredWidth >= textWidth then
            csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained
            rect.sizeDelta = Vector2(textWidth, rect.sizeDelta.y)
        else
            csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize
        end
    else
        local firstPetMatchData = self._matchPetData[1]
        if firstPetMatchData then
            ----全身静态立绘
            if self._isWin then
                for i = 1, #self._matchPetData do
                    -- 先查找是否有结算界面替换立绘 没有则使用普通大立绘
                    local cg = self._matchPetData[i]:GetPetBattleResultCG(PetSkinEffectPath.BODY_BATTLE_RESULT)
                    if not cg then
                        cg = self._matchPetData[i]:GetPetStaticBody(PetSkinEffectPath.BODY_BATTLE_RESULT)
                    end
                    if not self._imgRoleList[i] then
                        break
                    end
                    self._imgRoleList[i]:LoadImage(cg)
                    self._imgShadowList[i]:LoadImage(cg)
                    UICG.SetTransform(self._imgRoleList[i].gameObject.transform, self:GetName(), cg)
                    UICG.SetTransform(self._imgShadowList[i].gameObject.transform, self:GetName(), cg)
                end
                for i = #self._matchPetData + 1, 5 do
                    self._imgRoleList[i].transform.parent.parent.gameObject:SetActive(false)
                end
            else
                local cg = self._matchPetData[1]:GetPetBattleResultCG(PetSkinEffectPath.BODY_BATTLE_RESULT)
                if not cg then
                    cg = self._matchPetData[1]:GetPetStaticBody(PetSkinEffectPath.BODY_BATTLE_RESULT)
                end
                self._imgRole:LoadImage(cg)
                UICG.SetTransform(self._imgRole.gameObject.transform, self:GetName(), cg)
            end

            ---对话框
            local cfg = nil
            local phraseId = self._matchPetData[1]:GetSkinId()
            cfg = Cfg.pet_phrase[phraseId]
            if not cfg then
                phraseId = self._matchPetData[1]._cfg_pet.ID
                cfg = Cfg.pet_phrase[phraseId]
            end
            if not cfg then
                return
            end

            --判断星灵有没有换立绘
            local awaken
            --当前觉醒值是不是3
            local currentGrade = self._matchPetData[1]:GetPetGrade()
            if currentGrade == 3 then
                awaken = true
            else
                awaken = false
            end

            local left
            if awaken then
                left = cfg.AwakenDir == 0
            else
                left = cfg.Dir == 0
            end

            ---@type UILocalizationText
            local useDialogTxt = left and self._dialogLeftTxt or self._dialogRightTxt
            local pos
            if awaken then
                pos = cfg.AwakenPos
            else
                pos = cfg.Pos
            end

            local posTbl = table.tonumber(string.split(pos, "|"))
            if left then
                self._dialogLeftGO.transform.localPosition = Vector2(posTbl[1], posTbl[2])
            else
                self._dialogRightGO.transform.localPosition = Vector2(posTbl[1], posTbl[2])
            end
            self._dialogLeftGO:SetActive(left)
            self._dialogRightGO:SetActive(not left)

            local str = self._isWin and cfg.CompletePhrase or cfg.FailPhrase
            local trueStr = HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(str))
            useDialogTxt:SetText(trueStr)
            ---@type UnityEngine.UI.ContentSizeFitter
            local csf = useDialogTxt.transform.parent:GetComponent("ContentSizeFitter")
            local rect = useDialogTxt.rectTransform.parent:GetComponent("RectTransform")
            local textWidth = 570
            if useDialogTxt.preferredWidth >= textWidth then
                csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained
                rect.sizeDelta = Vector2(textWidth, rect.sizeDelta.y)
            else
                csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize
            end
        end
    end
    if MatchType.MT_Campaign == self._enterData._match_type then
        if self:IsSummerActivityTwo(self._enterData) then
            self._expParent:SetActive(false)
            self._summerTwoScore:SetActive(true)
            self._summerTwoNameGo:SetActive(true)
            self._summerTwoScoreBgGo:SetActive(true)
            self._stageTitle:SetActive(false)
            self._awardParent:SetActive(false)
            for i = 1, #self._starRootGOList do
                self._starRootGOList[i]:SetActive(false)
            end

            local missionInfo = self._enterData:GetMissionCreateInfo()
            local missionId = missionInfo.nCampaignMissionId
            local componentId = missionInfo.CampaignMissionParams
            if not componentId then
                return
            end
            local cfgs =
                Cfg.cfg_component_summer_ii_mission { CampaignMissionId = missionId, ComponentID = componentId[1] }
            if cfgs == nil or #cfgs <= 0 then
                return
            end
            local cfg = cfgs[1]
            local levelType = cfg.LevelType
            local missionCfgs = Cfg.cfg_campaign_mission { CampaignMissionId = missionId }
            if missionCfgs == nil or #missionCfgs <= 0 then
                return
            end
            local misionCfg = missionCfgs[1]
            local name = StringTable.Get(misionCfg.Name)
            --刷新UI数据
            if levelType == UISummerActivity2LevelType.Normal then
                self._summerTwoScoreBgGo:SetActive(false)
                self._summerTwoNameGo:SetActive(false)
                self._stageTitle:SetActive(true)
                if self._isWin then
                    self._awardParent:SetActive(true)
                else
                    self._awardParent:SetActive(false)
                end
            else
                self._summerTwoNameBgImg:LoadImage(UISummerActivityTwoConst.BattleResultEntryBg)
                self._summerTwoStageNameLabel.text = name
                if self._isWin then
                    ---@type CampaignModule
                    local campaignModule = GameGlobal.GetModule(CampaignModule)
                    ---@type CCampaignSummerII
                    local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_SUMMER_II)
                    ---@type SummerIIMissionComponent
                    local missionComponent =
                        progress:GetComponent(ECampaignSummerIIComponentID.ECAMPAIGN_SUMMERII_MISSION)
                    local hasPass = missionComponent:GetHistoryMissionPassStatus(missionId)

                    local affixList = self._enterData:GetAffixList()
                    local hardId = self._enterData:GetHardIndex()
                    local currentScore = UISummerActivityTwoLevelDatas.CalcScoreByCfg(hardId, affixList, cfg)

                    local affixArr = missionComponent:GetHistoryHighAffix(missionId)
                    local hardIdHis = missionComponent:GetHistoryHighHard(missionId)
                    local historyScore = 0
                    if hasPass and hardIdHis then
                        historyScore = UISummerActivityTwoLevelDatas.CalcScoreByCfg(hardIdHis, affixArr, cfg)
                    end

                    self._summerTwoScoreIcon1Img:LoadImage(UISummerActivityTwoConst.EntryIcon)
                    self._summerTwoScoreIcon2Img:LoadImage(UISummerActivityTwoConst.EntryIcon)
                    self._summerTwoScore1Label.text = historyScore
                    self._summerTwoScoreShadown1Label.text = historyScore
                    self._summerTwoScore2Label.text = currentScore
                    self._summerTwoScoreShadown2Label.text = currentScore
                    self._summerTwoScoreShadown1Label.color = self._summerLevelTypeToScoreColor[levelType]
                    self._summerTwoScoreShadown2Label.color = self._summerLevelTypeToScoreColor[levelType]
                    self._summerTwoScoreHistoryGo:SetActive(true)
                    self._summerTwoScoreCurrentGo:SetActive(true)
                    GameGlobal.TaskManager():StartTask(self.PlaySummerTwoResultAnim, self, currentScore >= historyScore)
                else
                    self._summerTwoScoreBgGo:SetActive(false)
                end
            end
            local againFightBtn = self:GetGameObject("againBtnRoot")
            againFightBtn:SetActive(false)
        elseif self:IsN21CC(self._enterData) then
            self._expParent:SetActive(false)
            self._stageTitle:SetActive(false)
            self._awardParent:SetActive(false)
            for i = 1, #self._starRootGOList do
                self._starRootGOList[i]:SetActive(false)
            end
            self._n21CCNameGo:SetActive(true)
            self._n21CCScoreGo:SetActive(true)
            local againFightBtn = self:GetGameObject("againBtnRoot")
            againFightBtn:SetActive(false)

            local missionInfo = self._enterData:GetMissionCreateInfo()
            local missionId = missionInfo.nCampaignMissionId
            local componentId = missionInfo.CampaignMissionParams
            if not componentId then
                return
            end

            -- local cfgs = Cfg.cfg_campaign_mission {CampaignMissionId = missionId}
            -- if cfgs == nil or #cfgs <= 0 then
            --     return
            -- end
            -- local cfg = cfgs[1]


            ---@type CampaignModule
            local campaignModule = GameGlobal.GetModule(CampaignModule)
            ---@type CCampaignN21Challenge
            local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N21_CHALLENGE)
            ---@type ChallengeMissionComponent
            local component = progress:GetComponent(ECampaignN21ChallengeComponentID.CHALLENGE)

            local cfgs1 =
                Cfg.cfg_component_challenge_mission {
                    ComponentID = component:GetComponentCfgId(),
                    CampaignMissionId = missionId
                }
            if cfgs1 == nil or #cfgs1 <= 0 then
                return
            end
            local cfg1 = cfgs1[1]

            local name = StringTable.Get(cfg1.MonsterName)
            self._n21CCStageNameLabel:SetText(name)

            if self._isWin then
                local historyScore = UIActivityN21CCConst.GetHistoryScore(missionId)
                self._n21CCHistoryScoreLabel:SetText(historyScore)
                local currentScore = component:GetScore(cfg1.LeveIndex)
                self._n21CCCurrentScoreLabel:SetText(currentScore)
            else
                self._n21CCScoreGo:SetActive(false)
            end
        elseif self:_NeedHideExpAndMoveUpReards(self._enterData) then
            self._expParent:SetActive(false)
            self:_HideExpAndMoveUpRewards(true)
        else
            self._summerTwoScore:SetActive(false)
            self._summerTwoNameGo:SetActive(false)
            self._summerTwoScoreBgGo:SetActive(false)
            self._n5Left:SetActive(false)
            self._n5Right:SetActive(false)
            self._worldBoss:SetActive(false)
        end
        --战斗模拟器不显示exp
        local isAir =
            self:GetModule(AircraftModule):IsAircraftCartridgeMission(
                self._enterData:GetCampaignMissionInfo().nMissionComId
            )
        self:_HideExpAndMoveUpRewards(isAir)
        self:_ActivityResult(self._enterData)
    elseif MatchType.MT_SailingMission == self._enterData._match_type then
        self._expParent:SetActive(false)
        self._stageTitle:SetActive(false)
        self._awardParent:SetActive(false)
        for i = 1, #self._starRootGOList do
            self._starRootGOList[i]:SetActive(false)
        end
        local againFightBtn = self:GetGameObject("againBtnRoot")
        againFightBtn:SetActive(false)
        ---@type UI_MatchResult
        local matchResult = self:_GetMatchResult()
        if self._isWin then
            self:StartTask(self.PlaySailingAnim, self, matchResult)
        end
        local bg = self:GetGameObject("UISailBg")
        bg:SetActive(true)
    elseif MatchType.MT_MiniMaze == self._enterData._match_type then
        self._expParent:SetActive(false)
        self._stageTitle:SetActive(false)
        self._awardParent:SetActive(false)
        for i = 1, #self._starRootGOList do
            self._starRootGOList[i]:SetActive(false)
        end
        local againFightBtn = self:GetGameObject("againBtnRoot")
        againFightBtn:SetActive(false)
        ---@type UI_MatchResult
        local matchResult = self:_GetMatchResult()
        self:StartTask(self.PlayVampireAnim, self, matchResult)
    elseif MatchType.MT_BlackFist == self._enterData._match_type then
        --战斗模拟器不显示exp
        local isAir =
            self:GetModule(AircraftModule):IsAircraftCartridgeMission(self._enterData:GetBlackFistInfo().component_id)
        local isN8CombatSimulator = (self:_IsActivityN8(self._enterData) == 2)
        self:_HideExpAndMoveUpRewards(isAir or isN8CombatSimulator)
    elseif MatchType.MT_Conquest == self._enterData._match_type then
        local matchResult = self:_GetMatchResult()
        self._n5Left:SetActive(true)
        self._n5Right:SetActive(true)
        self._worldBoss:SetActive(false)
        self._starConditionGO:SetActive(false)
        self._awardParent:SetActive(false)
        local cfg = Cfg.cfg_component_battlefield { CampaignMissionID = matchResult.m_nID }
        if cfg then
            self._difficultyImage:LoadImage(BattleFieldDifficultyImg.DifficultyImg[cfg[1].Index])
            self._n5StageName:SetText(StringTable.Get(cfg[1].MissionName))
            self._n5StageDifficulty:SetText(StringTable.Get(BattleFieldDifficultyText.DifficultyText[cfg[1].Index]))
        end
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        ---@type CCampaingN5
        local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N5)
        local leftValue = matchResult.m_vecAwardNormal.count
        local rightValue = progress:GetRecordMilitaryExploit(matchResult.m_nID)
        self._militaryExploitLeftValue:SetText(leftValue)
        self._militaryExploitRightValue:SetText(rightValue)
        if leftValue > rightValue then
            self._n5RightAnimation:Play("uieff_N5_Result_Left")
        else
            self._n5RightAnimation:Play("uieff_N5_Result_Right")
        end
    elseif MatchType.MT_WorldBoss == self._enterData._match_type then
        self._n5Left:SetActive(false)
        self._n5Right:SetActive(false)
        self._awardParent:SetActive(false)
        self._starConditionGO:SetActive(true)
        local worldBossModule = self:GetModule(WorldBossModule)
        local matchResult = self:_GetMatchResult()
        if worldBossModule:TeamMemberChange() and matchResult.m_damage > 0 then
            self:Lock("UIBattleResultComplete_WorldBoss")
            self:StartTask(
                function(TT)
                    YIELD(TT, 3167)
                    self:_ShowRecordChoice(worldBossModule, matchResult)
                    self:UnLock("UIBattleResultComplete_WorldBoss")
                end,
                self
            )
        else
            self:_DelayShowWorldBossDamage(worldBossModule, matchResult, false, false)
        end
    elseif MatchType.MT_DifficultyMission == self._enterData._match_type then
        local matchResult = self:_GetMatchResult()
        ---@type UIDiffResultRoot
        self._diffItem = self._diffRoot:SpawnObject("UIDiffResultRoot")
        local stageName = matchResult.m_stShowName
        local enties = matchResult.m_enties
        local nodeid = matchResult.m_parent_mission_id
        local stageid = matchResult.m_nID
        self._diffItem:SetData(stageid, stageName, enties, nodeid)
        self:_HideExpAndMoveUpRewards(self._isWin)

        local starCondition = self:GetUIComponent("RectTransform", "StarCondition")
        starCondition.anchoredPosition = Vector2(0, -50)
    elseif MatchType.MT_Season == self._enterData._match_type then
        self:_HideExpAndMoveUpRewards(true)
    else
        self._summerTwoScore:SetActive(false)
        self._summerTwoNameGo:SetActive(false)
        self._summerTwoScoreBgGo:SetActive(false)
        self._n5Left:SetActive(false)
        self._n5Right:SetActive(false)
        self._worldBoss:SetActive(false)
    end
end

---@param matchResult UI_MatchResult
function UIBattleResultComplete:IsPopStarNormalLevel(matchResult)
    if matchResult.m_nMatchType ~= MatchType.MT_PopStar then
        return false
    end

    local missionInfo = self._enterData:GetMissionCreateInfo()
    local missionId = missionInfo.mission_id
    local componentId = missionInfo.CampaignMissionParams
    local cfgs = Cfg.cfg_component_popstar_mission { MissionID = missionId, ComponentID = componentId[1] }
    local cfg = cfgs[1]

    if cfg.Type == 1 then
        return true
    end

    return false
end

---@param matchResult UI_MatchResult
function UIBattleResultComplete:IsPopStarChallengeLevel(matchResult)
    if matchResult.m_nMatchType ~= MatchType.MT_PopStar then
        return false
    end

    local missionInfo = self._enterData:GetMissionCreateInfo()
    local missionId = missionInfo.mission_id
    local componentId = missionInfo.CampaignMissionParams
    local cfgs = Cfg.cfg_component_popstar_mission { MissionID = missionId, ComponentID = componentId[1] }
    local cfg = cfgs[1]

    if cfg.Type == 2 then
        return true
    end

    return false
end

---@param matchResult UI_MatchResult
function UIBattleResultComplete:PlayVampireAnim(TT, matchResult)
    ---@type UIN25VampireBattleResult
    local item = self._vampireLoader:SpawnObject("UIN25VampireBattleResult")
    item:SetData(matchResult)
    YIELD(TT, 800)
    local eff1 = self:GetGameObject("eff_N25_01")
    if eff1 then
        eff1:SetActive(true)
    end
    local eff2 = self:GetGameObject("eff_N25_02")
    if eff2 then
        eff2:SetActive(true)
    end
    item:PlayAnim(TT, matchResult)
end

---@param matchResult UI_MatchResult
function UIBattleResultComplete:PlaySailingAnim(TT, matchResult)
    YIELD(TT, 2250)
    ---@type SailingMissionModule
    local sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
    ---@type UISailingBattleResultItem
    local item = self._sailingLoader:SpawnObject("UISailingBattleResultItem")
    item:Refresh(matchResult)
    YIELD(TT, 666)
    local historyCount = sailingMissionModule:GetCacheHistoryMissionCount()
    local currentCount = matchResult.history_exploration_progress
    if currentCount > historyCount then
        self:ShowDialog("UISailingBattleResultTips", matchResult)
    end
end

function UIBattleResultComplete:_ShowRecordChoice(worldBossModule, matchResult)
    self:ShowDialog(
        "UIWorldBossRecordChoice",
        matchResult.m_damage,
        function(choiceOld)
            self:_DelayShowWorldBossDamage(worldBossModule, matchResult, true, choiceOld)
        end
    )
end

function UIBattleResultComplete:_DelayShowWorldBossDamage(worldBossModule, matchResult, recordChoice, choiceOld)
    self:Lock("UIBattleResultComplete_DelayWorldBoss")
    self:StartTask(
        function(TT)
            if not recordChoice and matchResult.m_damage > 0 then
                YIELD(TT, 1500)
            end
            self:_ShowWorldBossDamage(worldBossModule, matchResult, recordChoice, choiceOld)
            self:UnLock("UIBattleResultComplete_DelayWorldBoss")
        end,
        self
    )
end

function UIBattleResultComplete:_ShowWorldBossDamage(worldBossModule, matchResult, recordChoice, choiceOld)
    self._worldBoss:SetActive(true)
    local record = worldBossModule:GetRecordByTeamIndex(worldBossModule:GetCurSelectTeamIndex())
    local oldDamge = 0
    if record then
        oldDamge = record.formation_damage
    end
    local newDamage = matchResult.m_damage
    if choiceOld then
        newDamage = oldDamge
    end
    self._damgeLeftValue:SetText(newDamage)
    self._damageRightValue:SetText(oldDamge)
    if oldDamge > matchResult.m_damage and not recordChoice then
        self._arrowRect.localRotation = Quaternion.Euler(0, -180, 0)
        self._worldBossAnimation:Play("uieff_WorldBoss_Result_Right")
    else
        self._worldBossAnimation:Play("uieff_WorldBoss_Result_Left")
    end
end

function UIBattleResultComplete:PlaySummerTwoResultAnim(TT, isLeft)
    self:Lock("UIBattleResultComplete_PlaySummerTwoResultAnim")
    YIELD(TT, 2700)
    if isLeft then
        self._summerTwoAnim:Play("uieff_SummerTwoScore_leftin")
    else
        self._summerTwoAnim:Play("uieff_SummerTwoScore_right")
    end
    self:UnLock("UIBattleResultComplete_PlaySummerTwoResultAnim")
end

function UIBattleResultComplete:Shot(callback)
    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "screenShot")
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    local shotRect = self:GetUIComponent("RectTransform", "screenShot")
    self._shot.width = shotRect.rect.width
    self._shot.height = shotRect.rect.height
    self._shot.blurTimes = 0
    self._shot:CleanRenderTexture()
    local cacheRt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    local rt = self._shot:RefreshBlurTexture()
    self:StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cacheRt)
            if callback then
                callback(cacheRt)
            end
        end
    )
end

function UIBattleResultComplete:Dispose()
    if self._shot then
        self._shot:CleanRenderTexture()
        self._shot = nil
    end
    UIBattleResultComplete.super:Dispose()
end

--切换到主界面
function UIBattleResultComplete:bgOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattleResultComplete", input = "bgOnClick", args = {} }
    )
    if not self:_IsAllTaskOver() or not self._expIncreaseAnimEnd then
        return
    end

    --自动战斗中
    local md = GameGlobal.GetModule(SerialAutoFightModule)
    if md:IsRunning() then
        return
    end

    --[[对局lua内存统计弹窗
    local memory = collectgarbage("count")

    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.Ok,
        "统计内存",
        memory,
        function(param)
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil)
        end, nil
    )
    ]]
    if MatchType.MT_Season == self._enterData._match_type then
        --退出返回地图
        GameGlobal:GetInstance():ExitCoreGame()
        local matchModule = self:GetModule(MatchModule)
        local enterData = matchModule:GetMatchEnterData()
        ---@type SeasonMissionCreateInfo
        local seasonMissionInfo = enterData:GetSeasonMissionInfo()
        ---@type SeasonModule
        local seasonModule = GameGlobal.GetModule(SeasonModule)
        local rt = nil
        -- if params then
        --     rt = params[1]
        -- end
        seasonModule:ExitBattle(seasonMissionInfo, self._isWin, rt)
    else
        self:Shot(
            function(rt)
                GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Exit_Core_Game, nil, rt)
            end
        )
    end
end

--再次挑战
function UIBattleResultComplete:againFightBtnOnClick()
    GameGlobal:GetInstance():ExitCoreGame() --退局处理
    local matchModule = self:GetModule(MatchModule)
    local matchData = matchModule:GetMatchEnterData()
    local missionId = matchData:GetLevelID()
    local isChess = matchData:GetMatchType() == MatchType.MT_Chess
    if isChess then
        --进入战斗音效
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIBattleStart)

        self:Lock("DoEnterMatch")
        --进局
        ---@type GameMatchModule
        local game = GameGlobal.GetModule(GameMatchModule)
        local matchType = MatchType.MT_Chess
        local teamId = 1
        ---@type CampaignModule
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        ---@type CCampaignChess
        local progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_CHESS)
        ---@type ChessComponent
        local chessComponent = progress:GetComponent(ECampaignChessComponentID.ECAMPAIGN_CHESS_MISSION)
        if not chessComponent then
            progress = campaignModule:GetCampaignLocalProcess(ECampaignType.CAMPAIGN_TYPE_N29)
            chessComponent = progress:GetComponent(ECampaignN29ComponentID.ECAMPAIGN_N29_CHESS)
        end
        local parmas = {}
        table.insert(parmas, missionId)
        table.insert(parmas, ECampaignMissionComponentId.ECampaignMissionComponentId_ChessMission)
        table.insert(parmas, chessComponent:GetCampaignMissionParamKeyMap())
        local createInfo = game:GetMatchCreateInfo(matchType, parmas)
        self:StartTask(
            function(TT)
                local res = game:StartMatchTask(TT, matchType, teamId, createInfo)
                if not res:GetSucc() then
                    ToastManager.ShowToast(game:GetErrorMsg(res:GetResult()))
                    self:SwitchState(UIStateType.UIMain)
                    self:UnLock("DoEnterMatch")
                else
                    self:UnLock("DoEnterMatch")
                end
            end,
            self
        )

        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnSetGraphicRaycaster, true)

        return
    end
    local missionModule = self:GetModule(MissionModule)
    local ctx = missionModule:TeamCtx()
    ctx:SetFightAgain(true)     --设置再次挑战
    ctx:ShowDialogUITeams(true) --直接打开编队界面（状态UI）
end

function UIBattleResultComplete:_SetNextFightBtn(matchRes)
    if EDITOR then
        ---@type TestRobotModule
        local testRobot = GameGlobal.GetModule(TestRobotModule)
        if testRobot and testRobot:GetIsEnableRobot() then
            ---冒烟测试时不跑这个逻辑
            return
        end
    end

    ---@type SerialAutoFightModule
    local autoFightModule = self:GetModule(SerialAutoFightModule)
    if autoFightModule:IsRunning() then
        return
    end

    ---@type TowerModule
    local towerModule = self:GetModule(TowerModule)
    local isActive = towerModule:IsNextStageActive(matchRes.m_nID)

    local isFirstWin = table.count(matchRes.m_vecFirstPassAward) ~= 0

    local isShow = self._isWin and isFirstWin and isActive
    self:GetGameObject("nextBtnRoot"):SetActive(isShow)
end

function UIBattleResultComplete:PrepareNextFightTeams_Tower()
    GameGlobal:GetInstance():ExitCoreGame() --退局处理
    ---@type UI_MatchResult
    local matchRes = self:_GetMatchResult()

    ---@type TeamsContext
    local ctx = self:GetModule(MissionModule):TeamCtx()
    ---@type TowerModule
    local towerModule = GameGlobal.GetModule(TowerModule)
    local nextCfg = towerModule:GetNextStageCfg(matchRes.m_nID)

    local ceiling = nextCfg.PetNumber
    local elememt = nextCfg.Type
    local id = nextCfg.ID
    ctx:SetTowerContext(ceiling, elememt, id)
    ctx:SetFightAgain(true) --设置再次挑战

    local curTeamId = ctx:GetCurrTeamId()

    local teams = ctx:GetTowerTeam()
    local team = teams:Get(curTeamId)
    local petsList = team.pets
    local count = 0
    for _, id in ipairs(petsList) do
        if id > 0 then
            count = count + 1
        end
    end
    local towerTeamCeiling = ctx:GetTowerTeamCeiling()
    if count < towerTeamCeiling then
        local tips = {
            [ElementType.ElementType_Blue] = "str_tower_pet_count_error_water",
            [ElementType.ElementType_Red] = "str_tower_pet_count_error_fire",
            [ElementType.ElementType_Green] = "str_tower_pet_count_error_wood",
            [ElementType.ElementType_Yellow] = "str_tower_pet_count_error_thunder"
        }
        ToastManager.ShowToast(string.format(StringTable.Get(tips[ctx:GetTowerElement()]), towerTeamCeiling))
        return
    end

    return ctx
end

function UIBattleResultComplete:NextFightTeams_Tower()
    local ctx = self:PrepareNextFightTeams_Tower()
    if ctx then
        ctx:ShowDialogUITeams(true)
    end
end

--挑战下一关 尖塔
function UIBattleResultComplete:NextFightBtnOnClick(go)
    local ctx = self:PrepareNextFightTeams_Tower()
    if not ctx then
        return
    end

    ---@type GameMatchModule
    local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
    local createInfo = gameMatchModule:GetMatchCreateInfo(MatchType.MT_Tower, ctx:GetTowerLayerID())

    local curTeamId = ctx:GetCurrTeamId()

    local lockName = "DoEnterMatch"
    self:Lock(lockName)
    self:StartTask(function(TT)
        local res = gameMatchModule:StartMatchTask(TT, MatchType.MT_Tower, curTeamId, createInfo)
        self:UnLock(lockName)
        if not res:GetSucc() then
            ToastManager.ShowToast(gameMatchModule:GetErrorMsg(res:GetResult()))
        end
    end)
end

--弹出连续自动战斗UI
function UIBattleResultComplete:btnSerialAutoFightOnClick()
    self:ShowDialog("UISerialAutoFightInfo", OpenUISerialFightInfoState.OutGame)
end

---@return boolean
function UIBattleResultComplete:_IsAllTaskOver()
    for k, taskID in pairs(self._taskIDList) do
        local task = GameGlobal.TaskManager():FindTask(taskID)
        if task ~= nil then
            return false
        end
    end
    return true
end

---经验条增长动画
function UIBattleResultComplete:_DisplayExpUp(TT, curValue, targetValue, startLv, matchResRoleInfo)
    while not TaskHelper:GetInstance():IsTaskFinished(self._3StarTaskID) do
        YIELD(TT)
    end

    YIELD(TT, 2200)
    self:_DisplayExpUpRecursively(TT, curValue, targetValue, startLv, startLv, matchResRoleInfo)
    self._expIncreaseAnimEnd = false
end

function UIBattleResultComplete:_DisplayExpUpRecursively(TT, startValue, targetValue, curLv, startLv, matchResRoleInfo)
    local lvProp = Cfg.cfg_role_level[curLv]
    if not lvProp then
        return
    end
    local curLvStartExp = HelperProxy:GetInstance():GetLevelExp(curLv)
    local sliderStartValue = startValue - curLvStartExp
    self._expSlider.maxValue = lvProp.NeedExp
    self._expSlider.value = sliderStartValue

    local curLvMaxExp = curLvStartExp + lvProp.NeedExp
    local sliderTargetValue = targetValue - curLvStartExp
    if curLvMaxExp <= targetValue then
        local curLvTargetValue = lvProp.NeedExp
        self._expSlider:DOValue(
            curLvTargetValue,
            self._expIncreaseAnimTime --[[(curLvTargetValue - sliderStartValue) / curLvTargetValue]],
            false
        ):OnUpdate(
            function()
                self._expTxt:SetText(
                    "<color=#D8D8D8>" ..
                    math.floor(self._expSlider.value) ..
                    "</color><color=#00F8FF>/</color><color=#D8D8D8>" .. curLvTargetValue .. "</color>"
                )
            end
        ):OnComplete(
            function()
                local nextLv = curLv + 1
                self._levelTxt:SetText(nextLv)
                if nextLv >= HelperProxy:GetInstance():GetMaxLevel() then
                    local autoFightModule = self:GetModule(SerialAutoFightModule)
                    if not autoFightModule:IsRunning() then
                        self:ShowDialog(
                            "UILevelUp",
                            startLv,
                            nextLv,
                            matchResRoleInfo,
                            function()
                                self:_ShowActivityAward()
                            end
                        )
                    end
                    self._expIncreaseAnimEnd = true
                else
                    self:_DisplayExpUpRecursively(TT, curLvMaxExp, targetValue, nextLv, startLv, matchResRoleInfo)
                end
            end
        )
    else
        self._expSlider:DOValue(
            sliderTargetValue,
            self._expIncreaseAnimTime --[[(sliderTargetValue - sliderStartValue) / lvProp.NeedExp]],
            false
        ):OnUpdate(
            function()
                self._expTxt:SetText(
                    "<color=#D8D8D8>" ..
                    math.floor(self._expSlider.value) ..
                    "</color><color=#00F8FF>/</color><color=#D8D8D8>" .. lvProp.NeedExp .. "</color>"
                )
            end
        ):OnComplete(
            function()
                if curLv ~= startLv then
                    local autoFightModule = self:GetModule(SerialAutoFightModule)
                    if not autoFightModule:IsRunning() then
                        self:ShowDialog(
                            "UILevelUp",
                            startLv,
                            curLv,
                            matchResRoleInfo,
                            function()
                                self:_ShowActivityAward()
                            end
                        )
                    end
                end
                self._expIncreaseAnimEnd = true
            end
        )
    end
end

function UIBattleResultComplete:ShowItemTips(itemID, pos)
    self._selectItemInfo:SetData(itemID, pos)
end

--局内普通战斗结果物品排序
function UIBattleResultComplete:BattleNormalResultSortAsset(assets)
    local dataList = self:GetPassAward()
    table.sort(
        assets,
        function(a, b)
            local ta = Cfg.cfg_item[a.assetid]
            local tb = Cfg.cfg_item[b.assetid]
            if (ta == nil) then
                Log.error(" Cfg.cfg_item cant find assetid ", a.assetid)
            end
            if (tb == nil) then
                Log.error(" Cfg.cfg_item cant find assetid ", b.assetid)
            end
            local aNormal = self:HasItem(dataList, ta.ID)
            local bNormal = self:HasItem(dataList, tb.ID)
            if aNormal == bNormal then
                if ta.Color == tb.Color then
                    return ta.ID < tb.ID
                else
                    return ta.Color > tb.Color
                end
            else
                return aNormal > bNormal
            end
        end
    )
    return assets
end

function UIBattleResultComplete:GetPassAward()
    local awardHeadType, cfgId
    if MatchType.MT_Mission == self._enterData._match_type then
        awardHeadType = AwardHeadType.Mission
        cfgId = self._enterData:GetMissionCreateInfo().mission_id
    elseif MatchType.MT_ExtMission == self._enterData._match_type then
        awardHeadType = AwardHeadType.ExtMisson
        local createData = self._enterData:GetMissionCreateInfo()
        cfgId = createData.m_nExtTaskID
    elseif MatchType.MT_ResDungeon == self._enterData._match_type then
        awardHeadType = AwardHeadType.ResInstance
        local createData = self._enterData:GetResDungeonInfo()
        cfgId = createData.res_dungeon_id
    end
    return UICommonHelper:GetInstance():GetPassAward(awardHeadType, cfgId)
end

function UIBattleResultComplete:GetPassRandomAward()
    -- body
end

function UIBattleResultComplete:HasItem(dataList, itemId)
    local isNormal = 0
    if dataList then
        for i, v in ipairs(dataList) do
            if v.ItemID == itemId then
                isNormal = 1
                break
            end
        end
    end
    return isNormal
end

function UIBattleResultComplete:OnCancelSerialAutoFight()
    self._blockMask:SetActive(false)
    if self._autoBtn then
        self._autoBtn:Hide()
    end
end

function UIBattleResultComplete:blockMaskOnClick()
    ToastManager.ShowToast(StringTable.Get("str_battle_cannot_use"))
end

function UIBattleResultComplete:_CheckNeedShowLevelUp(curLv, curExp, addExp)
    self._bNeedShowLevelUp = false
    local lvProp = Cfg.cfg_role_level[curLv]
    if not lvProp then
        return
    end
    local targetValue = curExp + addExp
    local curLvStartExp = HelperProxy:GetInstance():GetLevelExp(curLv)
    local curLvMaxExp = curLvStartExp + lvProp.NeedExp
    if curLvMaxExp <= targetValue then
        self._bNeedShowLevelUp = true
    end
end

function UIBattleResultComplete:_CheckShowActivityAward()
    if self._bNeedShowLevelUp then
        return
    else
        self:_ShowActivityAward()
    end
end

function UIBattleResultComplete:_ShowActivityAward()
    if self._bNeedPopActivityAward and #self._activityAwards > 0 then
        --弹窗tips文本
        local itemId = self._activityAwards[1].assetid
        local tipsText = ""
        if itemId then
            local tipsCfg = Cfg.cfg_activity_drop_item_get_tips_client[itemId]
            if tipsCfg then
                local tipsId = tipsCfg.GetItemTips
                if tipsId and tipsId ~= "" then
                    tipsText = StringTable.Get(tipsId)
                end
            end
        end
        local titleText = StringTable.Get("str_sakura_get_activity_item")
        self._bNeedPopActivityAward = false
        self:ShowDialog("UIGetItemController", self._activityAwards, nil, nil, tipsText, titleText)
        self._popActivityAwardEnd = true
    end
end

function UIBattleResultComplete:_HideExpAndMoveUpRewards(isHide)
    if isHide then
        self._expParent:SetActive(false)
        self._itemPoolRect.anchoredPosition = Vector2(self._itemPoolRect.anchoredPosition.x, 8)
        self._seasonItemsRect.anchoredPosition = Vector2(self._seasonItemsRect.anchoredPosition.x, 21)
    end
end

--region ActivityN8
---@param enterData MatchEnterData
function UIBattleResultComplete:_IsActivityN8(enterData)
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local createInfo = enterData:GetMissionCreateInfo()
        if createInfo then
            local campId, comId, comType = campaignModule:ParseCampaignMissionParams(createInfo.CampaignMissionParams)
            local campConfig = Cfg.cfg_campaign[campId]
            local campType = campConfig and campConfig.CampaignType

            if campType == ECampaignType.CAMPAIGN_TYPE_N8 then
                if comType == CampaignComType.E_CAMPAIGN_COM_LINE_MISSION then
                    return 1
                elseif comType == CampaignComType.E_CAMPAIGN_COM_CombatSimulator then
                    return 2
                end
            end
        end
    elseif MatchType.MT_BlackFist == enterData._match_type then
        local component_id = enterData:GetBlackFistInfo().component_id
        if component_id == ECampaignMissionComponentId.ECampaignMissionComponentId_SimulatorBlackfist then
            return 2
        end
    end
    return 0
end

---@param enterData MatchEnterData
function UIBattleResultComplete:_NeedHideExpAndMoveUpReards(enterData)
    local isN8Flag = self:_IsActivityN8(enterData)

    if isN8Flag == 1 or isN8Flag == 2 then
        return true
    else
        local isCampaignHideExp = self:IsCampaignMissionHideExp(enterData)
        if isCampaignHideExp then
            return true
        end
    end
    return false
end

--endregion
---@param enterData MatchEnterData
function UIBattleResultComplete:_ActivityResult(enterData)
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local createInfo = enterData:GetMissionCreateInfo()
        if createInfo then
            local campId, comId, comType = campaignModule:ParseCampaignMissionParams(createInfo.CampaignMissionParams)
            local campConfig = Cfg.cfg_campaign[campId]
            if not campConfig then
                self._activityImageObj:SetActive(false)
                return
            end
            local campType = campConfig.CampaignType
            if campType == ECampaignType.CAMPAIGN_TYPE_N12 then
                if
                    comType == CampaignComType.E_CAMPAIGN_COM_DAILY_MISSION or
                    comType == CampaignComType.E_CAMPAIGN_COM_CHALL_MISSION
                then
                    local cfg_campaign_mission = Cfg.cfg_campaign_mission[createInfo.nCampaignMissionId]
                    local levelName = campConfig.CampaignName
                    if cfg_campaign_mission then
                        levelName = cfg_campaign_mission.Name
                    end
                    self._activityResultLeft.dynamicInfoOfEngine:SetObjectName("UIN12BattleResultLeft.prefab")
                    ---@type UIN12BattleResultLeft
                    local item = self._activityResultLeft:SpawnObject("UIN12BattleResultLeft")
                    item:SetData(levelName)
                    if comType == CampaignComType.E_CAMPAIGN_COM_CHALL_MISSION then
                        self._activityResultRight.dynamicInfoOfEngine:SetObjectName("UIN12BattleResultRight.prefab")
                        ---@type UIN12BattleResultRight
                        local item = self._activityResultRight:SpawnObject("UIN12BattleResultRight")
                        item:SetData(self._isWin)
                    end
                    self._activityImageObj:SetActive(comType == CampaignComType.E_CAMPAIGN_COM_DAILY_MISSION)
                    self._starConditionGO:SetActive(false)
                end
            end
        end
    end
end

---@param enterData MatchEnterData
function UIBattleResultComplete:ShowAward(enterData)
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local createInfo = enterData:GetMissionCreateInfo()
        if createInfo then
            local campId, comId, comType = campaignModule:ParseCampaignMissionParams(createInfo.CampaignMissionParams)
            local campConfig = Cfg.cfg_campaign[campId]
            if not campConfig then
                return false
            end
            local campType = campConfig.CampaignType
            if campType == ECampaignType.CAMPAIGN_TYPE_N12 then
                if comType == CampaignComType.E_CAMPAIGN_COM_DAILY_MISSION then
                    return false
                end
            elseif campType == ECampaignType.CAMPAIGN_TYPE_WEEK_TOWER then
                return false
            elseif campType == ECampaignType.CAMPAIGN_TYPE_N13 then
                if comType == CampaignComType.E_CAMPAIGN_COM_LINE_MISSION then
                    return false
                end
            elseif campType == ECampaignType.CAMPAIGN_TYPE_N15 then
                if comType == CampaignComType.E_CAMPAIGN_COM_LINE_MISSION then
                    return false
                end
            elseif campType == ECampaignType.CAMPAIGN_TYPE_CHESS then
                if comType == CampaignComType.E_CAMPAIGN_COM_CHESS then
                    return false
                end
            end
        end
    end
    return true
end

---@param enterData MatchEnterData
function UIBattleResultComplete:ShowCondition(enterData)
    if MatchType.MT_Campaign == enterData._match_type then
        ---@type CampaignModule
        local campaignModule = self:GetModule(CampaignModule)
        local createInfo = enterData:GetMissionCreateInfo()
        if createInfo then
            local campId, comId, comType = campaignModule:ParseCampaignMissionParams(createInfo.CampaignMissionParams)
            local campConfig = Cfg.cfg_campaign[campId]
            if not campConfig then
                return false
            end
            local campType = campConfig.CampaignType
            if campType == ECampaignType.CAMPAIGN_TYPE_N12 then
                if comType == CampaignComType.E_CAMPAIGN_COM_DAILY_MISSION then
                    return false
                end
            elseif campType == ECampaignType.CAMPAIGN_TYPE_WEEK_TOWER then
                return false
            elseif campType == ECampaignType.CAMPAIGN_TYPE_N13 then
                if comType == CampaignComType.E_CAMPAIGN_COM_LINE_MISSION then
                    return false
                end
            end
        end
    end
    return true
end

---@param matchRes UI_MatchResult
---@param seasonMissionInfo SeasonMissionCreateInfo
function UIBattleResultComplete:FillSeasonAwardsArea(matchRes, seasonMissionInfo)
    ---@type UICustomWidgetPool
    local seasonAwardGen = self:GetUIComponent("UISelectObjectPath", "SeasonMultiAwardGroup")
    ---@type UISeasonResultMultiAwardList
    self._seasonMultiAwardList = seasonAwardGen:SpawnObject("UISeasonResultMultiAwardList")
    self._seasonMultiAwardList:SetData(matchRes, seasonMissionInfo)
end
