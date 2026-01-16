---@class UIQuestAchievementLatelyAchieveItem:UICustomWidget
_class("UIQuestAchievementLatelyAchieveItem", UICustomWidget)
UIQuestAchievementLatelyAchieveItem = UIQuestAchievementLatelyAchieveItem

--成就任务的每一条customwidget
function UIQuestAchievementLatelyAchieveItem:OnShow(uiParams)
    self._animation = self:GetUIComponent("Animation", "UIQuestAchievementLatelyAchieveItem")
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("[quest] error --> module is nil !")
        return
    end
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
end

function UIQuestAchievementLatelyAchieveItem:SetData(index, quest, getCallback, awardCallBack, isIntro)
    if self._introTask then
        GameGlobal.TaskManager():KillTask(self._introTask)
    end
    self:_GetComponents()
    self._quest = quest
    self._index = index
    self._point = 0
    for i = 1, #self._quest.rewards do
        if self._quest.rewards[i].assetid == RoleAssetID.RoleAssetAchPoint then
            self._point = self._quest.rewards[i].count
        end
    end
    self._getCallback = getCallback
    self._awardCallBack = awardCallBack
    self._finishState = quest.status --0,1,未完成 2，未领取 3，已领取
    self:_OnValue()

    if isIntro and (not self._isIntroPlayed) then
        self._introTask = GameGlobal.TaskManager():StartTask(function (TT)
            self._isIntroPlayed = true

            self._animation:Stop()
            YIELD(TT, index * 50)
            self._animation:Play("uieff_Quest_AchieveLatelyItem_In")
            self._introTask = nil
        end)
    end
end

function UIQuestAchievementLatelyAchieveItem:OnHide()
    if self._introTask then
        GameGlobal.TaskManager():KillTask(self._introTask)
    end
end

function UIQuestAchievementLatelyAchieveItem:_GetComponents()
    self._achieveTagTex = self:GetUIComponent("UILocalizationText", "achieveTagTex")
    self._achieveDesTex = self:GetUIComponent("UILocalizationText", "achieveDesTex")
    self._achievePointTex = self:GetUIComponent("UILocalizationText", "achievePointTex")
    self._stateValueTex = self:GetUIComponent("UILocalizationText", "stateValueTex")
    self._revolvingText = self:GetUIComponent("RevolvingTextWithDynamicScroll", "revolvingText")

    self._finishGo = self:GetGameObject("Finish")
    self._gotoGo = self:GetGameObject("GoTo")
    self._getGo = self:GetGameObject("Get")

    self._valueImg = self:GetUIComponent("Image", "valueImg")

    self._pools = self:GetUIComponent("UISelectObjectPath", "pools")
end

function UIQuestAchievementLatelyAchieveItem:_OnValue()
    self._achieveTagTex:SetText(StringTable.Get(self._quest.QuestName))
    self._achieveDesTex:SetText(StringTable.Get(self._quest.CondDesc))
    self._achievePointTex:SetText(self._point)

    local progress = ""
    if self._quest.ShowType == 1 then
        local c, d = math.modf(self._quest.cur_progress * 100 / self._quest.total_progress)
        if c < 1 and d > 0 then
            c = 1
        end
        progress = c .. "%"
    else
        progress = self._quest.cur_progress .. "/" .. self._quest.total_progress
    end
    self._stateValueTex:SetText(progress)

    self._revolvingText:OnRefreshRevolving()

    local rate = self._quest.cur_progress / self._quest.total_progress
    self._valueImg.fillAmount = rate

    self:_CheckQuestState()

    local awards = self._quest.rewards
    local awardsTemp = {}
    for i = 1, #awards do
        local award = awards[i]
        if award.assetid ~= RoleAssetID.RoleAssetAchPoint then
            table.insert(awardsTemp, award)
        end
    end
    local awardsCount = table.count(awardsTemp)

    self._pools:SpawnObjects("UIQuestSmallAwardItem", 2)
    local items = self._pools:GetAllSpawnList()
    for i = 1, table.count(items) do
        if i <= awardsCount then
            items[i]:GetGameObject():SetActive(true)
            items[i]:SetData(i, awardsTemp[i], self._awardCallBack, UIItemScale.Level4)
        else
            items[i]:GetGameObject():SetActive(false)
        end
    end
end

--任务状态
function UIQuestAchievementLatelyAchieveItem:_CheckQuestState()
    self._finishGo:SetActive(false)
    self._gotoGo:SetActive(false)
    self._getGo:SetActive(false)

    if self._quest.status <= QuestStatus.QUEST_Accepted then
        self._gotoGo:SetActive(true)
    elseif self._quest.status == QuestStatus.QUEST_Completed then
        self._getGo:SetActive(true)
    elseif self._quest.status == QuestStatus.QUEST_Taken then
        self._finishGo:SetActive(true)
    end
end

function UIQuestAchievementLatelyAchieveItem:GetBtnOnClick()
    if self._getCallback then
        self._getCallback(self._quest)
    end
end
