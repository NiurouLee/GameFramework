--[[
    护盾转血量逻辑
]]
_class("BuffLogicShieldToHP", BuffLogicBase)
BuffLogicShieldToHP = BuffLogicShieldToHP

function BuffLogicShieldToHP:Constructor(buffInstance, logicParam)
    self._recoverPersent = logicParam.recoverPersent
    self._clearShield = logicParam.clearShield
    self._lessThanLostHp = logicParam.lessThanLostHp or false
    self._lessThanPetMaxHp = logicParam.lessThanPetMaxHp or false
end

function BuffLogicShieldToHP:DoLogic()
    local e = self._buffInstance:Entity()

    --如果是一个星灵，则对队长加血
    ---@type Entity
    local recoverEntity = e
    if e:PetPstID() then
        recoverEntity = e:Pet():GetOwnerTeamEntity()
    end

    ---@type BuffComponent
    local buffCmpt = recoverEntity:BuffComponent()
    if buffCmpt == nil then
        return
    end

    local curShieldValue = buffCmpt:GetBuffValue("HPShield") or 0
    if curShieldValue == 0 then
        return
    end

    ---计算原始护盾转血量值
    local addHp = curShieldValue * self._recoverPersent
    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0
    addHp = math.floor(addHp * (1 + rate))

    ---计算加限制后的护盾转血量值
    local shieldToHpVal = addHp
    if self._lessThanPetMaxHp and self._lessThanLostHp then
        ---计算出已损失血量
        local lostHp = self:CalcLostHp(recoverEntity)
        ---最大血量
        local ownerMaxHp = self:GetBuffOwnerMaxHp(e)

        local maxShieldToHp = math.min(ownerMaxHp, lostHp)
        shieldToHpVal = math.min(addHp, maxShieldToHp)
    end

    local curShield = 0
    ---修改剩余护盾值
    if self._clearShield then
        buffCmpt:SetBuffValue("HPShield", curShield)
    else
        curShield = curShieldValue - shieldToHpVal
        if curShield < 0 then
            curShield = 0
        end

        buffCmpt:SetBuffValue("HPShield", curShield)
    end

    --没有禁疗属性才能回血
    if recoverEntity:Attributes():GetAttribute("BuffForbidCure") then
        Log.notice("BuffForbidCure , 諾爾無法回血")
        return
    end

    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(shieldToHpVal, DamageType.Recover)
    calcDamageSvc:AddTargetHP(recoverEntity:GetID(), damageInfo)
    addHp = damageInfo:GetDamageValue()
    local result = BuffResultShieldToHP:New(addHp, damageInfo,curShield)
    return result
end

---@param recoverEntity Entity
function BuffLogicShieldToHP:CalcLostHp(recoverEntity)
    ---取出当前血量和最大血量
    local currentHp = recoverEntity:Attributes():GetCurrentHP()
    local maxHp = recoverEntity:Attributes():CalcMaxHp()
    local lostHp = maxHp - currentHp
    return lostHp
end

---@param e Entity
function BuffLogicShieldToHP:GetBuffOwnerMaxHp(e)
    local ownerMaxHp = 0
    if e:HasPetPstID() then
        local pstid = e:PetPstID():GetPstID()
        local petData = self._world.BW_WorldInfo:GetPetData(pstid)
        ownerMaxHp = petData:GetPetHealth()
    elseif e:HasMonsterID() then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = configService:GetMonsterConfigData()
        local monsterid = e:MonsterID():GetMonsterID()
        local maxhp = monsterConfigData:GetMonsterHealth(monsterid)
        ownerMaxHp = maxhp
    end

    return ownerMaxHp
end
