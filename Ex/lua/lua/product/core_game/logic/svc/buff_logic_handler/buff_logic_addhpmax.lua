--[[
    提升血量上限，buff挂谁身上给谁加buff
    两极战队给队伍加血量上限，主线关给队伍加上限，秘境给队伍加上限并平均到每个人
    契法给自己加血量上限，主线关给队伍加上限，秘境给自己加上限并提升队伍上限
]]
AddHPMaxFromType = {
    OwnerEntity = 1, --buff宿主
    NotifyEntity = 2 --buff通知者
}

_class("BuffLogicAddHPMax", BuffLogicBase)
---@class BuffLogicAddHPMax:BuffLogicBase
BuffLogicAddHPMax = BuffLogicAddHPMax

function BuffLogicAddHPMax:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._addValue = logicParam.addValue or 0
    self._addHPMaxFromType = logicParam.addHPMaxFromType or AddHPMaxFromType.OwnerEntity --默认使用buff宿主的属性修改buff宿主
    self._addLimit = logicParam.addLimit or nil --限制添加的值，不能超过被加者生命的百分比
    self._totalAddLimit = logicParam.totalAddLimit --限制加成总上限
    self._displayDamage = logicParam.displayDamage or 1 --是否伤害飘字 默认飘
    self._notAddHP = logicParam.notAddHP or 0 --圣钉加血量上限不加血

    buffInstance.__AddHPMax_AddValue = 0
end

function BuffLogicAddHPMax:DoLogic(notify)
    --修改谁的属性，默认修改buff宿主
    local entity = self._buffInstance:Entity()
    local matchType = self._world:MatchType()
    --秘境下挂谁身上给谁加buff，其他情况给队伍加
    if matchType ~= MatchType.MT_Maze and entity:HasPetPstID() then
        entity = entity:Pet():GetOwnerTeamEntity()
    end
    local curHp = entity:Attributes():GetCurrentHP()
    if not curHp then--没有hp属性 例如合击技技能holder
        return
    end
    --死亡的不处理
    if entity:Attributes():GetCurrentHP() == 0 then
        return
    end

    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")

    --使用谁的属性
    local attributeEntity
    if self._addHPMaxFromType == AddHPMaxFromType.OwnerEntity then
        attributeEntity = entity
    elseif self._addHPMaxFromType == AddHPMaxFromType.NotifyEntity then
        attributeEntity = notify:GetNotifyEntity()
    end

    --计算血量增加值
    local baseMaxHp = attributeEntity:Attributes():CalcMaxHp()
    local add_value = math.floor(baseMaxHp * self._mulValue + self._addValue + 0.5)
    if self._addLimit then
        local ownerMaxHp = entity:Attributes():CalcMaxHp()
        add_value = math.min(add_value, math.floor(ownerMaxHp * self._addLimit))
    end

    --计算血量加成总上限
    if self._totalAddLimit then
        local curAddHpMax = self._buffComponent:GetBuffValue("AddHPMaxTotalLimit") or 0
        if curAddHpMax + add_value > math.floor(baseMaxHp * self._totalAddLimit + 0.5) then
            add_value = math.floor(baseMaxHp * self._totalAddLimit - curAddHpMax + 0.5)
        end
        self._buffComponent:AddBuffValue("AddHPMaxTotalLimit", add_value)
    end

    self._buffInstance.__AddHPMax_AddValue = self._buffInstance.__AddHPMax_AddValue + add_value
    --修改血量上限
    local ret = calcDamage:AddTargetMaxHP(entity:GetID(), self._buffInstance.__AddHPMax_AddValue, self:GetBuffSeq())

    --加红血量
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(add_value, DamageType.Recover)
    if self._notAddHP ~= 1 then
        calcDamage:AddTargetHP(entity:GetID(), damageInfo)
    end
    local buffResult = BuffResultAddHPMax:New(entity:GetID(), damageInfo, ret, self._displayDamage, self._notAddHP)
    return buffResult
end