--- @class UIS1MainController:UIController
_class("UIS1MainController", UIController)
UIS1MainController = UIS1MainController

function UIS1MainController:Constructor()
    self._isReview = false
    --self._canShare = self:GetModule(ShareModule):CanShare()
    self._svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
end

function UIS1MainController:_SetRemainingTime(widgetName, descId, endTime)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")
    obj:GetGameObject():SetActive(endTime ~= nil)
    if endTime == nil then
        return
    end

    -- obj:SetExtraRollingText()
    obj:SetAdvanceText(descId)

    obj:SetData(endTime, nil, function(isFirst)
        if not isFirst then
            self:_Refresh()
        end
    end)
end

--region resident func [ver_20220506]

function UIS1MainController:_SetCommonTopButton()
    ---@type UICommonTopButton
    local obj = UIWidgetHelper.SpawnObject(self, "_backBtns", "UICommonTopButton")
    obj:SetData(
        function()
            self:_Back()
        end,
        nil,
        nil,
        false,
        function()
            self:_HideUI()
        end
    )
end

function UIS1MainController:_Back()
    if self:Manager():CurUIStateType() == UIStateType.UIS1Main then
        -- CutsceneManager.ExcuteCutsceneIn(
        --     UIStateType.UIMain,
        --     function()
        --         self:_Shot(function()
        --             self:_PlayAnim(3, function()
        --                 self:SwitchState(UIStateType.UIMain) --有可能是虚实之扉界面
        --             end)
        --         end)
        --     end
        -- )
        self:SwitchState(UIStateType.UIMain) --有可能是虚实之扉界面
    else
        self:_Shot(function()
            self:_PlayAnim(3, function()
                self:CloseDialog()
                UIBgmHelper.PlayMainBgm()
            end)
        end)
    end
end

function UIS1MainController:_HideUI()
    self:GetGameObject("_backBtns"):SetActive(false)
    self:GetGameObject("_showBtn"):SetActive(true)

    -- self:GetGameObject("_uiElements"):SetActive(false)
    self:_PlayAnim(4)
end

function UIS1MainController:_ShowUI()
    self:GetGameObject("_backBtns"):SetActive(true)
    self:GetGameObject("_showBtn"):SetActive(false)

    -- self:GetGameObject("_uiElements"):SetActive(true)
    self:_PlayAnim(5)
end

function UIS1MainController:_SetBg(phase)
    -- phase = phase or 1
    -- phase = math.min(phase, 3) -- 背景只配了 3 个阶段
    -- local url = UIActivityHelper.GetCampaignMainBg(self._campaign, phase)
    -- if url then
    --     UIWidgetHelper.SetRawImage(self, "_mainBg", url)
    -- end
end

function UIS1MainController:_SetSpine()
    local phase = UISeasonPhaseHelper.CheckPhase()
    if phase == self._spinePhase then
        return
    end

    self._spinePhase = phase

    local spineName = UISeasonPhaseHelper.GetPhaseSpine(phase)
    UIWidgetHelper.SetSpineLoad(self, "_spine", spineName)
end

function UIS1MainController:_PlayAnim(idx, callback)
    local tb = {
        [1] = { animName = "uieff_UIS1_UIS1MainController", duration = 1000 },
        [2] = { animName = "uieff_UIS1_UIS1MainController_in", duration = 1000 },
        [3] = { animName = "uieff_UIS1_UIS1MainController_out", duration = 333 },
        [4] = { animName = "uieff_UIS1_UIS1MainController_hide", duration = 500 },
        [5] = { animName = "uieff_UIS1_UIS1MainController_show", duration = 500 }
    }
    UIWidgetHelper.PlayAnimation(self, "_anim", tb[idx].animName, tb[idx].duration, callback)
end

function UIS1MainController:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIS1MainController)
end

--endregion

-----------------------------------------------------------------

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIS1MainController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    local reqRes = self._seasonModule:ForceRequestCurSeasonData(TT)
    self._seasonId = self._seasonModule:GetCurSeasonID()
    -- 错误处理
    if reqRes and not reqRes:GetSucc() then
        self._seasonModule:CheckErrorCode(reqRes.m_result, self._seasonId, nil, nil)
        res:SetSucc(false)
        return
    end

    -- -- 清除 new
    -- self._campaign:ClearCampaignNew(TT)
    UISeasonLocalDBHelper.SeasonBtn_Set("UIS1MainEnter", "New")
end

function UIS1MainController:OnShow(uiParams)
    self:_SetCommonTopButton()
    self:_SetSpine()

    --------------------------------------------------------------------------------
    -- 传入底图，并决定是否播放动效
    local isRt = UIWidgetHelper.SetRawImageTexture(self, "rt", uiParams[1])
    local animIn = isRt and 1 or 2
    self:_PlayAnim(animIn, function()
        self:_CheckGuide()
    end)

    local delay = (animIn == 1) and 270 or 0 -- 使用第一种进场动效，需控制子按钮延迟播放动效
    self:_Refresh(true, delay)

    self:_AttachEvents()
end

function UIS1MainController:OnHide()
    self:_DetachEvents()
    if self._gameTimer then
        GameGlobal.Timer():CancelEvent(self._gameTimer)
        self._gameTimer = nil
    end

    AudioHelperController.PlayBGMById(SeasonCriAudio.BGMMain)
end

function UIS1MainController:_Refresh(first, delay)
    --- @type CampaignQuestComponent
    self._component_quest = self._seasonModule:GetCurSeasonQuestComponent()

    --- @type ExchangeItemComponent
    self._component_exchange = self._seasonModule:GetCurSeasonExchangeComponent()

    ---@type ActionPointComponent
    self._component_action = self._seasonModule:GetCurSeasonActionPointComponent()

    --------------------------------------------------------------------------------
    local curTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000
    local getComponentCloseTime = function(component)
        return component and component:GetComponentInfo().m_close_time or 0
    end

    local time_action = getComponentCloseTime(self._component_action)
    local time_exchange = getComponentCloseTime(self._component_exchange)

    local desc, time
    if curTime < time_action then
        desc, time = "str_season_s1_main_time_action", time_action
    elseif curTime < time_exchange then
        desc, time = "str_season_s1_main_time_exchange", time_exchange
    end
    self:_SetRemainingTime("_remainingTime", desc, time)

    --------------------------------------------------------------------------------
    self:_SetBtn_Collage()
    self:_SetBtn_Exchange(delay)
    self:_SetBtn_Medal()
    self:_SetBtn_Quest(delay)
    self:_SetBtn_Go()
end

--region Btn

function UIS1MainController:_SetBtn_Collage()
    local obj = UIWidgetHelper.SpawnObject(self, "CollageBtn", "UIS1CollageBtn")
    obj:SetData(self._seasonId)
end

function UIS1MainController:_SetBtn_Exchange(delay)
    local obj = UIWidgetHelper.SpawnObject(self, "ExchangeBtn", "UIS1ExchangeBtn")
    obj:SetData(self._seasonId, self._component_exchange, delay)
end

function UIS1MainController:_SetBtn_Medal()
    local obj = UIWidgetHelper.SpawnObject(self, "MedalBtn", "UIS1MedalBtn")
    obj:SetData(self._seasonId)
end

function UIS1MainController:_SetBtn_Quest(delay)
    local obj = UIWidgetHelper.SpawnObject(self, "QuestBtn", "UIS1QuestBtn")
    obj:SetData(self._seasonId, self._component_quest, delay)
end

function UIS1MainController:_SetBtn_Go()
    local obj = UIWidgetHelper.SpawnObject(self, "GoBtn", "UIS1GoBtn")

    obj:SetData(self._seasonId, self._component_action)
end

--endregion


--region Shot

function UIS1MainController:_Shot(callback)
    UIWidgetHelper.BlurHelperShot(self, "shot", self:GetName(), function(cache_rt)
        UIWidgetHelper.SetRawImageTexture(self, "rt", cache_rt)

        self:_AfterShot()
        callback()
    end)
end

function UIS1MainController:_AfterShot()
    self:GetGameObject("rt"):SetActive(true)

    self:GetGameObject("shot"):SetActive(false)
    self:GetGameObject("_uiElements"):SetActive(false)
    self:GetGameObject("_spine"):SetActive(false)
end

--endregion

--region Event Callback

function UIS1MainController:ShowBtnOnClick(go)
    self:_ShowUI()
end

function UIS1MainController:StoryBtnOnClick(go)
end

function UIS1MainController:IntroBtnOnClick(go)
    UISeasonHelper.ShowSeasonHelperBook(UISeasonHelperTabIndex.S1Main)
end

--endregion

--region AttachEvent

function UIS1MainController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._AfterUILayerChanged)
end

function UIS1MainController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._AfterUILayerChanged)
end

function UIS1MainController:_CheckActivityClose(id)
    if self._seasonId == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIS1MainController:_AfterUILayerChanged()
    local topui = GameGlobal.UIStateManager():IsTopUI(self:GetName())
    if topui then
        self:_Refresh()
    end
end

--endregion
