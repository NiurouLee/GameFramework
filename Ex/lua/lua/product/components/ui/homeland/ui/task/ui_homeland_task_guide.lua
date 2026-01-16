--
---@class UIhomelandTaskGuide : UICustomWidget
_class("UIhomelandTaskGuide", UICustomWidget)
UIhomelandTaskGuide = UIhomelandTaskGuide

function UIhomelandTaskGuide:Constructor()
    self._btnWidgets = nil
end

--初始化
function UIhomelandTaskGuide:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIhomelandTaskGuide:_GetComponents()
    self._guideBtns = self:GetUIComponent("UISelectObjectPath", "GuideBtns")
    ---@type UIDynamicScrollView
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")
    ---@type RawImageLoader
    self._guideTaskDone = self:GetGameObject("GuideTaskDone")
    self._taskName = self:GetUIComponent("UILocalizationText", "GuideTaskName")
    self._icon = self:GetUIComponent("RawImageLoader", "Icon")
    self._rewards = self:GetUIComponent("UISelectObjectPath", "Rewards")
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._parent = self:GetGameObject("Parent")
    self._descripution = self:GetGameObject("Descripution")
end

--设置数据
function UIhomelandTaskGuide:SetData(questData)
    self._allQuests = questData
    local defaultGroupID = 1
    local initDefault = false
    ---@type table<number, UIHomelandTaskGuideBtn>
    self._btnWidgets = self._guideBtns:SpawnObjects("UIHomelandTaskGuideBtn", #self._allQuests)
    for groupID, quests in pairs(self._allQuests) do
        if not self:_CheckAllQuestDone(quests) and not initDefault then
            defaultGroupID = groupID
            initDefault = true
        end
        self._btnWidgets[groupID]:SetData(groupID, 
        function (groupID)
            self:_RefreshUIInfo(groupID)
        end)
    end
    self:_RefreshUIInfo(defaultGroupID)
end

function UIhomelandTaskGuide:_RefreshUIInfo(groupID)
    for _, widget in pairs(self._btnWidgets) do
        widget:RefreshBtn(groupID)
    end
    local cfg = Cfg.cfg_homeland_task_group[groupID]
    self._taskName:SetText(StringTable.Get(cfg.GroupTitle))
    local quests = self._allQuests[groupID]
    local preQuestsDone = true
    if groupID > 1 then
        preQuestsDone = self:_CheckAllQuestDone(self._allQuests[groupID - 1])
    end
    self._parent:SetActive(preQuestsDone)
    self._descripution:SetActive(not preQuestsDone)
    if not preQuestsDone then
        return
    end
    local done = self:_CheckAllQuestDone(quests)
    self._icon:LoadImage(cfg.GroupIcon)
    self._guideTaskDone:SetActive(done)
    ---@type table<number, UIHomelandTaskGuideRewardItem>
    self._rewardsWidgets = self._rewards:SpawnObjects("UIHomelandTaskGuideRewardItem", #cfg.Reward)
    for key, widget in pairs(self._rewardsWidgets) do
        ---@type RoleAsset
        local roleAsset = {}
        roleAsset.assetid = cfg.Reward[key][1]
        roleAsset.count = cfg.Reward[key][2]
        widget:SetData(roleAsset, done)
    end
    ---@type table<number, UIHomelandTaskGuideItem>
    self._contentWidgets = self._content:SpawnObjects("UIHomelandTaskGuideItem", #quests)
    for key, widget in pairs(self._contentWidgets) do
        widget:SetData(quests[key])
    end
end

---@param quests table<number, Quest>
function UIhomelandTaskGuide:_CheckAllQuestDone(quests)
    for _, quest in pairs(quests) do
        if quest:QuestInfo().status < QuestStatus.QUEST_Taken then
            return false
        end
    end
    return true
end