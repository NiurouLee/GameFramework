---@class UIChangeEmblazonryController:UIController
_class("UIChangeEmblazonryController", UIController)
UIChangeEmblazonryController = UIChangeEmblazonryController

function UIChangeEmblazonryController:OnShow(uiParams)

    self._playerInfo = uiParams[1]
    self._timeEvents = {}

    self:_GetComponents()
    self:_OnValue()
end

function UIChangeEmblazonryController:_GetComponents()
    self._anim = self:GetUIComponent("Animation", "anim")

    self._emblazonryGroup = self:GetUIComponent("UISelectObjectPath", "emblazonryGroup")
    self._showBg = self:GetUIComponent("RawImageLoader", "showBg")
    self._unlockText = self:GetUIComponent("UILocalizationText", "unlockText")
    self._LockIcon = self:GetGameObject( "LockIcon")
    self._changeBtn = self:GetGameObject( "changeBtn")
    self._UsingIconObj = self:GetGameObject( "UsingIcon")
    self._emblazonryScrollView = self:GetUIComponent("UIDynamicScrollView", "emblazonryScrollView")

    ---@type UISelectObjectPath
    local _leftUpper = self:GetUIComponent("UISelectObjectPath", "LeftUpper")
    ---@type UICommonTopButton
    self._backBtns = _leftUpper:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self._anim:Play("uieff_UIChangeEmblazonry_out")
            self:_LockAnim(167)
            GameGlobal.Timer():AddEvent(167,function()
                self:CloseDialog()
            end)
        end,
        nil
    )
end

function UIChangeEmblazonryController:_OnValue()
    --占位处理阈值
    self._emblazonryHoldCount = 15
    --每行3个
    self._itemCountPerRow = 3
    self._itemModule = self:GetModule(ItemModule)
    self._roleModule = self:GetModule(RoleModule)

    local datas = {}
    local idx = 0
    local cfg_Fifure = {}
    local cfgFifure = Cfg.cfg_item_fifure{}
    for k, v in pairs(cfgFifure) do
        cfg_Fifure[v.Order] = v
    end
    if cfg_Fifure and next(cfg_Fifure) then
        for k, v in pairs(cfg_Fifure) do
            local emblazonry = v
            local data = {}
            if emblazonry then
                local lock = true
                local itemid = emblazonry.ID
                idx = idx + 1
                local itemcount = self._itemModule:GetItemCount(itemid)
                if itemcount and itemcount > 0 then
                    lock = false
                end       
                data.itemid = itemid  
                local iconCfg = Cfg.cfg_item_fifure_extend[itemid]
                if iconCfg then
                    data.icon = Cfg.cfg_item_fifure_extend[itemid].ChangeFifureIcon
                else
                    Log.error("缺少纹饰图片-", itemid)
                end
                data.Order = idx
                data.lock = lock
                data.using = self._playerInfo.m_fifure_used == itemid
                data.desc = Cfg.cfg_item_fifure[itemid].Desc
                data.callback = function(itemid)
                    self:_ChooseOneEmblazonry(itemid)
                end

                datas[itemid] = data
            end
        end

        --处理占位
        if self._emblazonryHoldCount > idx then
            for i = 1, self._emblazonryHoldCount - idx do
                local data = {}
                data.itemid = -i
                data.Order = idx + i
                datas[-i] = data
            end
        end
    end

    self._itemTotalCount = math.max(self._emblazonryHoldCount,  idx)
    self._datas = datas
    --动画加锁
    self:_LockAnim(100 * self:GetRowCount())
    self:_InitEmblazonrySrollView()

    --默认选中用户当前使用的
    self:_ChooseOneEmblazonry(self._playerInfo.m_fifure_used)
end

function UIChangeEmblazonryController:_InitEmblazonrySrollView()
    self._emblazonryScrollView:InitListView(
        self:GetRowCount(),
        function(scrollView, index)
            return self:InitEmblazonryList(scrollView, index)
        end
    )
end

function UIChangeEmblazonryController:_GetItemFromOrder(order)
    for _, v in pairs(self._datas) do
        if v.Order == order then
            return v
        end
    end
    return nil
end

--计算一共多少行
function UIChangeEmblazonryController:GetRowCount()
    local row = math.ceil(self._itemTotalCount / self._itemCountPerRow)
    return row
end

function UIChangeEmblazonryController:InitEmblazonryList(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
    end

    GameGlobal.Timer():AddEvent(
        index * 100,
        function()
            rowPool:SpawnObjects("UIEmblazonryItem", self._itemCountPerRow)
            local rowList = rowPool:GetAllSpawnList()
            for i = 1, self._itemCountPerRow do
                ---@type UIHeadItem
                local heartItem = rowList[i]
                local itemIndex = index * self._itemCountPerRow + i
        
                self:ShowEmblazonryItem(heartItem, itemIndex)
            end
        end
    )
    return item
end

function UIChangeEmblazonryController:ShowEmblazonryItem(item, index)
    local itemData = self:_GetItemFromOrder(index)
    if itemData then
        item:SetData(self:_GetItemFromOrder(index))
    else
        item:GetGameObject():SetActive(false)
    end
end

function UIChangeEmblazonryController:OnHide()
    for key, value in pairs(self._timeEvents) do
        GameGlobal.Timer():CancelEvent(value)
    end
end

function UIChangeEmblazonryController:_ChooseOneEmblazonry(itemid)
    if self._currentChooseItemID == itemid then
        return
    end

    self._currentChooseItemID = itemid
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnEmblazonryItemSelect, self._currentChooseItemID)

    local PreviewFifureIcon = Cfg.cfg_item_fifure_extend[itemid].PreviewFifureIcon
    self._showBg:LoadImage(PreviewFifureIcon)

    self:RefreshChangeBtnStatus(itemid)
end

function UIChangeEmblazonryController:RefreshChangeBtnStatus(itemid)
    local isUsing = self._playerInfo.m_fifure_used == itemid
    local isLock = self._datas[itemid].lock
    self._LockIcon:SetActive(isLock)
    self._changeBtn:SetActive(not isUsing and not isLock)
    self._UsingIconObj:SetActive(isUsing and not isLock)
    self._unlockText:SetText(StringTable.Get(self._datas[itemid].desc))
end

function UIChangeEmblazonryController:changeBtnOnClick()
    self:Lock("UIChangeEmblazonryController:changeBtnOnClick")
    self:StartTask(self._ChangeEmblazonryTask, self)
end

function UIChangeEmblazonryController:_ChangeEmblazonryTask(TT)
    local res = self._roleModule:Request_TitleAndFifure(TT, 2, self._currentChooseItemID)
    self:UnLock("UIChangeEmblazonryController:changeBtnOnClick")
    if res and res:GetSucc() then
        ToastManager.ShowToast(StringTable.Get("str_player_info_change_emblazonry_succ"))
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPlayerEmblazonryChange, self._currentChooseItemID)
        self._playerInfo = self._roleModule:UI_GetPlayerInfo()
        self:RefreshChangeBtnStatus(self._currentChooseItemID)
    else
        ToastManager.ShowToast("###[UIChangeEmblazonryController] changeBtnOnClick fail ! result --> ", res:GetResult())
        Log.error("###[UIChangeEmblazonryController] changeBtnOnClick fail ! result --> ", res:GetResult())
    end
end

function UIChangeEmblazonryController:_LockAnim(timeLen)
    self:Lock("UIChangeTitleController_LockAnim")
    local te = GameGlobal.Timer():AddEvent(
        timeLen,
        function()
            self:UnLock("UIChangeTitleController_LockAnim")
        end
    )
    table.insert(self._timeEvents,te)
end
