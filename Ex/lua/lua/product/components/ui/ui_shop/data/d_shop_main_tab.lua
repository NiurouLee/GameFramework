--[[
    商城:主页签数据
]]
---@class DShopMainTab
_class("DShopMainTab", Object)
---@class DShopMainTab:Object
DShopMainTab = DShopMainTab

local StringGet = StringTable.Get
function DShopMainTab:Constructor(cfg)
    if not cfg then
        return
    end
    self.cfg = cfg
end

---@public
---获取Id
function DShopMainTab:GetId()
    return self.cfg.ID
end
---@public
function DShopMainTab:GetMainTab()
    return self.cfg.MainTab
end

---@public
---获取tab名
function DShopMainTab:GetName()
    return StringTable.Get(self.cfg.TabName)
end

---@public
---获取tab名
function DShopMainTab:GetEnName()
    return self.cfg.EnName
end

---@public
---获取tab icon
function DShopMainTab:GetIcon()
    return self.cfg.TabIcon
end

---@public
---获取tab icon
function DShopMainTab:GetSelectIcon()
    return self.cfg.TabIconSelect
end

---@public
---是否开放
function DShopMainTab:IsOpen()
    local mainTabType = self:GetMainTab()
    return UIShopController.CheckIsOpen(mainTabType)
end

function DShopMainTab:GetSortIndex()
    return self.cfg.SortIndex
end
