--[[
    贡露高级时装复刻数据
]]
---@class UIHauteCoutureGL_Review:UIHauteCoutureDataBase
_class("UIHauteCoutureGL_Review", UIHauteCoutureDataBase)
UIHauteCoutureGL_Review = UIHauteCoutureGL_Review

-----------------------------------------------------------------------------------------------------------
---@return RoleAssetID 代币ID
function UIHauteCoutureGL_Review:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinGL_Re
end

---点击商店内的时装礼包打开高级时装主界面
function UIHauteCoutureGL_Review:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2ReviewController")
end

---打开代币购买界面
function UIHauteCoutureGL_Review:BuyItem()
    Log.exception("BuyItem()方法必须重写：", debug.traceback())
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureGL_Review:IsReview()
    return true
end

---@return HauteCoutureType
function UIHauteCoutureGL_Review:HC_Type()
    return HauteCoutureType.HC_GL_Re
end

---@return string 抽奖主界面uiprefab
---@return T 抽奖主界面ui类名
function UIHauteCoutureGL_Review:GetMainUIInfo()
    return "UIHauteCoutureDrawMainGL_Review.prefab", UIHauteCoutureDrawMainGL_Review
end

---@return string 抽奖主界面背景图uiprefab
---@return T 抽奖主界面背景图ui类名
function UIHauteCoutureGL_Review:GetMainUIBgInfo()
    return "UIHauteCoutureDrawBgGL.prefab", UIHauteCoutureDrawBgGL
end

---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureGL_Review:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemMainGL.prefab", UIHauteCoutureDrawGetItemMainGL
end

---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureGL_Review:GetChargeUIInfo()
    return "UIHauteCoutureDrawChargeMainGL.prefab", UIHauteCoutureDrawChargeMainGL
end

---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureGL_Review:GetChargeUIBgInfo()
    return "UIHauteCoutureDrawChargeBgGL.prefab", UIHauteCoutureDrawChargeBgGL
end

---@return string 抽奖规则说明uiprefab
---@return T 抽奖规则说明ui类名
function UIHauteCoutureGL_Review:GetRulesUIInfo()
    return "UIHauteCoutureDrawRulesMainGL.prefab", UIHauteCoutureDrawRulesMainGL
end

---@return string 抽奖规则说明背景图uiprefab
---@return T 抽奖规则说明界面背景图ui类名
function UIHauteCoutureGL_Review:GetRulesUIBgInfo()
    return "UIHauteCoutureDrawRulesBgGL.prefab", UIHauteCoutureDrawRulesBgGL
end

---@return string 抽奖视频展示uiprefab
---@return T 抽奖视频展示ui类名
function UIHauteCoutureGL_Review:GetVideoUIInfo()
    return "UIHauteCoutureDrawVideoMainGL.prefab", UIHauteCoutureDrawVideoMainGL
end

---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureGL_Review:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDrawDynamicProbabilityMainGL.prefab", UIHauteCoutureDrawDynamicProbabilityMainGL
end

---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureGL_Review:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDrawDynamicProbabilityBgGL.prefab", UIHauteCoutureDrawDynamicProbabilityBgGL
end

---@return string 主界面侧边栏入口文本
function UIHauteCoutureGL_Review:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title2")
end

--高级时装复刻,重复奖励变更界面背景图
function UIHauteCoutureGL_Review:Review_DuplicateRewardBgInfo()
    return "UIHauteCoutureDuplicateRewardBgGL.prefab", UIHauteCoutureDuplicateRewardBgGL
end

--高级时装复刻,重复奖励变更界面内容
function UIHauteCoutureGL_Review:Review_DuplicateRewardUIInfo()
    return "UIHauteCoutureDuplicateRewardGL.prefab", UIHauteCoutureDuplicateRewardGL
end
