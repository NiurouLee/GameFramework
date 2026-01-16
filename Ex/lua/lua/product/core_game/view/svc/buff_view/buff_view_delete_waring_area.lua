--[[
    播放表现
]]
_class("BuffViewDeleteWaringArea", BuffViewBase)
---@class BuffViewDeleteWaringArea:BuffViewBase
BuffViewDeleteWaringArea = BuffViewDeleteWaringArea

function BuffViewDeleteWaringArea:PlayView(TT, notify)
    ---@type BuffResultDeleteWaringArea
    local result = self._buffResult

    local skillHolderID = result:GetSkillHolderID()
    local skillHolder = self._world:GetEntityByID(skillHolderID)
    if not skillHolder then
        return
    end

    ---@type MainWorld
    local world = self._world
    local group = world:GetGroup(world.BW_WEMatchers.DamageWarningAreaElement)
    local pubListEntity = group:GetEntities()
    local listEntity = {}
    for _, entity in ipairs(pubListEntity) do
        ---@type DamageWarningAreaElementComponent
        local cmpt = entity:DamageWarningAreaElement()
        ---这里原始实现有问题 会删掉所有的预警区  先简单判断下只删有主的预警区
        if cmpt:GetOwnerEntityID() and cmpt:GetOwnerEntityID() == skillHolder:GetID() then
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
            entityPoolSvcR:DestroyCacheEntity(entityWork, entityConfigID)
        else
            entityPoolSvcR:DestroyCacheEntity(entityWork, EntityConfigIDRender.WarningArea)
        end
        cmpt:ClearOwnerEntityID()
        --world:DestroyEntity(entityWork)
    end

    -- 下面这段操作模仿自PlaySkillRemoveEffectPhase
    ---@type EffectHolderComponent
    local fxHoldCmpt = skillHolder:EffectHolder()
    if not fxHoldCmpt then
        return
    end

    local dicFxHeld = fxHoldCmpt:GetEffectIDEntityDic()
    local lstFx = dicFxHeld[self._warningTextEffectID]

    if not lstFx then
        return
    end

    ---@type EffectService
    local fxSvc = world:GetService("Effect")
    for _, eid in pairs(lstFx) do
        local e = world:GetEntityByID(eid)
        if e then
            world:DestroyEntity(e)
        end
    end
    dicFxHeld[self._warningTextEffectID] = nil
end
