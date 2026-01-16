require "command_base_handler"

_class("SwitchPetEquipRefineUICommandHandler", CommandBaseHandler)
---@class SwitchPetEquipRefineUICommandHandler: CommandBaseHandler
SwitchPetEquipRefineUICommandHandler = SwitchPetEquipRefineUICommandHandler

---@param cmd SwitchPetEquipRefineUICommand
function SwitchPetEquipRefineUICommandHandler:DoHandleCommand(cmd)
    local uiState = cmd:GetCmdRefineUIState()

    local petPstID = cmd:GetCmdCasterPstID()
    local entityID = self:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local petEntity = self._world:GetEntityByID(entityID)
    if not petEntity then
        return
    end

    if not self:CheckCanSwitchState(petEntity, uiState) then
        return
    end

    ---@type BuffComponent
    local buffCmpt = petEntity:BuffComponent()
    buffCmpt:SetBuffValue("EquipRefineUIState", uiState)

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local nt = NTEquipRefineUIStateChange:New(petEntity, uiState)
    triggerSvc:Notify(nt)

    if self._world:RunAtClient() then
        ---同步逻辑数据到表现端
        self._world:EventDispatcher():Dispatch(GameEventType.DataBuffValue, entityID, "EquipRefineUIState", uiState)
        ---通知UI刷新
        self._world:EventDispatcher():Dispatch(GameEventType.BattleUIRefreshRefineSwitchBtnState, uiState)
    end
end

---@param petEntity Entity
---@param uiState EquipRefineUIStateType
function SwitchPetEquipRefineUICommandHandler:CheckCanSwitchState(petEntity, uiState)
    ---@type BuffComponent
    local buffCmpt = petEntity:BuffComponent()
    if not buffCmpt then
        return false
    end

    if not buffCmpt:HasBuffEffect(BuffEffectType.ShowEquipRefineUI) then
        return false
    end

    if buffCmpt:GetBuffValue("EquipRefineUIState") == uiState then
        return false
    end

    return true
end
