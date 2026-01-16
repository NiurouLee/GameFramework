---@class UIHauteCoutureDrawBase:UICustomWidget
---@field controller UIHauteCoutureDrawV2Controller 控制器
_class("UIHauteCoutureDrawBase", UICustomWidget)
UIHauteCoutureDrawBase = UIHauteCoutureDrawBase

function UIHauteCoutureDrawBase:Constructor()
    self.controller = nil
    self._uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end

function UIHauteCoutureDrawBase:InitWidgetsBase()
    self.controller = self.uiOwner

    self._videoPlayer = self:GetGameObject("VideoPlayer")
    ---@type UILocalizationText
    self._endtime = self:GetUIComponent("UILocalizationText", "endtime")
    -- self._drawDes = self:GetUIComponent("UILocalizationText", "drawDes")
    -- self._drawTitle = self:GetUIComponent("UILocalizedTMP", "drawTitle")
    self._moneyNum = self:GetUIComponent("UILocalizationText", "moneyNum")

    -- self._moneyIcon = self:GetUIComponent("Image", "moneyIcon")
    --self._logoImg = self:GetUIComponent("RawImageLoader", "logo")
    --self._imgDes = self:GetUIComponent("UILocalizationText", "imgDes")

    self._freeGo = self:GetGameObject("free")
    self._redGo = self:GetGameObject("red")
    self._countParent = self:GetGameObject("normalSingleGo")
    self._drawBtnOj = self:GetGameObject("drawbtn")
    self._probalityBtn = self:GetGameObject("probabilityBtn")
    self._buyBtn = self:GetGameObject("buybtn")

    self._prizeEff = self:GetUIComponent("Transform", "PrizeEff")
    self._prizeEff.gameObject:SetActive(false)

    ---currency
    local currency = self:GetUIComponent("UISelectObjectPath", "currencyMenu")
    ---@type UICurrencyMenu
    self._topTips = currency:SpawnObject("UICurrencyMenu")

    self._topTips:SetData({self:GetCoinId()}, false)
    ---@type UICurrencyItem
    self._seniorSkinItem = self._topTips:GetItemByTypeId(self:GetCoinId())
    self._seniorSkinItem:SetAddCallBack(
        function(id, go)
            self:BuyBtnOnClick()
        end
    )
    --backBtns
    local btns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self:CloseSelf()
        end
    )
end
function UIHauteCoutureDrawBase:CloseSelf()
    self.controller:CloseDialog()
end

--子类返回具体
---@return number 代币Id
function UIHauteCoutureDrawBase:GetCoinId()
    Log.error("UIHauteCoutureDrawBase:GetCoinId should be inherited")
    return -1
end

function UIHauteCoutureDrawBase:OnHide()
end

--设置结束时间
function UIHauteCoutureDrawBase:SetEndTime(timeStr)
    if self._endtime then
        self._endtime:SetText(timeStr)
    end
end

--检查是否到结束时间
---@return boolean true代表已结束
function UIHauteCoutureDrawBase:CheckEndTime()
    local time = self.controller._componentInfo.m_close_time
    local now = math.floor(self:GetModule(SvrTimeModule):GetServerTime() / 1000)
    if now > time then
        local timeStr = StringTable.Get("str_activity_finished")
        self:SetEndTime(timeStr)
        self._timeStr = timeStr
        return true
    else
        local timeStr = HelperProxy:GetInstance():FormatTime_3(time - now, "#ffd009") --文本颜色有特殊需求可以重写此方法
        if self._timeStr ~= timeStr then
            self:SetEndTime(StringTable.Get("str_senior_skin_draw_end_time", timeStr))
            self._timeStr = timeStr
        end
        return false
    end
    return true
end

--加载Video
function UIHauteCoutureDrawBase:LoadVideo(url)
    --local url = ResourceManager:GetInstance():GetAssetPath(self.controller._cfg.VideoName .. ".mp4", LoadType.VideoClip)
    Log.debug("[guide movie] move url ", url)
    self._vp = self:GetUIComponent("VideoPlayer", "VideoPlayer")
    self._vp.gameObject:SetActive(true)
    self._vp.url = url
    if self.controller.CtxData:IsReview() then
        self._vp.targetCamera = GameGlobal.UIStateManager():GetControllerCamera("UIHauteCoutureDrawV2ReviewController")
    else
        self._vp.targetCamera = GameGlobal.UIStateManager():GetControllerCamera("UIHauteCoutureDrawV2Controller")
    end
    self._vp:Play()
    self._vp.loopPointReached = self._vp.loopPointReached + self._LoopPointReached
end

--规则按钮点击
function UIHauteCoutureDrawBase:RuleBtnOnClick(go)
    self:HandleRuleBtnClick()
end

--子类调用,处理规则按钮点击
function UIHauteCoutureDrawBase:HandleRuleBtnClick()
    if self.controller._closed then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        return
    end

    self:ShowDialog("UIHauteCoutureDrawRulesV2Controller", self.controller.CtxData)
end

--购买按钮点击
function UIHauteCoutureDrawBase:BuyBtnOnClick(go)
    self:HandleBuyBtnClick()
end

--子类调用，处理购买按钮点击
function UIHauteCoutureDrawBase:HandleBuyBtnClick()
    if self.controller._closed then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        return
    end
    GameGlobal.UIStateManager():ShowDialog(
        "UIHauteCoutureDrawChargeV2Controller",
        self.controller.hcType,
        self.controller._buyComponet,
        self.controller.CtxData
    )
end

--按钮点击
function UIHauteCoutureDrawBase:DrawBtnOnClick(go)
    self:HandleDrawBtnClick()
end

--子类调用,处理
function UIHauteCoutureDrawBase:HandleDrawBtnClick()
end

--按钮点击
function UIHauteCoutureDrawBase:ProbabilityBtnOnClick(go)
    self:HandleProbabilityBtnClick()
end

function UIHauteCoutureDrawBase:HandleProbabilityBtnClick()
    self:ShowDialog(
        "UIHauteCoutureDrawDynamicProbablityV2Controller",
        self.controller.hcType,
        self.controller._prizes,
        self.controller._componentInfo.shake_num,
        self.controller._componentInfo.shake_win_ids,
        self.controller._componentId,
        self.controller.CtxData
    )
end

--按钮点击
function UIHauteCoutureDrawBase:FgOnClick(go)
    self:HandleFgBtnClick()
end

--子类调用
function UIHauteCoutureDrawBase:HandleFgBtnClick()
    self:ShowDialog("UIHauteCoutureDrawVideoV2Controller", self.controller.CtxData)
end
