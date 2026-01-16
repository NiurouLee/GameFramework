---@class UITeamsNameModify:UIController
_class("UITeamsNameModify", UIController)
UITeamsNameModify = UITeamsNameModify

function UITeamsNameModify:OnShow(uiParams)
    self._id = uiParams[1]
    self._module = self:GetModule(MissionModule)
    self.ctx = self._module:TeamCtx()

    ---@type EmojiFilteredInputField
    self._iptName = self:GetUIComponent("EmojiFilteredInputField", "iptName")
    self._iptName.text = self:GetTeamName()
    local max = 12
    self.OnIptValueChanged = function()
        local s = self._iptName.text
        if string.isnullorempty(s) then
            return
        end
        local len = #s
        local curIdx = 1
        local asciiCount = 0 --ascii数
        while curIdx <= len do
            local c = string.byte(s, curIdx, curIdx)
            local charSize = self:GetCharSize(c)
            if charSize == 1 then
                if asciiCount + 1 > max then
                    break
                end
                asciiCount = asciiCount + 1
            elseif charSize > 1 then
                if asciiCount + 2 > max then
                    break
                end
                asciiCount = asciiCount + 2
            end
            local tmp = string.sub(s, curIdx, curIdx + charSize - 1)
            curIdx = curIdx + charSize
        end
        self._iptName.text = string.sub(s, 1, curIdx - 1)
    end
    self._iptName.onValueChanged:AddListener(self.OnIptValueChanged)
end

function UITeamsNameModify:OnHide()
    self._iptName.onValueChanged:RemoveListener(self.OnIptValueChanged)
    self.OnIptValueChanged = nil
end

function UITeamsNameModify:GetCharSize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

function UITeamsNameModify:bgOnClick(go)
    self:CloseDialog()
end

function UITeamsNameModify:btnCancelOnClick(go)
    self:CloseDialog()
end

function UITeamsNameModify:btnEnsureOnClick(go)
    local idip_mng = self:GetModule(IdipgameModule)
    if idip_mng:TextBanHandle(IDIPBanType.IDIPBan_Teamdes) == true then
        return
    end

    local text = string.trim(self._iptName.text)
    if string.isnullorempty(text) then
        ToastManager.ShowToast(StringTable.Get("str_discovery_team_name_cant_be_empty"))
        return
    end
    if text == self:GetTeamName() then
        ToastManager.ShowToast(StringTable.Get("str_discovery_team_name_not_change"))
        self:CloseDialog()
        return
    end
    self:StartTask(
        function(TT)
            self:LockBusy(true)
            local team = self:GetTeam()
            if self.ctx.teamOpenerType == TeamOpenerType.Tower then
                local module = self:GetModule(TowerModule)
                local tmpTeam = team:Clone()
                tmpTeam:UpdateName(text)
                local res, mul_formations = self.ctx:ReqTowerChangeMulFormationInfo(TT, tmpTeam)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            elseif self.ctx.teamOpenerType == TeamOpenerType.Maze then
                local mazeModule = self:GetModule(MazeModule)
                local res, data = mazeModule:UpdateMazeFormationInfo(self, self._id, text, team.pets)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            elseif self.ctx.teamOpenerType == TeamOpenerType.Trail then
                ---@type TalePetModule
                local taleModule = self:GetModule(TalePetModule)
                local res, data = taleModule:UpdateMainFormationInfo(self, self._id, text, team.pets)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            elseif self.ctx.teamOpenerType == TeamOpenerType.Air then
                local airModule = self:GetModule(AircraftModule)
                local res, data = airModule:RequestChangeTacticFormationInfo(self,self._id,text,team.pets)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            elseif self.ctx.teamOpenerType == TeamOpenerType.EightPets then
                local res = UIN33EightPetsTeamsContext:ReNameTT(TT, self._id, text)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                end
                self:LockBusy(false)
            elseif self.ctx.teamOpenerType == TeamOpenerType.Season then
                ---@type SeasonModule
                local seasonModule = GameGlobal.GetModule(SeasonModule)
                local res = seasonModule:ReqSeasonChangeFormationInfo(self, self._id, text, team.pets)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            else
                local res, data = self._module:UpdateMainFormationInfo(self, self._id, text, team.pets)
                if res:GetSucc() then
                    team:UpdateName(text)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, self._id)
                    self:CloseDialog()
                    self:LockBusy(false)
                else
                    ToastManager.ShowToast(self._module:GetErrorMsg(res.m_result))
                    self:LockBusy(false)
                end
            end
        end,
        self
    )
end

function UITeamsNameModify:LockBusy(isLockBusy)
    local lock = "UITeamsNameModify"
    if isLockBusy then
        self:SetShowBusy(true)
        self:Lock(lock)
    else
        self:SetShowBusy(false)
        self:UnLock(lock)
    end
end

function UITeamsNameModify:GetTeam()
    if not self.ctx then
        return
    end
    local teams = self.ctx:Teams()
    local team = teams:Get(self._id)
    return team
end
function UITeamsNameModify:GetTeamName()
    local team = self:GetTeam()
    if not team then
        return ""
    end
    return team.name
end
