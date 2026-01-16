---@class UIMapNodeItemNotReach:UIMapNodeItemBase
_class("UIMapNodeItemNotReach", UIMapNodeItemBase)
UIMapNodeItemNotReach = UIMapNodeItemNotReach

---@overload
function UIMapNodeItemNotReach:GetUIComponentStar()
end
---@overload
function UIMapNodeItemNotReach:FlushStar()
end

function UIMapNodeItemNotReach:Flush()
    UIMapNodeItemNotReach.super.Flush(self)
    local stage = self.nodeInfo.stages[1]
    local cfg_mission = Cfg.cfg_mission[stage.id]
    if cfg_mission then
        local level = cfg_mission.NeedLevel
        if level then
            self.txtTip:SetText(level .. StringTable.Get("str_discovery_level_not_reach_tip"))
        end
    end
end

---@overload
function UIMapNodeItemNotReach:ClickItem()
end
