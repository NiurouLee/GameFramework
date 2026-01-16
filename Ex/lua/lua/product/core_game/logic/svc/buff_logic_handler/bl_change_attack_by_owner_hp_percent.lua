--[[
    根据Buff持有者的血量百分比增加或减少攻击力
]]

require("buff_logic_base")

---@class BuffLogicChangeAttackByOwnerHPPercent:BuffLogicBase
_class("BuffLogicChangeAttackByOwnerHPPercent", BuffLogicBase)
BuffLogicChangeAttackByOwnerHPPercent = BuffLogicChangeAttackByOwnerHPPercent

function BuffLogicChangeAttackByOwnerHPPercent:Constructor(buffInstance, logicParam)
    self._paramA = logicParam.paramA or 0
    self._paramB = logicParam.paramB or 0
    self._startHPPercent = logicParam.startHPPercent or 0
    self._endHPPercent = logicParam.endHPPercent or 1
end

function BuffLogicChangeAttackByOwnerHPPercent:DoLogic()
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()

    ---@type Entity
    local useEntity = ownerEntity
    ---非秘境模式下，使用队伍血量
    if self._world:MatchType() ~= MatchType.MT_Maze and ownerEntity:HasPetPstID() then
        useEntity = ownerEntity:Pet():GetOwnerTeamEntity()
    end

    if not ownerEntity:Attributes() then
        return
    end

    ---计算血量百分比
    ---@type AttributesComponent
    local attrCmpt = useEntity:Attributes()
    if not attrCmpt then
        return
    end
    local maxHP = attrCmpt:CalcMaxHp()
    local curHP = attrCmpt:GetCurrentHP()
    local hpPercent = curHP / maxHP

    ---根据血量百分比计算需要改变的攻击百分比
    local val = 0
    if hpPercent < self._startHPPercent then
        val = self._paramB
    elseif hpPercent >= self._startHPPercent and hpPercent < self._endHPPercent then
        val = (hpPercent - self._startHPPercent) * self._paramA + self._paramB
    elseif hpPercent >= self._endHPPercent then
        val = (self._endHPPercent - self._startHPPercent) * self._paramA + self._paramB
    end
    if val <= -1 then
        val = -1
    end

    self._buffLogicService:ChangeBaseAttack(ownerEntity, self:GetBuffSeq(), ModifyBaseAttackType.AttackPercentage, val)
end

function BuffLogicChangeAttackByOwnerHPPercent:DoOverlap(logicParam)
    return self:DoLogic()
end

---@class BuffLogicChangeAttackByOwnerHPPercentUndo:BuffLogicBase
_class("BuffLogicChangeAttackByOwnerHPPercentUndo", BuffLogicBase)
BuffLogicChangeAttackByOwnerHPPercentUndo = BuffLogicChangeAttackByOwnerHPPercentUndo

function BuffLogicChangeAttackByOwnerHPPercentUndo:Constructor(buffInstance, logicParam)
end

function BuffLogicChangeAttackByOwnerHPPercentUndo:DoLogic()
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()
    self._buffLogicService:RemoveBaseAttack(ownerEntity, self:GetBuffSeq(), ModifyBaseAttackType.AttackPercentage)
end

function BuffLogicChangeAttackByOwnerHPPercentUndo:DoOverlap(logicParam)
    return self:DoLogic()
end
