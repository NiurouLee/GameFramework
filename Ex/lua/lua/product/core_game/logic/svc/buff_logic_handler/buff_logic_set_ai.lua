--[[
    替换AI
]]
--设置AI
_class("BuffLogicSetAI", BuffLogicBase)
BuffLogicSetAI = BuffLogicSetAI

function BuffLogicSetAI:Constructor(buffInstance, logicParam)
    self._newAI = logicParam.newAI
end

function BuffLogicSetAI:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    if not e:HasAI() then
        return
    end
    local listAiID = {}
    if type(self._newAI) ~= "table" then
        listAiID[#listAiID + 1] = self._newAI
    else
        listAiID = self._newAI
    end
    e:ReplaceAI(AILogicPeriodType.Main, listAiID)
end

--重置AI
_class("BuffLogicResetAI", BuffLogicBase)
BuffLogicResetAI = BuffLogicResetAI

function BuffLogicResetAI:Constructor(buffInstance, logicParam)
end

function BuffLogicResetAI:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    if not e:HasAI() then
        return
    end
    e:ResumeAI(AILogicPeriodType.Main)
end
