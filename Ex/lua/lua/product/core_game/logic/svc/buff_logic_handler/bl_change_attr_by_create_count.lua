_class("BuffLogicChangeAttrByCreateCount", BuffLogicBase)
---@class BuffLogicChangeAttrByCreateCount : BuffLogicBase
BuffLogicChangeAttrByCreateCount = BuffLogicChangeAttrByCreateCount

---@class BuffLogicChangeAttrByCreateCountType
local  BuffLogicChangeAttrByCreateCountType={
    Attack =1,
    MaxHp =2,
    Defence = 3,
}
_enum("BuffLogicChangeAttrByCreateCountType",BuffLogicChangeAttrByCreateCountType)

function BuffLogicChangeAttrByCreateCount:Constructor(buffInstance, logicParam)
    self._monsterID = logicParam.monsterID
    self._monsterClassID = logicParam.monsterClassID
    ---@type number[]
    self._changeAttrType = logicParam.changeAttrType or {}
    self._changeAttrParam = logicParam.changeAttrParam or {}
    if #self._changeAttrType ~= #self._changeAttrParam then
        Log.error("BuffLogicChangeAttrByCreateCount:Constructor changeAttrType and changeAttrParam length not equal")
        if EDITOR then
            Log.exception("BuffLogicChangeAttrByCreateCount:Constructor changeAttrType and changeAttrParam length not equal")
        end
    end
end

---@param notify NTMonsterShow
function BuffLogicChangeAttrByCreateCount:DoLogic(notify)
    if notify:GetNotifyType() ~= NotifyType.MonsterShow then
        return
    end
    ---@type Entity
    local ntEntity = notify:GetNotifyEntity()
    local count = 0
    ---@type BattleStatComponent
    local cBattleStat = self._world:BattleStat()
    if self._monsterID then
        count =count + cBattleStat:GetMonsterIDCount(self._monsterID)
    end
    if self._monsterClassID then
        count =count + cBattleStat:GetMonsterClassIDCount(self._monsterClassID)
    end
    for i, v in ipairs(self._changeAttrType) do
        local value = self._changeAttrParam[i]*count
        if v == BuffLogicChangeAttrByCreateCountType.Attack then
            self._buffLogicService:ChangeBaseAttack(ntEntity,self:GetBuffSeq(),ModifyBaseAttackType.AttackPercentage, value)
        elseif v == BuffLogicChangeAttrByCreateCountType.Defence then
            self._buffLogicService:ChangeBaseDefence(ntEntity,self:GetBuffSeq(),ModifyBaseDefenceType.DefencePercentage, value)
        elseif v == BuffLogicChangeAttrByCreateCountType.MaxHp then
            self._buffLogicService:ChangeBaseMaxHP(ntEntity,self:GetBuffSeq(),ModifyBaseMaxHPType.MaxHPPercentage, value)
            local maxHP = ntEntity:Attributes():CalcMaxHp()
            local curHP=  ntEntity:Attributes():GetCurrentHP()
            ntEntity:Attributes():Modify("HP", maxHP)
            Log.info("BuffLogicChangeAttrByCreateCount:DoLogic change maxHP =",maxHP," OldHP:",curHP," NewHP：",maxHP)
        end
    end
end