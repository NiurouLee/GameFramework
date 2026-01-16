---@class UIN28MainEnter : UICustomWidget
_class("UIN28MainEnter", UICustomWidget)
UIN28MainEnter = UIN28MainEnter

function UIN28MainEnter:OnShow(uiParams)
    self._new = self:GetGameObject("new")
    self._red = self:GetGameObject("red")
    self._new:SetActive(false)
    self._red:SetActive(false)
    self._tipspanel1 = self:GetGameObject("tipspanel1")
    self._tipspanel2 = self:GetGameObject("tipspanel2")
    self._tipspanel1:SetActive(false)
    self._tipspanel2:SetActive(false)
    ---@type UIActivityN28Const
    self._activityConst = UIActivityN28Const:New()
    self:RequestCampaign()
end

function UIN28MainEnter:OnHide()
end

function UIN28MainEnter:SetData_uiMainLobbyController(controller)
    ---@type UIMainLobbyController
    self._uiMainLobbyController = controller
end

function UIN28MainEnter:RequestCampaign()
    self:StartTask(
        function(TT)
            local lockName = "UIN28MainEnterRequestCampaign"
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

function UIN28MainEnter:Flush()
    self._tipspanel1:SetActive(false)
    self._tipspanel2:SetActive(false)
    -- local status, time = self._activityConst:GetAVGGameComponentStatus()
    -- if status == ActivityN28ComponentStatus.Open then
    --     self._tipspanel1:SetActive(true)
    -- end
   
    local status, time = self._activityConst:EnterGetHardLineMissionComponentStatus()
    if status == ActivityN28ComponentStatus.Open then
        self._tipspanel2:SetActive(true)
    end
end

function UIN28MainEnter:FlushNewRed()
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

function UIN28MainEnter:BtnOnClick(go)
    GameGlobal.TaskManager():StartTask(self.Enter, self)
end

function UIN28MainEnter:Enter(TT)
    self:Lock("UIN28MainEnter_Enter")

    ---@type AsyncRequestRes
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._activityConst:LoadData(TT, res)
    if res and not res:GetSucc() then
        ---@type CampaignModule
        local campModule = GameGlobal.GetModule(CampaignModule)
        campModule:CheckErrorCode(res.m_result, self._activityConst:GetCampaignId(), nil, nil)
        self:UnLock("UIN28MainEnter_Enter")
        return
    end

    -- -- 截图
    -- if self._uiMainLobbyController then
    --     self._uiMainLobbyController._screenShot.OwnerCamera = GameGlobal.UIStateManager():GetControllerCamera(self._uiMainLobbyController
    --         :GetName())
    --     local rt = self._uiMainLobbyController._screenShot:RefreshBlurTexture()
    --     local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    --     self:StartTask(
    --         function(TT)
    --             YIELD(TT)
    --             UnityEngine.Graphics.Blit(rt, cache_rt)
    --             self:SwitchState(UIStateType.UIActivityN28MainController, cache_rt)
    --         end
    --     )
    -- else
    --     self:SwitchState(UIStateType.UIActivityN28MainController)
    -- end
    CutsceneManager.ExcuteCutsceneIn_Shot()
    self:SwitchState(UIStateType.UIActivityN28MainController)

    self:UnLock("UIN28MainEnter_Enter")

end


-- function UIN28MainEnter:BtnOnClick(go)
--     GameGlobal.TaskManager():StartTask(self.Enter, self)
-- end

-- function UIN28MainEnter:Enter(TT)
--     self:Lock("UIN20MainEnter_Enter")
--     self:SwitchState(UIStateType.UIActivityN28MainController)
--     self:UnLock("UIN20MainEnter_Enter")
-- end