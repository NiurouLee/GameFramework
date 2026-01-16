--
---@class UIReviewDownloadTip : UIController
_class("UIReviewDownloadTip", UIController)
UIReviewDownloadTip = UIReviewDownloadTip

---@param res AsyncRequestRes
function UIReviewDownloadTip:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end
--初始化
function UIReviewDownloadTip:OnShow(uiParams)
    self:InitWidget()
    ---@type UIReviewActivityBase
    self._data = uiParams[1]
    self.size:SetText(
        StringTable.Get(
            "str_review_download_tip_size",
            string.format("%.2f", self._data:DownloadPackageSize() / 1024 / 1024)
        )
    )
end
--获取ui组件
function UIReviewDownloadTip:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.size = self:GetUIComponent("UILocalizationText", "size")
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    --generated end--
end
--按钮点击
function UIReviewDownloadTip:CancelOnClick(go)
    self:CloseDialog()
end
--按钮点击
function UIReviewDownloadTip:ConfirmOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIReviewOnDownloadStart, self._data:ActivityID())
    self:CloseDialog()
end
