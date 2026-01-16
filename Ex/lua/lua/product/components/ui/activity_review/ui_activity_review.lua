--
---@class UIActivityReview : UIController
_class("UIActivityReview", UIController)
UIActivityReview = UIActivityReview

---@param res AsyncRequestRes
function UIActivityReview:LoadDataOnEnter(TT, res)
    local count = GameGlobal.GetModule(RoleModule):GetReviewCoinAddedCount()
    local tmpRes = GameGlobal.GetModule(CampaignModule):EnterCampaignReiew(TT)
    if tmpRes and tmpRes:GetSucc() then
        self._addedCoinCount = count
        res:SetSucc(true)
    else
        GameGlobal.GetModule(CampaignModule):ShowErrorToast(tmpRes:GetResult())
        res:SetSucc(false)
    end
    -- self._addedCoinCount = 5
end
--初始化
function UIActivityReview:OnShow(uiParams)
    self:InitWidget()
    ---@type UICommonTopButton
    local topWidget = self.topBtn:SpawnObject("UICommonTopButton")
    topWidget:SetData(
        function()
            self:SwitchState(UIStateType.UIExtraSelect)
        end,
        function()
            self:ShowDialog("UIHelpController", self:GetName())
        end
    )
    ---@type UICurrencyMenu
    self._topCurrency = self.toptips:SpawnObject("UICurrencyMenu")
    self._topCurrency:SetData({RoleAssetID.RoleAssetActiveToken})

    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    self._data = uiModule:GetReviewData()
    self._dataList = self._data:GetAllOpenedList()

    -- self.list:InitListView(
    --     #self._dataList,
    --     function(scrollview, index)
    --         return self:_InitItem(scrollview, index)
    --     end
    -- )

    local paddingLeft = -135
    local paddingRight = 414
    local del1 = 580
    local del2 = 241
    local sWidth = self.safeArea.rect.width
    local width = paddingLeft
    for i = 1, #self._dataList do
        local value = i % 2
        if value == 1 then
            width = width + del1
        else
            width = width + del2
        end
    end
    width = width + paddingRight
    self.contentTr.sizeDelta = Vector2(math.max(sWidth, width), self.safeArea.rect.height)

    ---@type UIActivityReviewItem[]
    local items = self.content:SpawnObjects("UIActivityReviewItem", #self._dataList)
    for index, item in ipairs(items) do
        item:SetData(self._dataList[index], index, index == #self._dataList)
    end

    if self._addedCoinCount and self._addedCoinCount > 0 then
        ---@type UICurrencyItem
        local coinToptip = self._topCurrency:GetItemByTypeId(RoleAssetID.RoleAssetActiveToken)
        local count = GameGlobal.GetModule(ItemModule):GetItemCount(RoleAssetID.RoleAssetActiveToken)
        local from = math.max(count - self._addedCoinCount, 0)
        local to = count
        local max = Cfg.cfg_global["ActiveReviewTokenMax"].IntValue
        if from ~= to then
            local tl =
                EZTL_Sequence:New(
                {
                    EZTL_PlayAnimation:New(self.anim, "UIActivityReview_uianim", "Animation"),
                    EZTL_TextUpAnimFormat:New(coinToptip:GetUIText(), from, to, 500, "%s/" .. max, "文字滚动")
                },
                "顶条物品数量滚动"
            )
            self._eftPlayer = EZTL_Player:New()
            self.anim.gameObject:SetActive(true)
            self.AddValue:SetText("+" .. tostring(self._addedCoinCount))
            coinToptip:GetUIText():SetText(from .. "/" .. max)
            self._eftPlayer:Play(tl)
        end
    end
end
--获取ui组件
function UIActivityReview:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.topBtn = self:GetUIComponent("UISelectObjectPath", "topBtn")
    ---@type UIDynamicScrollView
    -- self.list = self:GetUIComponent("UIDynamicScrollView", "list")
    ---@type UICustomWidgetPool
    self.toptips = self:GetUIComponent("UISelectObjectPath", "toptips")
    --generated end--

    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UnityEngine.RectTransform
    self.contentTr = self:GetUIComponent("RectTransform", "Content")
    ---@type UnityEngine.RectTransform
    self.safeArea = self:GetUIComponent("RectTransform", "SafeArea")

    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "anim")
    self.anim.gameObject:SetActive(false)
    self.AddValue = self:GetUIComponent("UILocalizationText", "AddValue")

    ---@type H3DUIBlurHelper
    self._shot = self:GetUIComponent("H3DUIBlurHelper", "shot")
end

function UIActivityReview:OnHide()
    if self._eftPlayer then
        if self._eftPlayer:IsPlaying() then
            self._eftPlayer:Stop()
        end
        self._eftPlayer = nil
    end
end

function UIActivityReview:_InitItem(scrollview, index)
    if index < 0 then
        return nil
    end

    index = index + 1
    local item = scrollview:NewListViewItem("item")
    local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if not item.IsInitHandlerCalled then
        item.IsInitHandlerCalled = true
    end
    ---@type UIActivityReviewItem
    local itemWidget = cellPool:SpawnObject("UIActivityReviewItem")
    itemWidget:SetData(self._dataList[index], index, #self._dataList == index)

    return item
end

--某些活动进入动效需要传入屏幕截图
---@return UnityEngine.RenderTexture
function UIActivityReview:GetShotImage()
    self._shot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
    return self._shot:RefreshBlurTexture()
end
