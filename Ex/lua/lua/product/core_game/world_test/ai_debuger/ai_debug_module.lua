require("game_module")

_class("AIDebugModule", GameModule)
---@class AIDebugModule:GameModule
AIDebugModule = AIDebugModule


function AIDebugModule:Constructor()
    self._aiRunLog = {}
    self._selectMonsterID = nil
    self._coreGameIsRun = false
end

function AIDebugModule:StartCoreGame()
    self._coreGameIsRun = true
    self._aiRunLog = {}
end

function AIDebugModule:ClearAIDebugInfo()
    self._selectMonsterID = nil
    self._coreGameIsRun = false
    self._aiRunLog = {}
end

function AIDebugModule:InitDataStruct(monsterID, entityID, round, runCount, aiConfigID)
    local monster = tostring(monsterID)..".".. tostring(entityID)
    if not self._aiRunLog[monster] then
        self._aiRunLog[monster] = {}
    end
    if not self._aiRunLog[monster][aiConfigID]then
        self._aiRunLog[monster][aiConfigID] = {}
    end
    if not self._aiRunLog[monster][aiConfigID][round]then
        self._aiRunLog[monster][aiConfigID][round]= {}
    end
    if not self._aiRunLog[monster][aiConfigID][round][runCount] then
        self._aiRunLog[monster][aiConfigID][round][runCount] = {}
    end
end

function AIDebugModule:AddAIDebugStreamInfo(monsterID, entityID, round, runCount, aiConfigID, aiTreeID, slotID)
    self:InitDataStruct(monsterID, entityID, round, runCount, aiConfigID)
    local monster = tostring(monsterID)..".".. tostring(entityID)
    local t = { Type =AILogDataType.AISteamLog, TreeID = aiTreeID, SlotID= slotID}
    table.insert(self._aiRunLog[monster][aiConfigID][round][runCount] ,t)
end

function AIDebugModule:AddAIDebugRunInfo(monsterID, entityID, round, runCount, aiConfigID, aiTreeID,info)
    self:InitDataStruct(monsterID, entityID, round, runCount, aiConfigID)
    local monster = tostring(monsterID)..".".. tostring(entityID)
    local t = { Type =AILogDataType.AIDebugLog, TreeID = aiTreeID, Info= info}
    table.insert(self._aiRunLog[monster][aiConfigID][round][runCount] ,t)
end

function AIDebugModule:GetSelectedMonsterDebugData(monsterIDStr)
    if self._aiRunLog[monsterIDStr] then
        return self._aiRunLog[monsterIDStr]
    end
    return nil
end

function AIDebugModule:GetAIDebugInfo()
    if self._selectMonsterID then
        return {[self._selectMonsterID]= self._aiRunLog[self._selectMonsterID]}
    else
        return self._aiRunLog
    end

end

function AIDebugModule:SetSelectMonsterID(monsterID,entityID)
    self._selectMonsterID = tostring(monsterID)..".".. tostring(entityID)
end

function AIDebugModule:ClearSelectMonsterID()
    self._selectMonsterID = nil
end
