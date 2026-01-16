--[[----------------------------------------------------------
    PetChainSkillAttack 连锁技表现播放的基类
]] ------------------------------------------------------------
_class("PetChainSkillAttack", Object)
---@class PetChainSkillAttack:Object
PetChainSkillAttack = PetChainSkillAttack

function PetChainSkillAttack:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---提取连锁技的表现phase队列
function PetChainSkillAttack:_GetChainSkillPhaseArray(casterEntity, skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
    end
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray(skinId)

    return skillPhaseArray
end

function PetChainSkillAttack:_CheckFinalAttack(skillEffectResultContainer, casterEntity)
    local damageReslut = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if damageReslut == nil then
        skillEffectResultContainer:SetFinalAttack(false)
    else
        skillEffectResultContainer:SetFinalAttack(true)

        self:_SortForFinalAttack(damageReslut, casterEntity)
        ---@type SkillDamageEffectResult
        local skillDamageResult = damageReslut[#damageReslut]
        local finalAttackEnemyID = skillDamageResult:GetTargetID()
        skillEffectResultContainer:SetFinalAttackEntityID(finalAttackEnemyID)
    end
end

---此函数对逻辑结果进行了排序，有副作用，可能会导致计算出来的顺序和实际播放的顺序不一致
---todo:删掉
function PetChainSkillAttack:_SortForFinalAttack(skillDamageResultArray, casterEntity)
    if skillDamageResultArray == nil or #skillDamageResultArray <= 1 then
        return skillDamageResultArray
    end

    local count = #skillDamageResultArray
    ---先按照目标占据的格子大小来排序
    local function CmpBodyAreafunc(skillDamageEffectResult1, skillDamageEffectResult2)
        local areaCount1 = self:_GetAreaCount(skillDamageEffectResult1)
        local areaCount2 = self:_GetAreaCount(skillDamageEffectResult2)

        return areaCount1 < areaCount2
    end
    table.sort(skillDamageResultArray, CmpBodyAreafunc)

    ---查看最大的一个目标的格子数
    ---@type SkillDamageEffectResult
    local lastSkillDamageResult = skillDamageResultArray[count]
    local maxAreaCount = self:_GetAreaCount(lastSkillDamageResult)

    local sortByAreaArray = {}
    ---把所有格子数最大的放到一个队列里
    for _, v in ipairs(skillDamageResultArray) do
        local curAreaCount = self:_GetAreaCount(v)
        if curAreaCount == maxAreaCount then
            sortByAreaArray[#sortByAreaArray + 1] = v
        end
    end

    local areaArrayCount = #sortByAreaArray
    if areaArrayCount <= 1 then
        --只有一个目标，说明不需要按照距离排序了
        return skillDamageResultArray
    else
        --按照距离对sortByAreaArray排序
        local function CmpDistancefunc(skillDamageEffectResult1, skillDamageEffectResult2)
            local dis1 = self:_GetDistanceToPlayer(skillDamageEffectResult1, casterEntity)
            local dis2 = self:_GetDistanceToPlayer(skillDamageEffectResult2, casterEntity)

            return dis1 < dis2
        end
        table.sort(sortByAreaArray, CmpDistancefunc)

        ---得到距离最远的目标
        local maxDistanceResult = sortByAreaArray[areaArrayCount]

        ---先移除
        table.removev(skillDamageResultArray, maxDistanceResult)
        ---将这个目标放到最后一个元素
        skillDamageResultArray[#skillDamageResultArray + 1] = maxDistanceResult
    end
end

function PetChainSkillAttack:_GetAreaCount(skillDamageResult)
    local entityID = skillDamageResult:GetTargetID()
    local entity = self._world:GetEntityByID(entityID)
    ---这里的entityID找到的目标有可能是空，但
    if entity == nil then
        return 0
    end

    ---@type BodyAreaComponent
    local bodyAreaCmpt = entity:BodyArea()
    local areaCount = 0
    if bodyAreaCmpt ~= nil then
        areaCount = bodyAreaCmpt:GetAreaCount()
    end

    return areaCount
end
---@param casterEntity Entity
function PetChainSkillAttack:_GetDistanceToPlayer(skillDamageResult, casterEntity)
    local playerPos = casterEntity:GridLocation().Position
    local gridPos = skillDamageResult:GetGridPos()
    return Vector2.Distance(gridPos, playerPos)
end

---@return Vector2[]
---@param casterEntity Entity
function PetChainSkillAttack:GetPetForward(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type Vector2
    local casterPos = casterEntity:GridLocation().Position
    ---@type SkillDamageEffectResult[]
    local damageResultList = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if not damageResultList or table.count(damageResultList) == 0 then
        return
    end

    local beAttackEntityID = damageResultList[1]:GetTargetID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(beAttackEntityID)
    if not targetEntity then
        return
    end

    local function get_index(c, p)
        if p.x - c.x == 0 and p.y - c.y > 0 then
            return 1
        end
        if p.x - c.x > 0 and p.y - c.y > 0 then
            return 2
        end
        if p.x - c.x > 0 and p.y - c.y == 0 then
            return 3
        end
        if p.x - c.x > 0 and p.y - c.y < 0 then
            return 4
        end
        if p.x - c.x == 0 and p.y - c.y < 0 then
            return 5
        end
        if p.x - c.x < 0 and p.y - c.y < 0 then
            return 6
        end
        if p.x - c.x < 0 and p.y - c.y == 0 then
            return 7
        end
        if p.x - c.x < 0 and p.y - c.y > 0 then
            return 8
        end
        return 1
    end
    ---@type table<number,Vector2>
    local damagePosList = {}
    for i, result in ipairs(damageResultList) do
        if result:GetGridPos() then
            table.insert(damagePosList, result:GetGridPos())
        end
    end
    local cmpFunc = function(damageResultPos1, damageResultPos2)
        local dis1 = Vector2.Distance(damageResultPos1, casterPos)
        local dis2 = Vector2.Distance(damageResultPos2, casterPos)
        if dis1 == dis2 then
            return get_index(casterPos, damageResultPos1) < get_index(casterPos, damageResultPos2)
        else
            return dis1 < dis2
        end
    end
    table.sort(damagePosList, cmpFunc)
    local dir = damagePosList[1] - casterPos
    return dir
end
---@param casterEntity Entity
function PetChainSkillAttack:_IsLastPlayChainSkill(casterEntity)
    local playerEntity = casterEntity:Pet():GetOwnerTeamEntity()
    ---@type ChainSkillSequenceComponent
    local cChainSkillSequence = playerEntity:ChainSkillSequence()
    local arr = {playerEntity:GetID()}
    if cChainSkillSequence.ChainSkillSeqTable then
        for i, v in ipairs(cChainSkillSequence.ChainSkillSeqTable) do
            table.insert(arr, v)
        end
    end
    if arr[table.count(arr)] == casterEntity:GetID() then
        return true
    end
    return false
end

function PetChainSkillAttack:_ShowChainAttackMonsterDead(TT)
    ---怪物死亡
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:DoAllMonsterDeadRender(TT)
end

---提取施法者连锁技的打死怪物ID
---@param casterEntityID number 施法者的EntityID
function PetChainSkillAttack:_OnResultDeadEntityAddDeadFlag(casterEntityID, chainIndex)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_ChainAttackResult
    local chainAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.ChainAttack)

    local deadEntityIdList = chainAtkResCmpt:GetDeadEntityIDListByPet(casterEntityID)

    --刷新死亡标记
    local deadList = deadEntityIdList[chainIndex]
    if deadList then
        for _, eid in ipairs(deadList) do
            local e = self._world:GetEntityByID(eid)
            e:AddDeadFlag()
        end
    end
end
