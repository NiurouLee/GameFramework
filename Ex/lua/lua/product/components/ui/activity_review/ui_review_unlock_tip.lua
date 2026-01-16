--
---@class UIReviewUnlockTip : UIController
_class("UIReviewUnlockTip", UIController)
UIReviewUnlockTip = UIReviewUnlockTip

---@param res AsyncRequestRes
function UIReviewUnlockTip:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end
--初始化
function UIReviewUnlockTip:OnShow(uiParams)
    self:InitWidget()
    ---@type UIReviewActivityBase
    self._data = uiParams[1]
    self._customTips = uiParams[2]

    

    ---@type UICommonTopButton
    local topWidget = self.topBtn:SpawnObject("UICommonTopButton")
    topWidget:SetData(
        function()
            self:CloseDialog()
        end
    )
    self._topCurrency = self.toptips:SpawnObject("UICurrencyMenu")
    self._topCurrency:SetData({RoleAssetID.RoleAssetActiveToken})

    self.title:SetText(self._data:Title())
    local cfg = Cfg.cfg_activity_review[self._data:ActivityID()]
    if not cfg then
        ReviewError("cfg_activity_review中找不到配置：", self._data:ActivityID())
    end
    self.icon:LoadImage(cfg.UnlockIcon)
    self.des:SetText(StringTable.Get(cfg.UnlockDes))
    self._asset = self._data:UnlockCost()
    self.itemcount:SetText(self._asset.count)
    if self._data:CanUnlock() then
        self.itemcount.color = Color.green
    else
        self.itemcount.color = Color.red
    end

    self._unlockBtn = self:GetGameObject("UnlockBtn")
    self._customTipsBtn = self:GetGameObject("CustomTipsBtn")
    if self._customTips then
        self._unlockBtn:SetActive(false)
        self._customTipsBtn:SetActive(true)
        local customTips = self:GetUIComponent("UILocalizationText", "CustomTips")
        local progress = self:GetUIComponent("UILocalizationText", "Progress")
        customTips:SetText(self._customTips[1])
        progress:SetText(self._customTips[2])
    else
        self._unlockBtn:SetActive(true)
        self._customTipsBtn:SetActive(false)
    end
end
--获取ui组件
function UIReviewUnlockTip:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.topBtn = self:GetUIComponent("UISelectObjectPath", "topBtn")
    ---@type UICustomWidgetPool
    self.toptips = self:GetUIComponent("UISelectObjectPath", "toptips")
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    ---@type UILocalizationText
    self.des = self:GetUIComponent("UILocalizationText", "des")
    ---@type UILocalizationText
    self.itemcount = self:GetUIComponent("UILocalizationText", "itemcount")
    --generated end--
end
--按钮点击
function UIReviewUnlockTip:UnlockBtnOnClick(go)
    if self._data:CanUnlock() then
        self:StartTask(self._ReqUnlock, self)
    else
        local cfg = Cfg.cfg_item[self._asset.assetid]
        ToastManager.ShowToast(StringTable.Get("str_review_cant_unlock", StringTable.Get(cfg.Name)))
    end
end

function UIReviewUnlockTip:_ReqUnlock(TT)
    self:Lock(self:GetName())
    local res = GameGlobal.GetModule(CampaignModule):HandUnlockReviewCampaign(TT, self._data:ActivityID())
    self:UnLock(self:GetName())
    if res:GetSucc() then
        ---@type UICampaignModule
        local uiModule = GameGlobal.GetUIModule(CampaignModule)
        uiModule:GetReviewData():OnActivityUnlock(self._data)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIReviewOnUnlock, self._data:ActivityID())
        self:CloseDialog()
    else
        Log.fatal("请求解锁活动失败:", res:GetResult())
        GameGlobal.GetModule(CampaignModule):ShowErrorToast(res:GetResult())
    end
end
