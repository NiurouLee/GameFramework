--
---@class UISeasonRareCollectionController : UIController
_class("UISeasonRareCollectionController", UIController)
UISeasonRareCollectionController = UISeasonRareCollectionController

---@param res AsyncRequestRes
function UISeasonRareCollectionController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonRareCollectionController:OnShow(uiParams)
    self.closeCb = uiParams[1]
    self._itemCountPerRow = 1
    self.itemModule = self:GetModule(ItemModule)
    self:InitWidget()
    self:OnValue()
end

--获取ui组件
function UISeasonRareCollectionController:InitWidget()
    ---@type UICustomWidgetPool
    local topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    self._backBtns = topBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
            if self.closeCb then
                self.closeCb()
            end
        end,
        nil,
        nil,
        true
    )
    
    ---@type UILocalizationText
    self.txtCollectionCount = self:GetUIComponent("UILocalizationText", "txtCollectionCount")
    ---@type RawImageLoader
    self.imgHd = self:GetUIComponent("RawImageLoader", "imgHd")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtRequireDesc = self:GetUIComponent("UILocalizationText", "txtRequireDesc")
    ---@type UILocalizationText
    self.txtGetTime = self:GetUIComponent("UILocalizationText", "txtGetTime")
    ---@type UILocalizationText
    self.txtInfo = self:GetUIComponent("UILocalizationText", "txtInfo")
    
    self._contentRect = self:GetUIComponent("RectTransform", "Content")
    self._scrollRect = self:GetUIComponent("ScrollRect", "ScrollView")
    self._scrollRt = self:GetUIComponent("RectTransform", "ScrollView")
    ---@type UIDynamicScrollView
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")

    ---@type UnityEngine.GameObject
    self.emptyTipGo = self:GetGameObject("emptyTip")
end

function UISeasonRareCollectionController:OnValue()
    self._items = UISeasonExploreHelper.GetSeasonRareItems()
    local count  = #self._items
    self.emptyTipGo:SetActive(count == 0)

    if count > 0 then
        self.txtCollectionCount:SetText(count)
        self.selectIndex = 1
        self._collectionCount = count
        self._listShowItemCount = math.ceil(self._collectionCount / self._itemCountPerRow)

        self:_InitSrollView()
    end
end

function UISeasonRareCollectionController:_InitSrollView()
    self._scrollView:InitListView(
        self._listShowItemCount,
        function(scrollView, index)
            return self:InitCellList(scrollView, index)
        end
    )
    self._inited = true
end

function UISeasonRareCollectionController:InitCellList(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UISeasonRareCollectionCell", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local cellItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i

        if itemIndex > self._collectionCount then
            cellItem:GetGameObject():SetActive(false)
        else
            self:ShowCellItem(cellItem, itemIndex)
        end
    end
    return item
end

---@param cellItem UISeasonRareCollectionCell
function UISeasonRareCollectionController:ShowCellItem(cellItem, index)
    cellItem:GetGameObject():SetActive(true)
    local itemInfo = self._items[index]
    if (itemInfo ~= nil) then
        cellItem:SetData(
            itemInfo,
            index,
            self.selectIndex,
            function(cell)
                if cell.index == self.selectIndex then
                    return
                end
                self:OnClickCell(cell)
            end
        )
        if self.selectIndex == index then
            self:OnClickCell(cellItem)
        end
    end
end

function UISeasonRareCollectionController:OnClickCell(cell)
    if self.curCell then
        self.curCell:SetSelect(false)
    end
    self.curCell = cell
    self.selectIndex = cell.index
    self.curCell:SetSelect(true)

    local itemInfo = self._items[self.selectIndex]
    if not itemInfo then
        return
    end
    local itemCfg = itemInfo:GetTemplate()
    self.txtName:SetText(StringTable.Get(itemCfg.Name))
    self.txtInfo:SetText(StringTable.Get(itemCfg.Intro))
    local cfg = Cfg.cfg_item_season_collection[itemCfg.ID]
    if cfg then
        self.txtRequireDesc:SetText(cfg.RequireDesc)
        self.imgHd:LoadImage(cfg.HdImage)
    end
    local strGainTime = StringTable.Get("str_season_require_time", TimeToDate(itemInfo:GetGainTime()))
    self.txtGetTime:SetText(strGainTime)
end