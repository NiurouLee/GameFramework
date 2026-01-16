---@class UISeasonFinalPlotEnter:UICustomWidget
_class("UISeasonFinalPlotEnter", UICustomWidget)
UISeasonFinalPlotEnter = UISeasonFinalPlotEnter

function UISeasonFinalPlotEnter:OnShow(uiParams)
    self.rootGo = self:GetGameObject("Root")
    self.rootGo:SetActive(false)
    self.baseGo = self:GetGameObject("BaseImage")
    self.canTakeGo = self:GetGameObject("CanTakeImage")
    self.firstShowGo = self:GetGameObject("FirstShowImage")
    self:AttachEvents()
end

function UISeasonFinalPlotEnter:OnHide()
    if self._firstShowTask then
        GameGlobal.TaskManager():KillTask(self._firstShowTask)
        self._firstShowTask = nil
    end
end

function UISeasonFinalPlotEnter:AttachEvents()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest) --奖励弹窗结束后
end

---@param obj UISeasonObj
function UISeasonFinalPlotEnter:SetData(obj)
    ---@type UISeasonObj
    self._seasonObj = obj
    self._story = 0
    self.seasonId = self._seasonObj:GetSeasonID()
    local cfg = Cfg.cfg_season_campaign_client[self.seasonId]
    if cfg then
        self._story = cfg.FinalStoryID
    else
        self.rootGo:SetActive(false)
        return
    end
    ---@type CampaignQuestComponent
    self.questCmpt = self._seasonObj:GetComponent(ECCampaignSeasonComponentID.QUEST_STORY)

    self:Refresh()
end

function UISeasonFinalPlotEnter:OnUIGetItemCloseInQuest(type)
    self:Refresh()
    if self._finalPlotCg then
        self:_OnCollectAwardFinish()
    end
end

function UISeasonFinalPlotEnter:BtnGoOnClick()
    self:EnterPlot()
end

function UISeasonFinalPlotEnter:EnterPlot()
    if not self._story then
        return
    end
    if self._story == 0 then
        return
    end
    if self._firstShowTask then
        GameGlobal.TaskManager():KillTask(self._firstShowTask)
        self._firstShowTask = nil
    end
    UISeasonLocalDBHelper.SeasonFinalPlotBtnShowed_Set(self.seasonId)
    self:Refresh()

    local cb = function() self:OnPlotEnd() end --还没配组件，临时处理
    -- self:ShowDialog("UIStoryController", self._story, cb)
    UISeasonHelper.PlayStoryInSeasonScence(self._story, cb)
end

function UISeasonFinalPlotEnter:OnPlotEndTmp()
    ---@type AsyncRequestRes
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    local rewards = {}
    local roleAsset = RoleAsset:New()
    roleAsset.assetid = 7000110
    roleAsset.count = 1
    table.insert(rewards, roleAsset)
    self:_OnRecvRewardsWithAnim(res, rewards)
end

function UISeasonFinalPlotEnter:OnPlotEnd()
    if not self.questCmpt then
        return
    end
    ---@type CampaignQuestStatus
    local questStatus = self.questCmpt:CheckCampaignQuestStatus(self._quest._questInfo)
    if questStatus == CampaignQuestStatus.CQS_Completed then
        --领奖
        self:ReqTakeAwards(self._quest._questInfo)
    else
        self:Refresh()
        -- self:_OnCollectAwardFinish() --领过奖就不需要分享了
    end
end

---@param questStatus CampaignQuestStatus
function UISeasonFinalPlotEnter:_RefreshByQuestStatus(questStatus)
    if questStatus == CampaignQuestStatus.CQS_Completed then
        self.rootGo:SetActive(true)
        --抖动动画
        self.baseGo:SetActive(true)  --动效问题，各种状态只用base
    elseif questStatus == CampaignQuestStatus.CQS_Taken then
        self.rootGo:SetActive(false) --qa 已领取就不再显示
    else
        self.rootGo:SetActive(false)
    end
end

--动效做的与预期不符，先注掉
-- ---@param questStatus CampaignQuestStatus
-- function UISeasonFinalPlotEnter:_RefreshByQuestStatus(questStatus)
--     if questStatus == CampaignQuestStatus.CQS_Completed then
--         self.rootGo:SetActive(true)
--         --抖动动画
--         self.baseGo:SetActive(false)
--         --本地记录 第一次出现
--         if UISeasonLocalDBHelper.SeasonFinalPlotBtnShowed_Has(self.seasonId) then
--             if self._firstShowTask then
--                 GameGlobal.TaskManager():KillTask(self._firstShowTask)
--                 self._firstShowTask = nil
--             end
--             self.canTakeGo:SetActive(true)
--             self.firstShowGo:SetActive(false)
--         else
--             self.canTakeGo:SetActive(false)
--             self.firstShowGo:SetActive(true)
--             local isPlayingShow = false
--             if self._firstShowTask then
--                 if not TaskHelper:GetInstance():IsTaskFinished(self._firstShowTask) then
--                     isPlayingShow = true
--                 end
--             end
--             if not isPlayingShow then
--                 self._firstShowTask = self:StartTask(
--                     function(TT)
--                         YIELD(TT, 50000)
--                         UISeasonLocalDBHelper.SeasonFinalPlotBtnShowed_Set(self.seasonId)
--                         self:Refresh()
--                     end
--                 )
--             end
--         end
--     elseif questStatus == CampaignQuestStatus.CQS_Taken then
--         if self._firstShowTask then
--             GameGlobal.TaskManager():KillTask(self._firstShowTask)
--             self._firstShowTask = nil
--         end
--         --self.rootGo:SetActive(true)
--         self.rootGo:SetActive(false) --qa 已领取就不再显示
--         --没有抖动
--         self.baseGo:SetActive(true)
--         self.canTakeGo:SetActive(false)
--         self.firstShowGo:SetActive(false)
--     else
--         if self._firstShowTask then
--             GameGlobal.TaskManager():KillTask(self._firstShowTask)
--             self._firstShowTask = nil
--         end
--         self.rootGo:SetActive(false)
--     end
-- end

function UISeasonFinalPlotEnter:Refresh()
    if not self.questCmpt then
        return
    end
    if self.questCmpt then
        ---@type list<Quest>
        self._questList = self.questCmpt:GetQuestInfo()
        local seasonId = self._seasonObj:GetSeasonID()
        local finalStoryQuestId = nil
        local seasonClientCfg = Cfg.cfg_season_campaign_client[seasonId]
        if seasonClientCfg then
            finalStoryQuestId = seasonClientCfg.FinalStoryQuestID
        end
        for i, quest in ipairs(self._questList) do
            if quest:ID() == finalStoryQuestId then
                self._quest = quest
                break
            end
        end
    end
    if not self._quest then
        return
    end
    ---@type CampaignQuestStatus
    local questStatus = self.questCmpt:CheckCampaignQuestStatus(self._quest._questInfo)
    self:_RefreshByQuestStatus(questStatus)
end

function UISeasonFinalPlotEnter:ReqTakeAwards(questInfo)
    self.questCmpt:Start_HandleQuestTake(questInfo.quest_id, function(res, rewards)
        self:_OnRecvRewardsWithAnim(res, rewards)
    end)
end

function UISeasonFinalPlotEnter:_OnRecvRewardsWithAnim(res, rewards)
    if not self.view then
        return
    end
    if res and res:GetSucc() then
        local cfg = Cfg.cfg_season_campaign_client[self.seasonId]
        if cfg.FinalStoryCg then --以此标记判定是否有最终剧情分享功能
            self._finalPlotCg = true
        end
        UISeasonHelper.ShowUIGetRewards(rewards) --开始领奖
        self:Refresh()
    else
        self._seasonObj:CheckErrorCode(
            res.m_result,
            function()
                self:Refresh()
            end,
            function()
            end
        )
    end
end

function UISeasonFinalPlotEnter:_OnCollectAwardFinish()
    self:ShowDialog("UISeasonFinalPlotShare",
        self.seasonId,
        self._seasonObj:GetComponent(ECCampaignSeasonComponentID.STORY),
        function()
            self:_OnShareFinish()
        end
    )
end

function UISeasonFinalPlotEnter:_OnShareFinish()
    self._finalPlotCg = false
end
