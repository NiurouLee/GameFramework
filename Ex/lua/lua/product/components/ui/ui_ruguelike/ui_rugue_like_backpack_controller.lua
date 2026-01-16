---@class UIRugueLikeBackpackController:UIController
_class("UIRugueLikeBackpackController", UIController)
UIRugueLikeBackpackController = UIRugueLikeBackpackController

function UIRugueLikeBackpackController:OnShow(uiParam)
    self._cfg = Cfg.cfg_item {}
    if self._cfg == nil then
        Log.fatal("[error] maze --> _cfg == nil !")
    end

    self._itemCountPerRow = 5
    self._currFilterColor = 0

    self._innerGame = uiParam[1]

    self._isFromMiniMaze = uiParam[2]
    if self._isFromMiniMaze then
        self._itemInfo = self:SortItems(BattleStatHelper.GetAllMiniMazeRelic())
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIMazeBag)
        ---@type MazeModule
        self._module = GameGlobal.GetModule(MazeModule)
        if self._module == nil then
            Log.fatal("[error] maze --> module == nil !")
        end
        local mazeInfo = self._module:GetMazeInfo()

        self._itemInfo = self:SortItems(mazeInfo.relics)
    end

    self._listShowRowmItemCount = table.count(self._itemInfo)

    self:GetComponents()

    self:FlushFilters()

    self:_InitSrollView()
end

--物品排序，品级，id--1 2 3 11 6 34 21
function UIRugueLikeBackpackController:SortItems(items)
    table.sort(
        items,
        function(a, b)
            local ta = self._cfg[a]
            local tb = self._cfg[b]

            if ta.Color == tb.Color then
                return ta.ID < tb.ID
            end
            return ta.Color > tb.Color
        end
    )
    return items
end

function UIRugueLikeBackpackController:GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")

    local helpFun = function() self:ShowDialog("UIHelpController", "Maze") end
    if self._isFromMiniMaze then
        helpFun = nil
    end

    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        helpFun,
        nil,
        self._innerGame
    )

    ---@type UIDynamicScrollView
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")

    self._bgColor3 = self:GetGameObject("bgColor3")
    self._bgColor4 = self:GetGameObject("bgColor4")
    self._bgColor5 = self:GetGameObject("bgColor5")
    self._bgColorAll = self:GetGameObject("bgColorAll")

    self._colorTex3 = self:GetUIComponent("UILocalizationText", "colorTex3")
    self._colorTex4 = self:GetUIComponent("UILocalizationText", "colorTex4")
    self._colorTex5 = self:GetUIComponent("UILocalizationText", "colorTex5")
    self._colorTexAll = self:GetUIComponent("UILocalizationText", "colorTexAll")
end

function UIRugueLikeBackpackController:_InitSrollView()
    self._scrollView:InitListView(
        self:GetRowCount(),
        --self._listShowRowmItemCount/self._itemCountPerRow,
        function(scrollView, index)
            return self:InitSpritListInfo(scrollView, index)
        end
    )
end

function UIRugueLikeBackpackController:GetRowCount()
    local row = math.ceil(self._listShowRowmItemCount / self._itemCountPerRow)
    return row
end

function UIRugueLikeBackpackController:InitSpritListInfo(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIRugueLikeBackpackItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._listShowRowmItemCount then
            heartItem:GetGameObject():SetActive(false)
        else
            self:ShowHeartItem(heartItem, itemIndex)
        end
    end
    return item
end

function UIRugueLikeBackpackController:ShowHeartItem(item, index)
    local cfg = self._itemInfo[index]
    item:GetGameObject():SetActive(true)
    if cfg ~= nil then
        item:SetData(
            index,
            cfg,
            function(tIndex)
                self:ShowDialog("UIRelicInfoController", self._itemInfo[index])
            end,
            false
        )
    end
end

function UIRugueLikeBackpackController:RefrenshItems()
    if self._isFromMiniMaze then
        self._itemInfo = self:SortItems(BattleStatHelper.GetAllMiniMazeRelic())
    else
        local mazeInfo = self._module:GetMazeInfo()
        self._itemInfo = self:SortItems(mazeInfo.relics)
    end
    self:FilterItems()

    self._listShowRowmItemCount = table.count(self._itemInfo)
    self._scrollView:SetListItemCount(self:GetRowCount())
    self._scrollView:MovePanelToItemIndex(0, 0)
end

function UIRugueLikeBackpackController:FilterItems()
    if self._currFilterColor == 0 then
        return
    end
    local tab = {}
    for i = 1, #self._itemInfo do
        local itemid = self._itemInfo[i]
        local color = self._cfg[itemid].Color
        if color == self._currFilterColor then
            table.insert(tab, self._itemInfo[i])
        end
    end
    self._itemInfo = tab
end

function UIRugueLikeBackpackController:filter3OnClick()
    if self._currFilterColor ~= 3 then
        self._currFilterColor = 3
        self:FlushFilters()
        self:RefrenshItems()
    end
end

function UIRugueLikeBackpackController:filter4OnClick()
    if self._currFilterColor ~= 4 then
        self._currFilterColor = 4
        self:FlushFilters()
        self:RefrenshItems()
    end
end

function UIRugueLikeBackpackController:filter5OnClick()
    if self._currFilterColor ~= 5 then
        self._currFilterColor = 5
        self:FlushFilters()
        self:RefrenshItems()
    end
end

function UIRugueLikeBackpackController:filterAllOnClick()
    if self._currFilterColor ~= 0 then
        self._currFilterColor = 0
        self:FlushFilters()
        self:RefrenshItems()
    end
end

function UIRugueLikeBackpackController:FlushFilters()
    self._bgColor3:SetActive(false)
    self._bgColor4:SetActive(false)
    self._bgColor5:SetActive(false)
    self._bgColorAll:SetActive(false)

    local c = Color(1, 1, 1, 1)
    self._colorTex3.color = c
    self._colorTex4.color = c
    self._colorTex5.color = c
    self._colorTexAll.color = c

    local c_yellow = Color(252 / 255, 232 / 255, 2 / 255, 1)
    if self._currFilterColor == 0 then
        self._bgColorAll:SetActive(true)
        self._colorTexAll.color = c_yellow
    elseif self._currFilterColor == 3 then
        self._bgColor3:SetActive(true)
        self._colorTex3.color = c_yellow
    elseif self._currFilterColor == 4 then
        self._bgColor4:SetActive(true)
        self._colorTex4.color = c_yellow
    elseif self._currFilterColor == 5 then
        self._bgColor5:SetActive(true)
        self._colorTex5.color = c_yellow
    end
end

function UIRugueLikeBackpackController:GetBtn()
    return self.items and self.items[1]:GetGameObject()
end
