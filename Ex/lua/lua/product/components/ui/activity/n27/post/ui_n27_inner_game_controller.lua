--
---@class UIN27PostInnerGameController : UIController
_class("UIN27PostInnerGameController", UIController)
UIN27PostInnerGameController = UIN27PostInnerGameController

function UIN27PostInnerGameController:LoadDataOnEnter(TT, res, uiParams)
    local campaignModule = self:GetModule(CampaignModule)

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_N27,
        ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON
    )
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end

    self._component = self._campaign:GetComponent(ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON)
    self._componentInfo = self._campaign:GetComponentInfo(ECampaignN27ComponentID.ECAMPAIGN_N27_POSTSTATON)
end

--初始化
function UIN27PostInnerGameController:OnShow(uiParams)
    --当前关卡id
    self._MissionID = uiParams[1] or 6
    --初始化游戏数据，组件
    self:InitGameConfig();
    self:InitWidget()
    self:AttachEvents();
    --初始化游戏主逻辑
    self:InitMainGrid()
    self:InitItemTabBtnGroup()
    self:InitOrderGroup()
    self:InitTimeCounter()
    --开始游戏
    self:StartGame()
    UnityEngine.Input.multiTouchEnabled = true
end

function UIN27PostInnerGameController:InitGameConfig()
    --游戏格子宽度
    self._MainGridWidth = 5
    --游戏格子长度
    self._MainGridHeight = 5
    --游戏格子像素
    self._MainGridPixel = 625
    --定义所有游戏类型ID=99
    self._AllGameTypeID = 99
    --支持道具旋转角度
    self._RotationList = {0, 90, 180, 270}
    --倒计时图标列表
    self._TimeCountSprNameList = {"n27_yz_wf_first", "n27_yz_wf_second", "n27_yz_wf_third", "n27_yz_wf_fourth"}
    --开始倒计时总时长
    self._StartGameTime = 3
    -------游戏临时变量-----
    --当前运行市场
    self._RunTime = 0
    --游戏道具dic
    self._GameItemDic = {}
    --游戏道具类型
    self._GameItemTypeDic = {}
    --游戏道具实例map
    self._GameItemObjectMap = {}
    --变量缓存当前选择类型
    self._CurSelectItemTypeID = -1
    --当前拖拽的道具旋转索引
    self._CurRotateIdx = 1
    --当前拖拽的道具矩阵
    self._CurItemMatrix = nil
    --当前拖拽的道具ID
    self._CurDragItemID = nil
    --当前拖拽的道具唯一ID
    self._CurDragItemAtomicID = nil
    --当前展示订单索引
    self._CurShowOrderIdx = 1
    --是否拖拽道具
    self._IsDragItem = false    
    --当前鼠标悬停的网格块
    self._CurHoveredBlock = nil
    --全部游戏道具个数
    self._AllGameItemCount = 0
    --最大展示订单个数
    self._MaxOrderShowCount = 3
    --当前任务列表
    self._CurTaskList = {}
    --当前订单列表
    self._CurOrderList = {}
    --所有订单列表
    self._AllOrderList = {}
    --订单widget列表
    self._OrderWidgetList = {}
    --完成的订单列表
    self._FinishOrderList = {}
    --当前玩家选择的道具map(存在0的可能)
    self._CurItemMap = {}
    --当前玩家玩过的订单map
    self._CurOrderMap = {}
    --当前玩家玩过的订单RTmap
    self._CurOrderRTMap = {}
    --当前玩家玩过的订单序列
    self._CurOrderSeq = {}
    --道具UI实例map
    self._UIGameItemObjectMap = {}
    --是否是暂停状态
    self._IsPause = false
    --是否结束游戏
    self._EndGame = false
    --是否正在播放动效
    self._IsAnimated = false
    --单位格子像素
    self._BlockPixel = self._MainGridPixel / self._MainGridWidth
    --输入控制
    self._Input = GameGlobal.EngineInput()
    --鼠标是否接入
    self._MousePresent = GameGlobal.EngineInput().mousePresent
    --运行中的timer列表
    self._TimerList = {}
    --初始化关卡数据
    local missionCfg = Cfg.cfg_component_post_station_game_mission{ID = self._MissionID}
    if missionCfg then
        --当前关卡数据
        self._MissionCfg = missionCfg[1]
        --游戏总时长
        self._GameTime = self._MissionCfg.Time
        self._DayTextStr = self._MissionCfg.Title
        local taskIDList = self._MissionCfg.Target
        local orderIDList = self._MissionCfg.OrderList
        --任务列表
        for _, taskID in pairs(taskIDList) do
            local taskCfg = Cfg.cfg_component_post_station_game_mission_target{ID = taskID}
            if taskCfg then
                table.insert(self._CurTaskList, taskCfg[1])
            end
        end
        --订单列表
        for _, orderID in pairs(orderIDList) do
            local orderCfg = Cfg.cfg_component_post_station_game_mission_order{ID = orderID}
            if orderCfg then
                table.insert(self._AllOrderList, orderCfg[1])
            end
        end
    end
    --初始化道具数据
    --深拷贝一份道具数据，用于操作数量
    local itemCfg = table.cloneconf(Cfg.cfg_component_post_station_game_item())
    --local itemCfg = Cfg.cfg_component_post_station_game_item()
    for _, item in pairs(itemCfg) do
        local unLock = false
        for _, missionID in pairs(item.MissionList) do
            if missionID == self._MissionID then
                unLock = true
            end
        end
        if unLock then
            self._GameItemDic[item.ItemType] = self._GameItemDic[item.ItemType] or {}
            self._GameItemDic[item.ItemType][item.ID] = item
            local itemTypeCfg = Cfg.cfg_post_station_game_item_type{ItemType = item.ItemType}
            if itemTypeCfg then
                self._GameItemTypeDic[item.ItemType] = itemTypeCfg[1]
            end
            self._AllGameItemCount = self._AllGameItemCount + 1
        end
    end
    --初始化网格管理器
    self._UIN27PostPackageGridManager = UIN27PostPackageGridManager:New(self._MainGridWidth, self._MainGridHeight)
    --初始化任务管理器
    self._UIN27MissionTaskCondition = UIN27MissionTaskCondition:New()
end

--获取ui组件
function UIN27PostInnerGameController:InitWidget()
    self._atlas = self:GetAsset("PostInGame.spriteatlas", LoadType.SpriteAtlas)
    self._MainGridRawImage = self:GetUIComponent("RawImage", "MainGridRawImage")
    self._MainGridRawImageObj = self:GetGameObject("MainGridRawImage")
    self._ItemTabBtnGroup = self:GetUIComponent("UISelectObjectPath", "ItemTabBtnGroup")
    self._TaskObjList = {}
    self._OrderTabObjList = {}
    self._TimerImageList = {}
    for i = 1, 3 do
        table.insert(self._TaskObjList, self:GetGameObject("Task" .. i))
    end
    for i = 1, 3 do
        table.insert(self._OrderTabObjList, self:GetGameObject("OrderTabObj" .. i))
    end
    for i = 1, 4 do
        table.insert(self._TimerImageList, self:GetUIComponent("Image", "Timer" .. i))
    end
    self._OrderListGroup = self:GetUIComponent("UISelectObjectPath", "OrderList")
    self._ItemPanel = self:GetUIComponent("UISelectObjectPath", "ItemPanel")
    self._ItemPanelGo = self:GetGameObject("ItemPanel")
    self._StartPanelObj = self:GetGameObject("StartPanel")
    self._PausePanelObj = self:GetGameObject("PausePanel")
    self._DeletePanelObj = self:GetGameObject("DeletePanel")
    self._MainEmptyArea = self:GetGameObject("EmptyArea")
    self._StartTimeText = self:GetUIComponent("UILocalizationText", "StartTimeText")
    self._OrderTitleText = self:GetUIComponent("UILocalizationText", "OrderTitle")
    self._DayText = self:GetUIComponent("UILocalizationText", "DayText")
    self._PcImageRObj = self:GetGameObject("pcImageR")
    self._PcImageTObj = self:GetGameObject("pcImageT")
    self._GuideEffObj = self:GetGameObject("guideEff")
    self._Anim = self:GetUIComponent("Animation", "anim")
    self._AnimIn = self:GetUIComponent("Animation", "animIn")
    self._Transition = self:GetUIComponent("ATransitionComponent", "anim")
    self._HideGroup = self:GetUIComponent("CanvasGroup", "HideGroup")
    self._Shot = self:GetUIComponent("H3DUIBlurHelper", "HideGroup")

    self._box1Spine = self:GetUIComponent("SpineLoader", "spine2_1")
    self._box2Spine = self:GetUIComponent("SpineLoader", "spine2_2")
    self._petSpine = self:GetUIComponent("SpineLoader", "spine3")

    self._box1Trans = self:GetGameObject("spine2_1").transform
    self._MainGridRawImageTrans = self._MainGridRawImageObj.transform

    self._Camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
end

function UIN27PostInnerGameController:AttachEvents()
    self:AttachEvent(GameEventType.OnN27PostGameItemTypeChange, self.RefreshItemPanel)
    self:AttachEvent(GameEventType.OnN27PostGameItemPress, self.OnGameItemSelect)
    self:AttachEvent(GameEventType.OnN27PostGameItemRelease, self.OnGameItemRelease)
    self:AttachEvent(GameEventType.OnN27PostGameBlockHovered, self.OnGameBlockHovered)
    self:AttachEvent(GameEventType.OnN27PostGameBlockPress, self.OnGameBlockPress)
    self:AttachEvent(GameEventType.OnN27PostGameBlockRelease, self.OnGameBlockRelease)
    self:AttachEvent(GameEventType.ShowGuideStep, self.ShowGuideStep)
end

function UIN27PostInnerGameController:StartGame()
    self._StartPanelObj:SetActive(true)
    self._Transition:ChangeAnim("uieff_UIN27PostInnerGameController_StartPanel_in", 10)
    self._Transition:PlayEnterAnimation(true)
    local startShowTime = 0
    GameGlobal.Timer():AddEventTimes(1000,  self._StartGameTime, function()
        startShowTime = startShowTime + 1
        if startShowTime == 3 then
            self._MainGridGameCamera.depth = 11
            self._Transition:PlayLeaveAnimation(true)
            self:PlayGameInAnimation()
            --初始化默认刷新第一个订单
            self:RefreshOrderPanel(true)
            local te = GameGlobal.Timer():AddEvent(
                333,
                function()
                    self._StartPanelObj:SetActive(false)
                    if self._MissionID == 1 then
                        self:_CheckGuide()
                    end
                    if not GuideHelper.GuideInProgress() then
                        self._IsPause = false
                    end
                end
            )
            table.insert(self._TimerList, te)
        else
            self._StartTimeText.text = tostring(self._StartGameTime - startShowTime)
        end
    end)
    self._StartTimeText.text = self._StartGameTime .. ""
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1GameStart)
    self._DayText:SetText(StringTable.Get(self._DayTextStr))
    if EDITOR or IsPc() then
        self._PcImageRObj:SetActive(true)
        self._PcImageTObj:SetActive(true)
    end
end

function UIN27PostInnerGameController:PlayGameInAnimation()
    self._AnimIn:Play("uieff_UIN27PostInnerGameController_in")
    local itemWidgetList = self._ItemPanel:GetAllSpawnList()
    for idx, v in pairs(itemWidgetList) do
        local te = GameGlobal.Timer():AddEvent(
            30*idx,
            function()
                v:GetGameObject():SetActive(true)
            end
        )
        table.insert(self._TimerList, te)
        v:GetGameObject():SetActive(false)
    end
end

function UIN27PostInnerGameController:InitTimeCounter()
    self._RunTime = 0
    if self._countdownTimer then
        GameGlobal.Timer():CancelEvent(self._countdownTimer)
    end
    self._countdownTimer = GameGlobal.Timer():AddEventTimes(1000,  TimerTriggerCount.Infinite, function()
        if self._IsPause or self._EndGame then
            return
        end
        self._RunTime = self._RunTime + 1
        self:RefreshTimeCounter(self._GameTime - self._RunTime)
        if self._RunTime == self._GameTime then
            --超时
            self._EndGame = true
            self:ShowDialog("UIN27PostGameClosingController", 
            self._CurOrderMap, 
            self._CurOrderRTMap, 
            self._CurOrderSeq,
            self._CurTaskList,
            self._UIN27MissionTaskCondition,
            self._MissionID,
            self._componentInfo,
            false
        )
        end
    end)
    self:RefreshTimeCounter(self._GameTime - self._RunTime)
    --倒计时后开始
    self._IsPause = true
end

function UIN27PostInnerGameController:InitItemTabBtnGroup()
    self._ItemTabBtnGroup:SpawnObjects("UIN27SelectItemTypeItem", #self._GameItemTypeDic + 1)
    local spawnList = self._ItemTabBtnGroup:GetAllSpawnList()
    spawnList[1]:SetData(self._AllGameTypeID)
    local idx = 2
    for _, v in ipairs(self._GameItemTypeDic) do    
        spawnList[idx]:SetData(v.ItemType, v.TabIconUnSelect, v.TabIconSelect)
        idx = idx + 1
    end
    --实例化所有道具
    self._ItemPanel:SpawnObjects("UIN27SelectItem", self._AllGameItemCount)
    local itemWidgetList = self._ItemPanel:GetAllSpawnList()
    local idx = 1
    for _type, itemGroup in pairs(self._GameItemDic) do
        self._UIGameItemObjectMap[_type] = {}
        for _, v in pairs(itemGroup) do
            table.insert(self._UIGameItemObjectMap[_type], itemWidgetList[idx])
            idx = idx + 1
        end
    end
    --初始显示所有分类
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN27PostGameItemTypeChange, self._AllGameTypeID)
end

function UIN27PostInnerGameController:InitOrderGroup()
    --订单道具最大数量类型为5
    self._OrderListGroup:SpawnObjects("UIN27OrderItem", 5)
    self._OrderWidgetList = self._OrderListGroup:GetAllSpawnList()
    for _, v in pairs(self._OrderWidgetList) do
        v:InitWidget()
        if not self._firstOrderWidgetForGuide then
            self._firstOrderWidgetForGuide = v
        end
        v:GetGameObject():SetActive(false)
    end
    --装填订单
    for i = 1, self._MaxOrderShowCount do
        self._CurOrderList[i] = self._AllOrderList[1]
        table.remove(self._AllOrderList, 1)
    end
    --光灵头像按钮和事件绑定
    for i = 1, #self._OrderTabObjList do
        local showID = i
        local tabObj = self._OrderTabObjList[i]
        local selectGO = tabObj.transform:Find("SelectImage").gameObject
        tabObj.transform:Find("SelectImage/RawImage"):GetComponent("RawImageLoader"):LoadImage(self._CurOrderList[i].PetHeadSelectIcon)
        tabObj.transform:Find("NormalImage/RawImage"):GetComponent("RawImageLoader"):LoadImage(self._CurOrderList[i].PetHeadIcon)
        self:AddUICustomEventListener(
            UICustomUIEventListener.Get(tabObj),
            UIEvent.Click,
            function(go)
                self._OrderTabObjList[self._CurShowOrderIdx].transform:Find("SelectImage").gameObject:SetActive(false)
                selectGO:SetActive(true)
                self._CurShowOrderIdx = showID
                self:RefreshOrderPanel()
            end
        )
        selectGO:SetActive(showID == self._CurShowOrderIdx)
    end
    --初始化刷新任务
    self:RefreshTaskPanel()
end

--刷新任务栏
function UIN27PostInnerGameController:RefreshTaskPanel()
    local idx = 1
    for _, task in pairs(self._CurTaskList) do
        local taskObj = self._TaskObjList[idx]
        local textComp = taskObj.transform:Find("LocalizationText"):GetComponent("UILocalizationText")
        --这里有一套客户端任务检查机制
        local str = self._UIN27MissionTaskCondition:CheckTaskAndGetStr(task, self._CurOrderMap)
        textComp.text = str
        idx = idx + 1
    end
end

--刷新订单栏
function UIN27PostInnerGameController:RefreshOrderPanel(anim)
    local showOrder = self._CurOrderList[self._CurShowOrderIdx]
    local petID = showOrder.PetId
    local itemTypeList = showOrder.ItemTypeAndNum or {}
    local itemList = showOrder.ItemIdAndNum or {}
    local showCount = 0
    for i = 1, #self._OrderWidgetList do
        self._OrderWidgetList[i]:GetGameObject():SetActive(false) 
    end
    for i = 1, #self._OrderWidgetList do
        if i <= #itemTypeList then
            local orderItemCfg = itemTypeList[i]
            local typeCfg = self._GameItemTypeDic[orderItemCfg[1]]
            local count = orderItemCfg[2]
            local curCount = 0
            for itemID, countValue in pairs(self._CurItemMap) do
                local itemCfg = Cfg.cfg_component_post_station_game_item{ID = itemID}[1]
                if itemCfg.ItemType == orderItemCfg[1] then
                    curCount = curCount + countValue
                end
            end
            self._OrderWidgetList[i]:SetData(typeCfg, nil, count, curCount)
            showCount = showCount + 1
        elseif (i - #itemTypeList) <= #itemList then
            local idx = i - #itemTypeList
            local orderItemCfg = itemList[idx]
            local itemCfg = Cfg.cfg_component_post_station_game_item{ID = orderItemCfg[1]}[1]
            local count = orderItemCfg[2]
            local itemInMapCount = self._CurItemMap[orderItemCfg[1]]
            local curCount = itemInMapCount and itemInMapCount or 0
            self._OrderWidgetList[i]:SetData(nil, itemCfg, count, curCount)
            self._OrderWidgetList[i]:GetGameObject():SetActive(true)
            showCount = showCount + 1
        end
    end
    for i = 1, showCount do
        if anim then
            local te = GameGlobal.Timer():AddEvent(
                30*i,
                function()
                    self._OrderWidgetList[i]:GetGameObject():SetActive(true) 
                    self._OrderWidgetList[i]:PlayShowAnimation()
                    self._OrderWidgetList[i]:PlayCheckAnimation()
                end
            )
            table.insert(self._TimerList, te)
        else
            self._OrderWidgetList[i]:GetGameObject():SetActive(true) 
            self._OrderWidgetList[i]:PlayCheckAnimation()
        end
    end
    local str = StringTable.Get("str_n27_poststation_currentorder") .. "(%d/%d)"
    self._OrderTitleText:SetText(string.format(str, (table.count(self._CurOrderMap) + 1), self._MissionCfg.OrderNum))
end

--刷新道具栏
function UIN27PostInnerGameController:RefreshItemPanel(typeID, force)
    if self._CurSelectItemTypeID == typeID and not force then 
        return
    end

    --选择所有物品分类
    if typeID == self._AllGameTypeID then
        for _type, itemGroup in pairs(self._GameItemDic) do
            local widgetList = self._UIGameItemObjectMap[_type]
            local idx = 1
            for _, v in pairs(itemGroup) do
                local widget = widgetList[idx]
                widget:SetData(v) 
                widget:GetGameObject():SetActive(true)
                idx = idx + 1
            end
        end
    else
        for _type, itemGroup in pairs(self._GameItemDic) do
            local idx = 1
            local widgetList = self._UIGameItemObjectMap[_type]
            for _, v in pairs(itemGroup) do
                local widget = widgetList[idx]
                if _type == typeID then
                    widget:SetData(v) 
                    widget:GetGameObject():SetActive(true)
                else
                    widget:GetGameObject():SetActive(false)
                end
                idx = idx + 1
            end
        end
    end
    self._CurSelectItemTypeID = typeID
end

--初始化棋盘
function UIN27PostInnerGameController:InitMainGrid()
    self._MainGridReq = ResourceManager:GetInstance():SyncLoadAsset("UIN27MainGrid.prefab", LoadType.GameObject)
    self._MainGridReq.Obj:SetActive(true)
    self._MainGridItemPrefab = self._MainGridReq.Obj.transform:Find("Canvas/block").gameObject
    self._GameItemPrefab = self._MainGridReq.Obj.transform:Find("Canvas/itemRawImage").gameObject
    -- self._MainEmptyArea = self._MainGridReq.Obj.transform:Find("Canvas/EmptyArea").gameObject
    self._MainGridTransform = self._MainGridReq.Obj.transform:Find("Canvas/Grid")
    self._MainGridgGroupTransform = self._MainGridReq.Obj.transform:Find("Canvas/GridItemGroup")
    self._DragItem = self._MainGridReq.Obj.transform:Find("Canvas/DragItem").gameObject
    self._DragIconRawImageLoader = self._MainGridReq.Obj.transform:Find("Canvas/DragItem/dragIcon").gameObject:GetComponent("RawImageLoader")
    self._DragBgGroup = self._MainGridReq.Obj.transform:Find("Canvas/DragItem/bgGroup")
    self._DragHand = self._MainGridReq.Obj.transform:Find("Canvas/hand").gameObject
    self._MainGridGameCamera = self._MainGridReq.Obj.transform:Find("Camera"):GetComponent("Camera")
    self._GameRenderTexture = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    self._MainGridGameCamera.targetTexture = self._GameRenderTexture
    self._MainGridRawImage.texture = self._GameRenderTexture
    for i = 1, self._MainGridWidth do
        for j = 1, self._MainGridHeight do
            local mainGridItem = UnityEngine.GameObject.Instantiate(self._MainGridItemPrefab, self._MainGridTransform)
            local mainGridItemWidget = UIN27MainGridItem:New(i, j, mainGridItem)
            self._UIN27PostPackageGridManager:InjectWidgetToMainMatrix(i, j, mainGridItemWidget)
            mainGridItem:SetActive(true)
        end
    end
    --注册空点击区域事件
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._MainEmptyArea),
        UIEvent.Hovered,
        function(go)
            Log.debug("Empty Hovered!!!!!!!!!!!!")
            self._CurHoveredBlock = nil
            self._UIN27PostPackageGridManager:ClearCheckBlocksColor()
        end
    )
end

function UIN27PostInnerGameController:OnUpdate(deltaTimeMS)
    if self._EndGame then
        return
    end
    self:OnPCInputUpdate()
    self:OnDragUpdate()
end

function UIN27PostInnerGameController:OnDragUpdate()
    if not self._IsDragItem then
        return
    end
    --跟随鼠标
    local mousePosition = nil
    if self._MousePresent then
        mousePosition = self._Input.mousePosition
    else
        if self._Input.touchCount ~= 0 then
            mousePosition = self._Input.GetTouch(0).position
        else
            mousePosition = self._Input.mousePosition
        end
    end
    local screenPos = Vector2(mousePosition.x, mousePosition.y)
    local pos = UIHelper.ScreenPointToWorldPointInRectangle(self._DragItem.transform.parent, screenPos, self._MainGridGameCamera)
    self._DragItem.transform.position = pos
    self._DragHand.transform.position = pos
end

function UIN27PostInnerGameController:OnPCInputUpdate()
    if not self._IsDragItem then
        return
    end
    --旋转R
    if (self._Input.GetKeyDown(UnityEngine.KeyCode.R)) then
        self:RotateBtnOnClick()
    end
    --翻转T
    if (self._Input.GetKeyDown(UnityEngine.KeyCode.T)) then
        self:FlipBtnOnClick()
    end
end
function UIN27PostInnerGameController:SetDragStatus(flag)
    self._IsDragItem = flag
    self._DragItem:SetActive(flag)
    self._DragHand:SetActive(flag)
    self._MainEmptyArea:SetActive(flag)
    --UnityEngine.Input.multiTouchEnabled = flag
end

function UIN27PostInnerGameController:OnGameItemSelect(itemWidget)
    --当前道具已经达到上限
    if itemWidget:GetItemCount() == 0 then
        return
    end 
    --初始化数据
    self._CurHoveredBlock = nil
    local itemDetail = self._UIN27PostPackageGridManager:GetItemDetail(itemWidget:GetItemID())
    self._CurRotateIdx = 1
    self._CurItemMatrix = self._UIN27PostPackageGridManager:CopyMatrix(itemDetail.Matrix)
    self._CurDragItemID = itemWidget:GetItemID()
    local eulerAngle = self._RotationList[self._CurRotateIdx]
    local ndcX, ndxY = self._UIN27PostPackageGridManager:GetItemNDCCenter(itemWidget:GetItemID())
    local pivot = self:GetItemPivot({ndcX, ndxY}, self._CurRotateIdx, 1, 1)
    local RectTransform = self._DragItem:GetComponent("RectTransform")
    self._DragItem.transform.localEulerAngles = Vector3(0, 0, eulerAngle)
    self._DragItem.transform.localScale = Vector3.one
    RectTransform.pivot = Vector2(pivot[1], pivot[2])
    local sizeX, sizeY = self._UIN27PostPackageGridManager:GetItemSize(itemWidget:GetItemID())
    RectTransform.sizeDelta = Vector2(self._BlockPixel * sizeX, self._BlockPixel * sizeY)
    self:SetDragStatus(true)
    self:ShowDragItemBlockBG(self._CurItemMatrix)
    local itemCfg = Cfg.cfg_component_post_station_game_item{ID = self._CurDragItemID}[1]
    self._DragIconRawImageLoader:LoadImage(itemCfg.GameItemIcon)
    --引导
    if GuideHelper.GuideInProgress() then
        if GameGlobal.GuideMessageBoxMng()._uiMsgBox then
            GameGlobal.GuideMessageBoxMng()._uiMsgBox:SetShow(false)
        end
    end
end

function UIN27PostInnerGameController:OnGameItemRelease(itemWidget)
    self:SetDragStatus(false)
    --继续显示引导
    if GuideHelper.GuideInProgress() then
        if GameGlobal.GuideMessageBoxMng()._uiMsgBox then
            GameGlobal.GuideMessageBoxMng()._uiMsgBox:SetShow(true)
        end
    end
    if self._CurHoveredBlock == nil then
        --拖拽到界面外
        return
    end
    --这里用检测射中块
    local pos = Vector2(self._CurHoveredBlock:GetX(), self._CurHoveredBlock:GetY())
    local mainBlockWidget = self._UIN27PostPackageGridManager:GetMainMatrixWidget(pos.x, pos.y)
    local result, atomicItemID = self._UIN27PostPackageGridManager:TryToInsertMainMatrix(itemWidget:GetItemID(), self._CurItemMatrix, mainBlockWidget, self._CurRotateIdx, self._DragItem.transform.localScale)
    if result then
        Log.debug("------放置成功-----")
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1GameWeight)
        local itemDetail = self._UIN27PostPackageGridManager:GetItemDetailOnGridMap(atomicItemID)
        local gameObject = self:CreateItemOnGrid(itemWidget:GetItemID(), pos, itemDetail)
        self:SetItemToMap(itemWidget:GetItemID(), true)
        self._GameItemObjectMap[atomicItemID] = gameObject
        self:RefreshOrderPanel()
        --完成引导
        if GuideHelper.GuideInProgress() then
            self._GuideEffObj:SetActive(false)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ForceFinishGuideStep, GuideType.Button)
        end
    else
        Log.debug("------放置失败-----")
    end
    self._UIN27PostPackageGridManager:ClearCheckBlocksColor()
    self._CurHoveredBlock = nil
end

function UIN27PostInnerGameController:OnGameBlockHovered(blockWidget)
    if not self._IsDragItem then
        return
    end
    self._CurHoveredBlock = blockWidget
    --检查悬浮区域放置状态
    self._UIN27PostPackageGridManager:CheckItemHoveredOnMainMatrix(self._CurDragItemID, self._CurItemMatrix, blockWidget, self._CurRotateIdx)
end

function UIN27PostInnerGameController:OnGameBlockPress(blockWidget)
    --初始化数据
    local atomicItemID = blockWidget:GetAtomicItemID()
    local itemID = blockWidget:GetItemID()
    if atomicItemID == nil then
        --点击的块没有道具
        return
    end
    local itemDetail = self._UIN27PostPackageGridManager:GetItemDetailOnGridMap(atomicItemID)
    self._CurHoveredBlock = blockWidget
    self._CurDragItemAtomicID = atomicItemID
    self._CurRotateIdx = itemDetail.rotationID
    self._CurItemMatrix = itemDetail.matrix
    self._CurDragItemID = itemID
    local eulerAngle = self._RotationList[self._CurRotateIdx]
    local ndcX, ndxY = self._UIN27PostPackageGridManager:GetItemNDCCenter(itemID)
    local pivot = self:GetItemPivot({ndcX, ndxY}, self._CurRotateIdx, itemDetail.scale.x, itemDetail.scale.y)
    local RectTransform = self._DragItem:GetComponent("RectTransform")
    self._DragItem.transform.localEulerAngles = Vector3(0, 0, eulerAngle)
    self._DragItem.transform.localScale = itemDetail.scale
    RectTransform.pivot = Vector2(pivot[1], pivot[2])
    local sizeX, sizeY = self._UIN27PostPackageGridManager:GetItemSize(itemID)
    RectTransform.sizeDelta = Vector2(self._BlockPixel * sizeX, self._BlockPixel * sizeY)
    self._GameItemObjectMap[atomicItemID]:SetActive(false)
    --暂时释放拖拽物品的区域，用于后续检查
    for _, blockWidget in pairs(itemDetail.blockList) do
        blockWidget:SetOccupy(false, nil, nil)
    end
    self:SetDragStatus(true)
    self:ShowDragItemBlockBG(self._UIN27PostPackageGridManager:GetItemDetail(itemID).Matrix)
    local itemCfg = Cfg.cfg_component_post_station_game_item{ID = self._CurDragItemID}[1]
    self._DragIconRawImageLoader:LoadImage(itemCfg.GameItemIcon)
end

function UIN27PostInnerGameController:OnGameBlockRelease(blockWidget)
    self:SetDragStatus(false)
    local atomicItemID = self._CurDragItemAtomicID
    local itemID = self._CurDragItemID
    if atomicItemID == nil then
        --点击的块没有道具
        return
    end
    local itemDetail = self._UIN27PostPackageGridManager:GetItemDetailOnGridMap(atomicItemID)
    if self._CurHoveredBlock == nil then
        --拖拽到界面外，视为删除
        self:SetItemToMap(itemID, false)
        local gameObject = self._GameItemObjectMap[atomicItemID]
        self._GameItemObjectMap[atomicItemID] = nil
        UnityEngine.GameObject.Destroy(gameObject)
        self:RefreshOrderPanel()
    else
        --这里用检测射中块
        local pos = Vector2(self._CurHoveredBlock:GetX(), self._CurHoveredBlock:GetY())
        local mainBlockWidget = self._UIN27PostPackageGridManager:GetMainMatrixWidget(pos.x, pos.y)
        local result, newAtomicItemID = self._UIN27PostPackageGridManager:TryToInsertMainMatrix(itemID, self._CurItemMatrix, mainBlockWidget, self._CurRotateIdx, self._DragItem.transform.localScale)
        if result then
            Log.debug("------替换位置放置成功-----")
            --删除旧信息
            self._UIN27PostPackageGridManager:RemoveItemDetailInGridMap(atomicItemID)
            local gameObject = self._GameItemObjectMap[atomicItemID]
            self._GameItemObjectMap[atomicItemID] = nil
            UnityEngine.GameObject.Destroy(gameObject)
            --添加新信息
            itemDetail = self._UIN27PostPackageGridManager:GetItemDetailOnGridMap(newAtomicItemID)
            local gameObject = self:CreateItemOnGrid(itemID, pos, itemDetail)
            self._GameItemObjectMap[newAtomicItemID] = gameObject
            self:RefreshOrderPanel()
        else
            Log.debug("------放置失败还原位置-----")
            for _, blockWidget in pairs(itemDetail.blockList) do
                blockWidget:SetOccupy(true, atomicItemID, itemID)
            end
            self._GameItemObjectMap[atomicItemID]:SetActive(true)
        end
    end
    self._UIN27PostPackageGridManager:ClearCheckBlocksColor()
    self._CurDragItemAtomicID = nil
    self._CurHoveredBlock = nil
end

function UIN27PostInnerGameController:CreateItemOnGrid(itemID, center, itemDetail)
    local sizeX, sizeY = self._UIN27PostPackageGridManager:GetItemSize(itemID)
    local gameItemObj = UnityEngine.GameObject.Instantiate(self._GameItemPrefab, self._MainGridgGroupTransform)
    local te = GameGlobal.Timer():AddEvent(
        500,
        function()
            if not tolua.isnull(gameItemObj) then
                gameItemObj.transform:Find("eff").gameObject:SetActive(false)
            end
        end
    )
    table.insert(self._TimerList, te)
    local itemCfg = Cfg.cfg_component_post_station_game_item{ID = itemID}[1]
    local rawImage = gameItemObj:GetComponent("RawImageLoader")
    rawImage:LoadImage(itemCfg.GameItemIcon)
    local eulerAngle = self._RotationList[itemDetail.rotationID]
    local ndcX, ndxY = self._UIN27PostPackageGridManager:GetItemNDCCenter(itemID)
    local pivot = self:GetItemPivot({ndcX, ndxY}, self._CurRotateIdx, itemDetail.scale.x, itemDetail.scale.y)
    gameItemObj.transform.localEulerAngles = Vector3(0, 0, eulerAngle)
    gameItemObj.transform.localScale = itemDetail.scale
    local RectTransform = gameItemObj:GetComponent("RectTransform")
    RectTransform.sizeDelta = Vector2(self._BlockPixel * sizeX, self._BlockPixel * sizeY)
    RectTransform.anchoredPosition = Vector2(center.y * self._BlockPixel, -center.x * self._BlockPixel)
    RectTransform.pivot = Vector2(pivot[1], pivot[2])
    gameItemObj:SetActive(true)
    return gameItemObj
end

function UIN27PostInnerGameController:RotateBtnOnClick()
    if not self._IsDragItem or self._IsAnimated then
        return
    end
    self._CurRotateIdx = self._CurRotateIdx + 1
    self._CurRotateIdx = self._CurRotateIdx > #self._RotationList and 1 or self._CurRotateIdx
    local eulerAngle = self._RotationList[self._CurRotateIdx]
    local ndcX, ndxY = self._UIN27PostPackageGridManager:GetItemNDCCenter(self._CurDragItemID)
    local pivot = self:GetItemPivot({ndcX, ndxY}, self._CurRotateIdx, self._DragItem.transform.localScale.x, self._DragItem.transform.localScale.y)
    --动效
    self._IsAnimated = true
    local eulerAngles = Vector3(0, 0, eulerAngle)
    self._DragItem.transform:DORotate(eulerAngles, 0.3):SetEase(DG.Tweening.Ease.Linear):OnComplete(function()
        self._IsAnimated = false
    end)
    local RectTransform = self._DragItem:GetComponent("RectTransform")
    RectTransform:DOPivot(Vector2(pivot[1], pivot[2]), 0.3):SetEase(DG.Tweening.Ease.Linear)
    self._CurItemMatrix = self._UIN27PostPackageGridManager:RotateItemClockwise(self._CurItemMatrix)
    if self._CurHoveredBlock then
        self._UIN27PostPackageGridManager:CheckItemHoveredOnMainMatrix(self._CurDragItemID, self._CurItemMatrix, self._CurHoveredBlock, self._CurRotateIdx)
    end
end

function UIN27PostInnerGameController:FlipBtnOnClick()
    if not self._IsDragItem or self._IsAnimated then
        return
    end
    local scale = self._DragItem.transform.localScale
    local RectTransform = self._DragItem:GetComponent("RectTransform")
    local flipParam = self._CurRotateIdx & 1 == 1 and {-1,1} or {1,-1}
    --动效
    self._IsAnimated = true
    local tScaleX = scale.x * flipParam[1]
    local tScaleY = scale.y * flipParam[2]
    self._DragItem.transform:DOScale(Vector3(tScaleX, tScaleY, scale.z), 0.3):SetEase(DG.Tweening.Ease.Linear):OnComplete(function()
        self._IsAnimated = false
    end)
    local ndcX, ndxY = self._UIN27PostPackageGridManager:GetItemNDCCenter(self._CurDragItemID)
    local pivot = self:GetItemPivot({ndcX, ndxY}, self._CurRotateIdx, tScaleX, tScaleY)
    RectTransform:DOPivot(Vector2(pivot[1], pivot[2]), 0.3):SetEase(DG.Tweening.Ease.Linear)
    self._CurItemMatrix = self._UIN27PostPackageGridManager:FlipItem(self._CurItemMatrix)
    if self._CurHoveredBlock then
        self._UIN27PostPackageGridManager:CheckItemHoveredOnMainMatrix(self._CurDragItemID, self._CurItemMatrix, self._CurHoveredBlock, self._CurRotateIdx)
    end
end

function UIN27PostInnerGameController:DeleteBtnOnClick()
    self._Transition:ChangeAnim("uieff_UIN27PostInnerGameController_DeletePanel_in", 10)
    self._Transition:PlayEnterAnimation(true)
    self._MainGridGameCamera.depth = 0
    self._DeletePanelObj:SetActive(true)
end

function UIN27PostInnerGameController:DeleteCheckOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1GameTrash)
    self:ClearGameMainGrid()
    self:RefreshOrderPanel()
    if self._petSpine then
        local skeleton = self._petSpine.CurrentSkeleton
        if not skeleton then
            skeleton = self._petSpine.CurrentMultiSkeleton
        end
        if skeleton then
            skeleton.AnimationState:SetAnimation(0, "sad", false)
            skeleton.AnimationState:AddAnimation(0, "idle", true, 0)
        end
    end
    --anim
    self._Transition:PlayLeaveAnimation(true)
    local te = GameGlobal.Timer():AddEvent(
        333,
        function()
            self._MainGridGameCamera.depth = 11
            self._DeletePanelObj:SetActive(false)
        end
    )
    table.insert(self._TimerList, te)
end

function UIN27PostInnerGameController:DeleteCancelOnClick()
    --anim
    self._Transition:PlayLeaveAnimation(true)
    local te = GameGlobal.Timer():AddEvent(
        333,
        function()
            self._MainGridGameCamera.depth = 11
            self._DeletePanelObj:SetActive(false)
        end
    )
    table.insert(self._TimerList, te)
end

function UIN27PostInnerGameController:PostBtnOnClick()
    if self._EndGame then
        return
    end
    --保存订单信息
    local curOrder = self._CurOrderList[self._CurShowOrderIdx]
    local copy = {}
    for k, v in pairs(self._CurItemMap) do
        if v ~= 0 then
            copy[k] = v
        end
    end
    self._CurOrderMap[curOrder.ID] = copy
    self._CurOrderSeq[curOrder.ID] = table.count(self._CurOrderMap)
    self:Lock("UIN27PostInnerGameController_PostBtnOnClick")
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N27MiniGamePostBtn)
    self:StartTask(function(TT)
        --缓存游戏截图
        self:CacheGameRT(TT, curOrder.ID)
        --光灵spine动画
        local mainGridIdx = self._MainGridRawImageTrans:GetSiblingIndex()
        self._box1Trans:SetSiblingIndex(mainGridIdx)
        if self._petSpine then
            local skeleton = self._petSpine.CurrentSkeleton
            if not skeleton then
                skeleton = self._petSpine.CurrentMultiSkeleton
            end
            if skeleton then
                skeleton.AnimationState:SetAnimation(0, "happy", false)
                skeleton.AnimationState:AddAnimation(0, "idle", true, 0)
            end
        end
        --箱子spine动画
        if self._box1Spine then
            local skeleton = self._box1Spine.CurrentSkeleton
            if not skeleton then
                skeleton = self._box1Spine.CurrentMultiSkeleton
            end
            if skeleton then
                skeleton.AnimationState:SetAnimation(0, "dabao", false)
                skeleton.AnimationState:AddAnimation(0, "fangzhi", false, 0)
                skeleton.AnimationState:AddAnimation(0, "idle", false, 0)
            end
        end
        if self._box2Spine then
            local skeleton = self._box2Spine.CurrentSkeleton
            if not skeleton then
                skeleton = self._box2Spine.CurrentMultiSkeleton
            end
            if skeleton then
                skeleton.AnimationState:SetAnimation(0, "dabao", false)
                skeleton.AnimationState:AddAnimation(0, "fangzhi", false, 0)
                skeleton.AnimationState:AddAnimation(0, "idle", false, 0)
            end
        end
        --YIELD(TT, 200)
        self._MainGridRawImageObj:SetActive(false)
        --判断是否结束
        if table.count(self._CurOrderMap) == self._MissionCfg.OrderNum then
            self._EndGame = true
            local order_list = {}
            for orderID, set in pairs(self._CurOrderMap) do
                local missionOrderInfo = MissionOrderInfo:New() 
                missionOrderInfo.order_id = orderID
                missionOrderInfo.item_id_num = set
                order_list[orderID] = missionOrderInfo
            end
            --请求
            local res = AsyncRequestRes:New()
            local code, result =
                self._component:HandleSubmitMissionInfo(
                TT,
                res,
                self._MissionID,
                order_list
            )
            if code and result then
                YIELD(TT, 1800)
                --开始结算
                self:ShowDialog("UIN27PostGameClosingController", 
                    self._CurOrderMap, 
                    self._CurOrderRTMap, 
                    self._CurOrderSeq,
                    self._CurTaskList,
                    self._UIN27MissionTaskCondition,
                    self._MissionID,
                    self._componentInfo,
                    true
                )
            else
                self:QuitOnClick()
                Log.error("HandleSubmitMissionInfo req fail")
            end
            YIELD(TT, 1000)
            self._MainGridRawImageObj:SetActive(true)
            self._MainGridRawImageTrans:SetSiblingIndex(mainGridIdx)
            self._HideGroup:DOFade(1,0.3)
        else
            --填入一个新订单
            self._CurOrderList[self._CurShowOrderIdx] = self._AllOrderList[1]
            table.remove(self._AllOrderList, 1)
            --刷新切换按钮头像显示
            for i = 1, #self._OrderTabObjList do
                local tabObj = self._OrderTabObjList[i]
                tabObj.transform:Find("SelectImage/RawImage"):GetComponent("RawImageLoader"):LoadImage(self._CurOrderList[i].PetHeadSelectIcon)
                tabObj.transform:Find("NormalImage/RawImage"):GetComponent("RawImageLoader"):LoadImage(self._CurOrderList[i].PetHeadIcon)
            end
            --clear
            self:ClearGameMainGrid()
            --刷新订单详情
            self:RefreshOrderPanel()
            --刷新任务详情
            self:RefreshTaskPanel()
            --等待spine动画
            YIELD(TT, 2200)
            self._MainGridRawImageObj:SetActive(true)
            self._MainGridRawImageTrans:SetSiblingIndex(mainGridIdx)
            self._HideGroup:DOFade(1,0.3)
        end
        self:UnLock("UIN27PostInnerGameController_PostBtnOnClick")
    end)
end

function UIN27PostInnerGameController:ShowDragItemBlockBG(matrix)
    --重置
    for i = 0, self._DragBgGroup.childCount - 1 do
        self._DragBgGroup:GetChild(i).gameObject:SetActive(false)
    end
    local raw, col = #matrix, #matrix[1]
    local idx = 0
    for i = 1, raw do
        for j = 1, col do
            local go = self._DragBgGroup:GetChild(idx).gameObject
            go:SetActive(true)
            go:GetComponent("Image").color = Color(1,1,1,matrix[i][j])
            idx = idx + 1
        end
    end
end

function UIN27PostInnerGameController:GetItemPivot(ndcCenter, rotationID, scaleX, scaleY)
    local x, y = 0, 0
    if rotationID == 1 then
        x, y  = ndcCenter[1], 1 - ndcCenter[2]
    elseif rotationID == 2 then
        x, y  = 1 - ndcCenter[1], 1 - ndcCenter[2]
    elseif rotationID == 3 then
        x, y  = 1 - ndcCenter[1], ndcCenter[2]
    else
        x, y  = ndcCenter[1], ndcCenter[2]
    end
    if scaleX < 0 then
        x = 1 - x
    end
    if scaleY < 0 then
        y = 1 - y
    end
    return {x, y}
end

function UIN27PostInnerGameController:CacheGameRT(TT, id)
    self._HideGroup:DOFade(0,0.3)
    YIELD(TT, 300)
    --local format = UnityEngine.RenderTextureFormat.ARGB32
    -- if UnityEngine.SystemInfo.SupportsRenderTextureFormat(UnityEngine.RenderTextureFormat.ARGBHalf) then
    --     format = UnityEngine.RenderTextureFormat.ARGBHalf
    -- end
    -- local cacheRT = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 24)
    -- cacheRT.wrapMode = UnityEngine.TextureWrapMode.Clamp
    -- cacheRT.filterMode = UnityEngine.FilterMode.Bilinear
    -- local camera = GameGlobal.UIStateManager():GetControllerCamera("UIN27PostInnerGameController") 
    -- camera.targetTexture = cacheRT
    -- camera:Render()
    self._Shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera("UIN27PostInnerGameController")
    self._Shot.width = UnityEngine.Screen.width
    self._Shot.height = UnityEngine.Screen.height
    local rt = self._Shot:RefreshBlurTexture()
    local cacheRT = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    YIELD(TT)
    UnityEngine.Graphics.Blit(rt, cacheRT)
    UnityEngine.RenderTexture.active = cacheRT
    local tex2d = UnityEngine.Texture2D:New(
        UnityEngine.Screen.width,
        UnityEngine.Screen.height
    )
    tex2d:ReadPixels(UnityEngine.Rect:New(0, 0, UnityEngine.Screen.width, UnityEngine.Screen.height), 0, 0, false)
    tex2d:Apply()
    --camera.targetTexture = nil
    --cacheRT:Destroy()
    UnityEngine.RenderTexture.active = nil
    self._CurOrderRTMap[id] = tex2d
    self._Shot:CleanRenderTexture()
end

function UIN27PostInnerGameController:ClearGameMainGrid()
    --清理道具map
    for itemID, count in pairs(self._CurItemMap) do
        local itemCfg = Cfg.cfg_component_post_station_game_item{ID = itemID}[1]
        self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit = self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit + count
    end
    table.clear(self._CurItemMap)
    self:RefreshItemPanel(self._CurSelectItemTypeID, true)
    --清理网格widget
    self._UIN27PostPackageGridManager:ClearGrid()
    --清理道具实例
    for _, go in pairs(self._GameItemObjectMap) do
        UnityEngine.GameObject.Destroy(go)
    end
    table.clear(self._GameItemObjectMap)
end

function UIN27PostInnerGameController:SetItemToMap(itemID, isAdd)
    local itemCfg = Cfg.cfg_component_post_station_game_item{ID = itemID}[1]
    if isAdd then
        self._CurItemMap[itemID] = self._CurItemMap[itemID] or 0
        self._CurItemMap[itemID] = self._CurItemMap[itemID] + 1
        self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit = self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit - 1
    else
        self._CurItemMap[itemID] = self._CurItemMap[itemID] - 1
        self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit = self._GameItemDic[itemCfg.ItemType][itemID].ItemNumLimit + 1
    end
    self:RefreshItemPanel(self._CurSelectItemTypeID, true)
end

function UIN27PostInnerGameController:RefreshTimeCounter(second)
    local timeList = {}
    while second ~= 0 do
        table.insert(timeList, 1, second % 10)
        second = second // 10
    end
    local len = 4 - #timeList
    for i = 1, len do
        table.insert(timeList, 1, 0)
    end
    for i = 1, #self._TimerImageList do
        self._TimerImageList[i].sprite = self._atlas:GetSprite(self._TimeCountSprNameList[i] .. timeList[i])
    end
end

function UIN27PostInnerGameController:PauseOnClick()
    self._Transition:ChangeAnim("uieff_UIN27PostInnerGameController_PausePanel_in", 10)
    self._Transition:PlayEnterAnimation(true)
    self._PausePanelObj:SetActive(true)
    self._MainGridGameCamera.depth = 0
    self._IsPause = true
end

function UIN27PostInnerGameController:ResumeOnClick()
    self._Transition:PlayLeaveAnimation(true)
    local te = GameGlobal.Timer():AddEvent(
        333,
        function()
            self._PausePanelObj:SetActive(false)
            self._MainGridGameCamera.depth = 20
            self._IsPause = false
        end
    )
    table.insert(self._TimerList, te)
end

function UIN27PostInnerGameController:QuitOnClick()
    if self:CheckComponentClose() then
        self:SwitchState(UIStateType.UIMain)
    else    
        self:SwitchState(UIStateType.UIN27MiniGameController,self._MissionID)
    end
end

function UIN27PostInnerGameController:OnHide()
    self._EndGame = false
    self:DetachEvent(GameEventType.OnN27PostGameItemTypeChange, self.RefreshItemPanel)
    self:DetachEvent(GameEventType.OnN27PostGameItemPress, self.OnGameItemSelect)
    self:DetachEvent(GameEventType.OnN27PostGameItemRelease, self.OnGameItemRelease)
    self:DetachEvent(GameEventType.OnN27PostGameBlockHovered, self.OnGameBlockHovered)
    self:DetachEvent(GameEventType.OnN27PostGameBlockPress, self.OnGameBlockPress)
    self:DetachEvent(GameEventType.OnN27PostGameBlockRelease, self.OnGameBlockRelease)
    if self._countdownTimer then
        GameGlobal.Timer():CancelEvent(self._countdownTimer)
        self._countdownTimer = nil
    end
    for _, v in pairs(self._TimerList) do
        GameGlobal.Timer():CancelEvent(v)
    end
    UnityEngine.GameObject.Destroy(self._MainGridReq.Obj)
    self._MainGridReq = nil
    self._GameRenderTexture:Release()
    --关闭多点触控
    UnityEngine.Input.multiTouchEnabled = false
end

function UIN27PostInnerGameController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIN27PostInnerGameController)
end

function UIN27PostInnerGameController:_FinishDragItemGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.OperationFinish)
end

function UIN27PostInnerGameController:GetFirstOrderWidghtForGuide()
    return self._firstOrderWidgetForGuide:GetGameObject()
end

function UIN27PostInnerGameController:GetFirstItemForGuide()
    local itemWidgetList = self._ItemPanel:GetAllSpawnList()
    return itemWidgetList[1]:GetGameObject()
end

function UIN27PostInnerGameController:ShowGuideStep(param)
    if param.data.step == 4 then
        self._GuideEffObj:SetActive(true)
    else
        self._GuideEffObj:SetActive(false)
    end
end

--活动是否开启
function UIN27PostInnerGameController:CheckComponentClose()
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    if curTime >=  self._componentInfo.m_close_time then
        return true
    end
    return false
end