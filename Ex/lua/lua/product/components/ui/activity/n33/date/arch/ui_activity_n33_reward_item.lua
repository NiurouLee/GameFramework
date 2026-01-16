--
---@class UIActivityN33RewardItem : UICustomWidget
_class("UIActivityN33RewardItem", UICustomWidget)
UIActivityN33RewardItem = UIActivityN33RewardItem
--初始化
function UIActivityN33RewardItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIActivityN33RewardItem:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.itemNode = self:GetGameObject("ItemNode")
    ---@type UnityEngine.GameObject
    self.petNode = self:GetGameObject("PetNode")
    ---@type UnityEngine.GameObject
    self.petDontClickMark = self:GetGameObject("PetDontClickMark")
    ---@type UILocalizationText
    self.itemNumText = self:GetUIComponent("UILocalizationText", "ItemNumText")
    ---@type UnityEngine.UI.Image
    self.dontClickMark = self:GetUIComponent("Image", "DontClickMark")
    self.petImg = self:GetUIComponent("RawImageLoader","petImg")
    ---@type UnityEngine.GameObject
    self.petImgGo = self:GetGameObject("petImg")
    self.itemIconLoader = self:GetUIComponent("RawImageLoader", "icon")
    self.canClickShowTips = true
    --generated end--
end
--设置数据
---@param rewardConf table
---@param isReceived boolean
function UIActivityN33RewardItem:SetRewardData_Item(rewardConf, isReceived, activityConst)
    self.activityConst = activityConst
    self.itemNode:SetActive(true)
    self.petNode:SetActive(false)
    if not rewardConf then
        return
    end
    local assetid = rewardConf[1]
    if not assetid then
        assetid = rewardConf.assetid
    end
    local count = rewardConf[2]
    if not count then
        count = rewardConf.count
    end
    local templateData = Cfg.cfg_item[assetid]
    if not templateData then
        Log.fatal("###cfg_item is nil ! id --> ", assetid)
        return
    end
    self.itemNumText:SetText("X" .. count)
    self._assetID = assetid
    self._uiItemAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    local icon = templateData.Icon
    local quality = templateData.Color
    local text1 = count
    local itemId = templateData.ID
    self.itemIconLoader:LoadImage(icon)
    self.dontClickMark.gameObject:SetActive(isReceived)
    self.canClickShowTips = not isReceived
end

function UIActivityN33RewardItem:SetRewardData_PetStory(petStoryID, isReceived, activityConst)
    self.activityConst = activityConst
    self.itemNode:SetActive(false)
    self.petNode:SetActive(true)
    self.petDontClickMark:SetActive(isReceived)
    local cfg = Cfg.cfg_component_simulation_operation_story[petStoryID]
    self.petImg:LoadImage(cfg.BonuslIcon)
end


function UIActivityN33RewardItem:ClickItemBtnOnClick(go)
    if self.activityConst:CheckSimulationOperationIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        self:SwitchState(UIStateType.UIActivityN33MainController)
        return
    end
    if not self._assetID then
        return
    end
    if not self.canClickShowTips then
        return
    end
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.AircraftInteractiveEventRewardShowItemTips,
        self._assetID,
        self:GetGameObject().transform.position
    )
end