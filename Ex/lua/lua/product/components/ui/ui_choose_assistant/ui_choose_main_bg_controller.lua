---@class UIChooseMainBgController:UIController
_class("UIChooseMainBgController", UIController)
UIChooseMainBgController = UIChooseMainBgController

function UIChooseMainBgController:Constructor()
    self._itemCountPerRow = 1

    self._str2anim = {["OnShow"] = "uieff_Assistant_ChangeBg_In", ["OnHide"] = "uieff_Assistant_ChangeBg_Out"}
end

function UIChooseMainBgController:OnShow(uiParams)
    self._type = uiParams[1]

    self._pivot = Vector2(0.5,0.5)

    self:_GetComponents()

    self._itemModule = self:GetModule(ItemModule)
    self._roleModule = self:GetModule(RoleModule)
    self._currentMainBgID = self._roleModule:UI_GetMainBgID()
    if not Cfg.cfg_main_bg[self._currentMainBgID] then
        self._currentMainBgID = 1
    end

    self:_OnValue()
    self:_AttachEvent()
end
function UIChooseMainBgController:_AttachEvent()
    self:AttachEvent(GameEventType.OnMainCgChangeSave,self.OnMainCgChangeSave)
    self:AttachEvent(GameEventType.OnMainCgChangePos,self.OnMainCgChangePos)
    self:AttachEvent(GameEventType.OnMainCgChangeScale,self.OnMainCgChangeScale)
end
--type 1-cg,2-bg,11-2mainlobby(cg),22-2mainlobby(bg)  state 1-save,2-cancel,3-default
function UIChooseMainBgController:OnMainCgChangeSave(type,state)
    if type == UIChooseAssistantType.Change2Bg then
        if state == UIChooseAssistantState.Save then
            self._go:SetActive(true)
            --通知主界面保存当前背景偏移值
            --啥也不干
        elseif state == UIChooseAssistantState.Cancel then
            self._go:SetActive(true)
            --通知主界面还原之前偏移值
            --还原default到start，同主界面，同时设置表现
            self._defaultPos = self._startPos
            self._defaultScale = self._startScale
            self:TestOnMainCgChangePos()
            self:TestOnMainCgChangeScale()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Bg2MainLobby,self._defaultScale)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
        elseif state == UIChooseAssistantState.Default then
            --通知主界面还原默认偏移值
            --还原default和start到00，同主界面，同时设置表现
            self._defaultPos = Vector2(0,0)
            self._defaultScale = 1
            -- self._defaultPos = self._startPos
            -- self._defaultScale = self._startScale
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Bg2MainLobby,self._defaultScale)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
        end
    end
end
function UIChooseMainBgController:CalcImgInnerSafeArea(scale,pos,changeScale)
    --获得目标尺寸
    local _newSize = Vector2(math.floor(self._size.x*scale),math.floor(self._size.y*scale))
    local newScale = nil
    if _newSize.x < self._safeArea.x or _newSize.y < self._safeArea.y then
        --这个缩放值会导致宽高不对，先找到正确的缩放值，并返回回去
        local rate_x = self._safeArea.x/_newSize.x
        local rate_y = self._safeArea.y/_newSize.y
        if rate_x > rate_y then
            newScale = self._safeArea.x/self._size.x
        else
            newScale = self._safeArea.y/self._size.y
        end
        _newSize = Vector2(self._size.x*newScale,self._size.y*newScale)
    end
    --上边界不行
    local _up = math.floor(pos.y + (_newSize.y * (1-self._pivot.y))) < (self._safeArea.y * 0.5)
    local _left = math.floor(pos.x - (_newSize.x * (self._pivot.x))) > (self._safeArea.x * -0.5)
    local _right = math.floor(pos.x + (_newSize.x * (1-self._pivot.x))) < (self._safeArea.x * 0.5)
    local _down = math.floor(pos.y - (_newSize.y * (self._pivot.y))) > (self._safeArea.y * -0.5)

    if changeScale then
        return _up,_left,_right,_down,newScale
    else
        if not _up and not _left and not _right and not _down then
            return true
        end
    end
    return false
end
function UIChooseMainBgController:OnMainCgChangeScale(type,scale_off)
    if type == UIChooseAssistantType.Change2Bg then
        --计算是否可以缩放，可以再给主界面发消息
        local targetScale = self._defaultScale + scale_off
        if targetScale > 2 then
            targetScale = 2
        end
        local cantScale = false
        --需要调整
        local needChangePos = 0
        --region
        local up,left,right,down,newScale = self:CalcImgInnerSafeArea(targetScale,self._defaultPos,true)
        if     up and not left and not right and not down then
            --先缩小，再把他挪到上边界
            needChangePos = 2
        elseif up and left and not right and not down then
            --先缩小，再把他挪到左上边界
            needChangePos = 1
        elseif up and not left and right and not down then
            --先缩小，再把它挪到右上边界
            needChangePos = 3
        elseif not up and left and not right and not down then
            --先缩小，再把他挪到左边界
            needChangePos = 4
        elseif not up and left and not right and down then
            --先缩小，再把它挪到左下边界
            needChangePos = 7
        elseif not up and not left and right and not down then
            --先缩小，再把它挪到右边界
            needChangePos = 6
        elseif not up and not left and right and down then
            --先缩小，再把它挪到右下边界
            needChangePos = 9
        elseif not up and not left and not right and down then
            --先缩小，再把他挪到下边界
            needChangePos = 8
        elseif not up and not left and not right and not down then
            --先缩小
            needChangePos = 5
        else
            --不能缩
            cantScale = true
        end
        --endregion
        if not cantScale then
            if newScale then
                targetScale = newScale
            end
            self._defaultScale = targetScale
            self:TestOnMainCgChangeScale()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Bg2MainLobby,self._defaultScale)
            --这里先挪自己的defaultPos，然后testPos，然后给主界面发消息改defaultPos

            if needChangePos ~= 0 or needChangePos ~= 5 then
                local _newSize = Vector2(math.floor(self._size.x*self._defaultScale),math.floor(self._size.y*self._defaultScale))
                local gap = Vector2(0,0)
                if     needChangePos == 1 then
                    local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                    local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                    gap = Vector2(_x,_y)
                elseif needChangePos == 2 then
                    local _x = 0
                    local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                    gap = Vector2(_x,_y)
                elseif needChangePos == 3 then
                    local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                    local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                    gap = Vector2(_x,_y)
                elseif needChangePos == 4 then
                    local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                    local _y = 0
                    gap = Vector2(_x,_y)
                elseif needChangePos == 5 then
                elseif needChangePos == 6 then
                    local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                    local _y = 0
                    gap = Vector2(_x,_y)
                elseif needChangePos == 7 then
                    local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                    local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                    gap = Vector2(_x,_y)
                elseif needChangePos == 8 then
                    local _x = 0
                    local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                    gap = Vector2(_x,_y)
                elseif needChangePos == 9 then
                    local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                    local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                    gap = Vector2(_x,_y)
                end
                self._defaultPos = self._defaultPos + gap
                self:TestOnMainCgChangePos()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
            end
        end
    end
end
function UIChooseMainBgController:TestOnMainCgChangeScale()
    self._viewBg.localScale = Vector3(self._defaultScale, self._defaultScale, self._defaultScale)
end
function UIChooseMainBgController:OnMainCgChangePos(type,pos_off)
    if type == UIChooseAssistantType.Change2Bg then
        --计算是否可以移动，可以再给主界面发消息
        --x和y分开计算，手感
        local targetPos = self._defaultPos+pos_off
        local targetPos_x = self._defaultPos+Vector2(pos_off.x,0)
        local targetPos_y = self._defaultPos+Vector2(0,pos_off.y)
        if self:CalcImgInnerSafeArea(self._defaultScale,targetPos,false) then
            self._defaultPos = self._defaultPos+pos_off
            self:TestOnMainCgChangePos()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
        elseif self:CalcImgInnerSafeArea(self._defaultScale,targetPos_x,false) then
            self._defaultPos = targetPos_x
            self:TestOnMainCgChangePos()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
        elseif self:CalcImgInnerSafeArea(self._defaultScale,targetPos_y,false) then
            self._defaultPos = targetPos_y
            self:TestOnMainCgChangePos()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)
        end
    end
end
function UIChooseMainBgController:TestOnMainCgChangePos()
    self._viewBg.anchoredPosition = self._defaultPos
end
function UIChooseMainBgController:_GetComponents()
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "scrollView")
    self._anim = self:GetUIComponent("Animation", "UIChooseMainBgController")
    self._move1 = self:GetGameObject("move1")
    self._move2 = self:GetGameObject("move2")
    self._go = self:GetGameObject()
    ---@type UnityEngine.UI.Toggle
    self._tog = self:GetUIComponent("Toggle","Toggle")
    ---@type UnityEngine.RectTransform
    self._viewBg = self:GetUIComponent("RectTransform","viewBg")
end

function UIChooseMainBgController:moveBtnOnClick(go)
    if self._type == UIChooseAssistantBgType.Normal then
        return
    end
     self:ShowDialog("UIChooseMainCgController",UIChooseAssistantType.Change2Bg)
     self._go:SetActive(false)
end
function UIChooseMainBgController:_OnValue()
    local datas = {}
    local cfg_main_bg = Cfg.cfg_main_bg {Type=self._type}
    if cfg_main_bg and next(cfg_main_bg) then
        for i = 1, #cfg_main_bg do
            local unLock = true
            local data = {}
            local itemid = cfg_main_bg[i].ItemID
            if itemid then
                data.itemid = itemid
                local itemcount = self._itemModule:GetItemCount(itemid)
                if itemcount and itemcount > 0 then
                else
                    unLock = false
                end
            end
            
            if unLock then
                data.id = cfg_main_bg[i].ID
                data.bg = cfg_main_bg[i].BG
                data.name = cfg_main_bg[i].Name
                table.insert(datas, data)
            end
        end
    end
    if table.count(datas) < 5 then
        for i = 1, (5-table.count(datas)) do
            local data = {}
            --空
            data.id = 99999
            table.insert(datas, data)
        end
    end

    self._datas = {}
    self:_SortDatas(datas)
    self._dataCount = #self._datas

    self._currentChooseID = 0
    for i = 1, #self._datas do
        local _data = self._datas[i]
        if _data.id == self._currentMainBgID then
            self._currentChooseID = self._currentMainBgID
            break
        end
    end

    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()
    self._safeArea = Vector2(realWidth,realHeight)

    self:_InitScrollView()
    self:_ShowCgBgUI()
    self:ShowDialogAnim()
    self:GetPosAndScale()
    self:SetViewBg()
end
function UIChooseMainBgController:SetViewBg()
    self:TestOnMainCgChangePos()
    self:TestOnMainCgChangeScale()
end
function UIChooseMainBgController:_ShowCgBgUI()
    local petid = self._roleModule:GetResId()
    self._haveAs = true
    if petid and petid ~= 0 then
        if petid == -1 then
            self._haveAs = false
        end
    end
    --如果没有助理，tog不显示
    self._move2:SetActive(self._type == UIChooseAssistantBgType.Cg and self._haveAs and self._currentChooseID ~= 0)
    self._move1:SetActive(self._type == UIChooseAssistantBgType.Cg and self._currentChooseID ~= 0)
        --toggle
    --默认值
    local open_id = GameGlobal.GameLogic():GetOpenId()
    local key = "MAIN_BG_AS_ACTIVE"..open_id
    local state = LocalDB.GetInt(key,0)
    if state == 0 then
        self._togValue = true
    else
        self._togValue = false
    end
    self._tog.isOn = self._togValue

    if self._currentChooseID ~= 0 and self._type == UIChooseAssistantBgType.Cg and self._togValue then
        --主界面助理隐藏
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainLobbyHideAssistant,self._togValue)
    end

    self._tog.onValueChanged:AddListener(function(value)
        self:_OnToggleChange(value)
    end)
end
function UIChooseMainBgController:_OnToggleChange(value)
    self._togValue = value
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainLobbyHideAssistant,self._togValue)
end
function UIChooseMainBgController:ResetPosAndScale()    
    self._startPos = Vector2(0,0)
    self._startScale = 1
    local _id
    if self._currentChooseID == 0 then
        local _tmpid = self._roleModule:UI_GetMainBgID()
        if _tmpid == 0 then
            _tmpid = 1
        end
        _id = _tmpid
    else
        _id = self._currentChooseID
    end
    local cfg_mainBg = Cfg.cfg_main_bg[_id]
    if not cfg_mainBg then
        Log.error("###[UIChooseMainBgController] cfg is nil ! id --> ",_id)
    end
    --只有CG背景才
    if cfg_mainBg and cfg_mainBg.Type == UIChooseAssistantBgType.Cg then
        local open_id = GameGlobal.GameLogic():GetOpenId()
        local title = "MAIN_BG_OFFSET_"
        local key = title .. open_id .. "_" .. _id
        local pos_offset_str = LocalDB.GetString(key, "null")
        if pos_offset_str == "null" then
        else
            local strs = string.split(pos_offset_str, "|")
            local _x = tonumber(strs[1])
            local _y = tonumber(strs[2])
            self._startPos = Vector2(_x, _y)
            self._startScale = tonumber(strs[3])
        end
    end
    
    --如果这个缩放会导致当前背景就在屏幕里，那么修改这个缩放值，正比缩放，保证边界不在屏幕内
    --如果self._currentChooseID不等于0
    self._size = Vector2(2539,1439)
    local cfg = Cfg.cfg_main_bg[_id]
    if not cfg then
        Log.error("###[UIChooseMainBgController] cfg is nil ! id --> ",self._currentChooseID)
    end
    if cfg.Size then
        self._size = Vector2(cfg.Size[1],cfg.Size[2])
    end
    --如果size小于屏幕分辨率，则设为分辨率
    local rate_x = 1
    local rate_y = 1

    if self._size.x*self._startScale < self._safeArea.x then
        rate_x = self._size.x*self._startScale/self._safeArea.x
    end
    if self._size.y*self._startScale < self._safeArea.y then
        rate_y = self._size.y*self._startScale/self._safeArea.y
    end

    if rate_x < 1 or  rate_y < 1 then
        local changex = true
        if rate_x < rate_y then
            changex = true
        else
            changex = false
        end
        if changex then
            self._startScale = self._startScale/rate_x
        else
            self._startScale = self._startScale/rate_y
        end
    end
    self._defaultPos = self._startPos
    self._defaultScale = self._startScale

    self._viewBg.sizeDelta = self._size
end
function UIChooseMainBgController:GetPosAndScale()
    self:ResetPosAndScale()

    --缩放系数
    self._scaleK = 0.2
    self._touchScaleK = 0.001

    --缩放限制
    self._scaleMax = 1.5
    self._scaleMin = 0.5

    --移动系数
    self._moveK = 1
    --移动限制,动态计算
    -- self._moveMaxX = 1000
    -- self._moveMinX = -1000
    -- self._moveMaxY = 500
    -- self._moveMinY = -500

    --计算鼠标移动位置
    self._mousePos2 = 0
    self._mousePos = 0

    --动作
    self._scaling = false
    self._draging = false

    --手指移动位置
    self._touch0Pos = 0
    self._touch0Pos2 = 0

    --手指间距
    self._touchDis = 0
    self._touchDis2 = 0

    --算移动
    local pixels = Cfg.cfg_aircraft_camera["clickAndDragPixelLength"].Value
    self._startMove = pixels * pixels
end

function UIChooseMainBgController:_SortDatas(datas)
    local itemModule = GameGlobal.GetModule(ItemModule)
    local sortlist = datas
    local getItemFunc = function(id)
        local items = itemModule:GetItemByTempId(id)
        if items and table.count(items)>0 then
            for key, value in pairs(items) do
                return value
            end
        end
    end
    table.sort(sortlist,function(a,b)
        local a_id = a.id
        local b_id = b.id
        local priorityA = 0
        local priorityB = 0

        if self._currentMainBgID == a_id then
            priorityA = priorityA + 10000
        elseif self._currentMainBgID == b_id then
            priorityB = priorityA + 10000
        end

        local a_item_id = a.itemid
        if a_item_id then
            ---@type Item
            local item_data = getItemFunc(a_item_id)
            if item_data:IsNewOverlay() then
                priorityA = priorityA + 1000
            end
        end
        local b_item_id = b.itemid
        if b_item_id then
            ---@type Item
            local item_data = getItemFunc(b_item_id)
            if item_data:IsNewOverlay() then
                priorityB = priorityB + 1000
            end
        end

        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        return a_id < b_id
    end)
    self._datas = sortlist
end

function UIChooseMainBgController:_InitScrollView()
    if self._scrollView then
        self._scrollView:InitListView(
            self._dataCount,
            function(scrollView, index)
                return self:_InitListView(scrollView, index)
            end
        )
    end
end

function UIChooseMainBgController:_InitListView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIChooseMainBgItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local item = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._dataCount then
            item:GetGameObject():SetActive(false)
        else
            self:_ShowItem(item, itemIndex)
        end
    end
    return item
end

---@param item UIChooseMainBgItem
function UIChooseMainBgController:_ShowItem(item, index)
    local data = self._datas[index]
    item:GetGameObject():SetActive(true)
    if (data ~= nil) then
        item:SetData(
            data.id,
            data.itemid,
            data.id == self._currentMainBgID,
            data.bg,
            data.name,
            function(id)
                self:_ChooseOneBg(id)
            end
        )
    end
end

function UIChooseMainBgController:_ChooseOneBg(id)
    if self._currentChooseID == id then
        return
    end
    self._currentChooseID = id

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeMainBg, self._currentChooseID, true,false,false,false)
    --重置一下位置和缩放，通知主界面
    self:ResetPosAndScale()
    --设置中心点
    self:TestOnMainCgChangePos()
    self:TestOnMainCgChangeScale()
    
    if self._type == UIChooseAssistantBgType.Normal then
        return
    end
    
    --如果没有助理，tog不显示
    self._move2:SetActive(self._type == UIChooseAssistantBgType.Cg and self._haveAs and self._currentChooseID ~= 0)
    self._move1:SetActive(self._type == UIChooseAssistantBgType.Cg and self._currentChooseID ~= 0)
    if self._currentChooseID ~= 0 and self._togValue then
        --主界面助理隐藏
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainLobbyHideAssistant,self._togValue)
    end
end
function UIChooseMainBgController:cancelBtnOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeMainBg,false,false,false,false,self._togValue)
    --取消背景后要设置背景原来的位置，中心点，缩放
    -- self:ResetPosAndScale()
    -- self._defaultPos = self._startPos
    -- self._defaultScale = self._startScale
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Bg2MainLobby,self._defaultScale)
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Bg2MainLobby,self._defaultPos)

    self:CloseDialogAnim()
end

function UIChooseMainBgController:CloseDialogAnim()
    self:Lock("UIChooseMainBgController:CloseDialogAnim")
    self._anim:Play(self._str2anim["OnHide"])
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UIChooseMainBgController:CloseDialogAnim")
            self:CloseDialog()
        end,
        self
    )
end
function UIChooseMainBgController:ShowDialogAnim()
    self:Lock("UIChooseMainBgController:ShowDialogAnim")
    self._anim:Play(self._str2anim["OnShow"])
    self:StartTask(
        function(TT)
            YIELD(TT, 433)
            self:UnLock("UIChooseMainBgController:ShowDialogAnim")
        end,
        self
    )
end

function UIChooseMainBgController:saveBtnOnClick(go)
    local cancel = false
    if self._currentChooseID == 0 then
        cancel = true
    end
    if self._currentMainBgID == self._currentChooseID then
        cancel = true
    end
    if cancel then
        if self._haveAs and self._togValue and self._type == UIChooseAssistantBgType.Cg then
            self:HideAsReq()
        else
            --保存相当于取消,但是偏移要存
            local save = false
            if self._type == UIChooseAssistantBgType.Cg then
                save = true
            end
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeMainBg,false,false,true,save,true)
            self:CloseDialogAnim()
        end
    else
        self:Lock("UIChooseMainBgController:SaveBtnOnClick")
        GameGlobal.TaskManager():StartTask(self.OnSaveBtnOnClick, self)
    end
end
function UIChooseMainBgController:OnSaveBtnOnClick(TT)
    --这里表里一定有
    if not Cfg.cfg_main_bg[self._currentChooseID] then
        self._currentChooseID = 1
    end
    local param = {}
    param.nBackImageID = self._currentChooseID
    local res = self._roleModule:RequestRole_BackID(TT, param)
    self:UnLock("UIChooseMainBgController:SaveBtnOnClick")
    if res and res:GetSucc() then
        --保存助理状态,只有在当前的助理是显示状态才可用,否则不显示tog
        if self._haveAs and self._togValue and self._type == UIChooseAssistantBgType.Cg then
            self:HideAsReq()
        else 
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeMainBg, self._currentChooseID, true,true,true,true)
            self:SaveAsState()
            self:CloseDialogAnim()
        end
    else
        ToastManager.ShowToast("###[UIChooseMainBgController] OnSaveBtnOnClick fail ! result --> ", res:GetResult())
        Log.error("###[UIChooseMainBgController] OnSaveBtnOnClick fail ! result --> ", res:GetResult())
    end
end
function UIChooseMainBgController:HideAsReq()
    self:Lock("UIChooseMainBgController:HideAsReq()")
    GameGlobal.TaskManager():StartTask(self.OnHideAsReq,self)
end
function UIChooseMainBgController:OnHideAsReq(TT)
    local id = -1
    local grade = -1
    local skinID = -1
    local asID = -1
    local res = self._roleModule:RequestChoosePainting(TT, id, grade, skinID, asID)
    self:UnLock("UIChooseMainBgController:HideAsReq()")
    if res and res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeMainBg, self._currentChooseID, true,true,true,true)
        self:SaveAsState()
        self:CloseDialogAnim()
    else
        ToastManager.ShowToast("###[UIChooseMainBgController] HideAsReq fail ! result --> ", res:GetResult())
        Log.error("###[UIChooseMainBgController] HideAsReq fail ! result --> ", res:GetResult())
    end
end
function UIChooseMainBgController:SaveAsState()
    --默认值
    if not self._togValue then
        local open_id = GameGlobal.GameLogic():GetOpenId()
        local key = "MAIN_BG_AS_ACTIVE"..open_id
        LocalDB.SetInt(key,1)
    end
end
