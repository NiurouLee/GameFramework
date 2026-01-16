---@class UISerialAutoFightSweepResult:UIController
_class("UISerialAutoFightSweepResult", UIController)
UISerialAutoFightSweepResult = UISerialAutoFightSweepResult

--- @class UISerialAutoFightSweepState
local UISerialAutoFightSweepState = {
    Start = 1, -- 扫荡中
    Pause = 2, -- 暂停中
    Fin = 3    -- 扫荡完成
}
_enum("UISerialAutoFightSweepState", UISerialAutoFightSweepState)

function UISerialAutoFightSweepResult:OnShow(uiParams)
    self:_SetStyleUI(uiParams and uiParams[1])             -- 风格
    self._matchType = uiParams and uiParams[2]             -- 关卡类型
    self._stageId = uiParams and uiParams[3]               -- 关卡id
    self._maxProgress = uiParams and uiParams[4]           -- 扫荡次数
    self._trackData = uiParams and uiParams[5]             -- 跳转数据
    self._componentId = uiParams and uiParams[6]           -- 活动 组件id
    self._componentId = self._componentId or 0
    self._campaignMissionParams = uiParams and uiParams[7] -- CampaignMissionParams
    self._campaignMissionParams = self._campaignMissionParams or {}
    self._curProgress = 0

    self._tipsCallback = function(matid, pos)
        UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
    end

    self:_SetLvExp()
    self:_SetTargetItem(self._trackData)
    self:_SetRewards(self._maxProgress)

    UIWidgetHelper.SetAnimationPlay(self, "_anim", "uieff_UISerialAutoFightSweepResult_in")

    self:ContinueBtnOnClick()
    self:_AttachEvents()
end

function UISerialAutoFightSweepResult:ShowTips(matid, pos)
    UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
end

function UISerialAutoFightSweepResult:OnHide()
end

function UISerialAutoFightSweepResult:_SetStyleUI(styleName)
    self._styleName = styleName

    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "bg_di01", self, "_bg")
    UISerialAutoFightStyleHelper.FitStyle_Widget(self._styleName, "line01", self, "_line")
end

--region UI

function UISerialAutoFightSweepResult:_Refresh(matchRes)
    if not self.view then
        return
    end

    local needPause = false
    if matchRes then -- 刷新
        self._curProgress = self._curProgress + 1

        self._lvExp:Refresh(matchRes)
        if self._targetItem then
            needPause = self._targetItem:Refresh()
        end
        self._rewards:Refresh(self._curProgress, matchRes)
    end

    if self._curProgress == self._maxProgress then -- 战斗数量足够
        self:_SetStateWithAnim(UISerialAutoFightSweepState.Fin)
        return
    end

    if needPause then -- 首次达到目标物品数量
        self:_SetStateWithAnim(UISerialAutoFightSweepState.Pause, function()
            self:_ShowPauseMsgBox()
        end)
        return
    end

    self:_StartSweep() -- 扫荡下一场
end

function UISerialAutoFightSweepResult:_ShowPauseMsgBox()
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_battle_auto_fight_sweep_enough_msgbox"), -- title
        function()                                                    -- ok callback
            ---@type SerialAutoFightJumpData
            local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
            if not jumpData:JumpBack() then
                self:SwitchState(UIStateType.UIMain)
            end
        end,
        nil,
        function(param) -- cancel callback
            -- self:ContinueBtnOnClick()
        end,
        nil
    )
end

function UISerialAutoFightSweepResult:_SetState(state)
    local tb = {
        [UISerialAutoFightSweepState.Start] = { "_txtTitle_Start", "PauseBtn" },
        [UISerialAutoFightSweepState.Pause] = { "_txtTitle_Pause", "ContinueBtn", "CloseBtn" },
        [UISerialAutoFightSweepState.Fin] = { "_txtTitle_Fin", "AgainBtn", "CloseBtn" }
    }
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, tb)
    UIWidgetHelper.SetObjGroupShow(objs, state)
    self._state = state
end

function UISerialAutoFightSweepResult:_SetLvExp()
    ---@type UISerialAutoFightSweepResultLvExp
    self._lvExp = UIWidgetHelper.SpawnObject(self, "_lvExp", "UISerialAutoFightSweepResultLvExp")
    self._lvExp:SetStyleUI(self._styleName)
    self._lvExp:SetData()
end

function UISerialAutoFightSweepResult:_SetTargetItem(trackData)
    ---@type SerialAutoFightJumpData
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    local isShow = jumpData:IsShowTargetItem(trackData)
    if not isShow then
        return
    end
    local itemId, itemCondition = jumpData:GetTargetItem()

    ---@type UISerialAutoFightSweepResultTargetItem
    self._targetItem = UIWidgetHelper.SpawnObject(self, "_targetItem", "UISerialAutoFightSweepResultTargetItem")
    self._targetItem:SetStyleUI(self._styleName)
    self._targetItem:SetData(2, itemId, itemCondition, self._tipsCallback)
end

function UISerialAutoFightSweepResult:_SetRewards(maxProgress)
    ---@type UISerialAutoFightSweepRewards
    self._rewards = UIWidgetHelper.SpawnObject(self, "_rewards", "UISerialAutoFightSweepResultRewards")
    self._rewards:SetStyleUI(self._styleName)
    self._rewards:SetData(maxProgress, self._tipsCallback)
end

function UISerialAutoFightSweepResult:_SetNotEnough()
    ---@type ResDungeonModule
    local resModule = self:GetModule(ResDungeonModule)
    local total = resModule:GetDoubleResNum()
    local isShow = total <= 0
    if self._matchType == MatchType.MT_Season then
        isShow = false --赛季不用携行者 不显示不足提示
    end
    self:GetGameObject("_notEnough"):SetActive(isShow)
end

--endregion

--region Logic

function UISerialAutoFightSweepResult:_StartSweep()
    self:StartTask(function(TT)
        local duration = UISerialAutoFightConst.GetSweepDuration()
        YIELD(TT, duration)

        if self.view and self._waitForPause then
            self._waitForPause = false
            self:_SetStateWithAnim(UISerialAutoFightSweepState.Pause)
            return
        end

        if self.view and self._state == UISerialAutoFightSweepState.Start then
            local matchType = self._matchType
            local stageId = self._stageId
            local sweepTimes = 1

            ---@type GameMatchModule
            local gameMatchModule = GameGlobal.GetModule(GameMatchModule)
            gameMatchModule:Start_MatchSweep(matchType, stageId, sweepTimes, self._componentId,
                self._campaignMissionParams, function(res, matchResult)
                    if res:GetSucc() then
                        self:_Refresh(matchResult)
                    end
                end)
        end
    end)
end

--endregion

--region Event

function UISerialAutoFightSweepResult:PauseBtnOnClick()
    self._waitForPause = true
end

function UISerialAutoFightSweepResult:ContinueBtnOnClick()
    self:_SetStateWithAnim(UISerialAutoFightSweepState.Start, function()
        self:_StartSweep()
    end)
end

function UISerialAutoFightSweepResult:AgainBtnOnClick()
    self:_CloseDialogWithAnim(function()
        ---@type SerialAutoFightJumpData
        local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
        jumpData:OpenOptionAgain()
    end)
end

function UISerialAutoFightSweepResult:CloseBtnOnClick()
    self:_CloseDialogWithAnim()
end

--endregion

--region AttachEvent

function UISerialAutoFightSweepResult:_AttachEvents()
    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
end

function UISerialAutoFightSweepResult:_DetachEvents()
end

--endregion

function UISerialAutoFightSweepResult:_CloseDialogWithAnim(callback)
    UIWidgetHelper.PlayAnimation(self, "_anim", "uieff_UISerialAutoFightSweepResult_out", 200, function()
        if callback then
            callback()
        end
        self:CloseDialog()
        self:DispatchEvent(GameEventType.OnSerialAutoFightSweepFinish)
    end)
end

function UISerialAutoFightSweepResult:_SetStateWithAnim(state, callback)
    if state == self._state then
        return
    end

    if state == UISerialAutoFightSweepState.Fin then
        self:_SetNotEnough()
    end

    if (self._state == nil) then -- 首次进入不播放切换动效
        self:_SetState(state)

        if callback then
            callback()
        end
        return
    end

    local animInfo = {
        [UISerialAutoFightSweepState.Start] = { animName = "uieff_UISerialAutoFightSweepResult_start", duration = 367 },
        [UISerialAutoFightSweepState.Pause] = { animName = "uieff_UISerialAutoFightSweepResult_pause", duration = 333 },
        [UISerialAutoFightSweepState.Fin] = { animName = "uieff_UISerialAutoFightSweepResult_finish", duration = 333 }
    }
    local animName, duration = animInfo[state].animName, animInfo[state].duration

    UIWidgetHelper.PlayAnimation(self, "_anim", animName, duration,
        function()
            self:_SetState(state)

            if callback then
                callback()
            end
        end
    )
end
