--[[------------------------------------------------------------------------------------------
    SkillEffectTargetSorter : 技能目标排序器
    每个技能效果的目标由 目标选择器 SkillScopeTargetSelector 计算得到，
    这个目标列表还有可能需要根据效果进行排序，例如击退效果，需要按照由远到近的排序
    如果有其他技能效果也需要排序，可以在这里做
    这个排序并不是配置出来的，而是对技能效果固定的一个排序
    未来如果需要配置，也可以提取出来
]] --------------------------------------------------------------------------------------------

---@class SkillEffectTargetSorter: Object
_class("SkillEffectTargetSorter", Object)
SkillEffectTargetSorter = SkillEffectTargetSorter

---@param world MainWorld
function SkillEffectTargetSorter:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param casterEntity Entity 施法者
---@param skillEffectParam SkillEffectParamBase 技能效果参数
---@param skillScopeResult SkillScopeResult
function SkillEffectTargetSorter:DoSortTargetList(casterEntity, targetIDArray, skillEffectParam, skillScopeResult)
    ---@type SkillEffectType
    local skillEffectType = skillEffectParam:GetEffectType()
    if skillEffectType == SkillEffectType.HitBack then
        return self:_SortHitbackEffectTargetList(casterEntity, targetIDArray, skillEffectParam)
    end

    ---@type ActiveSkillPickUpComponent
    local component = casterEntity:ActiveSkillPickUpComponent()
    if component then
        local direction = component:GetLastPickUpDirection()
        ---只有火车需要排序,暂时只按照火车需求的排
        if skillEffectType == SkillEffectType.Damage and component:GetLastPickUpDirection() then
            return self:_SortDamageEffectTargetList(
                casterEntity,
                targetIDArray,
                skillEffectParam,
                direction,
                skillScopeResult
            )
        end
    end

    return targetIDArray
end

---@param casterEntity Entity 施法者
---@param hitbackParam SkillHitBackEffectParam 击退效果参数
function SkillEffectTargetSorter:_SortHitbackEffectTargetList(casterEntity, enemyIDList, hitbackParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("caster has no skill routine component")
    end

    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillEffectCalcService
    local effectCalcService = self._world:GetService("SkillEffectCalc")
    local casterPetEntityID = casterEntity:GetID()

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type SkillScopeType
    local scopeType = skillConfigData:GetSkillScopeType()
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    ---@type SkillTargetType
    local targetType = skillConfigData:GetSkillTargetType()

    ---击退方向
    ---@type HitBackDirectionType
    local hitbackDirType = hitbackParam:GetDirType()

    local casterPos = casterEntity:GridLocation().Position
    if pickUpType == SkillPickUpType.DirectionInstruction then
        ---@type ActiveSkillPickUpComponent
        local component = casterEntity:ActiveSkillPickUpComponent()
        if component then
            hitbackDirType = component:GetLastPickUpDirection()
        end
    elseif pickUpType == SkillPickUpType.Instruction then
        ---@type ActiveSkillPickUpComponent
        local component = casterEntity:ActiveSkillPickUpComponent()
        if component then
            if hitbackParam:GetForceUseCasterPos() then
            else
                casterPos = component:GetLastPickUpGridPos()
            end
        end
    end
    self:_SortHitbackTargetByDirType(enemyIDList, hitbackDirType, casterPos)

    for k, v in ipairs(enemyIDList) do
        ---@type Entity
        local enemyEntity = self._world:GetEntityByID(v)
        local pos = enemyEntity:GridLocation().Position
        --Log.fatal("SortHitBack:", pos)
    end

    return enemyIDList
end

---@param hitbackDirType HitBackDirectionType
function SkillEffectTargetSorter:_SortHitbackTargetByDirType(hitbackIDArray, hitbackDirType, casterPos)
    if hitbackDirType == HitBackDirectionType.Left then
        local function CmpLeftfunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position

            return pos1.x < pos2.x
        end
        table.sort(hitbackIDArray, CmpLeftfunc)
    elseif hitbackDirType == HitBackDirectionType.Right then
        local function CmpRightfunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position

            return pos1.x > pos2.x
        end
        table.sort(hitbackIDArray, CmpRightfunc)
    elseif hitbackDirType == HitBackDirectionType.Up then
        local function CmpUpfunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position
            return pos1.y > pos2.y
        end
        table.sort(hitbackIDArray, CmpUpfunc)
    elseif hitbackDirType == HitBackDirectionType.Down then
        local function CmpDownfunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position
            return pos1.y < pos2.y
        end
        table.sort(hitbackIDArray, CmpDownfunc)
    elseif hitbackDirType == HitBackDirectionType.AntiEightDir then
        local function CmpDistancefunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position
            local castPos = casterPos
            local dis1 = Vector2.Distance(castPos, pos1)
            local dis2 = Vector2.Distance(castPos, pos2)
            return dis1 < dis2
        end
        table.sort(hitbackIDArray, CmpDistancefunc)
    else
        local function CmpDistancefunc(entityID1, entityID2)
            local entity1 = self._world:GetEntityByID(entityID1)
            local entity2 = self._world:GetEntityByID(entityID2)

            local pos1 = entity1:GridLocation().Position
            local pos2 = entity2:GridLocation().Position
            local castPos = casterPos
            local dis1 = Vector2.Distance(castPos, pos1)
            local dis2 = Vector2.Distance(castPos, pos2)
            return dis1 > dis2
        end
        table.sort(hitbackIDArray, CmpDistancefunc)
    end
end
---暂时只考虑了斜方向单排的情况
---@param skillScopeResult SkillScopeResult
function SkillEffectTargetSorter:_SortDamageEffectTargetList(
    casterEntity,
    targetIDArray,
    skillEffectParam,
    directionType,
    skillScopeResult)
    if #targetIDArray == 0 or not directionType or directionType == HitBackDirectionType.None then
        return targetIDArray
    end
    ---@type Vector2[]
    local validScopeGridList = skillScopeResult:GetAttackRange()
    local cmpFun = nil
    if
    directionType == HitBackDirectionType.Up or directionType == HitBackDirectionType.LeftUp or
            directionType == HitBackDirectionType.RightUp
    then
        cmpFun = function(p1, p2)
            return p1.y < p2.y
        end
    elseif
    directionType == HitBackDirectionType.Down or directionType == HitBackDirectionType.LeftDown or
            directionType == HitBackDirectionType.RightDown
    then
        cmpFun = function(p1, p2)
            return p1.y > p2.y
        end
    elseif directionType == HitBackDirectionType.Left then
        cmpFun = function(p1, p2)
            return p1.x > p2.x
        end
    elseif directionType == HitBackDirectionType.Right then
        cmpFun = function(p1, p2)
            return p1.x < p2.x
        end
    end
    local pos2IDList = {}
    local targetPosList = {}
    for _, entityID in ipairs(targetIDArray) do
        local targetEntity = self._world:GetEntityByID(entityID)
        local bodyArea = targetEntity:BodyArea():GetArea()
        local position = targetEntity:GridLocation().Position
        for k, v in ipairs(bodyArea) do
            local bodyPos = Vector2(v.x + position.x, v.y + position.y)
            ---在攻击范围内
            if table.icontains(validScopeGridList, bodyPos) then
                table.insert(targetPosList, bodyPos)
                pos2IDList[bodyPos] = entityID
            end
        end
    end
    table.sort(targetPosList, cmpFun)
    ---@type Vector2[]
    local firstRowPosList = {}
    local firstRowPos = nil
    local newTargetIDList = {}
    for index, pos in ipairs(targetPosList) do
        ---第一排
        if index == 1 then
            firstRowPos = pos
            table.insert(firstRowPosList, firstRowPos)
        else
            ---左右击退比较X
            if directionType == HitBackDirectionType.Left or directionType == HitBackDirectionType.Right then
                ---上下击退比较Y
                if pos.x == firstRowPos.x then
                    table.insert(firstRowPosList, pos)
                end
            elseif directionType == HitBackDirectionType.Up or directionType == HitBackDirectionType.Down then
                if pos.y == firstRowPos.y then
                    table.insert(firstRowPosList, pos)
                end
            end
        end
        table.insert(newTargetIDList, pos2IDList[pos])
    end
    self._world:GetService("Trigger"):Notify(NTNotifyTrainFirstRowPos:New(firstRowPosList, casterEntity))
    newTargetIDList = table.unique(newTargetIDList)
    return newTargetIDList
end
