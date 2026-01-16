_class("BuffViewShowCalcScope", BuffViewBase)
---@class BuffViewShowCalcScope:BuffViewBase
BuffViewShowCalcScope = BuffViewShowCalcScope

function BuffViewShowCalcScope:PlayView(TT)
    ---@type BuffResultCalcScope
    local result = self:GetBuffResult()

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")

    local attackRange = result:GetScopeResult():GetAttackRange()

    local outlineEntityList = renderEntityService:CreateAreaOutlineEntity(attackRange, EntityConfigIDRender.WarningArea)
    for i = 1, #outlineEntityList do
        local outlineEntity = outlineEntityList[i]
        outlineEntity:ReplaceDamageWarningAreaElement(self:Entity():GetID(),EntityConfigIDRender.WarningArea)
    end
end

_class("BuffViewHideCalcScope", BuffViewBase)
---@class BuffViewHideCalcScope:BuffViewBase
BuffViewHideCalcScope = BuffViewHideCalcScope

function BuffViewHideCalcScope:PlayView(TT)
    local ownerEntityID = self:Entity():GetID()
    local casterEntity = self:Entity()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local group = world:GetGroup(world.BW_WEMatchers.DamageWarningAreaElement)
    local pubListEntity = group:GetEntities()
    local listEntity = {}
    for _, entity in ipairs(pubListEntity) do
        ---@type DamageWarningAreaElementComponent
        local cmpt = entity:DamageWarningAreaElement()
        if cmpt:GetOwnerEntityID() and cmpt:GetOwnerEntityID() == ownerEntityID then
            table.insert(listEntity, entity)
        end
    end

    ---@type EntityPoolServiceRender
    local entityPoolSvcR = world:GetService("EntityPool")
    for i = 1, #listEntity do
        ---@type Entity
        local entityWork = listEntity[i]
        ---@type DamageWarningAreaElementComponent
        local cmpt = entityWork:DamageWarningAreaElement()
        local entityConfigID =cmpt:GetEntityConfigID()
        if entityConfigID then
            entityPoolSvcR:DestroyCacheEntity(entityWork,entityConfigID)
        else
            entityPoolSvcR:DestroyCacheEntity(entityWork, EntityConfigIDRender.WarningArea)
        end
        cmpt:ClearOwnerEntityID()
    end
end
