--[[
    血量血条护盾
]]
---@class HPShieldFromType
local HPShieldFromType = {
    OwnerHP = 1, --buff宿主的血量百分比
    CasterHP = 2, --buff施法者的血量百分比
    LastDamage = 3, --buff宿主上次攻击造成的伤害百分比
    SpecificPet = 4, --指定宝宝
    SpilledHP = 5, --超载光盾溢出血量百分比
    OwnerMaxHP = 6, --buff宿主最大血量的百分比
    OwnerDefence = 7, --buff宿主防御力的百分比
    OwnerBaseDefence = 8, --buff宿主基础防御力的百分比
    OwnerBaseAttack = 9, --buff宿主基础攻击力百分比
    OwnerAttack = 10, --buff宿主攻击力百分比
    OwnerLostHPPercent = 11, --buff宿主损失生命
}
_enum("HPShieldFromType", HPShieldFromType)

--添加护盾buff
_class("BuffLogicAddHPShield", BuffLogicBase)
---@class BuffLogicAddHPShield : BuffLogicBase
BuffLogicAddHPShield = BuffLogicAddHPShield

function BuffLogicAddHPShield:Constructor(buffInstance, logicParam)
    self._shieldPercent = logicParam.shieldPercent
    self._shieldFromType = logicParam.shieldFromType or HPShieldFromType.OwnerHP
    self._shieldFromParam = logicParam.shieldFromParam
    self._mulChangeLayer = logicParam.mulChangeLayer --乘以变化层数
end

function BuffLogicAddHPShield:DoLogic(notify)
    --默认血条盾加给队伍
    ---@type Entity
    local buffResultEntity

    local entity = self._buffInstance:Entity()
    if entity:HasMonsterID() then
        buffResultEntity = entity
    else
        buffResultEntity = self._world:Player():GetCurrentTeamEntity()
    end
    local value = 0
    if self._shieldFromType == HPShieldFromType.OwnerHP then
        value = entity:Attributes():GetCurrentHP()
    elseif self._shieldFromType == HPShieldFromType.OwnerMaxHP then
        value = entity:Attributes():CalcMaxHp()
    elseif self._shieldFromType == HPShieldFromType.CasterHP then
        local casterEntity = self._buffInstance:Context().casterEntity
        if casterEntity:HasPetPstID() then
            --Log.error("petData:GetPetHealth()   ", petData:GetPetHealth())
            local pstid = casterEntity:PetPstID():GetPstID()
            local petData = self._world.BW_WorldInfo:GetPetData(pstid)
            value = petData:GetPetHealth()
        elseif casterEntity:HasMonsterID() then
            -- --怪物也可以加血条盾
            -- buffResultEntity = casterEntity

            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type MonsterConfigData
            local monsterConfigData = configService:GetMonsterConfigData()
            local monsterid = casterEntity:MonsterID():GetMonsterID()
            local maxhp = monsterConfigData:GetMonsterHealth(monsterid)
            value = maxhp
        else
            value = 0
        end
    elseif self._shieldFromType == HPShieldFromType.LastDamage then
        value = notify:GetDamage()
    elseif self._shieldFromType == HPShieldFromType.SpecificPet then
        ---@type Entity
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if entity:HasTeam() then
            teamEntity = entity
        elseif entity:HasPet() then
            teamEntity = entity:Pet():GetOwnerTeamEntity()
        end
        local pets = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(pets) do
            local cPetPstID = e:PetPstID()
            if self._shieldFromParam == cPetPstID:GetTemplateID() then
                value = e:Attributes():GetCurrentHP()
                break
            end
        end
    elseif self._shieldFromType == HPShieldFromType.SpilledHP then
        value = self._buffInstance:Context().hpSpilled
    elseif self._shieldFromType == HPShieldFromType.OwnerDefence then
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        local totalDefence =attributesComponent:GetDefence()
        value = totalDefence
    elseif self._shieldFromType == HPShieldFromType.OwnerBaseDefence then
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        local baseDefence = attributesComponent:GetAttribute("Defense")
        value = baseDefence
    elseif self._shieldFromType == HPShieldFromType.OwnerBaseAttack then
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        local baseAttack = attributesComponent:GetAttribute("Attack")
        value = baseAttack
    elseif self._shieldFromType == HPShieldFromType.OwnerAttack then
        ---@type AttributesComponent
        local attributesComponent = entity:Attributes()
        local curAttack = attributesComponent:GetAttack()
        value = curAttack
    elseif self._shieldFromType == HPShieldFromType.OwnerLostHPPercent then
        local cAttributes = entity:Attributes()
        local maxHP = cAttributes:CalcMaxHp()
        local currentHP = cAttributes:GetCurrentHP()
        value = maxHP - currentHP
    end

    local addShield = self._shieldPercent * value
    if self._mulChangeLayer and notify.GetChangeLayer then
        local layer = notify:GetChangeLayer()
        addShield = addShield * math.abs(layer)
    end
    
    local curHpSh = buffResultEntity:BuffComponent():AddBuffValue("HPShield", addShield)
    local damageInfo = DamageInfo:New(0, DamageType.Recover)
    damageInfo:SetHPShield(curHpSh)

    self._world:GetMatchLogger():BeginBuff(self._entity:GetID(), self._buffInstance:BuffID())
    local logger = self._world:GetMatchLogger()
    logger:AddHPShieldLog(
        self._entity:GetID(),
        {
            key = "CalcAddHPShield",
            desc = "BUFF加血条盾 攻击者[attacker] 被击者[defender] 加盾值[addShield] 当前血条盾[curShield] ",
            attacker = self._entity:GetID(),
            defender = buffResultEntity:GetID(),
            addShield = addShield,
            curShield = curHpSh
        }
    )
    self._world:GetMatchLogger():EndBuff(self._entity:GetID())

    local buffResult = BuffResultAddHPShield:New(buffResultEntity:GetID(), damageInfo)
    return buffResult
end

function BuffLogicAddHPShield:DoOverlap(logicParam)
    self._shieldPercent = logicParam.shieldPercent
    return self:DoLogic()
end

--去除护盾buff
_class("BuffLogicRemoveHPShield", BuffLogicBase)
BuffLogicRemoveHPShield = BuffLogicRemoveHPShield
function BuffLogicRemoveHPShield:Constructor(buffInstance, logicParam)
    self._isOwner = logicParam.isOwner
end
function BuffLogicRemoveHPShield:DoLogic()
    ---@type Entity
    local entity = self._world:Player():GetCurrentTeamEntity()
    if self._isOwner then
        entity = self._buffInstance:Entity()
    end

    if not entity:BuffComponent():HasBuffEffect(BuffEffectType.ShieldToHP) then
        entity:BuffComponent():SetBuffValue("HPShield", 0)
    end
    local damageInfo = DamageInfo:New(0, DamageType.Recover)
    damageInfo:SetHPShield(0)

    local buffResult = BuffResultRemoveHPShield:New(entity:GetID(), damageInfo)

    return buffResult
end

function BuffLogicRemoveHPShield:DoOverlap()
end
