--高级服装控制
---@class UIHauteCoutureDrawV2Controller:UIController
_class("UIHauteCoutureDrawV2Controller", UIController)
UIHauteCoutureDrawV2Controller = UIHauteCoutureDrawV2Controller
function UIHauteCoutureDrawV2Controller:Constructor()
    self._timer = 0
    self.hcType = HauteCoutureType.HC_None
    ---@type UICustomWidget
    self.bg = nil
    ---@type UIHauteCoutureDrawBase
    self.main = nil
    ---@type UIHauteCoutureDataBase
    self.CtxData = nil
end

function UIHauteCoutureDrawV2Controller:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIHauteCoutureDataBase
    self.CtxData = campaignModule:GetCurHauteCouture()
    if not self.CtxData then
        campaignModule:LoadCampaignInfoListTask(TT) --刷新一次数据
        campaignModule:RefreshCurHauteCoutureInfo()
        self.CtxData = campaignModule:GetCurHauteCouture()
    end
    if not self.CtxData then
        Log.fatal("没有开启的活动")
        res:SetSucc(false)
        return
    end
    self._campaign = self.CtxData:ReqDetailInfo(TT, res)
    if not self._campaign then
        res:SetSucc(false)
        return
    end

    -- -- 获取活动 以及本窗口需要的组件P
    -- ---@type UIActivityCampaign
    -- self._campaign = UIActivityCampaign:New()
    -- self._campaign:LoadCampaignInfo(
    --     TT,
    --     res,
    --     ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN,
    --     ECampaignSeniorSkinComponentID.ECAMPAIGN_BUY_GIFT,
    --     ECampaignSeniorSkinComponentID.ECAMPAIGN_SENIOR_SKIN
    -- )

    -- -- 错误处理
    -- if res and not res:GetSucc() then
    --     campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    --     return
    -- end

    -- -- 强拉数据
    -- self._campaign:ReLoadCampaignInfo_Force(TT, res)

    -- -- 错误处理
    -- if res and not res:GetSucc() then
    --     campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    --     return
    -- end

    -- 清除 new
    ---@type BuyGiftComponent
    self._buyComponet = self._campaign:GetLocalProcess()._buyGiftComponent
    self._buyComponetInfo = self._campaign:GetLocalProcess()._buyGiftComponentInfo

    ---@type SeniorSkinComponent
    self._component = self._campaign:GetLocalProcess()._seniorSkinComponent

    ---@type SeniorSkinComponentInfo
    self._componentInfo = self._campaign:GetLocalProcess()._seniorSkinComponentInfo

    local time = self._componentInfo.m_close_time
    local now = math.floor(self:GetModule(SvrTimeModule):GetServerTime() / 1000)
    if now > time then
        --活动结束
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        res:SetSucc(false)
        return
    end

    if self._campaign._id == 1034 then
        self.hcType = HauteCoutureType.HC_GL
        HauteCouture:GetInstance().CostCoinId = 3000266
    elseif self._campaign._id == 1038 then
        self.hcType = HauteCoutureType.HC_KR
        HauteCouture:GetInstance().CostCoinId = 3000275
    else
        --新逻辑
        self.hcType = self.CtxData:HC_Type()
        HauteCouture:GetInstance().CostCoinId = self.CtxData:CostItemID()
    end

    HauteCouture:GetInstance().HcType = self.hcType

    self._closed = false
    self._componentId = self._component:GetComponentCfgId()
    self._cfg = self.CtxData:GetSeniorSkinCfg()
    self._prizes = self.CtxData:GetPrizeCfgs()

    --获取所有奖励
    self._drawCost = Cfg.cfg_component_senior_skin_cost {ComponentID = self._componentId}
    if not self._drawCost then
        Log.exception("[HauteCouture] cfg_component_senior_skin_cost中缺少配置:", self._componentId)
    end

    -- self._maxRows = self._cfg.PrizeRows --最多行
    -- self._maxCols = self._cfg.PrizeCols --最多列(每行多少个)
    self._specialIdx = self._cfg.SpecialIdx -- RewardSortOrder
    ---@type table<number, UIHauteCoutureDrawPrizeItem>
    self._allPrizes = {} --所有奖品prefab
    table.sort(
        self._prizes,
        function(a, b)
            return a.RewardSortOrder > b.RewardSortOrder
        end
    )
end

function UIHauteCoutureDrawV2Controller:OnShow(uiParams)
    local bg = self:GetUIComponent("UISelectObjectPath", "bgRoot")
    local main = self:GetUIComponent("UISelectObjectPath", "uiRoot")
    if self.hcType == HauteCoutureType.HC_GL then
        bg.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawBgGL.prefab")
        main.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawMainGL.prefab")
        self.bg = bg:SpawnObject("UIHauteCoutureDrawBgGL")
        self.main = main:SpawnObject("UIHauteCoutureDrawMainGL")
    elseif self.hcType == HauteCoutureType.HC_KR then
        bg.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawBgKR.prefab")
        main.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawMainKR.prefab")
        self.bg = bg:SpawnObject("UIHauteCoutureDrawBgKR")
        self.main = main:SpawnObject("UIHauteCoutureDrawMainKR")
    else
        local bgPrefab, bgClass = self.CtxData:GetMainUIBgInfo()
        local mainPrefab, mainClass = self.CtxData:GetMainUIInfo()

        if string.isnullorempty(bgPrefab) then
            Log.exception("[HauteCouture] 高级时装背景图Prefab为空:", self.CtxData:CampaignID())
        end
        if not bgClass then
            Log.exception("[HauteCouture] 高级时装背景类为空:", self.CtxData:CampaignID())
        end

        if string.isnullorempty(mainPrefab) then
            Log.exception("[HauteCouture] 高级时装主界面Prefab为空:", self.CtxData:CampaignID())
        end
        if not mainClass then
            Log.exception("[HauteCouture] 高级时装主界面类型为空:", self.CtxData:CampaignID())
        end

        bg.dynamicInfoOfEngine:SetObjectName(bgPrefab)
        main.dynamicInfoOfEngine:SetObjectName(mainPrefab)
        self.bg = bg:SpawnObject(bgClass._className)
        self.main = main:SpawnObject(mainClass._className)
    end

    if not self.bg then
        return
    end
    self.main:CheckEndTime()

    self._oldBgm = AudioHelperController.GetCurrentBgm()
    AudioHelperController.PlayBGMById(self.CtxData:GetBgm(), AudioConstValue.BGMCrossFadeTime)
end

function UIHauteCoutureDrawV2Controller:OnUpdate(dtMS)
    if not self._closed then
        self._timer = self._timer + dtMS
        if self._timer > 1000 then
            self._timer = 0
            self._closed = self.main:CheckEndTime()
        end
    end
end

function UIHauteCoutureDrawV2Controller:OnHide()
    AudioHelperController.PlayBGMById(self._oldBgm, AudioConstValue.BGMCrossFadeTime)
end

--活动倒计时放到主界面逻辑内部进行，因为有文本变色等特殊需求
-- function UIHauteCoutureDrawV2Controller:checkEndTime()
--     local time = self._componentInfo.m_close_time
--     local now = math.floor(self:GetModule(SvrTimeModule):GetServerTime() / 1000)
--     if now > time then
--         local timeStr = StringTable.Get("str_activity_finished")
--         if self.main then
--             self.main:SetEndTime(timeStr)
--         end
--         self._timeStr = timeStr
--         self._closed = true
--     else
--         local timeStr = HelperProxy:GetInstance():FormatTime_3(time - now, "#ffd009")
--         if self._timeStr ~= timeStr then
--             if self.main then
--                 self.main:SetEndTime(StringTable.Get("str_senior_skin_draw_end_time", timeStr))
--             end
--             self._timeStr = timeStr
--         end
--         self._closed = false
--     end
-- end
