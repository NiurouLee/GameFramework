--- @class UIN22EntrustStageController:UIController
_class("UIN22EntrustStageController", UIController)
UIN22EntrustStageController = UIN22EntrustStageController

function UIN22EntrustStageController:_PlayAnimAndSwitchState(levelId)
    -- 检查活动组件是否开放
    if not self._campaign:CheckComponentOpen(self._componentId) then
        local result = self._campaign:CheckComponentOpenClientError(self._componentId)
        self._campaign:ShowErrorToast(result, true)
        return
    end

    UIWidgetHelper.PlayAnimation(self, "_anim", "uieff_UIN22EntrustStageController_out", 267, 
        function()
            self:SwitchState(UIStateType.UIN22EntrustLevelController, levelId, true)
        end
    )
end

function UIN22EntrustStageController:_SetCommonTopButton()
    ---@type UICommonTopButton
    self._backBtns = UIWidgetHelper.SpawnObject(self, "_backBtns", "UICommonTopButton")
    self._backBtns:SetData(
        function()
            self._campaign._campaign_module:CampaignSwitchState(
                true,
                UIStateType.UIActivityN22MainController,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end,
        function() -- 活动说明
            self:ShowDialog("UIIntroLoader", "UIN22Entrust_Intro")
        end,
        nil,
        false
    )
end

--
function UIN22EntrustStageController:_SetImgRT(imgRT)
    if imgRT ~= nil then
        ---@type UnityEngine.UI.RawImage
        local rt = self:GetUIComponent("RawImage", "rt")
        rt.texture = imgRT

        return true
    end
    return false
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN22EntrustStageController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N22
    self._componentId = ECampaignN22ComponentID.ECAMPAIGN_N22_ENTRUST

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, self._componentId)
    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end

    -- 检查活动组件是否开放
    if not self._campaign:CheckComponentOpen(self._componentId) then
        res.m_result = self._campaign:CheckComponentOpenClientError(self._componentId)
        self._campaign:ShowErrorToast(res.m_result, true)
        return
    end

    ---@type EntrustComponent
    self._component = self._campaign:GetComponent(self._componentId)
end

function UIN22EntrustStageController:OnShow(uiParams)
    self:_AttachEvents()

    --------------------------------------------------------------------------------
    -- 传入底图
    self:_SetImgRT(uiParams[1])

    self._isPlayEnter = uiParams[2] or false
    if self._isPlayEnter then
        UIWidgetHelper.PlayAnimation(self, "_anim", "uieff_UIN22EntrustStageController_in", 667)
    end

    self:_Init()
end

function UIN22EntrustStageController:OnHide()
    self:_DetachEvents()
end

function UIN22EntrustStageController:_Init()
    self:_ClearNew()
    self:_SetCommonTopButton()
    self:_Refresh()
end

function UIN22EntrustStageController:_ClearNew()
    self._component:EntrustStageClearNew()
end

function UIN22EntrustStageController:_Refresh()
    self:_SetNode()
    self:_SetLine()
end

function UIN22EntrustStageController:_SetNode()
    local tb = self._component:GetAllLevelId()

    ---@type UIN22EntrustStageNode[]
    local objs = UIWidgetHelper.SpawnObjects(self, "_nodes", "UIN22EntrustStageNode", table.count(tb))
    for i, v in ipairs(objs) do
        v:SetData(self._campaignType, self._componentId,  self._campaign,  tb[i], 
            function(levelId)
                self:_PlayAnimAndSwitchState(levelId)
            end
        )
        v:SetPos(self._component:GetStagePointPos(tb[i]))

        local start = self._isPlayEnter and 200 or 0 -- 从 200ms 开始播放
        local interval = 30 -- 间隔 30ms
        local delay = start + (i - 1) * interval
        local time = 500 -- 播放 500ms
        v:PlayAnim(i, "uieff_UIN22EntrustStage_Node_in", delay, time)
    end
end

function UIN22EntrustStageController:_SetLine()
    local tb = self._component:GetAllLevelId()

    ---@type UIN22EntrustStageLine[]
    local objs = UIWidgetHelper.SpawnObjects(self, "_lines", "UIN22EntrustStageLine", table.count(tb) - 1)
    for i, v in ipairs(objs) do
        local from = self._component:GetStagePointPos(tb[i])
        local to = self._component:GetStagePointPos(tb[i + 1])
        v:SetPos(from, to)

        local start = self._isPlayEnter and 200 + 200 or 0 + 200 -- 从第一个节点开始显示后的某个时间开始
        local interval = 30 -- 间隔 30ms
        local delay = start + (i - 1) * interval
        local time = 30 -- 播放 30ms
        v:PlayAnim(i, nil, delay, time) 
    end
end

--region AttachEvent

function UIN22EntrustStageController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIN22EntrustStageController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIN22EntrustStageController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

--endregion
