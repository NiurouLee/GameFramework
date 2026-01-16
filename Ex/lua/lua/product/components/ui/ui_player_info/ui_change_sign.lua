---@class UIChangeSignController:UIController
_class("UIChangeSignController", UIController)
UIChangeSignController = UIChangeSignController

function UIChangeSignController:OnShow(uiParams)
    ---@type PlayerRoleBaseInfo
    self._playerInfo = uiParams[1]

    ---@type RoleModule
    self._roleModule = self:GetModule(RoleModule)

    -- self._signUpper = Cfg.cfg_global["ui_player_info_sign_upper"].IntValue or 150
    --ui的服务器用不了，改为用枚举值
    self._signUpper = EnumMaxStringLen.E_MaxString_SignText

    self:_GetComponents()
    self:_OnValue()
end
function UIChangeSignController:OnHide()
end
function UIChangeSignController:_GetComponents()
    self._oldSignTex = self:GetUIComponent("UILocalizationText", "oldSign")
    ---@type UnityEngine.UI.InputField
    self._inputField = self:GetUIComponent("InputField", "changeSign")
    self._rulerTex = self:GetUIComponent("UILocalizationText", "ruler")
end
function UIChangeSignController:_OnValue()
    local maxValue = Cfg.cfg_global["change_chapter_sign_max_value_view"].IntValue or 50
    -- self._rulerTex:SetText(string.format(StringTable.Get("str_player_info_the_sign_ruler"), maxValue))
    self._rulerTex:SetText("")

    self._oldSign = self._playerInfo.m_stSignText

    --暂时不显示旧的签名
    --self._oldSignTex:SetText(self._oldSign)

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
end
function UIChangeSignController:ActiveKeyboard(active)
    self._inputField.touchScreenKeyboard.active = active
end

function UIChangeSignController:backOnClick()
    self:CloseDialog()
end

function UIChangeSignController:changeBtnOnClick()
    if self:CheckSignError() then
        return
    end

    local idip_mng = self:GetModule(IdipgameModule)
    if idip_mng:TextBanHandle(IDIPBanType.IDIPBan_Signs) == true then
        return
    end

    --改签名request
    self:Lock("UIChangeSignController:changeBtnOnClick")
    self:StartTask(self.OnchangeBtnOnClick, self)
end
function UIChangeSignController:CheckSignError()
    --[[
        -- 空签名
        if string.isnullorempty(self._inputField.text) then
            ToastManager.ShowToast(StringTable.Get("str_player_info_change_sign_kong"))
            return true
        end
        ]]
    self.newSign = self._inputField.text
    -- 签名长度
    if string.len(self.newSign) > self._signUpper then
        ToastManager.ShowToast(StringTable.Get("str_player_info_change_sign_chaoguo"))
        return true
    end
    if self._oldSign == self.newSign then
        ToastManager.ShowToast(StringTable.Get("str_player_info_change_sign_same"))
        return true
    end
    return false
end

function UIChangeSignController:OnchangeBtnOnClick(TT)
    local res = self._roleModule:Request_AmendSignText(TT, self.newSign)
    self:UnLock("UIChangeSignController:changeBtnOnClick")
    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnChapcterInfoChanged)
        ToastManager.ShowToast(StringTable.Get("str_player_info_change_sign_succ"))
        self:CloseDialog()
    else
        local errorCode = res:GetResult()
        Log.fatal("###playerinfo - RequestChangeName fail ! result - ", errorCode)

        if errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_INVALID then --     -- 名字含有其他国家的文字 只能是中文 日文 数字 英文字母
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DIRTY_NICK then --  // 名字含有敏感字
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_DIRTY_NICK"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_SPE then -- // 名字含有特殊字符
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_SPE"))
        end
    end
end
