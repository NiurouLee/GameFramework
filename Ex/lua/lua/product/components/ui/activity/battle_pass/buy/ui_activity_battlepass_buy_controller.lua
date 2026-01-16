--- @class UIActivityBattlePassBuyController:UIController
_class("UIActivityBattlePassBuyController", UIController)
UIActivityBattlePassBuyController = UIActivityBattlePassBuyController

--region component help
--- @return LVRewardComponent
function UIActivityBattlePassBuyController:_GetLVRewardComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponent(cmptId)
end

--- @return LVRewardComponentInfo
function UIActivityBattlePassBuyController:_GetLVRewardComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponentInfo(cmptId)
end

--- @return BuyGiftComponent
function UIActivityBattlePassBuyController:_GetBuyGiftComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponent(cmptId)
end

--- @return BuyGiftComponentInfo
function UIActivityBattlePassBuyController:_GetBuyGiftComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponentInfo(cmptId)
end
--endregion

function UIActivityBattlePassBuyController:_GetComponents()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            if self.callback then
                self.callback()
            end
            self:CloseDialog()
        end
    )

    ---@type UICustomWidgetPool
    local eliteBoardPool = self:GetUIComponent("UISelectObjectPath", "eliteBoardPool")
    self._eliteBoard = eliteBoardPool:SpawnObject("UIActivityBattlePassBoard")

    ---@type UICustomWidgetPool
    local deluxeBoardPool = self:GetUIComponent("UISelectObjectPath", "deluxeBoardPool")
    self._deluxeBoard = deluxeBoardPool:SpawnObject("UIActivityBattlePassBoard")
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityBattlePassBuyController:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_BATTLEPASS,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_1,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_2,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_3,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    )
    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIActivityBattlePassBuyController:OnShow(uiParams)
    self:_AttachEvents()

    self._isOpen = true
    if uiParams then
        self.callback = uiParams[1]
    end

    self:_GetComponents()

    -- 设置立绘
    UIActivityBattlePassHelper.SetSpecialImg(
        self._campaign,
        self:GetGameObject("imgRoot"),
        self:GetUIComponent("RawImageLoader", "img"),
        self:GetName()
    )

    self:_SetBoard()
end

function UIActivityBattlePassBuyController:OnHide()
    self:_DetachEvents()
    self._isOpen = false
end

function UIActivityBattlePassBuyController:_SetBoard()
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()
    --- @type BuyGiftComponentInfo
    local componentInfo = self:_GetBuyGiftComponentInfo()

    ---------------------------------------------------
    ---@type CampaignGiftType
    local type = CampaignGiftType.ECGT_ADVANCED
    local giftId = component:GetFirstGiftIDByType(type)

    -- 显示用带货币符号的字符串
    local price = component:GetGiftPriceForShowById(giftId)

    self._eliteBoard:SetData(
        self._campaign,
        type,
        price,
        function(type)
            self:BuyBtnOnClick(type)
        end
    )

    ---------------------------------------------------
    type = CampaignGiftType.ECGT_LUXURY
    local buyState = componentInfo.m_buy_state
    if buyState == BuyGiftStateType.EBGST_ADVANCED then
        type = CampaignGiftType.ECGT_ADDITIONALBUY
    end

    giftId = component:GetFirstGiftIDByType(type)
    -- 显示用带货币符号的字符串
    price = component:GetGiftPriceForShowById(giftId)

    self._deluxeBoard:SetData(
        self._campaign,
        type,
        price,
        function(type)
            self:BuyBtnOnClick(type)
        end
    )
end

--region Event Callback
function UIActivityBattlePassBuyController:BuyBtnOnClick(type)
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()

    local giftId = component:GetFirstGiftIDByType(type)
    component:BuyGift(giftId ,1, type)
end
--endregion

--region AttachEvent
function UIActivityBattlePassBuyController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.ActivityCurrencyBuySuccess, self._OnCurrencyBuySuccess)
end

function UIActivityBattlePassBuyController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.ActivityCurrencyBuySuccess, self._OnCurrencyBuySuccess)
end

function UIActivityBattlePassBuyController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

-- 直购的回调
function UIActivityBattlePassBuyController:_OnCurrencyBuySuccess(id)
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()

    local type = nil
    for t = CampaignGiftType.ECGT_ADVANCED, CampaignGiftType.ECGT_ADDITIONALBUY do
        if component:GetFirstGiftIDByType(t) == id then
            type = t
            break
        end
    end

    if type then
        self:ShowDialog(
            "UIActivityBattlePassAwardController",
            type,
            function()
                if self.callback then
                    self.callback(type == CampaignGiftType.ECGT_LUXURY or type == CampaignGiftType.ECGT_ADDITIONALBUY)
                end
                self:CloseDialog()
            end
        )
    else
        Log.fatal("UIActivityBattlePassBuyController:_OnCurrencyBuySuccess(id) CampaignGiftType Wrong! id = ", id)
    end
end
--endregion
