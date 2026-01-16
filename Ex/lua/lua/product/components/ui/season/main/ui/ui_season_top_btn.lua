--
---@class UISeasonTopBtn : UICustomWidget
_class("UISeasonTopBtn", UICustomWidget)
UISeasonTopBtn = UISeasonTopBtn
--初始化
function UISeasonTopBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonTopBtn:InitWidget()
    self._home = self:GetGameObject("Home")
    self._hide = self:GetGameObject("Hide")
    self._help = self:GetGameObject("Help")
    self._video = self:GetGameObject("Video")
end

--设置数据
function UISeasonTopBtn:SetData(backCB, homeCB, hideCB, helpCB, videoCB)
    self._backCB = backCB
    self._homeCB = homeCB
    self._hideCB = hideCB
    self._helpCB = helpCB
    self._videoCB = videoCB
    self._home:SetActive(self._homeCB ~= nil)
    self._hide:SetActive(self._hideCB ~= nil)
    self._help:SetActive(self._helpCB ~= nil)
    self._video:SetActive(self._videoCB ~= nil)
end

--按钮点击
function UISeasonTopBtn:BackOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundCancel)
    self._backCB()
end

--按钮点击
function UISeasonTopBtn:HomeOnClick()
    if self._homeCB then
        self._homeCB()
    end
end

--按钮点击
function UISeasonTopBtn:HideOnClick()
    if self._homeCB then
        self._hideCB()
    end
end

--按钮点击
function UISeasonTopBtn:HelpOnClick()
    if self._helpCB then
        self._helpCB()
    end
end

function UISeasonTopBtn:VideoOnClick()
    if self._videoCB then
        self._videoCB()
    end
end
