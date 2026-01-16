--- @class UIN12EntrustStageController:UIController
_class("UIN12EntrustStageController", UIController)
UIN12EntrustStageController = UIN12EntrustStageController

--region help
function UIN12EntrustStageController:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN12EntrustStageController:_SpawnObjects(widgetName, className, count)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local objs = {}
    pool:SpawnObjects(className, count, objs)
    return objs
end

function UIN12EntrustStageController:_PlayAnim(widgetName, animName, time, callback)
    local anim = self:GetUIComponent("Animation", widgetName)

    self:Lock(animName)
    anim:Play(animName)
    self:StartTask(
        function(TT)
            YIELD(TT, time)
            self:UnLock(animName)
            if callback then
                callback()
            end
        end,
        self
    )
end

function UIN12EntrustStageController:_GetRoleId()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    return pstId
end

--endregion

function UIN12EntrustStageController:_InitWidget()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self._campaign._campaign_module:CampaignSwitchState(
                true,
                UIStateType.UIN12MainController,
                UIStateType.UIMain,
                nil,
                self._campaign._id
            )
        end,
        function()
            self:ShowDialog("UIN12EntrustStageIntroController", "UIN12EntrustStageIntroController")
        end,
        nil,
        false
    )

    local bg = self:GetGameObject("_bg")
    bg:SetActive(true)
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN12EntrustStageController:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N12
    self._componentId = ECampaignN12ComponentID.ECAMPAIGN_N12_ENTRUST

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, self._componentId)
    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end
end

function UIN12EntrustStageController:OnShow(uiParams)
    self:_AttachEvents()

    self._isOpen = true
    UIActivityN12Helper.EntrustClearNew()

    -- 首次剧情
    UIActivityHelper.PlayFirstPlot_Component(
        self._campaign,
        self._componentId,
        function()
            self:_Init()
        end
    )
end

function UIN12EntrustStageController:OnHide()
    self:_DetachEvents()
    self._isOpen = false
end

function UIN12EntrustStageController:_Init()
    self:_InitWidget()
    self:_Refresh()
    self:_RecordEnteredEntrust()
end

function UIN12EntrustStageController:_Refresh()
    self:_SetNode()
    self:_SetLine()
end

function UIN12EntrustStageController:_RecordEnteredEntrust()
    N12ToolFunctions.SetLocalDBInt(N12OperationRecordKey.EnteredEntrust, 1)
end

function UIN12EntrustStageController:_SetNode()
    ---@type EntrustComponent
    local component = self._campaign:GetComponent(self._componentId)

    local tb = component:GetAllLevelId()
    -- local tb = {101501, 101502, 101503, 101504, 101505, 101506} --Hack: 关卡列表

    ---@type UIN12EntrustStageNode[]
    local objs = self:_SpawnObjects("_nodes", "UIN12EntrustStageNode", table.count(tb))
    for i, v in ipairs(objs) do
        v:SetData(self._campaign, tb[i])
        v:SetPos(component:GetStagePointPos(tb[i]))

        local cfg = Cfg.cfg_n12_entrust_anim[1]
        local delayTime = cfg.StageNodeDelayTime
        v:PlayAnim(i, "_anim", "uieff_StageNode_In", i * delayTime, 500) -- 间隔 66ms，播放 500ms
    end
end

function UIN12EntrustStageController:_SetLine()
    ---@type EntrustComponent
    local component = self._campaign:GetComponent(self._componentId)

    local tb = component:GetAllLevelId()

    ---@type UIN12EntrustStageLine[]
    local objs = self:_SpawnObjects("_lines", "UIN12EntrustStageLine", table.count(tb) - 1)
    for i, v in ipairs(objs) do
        local from = component:GetStagePointPos(tb[i])
        local to = component:GetStagePointPos(tb[i + 1])
        v:SetPos(from, to)

        local cfg = Cfg.cfg_n12_entrust_anim[1]
        local delayTime = cfg.StageLineDelayTime
        local time = cfg.StageLineTime
        v:PlayAnim(i, "shape", i * delayTime, 100) -- 间隔 100ms，播放 100ms
    end
end

--region Event Callback
--活动说明
-- function UIN12EntrustStageController:InfoBtnOnClick(go)
--     UIActivityHelper.ShowActivityIntro("UIN9Intro")
-- end
--endregion

--region AttachEvent
function UIN12EntrustStageController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIN12EntrustStageController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
end

function UIN12EntrustStageController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

--endregion
