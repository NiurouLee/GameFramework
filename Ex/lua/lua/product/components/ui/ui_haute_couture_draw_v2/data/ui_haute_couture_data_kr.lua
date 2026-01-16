--[[
    卡戎高级时装数据
]]
---@class UIHauteCoutureKR:UIHauteCoutureDataBase
_class("UIHauteCoutureKR", UIHauteCoutureDataBase)
UIHauteCoutureKR = UIHauteCoutureKR

function UIHauteCoutureKR:Constructor()
end

---@return RoleAssetID 代币ID
function UIHauteCoutureKR:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinKR
end
---点击商店内的时装礼包打开高级时装注解main
function UIHauteCoutureKR:ShopGoodsOnClick()
end
---打开代币购买界面
function UIHauteCoutureKR:BuyItem()
end

---@return boolean 是否为复刻的高级时装
function UIHauteCoutureKR:IsReview()
    return false
end
---@return HauteCoutureType
function UIHauteCoutureKR:HC_Type()
    return HauteCoutureType.HC_KR
end
---@return string 抽奖主界面ui类名
---@return type 抽奖主界面uiprefab
function UIHauteCoutureKR:GetMainUIInfo()
    -- return "UIHauteCoutureDrawMainBLH.prefab", UIHauteCoutureDrawMainBLH
end
---@return string 抽奖主界面背景图ui类名
---@return type 抽奖主界面背景图uiprefab
function UIHauteCoutureKR:GetMainUIBgInfo()
    -- return "UIHauteCoutureDrawBgBLH.prefab", UIHauteCoutureDrawBgBLH
end
---@return string 主界面侧边栏入口文本
function UIHauteCoutureKR:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title3")
end
