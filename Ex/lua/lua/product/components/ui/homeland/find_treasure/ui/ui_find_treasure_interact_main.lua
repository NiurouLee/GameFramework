---@class UIFindTreasureInteractMain:UIController
_class("UIFindTreasureInteractMain", UIController)
UIFindTreasureInteractMain = UIFindTreasureInteractMain


--
--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIFindTreasureInteractMain:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = HomelandFindTreasureConst.GetCampaignType()
    self._componentId = HomelandFindTreasureConst.GetComponentType()

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

function UIFindTreasureInteractMain:OnShow(uiParams)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, false)
    self._loader = self:GetUIComponent("UISelectObjectPath", "Loader")
    local ui = self._loader:SpawnObject("UIFindTreasureInteract")
    ui:Init(self)
end

function UIFindTreasureInteractMain:OnHide()
end

function UIFindTreasureInteractMain:Exit()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, true)
    self:CloseDialog()
end

function UIFindTreasureInteractMain:Enter()
    self:CloseDialog()
    UIActivityHelper.PlayFirstPlot_Component(
        self._campaign,
        self._componentId,
        function()
            self:ShowDialog("UIFindTreasureDetail", false)
        end
    )
end
