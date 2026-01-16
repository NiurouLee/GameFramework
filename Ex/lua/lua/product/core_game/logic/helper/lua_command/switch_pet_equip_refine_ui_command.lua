--[[------------------------------------------------------------------------------------------
   SwitchPetEquipRefineUICommand 点击切换局内光灵装备精炼开关
]]
--------------------------------------------------------------------------------------------

---@class SwitchPetEquipRefineUICommand:IEntityCommand
_class("SwitchPetEquipRefineUICommand", IEntityCommand)
SwitchPetEquipRefineUICommand = SwitchPetEquipRefineUICommand

SwitchPetEquipRefineUICommand.CommandType = "SwitchPetEquipRefineUI"

function SwitchPetEquipRefineUICommand:Constructor()
    self._uiState = EquipRefineUIStateType.On
    self._casterPstID = -1
end

function SwitchPetEquipRefineUICommand:GetCommandType()
    return SwitchPetEquipRefineUICommand.CommandType
end

function SwitchPetEquipRefineUICommand:GetExecStateID(runAtClient)
    --客户端在preview状态，服务器在waitinput状态
    if runAtClient then
        return GameStateID.PreviewActiveSkill
    else
        return GameStateID.WaitInput
    end
end

function SwitchPetEquipRefineUICommand:DependRoundCount()
    return true
end

function SwitchPetEquipRefineUICommand:GetCmdRefineUIState()
    return self._uiState
end

function SwitchPetEquipRefineUICommand:GetCmdCasterPstID()
    return self._casterPstID
end

function SwitchPetEquipRefineUICommand:SetCmdRefineUIState(uiState)
    self._uiState = uiState
end

function SwitchPetEquipRefineUICommand:SetCmdCasterPstID(pstID)
    self._casterPstID = pstID
end

function SwitchPetEquipRefineUICommand:ToNetMessage()
    local msg = CEventSwitchPetEquipRefineUICommand:New()
    msg.EntityID = self.EntityID
    msg.RoundCount = self.RoundCount
    msg.ClientWaitInput = self.ClientWaitInput
    msg.IsAutoFight = self.IsAutoFight
    msg.CmdIndex = self.CmdIndex

    msg.UIState = self._uiState
    msg.CasterPstID = self._casterPstID
    return msg
end

---@param msg CEventSwitchPetEquipRefineUICommand
function SwitchPetEquipRefineUICommand:FromNetMessage(msg)
    self.EntityID = msg.EntityID
    self.RoundCount = msg.RoundCount
    self.ClientWaitInput = msg.ClientWaitInput
    self.IsAutoFight = msg.IsAutoFight
    self.CmdIndex = msg.CmdIndex

    self._uiState = msg.UIState
    self._casterPstID = msg.CasterPstID
end
