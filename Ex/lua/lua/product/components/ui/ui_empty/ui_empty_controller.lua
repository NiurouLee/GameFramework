---@class UIEmptyController:UIController
_class("UIEmptyController", UIController)
UIEmptyController = UIEmptyController

--传进来一个回调(一般用于关闭,暂时没有参数),第二个参数为是否切后台时调用(默认false)
function UIEmptyController:OnShow(uiParams)
    self._pos = self:GetUIComponent("RectTransform", "pos")
    self._safe = self:GetUIComponent("RectTransform", "SafeArea")

    local pos = uiParams[1]
    local size = uiParams[2]

    if self._pos then
        self._pos.position = pos + self._safe.position
        self._pos.sizeDelta = size
    end

    self._callback = uiParams[3]

    if uiParams[5] then
        self._homeCall = uiParams[4]
    else
        self._homeCall = false
    end
    self:UnLock("UIPowerOpened")
end

function UIEmptyController:Dispose()
    --切后台回调
    --self:DetachEvent(GameEventType.AppHome, self.OnAppHome)
end

function UIEmptyController:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIEmptyClose)
end

function UIEmptyController:Constructor()
    --切后台回调
    --self:AttachEvent(GameEventType.AppHome, self.OnAppHome)
end

function UIEmptyController:bgOnClick()
    if self._callback then
        self:_callback()
    end
    self:CloseDialog()
end

--切后台回调
function UIEmptyController:OnAppHome()
    if self._homeCall then
        self:bgOnClick()
    end
end
