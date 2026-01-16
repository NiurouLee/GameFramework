require("base_ins_r")
--约书亚主动技针对魔免怪的特殊处理指令
---@class PlayBeHitEffectAtPickUpMonsterInstruction: BaseInstruction
_class("PlayBeHitEffectAtPickUpMonsterInstruction", BaseInstruction)
PlayBeHitEffectAtPickUpMonsterInstruction = PlayBeHitEffectAtPickUpMonsterInstruction

function PlayBeHitEffectAtPickUpMonsterInstruction:Constructor(paramList)
    self._hitEffectID = tonumber(paramList["hitEffectID"])
    self._pickUpIndex = tonumber(paramList["pickUpIndex"]) or 1
end

---@param casterEntity Entity
function PlayBeHitEffectAtPickUpMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local oriEntity = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        oriEntity = cSuperEntity:GetSuperEntity()
    end

    ---@type MainWorld
    local world = oriEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---@type RenderPickUpComponent
    local renderPickUpComponent = oriEntity:RenderPickUpComponent()
    if not renderPickUpComponent then
        return
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local v2PickupPos = pickUpGridArray[self._pickUpIndex]
    
    ---@type UtilDataServiceShare
    --local utilData = world:GetService("UtilData")
    --local targetEntity = utilData:GetMonsterAtPos(v2PickupPos)
    local targetEntity = self:_FindTargetEntityOnPos(v2PickupPos,world)
    if not targetEntity then
        return
    end
    -- if monsterEntity:HasDeadMark() then
    --     return
    -- end

    ---------
    local playDamageService = world:GetService("PlayDamage")
    local damageGridPos = v2PickupPos
    local damageShowType = playDamageService:SingleOrGrid(skillID)
    if self._hitEffectID and self._hitEffectID > 0 then
        local beHitEffectEntity =
            effectService:CreateBeHitEffect(self._hitEffectID, targetEntity, damageShowType, damageGridPos)
        if beHitEffectEntity ~= nil then
            ---@type EffectControllerComponent
            local effectCtrl = beHitEffectEntity:EffectController()
            if effectCtrl ~= nil and casterEntity ~= nil then
                effectCtrl:SetEffectCasterID(casterEntity:GetID())
            end

            -- if self._randomDir then
            --     effectCtrl:SetNoResetRotationOnCreated(true)

            --     local rand = math.random(self._randomMin, self._randomMax)
            --     local v3 = Vector3.up * rand * phaseContext.__PlayTargetBeHitEffect_RandTime
            --     ---@type UnityEngine.Transform
            --     local trans = beHitEffectEntity:View():GetGameObject().transform
            --     trans.rotation = Quaternion.identity
            --     trans:Rotate(v3)

            --     phaseContext.__PlayTargetBeHitEffect_RandTime = phaseContext.__PlayTargetBeHitEffect_RandTime + 1
            -- end
        end
    end
end

function PlayBeHitEffectAtPickUpMonsterInstruction:GetCacheResource()
    local t = {}
    if self._hitEffectID and self._hitEffectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._hitEffectID].ResPath, 1 })
    end
    return t
end
function PlayBeHitEffectAtPickUpMonsterInstruction:_FindTargetEntityOnPos(v2Pos,world)
    if world:MatchType() == MatchType.MT_BlackFist then
        local enemyTeamEntity = world:Player():GetCurrentEnemyTeamEntity()
        if enemyTeamEntity then
            if enemyTeamEntity:GetRenderGridPosition() == v2Pos then
                return enemyTeamEntity
            end
        end
    else
        local monster_group = world:GetGroup(world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monster_group:GetEntities()) do
            --if not e:HasDeadMark() then
            local monsterPos = e:GetRenderGridPosition()
            local bodyAreaList = e:BodyArea():GetArea()
            for _, bodyArea in ipairs(bodyAreaList) do
                local pos = monsterPos + bodyArea
                if pos == v2Pos then
                    return e
                end
            end
        end
    end
end