--[[
    伯利恒高级时装复刻数据
]]
---@class UIHauteCoutureBLH_Review:UIHauteCoutureDataBase
_class("UIHauteCoutureBLH_Review", UIHauteCoutureDataBase)
UIHauteCoutureBLH_Review = UIHauteCoutureBLH_Review

-----------------------------------------------------------------------------------------------------------
---@return RoleAssetID 代币ID
function UIHauteCoutureBLH_Review:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinBLH_Re
end

---点击商店内的时装礼包打开高级时装主界面
function UIHauteCoutureBLH_Review:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2ReviewController")
end

---打开代币购买界面
function UIHauteCoutureBLH_Review:BuyItem()
    Log.exception("BuyItem()方法必须重写：", debug.traceback())
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureBLH_Review:IsReview()
    return true
end

---@return HauteCoutureType
function UIHauteCoutureBLH_Review:HC_Type()
    return HauteCoutureType.HC_BLH_Re
end

---@return string 抽奖主界面uiprefab
---@return T 抽奖主界面ui类名
function UIHauteCoutureBLH_Review:GetMainUIInfo()
    return "UIHauteCoutureDrawMainBLH_Review.prefab", UIHauteCoutureDrawMainBLH_Review
end

---@return string 抽奖主界面背景图uiprefab
---@return T 抽奖主界面背景图ui类名
function UIHauteCoutureBLH_Review:GetMainUIBgInfo()
    return "UIHauteCoutureDrawBgBLH.prefab", UIHauteCoutureDrawBgBLH
end

---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureBLH_Review:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemMainBLH.prefab", UIHauteCoutureDrawGetItemMainBLH
end

---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureBLH_Review:GetChargeUIInfo()
    return "UIHauteCoutureDrawChargeMainBLH.prefab", UIHauteCoutureDrawChargeMainBLH
end

---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureBLH_Review:GetChargeUIBgInfo()
    return "UIHauteCoutureDrawChargeBgBLH.prefab", UIHauteCoutureDrawChargeBgBLH
end

---@return string 抽奖规则说明uiprefab
---@return T 抽奖规则说明ui类名
function UIHauteCoutureBLH_Review:GetRulesUIInfo()
    return "UIHauteCoutureDrawRulesMainBLH.prefab", UIHauteCoutureDrawRulesMainBLH
end

---@return string 抽奖规则说明背景图uiprefab
---@return T 抽奖规则说明界面背景图ui类名
function UIHauteCoutureBLH_Review:GetRulesUIBgInfo()
    return "UIHauteCoutureDrawRulesBgBLH.prefab", UIHauteCoutureDrawRulesBgBLH
end

---@return string 抽奖视频展示uiprefab
---@return T 抽奖视频展示ui类名
function UIHauteCoutureBLH_Review:GetVideoUIInfo()
    return "UIHauteCoutureDrawVideoMainBLH.prefab", UIHauteCoutureDrawVideoMainBLH
end

---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureBLH_Review:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDrawDynamicProbabilityMainBLH.prefab", UIHauteCoutureDrawDynamicProbabilityMainBLH
end

---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureBLH_Review:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDrawDynamicProbabilityBgBLH.prefab", UIHauteCoutureDrawDynamicProbabilityBgBLH
end

---@return string 主界面侧边栏入口文本
function UIHauteCoutureBLH_Review:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title2")
end

--高级时装复刻,重复奖励变更界面背景图
function UIHauteCoutureBLH_Review:Review_DuplicateRewardBgInfo()
    return "UIHauteCoutureDuplicateRewardBgBLH.prefab", UIHauteCoutureDuplicateRewardBgBLH
end

--高级时装复刻,重复奖励变更界面内容
function UIHauteCoutureBLH_Review:Review_DuplicateRewardUIInfo()
    return "UIHauteCoutureDuplicateRewardBLH.prefab", UIHauteCoutureDuplicateRewardBLH
end
