--[[
    根据当前的连线属性和连线拐角设置普攻
]]
---@class BuffLogicSetNormalSkillWithElementAndChainAngle:BuffLogicBase
_class("BuffLogicSetNormalSkillWithElementAndChainAngle", BuffLogicBase)
BuffLogicSetNormalSkillWithElementAndChainAngle = BuffLogicSetNormalSkillWithElementAndChainAngle

function BuffLogicSetNormalSkillWithElementAndChainAngle:Constructor(buffInstance, logicParam)
    self._element = logicParam.element
    self._skillList = logicParam.skillList
end

function BuffLogicSetNormalSkillWithElementAndChainAngle:DoLogic(notify)
    if not notify.GetChainPathType then
        return
    end

    --如果属性不符 会设置为nil
    local setSkillValue = nil
    local setOrderValue = nil
    local setBeforeMoveValue = nil

    local chainElement = notify:GetChainPathType()
    if chainElement == self._element then
        setSkillValue = self._skillList
        setOrderValue = 1
        setBeforeMoveValue = true
    end

    local e = self._buffInstance:Entity()
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    --储存连线中替换的普攻技能
    buffCmpt:SetBuffValue("ChangeNormalSkillIDWithChainPathRightAngle", setSkillValue)

    --设置普攻表现在移动前
    buffCmpt:SetBuffValue("NormalSkillBeforeMove", setBeforeMoveValue)

    --设置出战顺序
    buffCmpt:SetBuffValue("PetRoundTeamOrder_" .. SkillType.Normal, setOrderValue)
end
