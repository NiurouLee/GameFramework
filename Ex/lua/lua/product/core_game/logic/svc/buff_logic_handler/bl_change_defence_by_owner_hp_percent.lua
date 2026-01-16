--[[
    根据Buff持有者的血量百分比增加或减少防御力
]]

require("buff_logic_base")

---@class BuffLogicChangeDefenceByOwnerHPPercent:BuffLogicBase
_class("BuffLogicChangeDefenceByOwnerHPPercent", BuffLogicBase)
BuffLogicChangeDefenceByOwnerHPPercent = BuffLogicChangeDefenceByOwnerHPPercent

function BuffLogicChangeDefenceByOwnerHPPercent:Constructor(buffInstance, logicParam)
    self._paramA = logicParam.paramA or 0
    self._paramB = logicParam.paramB or 0
    self._startHPPercent = logicParam.startHPPercent or 0
    self._endHPPercent = logicParam.endHPPercent or 1
end

function BuffLogicChangeDefenceByOwnerHPPercent:DoLogic()
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()

    ---@type Entity
    local useEntity = ownerEntity
    ---非秘境模式下，使用队伍血量
    if self._world:MatchType() ~= MatchType.MT_Maze and ownerEntity:HasPetPstID() then
        useEntity = ownerEntity:Pet():GetOwnerTeamEntity()
    end

    if not ownerEntity:Attributes() or not useEntity:Attributes() then
        return
    end

    ---计算血量百分比
    ---@type AttributesComponent
    local attrCmpt = useEntity:Attributes()
    local maxHP = attrCmpt:CalcMaxHp()
    local curHP = attrCmpt:GetCurrentHP()
    local hpPercent = curHP / maxHP

    ---根据血量百分比计算需要改变的防御百分比
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

    self._buffLogicService:ChangeBaseDefence(ownerEntity, self:GetBuffSeq(), ModifyBaseDefenceType.DefencePercentage, val)
end

function BuffLogicChangeDefenceByOwnerHPPercent:DoOverlap(logicParam)
    return self:DoLogic()
end

---@class BuffLogicChangeDefenceByOwnerHPPercentUndo:BuffLogicBase
_class("BuffLogicChangeDefenceByOwnerHPPercentUndo", BuffLogicBase)
BuffLogicChangeDefenceByOwnerHPPercentUndo = BuffLogicChangeDefenceByOwnerHPPercentUndo

function BuffLogicChangeDefenceByOwnerHPPercentUndo:Constructor(buffInstance, logicParam)
end

function BuffLogicChangeDefenceByOwnerHPPercentUndo:DoLogic()
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()
    self._buffLogicService:RemoveBaseDefence(ownerEntity, self:GetBuffSeq(), ModifyBaseDefenceType.DefencePercentage)
end

function BuffLogicChangeDefenceByOwnerHPPercentUndo:DoOverlap(logicParam)
    return self:DoLogic()
end
