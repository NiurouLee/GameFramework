---@class UITestFuncSubpageN25Idol:UITestFuncSubpageBase
_class("UITestFuncSubpageN25Idol", UITestFuncSubpageBase)
UITestFuncSubpageN25Idol = UITestFuncSubpageN25Idol

---@type btnManager UITestFuncBtnManager
function UITestFuncSubpageN25Idol:_FillData(btnManager)
    self:_Start_GetCampaignInfo()

    btnManager:_AddFunSwitchState("N25Main", UIStateType.UIActivityN25MainController)
    btnManager:_AddFunSwitchState("Login", UIStateType.UIN25IdolLogin)
    btnManager:_AddFunShowDialog("Game", "UIN25IdolGame")
    btnManager:_AddFunShowDialog("训练", "UIN25IdolGameTraining")
    btnManager:_AddFunShowDialog("突发事件", "UIN25IdolGamePuppy", {16, 1, nil, nil, true}) -- 事件 ID
    btnManager:_AddFunShowDialog("约定事件", "UIN25IdolApController", {50371401}) -- 事件 ID
    btnManager:_AddFunShowDialog("偶像活动", "UIN25IdolAct", true)

    btnManager:_AddCallback("下一个状态", function()
        self:_Debug_NextState()
    end)
end

function UITestFuncSubpageN25Idol:_Start_GetCampaignInfo()
    self:StartTask(self._LoadData, self)
end

function UITestFuncSubpageN25Idol:_LoadData(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)

    self._campaignType = ECampaignType.CAMPAIGN_TYPE_N25
    self._componentId = ECampaignN25ComponentID.ECAMPAIGN_N25_IDOL

    ---@type UIActivityCampaign
    self._campaign = UIActivityHelper.LoadDataOnEnter(TT, res, self._campaignType, {self._componentId})

    ---@type IdolMiniGameComponent
    self._component = self._campaign:GetComponent(self._componentId)
    self._componentInfo = self._campaign:GetComponentInfo(self._componentId)
end

function UITestFuncSubpageN25Idol:_Debug_NextState()
    local tb = {
        [IdolRoundState.IdolRoundState_None] = 0, 
        [IdolRoundState.IdolRoundState_Begin] = 0,
        [IdolRoundState.IdolRoundState_Play] = 0,
        [IdolRoundState.IdolRoundState_End] = 1
        }
    local roundState = self._componentInfo.break_info.round_state
    local t = tb[roundState]
    if t then
        local nextIndex = self._componentInfo.break_info.round_index + t
        local nextState = (roundState % IdolRoundState.IdolRoundState_End) + 1
        local trainType = (nextState == IdolRoundState.IdolRoundState_Play) and IdolTrainType.IdolTrainType_Music or IdolTrainType.IdolTrainType_None
        self._component:Start_HandleIdolTrain(nextIndex, nextState, trainType)
    end
end