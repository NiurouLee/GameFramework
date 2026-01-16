---@class UIMapNodeNotReachPart:UIMapNodeBasePart
_class("UIMapNodeNotReachPart", UIMapNodeBasePart)
UIMapNodeNotReachPart = UIMapNodeNotReachPart

---@overload
function UIMapNodeNotReachPart:GetUIComponentStar()
end
---@overload
function UIMapNodeNotReachPart:FlushStar()
end

function UIMapNodeNotReachPart:Flush()
    UIMapNodeNotReachPart.super.Flush(self)
    local stage = self.nodeInfo.stages[1]
    local cfg_mission = Cfg.cfg_mission[stage.id]
    if cfg_mission then
        local level = cfg_mission.NeedLevel
        if level then
            self.txtIdx:SetText(level .. StringTable.Get("str_discovery_level_not_reach_tip"))
        end
    end
end

---@overload
function UIMapNodeNotReachPart:ClickItem()
end
