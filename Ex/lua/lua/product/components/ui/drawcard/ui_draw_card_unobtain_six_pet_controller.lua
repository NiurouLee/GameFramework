--
---@class UIUnObtainSixPetController : UIController
_class("UIUnObtainSixPetController", UIController)
UIUnObtainSixPetController = UIUnObtainSixPetController


function UIUnObtainSixPetController:Constructor()
    self.isDynamicSvInited = nil --scrollview 是否初始化
    self._itemCountPerRow = 5 --scrollView 每行数量
    self._dynamicListSize = 0 --scrollview 行数
    self.petIdList = nil
end

--初始化
function UIUnObtainSixPetController:OnShow(uiParams)
    self:InitWidget()
    self.petIdList = uiParams[1]
    self:InitPetList()
end
--获取ui组件
function UIUnObtainSixPetController:InitWidget()
    ---@type UIDynamicScrollView
    self.dynamicSv = self:GetUIComponent("UIDynamicScrollView", "dynamicSv")
end

function UIUnObtainSixPetController:InitPetList()
    if not self.petIdList then
        return
    end

    local len = #self.petIdList

    if len > 0 then
        self._dynamicListSize = math.floor((len - 1) / self._itemCountPerRow + 1)
        if  not self.isDynamicSvInited then
            self.isDynamicSvInited = true
            self.dynamicSv:InitListView(
                self._dynamicListSize,
                function(scrollView, index)
                    return self:SpawnListItem(scrollView, index)
                end
            )
        else
            self:RefreshItemScroll(self._dynamicListSize, self.dynamicSv)
        end
    end
end

function UIUnObtainSixPetController:SpawnListItem(scrollView, rowIndex)
    if rowIndex < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIUnObtainSixPetItem", self._itemCountPerRow)
    end
    ---@type UIUnObtainSixPetItem[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local subItem = rowList[i]
        local itemIndex = rowIndex * self._itemCountPerRow + i

        if itemIndex > #self.petIdList then
            subItem:GetGameObject():SetActive(false)
        else
            subItem:GetGameObject():SetActive(true)
            self:RefreshPetItem(subItem, itemIndex)
        end
    end
    return item
end

function UIUnObtainSixPetController:RefreshItemScroll(count, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIUnObtainSixPetController:RefreshPetItem(item, index)
    if not self.petIdList then
        return
    end

    local petId = self.petIdList[index]
    item:SetData(petId)
end

--按钮点击
function UIUnObtainSixPetController:CloseBtnOnClick(go)
    self:CloseDialog()
end
