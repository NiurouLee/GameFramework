--[[
    青瞳高级时装数据
]]
---@class UIHauteCoutureQT:UIHauteCoutureDataBase
_class("UIHauteCoutureQT", UIHauteCoutureDataBase)
UIHauteCoutureQT = UIHauteCoutureQT

function UIHauteCoutureQT:Constructor()
end

---@return RoleAssetID 代币ID
function UIHauteCoutureQT:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinQT
end
---点击商店内的时装礼包打开高级时装注解main
function UIHauteCoutureQT:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDrawV2Controller")
end
---打开代币购买界面
function UIHauteCoutureQT:BuyItem()
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureQT:IsReview()
    return false
end
---@return HauteCoutureType
function UIHauteCoutureQT:HC_Type()
    return HauteCoutureType.HC_BLH
end

---@return string 抽奖主界面ui类名
---@return T 抽奖主界面uiprefab
function UIHauteCoutureQT:GetMainUIInfo()
    return "UIHauteCoutureDraw_QT_Main.prefab", UIHauteCoutureDraw_QT_Main
end
---@return string 抽奖主界面背景图ui类名
---@return T 抽奖主界面背景图uiprefab
function UIHauteCoutureQT:GetMainUIBgInfo()
    return "UIHauteCoutureDraw_QT_Bg.prefab", UIHauteCoutureDraw_QT_Bg
end
---@return string 获得物品弹窗prefab
---@return T 获得物品弹窗ui类
function UIHauteCoutureQT:GetGetItemUIInfo()
    return "UIHauteCoutureDraw_QT_GetItemMain.prefab", UIHauteCoutureDraw_QT_GetItemMain
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureQT:GetChargeUIInfo()
    return "UIHauteCoutureDraw_QT_ChargeMain.prefab", UIHauteCoutureDraw_QT_ChargeMain
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureQT:GetChargeUIBgInfo()
    return "UIHauteCoutureDraw_QT_ChargeBg.prefab", UIHauteCoutureDraw_QT_ChargeBg
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureQT:GetRulesUIInfo()
    return "UIHauteCoutureDraw_QT_RulesMain.prefab", UIHauteCoutureDraw_QT_RulesMain
end
---@return string 抽奖充值背景图uiprefab
---@return T 抽奖充值界面背景图ui类名
function UIHauteCoutureQT:GetRulesUIBgInfo()
    return "UIHauteCoutureDraw_QT_RulesBg.prefab", UIHauteCoutureDraw_QT_RulesBg
end
---@return string 抽奖充值uiprefab
---@return T 抽奖充值ui类名
function UIHauteCoutureQT:GetVideoUIInfo()
    return "UIHauteCoutureDraw_QT_VideoMain.prefab", UIHauteCoutureDraw_QT_VideoMain
end
---@return string 抽奖动态概率uiprefab
---@return T 抽奖动态概率ui类名
function UIHauteCoutureQT:GetDynamicProbablityUIInfo()
    return "UIHauteCoutureDraw_QT_DynamicProbabilityMain.prefab", UIHauteCoutureDraw_QT_DynamicProbabilityMain
end
---@return string 抽奖动态概率背景图uiprefab
---@return T 抽奖动态概率界面背景图ui类名
function UIHauteCoutureQT:GetDynamicProbablityUIBgInfo()
    return "UIHauteCoutureDraw_QT_DynamicProbabilityBg.prefab", UIHauteCoutureDraw_QT_DynamicProbabilityBg
end
---@return string 主界面侧边栏入口文本
function UIHauteCoutureQT:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title4")
end
