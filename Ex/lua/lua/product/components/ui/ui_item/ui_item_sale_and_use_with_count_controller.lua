_class("UIItemSaleAndUseWithCountController", UIController)
---@class UIItemSaleAndUseWithCountController: UIController
UIItemSaleAndUseWithCountController = UIItemSaleAndUseWithCountController

---@param uiParams table 参数[1]-物品信息 [2]-openType-EnumItemSaleAndUseState  出售:使用 [3]-点击事件
function UIItemSaleAndUseWithCountController:OnShow(uiParams)
    -----------------------------------------------------------------------------
    ---@type Item
    self._itemdata = uiParams[1]

    self._openType = uiParams[2]

    self._callBack = uiParams[3]

    self._itemID = self._itemdata:GetID()

    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)

    self._inputItemCount = self:GetUIComponent("InputField", "input_item_count")
    self._txtItemName = self:GetUIComponent("UILocalizationText", "txt_item_name")
    self._itemCountText = self:GetUIComponent("UILocalizationText", "itemCount")

    self:DoAnimation()

    self._saleGo = self:GetGameObject("sale")
    self._useGo = self:GetGameObject("use")

    if self._openType == EnumItemSaleAndUseState.Sale then
        -- 出售
        self._useGo:SetActive(false)
        self._itemSaleMoney = self:GetUIComponent("UILocalizationText", "txt_sale_money")
    else
        --使用
        self._saleGo:SetActive(false)
    end

    local templetaData = self._itemdata:GetTemplate()
    self._itemCount = self._itemdata:GetCount()
    self._itemCountText:SetText(
        StringTable.Get("str_item_public_owned") ..
            UIItemSaleAndUseWithCountController._FormatItemCount(self._itemCount)
    )
    self._itemPerPiece = templetaData.SaleGold
    self._txtItemName:SetText(StringTable.Get(templetaData.Name))
    local icon = templetaData.Icon
    local quality = templetaData.Color
    local itemId = templetaData.ID
    self.uiItem:SetData({icon = icon, quality = quality, itemId = itemId})
    self._currentCount = 1

    --设置键盘为数字键盘,没有导出UnityEngine.TouchScreenKeyboardType的枚举值
    self._inputItemCount.keyboardType = UnityEngine.TouchScreenKeyboardType.NumberPad
    self._inputItemCount.onValueChanged:AddListener(
        function(inputString)
            self:OnValueChange(inputString)
        end
    )
    self:SetInputText(self._currentCount)

    self._addBtn = self:GetGameObject("addBtn")
    self._subBtn = self:GetGameObject("subBtn")

    self._isAddMouseDown = false
    self._isSubMouseDown = false

    --长按
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
        self:itemaddOnClick()
    end
    ----------------
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
        self:itemsubOnClick()
    end
    ---------------------------
    --长安的间隔,毫秒,可以加到配置中
    self._pressTime = Cfg.cfg_global["sale_and_use_press_long_deltaTime"].IntValue
    --记录时间
    self._updateTime = 0
end

--动画
function UIItemSaleAndUseWithCountController:DoAnimation()
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "panel")
    self._canvasGroup.alpha = 1

    --[[

        self._pointBg = self:GetUIComponent("RectTransform", "pointBg")
        self._pointBg.localScale = Vector3(1.5, 1.5, 1.5)
        self._pointBg:DOScale(Vector3(1, 1, 1), 0.3)
        ]]
    self._bg = self:GetUIComponent("RectTransform", "bg")

    self._panel = self:GetUIComponent("RectTransform", "panel")
    self._panel.localScale = Vector3(0.5, 0.5, 0.5)
    self._panel:DOScale(Vector3(1, 1, 1), 0.3):OnComplete(
        function()
            self._bg:DOPunchScale(Vector3(0.1, 0.1, 0.1), 0.3)
        end
    )
end

---@private
---@param itemCount number
---@return string
function UIItemSaleAndUseWithCountController._FormatItemCount(itemCount)
    return HelperProxy:GetInstance():FormatItemCount(itemCount)
end

--TODO 一个操作显示数量的接口
function UIItemSaleAndUseWithCountController:SetInputText(count)
    if count == nil then
        return
    end
    if count < 1 then
        count = 1
    elseif count > self._itemCount then
        count = self._itemCount
    end
    self._currentCount = count
    self._inputItemCount.text = tostring(self._currentCount)

    if self._openType == 1 then
        local allPrice
        if self._currentCount * self._itemPerPiece > 99999999 then
            allPrice = "9999" .. StringTable.Get("str_item_public_unit")
        else
            allPrice = tostring(self._currentCount * self._itemPerPiece)
        end
        self._itemSaleMoney:SetText(tostring(allPrice))
    end
end

function UIItemSaleAndUseWithCountController:OnValueChange(inputString)
    local num = 0
    if inputString == nil then
        num = 1
    elseif inputString == "" then
        num = 1
    else
        num = tonumber(inputString)
    end

    if num < 1 then
        num = 1
    else
        num = self:_ComputeMaxItemCount(num)
    end

    self:SetInputText(num)
end

--长按操作
function UIItemSaleAndUseWithCountController:OnUpdate(deltaTimeMS)
    self._updateTime = self._updateTime + deltaTimeMS
    if self._updateTime > self._pressTime then
        self._updateTime = self._updateTime - self._pressTime
        if self._isAddMouseDown then
            self:itemaddOnClick()
        end
        if self._isSubMouseDown then
            self:itemsubOnClick()
        end
    end
end

function UIItemSaleAndUseWithCountController:_ComputeMaxItemCount(nCount)
    local itemData = self._itemdata:GetTemplate()
    local stUseEffect = itemData.UseEffect
    local nMaxLimitCount = 99
    local isPhy = false
    if stUseEffect == "PhyGift" then
        isPhy = true
        nMaxLimitCount = 1
        ---@type RoleModule
        local roleModule = self:GetModule(RoleModule)
        ---@type ItemModule
        local itemModule = self:GetModule(ItemModule)
        local nPhyData = roleModule:GetHealthPoint()
        local cfgRoleLevel = Cfg.cfg_role_level[roleModule:GetLevel()]
        if cfgRoleLevel then
            local nPhyMaxLevel = cfgRoleLevel.TotalMaxPhyPoint or 100
            local nPhyMaxLimit = Cfg.cfg_global["role_phy_max_limit"].IntValue or 999
            local nPhyMax = 0
            if nPhyMaxLimit > nPhyMaxLevel then
                nPhyMax = nPhyMaxLevel
            else
                nPhyMax = nPhyMaxLimit
            end
            if nPhyMax > nPhyData then
                local nPhyEffect = itemModule:GetPhyGiftData(itemData.ID)
                if nPhyEffect > 0 then
                    local nMaxCount = (nPhyMax - nPhyData) / nPhyEffect --itemData.
                    nMaxLimitCount = math.floor(nMaxCount)
                end
            end
        end
    end
    if nCount > nMaxLimitCount then
        if isPhy then
            local tips = StringTable.Get("str_item_public_use_phy_more_than_max")
            ToastManager.ShowToast(tips)
        end
        return nMaxLimitCount
    end
    return nCount
end

function UIItemSaleAndUseWithCountController:itemaddOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._inputItemCount.text == nil then
        self._inputItemCount.text = "1"
    end
    local num = tonumber(self._inputItemCount.text)
    num = self:_ComputeMaxItemCount(num + 1)
    self:SetInputText(num)
end
function UIItemSaleAndUseWithCountController:itemsubOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._inputItemCount.text == nil then
        self._inputItemCount.text = "1"
    end
    local num = tonumber(self._inputItemCount.text)
    if num > 1 then
        num = num - 1
    else
        num = 1
    end
    self:SetInputText(num)
end
function UIItemSaleAndUseWithCountController:itemmaxOnClick()
    if self._inputItemCount.text == nil then
        self._inputItemCount.text = "1"
    end
    local num = tonumber(self._inputItemCount.text)
    num = self:_ComputeMaxItemCount(self._itemCount)
    self:SetInputText(num)
end
--出售物品
function UIItemSaleAndUseWithCountController:itemsaleOnClick()
    if self._currentCount ~= 0 then
        self._callBack(self._itemdata, self._currentCount)
    end
    self:ClosePanel()
end

--关闭animation
function UIItemSaleAndUseWithCountController:ClosePanel(TT)
    GameGlobal.TaskManager():StartTask(self.OnClosePanel, self)
end
function UIItemSaleAndUseWithCountController:OnClosePanel(TT)
    if self._exit then
        return
    end
    self._exit = true
    local a = 1
    while a > 0 do
        a = a - 0.05
        self._canvasGroup.alpha = a
        YIELD(TT)
    end
    YIELD(TT)
    self._exit = false
    self:CloseDialog()
end

--使用物品
function UIItemSaleAndUseWithCountController:itemuseOnClick()
    if self._currentCount ~= 0 then
        self._callBack(self._itemdata, self._currentCount)
    end
    self:ClosePanel()
end

function UIItemSaleAndUseWithCountController:closeOnClick()
    self:ClosePanel()
end
