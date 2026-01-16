require "command_base_handler"

---@class CastPickUpChainSkillCommandHandler: CommandBaseHandler
_class("CastPickUpChainSkillCommandHandler", CommandBaseHandler)
CastPickUpChainSkillCommandHandler = CastPickUpChainSkillCommandHandler

---@param cmd CastPickUpChainSkillCommand
function CastPickUpChainSkillCommandHandler:DoHandleCommand(cmd)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local pickUpGridPos = cmd:GetCmdPickUpResult()
    if pickUpGridPos then
        if not self:IsPosNil(pickUpGridPos) then
            if self:IsGridPosValid(pickUpGridPos) then
                ---@type UtilDataServiceShare
                local utilData = self._world:GetService("UtilData")
                if  not utilData:IsPosDimensionDoor(pickUpGridPos) then --不能选任意门
                    ---@type LogicPickUpComponent
                    local logicPickUpCmpt = teamEntity:LogicPickUp()
                    logicPickUpCmpt:SetLogicPickUpGridPos(pickUpGridPos)
                    logicPickUpCmpt:SetLogicPickUpGridSafePos(pickUpGridPos)
                    self._world:BattleStat():SetCastChainByDimensionDoorState(true)
                    self._world:EventDispatcher():Dispatch(GameEventType.PickUpChainSkillTargetFinish, 1)
                    return
                end
            end
        end
    end
    local errorMsg = "ChainSkillPickUp Invalid GridPos:"
    if pickUpGridPos then
        errorMsg = errorMsg..tostring(pickUpGridPos)
    end
    self:_HandleServerSyncFailed(BattleFailedType.ChainPathPickUpGridPosInvalid, errorMsg)
end
