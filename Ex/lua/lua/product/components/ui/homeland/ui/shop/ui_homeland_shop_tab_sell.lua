---@class UIHomelandShopTabSell:UICustomWidget
_class("UIHomelandShopTabSell", UICustomWidget)
UIHomelandShopTabSell = UIHomelandShopTabSell

function UIHomelandShopTabSell:OnShow(uiParams)
    self._isOpen = true
end

function UIHomelandShopTabSell:OnHide()
    self._isOpen = false
end

function UIHomelandShopTabSell:SetData(shop_info)
    self._itemIndex = 1
    self:_SetItemSelect(self._itemIndex)
end

function UIHomelandShopTabSell:_SetItemSelect(index)
    self._itemIndex = index

    self._infos = self:_GetDynamicListData()
    self:_SetDynamicList()

    self:_SetPanel()
end

--region DynamicList
function UIHomelandShopTabSell:_GetDynamicListData()
    local tb = {}
    local cfgs = Cfg.cfg_homeland_univalence {}
    for k, v in pairs(cfgs) do
        if UIHomelandShopHelper.GetItemCount_ForSale(k) > 0 then
            table.insert(tb, v)
        end
    end
    return tb
end

function UIHomelandShopTabSell:_SetDynamicList()
    if not self._dynamicListHelper then
        ---@type UIActivityDynamicListHelper
        self._dynamicListHelper = UIActivityDynamicListHelper:New(
            self,
            self:GetUIComponent("UIDynamicScrollView", "_dynamicList"),
            "UIHomelandShopTabSellItem",
            function(listItem, itemIndex)
                local itemId = self._infos[itemIndex].ID
                ---@type ItemModule
                local itemModule = GameGlobal.GetModule(ItemModule)
                local count = UIHomelandShopHelper.GetItemCount_ForSale(itemId)

                ---@type RoleAsset
                local roleAsset = RoleAsset:New()
                roleAsset.assetid = itemId
                roleAsset.count = count

                listItem:SetData(roleAsset,
                    function()
                        self:_SetItemSelect(itemIndex)
                    end,
                    true
                )
                listItem:SetSelected(self._itemIndex == itemIndex)
            end
        )
    end

    local itemCount = #self._infos
    local itemCountPerRow = 4
    self._dynamicListHelper:Refresh(itemCount, itemCountPerRow)
end

--endregion

function UIHomelandShopTabSell:_SetPanel()
    ---@type UIHomelandShopTabSellDetailPanel
    local obj = UIWidgetHelper.SpawnObject(self, "_detailPanel", "UIHomelandShopTabSellDetailPanel")
    local itemId = self:_GetMainItemId()
    obj:SetData(itemId,
        function(itemId, count) -- UIHomelandShopTabSellDetailPanel -> UIHomelandShopSellConfirm 点击回调
            local id_num = { [itemId] = count }

            local reward = UIHomelandShopHelper.CalcItemSellPrice(itemId, count)

            -- 检测稀有物品
            UIHomelandShopHelper.CheckSellRare(itemId,
                function()
                    -- 检测家园币溢出
                    UIHomelandShopHelper.CheckCoinOverflow(reward.count,
                        function()
                            UIHomelandShopHelper.Start_HomelandSellReq(id_num, { reward })
                        end
                    )
                end
            )
        end
    )
end

function UIHomelandShopTabSell:_GetMainItemId()
    self._itemIndex = Mathf.Clamp(self._itemIndex, 0, #self._infos)
    return self._infos[self._itemIndex] and self._infos[self._itemIndex].ID
end
