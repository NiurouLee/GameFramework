--[[
    伯利恒高级时装数据
]]
---@class UIHauteCouturePLM:UIHauteCoutureDataBase
_class("UIHauteCouturePLM", UIHauteCoutureDataBase)
UIHauteCouturePLM = UIHauteCouturePLM

function UIHauteCouturePLM:Constructor()
end

---@return RoleAssetID 代币ID
function UIHauteCouturePLM:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinPLM
end
---点击商店内的时装礼包打开高级时装注解main
function UIHauteCouturePLM:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2Controller")
end
---打开代币购买界面
function UIHauteCouturePLM:BuyItem()
end

---@return boolean 是否为复刻的高级时装
function UIHauteCouturePLM:IsReview()
    return false
end
---@return HauteCoutureType
function UIHauteCouturePLM:HC_Type()
    return HauteCoutureType.HC_PLM
end
---@return string 抽奖主界面ui类名
---@return T 抽奖主界面uiprefab
function UIHauteCouturePLM:GetMainUIInfo()
    return "UIHauteCoutureDrawMainPLM.prefab", UIHauteCoutureDrawMainPLM
end
---@return string 抽奖主界面背景图ui类名
---@return T 抽奖主界面背景图uiprefab
function UIHauteCouturePLM:GetMainUIBgInfo()
    return "UIHauteCoutureDrawBgPLM.prefab", UIHauteCoutureDrawBgPLM
end
---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCouturePLM:GetGetItemUIInfo()
    return "UIHauteCoutureDrawGetItemMainPLM.prefab", UIHauteCoutureDrawGetItemMainPLM
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCouturePLM:GetChargeUIInfo()
    return "UIHauteCoutureDrawChargeMainPLM.prefab", UIHauteCoutureDrawChargeMainPLM
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCouturePLM:GetChargeUIBgInfo()
    return "UIHauteCoutureDrawChargeBgPLM.prefab", UIHauteCoutureDrawChargeBgPLM
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCouturePLM:GetRulesUIInfo()
    return "UIHauteCoutureDrawRulesMainPLM.prefab", UIHauteCoutureDrawRulesMainPLM
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCouturePLM:GetRulesUIBgInfo()
    return "UIHauteCoutureDrawRulesBgPLM.prefab", UIHauteCoutureDrawRulesBgPLM
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCouturePLM:GetVideoUIInfo()
    return "UIHauteCoutureDrawVideoMainPLM.prefab", UIHauteCoutureDrawVideoMainPLM
end
---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCouturePLM:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDrawDynamicProbabilityMainPLM.prefab", UIHauteCoutureDrawDynamicProbabilityMainPLM
end
---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCouturePLM:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDrawDynamicProbabilityBgPLM.prefab", UIHauteCoutureDrawDynamicProbabilityBgPLM
end
---@return string 主界面侧边栏入口文本
function UIHauteCouturePLM:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title4")
end
