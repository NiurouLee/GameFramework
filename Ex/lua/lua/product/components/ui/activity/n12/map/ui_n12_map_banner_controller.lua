require "ui_n12_map_controller"

---@class UIN12MapBannerController : UIN12MapController
_class("UIN12MapBannerController", UIN12MapController)
UIN12MapBannerController = UIN12MapBannerController

function UIN12MapBannerController:OnValue()
    local cfg = self:Cfg()
    local params = cfg.Params[1]
    local bannerid = params.BannerID
    local bannerType = params.BannerType

    if bannerType == 1 then
        GameGlobal.UIStateManager():ShowDialog(
            "UIStoryController",
            bannerid,
            function()
                self:OnStoryEnd()
            end
        )
    elseif bannerType == 2 then
        GameGlobal.UIStateManager():ShowDialog("UIStoryBanner", bannerid,StoryBannerShowType.HalfPortrait,function()
            self:OnStoryEnd()
        end)
    elseif bannerType == 3 then
        self:OnStoryEnd()
    end
end
function UIN12MapBannerController:OnStoryEnd()
    --检查这个路点有没有获取过奖励
    self._got = self:CheckFinish()
    if self._got then
        self:CloseDialog()
    else
        self:RequestFinishEvent()
    end
end
function UIN12MapBannerController:OnFinishEvent(rewards)
    self:ShowDialog("UIN12MapGetRewardsController",StringTable.Get("str_n12_map_get_rewards_title"),rewards,function()
        self:CloseDialog()
    end)
end
--重写父类的hide，banner关闭时检测是不是第一次到达终点，和普通的检测完成度不一样
function UIN12MapBannerController:OnHide()
    if not self._got then
        UIActivityN12Helper.N12_MapNode_Over(self._nodeid,self._stageid,self._component)
    end
end
