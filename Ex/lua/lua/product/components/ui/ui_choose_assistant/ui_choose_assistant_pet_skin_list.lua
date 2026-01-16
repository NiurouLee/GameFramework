---@class UIChooseAssistantPetSkinList : UICustomWidget
_class("UIChooseAssistantPetSkinList", UICustomWidget)
UIChooseAssistantPetSkinList = UIChooseAssistantPetSkinList
function UIChooseAssistantPetSkinList:Constructor()
    self._cardWidth = 400
    self._cardHeight = 90
    self._lastContentPosX = 0
    self._listOrderCmpt = nil
    self._disableDrag = true
end
function UIChooseAssistantPetSkinList:OnShow(uiParams)
    self._isScrollReady = false
    self._refreshUiCallBack = nil
    self._checkIsCurSkinCallBack = nil
    self:InitWidget()
end
function UIChooseAssistantPetSkinList:InitWidget()
    --generated--
    self._content = self:GetUIComponent("RectTransform", "Content")
    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "SkinsList")
    ---@type UnityEngine.UI.Image
    self._swithArrowAreaGo = self:GetGameObject("SwithArrowArea")
    --self._scrollHandleGo = self:GetGameObject("ScrollHandle")
    --generated end--
end
function UIChooseAssistantPetSkinList:SetData()
    
end
---@param data choose_assistant_ui_data_pet
function UIChooseAssistantPetSkinList:RefreshData(data)
    self._isScrollReady = false

    ---清理掉所有创建的cell
    self:DisposeCustomWidgets()
    self._data = data 
    
    local _skinsCellCount = #self._data.skinList
    local _asCellCount = #self._data.aslist
    self._skinsCellCount = _skinsCellCount+_asCellCount
    self._count = self._skinsCellCount
    self._curSelSkinIndex = 1
    self:_CreateScrollItem()

    self:_selDefaultIndex()


    --self:AddUICustomEventListener(UICustomUIEventListener.Get(self._scrollHandleGo), UIEvent.BeginDrag, function(eventData) self:_beginDragScrollBar(eventData) end)
    --self:AddUICustomEventListener(UICustomUIEventListener.Get(self._scrollHandleGo), UIEvent.Drag, function(eventData) self:_dragScrollBar(eventData) end)
    --self:AddUICustomEventListener(UICustomUIEventListener.Get(self._scrollHandleGo), UIEvent.EndDrag, function(eventData) self:_endDragScrollBar(eventData) end)

    self._isScrollReady = true
end
function UIChooseAssistantPetSkinList:SetRefreshUiCallBack(callBack)
    self._refreshUiCallBack = callBack
end
function UIChooseAssistantPetSkinList:SetCheckIsCurSkinCallBack(callBack)
    self._checkIsCurSkinCallBack = callBack
end
function UIChooseAssistantPetSkinList:_CreateScrollItem()
    if self._disableDrag then
        self._scrollRect.vertical = false--去掉滑动
    else
        if self._count <= 1 then
            self._scrollRect.vertical = false
        else
            self._scrollRect.vertical = true
        end
    end
    ---------------------------------------------------
    ---@type UICustomWidgetPool
    self._itemPool = self:GetUIComponent("UISelectObjectPath", "Content")
    self._itemPool:SpawnObjects("UIChooseAssistantPetSkinCard", self._skinsCellCount)
    ---@type UIChooseAssistantPetSkinCard[]
    local items = self._itemPool:GetAllSpawnList()
    self._items = items

    ---@type choose_assistant_ui_data_skin[]
    self._datas = {}
    ---@type choose_assistant_ui_data_skin[]
    local datas2 = {}

    for i = 1, #self._data.skinList do
        local data = self._data.skinList[i]
        table.insert(datas2,data)
    end
    for i = 1, #self._data.aslist do
        local data = self._data.aslist[i]
        table.insert(datas2,data)
    end

    --找当前的下标
    local insertNewIdx = 0
    local igCount = 0
    for i = 1, #datas2 do
        local data = datas2[i]
        local cur = self._checkIsCurSkinCallBack(data.petid,data.grade,data.skinid,data.asid)
        local new = self:CheckIsNew(data.asid)
        if new then
            igCount = igCount + 1
        end
        if cur then
            insertNewIdx = i
            break
        end
    end
    if insertNewIdx ~= 0 then
        insertNewIdx = insertNewIdx - igCount
    end
    --把新的挪出来，再重新插进去
    local tmpDatas = {}
    local removeIdxs = {}
    local cfg_tmp = Cfg.cfg_only_assistant{}
    for i = 1, #datas2 do
        local data = datas2[i]
        local asid = data.asid
        local new = self:CheckIsNew(asid)
        if new then
            table.insert(tmpDatas,data)
            table.insert(removeIdxs,i)
        end
    end
    --移除
    for i = #removeIdxs, 1, -1 do
        table.remove(datas2,removeIdxs[i])
    end
    --插入
    for i = 1, #tmpDatas do
        table.insert(datas2,i+insertNewIdx,tmpDatas[i])
    end
    --赋值
    for i = 1, #datas2 do
        local data = datas2[i]
        table.insert(self._datas,data)
    end

    for i = 1, self._skinsCellCount do
        local itemGo = items[i]:GetGameObject()
        local skinData = self._datas[i]

        items[i]:SetCheckIsCurSkinCallBack(self._checkIsCurSkinCallBack)
        local skinCfg = MatchPet.GetPetSkinCfg()
        items[i]:SetData(
            skinData,
            i,
            function(idx) --onclick
                if self._count <= 1 then
                    return
                end
                self:_SelectSkinCellIdx(idx)
                self:_SetMoveToCurSelIdx()
                self._isDarging = false
            end,
            function(eventData) --dragBegin
                if self._disableDrag then
                    return --去掉滑动功能
                end
                if self._count <= 1 then
                    return
                end
                self._bDragPosY = eventData.position.y
                self._DragBeginPos = eventData.position
                self._isDarging = true
            end,
            function(eventData) --draging
            end,
            function(eventData) --dragEnd
                if self._disableDrag then
                    return --去掉滑动功能
                end
                if self._count <= 1 then
                    return
                end
                local finalIdx = 1
                if self._listOrderCmpt then
                    finalIdx = self._listOrderCmpt:CalculateNewIndexByDragPos(self._DragBeginPos,eventData.position,self._curSelSkinIndex)
                end
                --finalIdx = self:_CalculateNewIndexByPos(eventData.position)
                self:_SelectSkinCellIdx(finalIdx)
                self:_SetMoveToCurSelIdx()
                self._isDarging = false
            end
        )
    end
    ui_list_middle_on_top_component.InitListLayout(self._content,self._items,self._cardWidth,self._cardHeight,false,true)
    self._listOrderCmpt = ui_list_middle_on_top_component:New(self._items,self._scrollRect,self._content,false,true)
    self._listOrderCmpt:SetCustomScrollBar(
        self:GetGameObject("CustomScrollBar"),
        self:GetGameObject("ScrollSlidingArea"),
        self:GetGameObject("ScrollHandle")
        )
end
function UIChooseAssistantPetSkinList:CheckIsNew(asid)
    local itemModule = GameGlobal.GetModule(ItemModule)
    local itemDatas = itemModule:GetItemByTempId(asid)
    if itemDatas and table.count(itemDatas) > 0 then
        ---@type Item
        local item_data
        for key, value in pairs(itemDatas) do
            item_data = value
            break
        end
        local isNew = item_data:IsNewOverlay()
        local pstid = item_data:GetID()
        return isNew,pstid
    end
    return false
end
function UIChooseAssistantPetSkinList:_SetMoveToCurSelIdx()
    --self._targetPosY = self:_CalcPosY(self._curSelSkinIndex)
    self._targetPosY = 0
    if self._listOrderCmpt then
        self._targetPosY = self._listOrderCmpt:CalcPosParam(self._curSelSkinIndex)
    end    
    --self._targetPosY = self:_CalcPosY(self._curSelSkinIndex)
    if self._listOrderCmpt then
        self._listOrderCmpt:RefreshListOrder()
    end
end

function UIChooseAssistantPetSkinList:_SelectSkinCellIdx(idx, bNoAnim)
    local useAnim = true
    if bNoAnim then
        useAnim = false
    end
    if idx == self._curSelSkinIndex then
        useAnim = false
    end
    useAnim = false

    local bLeft = idx >= self._curSelSkinIndex
    self._curSelSkinIndex = idx
    if useAnim then
        if bLeft then
            self:PlayLeftOut()
            -- 开启倒计时
            self._timeEvents._swithLeftTimeEvent =
                GameGlobal.Timer():AddEvent(
                self._animNames.left_out.time_len,
                function()
                    self:_RefreshUiByCurSkinIndex()
                    self:PlayLeftIn()
                end
            )
        else
            self:PlayRightOut()
            -- 开启倒计时
            self._timeEvents._swithLeftTimeEvent =
                GameGlobal.Timer():AddEvent(
                self._animNames.right_out.time_len,
                function()
                    self:_RefreshUiByCurSkinIndex()
                    self:PlayRightIn()
                end
            )
        end
    else
        self:_RefreshUiByCurSkinIndex()
    end

    self:RemoveNew()
end
function UIChooseAssistantPetSkinList:RemoveNew()
    local data = self._datas[self._curSelSkinIndex]
    if data then
        local asid = data.asid
        if asid then
            local isNew,pstid = self:CheckIsNew(asid)
            if isNew then
                --请求删除红点
                self:StartTask(
                    function(TT)
                        local itemModule = GameGlobal.GetModule(ItemModule)
                        itemModule:SetItemUnnewOverlay(TT, pstid)                    
                    end
                )
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnRemoveAsCardNew,asid)
            end
        end
    end
end
function UIChooseAssistantPetSkinList:_RefreshUiByCurSkinIndex()
    if self._refreshUiCallBack then
        -- local datas = {}
        -- for i = 1, #self._data.skinList do
        --     local data = self._data.skinList[i]
        --     table.insert(datas,data)
        -- end
        -- for i = 1, #self._data.aslist do
        --     local data = self._data.aslist[i]
        --     table.insert(datas,data)
        -- end
        local data = self._datas[self._curSelSkinIndex]
        self._refreshUiCallBack(data.petid,data.grade,data.skinid,data.asid)
    end
end

function UIChooseAssistantPetSkinList:OnUpdate(deltaTimeMS)
    if self._isScrollReady then
        if self._count <= 1 then
            return
        end
        if not self._isDarging then
            local absDis = math.abs(self._content.anchoredPosition.y - self._targetPosY)
            if absDis > 1 then
                local moveTime = 0.5
                self._content.anchoredPosition =
                    Vector2(
                    self._content.anchoredPosition.x,
                    Mathf.Lerp(self._content.anchoredPosition.y, self._targetPosY, moveTime)
                )
            else
                self._content.anchoredPosition = Vector2(self._content.anchoredPosition.x,self._targetPosY)
            end
        end
        if self._listOrderCmpt then
            self._listOrderCmpt:OnUpdate(deltaTimeMS)
        end
    end
end

function UIChooseAssistantPetSkinList:_selDefaultIndex()
    local defaultIndex = 1
    ---@type choose_assistant_ui_data_skin[]
    local datas = {}
    for i = 1, #self._data.skinList do
        table.insert(datas,self._data.skinList[i])
    end
    for i = 1, #self._data.aslist do
        table.insert(datas,self._data.aslist[i])
    end
    if self._checkIsCurSkinCallBack then
        for i = 1, self._skinsCellCount do
            local skinData = datas[i]
            local isCur = self._checkIsCurSkinCallBack(skinData.petid,skinData.grade,skinData.skinid,skinData.asid)
            if isCur then
                defaultIndex = i
                break
            end
        end
    end
    self:_SelectSkinCellIdx(defaultIndex, true)
    self:_SetMoveToCurSelIdx()
end
function UIChooseAssistantPetSkinList:Arrow1BtnOnClick(go)
    if self._curSelSkinIndex == 1 then
        return
    end
    self._curSelSkinIndex = self._curSelSkinIndex - 1
    self:_SelectSkinCellIdx(self._curSelSkinIndex)
    self:_SetMoveToCurSelIdx()
end

function UIChooseAssistantPetSkinList:Arrow2BtnOnClick(go)
    if self._curSelSkinIndex == self._skinsCellCount then
        return
    end
    self._curSelSkinIndex = self._curSelSkinIndex + 1
    self:_SelectSkinCellIdx(self._curSelSkinIndex)
    self:_SetMoveToCurSelIdx()
end

function UIChooseAssistantPetSkinList:_beginDragScrollBar(eventData)
    if self._disableDrag then
        return --去掉滑动功能
    end
    if self._count <= 1 then
        return
    end
    self._bDragPosY = eventData.position.y
    self._DragBeginPos = eventData.position
    self._isDarging = true
end
function UIChooseAssistantPetSkinList:_dragScrollBar(eventData)
    if self._disableDrag then
        return --去掉滑动功能
    end
    if self._count <= 1 then
        return
    end
    local deltaY = -eventData.delta.y
    local conPos = self._content.anchoredPosition
    self._content.anchoredPosition = Vector2(conPos.x,conPos.y + deltaY)
end
function UIChooseAssistantPetSkinList:_endDragScrollBar(eventData)
    if self._disableDrag then
        return --去掉滑动功能
    end
    if self._count <= 1 then
        return
    end
    local finalIdx = 1
    if self._listOrderCmpt then
        local endPos = eventData.position
        local conEndPosY = self._DragBeginPos.y - (endPos.y - self._DragBeginPos.y)
        local conEndPos = Vector2(endPos.x,conEndPosY)
        finalIdx = self._listOrderCmpt:CalculateNewIndexByDragPos(self._DragBeginPos,conEndPos,self._curSelSkinIndex)
    end
    --finalIdx = self:_CalculateNewIndexByPos(eventData.position)
    self:_SelectSkinCellIdx(finalIdx)
    self:_SetMoveToCurSelIdx()
    self._isDarging = false
end