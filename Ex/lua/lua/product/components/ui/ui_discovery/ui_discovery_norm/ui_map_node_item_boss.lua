---@class UIMapNodeItemBoss:UIMapNodeItemBase
_class("UIMapNodeItemBoss", UIMapNodeItemBase)
UIMapNodeItemBoss = UIMapNodeItemBoss

function UIMapNodeItemBoss:OnShow()
    UIMapNodeItemBoss.super.OnShow(self)
    ---@type MultiplyImageLoader
    self._imgCG = self:GetUIComponent("MultiplyImageLoader", "imgCG")
end

---@overload
function UIMapNodeItemBoss:Flush()
    UIMapNodeItemBoss.super.Flush(self)
    local stageType = self.nodeInfo:GetStageType()
    if stageType == DiscoveryStageType.FightBoss then
        if state == DiscoveryStageState.CanPlay then
            self._imgCG:Load(self.nodeInfo.monstercg, "tip_big_multiply")
        else
            self._imgCG:Load(self.nodeInfo.monstercg, "white")
        end
    end
end

---@overload
function UIMapNodeItemBoss:GetTipAnimName()
    return "uieff_UINormNodeBoss_in"
end
