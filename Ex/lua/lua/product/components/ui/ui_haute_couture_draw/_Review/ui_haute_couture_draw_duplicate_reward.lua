--[[
    卡莲高级时装复刻奖励重复变更说明界面
]]
---@class UIHauteCoutureDrawDuplicateReward : UIController
_class("UIHauteCoutureDrawDuplicateReward", UIController)
UIHauteCoutureDrawDuplicateReward = UIHauteCoutureDrawDuplicateReward

---@param res AsyncRequestRes
function UIHauteCoutureDrawDuplicateReward:LoadDataOnEnter(TT, res)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    ---@type UIHauteCoutureDataBase 当前开放的高级时装复刻数据
    self.CtxData = campaignModule:GetCurHauteCouture_Review()
    if not self.CtxData then
        Log.fatal("没有开启的高级时装复刻活动")
        res:SetSucc(false)
        return
    end
    -- self._campaign = self.CtxData:ReqDetailInfo(TT, res)
    -- if not self._campaign then
    --     res:SetSucc(false)
    --     return
    -- end
    res:SetSucc(true)
end
--初始化
function UIHauteCoutureDrawDuplicateReward:OnShow(uiParams)
    self:InitWidget()

    local bg, bgClass = self.CtxData:Review_DuplicateRewardBgInfo()
    local ui, uiClass = self.CtxData:Review_DuplicateRewardUIInfo()

    if bg and bgClass then
        self.bg.dynamicInfoOfEngine:SetObjectName(bg)
        self.bg:SpawnObject(bgClass._className)
    end
    self.content.dynamicInfoOfEngine:SetObjectName(ui)
    ---@type UIHauteCoutureDrawDuplicateRewardBase
    local content = self.content:SpawnObject(uiClass._className)
    content:SetData(uiParams)
end

--获取ui组件
function UIHauteCoutureDrawDuplicateReward:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.bg = self:GetUIComponent("UISelectObjectPath", "bg")
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "content")
    --generated end--
end
