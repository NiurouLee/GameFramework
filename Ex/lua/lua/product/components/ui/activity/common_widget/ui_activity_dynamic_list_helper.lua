--[[
    Dynamic List 通用的脚本
    仅包含最基本功能，可实现一维和二维的动态列表
    其他功能可在外部直接对 dynamicList 操作

    uiView 父 UIController 或 UICustomWidget
    dynamicList 组件 UIDynamicScrollView
    className 动态生成 ListItem 的类名
    callback 对 ListItem 设置的回调
]]
---@class UIActivityDynamicListHelper:Object
_class("UIActivityDynamicListHelper", Object)
UIActivityDynamicListHelper = UIActivityDynamicListHelper

function UIActivityDynamicListHelper:Constructor(uiView, dynamicList, className, callback)
    self._uiView = uiView
    self._dynamicList = dynamicList
    self._className = className
    self._setListItemDataCallback = callback
end

function UIActivityDynamicListHelper:Refresh(itemCount, itemCountPerRow)
    self._dynamicListSize = itemCount
    self._itemCountPerRow = itemCountPerRow
    self._dynamicListRowSize = math.floor((self._dynamicListSize - 1) / self._itemCountPerRow + 1)

    if not self._isDynamicInited then
        self._isDynamicInited = true

        self._dynamicList:InitListView(
            self._dynamicListRowSize,
            function(scrollView, index)
                return self:_SpawnListItem(scrollView, index)
            end
        )
    else
        self:_RefreshList(self._dynamicListRowSize, self._dynamicList)
    end
end

function UIActivityDynamicListHelper:_RefreshList(count, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityDynamicListHelper:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end

    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self._uiView:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects(self._className, self._itemCountPerRow)
    end

    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._dynamicListSize then
            listItem:GetGameObject():SetActive(false)
        else
            listItem:GetGameObject():SetActive(true)

            if self._setListItemDataCallback then
                self._setListItemDataCallback(listItem, itemIndex)
            end
        end
    end
    return item
end

function UIActivityDynamicListHelper:GetVisibleItem()
    local tb_out = {}
    
    local showTabIds = self._dynamicList:GetVisibleItemIDsInScrollView()
    if showTabIds == nil then
        return tb_out
    end
    
    for index = 0, showTabIds.Count - 1 do
        local id = math.floor(showTabIds[index])
        local item = self._dynamicList:GetShownItemByItemIndex(id)
        local rowPool = self._uiView:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
        local rowList = rowPool:GetAllSpawnList()
        for i = 1, self._itemCountPerRow do
            local listItem = rowList[i]
            local itemIndex = index * self._itemCountPerRow + i
            table.insert(tb_out, {item = listItem, index = itemIndex})
        end
    end
    return tb_out
end