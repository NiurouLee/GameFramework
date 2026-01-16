---@class UIQuestAchievementPointAwardsItem:UICustomWidget
_class("UIQuestAchievementPointAwardsItem", UICustomWidget)
UIQuestAchievementPointAwardsItem = UIQuestAchievementPointAwardsItem

function UIQuestAchievementPointAwardsItem:OnShow(uiParams)
    ---@type QuestModule
    self._questModule = GameGlobal.GetModule(QuestModule)
    if self._questModule == nil then
        Log.fatal("[quest] error --> self._questModule is nil !")
        return
    end

    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvents()
end

function UIQuestAchievementPointAwardsItem:OnHide()
    self:RemoveEvents()
end

function UIQuestAchievementPointAwardsItem:_GetComponents()
    ---@type UILocalizationText
    self._pointValueTex = self:GetUIComponent("UILocalizationText", "getState")
    self._itemCountTex = self:GetUIComponent("UILocalizationText", "cTex")
    self._itemPool = self:GetUIComponent("UISelectObjectPath", "item")
    self._btnImg = self:GetUIComponent("Image", "btn")
    self._btnGo = self:GetGameObject("btn")
    self._countGo = self:GetGameObject("count")
    self._line = self:GetGameObject("line")
    --self._colorGo = self:GetGameObject("color")
end

function UIQuestAchievementPointAwardsItem:_OnValue()
    local got = self._questModule:IsGotAchPointReward(self._rewardid)
    if got then
        self._getState = QuestStatus.QUEST_Taken
    else
        if self._currentPoint < self._value then
            self._getState = QuestStatus.QUEST_Accepted
        else
            self._getState = QuestStatus.QUEST_Completed
        end
    end

    self._btnGo:SetActive(false)
    --self._colorGo:SetActive(false)
    self._countGo:SetActive(false)

    if self._getState <= QuestStatus.QUEST_Accepted then
        self._countGo:SetActive(true)
        self._itemCountTex:SetText(self._value)
    elseif self._getState == QuestStatus.QUEST_Completed then
        self._btnGo:SetActive(true)
        --self._colorGo:SetActive(true)
        self._btnImg.sprite = self._atlas:GetSprite("task_chengjiu_frame17")
        self._pointValueTex:SetText(StringTable.Get("str_quest_base_can_get"))
        self._pointValueTex.color = Color(46 / 255, 46 / 255, 46 / 255)
    elseif self._getState == QuestStatus.QUEST_Taken then
        --self._colorGo:SetActive(false)
        self._btnGo:SetActive(true)
        self._btnImg.sprite = self._atlas:GetSprite("task_chengjiu_frame21")
        self._pointValueTex:SetText(StringTable.Get("str_quest_base_got"))
        self._pointValueTex.color = Color(77 / 255, 77 / 255, 77 / 255)
    end

    local item = self._itemPool:SpawnObject("UIQuestBigAwardItem")
    local rewards = {}
    rewards.assetid = self._reward[1]
    rewards.count = self._reward[2]

    item:SetData(self._rewardid, rewards, self._lookCallback, false)
end

function UIQuestAchievementPointAwardsItem:SetData(index, point, currentPoint, reward, callback, lookCallback)
    self:_GetComponents()
    self._rewardid = index
    self._value = point
    self._currentPoint = currentPoint
    self._reward = reward[1]
    self._lookCallback = lookCallback

    self._line:SetActive(index ~= 1)

    --成就点领取状态,0,1,不可，2可领，3一领
    self._getState = 0

    self:_OnValue()
end

function UIQuestAchievementPointAwardsItem:bgOnClick()
    if self._getState <= QuestStatus.QUEST_Accepted then
        -- body
    elseif self._getState == QuestStatus.QUEST_Completed then
        GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
        self:Lock("UIQuestGet")
        self:StartTask(self._OnGet, self)
    elseif self._getState == QuestStatus.QUEST_Taken then
    -- body
    end
end

function UIQuestAchievementPointAwardsItem:OnUIGetItemCloseInQuest(type, index)
    if type == (QuestType.QT_Achieve + 100) and index == self._rewardid then
        self._btnGo:SetActive(true)
        --self._colorGo:SetActive(false)
        self._countGo:SetActive(false)
        self._getState = QuestStatus.QUEST_Taken
        self._btnImg.sprite = self._atlas:GetSprite("task_chengjiu_frame21")
        self._pointValueTex:SetText(StringTable.Get("str_quest_base_got"))
        self._pointValueTex.color = Color(77 / 255, 77 / 255, 77 / 255)
    end
end

function UIQuestAchievementPointAwardsItem:AttachEvents()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end
function UIQuestAchievementPointAwardsItem:RemoveEvents()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end

function UIQuestAchievementPointAwardsItem:OnUIPetObtainCloseInQuest(type, idx)
    if type == (QuestType.QT_Achieve + 100) and idx == self._rewardid then
        self:ShowDialog(
            "UIGetItemController",
            self._tempMsgRewards,
            function()
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.OnUIGetItemCloseInQuest,
                    QuestType.QT_Achieve + 100,
                    self._rewardid
                )
            end
        )
    end
end

function UIQuestAchievementPointAwardsItem:_OnGet(TT)
    local res, msg = self._questModule:TakeAchReward(TT, self._rewardid)
    self:UnLock("UIQuestGet")
    if (self.uiOwner == nil) then
        return
    end
    if res:GetSucc() then
        --刷新红点
        --GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckQuestRedPoint, QuestType.QT_Achieve)
        local tempPets = {}
        local pets = msg.rewards
        self._tempMsgRewards = msg.rewards

        if #pets > 0 then
            for i = 1, #pets do
                local ispet = GameGlobal.GetModule(PetModule):IsPetID(pets[i].assetid)
                if ispet then
                    table.insert(tempPets, pets[i])
                end
            end
        end
        if #tempPets > 0 then
            self:ShowDialog(
                "UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIPetObtainCloseInQuest,
                        QuestType.QT_Achieve + 100,
                        self._rewardid
                    )
                end
            )
        else
            self:ShowDialog(
                "UIGetItemController",
                msg.rewards,
                function()
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.OnUIGetItemCloseInQuest,
                        QuestType.QT_Achieve + 100,
                        self._rewardid
                    )
                end
            )
        end
    else
        Log.fatal("###questModule:TakeAchReward - res:", res:GetResult(), " -id --> ", self._rewardid)
    end
end
