--[[
    家园商店辅助类
]]
---@class UIHomelandShopHelper
_class("UIHomelandShopHelper", Object)
UIHomelandShopHelper = UIHomelandShopHelper

--
function UIHomelandShopHelper:Constructor()
end

--region helper

--
function UIHomelandShopHelper.ShowHomelandMessageBox_OK_Cancel(title, desc, callback)
    local btn1Data = {
        StringTable.Get("str_common_cancel"),
        function(param)
        end
    }
    local btn2Data = {
        StringTable.Get("str_common_ok"),
        callback
    }
    local hideCloseBtn = true
    GameGlobal.UIStateManager():ShowDialog("UIHomelandMessageBox", title, desc, btn1Data, btn2Data, hideCloseBtn)
end

-- 检测家园币溢出
--[[
    商店订单
    商店物品卖出
    签到
    任务奖励
    寻宝 随机的不提示
]]
function UIHomelandShopHelper.CheckCoinOverflow(count, callback)
    local key = GameGlobal.GameLogic():GetOpenId() .. "_HomeReachCoinCeiling"
    if LocalDB.GetInt(key, 0) > 0 then
        if callback then
            callback()
        end
        return
    end
    local cur = UIHomelandShopHelper.GetCoinItemCount()
    local check = (cur > GameGlobal.MAX_ITEM_OVERLAY - count)

    if check then
        -- 售出溢出确认弹窗
        local title = StringTable.Get("str_homeland_shop_check_overflo_title")
        local desc = StringTable.Get("str_homeland_shop_check_overflo_desc")
        local onconfirm = function()
            LocalDB.SetInt(key, 1)
            if callback then
                callback()
            end
        end
        UIHomelandShopHelper.ShowHomelandMessageBox_OK_Cancel(title, desc, onconfirm)
    else
        if callback then
            callback()
        end
    end
end

-- 检测稀有物品
function UIHomelandShopHelper.CheckSellRare(itemId, callback)
    local check = UIHomelandShopHelper.GetItemSellRare(itemId)

    if check then
        -- 售出稀有确认弹窗
        local title = StringTable.Get("str_homeland_shop_tab_sell_confirm_title")
        local desc = StringTable.Get("str_homeland_shop_tab_sell_confirm_desc")
        UIHomelandShopHelper.ShowHomelandMessageBox_OK_Cancel(title, desc, callback)
    else
        if callback then
            callback()
        end
    end
end

--endregion

--region Coin

--
function UIHomelandShopHelper.GetCoinItemId()
    local itemId = UIHomelandShopHelper._GetIdFromCfg()
    return itemId
end

function UIHomelandShopHelper._GetIdFromCfg()
    local cfgs = Cfg.cfg_homeland_univalence {}
    for _, v in pairs(cfgs) do
        return v.GainItemId
    end
end

--
function UIHomelandShopHelper.GetCoinItemIconName()
    return UIHomelandShopHelper.GetItemIconName(UIHomelandShopHelper.GetCoinItemId())
end

--
function UIHomelandShopHelper.GetCoinItemCount(format)
    local count = UIHomelandShopHelper.GetItemCount(UIHomelandShopHelper.GetCoinItemId())
    return format and HelperProxy:GetInstance():FormatItemCount(count) or count
end

--
function UIHomelandShopHelper.GetItemName(itemId)
    local cfg = Cfg.cfg_item[itemId]
    return cfg and cfg.Name
end

--
function UIHomelandShopHelper.GetItemIconName(itemId)
    local cfg = Cfg.cfg_item[itemId]
    return cfg and cfg.Icon
end

--
function UIHomelandShopHelper.GetItemCount(itemId)
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    local itemCount = itemModule:GetItemCount(itemId)
    return itemCount
end

function UIHomelandShopHelper.GetItemCount_ForSale(itemId)
    -- 许愿池中的鱼不可出售
    ---@type HomelandModule
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    local fishInWishing = homelandModule:GetFishsInWishingBuilding()
    local count_NotForSale = fishInWishing[itemId] or 0
    -- 水族箱中的鱼不可出售
    local fishInAquarium = homelandModule:GetFishsInAquarium()
    local countInAquarium = 0
    for buildPstID, fishs in pairs(fishInAquarium) do
        local curCount = fishs[itemId] or 0
        countInAquarium = countInAquarium + curCount
    end

    return UIHomelandShopHelper.GetItemCount(itemId) - count_NotForSale - countInAquarium
end

--
function UIHomelandShopHelper.CalcItemSellPrice(itemId, count)
    local cfg = Cfg.cfg_homeland_univalence[itemId]
    local price = cfg and cfg.Sell or 0

    local roleAsset = RoleAsset:New()
    roleAsset.assetid = UIHomelandShopHelper.GetCoinItemId()
    -- roleAsset.assetid = cfg.GainItemId
    roleAsset.count = price * count

    return roleAsset
end

--
function UIHomelandShopHelper.GetItemSellRare(itemId)
    local cfg = Cfg.cfg_homeland_univalence[itemId]
    return cfg and cfg.Rare == 1 or false
end

--endregion

--region goods helper

--
function UIHomelandShopHelper.CheckOrderSubmit()
    ---@type HomelandModule
    local homeLandModule = GameGlobal.GetModule(HomelandModule)
    local shop_info = homeLandModule.m_homeland_info.shop_info

    for i, v in pairs(shop_info.goods_info) do
        if UIHomelandShopHelper.CheckOrderRequire(v.item_info) then
            return true
        end
    end
    return false
end

--
function UIHomelandShopHelper.CheckOrderRequire(good_info)
    for _, v in ipairs(good_info) do
        local count = UIHomelandShopHelper.GetItemCount_ForSale(v.assetid)
        if count < v.count then
            return false
        end
    end
    return true
end

--
function UIHomelandShopHelper.GetGoodsRefreshCount()
    local itemId = Cfg.cfg_homeland_global["GoodsRefreshItemId"].IntValue
    local itemCount = UIHomelandShopHelper.GetItemCount(itemId)
    local maxCount = Cfg.cfg_homeland_global["GoodsMaxRefreshCount"].IntValue
    return itemCount, maxCount
end

--
function UIHomelandShopHelper.GetGoodsExtraColor(n)
    local color = "#FFFFFF"
    local cfg = Cfg.cfg_homeland_shop_order_color {}
    for _, v in ipairs(cfg) do
        color = v.Color
        if n < v.Count then
            break
        end
    end
    return color
end

--
function UIHomelandShopHelper.Hex2Color(hex)
    local default_color = Color.white

    local len = string.len(hex)
    if len ~= 7 or string.sub(hex, 1, 1) ~= "#" then
        return default_color
    end

    local str_2_hex = function(str)
        return tonumber(str, 16) or 255
    end

    local r = str_2_hex(string.sub(hex, 2, 3))
    local g = str_2_hex(string.sub(hex, 4, 5))
    local b = str_2_hex(string.sub(hex, 6, 7))
    return Color(r / 255, g / 255, b / 255)
end

--endregion

--region Req helper

--
function UIHomelandShopHelper.ShowHomelandRewards(rewards)
    GameGlobal.UIStateManager():ShowDialog(
        "UIHomeShowAwards",
        rewards,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
        end,
        true,
        nil
    )
end

--
---@type id cfg_homeland_shop 的 ID
function UIHomelandShopHelper.Start_HomelandShopReq(id, num, rewards)
    Log.info("UIHomelandShopHelper.Start_HomelandShopReq() id = ", id, " num = ", num)
    TaskManager:GetInstance():StartTask(
        function(TT)
            ---@type HomelandModule
            local homeLandModule = GameGlobal.GetModule(HomelandModule)
            local res, shop_info = homeLandModule:HomelandShopReq(TT, id, num)
            if res and res:GetSucc() then
                Log.info("HomelandModule:Start_HomelandShopReq() Succ")
                -- ToastManager.ShowHomeToast("HomelandModule:Start_HomelandShopReq() Succ")

                UIHomelandShopHelper.ShowHomelandRewards(rewards)
            else
                Log.error("HomelandModule:Start_HomelandShopReq() Failed, ", res.m_result)
                ToastManager.ShowHomeToast("HomelandModule:Start_HomelandShopReq() Failed, " .. res.m_result)

                GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
            end
        end
    )
end

--
function UIHomelandShopHelper.Start_HomelandGoodReq(index, isSell, rewards)
    index = index - 1 -- 服务器数据从 0 开始

    Log.info("UIHomelandShopHelper.Start_HomelandGoodReq() index = ", index, " isSell = ", tostring(isSell))
    TaskManager:GetInstance():StartTask(
        function(TT)
            ---@type HomelandModule
            local homeLandModule = GameGlobal.GetModule(HomelandModule)
            local res, shop_info = homeLandModule:HomelandGoodsReq(TT, index, isSell)
            if res and res:GetSucc() then
                Log.info("UIHomelandShopHelper.Start_HomelandGoodReq() Succ")
                -- ToastManager.ShowHomeToast("UIHomelandShopHelper.Start_HomelandGoodReq() Succ")

                if isSell then
                    UIHomelandShopHelper.ShowHomelandRewards(rewards)
                else
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
                end
            else
                Log.error("UIHomelandShopHelper.Start_HomelandGoodReq() Failed, ", res.m_result)
                ToastManager.ShowHomeToast("UIHomelandShopHelper.Start_HomelandGoodReq() Failed, " .. res.m_result)

                GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
            end
        end
    )
end

--
function UIHomelandShopHelper.Start_HomelandSellReq(id_num, rewards)
    Log.info("UIHomelandShopHelper.Start_HomelandSellReq()")
    -- local id_num = {[3210101] = 1}

    TaskManager:GetInstance():StartTask(
        function(TT)
            ---@type HomelandModule
            local homeLandModule = GameGlobal.GetModule(HomelandModule)
            local res, shop_info = homeLandModule:HomelandSellReq(TT, id_num)
            if res and res:GetSucc() then
                Log.info("HomelandModule:HomelandSellReq() Succ")
                -- ToastManager.ShowHomeToast("HomelandModule:HomelandSellReq() Succ")

                UIHomelandShopHelper.ShowHomelandRewards(rewards)
            else
                Log.error("HomelandModule:HomelandSellReq() Failed, ", res.m_result)
                ToastManager.ShowHomeToast("HomelandModule:HomelandSellReq() Failed, " .. res.m_result)

                GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
            end
        end
    )
end

--
function UIHomelandShopHelper.Start_HomelandShopRefreshReq(delay)
    Log.info("UIHomelandShopHelper.Start_HomelandShopRefreshReq()")

    TaskManager:GetInstance():StartTask(
        function(TT)
            YIELD(TT, delay * 1000) -- 延迟

            ---@type HomelandModule
            local homeLandModule = GameGlobal.GetModule(HomelandModule)
            local res, shop_info = homeLandModule:HomelandShopRefreshReq(TT)
            if res and res:GetSucc() then
                -- ToastManager.ShowHomeToast("HomelandModule:Start_HomelandShopRefreshReq() Succ")
                Log.info("HomelandModule:Start_HomelandShopRefreshReq() Succ")
            else
                Log.error("HomelandModule:Start_HomelandShopRefreshReq() Failed, ", res.m_result)
                ToastManager.ShowHomeToast("HomelandModule:Start_HomelandShopRefreshReq() Failed, " .. res.m_result)
            end
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandShopUpdate)
        end
    )
end

--endregion
