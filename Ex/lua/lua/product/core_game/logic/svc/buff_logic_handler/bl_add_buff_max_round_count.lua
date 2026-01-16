require('buff_logic_base')

--[[
    增加buff的持续回合数

    注意：没有考虑过增加负数时的功能！
]]

_class("BuffLogicAddBuffMaxRoundCount", BuffLogicBase)
---@class BuffLogicAddBuffMaxRoundCount:BuffLogicBase
BuffLogicAddBuffMaxRoundCount = BuffLogicAddBuffMaxRoundCount

function BuffLogicAddBuffMaxRoundCount:Constructor(buffInstance, logicParam)
    self._addVal = tonumber(logicParam.addVal)
end

---@param notify NTEachAddBuffEnd
function BuffLogicAddBuffMaxRoundCount:DoLogic(notify)
    local entity = notify:GetDefenderEntity()
    local buffID = notify:GetBuffID()
    local seqID = notify:GetBuffSeqID()

    if (not buffID) or (not seqID) then
        return
    end

    local cBuff = entity:BuffComponent()
    local instance = cBuff:GetBuffBySeq(seqID)

    if not instance then
        return
    end

    --参见BuffInstance:AddMaxRoundCount：通过修改最大回合数，将buff从无回合数改为按回合销毁，或反之，都是不允许的操作
    local before = instance:GetMaxRoundCount()
    instance:AddMaxRoundCount(self._addVal)
    local after = instance:GetMaxRoundCount()

    return {
        entityID = entity:GetID(),
        buffID = buffID,
        seqID = seqID,
        beforeRound = before,
        afterRound = after
    }
end
