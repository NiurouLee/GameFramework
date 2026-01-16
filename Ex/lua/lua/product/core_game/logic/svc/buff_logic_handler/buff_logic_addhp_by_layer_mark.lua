--[[
    根据LayerMark增加血量
]]
_class("BuffLogicAddHPByLayerMark", BuffLogicBase)
---@class BuffLogicAddHPByLayerMark:BuffLogicBase
BuffLogicAddHPByLayerMark = BuffLogicAddHPByLayerMark

function BuffLogicAddHPByLayerMark:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._oneLayerValue = logicParam.oneLayerValue or 0
end

function BuffLogicAddHPByLayerMark:DoLogic(notify)
    ---@type Entity
    local casterEntity = self._buffInstance:Entity()
    --优先使用技能的上下文
    local context = self._buffInstance:Context()
    if context then
        casterEntity = context.casterEntity
    end

    ---@type Entity
    local e = casterEntity
    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0
    --如果是一个星灵，则对队长加血
    if casterEntity:PetPstID() then
        e = casterEntity:Pet():GetOwnerTeamEntity()
    end

    --死亡不加血
    if e:Attributes():GetCurrentHP() == 0 then
        return
    end

    --没有禁疗属性才能回血
    if e:Attributes():GetAttribute("BuffForbidCure") then
        return
    end
    ---@type AttributesComponent
    local attrCmpt = casterEntity:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()
    if casterEntity:PetPstID() then --是星灵
        local pstId = casterEntity:PetPstID():GetPstID()
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(pstId)
        max_hp = petData:GetPetHealth()
    end
    --获取层数
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local curMarkLayer = svc:GetBuffLayer(self._entity, self._layerType)
    local add_value = 0

    add_value = max_hp * self._oneLayerValue * curMarkLayer
    local damageType = DamageType.Recover

    add_value = add_value * (1 + rate)
    ---@type CalcDamageService
    local svc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(add_value, damageType)
    svc:AddTargetHP(e:GetID(), damageInfo)

    local res = BuffResultAddHPByLayerMark:New(damageInfo, e:GetID())
    return res
end
