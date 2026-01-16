---@class UIAircraftDecorateController : UIController
_class("UIAircraftDecorateController", UIController)
UIAircraftDecorateController = UIAircraftDecorateController

-- function UIAircraftDecorateController:LoadDataOnEnter(TT, res, uiParams)
--     ---@type AircraftModule
--     local aircraftModule = GameGlobal.GameLogic():GetModule(AircraftModule)
--     aircraftModule:ReqFurnitureInfo(TT)
--     res:SetSucc(true)
-- end

function UIAircraftDecorateController:OnShow(uiParams)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIAircraftDecorate)

    --打开时当前的深度，运行过程中可能会改变
    self._uiDepth = self:GetDepth()
    GameGlobal.UIStateManager():SetDepthRaycast(self._uiDepth, false)

    --当前房间信息
    ---@type AircraftDecorateManager
    self._decorateMng = uiParams[1]

    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GameLogic():GetModule(AircraftModule)

    ---@type ItemModule
    self._itemModule = GameGlobal.GameLogic():GetModule(ItemModule)

    ---@type AircraftMain
    self._airMain = self._aircraftModule:GetClientMain()

    -------
    self._showDescItemID = nil
    self._tweenTime = 0.2 --动画时间
    self._tabItemRectTransform = {}
    self._tabOpenState = {} --标签打开的状态
    self._tablChild = 0 --当前打开的子标签
    -- self._openTab = 1 --开始自动点击的按钮
    self._openTabChild = 201

    --第一次初始化详细信息
    self._isFirstDetail = true
    self._isDetaiOpen = false

    self._colorBlue = Color(0, 220 / 255, 1, 1)
    self._colorGreen = Color(157 / 255, 238 / 255, 28 / 255, 1)
    self._colorRed = Color(238 / 255, 52 / 255, 28 / 255, 1)

    --装扮模式

    --left
    local commonTopRoot = self:GetUIComponent("UISelectObjectPath", "TopButton")
    ---@type UICommonTopButton
    local backBtns = commonTopRoot:SpawnObject("UICommonTopButton")
    backBtns:SetData(
        function()
            self._decorateMng:Back()
        end,
        nil,
        nil,
        true
    )
    self._tabContent = self:GetUIComponent("UISelectObjectPath", "TabContent")
    self._rootLeft = self:GetGameObject("Left")

    --top
    self._rootTop = self:GetGameObject("Top")
    self._textRoomTitle = self:GetUIComponent("UILocalizationText", "TextRoomTitle")

    --bottom
    self._rootBottom = self:GetGameObject("Bottom")
    ---@type UIDynamicScrollView
    self._detailScrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollViewDynamic")

    --right
    self._rootRight = self:GetGameObject("Right")

    --topRight
    self._textAtmosphere = self:GetUIComponent("UILocalizationText", "TextAtmosphere")

    --rotate
    self._rotateMask = self:GetGameObject("RotateMask")
    ---@type UIRotater
    self._rotater = self:GetUIComponent("UIRotater", "Rotater")
    self._rotater.onAngleChanged:AddListener(
        function(angle)
            self._decorateMng:OnRotate(angle)
        end
    )
    self._rotaterRect = self:GetUIComponent("RectTransform", "Rotater")
    self:AttachEvent(GameEventType.UIAircraftShowRotater, self._OnShowRotater)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnUIDepthChanged)

    --center
    self._descWindow = self:GetGameObject("DescWindow")
    self._descWindowAnim = self:GetUIComponent("Animation", "DescWindow")
    self._descCanvasGroup = self:GetUIComponent("CanvasGroup", "DescWindow")
    self._btnDescFind = self:GetGameObject("BtnFind")
    self._btnDescPut = self:GetGameObject("BtnPut")
    self._textDescName = self:GetUIComponent("UILocalizationText", "TextDescName")
    self._textDescCount = self:GetUIComponent("UILocalizationText", "TextDescCount")
    self._textDescAtmosphere = self:GetUIComponent("UILocalizationText", "TextDescAtmosphere")
    self._textDesc = self:GetUIComponent("UILocalizationText", "TextDesc")
    self._textDescRoot = self:GetUIComponent("RectTransform", "TextDescRoot")
    self._rawImageDesc = self:GetUIComponent("RawImageLoader", "RawImageDesc")

    self:AttachEvent(GameEventType.UIAircraftDecorateSwitchModel, self._OnSwitchDecorateModel)
    self:AttachEvent(GameEventType.UIAircraftDecorateRefreshAtmosphere, self._OnRefreshAtmosphere)
    self:AttachEvent(GameEventType.UIAircraftDecorateRefreshRoomTitle, self._OnRefreshRoomTitle)

    ---@type FurnitureSearchResult
    self._searchResult = FurnitureSearchResult:New()

    ---@type table<number, GameObject> 家具模板id/item map
    self._furnitureDic = {}

    --refresh
    self:_OnValue()

    self._decorateMng:OnDecorateUIShow(self:GetGameObject("furnitureBtns"))
end

function UIAircraftDecorateController:OnUIDepthChanged()
    local depth = self:GetDepth()
    if self._uiDepth ~= depth then
        AirLog("装修UI深度变化：", depth)
        GameGlobal.UIStateManager():SetDepthRaycast(self._uiDepth, true)
        self._uiDepth = depth
        GameGlobal.UIStateManager():SetDepthRaycast(self._uiDepth, false)
    end
end

function UIAircraftDecorateController:OnHide()
    --自动解除绑定
    -- self:DetachEvent(GameEventType.UIAircraftDecorateSwitchModel, self._OnSwitchDecorateModel)
    -- self:DetachEvent(GameEventType.UIAircraftDecorateRefreshAtmosphere, self._OnRefreshAtmosphere)
    -- self:DetachEvent(GameEventType.UIAircraftDecorateRefreshRoomTitle, self._OnRefreshRoomTitle)
    --全部星灵消失清屏
    -- self:_EndDecorateShowAllPet()
    self._decorateMng:OnDecorateUIClose()
    self._furnitureDic = nil
    GameGlobal.UIStateManager():SetDepthRaycast(self._uiDepth, true)
end

function UIAircraftDecorateController:_OnValue()
    self:_InitFurnitureTabs()

    --刷新标签
    for i = self._tabCount, 1, -1 do
        --强制刷新 计算sizeData
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._tabs[i]:ItemMoveRectTransform())
        local height = self._tabs[i]:OnGetMaskSizeDeltaHeight()
        self:_OnChangeLayout(i, height)
    end
    -- --点击默认的二级标签
    -- self:_OnSelectTabChild(self._openTabChild)

    --右上角氛围
    local atmosphereNum = self._aircraftModule:CalFurnitureAmbient(true)
    self:_OnRefreshAtmosphere(atmosphereNum)

    self:_OnSwitchDecorateModel(true, self._openTabChild)

    --刷新房间名字
    self:_OnRefreshRoomTitle()

    --全部星灵消失
    self:_BeginDecorateClearAllPet()
end

---刷新左侧标签
function UIAircraftDecorateController:_InitFurnitureTabs()
    local tempTab = {}
    --一级标签数组
    local cfg_aircraft_furniture_tab = Cfg.cfg_aircraft_furniture_tab1 {}
    for i = 1, #cfg_aircraft_furniture_tab do
        table.insert(tempTab, cfg_aircraft_furniture_tab[i])
    end

    self._tabCount = table.count(tempTab)
    self._tabContent:SpawnObjects("UIAircraftDecorateTabItem", self._tabCount)
    ---@type UIAircraftDecorateTabItem[]
    self._tabs = self._tabContent:GetAllSpawnList()
    for i = 1, self._tabCount do
        local itemData = tempTab[i]
        self._tabs[i]:SetData(
            i,
            itemData,
            function(enum)
                self:_OnSelectTabChild(enum)
            end,
            function(idx, height, doTween)
                self:_OnChangeLayout(idx, height, doTween)
            end
        )
    end

    for i = 1, self._tabCount do
        local itemRT = self._tabs[i]:ItemRectTransform()
        table.insert(self._tabItemRectTransform, itemRT)
        table.insert(self._tabOpenState, false)
    end

    self._tabRectTransform = self:GetUIComponent("RectTransform", "TabContent")
    --强制刷新
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._tabRectTransform)
    local leftGrid = self:GetUIComponent("GridLayoutGroup", "TabContent")
    --设置默认的范围和坐标
    self._tabRectTransform.sizeDelta =
        Vector2(leftGrid.cellSize.x, leftGrid.cellSize.y * self._tabCount + leftGrid.spacing.y * (self._tabCount - 1))
    self._tabRectTransform.anchoredPosition = Vector2(0, 0)

    -- self._tabRectTransform.anchoredPosition = Vector2(0, self._tabRectTransform.sizeDelta.y)
    --自动布局关闭
    leftGrid.enabled = false
end

---刷新选中二级标签的内容
function UIAircraftDecorateController:_OnSelectTabChild(tabChild, force)
    if self._tablChild == tabChild and not force then
        return
    end
    self._tablChild = tabChild

    if self._isFirstDetail == true then
        self._isFirstDetail = false
        --初始化详细信息
        self:_InitDetailScrollView()
    else
        self:_RefrenshDetailScrollView()
    end

    --关闭详情界面
    self:BtnCloseDescOnClick()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIAircraftDecorateSmallTabClick, self._tablChild)
end

function UIAircraftDecorateController:_RefrenshDetailScrollView()
    -- --关闭详情界面
    -- self:BtnCloseDescOnClick()

    self._furnitureDataList = self:_GetFurnitureList()
    local furnitureDataListCount = table.count(self._furnitureDataList)
    self._detailScrollView:SetListItemCount(furnitureDataListCount)
    self._detailScrollView:MovePanelToItemIndex(0, 0)
end

---根据选中的二级标签，返回玩家身上的家居列表
function UIAircraftDecorateController:_GetFurnitureList()
    local tempList = {}

    local furnitureListAll = self._aircraftModule:GetFurnitureList()
    for k, value in pairs(furnitureListAll) do
        local cfg_item_furniture = Cfg.cfg_item_furniture[value:GetTemplateID()]
        if not cfg_item_furniture then
            Log.exception("玩家已有道具：", value.ID, "，在家居道具表cfg_item_furniture.xlsx里没找到")
            return
        end

        if cfg_item_furniture.Tab == self._tablChild then
            table.insert(tempList, value)
        end
    end

    --排序  1New    2有剩余    3排序
    if table.count(tempList) > 0 then
        table.sort(
            tempList,
            function(a, b)
                if a:IsNewFurniture() == b:IsNewFurniture() then
                    local remainsNumA = self._aircraftModule:GetRemainsFurnitureItemNumByItemID(a:GetTemplateID())
                    local remainsNumB = self._aircraftModule:GetRemainsFurnitureItemNumByItemID(b:GetTemplateID())

                    if (remainsNumA > 0 and remainsNumB > 0) or (remainsNumA == 0 and remainsNumB == 0) then
                        return a:GetTemplate().BagSortIndex < b:GetTemplate().BagSortIndex
                    end
                    return remainsNumB == 0
                end
                return a:IsNewFurniture()
            end
        )
    end
    return tempList
end
---------------------------------region-----------------------------------------
--全部星灵消失
function UIAircraftDecorateController:_BeginDecorateClearAllPet()
    -- self._airMain:ChangeMode(AircraftMode.Decorate)
end

--全部星灵出现
function UIAircraftDecorateController:_EndDecorateShowAllPet()
    --self._airMain:ResetPet()
    -- self._airMain:ChangeMode(AircraftMode.Normal)
end
---endregion

--初始化详细信息
function UIAircraftDecorateController:_InitDetailScrollView()
    self._furnitureDataList = self:_GetFurnitureList()
    local furnitureDataListCount = table.count(self._furnitureDataList)
    self._detailScrollView:InitListView(
        furnitureDataListCount,
        function(scrollView, index)
            return self:_OnInitDetailScrollView(scrollView, index)
        end
    )
end

function UIAircraftDecorateController:_OnInitDetailScrollView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIAircraftDecorateItem", 1)
    end
    local rowList = rowPool:GetAllSpawnList()
    local decorateItem = rowList[1]
    local itemIndex = index + 1
    self:_ShowDecorateItem(decorateItem, itemIndex)
    return item
end

---@param decorateItem UIAircraftDecorateItem
function UIAircraftDecorateController:_ShowDecorateItem(decorateItem, itemIndex)
    local data = self._furnitureDataList[itemIndex]
    self._furnitureDic[data:GetTemplateID()] = decorateItem
    decorateItem:GetGameObject():SetActive(true)
    if (data ~= nil) then
        decorateItem:SetData(
            itemIndex,
            data,
            function(item)
                self:_OnSelectItem(item)
            end
        )
    end
end

---@param item Item
function UIAircraftDecorateController:_OnSelectItem(item)
    --打开装备详情
    self:_OnRefreshDescWindow(item)

    --通知选中状态
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIAircraftDecorateSelectItem, item)

    --发送协议 去掉New
    self:StartTask(self._OnReadFurniture, self, item)
end

---@param item Item
function UIAircraftDecorateController:_OnReadFurniture(TT, item)
    --检查数据是否有New  没有New返回 不发送
    if not item:IsNewFurniture() then
        return
    end

    self._aircraftModule:PushViewNewFurniture(item:GetTemplateID())
    item:SetOldFurniture()
end

---刷新装备详情界面
---@param item Item
function UIAircraftDecorateController:_OnRefreshDescWindow(item)
    local itemID = item:GetTemplateID()
    if self._showDescItemID == itemID then
        return
    end
    self._showDescItemID = itemID

    -- self._descWindow:SetActive(true)
    self._descWindowAnim:Play("uieff_AircraftDecorate_DescWindow")
    self._descCanvasGroup.blocksRaycasts = true

    local cfg_item_furniture = Cfg.cfg_item_furniture[itemID]
    local cfg_item = Cfg.cfg_item[itemID]
    --拥有数量
    local itemCount = self._itemModule:GetItemCount(itemID)
    --摆放数量，不包含未保存的家具
    local useCount = self._aircraftModule:GetFurnitureItemNumInBagByItemID(itemID)
    --剩余数量
    local remainsNum = self._aircraftModule:GetRemainsFurnitureItemNumByItemID(itemID)

    self._textDescName:SetText(StringTable.Get(cfg_item.Name))
    self._textDesc:SetText(StringTable.Get(cfg_item.RpIntro))
    self._textDescRoot.anchoredPosition = Vector2(0, 0)

    self._rawImageDesc:LoadImage(cfg_item.Icon)
    local atmosphere = cfg_item_furniture.Atmosphere
    local lfAv, lfMv = self._aircraftModule:CalCentralPetWorkSkill()
    local newAtmosphere = atmosphere + math.floor(atmosphere * lfMv) + math.floor(lfAv)
    self._textDescAtmosphere:SetText(newAtmosphere)

    local remainsNumStr = "<color=#ffd800>" .. remainsNum .. "</color>"
    local itemCountStr = "<color=#a0a0a0>" .. itemCount .. "</color>"
    self._textDescCount.text = remainsNumStr .. "/" .. itemCountStr

    --根据情况显示寻找按钮
    self._btnDescFind:SetActive(useCount > 0)
    self._btnDescPut:SetActive(remainsNum > 0)
end

function UIAircraftDecorateController:_OnChangeLayout(tabIndex, height, doTween)
    --如果是点击标签 且 正在动画中
    if doTween and self._isDetaiOpen then
        return
    end

    --判断本次打开还是关闭
    local isOpenTab = self._tabOpenState[tabIndex] == false
    --
    self._tabOpenState[tabIndex] = isOpenTab
    self._isDetaiOpen = true

    local changeSizeDelta = Vector2(0, 0)
    if isOpenTab then
        changeSizeDelta = Vector2(0, height)
        self._tabs[tabIndex]:OpenMovePos(doTween)
    else
        changeSizeDelta = Vector2(0, -height)
        self._tabs[tabIndex]:CloseMovePos(doTween)
    end

    for i = 1, self._tabCount do
        local changePosition = Vector2(0, 0)
        if isOpenTab then
            --打开  自己和上面的不动  下面的减少
            if i >= tabIndex then
                changePosition = Vector2(0, 0)
            else
                changePosition = Vector2(0, -height)
            end
        else
            --关闭  自己和下面的增加  上面的不动
            if i >= tabIndex then
                changePosition = Vector2(0, 0)
            else
                changePosition = Vector2(0, height)
            end
        end

        local targetPos = self._tabItemRectTransform[i].anchoredPosition + changePosition
        --直接设置坐标
        if not doTween then
            self._tabItemRectTransform[i].anchoredPosition = targetPos
            self._isDetaiOpen = false
        else
            ---@type DG.Tweening.Tween
            local tweener = self._tabItemRectTransform[i]:DOAnchorPos(targetPos, self._tweenTime)
        end
    end

    local tabRootTargetPos = Vector2(0, 0)
    if not doTween then
        --只有非dotween  才需要重新计算背景
        self._tabRectTransform.sizeDelta = self._tabRectTransform.sizeDelta + changeSizeDelta
        --修改背景坐标左下角对齐
        tabRootTargetPos = Vector2(0, 0)
        -- tabRootTargetPos = Vector2(0, self._tabRectTransform.sizeDelta.y)
        self._tabRectTransform.anchoredPosition = tabRootTargetPos
    else
        --[[

            self._tabRectTransform:DOAnchorPos(tabRootTargetPos, self._tweenTime):OnComplete(
                function()
                    self._isDetaiOpen = false
                end
                )
                ]]
        tabRootTargetPos = self._tabRectTransform.anchoredPosition + changeSizeDelta

        self._isDetaiOpen = false
    end

    --改变其他按钮的选中状态
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIAircraftDecorateBigTabClick, tabIndex, isOpenTab)
end

---关闭详情界面
function UIAircraftDecorateController:BtnCloseDescOnClick()
    -- self._descWindow:SetActive(false)
    if self._descCanvasGroup.alpha == 1 then
        self._descWindowAnim:Play("uieff_AircraftDecorate_DescWindow_Fade")
    end
    self._descCanvasGroup.blocksRaycasts = false
    self._showDescItemID = nil
end
---详情界面查找
function UIAircraftDecorateController:BtnFindOnClick()
    local findItemID = self._showDescItemID

    self._decorateMng:TryPopTip(
        function()
            self:_searchFur(findItemID)
            self:BtnCloseDescOnClick()
        end
    )
end

function UIAircraftDecorateController:_searchFur(id)
    local target = self._searchResult:Search(id)
    self._decorateMng:FocusFurniture(target)
end

---详情界面摆放
function UIAircraftDecorateController:BtnPutOnClick()
    --判断是否可以摆放
    if self._decorateMng:TryAddFurniture(self._showDescItemID) then
        -- self:_OnSwitchDecorateModel(false)
        self:BtnCloseDescOnClick()
    else
        ToastManager.ShowToast(StringTable.Get("str_aircraft_no_space"))
    end
end

---切换装扮模式，关闭左侧和下侧UI
function UIAircraftDecorateController:_OnSwitchDecorateModel(show, openTabChild)
    self._rootTop:SetActive(show)
    self._rootBottom:SetActive(show)
    self._rootLeft:SetActive(show)
    self._rootRight:SetActive(show)

    if show then
        local tabChild = openTabChild
        if not tabChild then
            tabChild = self._tablChild
        end

        --点击默认的二级标签
        self:_OnSelectTabChild(tabChild, true)
    end
end

---刷新右上角氛围
function UIAircraftDecorateController:_OnRefreshAtmosphere(atmosphereNum)
    local realAmbient = self._aircraftModule:CalFurnitureAmbient(true)

    if atmosphereNum < realAmbient then
        self._textAtmosphere.color = self._colorRed
    elseif atmosphereNum > realAmbient then
        self._textAtmosphere.color = self._colorGreen
    else
        self._textAtmosphere.color = self._colorBlue
    end

    local CurCentralAmbientLimit = self._aircraftModule:GetCurCentralAmbientLimit()
    if atmosphereNum > CurCentralAmbientLimit then
        atmosphereNum = CurCentralAmbientLimit
    end
    self._textAtmosphere:SetText(atmosphereNum)
end

function UIAircraftDecorateController:_OnShowRotater(show, angle, offset)
    if show then
        self._rotater:SetAngle(angle)
        self._rotaterRect.anchoredPosition = offset
    end
    self._rotateMask:SetActive(show)
end
---氛围详情
function UIAircraftDecorateController:BtnAtmosphereOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIAmbientPanel")
end
---撤销
function UIAircraftDecorateController:BtnRepealOnClick()
    self._decorateMng:Revert()
end
---清除
function UIAircraftDecorateController:BtnClearOnClick()
    self._decorateMng:RemoveAll()
end
---保存
function UIAircraftDecorateController:BtnSaveOnClick()
    self._decorateMng:Save()
end
---切换房间
function UIAircraftDecorateController:BtnSwitchRoomLeftOnClick()
    self._decorateMng:SwitchArea(-1)
end

---切换房间
function UIAircraftDecorateController:BtnSwitchRoomRightOnClick()
    self._decorateMng:SwitchArea(1)
end

---刷新房间名字
function UIAircraftDecorateController:_OnRefreshRoomTitle()
    local curArea = self._decorateMng:CurrentArea()
    local cfg_aircraft_area = Cfg.cfg_aircraft_area[curArea]
    self._textRoomTitle:SetText(StringTable.Get(cfg_aircraft_area.Name))
end

function UIAircraftDecorateController:RotateMaskOnClick()
    self:_OnShowRotater(false)
    self._decorateMng:ShowFurTip()
end

function UIAircraftDecorateController:GetTabItem(itemIndex)
    local tabTwo = itemIndex % 100
    local tabOne = itemIndex - tabTwo

    if tabOne == 0 or tabTwo == 0 then
        return nil
    end

    ---@type UIAircraftDecorateTabItem
    local tabOneItem = self._tabs[tabOne]
    if not tabOneItem then
        return nil
    end

    local tabTwoItem = tabOneItem:GetChildItem(tabTwo)
    if tabTwoItem then
        return tabTwoItem.gameobject
    end

    return nil
end

---region 引导支持
function UIAircraftDecorateController:GetFurnitureItemByID(tplID)
    local index = -1
    for i = 1, #self._furnitureDataList do
        if self._furnitureDataList[i]:GetTemplateID() == tplID then
            index = i
            break
        end
    end
    self._detailScrollView:MovePanelToItemIndex(index - 1, 0)
    if self._furnitureDic[tplID] == nil then
        Log.exception("找不到引导需要的家具，请注册新账号:", tplID)
    end
    return self._furnitureDic[tplID]:GetBG()
end

function UIAircraftDecorateController:GetScrollRect()
    return self:GetUIComponent("ScrollRect", "ScrollViewDynamic")
end
---region end 引导支持
