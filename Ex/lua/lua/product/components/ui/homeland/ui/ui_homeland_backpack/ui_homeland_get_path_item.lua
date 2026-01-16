---@class UIHomelandGetPathItem : UICustomWidget
_class("UIHomelandGetPathItem", UICustomWidget)
UIHomelandGetPathItem = UIHomelandGetPathItem

---OnShow
function UIHomelandGetPathItem:OnShow(uiParams)
    ---@type UILocalizationText
    self.txtGetway = self:GetUIComponent("UILocalizationText", "txtGetway")
    ---@type UnityEngine.RectTransform
    self.txtGetwayRect = self:GetUIComponent("RectTransform", "txtGetway")
    self.btnJump = self:GetGameObject("btnJump")
    self.btnLock = self:GetGameObject("btnLock")
    self.btnUse = self:GetGameObject("btnUse")
end

---@param itemDataInfo UIHomelandGetPathItemData 物品信息
---@param tplId number 道具id
---Flush
function UIHomelandGetPathItem:Flush(homelandGetPathItemData, tplId)
    self.tplId = tplId
    self.homelandGetPathItemData = homelandGetPathItemData
    self.btnJump:SetActive(false)
    self.btnLock:SetActive(false)
    self.btnUse:SetActive(false)
    if homelandGetPathItemData.way == GetWayItemType.Jump then
        if homelandGetPathItemData.enabled then
            self.btnJump:SetActive(true)
        else
            self.btnLock:SetActive(true)
        end
    elseif homelandGetPathItemData.way == GetWayItemType.Text then
    elseif homelandGetPathItemData.way == GetWayItemType.Use then
        self.btnUse:SetActive(true)
    end
    self.txtGetway:SetText(homelandGetPathItemData:GetDesc())
    if self.btnJump.activeSelf or self.btnLock.activeSelf or self.btnUse.activeSelf then
        self.txtGetwayRect.sizeDelta = Vector2(645, 120)
    else
        self.txtGetwayRect.sizeDelta = Vector2(837, 120)
    end
end

---跳转按钮
function UIHomelandGetPathItem:btnJumpOnClick(go)
    ---@type UIJumpModule
    local mQuest = self:GetModule(QuestModule).uiModule
    mQuest:GotoWithItemGetPath(
        self.homelandGetPathItemData.jumpId,
        self.tplId,
        FromUIType.NormalUI,
        "UIHomelandBackpack",
        UIStateType.UIMain
    )
end
---使用按钮
function UIHomelandGetPathItem:btnUseOnClick(go)
    --打开自选礼包
    local mItem = GameGlobal.GetModule(ItemModule)
    ---@type Item
    local item_data
    local item_datas = mItem:GetItemByTempId(self.homelandGetPathItemData.useItemId)
    if item_datas and table.count(item_datas) > 0 then
        for key, value in pairs(item_datas) do
            item_data = value
            break
        end
    end
    if item_data:GetCount() == 1 then
        self:ShowDialog("UIHomelandBackpackBox", item_data, 1)
    else
        self:ShowDialog(
            "UIHomelandSaleAndUseWithCount",
            item_data,
            EnumItemSaleAndUseState.Use,
            function(item_data, count)
                self:ShowDialog("UIHomelandBackpackBox", item_data, count)
            end
        )
    end
end
