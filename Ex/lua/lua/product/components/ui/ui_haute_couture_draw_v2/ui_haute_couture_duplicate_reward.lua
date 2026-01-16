--[[
    高级时装复刻奖励重复变更说明界面父类
]]
---@class UIHauteCoutureDuplicateReward : UIController
_class("UIHauteCoutureDuplicateReward", UIController)
UIHauteCoutureDuplicateReward = UIHauteCoutureDuplicateReward

---@param res AsyncRequestRes
function UIHauteCoutureDuplicateReward:LoadDataOnEnter(TT, res)
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
function UIHauteCoutureDuplicateReward:OnShow(uiParams)
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
function UIHauteCoutureDuplicateReward:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.bg = self:GetUIComponent("UISelectObjectPath", "bg")
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "content")
    --generated end--
end
--按钮点击
function UIHauteCoutureDuplicateReward:CloseBtnOnClick(go)
    self:CloseDialog()
end

function UIHauteCoutureDuplicateReward:OnItemClick(id, pos)
    if self._selectInfo then
        self._selectInfo:SetData(id, pos)
    end
end
