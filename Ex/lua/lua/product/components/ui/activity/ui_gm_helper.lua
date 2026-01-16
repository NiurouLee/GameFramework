--[[
    活动辅助类
]]
---@class UIGMHelper:Object
_class("UIGMHelper", Object)
UIGMHelper = UIGMHelper

--
function UIGMHelper:Constructor()
end

--
function UIGMHelper.Start_SendCmdTask(cmd, callback)
    TaskManager:GetInstance():StartTask(
        function(TT)
            ---@type GMProxyModule
            local gmproxy = GameGlobal.GetModule(GMProxyModule)
            ---@type AsyncRequestRes
            local res = gmproxy:SendCmdTask(TT, cmd)
            if res.m_call_err ~= CallResultType.Normal then
                ToastManager.ShowToast("UIGMHelper.Start_SendCmdTask Failed, cmd = ", cmd)
            else
                ToastManager.ShowToast("UIGMHelper.Start_SendCmdTask() Succ")
            end

            if callback then
                callback()
            end
        end
    )
end

--
function UIGMHelper.AddAsset(itemId, count, callback)
    local cmd = string.format("add_asset %s %d %d", LocalDB.GetString("OpenIdTest"), itemId, count)
    UIGMHelper.Start_SendCmdTask(cmd, callback)
end

--
function UIGMHelper.ChangeQuestStatus(questId, status, b, callback)
    local cmd = string.format("ChangeQuestStatus %s %d %d %d", LocalDB.GetString("OpenIdTest"), questId, status, b)
    UIGMHelper.Start_SendCmdTask(cmd, callback)
end
