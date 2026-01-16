---@class UIQuestAchievementPointAwardsController:UIController
_class("UIQuestAchievementPointAwardsController", UIController)
UIQuestAchievementPointAwardsController = UIQuestAchievementPointAwardsController

function UIQuestAchievementPointAwardsController:OnShow(uiParams)
    self:_GetComponents()
    self._itemCountPerRow = 1
    ---@type QuestModule
    self._questModule = GameGlobal.GetModule(QuestModule)

    self._achievementPoint = self._questModule:GetAchPoint()

    self._cfg = Cfg.cfg_achieve_reward {}
    if self._cfg == nil then
        Log.fatal("###[quest] error --> cfg_achieve_reward is nil !")
        return
    end

    self._awardsCount = table.count(self._cfg)

    self._achievementPointUpper = self._cfg[self._awardsCount].AchPoint

    self:_OnValue()
end

function UIQuestAchievementPointAwardsController:OnHide()
end

function UIQuestAchievementPointAwardsController:_GetComponents()
    self._pointValueTex = self:GetUIComponent("UILocalizationText", "pointValueTex")

    self._pools = self:GetUIComponent("UIDynamicScrollView", "pools")

    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")
end

function UIQuestAchievementPointAwardsController:_OnValue()
    self._pointValueTex:SetText(
        "<size=42><color=#fdd100>" ..
            self._achievementPoint .. "</color></size><size=32>/" .. self._achievementPointUpper .. "</size>"
    )

    self:_InitScrollView()
end

function UIQuestAchievementPointAwardsController:_InitScrollView()
    self._pools:InitListView(
        self._awardsCount,
        function(scrollView, index)
            return self:_InitAwardsList(scrollView, index)
        end
    )
end
function UIQuestAchievementPointAwardsController:_InitAwardsList(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIQuestAchievementPointAwardsItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i

        self:_ShowAwardItem(heartItem, itemIndex)
    end
    return item
end
function UIQuestAchievementPointAwardsController:_ShowAwardItem(heartItem, index)
    if (heartItem ~= nil) then
        heartItem:GetGameObject():SetActive(true)
        heartItem:SetData(
            index,
            self._cfg[index].AchPoint,
            self._achievementPoint,
            self._cfg[index].Reward,
            function(idx)
                --暂时把领取放在item
                --self:_AwardItemClick(idx)
            end,
            function(matid, pos)
                self:_ItemClick(matid, pos)
            end
        )
    end
end
function UIQuestAchievementPointAwardsController:_AwardItemClick(idx)
    --暂时把领取放在item
end

function UIQuestAchievementPointAwardsController:_ItemClick(matid, pos)
    self._selectInfo:SetData(matid, pos)
end

function UIQuestAchievementPointAwardsController:bgOnClick()
    self:CloseDialog()
end
