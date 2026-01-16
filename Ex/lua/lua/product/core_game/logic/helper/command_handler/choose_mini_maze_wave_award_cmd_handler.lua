require "command_base_handler"

---@class WaveResultAwardNextStateType
WaveResultAwardNextStateType = {
    None = 0, --不进行状态机切换
    WaveSwitch = 1, --进入波次切换状态机，对应WaveResultAward的NextState[1]
    WaitInput = 2, --进入等待输入，对应WaveResultAward的NextState[2]
}
_enum("WaveResultAwardNextStateType", WaveResultAwardNextStateType)

_class("ChooseMiniMazeWaveAwardCommandHandler", CommandBaseHandler)
---@class ChooseMiniMazeWaveAwardCommandHandler: CommandBaseHandler
ChooseMiniMazeWaveAwardCommandHandler = ChooseMiniMazeWaveAwardCommandHandler

---@param cmd ChooseMiniMazeWaveAwardCommand
function ChooseMiniMazeWaveAwardCommandHandler:DoHandleCommand(cmd)
    local relicID = cmd:GetChooseRelicID()
    local partnerID = cmd:GetChoosePartnerID()
    local isOpening = cmd:IsBattleOpening()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetWaveWaitApplyAward(relicID,isOpening,partnerID)
    Log.debug("[MiniMaze] ChooseMiniMazeWaveAwardCommandHandler relicID: ",relicID," partnerID: ",partnerID, " isOpen ", isOpening)
    self._world:EventDispatcher():Dispatch(GameEventType.WaveResultAwardFinish, 1)
end
