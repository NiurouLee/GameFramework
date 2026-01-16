---@class UIN25MainEnter : UICustomWidget
_class("UIN25MainEnter", UICustomWidget)
UIN25MainEnter = UIN25MainEnter

function UIN25MainEnter:OnShow(uiParams)
    self._new = self:GetGameObject("new")
    self._red = self:GetGameObject("red")
    self._new:SetActive(false)
    self._red:SetActive(false)
    self._tipspanel1 = self:GetGameObject("tipspanel1")
    self._tips1 = self:GetUIComponent("RollingText", "tips1")--小游戏

    self._tipspanel2 = self:GetGameObject("tipspanel2")
    self._tips2 = self:GetUIComponent("RollingText", "tips2")--困难关

    self._tipspanel1:SetActive(false)
    ---@type UIActivityN25Const
    self._activityConst = UIActivityN25Const:New()
    self:RequestCampaign()
end

function UIN25MainEnter:OnHide()
end

function UIN25MainEnter:SetData_uiMainLobbyController(controller)
    ---@type UIMainLobbyController
    self._uiMainLobbyController = controller
end

function UIN25MainEnter:RequestCampaign()
    self:StartTask(
        function(TT)
            local lockName = "UIN25MainEnterRequestCampaign"
            self:Lock(lockName)
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self._activityConst:LoadData(TT, res)
            self:Flush()
            self:FlushNewRed()
            self:UnLock(lockName)
        end,
        self
    )
end

function UIN25MainEnter:Flush()
    self._tipspanel1:SetActive(false)
    self._tipspanel2:SetActive(false)

    local bloodSuckerState =  self._activityConst:GetStateGameBloodSucker()
    if bloodSuckerState == UISummerOneEnterBtnState.Normal then
        self._tipspanel2:SetActive(true)
        self._tips2:RefreshText(StringTable.Get("str_n25_bloodSucker_open"))--吸血鬼小游戏开启
        return
    end

    local hardState =  self._activityConst:GetStateHard()
    if hardState == UISummerOneEnterBtnState.Normal then
        self._tipspanel2:SetActive(true)
        self._tips2:RefreshText(StringTable.Get("str_n25_hard_level_open"))--吸血鬼小游戏开启
    end

    -- local idolState =  self._activityConst:GetStateGameIdol()
    -- if idolState == UISummerOneEnterBtnState.Normal then
    --     self._tipspanel1:SetActive(true)
    --     self._tips1:RefreshText(StringTable.Get("str_n25_idol_open"))--偶像养成小游戏开启
    -- end

    -- if self._activityConst:IsHomelandTaskEnable() then
    --     self._tipspanel1:SetActive(true)
    --     self._tips1:RefreshText(StringTable.Get("str_n25_main_entry_tips"))
    -- end
end

function UIN25MainEnter:FlushNewRed()
    self._new:SetActive(false)
    self._red:SetActive(false)
    if self._activityConst:IsShowEntryNew() then
        self._new:SetActive(true)
        return
    end

    if self._activityConst:IsShowEntryRed() then
        self._red:SetActive(true)
    end
end

function UIN25MainEnter:BtnOnClick(go)
    if self._activityConst:IsActivityEnd() then
        self.mCampaign = self:GetModule(CampaignModule)
        local errorType  = CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED
        self.mCampaign:ShowErrorToast(errorType, true)
    else
        GameGlobal.TaskManager():StartTask(self.Enter, self)
    end
end

function UIN25MainEnter:Enter(TT)
    self._stateType = UIStateType.UIActivityN25MainController
    self:SwitchState(self._stateType)

    --  -- 截图
    --  if self._uiMainLobbyController then
    --     self._uiMainLobbyController._screenShot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self._uiMainLobbyController
    --         :GetName())
    --     local rt = self._uiMainLobbyController._screenShot:RefreshBlurTexture()
    --     local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    --     self:StartTask(
    --         function(TT)
    --             YIELD(TT)
    --             UnityEngine.Graphics.Blit(rt, cache_rt)
    --             self:SwitchState(self._stateType, cache_rt)
    --         end
    --     )
    -- else
    --     self:SwitchState(self._stateType)
    -- end
end
