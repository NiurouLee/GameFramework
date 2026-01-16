--[[
    精英怪词缀buff：降低最大生命值
]]
_class("BuffLogicDecreaseMaxHP", BuffLogicBase)
---@class BuffLogicDecreaseMaxHP:BuffLogicBase
BuffLogicDecreaseMaxHP = BuffLogicDecreaseMaxHP

function BuffLogicDecreaseMaxHP:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue

    assert(self._mulValue, "DecreaseMaxHP: parameter [mulValue] is required. ")
    assert((self._mulValue < 1) and (self._mulValue > 0), "DecreaseMaxHP: mulValue is invalid. Range is (0, 1). ")
end

---@return BuffResultDecreaseMaxHP
function BuffLogicDecreaseMaxHP:DoLogic()
    --修改谁的属性，默认修改buff宿主
    local entity = self._buffInstance:Entity()
    local matchType = self._world:MatchType()
    --秘境下挂谁身上给谁加buff，其他情况给队伍加
    if matchType ~= MatchType.MT_Maze and entity:HasPetPstID() then
        entity = entity:Pet():GetOwnerTeamEntity()
    end
    
    --死亡的不处理
    if entity:Attributes():GetCurrentHP() == 0 then
        return
    end

    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")

    local baseMaxHp = entity:Attributes():CalcMaxHp()
    local val = math.floor(baseMaxHp * self._mulValue)
    local ret = calcDamage:DecreaseTargetMaxHP(entity:GetID(), val, self:GetBuffSeq())

    ---@type DamageInfo
    local damageInfo = DamageInfo:New(baseMaxHp - val, DamageType.Real)
    calcDamage:DecreaseTargetHP(entity, damageInfo)
    local buffResult = BuffResultDecreaseMaxHP:New(entity:GetID(), damageInfo, ret)

    return buffResult
end
