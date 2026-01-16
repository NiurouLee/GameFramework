---@class UIN17MainLobbyEntry : UICustomWidget
_class("UIN17MainLobbyEntry", UICustomWidget)
UIN17MainLobbyEntry = UIN17MainLobbyEntry

--
function UIN17MainLobbyEntry:OnShow(uiParams)
    self:_AttachEvents()

    self._stateType = UIStateType.UIN17MainController

    self:_LoadCampaignInfo(
        false,
        ECampaignType.CAMPAIGN_TYPE_N17,
        ECampaignN17ComponentID.ECAMPAIGN_N17_CYCLE_QUEST,
        ECampaignN17ComponentID.ECAMPAIGN_N17_LOTTERY,
        ECampaignN17ComponentID.ECAMPAIGN_N17_CUMULATIVE_LOGIN,
        ECampaignN17ComponentID.ECAMPAIGN_N17_STORY,
        ECampaignN17ComponentID.ECAMPAIGN_N17_MINI_GAME
    )
end

--
function UIN17MainLobbyEntry:OnHide()
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self:_DetachEvents()
end

-- 实现此方法，传入截图。注释此方法，不传截图
function UIN17MainLobbyEntry:SetData_uiMainLobbyController(controller)
    ---@type UIMainLobbyController
    self._uiMainLobbyController = controller
end

--
function UIN17MainLobbyEntry:_LoadCampaignInfo(isLocal, camType, ...)
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    if isLocal then
        self._campaign:LoadCampaignInfo_Local(camType, ...)
        self:_CheckPoint()
    else
        GameGlobal.TaskManager():StartTask(
            function(TT, ...)
                local lockName = "UIActivityMainLobbyEntry_LoadCampaignInfo"
                self:Lock(lockName)

                local res = AsyncRequestRes:New()
                self._campaign:LoadCampaignInfo(TT, res, camType, ...)
                self:_CheckPoint()

                ---@type LotteryComponent
                self._lotteryComponent = self._campaign:GetComponent(ECampaignN17ComponentID.ECAMPAIGN_N17_LOTTERY)
                ---@type ExploreMinigameComponent
                self._miniGameComponent = self._campaign:GetComponent(ECampaignN17ComponentID.ECAMPAIGN_N17_MINI_GAME)

                self:StartCheckActivityStatus()

                self:UnLock(lockName)
            end
        )
    end
end

--
function UIN17MainLobbyEntry:EntryBtnOnClick(go)
    -- 首次剧情
    UIActivityHelper.PlayFirstPlot_Campaign(self._campaign,
        function()
            self:_Entry()
        end,
        false
    )

    -- self:StartTask(
    --     function(TT)
    --         self:EntryBtnOnClickCoro(TT)
    --     end
    -- )

end

--
function UIN17MainLobbyEntry:_Entry()
    -- 截图
    if self._uiMainLobbyController then
        self._uiMainLobbyController._screenShot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self._uiMainLobbyController
            :GetName())
        local rt = self._uiMainLobbyController._screenShot:RefreshBlurTexture()
        local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
        self:StartTask(
            function(TT)
                YIELD(TT)
                UnityEngine.Graphics.Blit(rt, cache_rt)
                self:SwitchState(self._stateType, cache_rt)
            end
        )
    else
        self:SwitchState(self._stateType)
    end
end

function UIN17MainLobbyEntry:EntryBtnOnClickCoro(TT)
    self:Lock("UIN17MainLobbyEntry_EntryBtnOnClickCoro")
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIActivityN16MainController,
        function()
            if self._uiMainLobbyController then
                self._uiMainLobbyController._screenShot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self
                    ._uiMainLobbyController:GetName())
                local rt = self._uiMainLobbyController._screenShot:RefreshBlurTexture()
                local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
                self:StartTask(
                    function(TT)
                        YIELD(500)
                        self:UnLock("UIN17MainLobbyEntry_EntryBtnOnClickCoro")
                        UnityEngine.Graphics.Blit(rt, cache_rt)
                        self:SwitchState(self._stateType, cache_rt)

                    end
                )
            else
                self:SwitchState(self._stateType)
                self:UnLock("UIN17MainLobbyEntry_EntryBtnOnClickCoro")
            end
        end
    )
end

--region AttachEvent
--
function UIN17MainLobbyEntry:_AttachEvents()
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:AttachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

--
function UIN17MainLobbyEntry:_DetachEvents()
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:DetachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

--
function UIN17MainLobbyEntry:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign and self._campaign._id == campaign_id then
        self:_CheckPoint()
    end
end

--
function UIN17MainLobbyEntry:_OnQuestUpdate()
    -- self:_CheckPoint()
end

--
function UIN17MainLobbyEntry:_CheckPoint()
    -- local new = UIActivityHelper.CheckCampaignSampleNewPoint(self._campaign)
    -- local red = UIActivityHelper.CheckCampaignSampleRedPoint(self._campaign)
    local new = self._campaign:GetLocalProcess():GetEntryNew()
    local red = self._campaign:GetLocalProcess():GetEntryRedDot()

    UIWidgetHelper.SetNewAndReds(self, new, red, "new", "red")
end

--
function UIN17MainLobbyEntry:StartCheckActivityStatus()
    self:CheckActivityStatus()

    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
    self._timerHandler = GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:CheckActivityStatus()
        end
    )
end

--
function UIN17MainLobbyEntry:CheckActivityStatus()
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    local step1_a = self._miniGameComponent:GetComponentInfo().m_unlock_time
    local step1_b = self._miniGameComponent:GetComponentInfo().m_close_time
    local step1 = (curTime >= step1_a) and (curTime < step1_b)

    local step2_a = self._miniGameComponent:GetComponentInfo().m_unlock_time
    local step2_b = self._miniGameComponent:GetComponentInfo().m_close_time
    local step2 = (curTime >= step2_a) and (curTime < step2_b)

    local mode = step1 and 1 or (step2 and 2 or 0)
    self:_SetHintOpen(mode)
end

function UIN17MainLobbyEntry:_SetHintOpen(mode)
    if self._mode == mode then
        return
    end
    self._mode = mode

    -- [0] = close
    -- [1] = lottery
    -- [2] = minigame
    self:GetGameObject("_hintBg"):SetActive(mode ~= 0)

    local ids = {
        "str_n17_drawgame_unlock",
        "str_n17_exploregame_unlock"
    }
    local text = StringTable.Get(ids[mode])
    UIWidgetHelper.SetLocalizationText(self, "_hintText", text)
    UIWidgetHelper.SetRollingText(self, "_hintText")
end

--endregion
