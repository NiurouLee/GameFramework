--[[
    卡莲高级时装复刻数据
]]
---@class UIHauteCoutureKL_Review:UIHauteCoutureDataBase
_class("UIHauteCoutureKL_Review", UIHauteCoutureDataBase)
UIHauteCoutureKL_Review = UIHauteCoutureKL_Review

---@return RoleAssetID 代币ID
function UIHauteCoutureKL_Review:CostItemID()
    return RoleAssetID.RoleAssetDrawCardSeniorSkinKL_Re
end
---点击商店内的时装礼包打开高级时装注解main
function UIHauteCoutureKL_Review:ShopGoodsOnClick()
    GameGlobal.UIStateManager():ShowDialog("UIHauteCoutureDraw_Review")
end
---打开代币购买界面
function UIHauteCoutureKL_Review:BuyItem()
    --旧的逻辑不会调到这个方法，不用重写
end
---@return boolean 是否为复刻的高级时装
function UIHauteCoutureKL_Review:IsReview()
    return true
end
---@return HauteCoutureType
function UIHauteCoutureKL_Review:HC_Type()
    Log.exception("HC_Type()方法必须重写：", debug.traceback())
end
---@return string 抽奖主界面uiprefab
---@return string 抽奖主界面ui类名
function UIHauteCoutureKL_Review:GetMainUIInfo()
    Log.exception("GetMainUIInfo()方法必须重写：", debug.traceback())
end
---@return string 抽奖主界面背景图uiprefab
---@return string 抽奖主界面背景图ui类名
function UIHauteCoutureKL_Review:GetMainUIBgInfo()
    Log.exception("GetMainUIInfo()方法必须重写：", debug.traceback())
end
---@return string 主界面侧边栏入口文本
function UIHauteCoutureKL_Review:SideEnterText()
    return StringTable.Get("str_senior_skin_draw_lobby_enter_title")
end
