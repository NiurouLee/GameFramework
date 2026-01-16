--[[
    卡戎高级时装数据
]]
---@class UIHauteCoutureKR_Review:UIHauteCoutureDataBase
_class("UIHauteCoutureKR_Review", UIHauteCoutureDataBase)
UIHauteCoutureKR_Review = UIHauteCoutureKR_Review

-----------------------------------------------------------------------------------------------------------
---@return RoleAssetID 代币ID
function UIHauteCoutureKR_Review:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinKR_Re
end

---点击商店内的时装礼包打开高级时装主界面
function UIHauteCoutureKR_Review:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2ReviewController")
end

---打开代币购买界面
function UIHauteCoutureKR_Review:BuyItem()
    Log.exception("BuyItem()方法必须重写：", debug.traceback())
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureKR_Review:IsReview()
    return true
end

---@return HauteCoutureType
function UIHauteCoutureKR_Review:HC_Type()
    return HauteCoutureType.HC_KR_Re
end

---@return string 抽奖主界面uiprefab
---@return T 抽奖主界面ui类名
function UIHauteCoutureKR_Review:GetMainUIInfo()
    return "UIHauteCoutureDrawMainKR_Review.prefab", UIHauteCoutureDrawMainKR_Review
end

---@return string 抽奖主界面背景图uiprefab
---@return T 抽奖主界面背景图ui类名
function UIHauteCoutureKR_Review:GetMainUIBgInfo()
    return "UIHauteCoutureDrawBgKR.prefab", UIHauteCoutureDrawBgKR
end

---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureKR_Review:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemMainKR.prefab", UIHauteCoutureDrawGetItemMainKR
end

---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureKR_Review:GetChargeUIInfo()
    return "UIHauteCoutureDrawChargeMainKR.prefab", UIHauteCoutureDrawChargeMainKR
end

---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureKR_Review:GetChargeUIBgInfo()
    return "UIHauteCoutureDrawChargeBgKR.prefab", UIHauteCoutureDrawChargeBgKR
end

---@return string 抽奖规则说明uiprefab
---@return T 抽奖规则说明ui类名
function UIHauteCoutureKR_Review:GetRulesUIInfo()
    return "UIHauteCoutureDrawRulesMainKR.prefab", UIHauteCoutureDrawRulesMainKR
end

---@return string 抽奖规则说明背景图uiprefab
---@return T 抽奖规则说明界面背景图ui类名
function UIHauteCoutureKR_Review:GetRulesUIBgInfo()
    return "UIHauteCoutureDrawRulesBgKR.prefab", UIHauteCoutureDrawRulesBgKR
end

---@return string 抽奖视频展示uiprefab
---@return T 抽奖视频展示ui类名
function UIHauteCoutureKR_Review:GetVideoUIInfo()
    return "UIHauteCoutureDrawVideoMainKR.prefab", UIHauteCoutureDrawVideoMainKR
end

---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureKR_Review:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDrawDynamicProbabilityMainKR.prefab", UIHauteCoutureDrawDynamicProbabilityMainKR
end

---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureKR_Review:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDrawDynamicProbabilityBgKR.prefab", UIHauteCoutureDrawDynamicProbabilityBgKR
end

---@return string 主界面侧边栏入口文本
function UIHauteCoutureKR_Review:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title2")
end

--高级时装复刻,重复奖励变更界面背景图
function UIHauteCoutureKR_Review:Review_DuplicateRewardBgInfo()
    return "UIHauteCoutureDuplicateRewardBgKR.prefab", nil
end

--高级时装复刻,重复奖励变更界面内容
function UIHauteCoutureKR_Review:Review_DuplicateRewardUIInfo()
    return "UIHauteCoutureDrawDuplicateRewardKR.prefab", UIHauteCoutureDuplicateRewardKR
end
