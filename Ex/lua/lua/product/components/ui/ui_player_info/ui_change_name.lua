---@class UIChangeNameController:UIController
_class("UIChangeNameController", UIController)
UIChangeNameController = UIChangeNameController

function UIChangeNameController:OnShow(uiParams)
    ---@type PlayerRoleBaseInfo
    self._playerInfo = uiParams[1]

    self._cast_count = Cfg.cfg_global["change_chapter_name_cast"].IntValue or 200

    self._cast_id = Cfg.cfg_global["change_chapter_name_cast_item_id"].IntValue or 3000003

    self._nameMaxValue = Cfg.cfg_global["change_chapter_name_max_value_code"].IntValue or 14

    ---@type RoleModule
    self._roleModule = self:GetModule(RoleModule)

    local changeNameCount = self._roleModule:GetChangeNameTimes()

    Log.debug("###[UIChangeNameController] changeNameCount --> ", changeNameCount)

    ---TODO---首次改名
    self._firstChange = (changeNameCount <= 0)

    self:_GetComponents()
    self:_OnValue()
end
function UIChangeNameController:OnHide()
end
function UIChangeNameController:_GetComponents()
    self._castTexLeft = self:GetUIComponent("UILocalizationText", "castLeft")
    self._castTexRight = self:GetUIComponent("UILocalizationText", "castRight")
    self._castImg = self:GetUIComponent("Image", "castImg")
    ---@type UnityEngine.UI.InputField
    self._inputField = self:GetUIComponent("InputField", "changeName")
    self._rulerTex = self:GetUIComponent("UILocalizationText", "ruler")

    self._castNormal = self:GetGameObject("castLayout")
    self._castFirst = self:GetGameObject("castLayoutFirst")
    self._castTexLeftFirst = self:GetUIComponent("UILocalizationText", "castLeftFirst")
    self._castTexRightFirst = self:GetUIComponent("UILocalizationText", "castRightFirst")
    self._castImgFirst = self:GetUIComponent("Image", "castImgFirst")
end
function UIChangeNameController:_OnValue()
    local nameShowMaxValue = Cfg.cfg_global["change_chapter_name_max_value_view"].IntValue or 7
    self._rulerTex:SetText(string.format(StringTable.Get("str_player_info_the_name_ruler"), nameShowMaxValue))

    local itemName = ""
    local cfg_item = Cfg.cfg_item[self._cast_id]
    if cfg_item then
        itemName = StringTable.Get(cfg_item.Name)
    else
        Log.fatal("###playerinfo - cfg_item is nil ! id - ", self._cast_id)
    end
    local castStr = (self._cast_count .. " " .. itemName)
    local atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    local itemIcon = Cfg.cfg_global["change_chapter_name_cast_item_icon"].StrValue or "toptoon_3000003"

    self._castNormal:SetActive(not self._firstChange)
    self._castFirst:SetActive(self._firstChange)
    if self._firstChange then
        self._castTexLeftFirst:SetText(StringTable.Get("str_player_info_change_name_cast_first"))
        self._castTexRightFirst:SetText(castStr)
        self._castImgFirst.sprite = atlas:GetSprite(itemIcon)
    else
        self._castTexLeft:SetText(StringTable.Get("str_player_info_change_name_cast"))
        self._castTexRight:SetText(castStr)
        self._castImg.sprite = atlas:GetSprite(itemIcon)
    end

    ---@type UnityEngine.RectTransform
    --local inpTr = self._inputField.gameObject:GetComponent(typeof(UnityEngine.RectTransform))
    --local caret = inpTr:GetChild(0)
    --caret.localPosition = Vector2(5, 8)
    -- self._inputField.caretPosition = 5

    self._etl = UICustomUIEventListener.Get(self._inputField.gameObject)
    self:AddUICustomEventListener(
        self._etl,
        UIEvent.Press,
        function()
            if self._inputField.touchScreenKeyboard then
                pcall(self.ActiveKeyboard, self, false)
            end
        end
    )
    --[[

        self._etl.onClick = function()
            if string.len(self._inputField.text) <= 0 then
                self._inputField.placeholder.enabled = false
            end
        end
        ]]
    self._inputField.onEndEdit:AddListener(
        function()
            if string.len(self._inputField.text) <= 0 then
                self._inputField.placeholder.enabled = true
            end
        end
    )
    self._inputField.onValueChanged:AddListener(
        function()
            local s = self._inputField.text
            if string.match(s, " ") then
                ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
                s = string.gsub(s, " ", "")
            end
            self._inputField.text = s
        end
    )
end

function UIChangeNameController:ActiveKeyboard(active)
    self._inputField.touchScreenKeyboard.active = active
end
function UIChangeNameController:backOnClick()
    self:CloseDialog()
end

function UIChangeNameController:changeBtnOnClick()
    if self:CheckCreateNameError() then
        return
    end

    local idip_mng = self:GetModule(IdipgameModule)
    if idip_mng:TextBanHandle(IDIPBanType.IDIPBan_Nick) == true then
        return
    end
    --改名request
    self:Lock("UIChangeNameController:changeBtnOnClick")
    self:StartTask(self.OnchangeBtnOnClick, self)
end
function UIChangeNameController:CheckCreateNameError()
    -- 空名字
    if string.isnullorempty(self._inputField.text) then
        ToastManager.ShowToast(StringTable.Get("str_guide_create_no_name"))
        return true
    end
    self.newName = self._inputField.text
    -- 名字长度
    if HelperProxy:GetInstance():GetCharLength(self.newName) > self._nameMaxValue then
        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_LIMIT"))
        return true
    end
    local oldName = self._roleModule:GetName()
    if oldName == self.newName then
        ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_NEWNAME_THE_SAME_AS_OLD"))
        return true
    end

    if self._firstChange then
    else
        local mRole = GameGlobal.GetModule(RoleModule)
        local count = mRole:GetGlow()
        if count < self._cast_count then
            GameGlobal.UIStateManager():ShowDialog("UIShopCurrency1To2", self._cast_count - count)
            return true
        end
    end
    return false
end

function UIChangeNameController:OnchangeBtnOnClick(TT)
    local res = self._roleModule:Request_AmendRoleName(TT, self.newName)
    self:UnLock("UIChangeNameController:changeBtnOnClick")
    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnChapcterInfoChanged)
        ToastManager.ShowToast(StringTable.Get("str_player_info_change_name_succ"))
        self:CloseDialog()
    else
        local errorCode = res:GetResult()
        Log.fatal("###playerinfo - RequestChangeName fail ! result - ", errorCode)

        if errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_INVALID then --     -- 名字含有其他国家的文字 只能是中文 日文 数字 英文字母
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_LIMIT then -- // 名字最大长度不能超过16个字符(英文16个中文8个)
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_LIMIT"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DIRTY_NICK then --  // 名字含有敏感字
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_DIRTY_NICK"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_REPEAT then -- // 该角色已经拥有名字
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_REPEAT"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_SPE then -- // 名字含有特殊字符
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_SPE"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DUPLICATE_NICK then -- //  // 重名
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_DUPLICATE_NICK"))
        end
    end
end
