require("base_ins_r")
---暗屏的开启与关闭
---@class PlayDeleteWaringAreaInstruction: BaseInstruction
_class("PlayDeleteWaringAreaInstruction", BaseInstruction)
PlayDeleteWaringAreaInstruction = PlayDeleteWaringAreaInstruction

function PlayDeleteWaringAreaInstruction:Constructor(paramList)
    self._warningTextEffectID = tonumber(paramList["warningTextEffectID"]) or BattleConst.DefaultWarningAreaTextEffectID
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDeleteWaringAreaInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local group = world:GetGroup(world.BW_WEMatchers.DamageWarningAreaElement)
    local pubListEntity = group:GetEntities()
    local listEntity = {}
    for _, entity in ipairs(pubListEntity) do
        ---@type DamageWarningAreaElementComponent
        local cmpt = entity:DamageWarningAreaElement()
        ---这里原始实现有问题 会删掉所有的预警区  先简单判断下只删有主的预警区
        if cmpt:GetOwnerEntityID() and cmpt:GetOwnerEntityID()  ~=0  then
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
            entityPoolSvcR:DestroyCacheEntity(entityWork,EntityConfigIDRender.WarningArea)
        end
        cmpt:ClearOwnerEntityID()
        --world:DestroyEntity(entityWork)
    end

    -- 下面这段操作模仿自PlaySkillRemoveEffectPhase
    ---@type EffectHolderComponent
    local fxHoldCmpt = casterEntity:EffectHolder()
    if not fxHoldCmpt then return end

    local dicFxHeld = fxHoldCmpt:GetEffectIDEntityDic()
    local lstFx = dicFxHeld[self._warningTextEffectID]

    if not lstFx then return end

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
