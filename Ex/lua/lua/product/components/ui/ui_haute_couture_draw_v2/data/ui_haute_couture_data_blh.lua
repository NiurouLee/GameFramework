--[[
    伯利恒高级时装数据
]]
---@class UIHauteCoutureBLH:UIHauteCoutureDataBase
_class("UIHauteCoutureBLH", UIHauteCoutureDataBase)
UIHauteCoutureBLH = UIHauteCoutureBLH

function UIHauteCoutureBLH:Constructor()
end

---@return RoleAssetID 代币ID
function UIHauteCoutureBLH:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinBLH
end
---点击商店内的时装礼包打开高级时装注解main
function UIHauteCoutureBLH:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2Controller")
end
---打开代币购买界面
function UIHauteCoutureBLH:BuyItem()
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureBLH:IsReview()
    return false
end
---@return HauteCoutureType
function UIHauteCoutureBLH:HC_Type()
    return HauteCoutureType.HC_BLH
end
---@return string 抽奖主界面ui类名
---@return T 抽奖主界面uiprefab
function UIHauteCoutureBLH:GetMainUIInfo()
    return "UIHauteCoutureDrawMainBLH.prefab", UIHauteCoutureDrawMainBLH
end
---@return string 抽奖主界面背景图ui类名
---@return T 抽奖主界面背景图uiprefab
function UIHauteCoutureBLH:GetMainUIBgInfo()
    return "UIHauteCoutureDrawBgBLH.prefab", UIHauteCoutureDrawBgBLH
end
---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureBLH:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemMainBLH.prefab", UIHauteCoutureDrawGetItemMainBLH
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureBLH:GetChargeUIInfo()
    return "UIHauteCoutureDrawChargeMainBLH.prefab", UIHauteCoutureDrawChargeMainBLH
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureBLH:GetChargeUIBgInfo()
    return "UIHauteCoutureDrawChargeBgBLH.prefab", UIHauteCoutureDrawChargeBgBLH
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureBLH:GetRulesUIInfo()
    return "UIHauteCoutureDrawRulesMainBLH.prefab", UIHauteCoutureDrawRulesMainBLH
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureBLH:GetRulesUIBgInfo()
    return "UIHauteCoutureDrawRulesBgBLH.prefab", UIHauteCoutureDrawRulesBgBLH
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureBLH:GetVideoUIInfo()
    return "UIHauteCoutureDrawVideoMainBLH.prefab", UIHauteCoutureDrawVideoMainBLH
end
---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureBLH:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDrawDynamicProbabilityMainBLH.prefab", UIHauteCoutureDrawDynamicProbabilityMainBLH
end
---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureBLH:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDrawDynamicProbabilityBgBLH.prefab", UIHauteCoutureDrawDynamicProbabilityBgBLH
end
---@return string 主界面侧边栏入口文本
function UIHauteCoutureBLH:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title4")
end
