---@class UIIndulgeModule:UIModule
_class("UIIndulgeModule", UIModule)
UIIndulgeModule = UIIndulgeModule

local eCode = 100 --c#里面没有枚举，100表示退出登录

function UIIndulgeModule:Constructor()
    self._modal = false --web是否模态
    self._Module = self:GetModule(IndulgeModule)

    self:AttachEvent(GameEventType.IndulgeDataEvent, self.HandleData)
    self:AttachEvent(GameEventType.SwitchUIStateFinish, self.UIHandle)

    --注册回调
    self._NoticeRetEvent = function(ret)
        self:NoticeRetEvent(ret)
    end
    
    SDKProxy:GetInstance():WebViewRetEvent(self._NoticeRetEvent, true)
end

function UIIndulgeModule:Dispose()
    SDKProxy:GetInstance():WebViewRetEvent(self._NoticeRetEvent, false)
end

---#请求webview的回调
---@param ret MSDKWebViewRet
function UIIndulgeModule:NoticeRetEvent(ret)
    Log.debug("[indulge] ", "NoticeRetEvent type:", ret.MsgType, ", modal", (self._modal and "true" or "false"))
    if self._modal == false then
        return
    end
    self._modal = false
    if ret.MsgType ~= eCode then
        return
    end

    if GameGlobal.UIStateManager():CurUIStateType() == UIStateType.LoginEmpty then
        --nil
    else
        GameGlobal.GameLogic():BackToLogin(false, LoginModule, "player logout", false)
    end
end

--处理消息
function UIIndulgeModule:HandleData()
    self:ShowUI()
end

--注意：：：：
function UIIndulgeModule:UIHandle(uiStateType)
    self:ShowUI()
end

function UIIndulgeModule:ShowUI()
    if self._Module == nil or self._Module:IsIndulge() == false then
        return
    end

    local curUIState = GameGlobal.UIStateManager():CurUIStateType()
    if curUIState == UIStateType.BattleLoading or curUIState == UIStateType.UIBattle then --在战斗内不显示
        return
    end

    local info = self._Module:GetAndClearInfo()
    if info == nil then
        return
    end

    self._modal = false

    Log.debug("[indulge] ", "indulge type:", info.type, ", title:", info.title, ", msg:", info.msg, ", url:", info.url)
    if info.type == IndulgeRes.Tips then
        self:HandleTips(info)
    elseif info.type == IndulgeRes.Logout then
        self:HandleLogout(info)
    elseif info.type == IndulgeRes.OpenUrl then
        self._modal = (info.modal == 1 and true or false)
        self:HandleOpenUrl(info)
    else
        Log.error("UIIndulgeModule type error")
    end
end

function UIIndulgeModule:HandleTips(info)
    PopupManager.Alert("UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, info.title, info.msg)
end

function UIIndulgeModule:HandleLogout(info)
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.Ok,
        info.title,
        info.msg,
        function()
            if GameGlobal.UIStateManager():CurUIStateType() == UIStateType.LoginEmpty then
                --nil
            else
                GameGlobal.GameLogic():BackToLogin(false, LoginModule, "player logout", false)
            end
        end
    )
end

function UIIndulgeModule:HandleOpenUrl(info)
    --[[PopupManager.Alert(
        "UICommonMessageBox", PopupPriority.Normal, PopupMsgBoxType.Ok, info.title, info.msg,
        function ()
            GameGlobal.GameLogic():BackToLogin(
                false,
                LoginModule,
                "player logout",
                false
            )

			SDKProxy:GetInstance():OpenUrl(info.url);
        end
        );--]]
    SDKProxy:GetInstance():OpenUrl(info.url)
end
