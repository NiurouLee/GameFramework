--麻痹逻辑
---@class BuffLogicSetBenumb:BuffLogicBase
_class("BuffLogicSetBenumb", BuffLogicBase)
BuffLogicSetBenumb = BuffLogicSetBenumb

function BuffLogicSetBenumb:Constructor(buffInstance, logicParam)
end

function BuffLogicSetBenumb:DoLogic(notify)
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.Benumb)
    if e:HasMonsterID() then
        local cAI = e:AI()
        local vmb = cAI:GetMobilityValid()
        if vmb > 0 then
            cAI:ClearMobilityTotal() --停止正在执行的ai
        end
        e:Attributes():Modify("MaxMobility", 1)
    end

    self._world:GetService("Trigger"):Notify(NTBenumbed:New(e))
    return true
end

--去除麻痹
---@class BuffLogicResetBenumb:BuffLogicBase
_class("BuffLogicResetBenumb", BuffLogicBase)
BuffLogicResetBenumb = BuffLogicResetBenumb

function BuffLogicResetBenumb:Constructor(buffInstance, logicParam)
end

function BuffLogicResetBenumb:DoLogic(notify)
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.Benumb)
    if e:HasMonsterID() then
        e:Attributes():Modify("MaxMobility", 99)
    end
    return true
end
