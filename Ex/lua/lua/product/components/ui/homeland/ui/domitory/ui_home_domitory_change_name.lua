---@class UIHomeDomitoryChangeName : UIController
_class("UIHomeDomitoryChangeName", UIController)
UIHomeDomitoryChangeName = UIHomeDomitoryChangeName
function UIHomeDomitoryChangeName:OnShow(uiParams)
    self:InitWidget()

    self._roomIdx = uiParams[1]
    self.roomName.text = ""
end
function UIHomeDomitoryChangeName:InitWidget()
    --generated--
    ---@type EmojiFilteredInputField
    self.roomName = self:GetUIComponent("EmojiFilteredInputField", "roomName")
    --generated end--
end
function UIHomeDomitoryChangeName:bgOnClick(go)
    self:CloseDialog()
end
function UIHomeDomitoryChangeName:btnCancelOnClick(go)
    self:CloseDialog()
end
function UIHomeDomitoryChangeName:btnEnsureOnClick(go)
    self:StartTask(self.change, self)
end

function UIHomeDomitoryChangeName:change(TT)
    local str = self.roomName.text
    if string.isnullorempty(str) then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_domitory_name_illegal2"))
        return
    end
    local length = HelperProxy:GetInstance():GetCharLength(str)
    if length > 12 then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_domitory_name_illegal1"))
        return
    end
    local res = self:GetModule(HomelandModule):DormitoryChangeName(TT, self._roomIdx, str)
    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.HomeDomitoryRefreshRoom)
        self:CloseDialog()
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_domitory_name_changed"))
    else
        local errorCode = res:GetResult()
        Log.fatal("###domitory - RequestChangeName fail ! result - ", errorCode)
        if errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_LIMIT then -- // 名字最大长度不能超过16个字符(英文16个中文8个)
            ToastManager.ShowHomeToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_LIMIT"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_DIRTY_NICK then --  // 名字含有敏感字
            ToastManager.ShowHomeToast(StringTable.Get("str_guide_ROLE_ERROR_DIRTY_NICK"))
        elseif errorCode == ROLE_RESULT_CODE.ROLE_ERROR_CHANGE_NICK_INVALID then --名字含有其他国家的文字 只能是中文 日文 数字 英文字母
            ToastManager.ShowToast(StringTable.Get("str_guide_ROLE_ERROR_CHANGE_NICK_INVALID"))
        else
            ToastManager.ShowHomeToast(res:GetResult())
        end
    end
end
