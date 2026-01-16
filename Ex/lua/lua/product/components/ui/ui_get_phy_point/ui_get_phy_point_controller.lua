---@class UIGetPhyPointController:UIController
_class("UIGetPhyPointController", UIController)
UIGetPhyPointController = UIGetPhyPointController

function UIGetPhyPointController:LoadDataOnEnter(TT, res, uiParams)
    ---@type ShopModule
    self._shopModule = GameGlobal.GetModule(ShopModule)

    self._roleModule = self:GetModule(RoleModule)

    local req = self._shopModule:RequestPhysicalData(TT)
    if req:GetSucc() then
        res:SetSucc(true)
    else
        res:SetSucc(false)
    end
end

function UIGetPhyPointController:OnShow(uiParams)
    self._active = true
    self.down = false
    self:_GetComponents()
    --购买方式,1,左边，2，右边
    self._bugState = nil
    self._bugMaxCount = 999

    self:_OnValue()

    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
    self:AttachEvent(GameEventType.DiamondCountChanged, self.OnItemCountChange)
end

function UIGetPhyPointController:OnHide()
    self._active = false
end

function UIGetPhyPointController:_GetComponents()
    self._leftBeforeTex = self:GetUIComponent("UILocalizationText", "left_before")
    self._leftAfterTex = self:GetUIComponent("UILocalizationText", "left_after")
    self._leftAddTex = self:GetUIComponent("UILocalizationText", "left_add")
    self._leftCostTex = self:GetUIComponent("UILocalizationText", "left_cost")
    self._leftTipsTex = self:GetUIComponent("UILocalizationText", "left_tip")

    self._rightBeforeTex = self:GetUIComponent("UILocalizationText", "right_before")
    self._rightAfterTex = self:GetUIComponent("UILocalizationText", "right_after")
    self._rightAddTex = self:GetUIComponent("UILocalizationText", "right_add")
    self._rightCostTex = self:GetUIComponent("UILocalizationText", "right_cost")
    self._rightTipsTex = self:GetUIComponent("UILocalizationText", "right_tip")

    self._leftIconRaw = self:GetUIComponent("RawImageLoader", "left_icon")
    self._rightIconRaw = self:GetUIComponent("RawImageLoader", "right_icon")
    --长按
    self._subBtn = self:GetGameObject("left_subbtn")
    self._addBtn = self:GetGameObject("left_addbtn")
    self._isAddMouseDown = false
    self._isSubMouseDown = false
    local etlAdd = UILongPressTriggerListener.Get(self._addBtn)
    etlAdd.onLongPress = function(go)
        if self._isAddMouseDown == false then
            self._isAddMouseDown = true
        end
    end
    etlAdd.onLongPressEnd = function(go)
        if self._isAddMouseDown == true then
            self._isAddMouseDown = false
        end
    end
    etlAdd.onClick = function(go)
        self:Left_addClick()
    end
    ---------------------------------------------------------------
    local etlSub = UILongPressTriggerListener.Get(self._subBtn)
    etlSub.onLongPress = function(go)
        if self._isSubMouseDown == false then
            self._isSubMouseDown = true
        end
    end
    etlSub.onLongPressEnd = function(go)
        if self._isSubMouseDown == true then
            self._isSubMouseDown = false
        end
    end
    etlSub.onClick = function(go)
        self:Left_subClick()
    end
    ---------------------------
    --长安的间隔,毫秒,可以加到配置中
    self._pressTime = Cfg.cfg_global["sale_and_use_press_long_deltaTime"].IntValue
    --记录时间
    self._updateTime = 0

end

--长按操作
function UIGetPhyPointController:OnUpdate(deltaTimeMS)
    self._updateTime = self._updateTime + deltaTimeMS
    if self._updateTime > self._pressTime then
        self._updateTime = self._updateTime - self._pressTime
       
        if self._isAddMouseDown then
            self:Left_addClick()
        end
        if self._isSubMouseDown then
            self:Left_subClick()
        end
    end
end

function UIGetPhyPointController:_OnValue()
    self._left_data, self._right_data = self._shopModule:GetCurExchangePhyState()
    local allValid = self._shopModule:GetCurExchangePhyValidLeftState()
    for _, value in ipairs(allValid) do
        if self._roleModule:GetAssetCount(value.cost_id) > 0 then
            self._left_data = value
            break
        end
    end
    --id
    self._leftCostID = self._left_data.cost_id
    if not self._leftCostID then
        Log.fatal("###[UIGetPhyPointController] self._leftCostID is nil !")
    end
    local cfg_item = Cfg.cfg_item[self._leftCostID]
    if not cfg_item then
        Log.fatal("###[UIGetPhyPointController] cfg_item is nil ! id --> ", self._leftCostID)
    end
    --icon
    local left_icon = cfg_item.Icon
    self._leftIconRaw:LoadImage(left_icon)
    --left tips
    local left_count_now = 0
    for _, value in pairs(allValid) do
        left_count_now = left_count_now + self._roleModule:GetAssetCount(value.cost_id)
    end
    self._leftTipsTex:SetText(StringTable.Get("str_get_phy_point_current_have", left_count_now))
    --left cost
    self._left_cost_count = self._left_data.cost_count
    local left_cost_str
    if self._left_cost_count > left_count_now then
        left_cost_str = "<color=#ff0000>" .. self._left_cost_count .. "</color>"
    else
        left_cost_str = self._left_cost_count
    end
    self._leftCostTex:SetText(left_cost_str)
    --left add
    self._left_add = self._left_data.add_phy_count
    self._leftAddTex:SetText("+" .. self._left_add)
    --left number
    local current_phy_point = self._roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
    local current_phy_point_str
    if current_phy_point > 999 then
        current_phy_point_str = "999+"
    elseif current_phy_point < 0 then
        current_phy_point_str = "0"
    else
        current_phy_point_str = current_phy_point
    end
    self._leftBeforeTex:SetText(current_phy_point_str)
    local left_after_phy_point = current_phy_point + self._left_add
    local left_after_phy_point_str
    if left_after_phy_point > 999 then
        left_after_phy_point_str = "999+"
    elseif left_after_phy_point < 0 then
        left_after_phy_point_str = "0"
    else
        left_after_phy_point_str = left_after_phy_point
    end
    self._leftAfterTex:SetText(left_after_phy_point_str)

    --左侧材料可能有到期时间
    local left_dead_time = cfg_item.DeadTime
    if string.isnullorempty(left_dead_time) then
        left_dead_time = cfg_item.CompulsiveDeadTime
    end
    if not string.isnullorempty(left_dead_time) then
        local loginModule = self:GetModule(LoginModule)
        local time = loginModule:GetTimeStampByTimeStr(left_dead_time, Enum_DateTimeZoneType.E_ZoneType_GMT)
        local deltaTime = time - GetSvrTimeNow()
        if deltaTime > 0 then
            if self._refreshTimer then
                GameGlobal.Timer():CancelEvent(self._refreshTimer)
            end
            self._refreshTimer =
                GameGlobal.Timer():AddEvent(
                deltaTime * 1000,
                function()
                    self:StartTask(self._RequestAndRefresh, self)
                end
            )
        end
    end
    --right times
    self._getTimes = self._right_data.max_times - self._right_data.cur_times
    local getTimesMax = self._right_data.max_times

    self._right_cost_id = self._right_data.cost_id
    if not self._right_cost_id then
        Log.fatal("###[UIGetPhyPointController] self._right_cost_id is nil !")
    end
    self._right_cost_count = self._right_data.cost_count
    self._right_reply_count = self._right_data.add_phy_count

    --right id
    local cfg_item_right = Cfg.cfg_item[self._right_cost_id]
    if not cfg_item_right then
        Log.fatal("###[UIGetPhyPointController] cfg_item_right is nil ! id --> ", self._right_cost_id)
    end
    --right icon
    local right_icon = cfg_item_right.Icon
    self._rightIconRaw:LoadImage(right_icon)
    --right add
    self._rightAddTex:SetText("+" .. self._right_reply_count)
    --right tips
    local getTimesStr
    if self._getTimes <= 0 then
        getTimesStr = "<color=#ff0000>" .. self._getTimes .. "</color>"
    else
        getTimesStr = self._getTimes
    end
    local _right_tips = getTimesStr .. "/" .. getTimesMax
    self._rightTipsTex:SetText(StringTable.Get("str_get_phy_point_today_bug_times", _right_tips))
    --right cost
    local right_have_count = self._roleModule:GetAssetCount(self._right_cost_id)
    local right_cost_str
    if right_have_count < self._right_cost_count then
        right_cost_str = "<color=#ff0000>" .. self._right_cost_count .. "</color>"
    else
        right_cost_str = self._right_cost_count
    end
    self._rightCostTex:SetText(right_cost_str)
    --right number
    self._rightBeforeTex:SetText(current_phy_point_str)
    local right_after_phy_point = current_phy_point + self._right_reply_count
    local right_after_phy_point_str
    if right_after_phy_point > 999 then
        right_after_phy_point_str = "999+"
    elseif right_after_phy_point < 0 then
        right_after_phy_point_str = "0"
    else
        right_after_phy_point_str = right_after_phy_point
    end
    self._rightAfterTex:SetText(right_after_phy_point_str)
end

function UIGetPhyPointController:OnItemCountChange()
    local left_count_now = self._roleModule:GetAssetCount(self._leftCostID)
    local left_cost_str
    if self._left_cost_count > left_count_now then
        left_cost_str = "<color=#ff0000>" .. self._left_cost_count .. "</color>"
    else
        left_cost_str = self._left_cost_count
    end
    self._leftCostTex:SetText(left_cost_str)

    local right_have_count = self._roleModule:GetAssetCount(self._right_cost_id)
    local right_cost_str
    if right_have_count < self._right_cost_count then
        right_cost_str = "<color=#ff0000>" .. self._right_cost_count .. "</color>"
    else
        right_cost_str = self._right_cost_count
    end
    self._rightCostTex:SetText(right_cost_str)
end

function UIGetPhyPointController:bgOnClick()
    self:CloseDialog()
end

function UIGetPhyPointController:right_tips_btnOnClick()
    self:ShowDialog("UIGetPhyPointTipsController", self._right_data)
end
function UIGetPhyPointController:right_btnOnClick()
    local hasCount = self._roleModule:GetAssetCount(self._right_cost_id)
    if self._right_cost_count > hasCount then
        self:ShowDialog("UIShopCurrency1To2", self._right_cost_count - hasCount)
        return
    end

    if self._getTimes <= 0 then
        local tips = StringTable.Get("str_get_phy_point_bug_times_nil")
        ToastManager.ShowToast(tips)
        return
    end

    self._bugState = ExchangePhyPointType.EPPT_RIGHT
    local costId = self._right_cost_id
    local costCount = self._right_cost_count
    local replyId = RoleAssetID.RoleAssetPhyPoint
    local replyCount = self._right_reply_count
    self:TipsToast(costId, costCount, replyId, replyCount,0,0)
end
function UIGetPhyPointController:left_btnOnClick()
    local left_count_now = 0
    local allValid = self._shopModule:GetCurExchangePhyValidLeftState()
    for _, value in pairs(allValid) do
        left_count_now = left_count_now + self._roleModule:GetAssetCount(value.cost_id)
    end
    local not_expire_count = self._roleModule:GetAssetCount(3400043)--不限时的充能盒数量
    local other_count = left_count_now - not_expire_count

    if self._left_cost_count > left_count_now then  --self._roleModule:GetAssetCount(self._leftCostID)


        local cfg_item_cost = Cfg.cfg_item[self._leftCostID]

        local costName = StringTable.Get(cfg_item_cost.Name)

        local cfg_item_get = Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint]

        local getName = StringTable.Get(cfg_item_get.Name)

        local tips = StringTable.Get("str_get_phy_point_mat_not_enough", costName, getName)

        ToastManager.ShowToast(tips)
        return
    end

    self._bugState = ExchangePhyPointType.EPPT_LEFT
    local costId = self._leftCostID
    local costCount = self._left_cost_count
    local replyId = RoleAssetID.RoleAssetPhyPoint
    local replyCount = self._left_add
    self:TipsToast(costId, costCount, replyId, replyCount,not_expire_count,other_count)
end

function UIGetPhyPointController:TipsToast(cId, cCount, rId, rCount, nCount, oCount)
    local type = self._bugState
    local current_phy_point = self._roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
    if current_phy_point + rCount >= self._bugMaxCount then
        local cfg_item = Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint]
        local name = StringTable.Get(cfg_item.Name)
        local tips = StringTable.Get("str_get_phy_point_reply_fail_more_than", name)
        ToastManager.ShowToast(tips)
        return
    end

    local cfg_item_cost = Cfg.cfg_item[cId]
    local costName = StringTable.Get(cfg_item_cost.Name)
    local cfg_item_reply = Cfg.cfg_item[rId]
    local replyName = StringTable.Get(cfg_item_reply.Name)
    local cfg_item_not_expire = Cfg.cfg_item[3400043]
    local not_expire_name = StringTable.Get(cfg_item_not_expire.Name)
    local tips = StringTable.Get("str_get_phy_point_bug_toast_tips", cCount, costName, rCount, replyName)
    if type == 1 then
        if cCount > oCount and nCount ~= 0 and oCount ~= 0 then   
            tips = StringTable.Get("str_get_phy_point_bug_toast_another_tips", oCount, cCount-oCount, not_expire_name, rCount, replyName)
        end
    end
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        tips,
        function(param)
            self:Lock("UIGetPhyPointController:TipsToast")
            GameGlobal.TaskManager():StartTask(self.OnTipsToast, self, param)
        end,
        rCount,
        function(param)
            Log.debug("###[UIGetPhyPointController]TipsToast cancel ..")
        end,
        nil
    )
end

---@type ExchangePhyPointType
function UIGetPhyPointController:OnTipsToast(TT, param)
    local p = self._bugState
    local count = self._left_cost_count
    if p == 2 then
        count = 0
    end
    local res = self._shopModule:BuyPhysicalPower(TT, p, count)
    if res:GetSucc() then
        local cfg_item = Cfg.cfg_item[RoleAssetID.RoleAssetPhyPoint]
        local name = StringTable.Get(cfg_item.Name)
        local tips = StringTable.Get("str_get_phy_point_reply_succ_tips", name, param)
        ToastManager.ShowToast(tips)
        self._shopModule:RequestPhysicalData(TT)
        self:_OnValue()
        self:UnLock("UIGetPhyPointController:TipsToast")
    else
        local result = res:GetResult()
        Log.error("###[UIGetPhyPointController] OnTipsToast fail -- result --> ", result)
        local tips = StringTable.Get("str_get_phy_point_reply_fail_error_code") .. " - " .. result
        ToastManager.ShowToast(tips)
        self:UnLock("UIGetPhyPointController:TipsToast")
    end
end

function UIGetPhyPointController:_RequestAndRefresh(TT)
    self:Lock("UIGetPhyPointController:_RequestAndRefresh")
    local req = self._shopModule:RequestPhysicalData(TT)
    self:UnLock("UIGetPhyPointController:_RequestAndRefresh")
    if not self._active then
        return --界面已经关了，不处理了
    end
    if req:GetSucc() then
        self:_OnValue()
    else
        Log.error("###[UIGetPhyPointController] request refresh error:", req:GetResult())
    end
end

function UIGetPhyPointController:Left_addClick()
    if self._left_cost_count > 999 then
        return
    end
    local current_phy_point = self._roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
    if current_phy_point + self._left_add > 999 then
        return
    end
    local left_cost_str
    local left_count_now = 0
    local allValid = self._shopModule:GetCurExchangePhyValidLeftState()
    for _, value in pairs(allValid) do
        left_count_now = left_count_now + self._roleModule:GetAssetCount(value.cost_id)
    end

    if  self._left_cost_count + 1 > left_count_now then
        return
    end

    self._left_cost_count = self._left_cost_count + 1
    left_cost_str = self._left_cost_count

    self._leftCostTex:SetText(left_cost_str)
    self:LeftValueChange()
end

function UIGetPhyPointController:Left_subClick()
    if self._left_cost_count <= 1 then
        return
    end
    local left_cost_str
    local left_count_now = 0
    local allValid = self._shopModule:GetCurExchangePhyValidLeftState()
    for _, value in pairs(allValid) do
        left_count_now = left_count_now + self._roleModule:GetAssetCount(value.cost_id)
    end

    self._left_cost_count = self._left_cost_count - 1

    if self._left_cost_count > left_count_now then
        left_cost_str = "<color=#ff0000>" .. self._left_cost_count .. "</color>"
    else
        left_cost_str = self._left_cost_count
    end
    self._leftCostTex:SetText(left_cost_str)
    self:LeftValueChange()
end

function UIGetPhyPointController:LeftValueChange()
    self._left_add = self._left_data.add_phy_count*self._left_cost_count
    self._leftAddTex:SetText("+" .. self._left_add)

    local current_phy_point = self._roleModule:GetAssetCount(RoleAssetID.RoleAssetPhyPoint)
    local left_after_phy_point = current_phy_point + self._left_add
    local left_after_phy_point_str
    if left_after_phy_point > 999 then
        left_after_phy_point_str = "999+"
    elseif left_after_phy_point < 0 then
        left_after_phy_point_str = "0"
    else
        left_after_phy_point_str = left_after_phy_point
    end
    self._leftAfterTex:SetText(left_after_phy_point_str)
end
