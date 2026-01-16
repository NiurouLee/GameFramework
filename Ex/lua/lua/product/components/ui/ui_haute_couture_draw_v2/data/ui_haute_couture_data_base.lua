--[[
    高级时装数据基类
]]
---@class UIHauteCoutureDataBase:Object
_class("UIHauteCoutureDataBase", Object)
UIHauteCoutureDataBase = UIHauteCoutureDataBase

function UIHauteCoutureDataBase:Constructor(campaignID)
    self._id = campaignID
end

--region 必须重写的方法
---@return RoleAssetID 代币ID
function UIHauteCoutureDataBase:CostItemID()
    Log.exception("CostItemID()方法必须重写：", debug.traceback())
end
---点击商店内的时装礼包打开高级时装主界面
function UIHauteCoutureDataBase:ShopGoodsOnClick()
    Log.exception("ShopGoodsOnClick()方法必须重写：", debug.traceback())
end
---打开代币购买界面
function UIHauteCoutureDataBase:BuyItem()
    Log.exception("BuyItem()方法必须重写：", debug.traceback())
end
---@return boolean 是否为复刻的高级时装
function UIHauteCoutureDataBase:IsReview()
    Log.exception("IsReview()方法必须重写：", debug.traceback())
end
---@return HauteCoutureType
function UIHauteCoutureDataBase:HC_Type()
    Log.exception("HC_Type()方法必须重写：", debug.traceback())
end
---@return string 抽奖主界面uiprefab
---@return T 抽奖主界面ui类名
function UIHauteCoutureDataBase:GetMainUIInfo()
    Log.exception("GetMainUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖主界面背景图uiprefab
---@return T 抽奖主界面背景图ui类名
function UIHauteCoutureDataBase:GetMainUIBgInfo()
    Log.exception("GetMainUIInfo()方法必须重写：", debug.traceback())
end
---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureDataBase:GetGetItemUIInfo()
    Log.exception("GetGetItemUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureDataBase:GetChargeUIInfo()
    Log.exception("GetChargeUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureDataBase:GetChargeUIBgInfo()
    Log.exception("GetChargeUIBgInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖规则说明uiprefab
---@return T 抽奖规则说明ui类名
function UIHauteCoutureDataBase:GetRulesUIInfo()
    Log.exception("GetRulesUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖规则说明背景图uiprefab
---@return T 抽奖规则说明界面背景图ui类名
function UIHauteCoutureDataBase:GetRulesUIBgInfo()
    Log.exception("GetRulesUIBgInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖视频展示uiprefab
---@return T 抽奖视频展示ui类名
function UIHauteCoutureDataBase:GetVideoUIInfo()
    Log.exception("GetVideoUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureDataBase:GetDynamicProbablityUIInfo()
    Log.exception("GetDynamicProbablityUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureDataBase:GetDynamicProbablityUIBgInfo()
    Log.exception("GetDynamicProbablityUIBgInfo()方法必须重写：", debug.traceback())
end
---@return string 主界面侧边栏入口文本
function UIHauteCoutureDataBase:SideEnterText()
    Log.exception("SideEnterText()方法必须重写：", debug.traceback())
end
--高级时装复刻,重复奖励变更界面背景图
function UIHauteCoutureDataBase:Review_DuplicateRewardBgInfo()
    if not self:IsReview() then
        Log.exception("非复刻的活动不可调用Review_DuplicateRewardBgInfo()方法:", debug.traceback())
        return
    end
    Log.exception("Review_DuplicateRewardBgInfo()方法必须重写：", debug.traceback())
end
--高级时装复刻,重复奖励变更界面内容
function UIHauteCoutureDataBase:Review_DuplicateRewardUIInfo()
    if not self:IsReview() then
        Log.exception("非复刻的活动不可调用Review_DuplicateRewardUIInfo()方法:", debug.traceback())
        return
    end
    Log.exception("Review_DuplicateRewardUIInfo()方法必须重写：", debug.traceback())
end
--endregion

--region 外部调用的公共方法(Set)
---请求活动详细数据
---@return UIActivityCampaign
function UIHauteCoutureDataBase:ReqDetailInfo(TT, res)
    if not res then
        res = AsyncRequestRes:New()
        res:SetSucc(false)
    end

    local module = GameGlobal.GetModule(CampaignModule)

    local campType, cmpIDs
    if self:IsReview() then
        campType = ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN_COPY
    else
        campType = ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN
    end
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, campType) --下面会强制拉数据，这里不用传组件id

    -- 错误处理
    if res and not res:GetSucc() then
        module:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return nil
    end

    -- 强拉数据
    self._campaign:ReLoadCampaignInfo_Force(TT, res)

    -- 错误处理
    if res and not res:GetSucc() then
        module:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return nil
    end
    ---@type BuyGiftComponent
    self._buyGiftCmp = nil
    ---@type SeniorSkinComponent
    self._seniorSkinCmp = nil
    if self:IsReview() then
        self._buyGiftCmp = self._campaign:GetComponentByType(ECampaignSeniorSkinCopyComponentID.ECAMPAIGN_COPY_BUY_GIFT)
    else
        self._buyGiftCmp = self._campaign:GetComponentByType(ECampaignSeniorSkinComponentID.ECAMPAIGN_BUY_GIFT)
    end
    return self._campaign
end
--endregion

--region 外部调用的公共方法(Get)
---5次后才有可能抽到最终奖励
function UIHauteCoutureDataBase:MinDrawCount()
    return 5
end
function UIHauteCoutureDataBase:CampaignID()
    return self._id
end
---@return CriAudioIDConst 主界面bgm，有需要就重写
function UIHauteCoutureDataBase:GetBgm()
    return CriAudioIDConst.BGSeniorSkin
end
---@return number 特殊奖励（高级时装）配置索引
function UIHauteCoutureDataBase:SpecailAwardIdx()
    return 10
end
---@return BuyGiftComponent 购买礼包组件
function UIHauteCoutureDataBase:GetBuyGiftCmp()
    if not self._campaign then
        Log.exception("必须先调用ReqDetailInfo()请求详细数据，才能调用GetBuyGiftCmp()。", debug.traceback())
        return nil
    end
    if self:IsReview() then
        return self._campaign:GetComponent(ECampaignSeniorSkinCopyComponentID.ECAMPAIGN_COPY_BUY_GIFT)
    else
        return self._campaign:GetComponent(ECampaignSeniorSkinComponentID.ECAMPAIGN_BUY_GIFT)
    end
end
---@return SeniorSkinComponent 高级时装组件
function UIHauteCoutureDataBase:GetSeniorSkinCmp()
    if not self._campaign then
        Log.exception("必须先调用ReqDetailInfo()请求详细数据，才能调用GetSeniorSkinCmp()。", debug.traceback())
        return nil
    end
    if self:IsReview() then
        return self._campaign:GetComponent(ECampaignSeniorSkinCopyComponentID.ECAMPAIGN_COPY_SENIOR_SKIN)
    else
        return self._campaign:GetComponent(ECampaignSeniorSkinComponentID.ECAMPAIGN_SENIOR_SKIN)
    end
end
---@return table 全部奖励排序后的配置数组
function UIHauteCoutureDataBase:GetPrizeCfgs()
    if not self._cfg_prizes then
        local cmpID = self:GetSeniorSkinCmp():GetComponentCfgId()
        self._cfg_prizes = Cfg.cfg_component_senior_skin_weight {ComponentID = cmpID}
        if not self._cfg_prizes or not next(self._cfg_prizes) then
            Log.exception("[HauteCouture] cfg_component_senior_skin_weight中缺少配置:", cmpID)
        end
        table.sort(
            self._cfg_prizes,
            function(a, b)
                return a.RewardSortOrder > b.RewardSortOrder
            end
        )
    end
    return self._cfg_prizes
end
---@return UIActivityCampaign 获取详细数据
function UIHauteCoutureDataBase:GetUICampaign()
    return self._campaign
end

function UIHauteCoutureDataBase:GetSeniorSkinCfg()
    if not self._cfg_senior_skin then
        local cmpID = self:GetSeniorSkinCmp():GetComponentCfgId()
        local cfgs = Cfg.cfg_senior_skin_draw {ComponentId = cmpID}
        if not cfgs or not next(cfgs) then
            Log.exception("[HauteCouture] cfg_senior_skin_draw中缺少配置:", cmpID)
        end
        self._cfg_senior_skin = cfgs[1]
    end
    return self._cfg_senior_skin
end

--endregion
