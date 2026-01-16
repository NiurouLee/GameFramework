--
---@class UIN1SpecialTaskItem : UICustomWidget
_class("UIN1SpecialTaskItem", UICustomWidget)
UIN1SpecialTaskItem = UIN1SpecialTaskItem

function UIN1SpecialTaskItem:Constructor()
    self._svrTimeModule = self:GetModule(SvrTimeModule)
end

--初始化
function UIN1SpecialTaskItem:OnShow(uiParams)
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("N1SpecialTask.spriteatlas", LoadType.SpriteAtlas)
    self:_GetComponents()
end

function UIN1SpecialTaskItem:OnHide()
    if self._cdTask then
        GameGlobal.TaskManager():KillTask(self._cdTask)
        self._cdTask = nil
    end
end

--获取ui组件
function UIN1SpecialTaskItem:_GetComponents()
    self._descRollText = self:GetUIComponent("UILocalizationText", "Desc")
    ---@type UILocalizationText
    self._progress = self:GetUIComponent("UILocalizationText", "Progress")
    ---@type UICustomWidgetPool
    self._redPoint = self:GetGameObject("RedPoint")
    ---@type UICustomWidgetPool
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._lockGo = self:GetGameObject("Lock")
    ---@type UILocalizationText
    self._lockText = self:GetUIComponent("UILocalizationText", "LockText")
    self._selectedGo = self:GetGameObject("Selected")
    self._gotGo = self:GetGameObject("Got")
    self._gotRawImage = self:GetUIComponent("RawImageLoader", "Got")
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect","ScrollView")
    --self._progressBar = self:GetUIComponent("Image", "progressBar")
    self._doingBtn = self:GetGameObject("DoingBtn")
    self._getBtn = self:GetGameObject("GetBtn")
    self._gotBtn = self:GetGameObject("GotBtn")

    self._daily = self:GetGameObject("daily")
    self._notdaily = self:GetGameObject("notdaily")
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
end
function UIN1SpecialTaskItem:SetDaily()
    local cfg = Cfg.cfg_component_quest{QuestID=self._questInfo.quest_id}
    if cfg and next(cfg) then
        local daily = cfg[1].NeedReset or false
        self._daily:SetActive(daily)
        self._notdaily:SetActive(not daily)
    end
end
--设置数据
---@param component CampaignQuestComponent
---@param quest Quest
function UIN1SpecialTaskItem:SetData(component, quest, callback, showTips, refreshUI, closeUI, errorCheck)
    self._questComponent = component
    self._questComponentInfo = self._questComponent:GetComponentInfo()
    self._quest = quest
    self._callback = callback
    self._showTips = showTips
    self._refreshUI = refreshUI
    self._closeUI = closeUI
    self._errorCheck = errorCheck
    self._questInfo = self._quest:QuestInfo()
    self._state = self._quest:Status()
    ---@type CampaignQuestStatus
    self._campaignQuestState = self._questComponent:CheckCampaignQuestStatus(self._questInfo)

    self:_SetLock(self._campaignQuestState == CampaignQuestStatus.CQS_NotStart)
    local descStr = StringTable.Get(self._questInfo.QuestDesc) 
    local progressStr = self._questInfo.cur_progress
    if self._cdTask then
        GameGlobal.TaskManager():KillTask(self._cdTask)
        self._cdTask = nil
    end
    if self._campaignQuestState == CampaignQuestStatus.CQS_NotStart then
        local curTime = self._svrTimeModule:GetServerTime() * 0.001
        local timeInfo = self._questComponentInfo.m_quest_time_param_map[self._questInfo.quest_id]
        local remainTime = timeInfo.m_open_time - curTime
        local unlockTime = UIN1SpecialTaskToolFunctions.GetRemainTime(remainTime)
        self._lockText:SetText(StringTable.Get("str_n24_specialtask_unlock", unlockTime))
        self._cdTask = self:StartTask(
        function(TT)
            YIELD(TT, (remainTime + 1) * 1000)
            if self._refreshUI then
                self._refreshUI()
            end
        end,
        self)
    end
    if self._state == QuestStatus.QUEST_Accepted then
        progressStr = "<color=#ffe98a>".. self._questInfo.cur_progress .. "</color>"
        progressStr = StringTable.Get("str_sakura_specialtask_progress", progressStr .. "/" .. self._questInfo.total_progress)
        self._doingBtn:SetActive(true)
        self._getBtn:SetActive(false)
        self._gotBtn:SetActive(false)
    elseif self._state == QuestStatus.QUEST_Completed then
        progressStr = "<color=#FFFFFF>".. self._questInfo.cur_progress .. "</color>"
        progressStr = StringTable.Get("str_sakura_specialtask_progress", progressStr .. "/" .. self._questInfo.total_progress)
        self._doingBtn:SetActive(false)
        self._getBtn:SetActive(true)
        self._gotBtn:SetActive(false)
    elseif self._state == QuestStatus.QUEST_Taken then
        progressStr = StringTable.Get("str_sakura_specialtask_progress", self._questInfo.cur_progress .. "/" .. self._questInfo.total_progress)
        progressStr = "<color=#FFFFFF>".. progressStr .. "</color>"
        self._doingBtn:SetActive(false)
        self._getBtn:SetActive(false)
        self._gotBtn:SetActive(true)
    end
    self._descRollText:SetText(descStr)
    self._progress:SetText(progressStr)
    -- local rate = self._questInfo.cur_progress / self._questInfo.total_progress
    -- self._progressBar.fillAmount = rate

    self._redPoint:SetActive(self._state == QuestStatus.QUEST_Completed)
    self._gotGo:SetActive(self._state == QuestStatus.QUEST_Taken)


    self._questID = self._questInfo.quest_id
    local cfg_vice_awards = Cfg.cfg_activity_vice_quest_rewards_view[self._questID]
    local item = cfg_vice_awards.AwardsView

    local count = #item

    if count == 1 then
        self._gotRawImage:LoadImage("gf_n1_bzhd_mask01")
    else
        self._gotRawImage:LoadImage("gf_n1_bzhd_mask02")
    end

    --local count = #self._questInfo.rewards
    if count <= 0 then
        return
    end
    if count <= 2 then
        self._scrollRect.horizontal = false
    else
        self._scrollRect.horizontal = true
    end
    self._content:SpawnObjects("UIN1SpecialTaskAwardItem", count)
    ---@type UIN1SpecialTaskAwardItem[]
    local items = self._content:GetAllSpawnList()
    for i = 1, count do
        --local cfg = Cfg.cfg_item[reward.assetid]
        --local cfg = Cfg.cfg_item[self._questInfo.rewards[i].assetid]
        --if cfg then
            items[i]:SetData(item[i], self._showTips, self._campaignQuestState == CampaignQuestStatus.CQS_NotStart)
            --items[i]:SetData(self._questInfo.rewards[i], self._showTips, self._campaignQuestState == CampaignQuestStatus.CQS_NotStart)
        --end
    end
    self:SetDaily()
end

function UIN1SpecialTaskItem:_SetLock(isLock)
    self._lockGo:SetActive(isLock)
    self:GetGameObject("ScrollView"):SetActive(not isLock)
    self:GetGameObject("Desc"):SetActive(not isLock)
end

--按钮点击
function UIN1SpecialTaskItem:GetOnClick(go)
    if self._state == QuestStatus.QUEST_Completed then
        GameGlobal.TaskManager():StartTask(self.GetAwards, self)
    end
    self:OnSelect(true)
    self._callback(self)
end

function UIN1SpecialTaskItem:OnSelect(select)
    --self._selectedGo:SetActive(select)
end

function UIN1SpecialTaskItem:GetAwards(TT)
    self:Lock("UIN1SpecialTaskItemGetAwards")
    local res = AsyncRequestRes:New()
    local retCode, rewards = self._questComponent:HandleQuestTake(TT, res, self._quest:ID())
    if retCode == QuestErrorCode.QuestEC_Succ then
        self:ShowRewards(rewards)
        -- if self._refreshUI then
        --     self._refreshUI()
        -- end
    else
        if self._errorCheck then
            self._errorCheck(res.m_result)
        end
    end
    self:UnLock("UIN1SpecialTaskItemGetAwards")
end

function UIN1SpecialTaskItem:ShowRewards(rewards)
    local petIdList = {}
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    
    for _, reward in pairs(rewards) do
        if petModule:IsPetID(reward.assetid) then
            table.insert(petIdList, reward)
        end
    end
    if table.count(petIdList) > 0 then
        self:ShowDialog(
            "UIPetObtain",
            petIdList,
            function()
                GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                self:ShowDialog("UIGetItemController", rewards)
            end
        )
        return
    end
    self:ShowDialog("UIGetItemController", rewards)
end

function UIN1SpecialTaskItem:PlayAnimationInSequence(index)
    local delay = 0 + (index - 1) * 50
    UIWidgetHelper.PlayAnimationInSequence(self, "_anim", "_anim", "uieff_UIN1SpecialTaskItem_in", delay)
end