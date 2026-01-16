--
---@class UIN5ReviewProgressAwardDetail : UIController
_class("UIN5ReviewProgressAwardDetail", UIController)
UIN5ReviewProgressAwardDetail = UIN5ReviewProgressAwardDetail

---@param res AsyncRequestRes
function UIN5ReviewProgressAwardDetail:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end
--初始化
function UIN5ReviewProgressAwardDetail:OnShow(uiParams)
    self:InitWidget()
    self.CallBack = uiParams[1]
    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    ---@type UIReviewActivityN1
    self._reviewData = uiModule:GetReviewData():GetActivityByType(ECampaignType.CAMPAIGN_TYPE_REVIEW_N5)
    ---@type UIActivityCampaign
    self._campaign = self._reviewData:GetDetailInfo()
    ---@type PointProgressComponent 进度组件
    self._progressCom = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_POINT_PROGRESS, 1)
    ---@type PointProgressComponentInfo
    self._progressInfo = self._progressCom:GetComponentInfo()

    self.selectInfoLoader = self:GetUIComponent("UISelectObjectPath", "selectInfo")

    self._allAwards = {}
    for progress, award in pairs(self._progressInfo.m_progress_rewards) do
        --每个进度只取第1个奖励
        table.insert(self._allAwards, {Progress = progress, AwardID = award[1].assetid, Count = award[1].count})
    end
    table.sort(
        self._allAwards,
        function(a, b)
            return a.Progress < b.Progress
        end
    )

    local delay = 0
    ---@type UIN5ReviewProgressAwardDetailItem[]
    local uis = self.awards:SpawnObjects("UIN5ReviewProgressAwardDetailItem", #self._allAwards)
    for index, award in ipairs(self._allAwards) do
        local item = uis[index]
        item:SetData(
            award.AwardID,
            award.Count,
            award.Progress,
            table.icontains(self._progressInfo.m_received_progress, award.Progress),
            self._reviewData:ProgressPercent() >= award.Progress,
            function(id, go)
                self:OnClickAward(id, go)
            end,
            function (progress)
                self:GetReward(progress)
            end
        )
        item:PlayEnterAni(delay)
        delay = delay + 30
    end
end

function UIN5ReviewProgressAwardDetail:GetReward(progress)
    self:StartTask(self.GetRewardCoro, self, progress)
end

function UIN5ReviewProgressAwardDetail:GetRewardCoro(TT, progress)
    self:Lock("UIN5ReviewProgressAwardDetail")
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    local rewards = self._progressCom:HandleReceiveReward(TT, res, progress)
    if rewards and #rewards > 0 then
        UIActivityHelper.ShowUIGetRewards(rewards)
        self.CallBack()
    end

    self:UnLock("UIN5ReviewProgressAwardDetail")
end

--获取ui组件
function UIN5ReviewProgressAwardDetail:InitWidget()
    ---@type UICustomWidgetPool
    self.awards = self:GetUIComponent("UISelectObjectPath", "awards")
    ---@type UnityEngine.Animation
    self.animation = self:GetUIComponent("Animation", "animation")
end
--按钮点击
function UIN5ReviewProgressAwardDetail:CloseOnClick(go)
    self:StartTask(
        function (TT)
            local lockName = "UIN5ReviewProgressAwardDetail_OutAni"
            self:Lock(lockName)
            self.animation:Play("uieff_N24_Main_Review_SafeArea_bg_out01")
            YIELD(TT, 120)
            self:UnLock(lockName)
            self:CloseDialog()
        end
    )
end

function UIN5ReviewProgressAwardDetail:OnClickAward(itemID, go)
    if not self._selectInfo then
        ---@type UISelectInfo
        self._selectInfo = self.selectInfoLoader:SpawnObject("UISelectInfo")
    end
    self._selectInfo:SetData(itemID, go.transform.position)
end
