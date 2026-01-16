--- @class UIN5MainController_Review:UIController
_class("UIN5MainController_Review", UIController)
UIN5MainController_Review = UIN5MainController_Review

function UIN5MainController_Review:_GetComponents()
    --self._mainBg = self:GetUIComponent("RawImageLoader", "_mainBg")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIActivityReview)
        end,
        nil,
        nil,
        false,
        function()
            self:HideBtnOnClick()
        end
    )

    ---@type UICustomWidgetPool
    self._lineMissionRedPoint = self:GetUIComponent("UISelectObjectPath", "_lineMissionRedPoint")
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN5MainController_Review:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    self._campaignModule = campaignModule

    ---@type UICampaignModule
    local uiModule = GameGlobal.GetUIModule(CampaignModule)
    ---@type UIReviewActivityN5
    self._reviewData = uiModule:GetReviewData():GetActivityByType(ECampaignType.CAMPAIGN_TYPE_REVIEW_N5)
    self._reviewData:ReqDetailInfo(TT, res)
    self._campaign = self._reviewData:GetDetailInfo()

    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIN5MainController_Review:OnShow(uiParams)
    -- --- @type SvrTimeModule
    -- self._svrTimeModule = self:GetModule(SvrTimeModule)

    self._timePhase = nil
    self:_GetComponents()

    -- if not self._campaign:GetSample():GetStepStatus(ECampaignStep.CAMPAIGN_STEP_NEW) then
    --     self:_SetUI()
    -- else
    --     self:_SetFirstPlot()
    -- end

    local progressPool = self:GetUIComponent("UISelectObjectPath", "_progress")
    ---@type UIReviewProgress
    local progress = progressPool:SpawnObject("UIN5ReviewProgress")
    progress:SetData(self._reviewData)
    CutsceneManager.ExcuteCutsceneOut()
end

function UIN5MainController_Review:HideBtnOnClick()
    local root = self:GetGameObject("_root")
    root:SetActive(false)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(true)
end

function UIN5MainController_Review:ShowBtnOnClick()
    local root = self:GetGameObject("_root")
    root:SetActive(true)
    local showBtn = self:GetGameObject("_showBtn")
    showBtn:SetActive(false)
end

function UIN5MainController_Review:OnHide()
    self:_DetachEvents()
end

-- function UIN5MainController_Review:_SetFirstPlot()
--     local storyID = 0
--     local cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
--     if cfg_campaign then
--         storyID = cfg_campaign.FirstEnterStoryID[1]
--     end

--     if storyID == 0 then
--         self:_SetUI()
--         self:StartTask(
--             function(TT)
--                 local res = AsyncRequestRes:New()
--                 ---@type CampaignModule
--                 local campaignModule = GameGlobal.GetModule(CampaignModule)
--                 campaignModule:CampaignClearNewFlag(TT, res, self._campaign._id)
--                 if not res:GetSucc() then
--                     Log.info(
--                         "UIActivityEveSinsaMainController:_SetFirstPlot() CampaignClearNewFlag res.m_result = ",
--                         res.m_result
--                     )
--                 end
--             end,
--             self
--         )
--         return
--     end

--     self:ShowDialog(
--         "UIStoryController",
--         storyID,
--         function()
--             self:StartTask(
--                 function(TT)
--                     local res = AsyncRequestRes:New()
--                     ---@type CampaignModule
--                     local campaignModule = GameGlobal.GetModule(CampaignModule)
--                     campaignModule:CampaignClearNewFlag(TT, res, self._campaign._id)
--                     if not res:GetSucc() then
--                         Log.info(
--                             "UIActivityEveSinsaMainController:_SetFirstPlot() CampaignClearNewFlag res.m_result = ",
--                             res.m_result
--                         )
--                     end
--                     self:_SetUI()
--                 end,
--                 self
--             )
--         end
--     )
-- end


function UIN5MainController_Review:LineMissionBtnOnClick(go)
    self:StartTask(
        function(TT)
            self:Lock("UIN5MainControllerReviewPlayAnimation")
          --  self:_PlayBtnClickAnim(self._lineMissionBtnAnimation)
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N5NormalClick)
          --  YIELD(TT, self._btnClickAnimTime)
            if self:_CheckCampaignClose() or
                    not self:_GetComponentState(ECampaignReviewN5ComponentID.ECAMPAIGN_REVIEW_ReviewN5_LINE_MISSION)
             then
                --self:_RefreshUIInfo()
                ToastManager.ShowToast(StringTable.Get("str_activity_common_end"))
                self:UnLock("UIN5MainControllerReviewPlayAnimation")
                return
            end
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N5CloseDoor)
            self._campaignModule:CampaignSwitchState(
                true,
                UIStateType.UIActivityN5SimpleLevelReview,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
            self:UnLock("UIN5MainControllerReviewPlayAnimation")
        end,
        self
    )
end

function UIN5MainController_Review:_CheckCampaignClose()
    return not self._campaign:CheckCampaignOpen()
end

function UIN5MainController_Review:_GetComponentState(componentid)
    return self._campaign:CheckComponentOpen(componentid)
end

--region AttachEvent
function UIN5MainController_Review:_AttachEvents()
    --self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
  --  self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
end

function UIN5MainController_Review:_DetachEvents()
    --self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
   -- self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
end


function UIN5MainController_Review:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign then
        if (self._campaign._id == campaign_id) then
            self:_CheckRedPointAll()
        end
    end
end

function UIN5MainController_Review:_CheckRedPointAll()
    -- self:_CheckRedPoint(
    --     self._redTaskRewardBtn
    -- )
    -- self:_CheckRedPoint(
    --     self._redLoginRewardBtn
    -- )
end

function UIN5MainController_Review:_CheckRedPoint(obj, ...)
    obj:SetActive(false)
end