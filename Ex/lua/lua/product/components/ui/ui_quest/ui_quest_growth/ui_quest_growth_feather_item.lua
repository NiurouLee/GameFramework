---@class UIQuestGrowthFeatherItem:UICustomWidget
_class("UIQuestGrowthFeatherItem", UICustomWidget)
UIQuestGrowthFeatherItem = UIQuestGrowthFeatherItem

function UIQuestGrowthFeatherItem:OnShow(uiParams)
    self._questModule = self:GetModule(QuestModule)
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvents()
end

function UIQuestGrowthFeatherItem:SetData(tabIndex, index, posx, lastPos, iconID, iconCount, featherCount, currCount)
    self:_GetComponents()

    self._posX = posx
    self._lastPos = lastPos
    self._tabIndex = tabIndex
    self._index = index
    self._id = iconID
    self._iconCount = iconCount

    self._count = featherCount
    self._currCount = currCount
    ---@type QuestStatus
    self._state = QuestStatus.QUEST_Accepted

    self:_OnValue()
end

function UIQuestGrowthFeatherItem:_OnValue()
    self:_SetState(self._tabIndex)
    self:_GetState()
    self:_ShowInfo()
    self:_ShowState()
    self:_CalcWidthAndPos()
end

function UIQuestGrowthFeatherItem:_SetState(mode)
    self._stateObj = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            { "_dayIcon" },
            { "_goalIcon" }
        },
        self._stateObj
    )
    UIWidgetHelper.SetObjGroupShow(self._stateObj, mode)
end

function UIQuestGrowthFeatherItem:_GetState()
    local isGot = {
        self._questModule:CheckGrowthFeatherState(self._index),
        self._questModule:CheckStage2GrowthFeatherState(self._index)
    }

    if isGot[self._tabIndex] then
        self._state = QuestStatus.QUEST_Taken
    else
        if self._currCount >= self._count then
            self._state = QuestStatus.QUEST_Completed
        else
            self._state = QuestStatus.QUEST_Accepted
        end
    end
end

function UIQuestGrowthFeatherItem:_ShowState()
    self._di.gameObject:SetActive(self._state == QuestStatus.QUEST_Completed)
    self._eff:SetActive(self._state == QuestStatus.QUEST_Completed)
    if self._state <= QuestStatus.QUEST_Accepted then
    elseif self._state == QuestStatus.QUEST_Completed then
        self._getStateTex:SetText(StringTable.Get("str_quest_base_get"))
        self._di.sprite = self._atlas:GetSprite("task_chengzhang_frame21")
        self._di:SetNativeSize()
        self._getStateTex.color = Color(24 / 255, 24 / 255, 24 / 255)
    elseif self._state == QuestStatus.QUEST_Taken then
    end
    self._imgGot:SetActive(self._state == QuestStatus.QUEST_Taken)
end

function UIQuestGrowthFeatherItem:_ShowInfo()
    local cfg_item = Cfg.cfg_item[self._id]
    if not cfg_item then
        Log.fatal("###cfg_item is nil ! id --> ", self._id)
    end
    self._countTex:SetText(self._count)
    local icon = cfg_item.Icon
    local quality = cfg_item.Color
    local text1 = UIActivityHelper.GetRichText({ size = 42 }, self._iconCount)
    local itemId = self._id

    self.uiItem:SetData({ icon = icon, quality = quality, text1 = text1, itemId = self._id })
end

function UIQuestGrowthFeatherItem:_GetComponents()
    self._line = self:GetUIComponent("RectTransform", "line")
    self._texPos = self:GetUIComponent("RectTransform", "texPos")

    self._imgGot = self:GetGameObject("imgGot")
    self._countTex = self:GetUIComponent("UILocalizationText", "countTex")

    self._rect = self:GetUIComponent("RectTransform", "rect")
    ---@type UnityEngine.UI.Image
    self._di = self:GetUIComponent("Image", "di")
    ---@type UnityEngine.RectTransform
    self._diRect = self:GetUIComponent("RectTransform", "di")
    self._getStateTex = self:GetUIComponent("UILocalizationText", "getStateTex")

    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base, UIItemScale.Level3)
    self.uiItem:SetClickCallBack(
        function(go)
            self:bgOnClick(go)
        end
    )

    self._eff = self:GetGameObject("eff")
end

function UIQuestGrowthFeatherItem:_CalcWidthAndPos()
    self._rect.anchoredPosition = Vector2(self._posX, 0)

    local width = 0
    --奖励框
    local awardWidthHalf = 70
    local awardWidthPadding = 12
    local startOffset = 25
    if self._index > 1 then
        width = self._posX - self._lastPos - 2 * awardWidthHalf - 2 * awardWidthPadding
    else
        width = self._posX - awardWidthHalf - awardWidthPadding - startOffset
    end

    self._line.sizeDelta = Vector2(width, 2)

    local texPos = 0
    texPos = -width * 0.5
    self._texPos.anchoredPosition = Vector2(texPos, 0)

    if self._index == 1 then
        self._texPos.gameObject:SetActive(false)
    else
        self._texPos.gameObject:SetActive(true)
    end
end

function UIQuestGrowthFeatherItem:bgOnClick(go)
    if self._state <= QuestStatus.QUEST_Accepted then
        local pos = go.transform.position
        GameGlobal.EventDispatcher():Dispatch(GameEventType.QuestAwardItemClick, self._id, pos)
    elseif self._state == QuestStatus.QUEST_Completed then
        self:_GetAward()
    elseif self._state == QuestStatus.QUEST_Taken then
    end
end

function UIQuestGrowthFeatherItem:_GetAward()
    self:Lock(self:GetName())
    GameGlobal.TaskManager():StartTask(self._OnGetAward, self)
end

function UIQuestGrowthFeatherItem:OnUIGetItemCloseInQuest(type)
    if type == (QuestType.QT_Growth + 1000) then
        self:_GetState()

        self:_ShowState()
    end
end

function UIQuestGrowthFeatherItem:OnUIPetObtainCloseInQuest(type)
    if type == (QuestType.QT_Growth + 1000 * self._index) then
        self:ShowDialog(
            "UIGetItemController",
            self._tempMsgRewards,
            function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, QuestType.QT_Growth + 1000)
            end
        )
    end
end

function UIQuestGrowthFeatherItem:AttachEvents()
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end

function UIQuestGrowthFeatherItem:RemoveEvents()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.OnUIPetObtainCloseInQuest, self.OnUIPetObtainCloseInQuest)
end

function UIQuestGrowthFeatherItem:_OnGetAward(TT)
    local res, msg = self._questModule:RequestGetGrowthFeatherAward(TT, self._index)
    self:UnLock(self:GetName())
    if (self.uiOwner == nil) then
        return
    end

    if res:GetSucc() then
        --刷新红点
        --GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckQuestRedPoint, QuestType.QT_Growth)
        local tempPets = {}
        local pets = msg.rewards
        self._tempMsgRewards = pets

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
                        QuestType.QT_Growth + 1000 * self._index
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
                        QuestType.QT_Growth + 1000
                    )
                end
            )
        end
    else
        local result = res:GetResult()
        Log.fatal("### RequestGetGrowthFeatherAward fail , result -> ", result)
    end
end

function UIQuestGrowthFeatherItem:OnHide()
    self:RemoveEvents()
end
