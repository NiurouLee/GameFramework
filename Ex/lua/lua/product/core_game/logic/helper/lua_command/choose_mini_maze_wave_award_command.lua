--[[------------------------------------------------------------------------------------------
   ChooseMiniMazeWaveAwardCommand 小秘境选波次奖励
]] --------------------------------------------------------------------------------------------

_class("ChooseMiniMazeWaveAwardCommand", IEntityCommand)
---@class ChooseMiniMazeWaveAwardCommand:IEntityCommand
ChooseMiniMazeWaveAwardCommand = ChooseMiniMazeWaveAwardCommand

ChooseMiniMazeWaveAwardCommand.CommandType = "ChooseMiniMazeWaveAward"

function ChooseMiniMazeWaveAwardCommand:Constructor()
    ---@type number
    self._partnerID = 0
    ---@type number
    self._relicID = 0
    ---@type boolean
    self._isBattleOpening = false ---是否是开局选择圣物奖励
end

function ChooseMiniMazeWaveAwardCommand:GetCommandType()
    return ChooseMiniMazeWaveAwardCommand.CommandType
end

function ChooseMiniMazeWaveAwardCommand:GetExecStateID()
    return 0
end

function ChooseMiniMazeWaveAwardCommand:IsExecExcluded()
    return 0
end

function ChooseMiniMazeWaveAwardCommand:DependRoundCount()
    return true
end

function ChooseMiniMazeWaveAwardCommand:GetChoosePartnerID()
    return self._partnerID
end

function ChooseMiniMazeWaveAwardCommand:SetChoosePartnerID(partnerID)
    self._partnerID = partnerID
end

function ChooseMiniMazeWaveAwardCommand:GetChooseRelicID()
    return self._relicID
end

function ChooseMiniMazeWaveAwardCommand:SetChooseRelicID(relicID)
    self._relicID = relicID
end

function ChooseMiniMazeWaveAwardCommand:IsBattleOpening()
    return self._isBattleOpening
end

function ChooseMiniMazeWaveAwardCommand:SetIsBattleOpening(isOpening)
    self._isBattleOpening = isOpening
end

function ChooseMiniMazeWaveAwardCommand:ToNetMessage()
    local msg = CEventChooseMiniMazeWaveAwardCommand:New()
    msg.EntityID = self.EntityID
    msg.RoundCount = self.RoundCount
    msg.ClientWaitInput = self.ClientWaitInput
    msg.IsAutoFight = self.IsAutoFight
    msg.CmdIndex = self.CmdIndex

    msg.relicID = self._relicID
    msg.partnerID = self._partnerID
    msg.isBattleOpening = self._isBattleOpening
    return msg
end

---@param msg CEventChooseMiniMazeWaveAwardCommand
function ChooseMiniMazeWaveAwardCommand:FromNetMessage(msg)
    self.EntityID = msg.EntityID
    self.RoundCount = msg.RoundCount
    self.ClientWaitInput = msg.ClientWaitInput
    self.IsAutoFight = msg.IsAutoFight
    self.CmdIndex = msg.CmdIndex

    self._relicID = msg.relicID
    self._partnerID = msg.partnerID
    self._isBattleOpening = msg.isBattleOpening
end
