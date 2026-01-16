--[[
    活动通用的关卡详情界面
    衍生历史:UIStage->UIActivityStage->UIXH1Stage->UIActivityLevelStage
    UIActivityStage是伊芙活动使用的关卡详情
    UIXH1Stage相对于UIActivityStage,优化了路点截图显示逻辑,支持使用行动点作为体力
    UIActivityLevelStage与UIXH1Stage完全一致,为了不改动已上线的夏活1逻辑,这里复制了一份改了类名作为以后通用的关卡详情界面
    之所以做成通用的是因为ui类名影响自动战斗相关逻辑,每新加一种都需要在UISetAutoFightCount中新加1个分支

    N8 活动关卡不消耗体力及行动点，增加可设置 不显示体力信息 self._hideNeedPower
]]
---@class UIActivityLevelStage:UIController
_class("UIActivityLevelStage", UIController)
UIActivityLevelStage = UIActivityLevelStage

--- @class ActivityMissionType 因为复制文件的原因,这个枚举在UIActivityStage和UIXH1Stage也存在,删掉其他只在这里保留一份
local ActivityMissionType = {
    FightNormal = 1, --普通战斗关卡
    FightBoss = 2, --Boss战斗关卡
    Plot = 3, --剧情关卡
    Node = 4, --节点关卡
    SNode = 5 --s节点关卡
}
_enum("ActivityMissionType", ActivityMissionType)
--
function UIActivityLevelStage:_GetComponents()
    self._chapterPool = self:GetUIComponent("UISelectObjectPath", "chapter_normal")

    self._enemyPool = self:GetUIComponent("UISelectObjectPath", "enemy_normal")

    ---@type UISelectObjectPath
    self._sop = self:GetUIComponent("UISelectObjectPath", "conditions")
    self._conditionGo = self:GetGameObject("condition")
    self._conditionsGo = self:GetGameObject("conditions")
    self._conditionNo = self:GetGameObject("conditionNo")
    ---@type UnityEngine.UI.ScrollRect
    self._sr = self:GetUIComponent("ScrollRect", "ScrollView")
    self._txtCost = self:GetUIComponent("UILocalizationText", "txtCost")
    --Tips
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    local s = self:GetUIComponent("UISelectObjectPath", "itemTips")
    self._tips = s:SpawnObject("UISelectInfo")
    self._rt = self:GetUIComponent("RawImage", "rt")
    self._rtRect = self:GetUIComponent("RectTransform", "rt")
    --self._stagePosition = self:GetUIComponent("UILocalizationText", "stagePosition")
    self._power = self:GetUIComponent("Transform", "power")
    --self._areaBg = self:GetUIComponent("RectTransform", "areaBg")
    --sprite
    self._redBg = self:GetGameObject("redBg")
    self._conditionTitleBg = self:GetUIComponent("Image", "conditionTitleBg")
    self._conditionTitleBg2 = self:GetUIComponent("Image", "conditionTitleBg2")
    self._awardTitleBg = self:GetUIComponent("Image", "awardTitleBg")
    self._awardTitleBg2 = self:GetUIComponent("Image", "awardTitleBg2")
    self._awardTitleTex = self:GetUIComponent("UILocalizationText", "awardTitleTex")
    self._conditionTitleTex = self:GetUIComponent("UILocalizationText", "conditionTitleTex")
    self._buffTips_obj = self:GetGameObject("BuffTips")
    local buffTips = self:GetUIComponent("UISelectObjectPath", "BuffTips")
    self._buffTips = buffTips:SpawnObject("UIResBuffDetail")
    ---@type UISelectObjectPath
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self:CloseDialog()
        end
    )
    self._btnIcon = self:GetUIComponent("Image", "powerIcon")
end

-- onshow
function UIActivityLevelStage:OnShow(uiParams)
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIStage.spriteatlas", LoadType.SpriteAtlas)
    ---@type MissionModule
    self._module = self:GetModule(MissionModule)

    self._missionID = uiParams[1] --点击的关卡id
    ---@type cam_mission_info
    self._missionFinishInfo = uiParams[2] --关卡完成情况
    ---@type ICampaignComponent
    self._campComp = uiParams[3]

    local rt = uiParams[4]
    local offset = uiParams[5]
    local width = uiParams[6]
    local height = uiParams[7]
    local scale = uiParams[8]
    self._autoFightShow = uiParams[9]
    ---@type ICampaignComponent 行动点组件
    self._pointComp = uiParams[10]
    self._hideNeedPower = uiParams[11] -- 隐藏所需体力信息
    self._isChess = uiParams[12] -- 是否是战棋关卡
    if self._isChess == nil then
        self._isChess = false
    end

    --campaignType
    if self._campComp then
        local cmpID = self._campComp:GetComponentCfgId()
        local camModule = self:GetModule(CampaignModule)
        local campID, _, _ = camModule:ParseCfgComponentID(cmpID)
        local campConfig = Cfg.cfg_campaign[campID]
        if campConfig then
            self._campType = campConfig.CampaignType
        end
    end

    self:_GetComponents()

    --设置截图位置缩放
    local maskSize = Vector2(1058, 524)
    local size = Vector2(width, height) * scale
    local deltaX = (size.x - maskSize.x) / 2
    local deltaY = (size.y - maskSize.y) / 2
    local xMin, xMax, yMin, yMax = -deltaX, deltaX, -deltaY, deltaY
    offset = offset * scale
    offset.x = Mathf.Clamp(offset.x, xMin, xMax)
    offset.y = Mathf.Clamp(offset.y, yMin, yMax)
    self._rtRect.sizeDelta = size
    self._rtRect.localScale = Vector3.one
    self._rtRect.anchoredPosition = offset
    self._rt.texture = rt

    self:Init()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryShowHideChapter, false)

    --自动战斗
    self:InitAutoBtnState()

    -- 剧情回顾
    self:_SetStoryBtn()

    -- 设置不显示体力信息
    self:_SetNoNeedPower()

    --关卡词条
    local baseWordBuff = UIWidgetHelper.SpawnObject(self, "BaseWordBuff", "UIStageBaseWordBuff")
    if self._isChess then
        baseWordBuff:SetData(Cfg.cfg_chess_mission[self._missionID])
    else
        baseWordBuff:SetData(Cfg.cfg_campaign_mission[self._missionID])
    end
end

--region UIActivityLevelStage 剧情回顾
function UIActivityLevelStage:_SetStoryBtn()
    self._activityGroupObj = self:GetGameObject("ActivityGroup")
    self._imgBlack = self:GetGameObject("imgBlack")

    local storyList = DiscoveryStoryList:New()
    storyList:Init(self._missionID)

    local flag = self._missionFinishInfo and storyList:Count() ~= 0 and true or false
    self._activityGroupObj:SetActive(flag)
end

--endregion

--region AutoOpenState
---@param stageId number 关卡id
function UIActivityLevelStage.GetAutoOpenState(matchType, stageId)
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
function UIActivityLevelStage.SetAutoOpenState(matchType, stageId, isOpen)
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

function UIActivityLevelStage:InitAutoBtnState()
    local matchType = MatchType.MT_Campaign
    local param = { self._missionID }
    --local enable, msg = self:GetModule(RoleModule):GetAutoFightStatusUI(param, matchType)
    local enable, msg = self:_CanAutoFight()

    self._autoBtnEnable = enable
    self._autoBtnMsg = msg

    local autoFight_root = self:GetGameObject("autoFightRoot")
    local autoFight_lock = self:GetGameObject("lock")
    local autoFight_unlock = self:GetGameObject("unlock")
    --显隐
    autoFight_root:SetActive(self._autoFightShow)
    --置灰
    autoFight_lock:SetActive(not self._autoBtnEnable)
    --autoFight_unlock:SetActive(self._autoBtnEnable)

    --词缀
    self.btnWord = self:GetGameObject("btnUnknown")
    local show = self:_CheckShowWordBuff()
    --self:GetModule(RoleModule):CheckWordBuff(param, matchType)
    if self._isChess then
        self.btnWord:SetActive(false)
    else
        self.btnWord:SetActive(show)
    end
end

function UIActivityLevelStage:autoFightBtnOnClick()
    if self._autoBtnEnable then
        --连续自动战斗
        if self._powerID == RoleAssetID.RoleAssetPhyPoint then
            self:ShowDialog("UISetAutoFightCount", MatchType.MT_Campaign, self._needPower, 0, nil, nil, self._campType)
        else
            --体力的物品id不是棱镜，则视为活动关卡的行动点
            self:ShowDialog(
                "UISetAutoFightCount",
                MatchType.MT_Campaign,
                self._needPower,
                0,
                nil,
                self._pointComp,
                self._campType
            )
        end
    else
        ToastManager.ShowToast(StringTable.Get(self._autoBtnMsg))
    end
end

function UIActivityLevelStage:OnHide()
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryShowHideChapter, true)
end

function UIActivityLevelStage:InitAwards(missionCfg)
    ---@type table<int, Award>
    local awards = self:ProcessAward(missionCfg)
    if not awards then
        return
    end
    local count = table.count(awards)
    ---@type UnityEngine.UI.GridLayoutGroup
    local grid = self:GetUIComponent("GridLayoutGroup", "Content")
    --local awardScrollView = self:GetUIComponent("ScrollRect", "ScrollView")
    local contentSizeFilter = self:GetUIComponent("ContentSizeFitter", "Content")
    ---@type UnityEngine.RectTransform
    local contentRect = self:GetUIComponent("RectTransform", "Content")
    if count > 6 then
        grid.childAlignment = UnityEngine.TextAnchor.MiddleLeft
        contentSizeFilter.enabled = true
    else
        grid.childAlignment = UnityEngine.TextAnchor.MiddleCenter
        contentSizeFilter.enabled = false
    end
    contentRect.localPosition = Vector3(0, 0, 0)

    ---@type UISelectObjectPath
    local sop = self:GetUIComponent("UISelectObjectPath", "Content")
    sop:SpawnObjects("UIAwardItem", count)
    ---@type UIAwardItem[]
    local list = sop:GetAllSpawnList()
    for i, v in ipairs(list) do
        v:Flush(awards[i])
    end
end

function UIActivityLevelStage:ProcessAward(missionCfg)
    local awards = {}
    if not self:HasPassThreeStar(missionCfg) then
        local awardsStar = self:GetSortedArr(AwardType.ThreeStar, missionCfg, StageAwardType.Star)
        if awardsStar then
            for i, v in ipairs(awardsStar) do
                awards[#awards + 1] = v
            end
        end
    end
    if not self._missionFinishInfo then
        local awardsFirst = self:GetSortedArr(AwardType.First, missionCfg, StageAwardType.First)
        if awardsFirst then
            for i, v in ipairs(awardsFirst) do
                awards[#awards + 1] = v
            end
        end
    end
    local normalArr = self:GetSortedArr(AwardType.Pass, missionCfg, StageAwardType.Normal)
    if normalArr then
        for i, v in ipairs(normalArr) do
            awards[#awards + 1] = v
        end
    end
    return awards
end

function UIActivityLevelStage:HasPassThreeStar(missionCfg)
    if not self._missionFinishInfo then
        return false
    end

    if missionCfg.ThreeStarCondition1 and (self._missionFinishInfo.star & 1) == 0 then
        return false
    end

    if missionCfg.ThreeStarCondition2 and (self._missionFinishInfo.star & 2) == 0 then
        return false
    end

    if missionCfg.ThreeStarCondition3 and (self._missionFinishInfo.star & 4) == 0 then
        return false
    end

    return true
end

function UIActivityLevelStage:GetSortedArr(awardType, cfg, stageAwardType)
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

---根据路点id初始化
function UIActivityLevelStage:Init()
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if self._isChess then
        missionCfg = Cfg.cfg_chess_mission[self._missionID]
    end
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
        self._powerPool = self:GetUIComponent("UISelectObjectPath", "powerpool")
        ---@type UIPowerInfo
        local powerPool = self._powerPool:SpawnObject("UIPowerInfo")
        powerPool:SetData(self._power)
    else
        if not self._pointComp then
            Log.exception("关卡体力为行动点,但没有传入活动的行动点组件")
        end
        self._pointPool = self:GetUIComponent("UISelectObjectPath", "pointpool")
        ---@type UIActivityPointToptip
        local pointPool = self._pointPool:SpawnObject("UIActivityPointToptip")
        pointPool:SetData(self._pointComp, self._needPower)
        local cmpID = self._pointComp:GetComponentCfgId()
        local pointCfg = self._pointComp:GetActionPointConfig()
        local itemCfg = Cfg.cfg_top_tips[pointCfg.ItemID]
        self._btnIcon.sprite = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas):GetSprite(itemCfg.Icon)

        -- 行动点不足时显示红色
        local module = self:GetModule(ItemModule)
        local count = module:GetItemCount(pointCfg.ItemID)
        if count < self._needPower then
            needPowerText = "<color=#FF0000>" .. self._needPower .. "</color>"
        end
    end

    self._txtCost:SetText(needPowerText)
    ---end

    local color = Color(1, 1, 1, 1)
    local enemyTitleBgSprite = nil
    local enemyTitleBg2Sprite = nil
    if missionCfg.Type == ActivityMissionType.FightBoss then
        self._awardTitleBg.sprite = self._atlas:GetSprite("map_guanqia_tiao7")
        self._awardTitleBg2.sprite = self._atlas:GetSprite("map_guanqia_tiao8")

        self._conditionTitleBg.sprite = self._atlas:GetSprite("map_guanqia_tiao3")
        self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_guanqia_tiao4")

        enemyTitleBgSprite = self._atlas:GetSprite("map_guanqia_tiao3")
        enemyTitleBg2Sprite = self._atlas:GetSprite("map_guanqia_tiao4")

        self._redBg:SetActive(true)
    else
        color = Color(100 / 255, 100 / 255, 100 / 255, 1)
        self._awardTitleBg.sprite = self._atlas:GetSprite("map_guanqia_tiao5")
        self._awardTitleBg2.sprite = self._atlas:GetSprite("map_guanqia_tiao6")

        self._conditionTitleBg.sprite = self._atlas:GetSprite("map_bantou4_frame")
        self._conditionTitleBg2.sprite = self._atlas:GetSprite("map_bantou15_frame")

        enemyTitleBgSprite = self._atlas:GetSprite("map_bantou4_frame")
        enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")

        self._redBg:SetActive(false)
    end

    if self._isChess then
        self._buffTips_obj:SetActive(false)
    else
        self._buffTips_obj:SetActive(true)
    end

    self._awardTitleTex.color = color
    self._conditionTitleTex.color = color

    self:Flush(missionCfg)
    self:InitAwards(missionCfg)

    self._reachGo = self:GetGameObject("reachGo")
    self._reachGo:SetActive(false)

    --enemy
    ---@type UIStageEnemy
    self._enemyObj = self._enemyPool:SpawnObject("UIStageEnemy")

    local recommendAwaken = missionCfg.RecommendAwaken and missionCfg.RecommendAwaken or 0
    local recommendLV = missionCfg.RecommendLV and missionCfg.RecommendLV or 0
    self._enemyObj:Flush(
        recommendAwaken,
        recommendLV,
        missionCfg.FightLevel or missionCfg.LevelID,
        color,
        enemyTitleBgSprite,
        enemyTitleBg2Sprite,
        self._isChess
    )
end

function UIActivityLevelStage:Flush(missionCfg)
    ---@type UIStageChapter
    local chapterObj = self._chapterPool:SpawnObject("UIStageChapter")
    chapterObj:Flush(
        nil,
        StringTable.Get(missionCfg.Name),
        StringTable.Get(missionCfg.Desc),
        nil,
        false
    )

    local threeStarConditions = {}

    if missionCfg.IgnoreThreeStar == 0 then
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
        if self._missionFinishInfo then
            local starCount, completeStarList = self._module:ParseStarInfo(self._missionFinishInfo.star)
            self:UpdateCondition(threeStarConditions, completeStarList)
        end
    end

    --条件
    if self._campComp:GetComponentType() == CampaignComType.E_CAMPAIGN_COM_TREE_MISSION then
        -- UIActivityLevelStage E_CAMPAIGN_COM_TREE_MISSION 时隐藏条件
        self._conditionGo:SetActive(false)
        self._conditionsGo:SetActive(false)
        self._conditionNo:SetActive(false)
    else
        if #threeStarConditions > 0 then
            self._conditionGo:SetActive(true)
            self._conditionsGo:SetActive(true)
            self._conditionNo:SetActive(false)
            self._sop:SpawnObjects("UIConditionItem", #threeStarConditions)
            ---@type UIConditionItem[]
            self._conditions = self._sop:GetAllSpawnList()
            for i, v in ipairs(self._conditions) do
                v:Flush(threeStarConditions[i], i)
            end
        else
            self._conditionGo:SetActive(false)
            self._conditionNo:SetActive(true)
        end
    end
    self._sr.horizontalNormalizedPosition = 0
end

function UIActivityLevelStage:btnFightOnClick(go)
    if self._isChess then
        --进入战斗音效
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIBattleStart)

        self:Lock("DoEnterMatch")
        --进局
        ---@type GameMatchModule
        local game = GameGlobal.GetModule(GameMatchModule)
        local matchType = MatchType.MT_Chess
        local teamId = 1
        local parmas = {}
        table.insert(parmas, self._missionID)
        table.insert(parmas, ECampaignMissionComponentId.ECampaignMissionComponentId_ChessMission)
        table.insert(parmas, self._campComp:GetCampaignMissionParamKeyMap())
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
        return
    end
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    local enough = false
    local roleModule = self:GetModule(RoleModule)
    local leftPower = roleModule:GetAssetCount(self._powerID)
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
        TeamOpenerType.Campaign,
        {
            self._missionID,
            self._campComp:GetCampaignMissionComponentId(),
            self._campComp:GetCampaignMissionParamKeyMap()
        }
    )
    self:Lock("DoEnterTeam")
    ctx:ShowDialogUITeams()
end

function UIActivityLevelStage:UpdateCondition(three_star_condition, conditions)
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

function UIActivityLevelStage:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end

function UIActivityLevelStage:bgOnClick()
    self:CloseDialog()
end

function UIActivityLevelStage:threeStarTipsBtnOnClick(go)
    --GameGlobal.UAReportForceGuideEvent("UIStageClick", {"threeStarTipsBtnOnClick"}, true)
    self:ShowDialog("UIThreeStarTips")
end

function UIActivityLevelStage:btnUnknownOnClick(go)
    local buffData = {}
    buffData.name = ""
    buffData.des = ""
    local buffId = BattleConst.WordBuffForMission
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if missionCfg then
        if missionCfg.WordBuff and missionCfg.WordBuff ~= 0 then
            buffId = missionCfg.WordBuff
        end
    end
    local word = Cfg.cfg_word_buff[buffId]
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
end

function UIActivityLevelStage:btnPlotOnClick()
    local storyList = DiscoveryStoryList:New()
    storyList:Init(self._missionID)

    if storyList then
        if storyList:Count() == 1 then
            local story = storyList.list[1]
            self:ShowDialog("UIStoryController", story.id)
        else
            local before = storyList:GetStoryByStoryType(StoryTriggerType.BeforeFight)
            local after = storyList:GetStoryByStoryType(StoryTriggerType.AfterFight)
            if not before and not after then
                Log.warn("### no story in curStage", storyList.stageId)
            end
            if before and after then
                self._imgBlack:SetActive(true)
                self:ShowDialog(
                    "UIStoryController",
                    before.id,
                    function()
                        self:StartTask(
                            function()
                                YIELD(TT)
                                self:ShowDialog(
                                    "UIStoryController",
                                    after.id,
                                    function()
                                        self._imgBlack:SetActive(false)
                                    end
                                )
                            end
                        )
                    end
                )
            else
                local story = storyList.list[1]
                self:ShowDialog("UIStoryController", story.id)
            end
        end
    end
end

--检查可开启连续自动战斗
function UIActivityLevelStage:_CanAutoFight()
    local tipsStr = ""
    local cfg = Cfg.cfg_global["auto_fight_need_pass"]
    if cfg and cfg.StrValue then
        tipsStr = cfg.StrValue
        --if cfg.IntValue == 1 then
        --end
    end
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if not missionCfg then
        return false, tipsStr
    end
    local enableParam = missionCfg.EnableSerialAutoFight
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_DISABLE then
        return false, tipsStr
        --不应该显示
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_ENABLE then
        return true
    end
    if enableParam == CampainMissionCanSerialAutoFightType.E_CAMPAIGN_MISSION_CAN_SERIAL_AUTO_FIGHT_NEED_UNLOCK then
        if self._missionFinishInfo then
            return true
        else
            return false, tipsStr
        end
    end
    return false
end

--检查显示熟练的智慧按钮
function UIActivityLevelStage:_CheckShowWordBuff()
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if not missionCfg then
        return false
    end
    if missionCfg.WordBuff and missionCfg.WordBuff > 0 then
    else
        return false
    end
    if not self._missionFinishInfo then
        return false
    end
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if not self:HasPassThreeStar(missionCfg) then --未三星通关
        return false
    end
    -- if (self._missionFinishInfo.star & 4) == 0 then --未三星通关
    --     return false
    -- end
    return true
end

function UIActivityLevelStage:_SetNoNeedPower()
    if self._hideNeedPower then
        local powerPool = self:GetGameObject("powerpool")
        powerPool:SetActive(false)

        local cost = self:GetGameObject("cost")
        local noCost = self:GetGameObject("noCost")
        cost:SetActive(false)
        noCost:SetActive(true)
    end
end
