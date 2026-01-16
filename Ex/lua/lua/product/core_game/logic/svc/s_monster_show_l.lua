--[[------------------------------------------------------------------------------------------
    MonsterShowLogicService 怪物进场展示相关Service——逻辑 MonsterShowLogic
]] --------------------------------------------------------------------------------------------

_class("MonsterShowLogicService", BaseService)
---@class MonsterShowLogicService:BaseService
MonsterShowLogicService = MonsterShowLogicService

---所有怪物死亡逻辑
function MonsterShowLogicService:DoAllMonsterDeadLogic(deadMarkOrderRequired)
    local drops = self:_CalcMonsterDrop() --逻辑上计算所有怪物的掉落
    --处理幻象死亡，幻象的宿主如果挂了deadmark，那么幻象也要挂上deadmark
    self:_DoPhantamDead()

    local deadEntityIDList = {}
    local deadMarkAddCountMap = {}
    local deadMonsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    for _, e in ipairs(deadMonsterGroup:GetEntities()) do
        if e:HasMonsterID() and not e:DeadMark():HasDoLogicDead() then
            deadEntityIDList[#deadEntityIDList + 1] = e:GetID()
            deadMarkAddCountMap[e:GetID()] = e:DeadMark():GetDeadMarkAddCount()
        end
    end

    if deadMarkOrderRequired then
        table.sort(deadEntityIDList, function (a, b)
            return deadMarkAddCountMap[a] < deadMarkAddCountMap[b]
        end)
    end

    for _, v in ipairs(deadEntityIDList) do
        local monsterEntity = self._world:GetEntityByID(v)
        ---此函数内部会判断是否重复执行过Dead
        self:_DoLogicDead(monsterEntity)
    end
    return drops, deadEntityIDList
end

--幻象跟随主身死亡
function MonsterShowLogicService:_DoPhantamDead()
    local deadMonsters = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark):GetEntities()
    local phantoms = self._world:GetGroup(self._world.BW_WEMatchers.Phantom):GetEntities()
    if deadMonsters and #deadMonsters > 0 and phantoms and #phantoms > 0 then
        local deads = {}
        for _, entity in ipairs(deadMonsters) do
            deads[entity:GetID()] = true
        end
        for _, phantom in ipairs(phantoms) do
            if deads[phantom:PhantomComponent():GetOwnerEntityID()] then
                phantom:AddDeadMark()
            end
        end
    end
end

---@param monsterEntity Entity
---@return number skillID
---计算死亡技效果
function MonsterShowLogicService:_CalcMonsterDeathSkill(monsterEntity)
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterIDCmpt = monsterEntity:MonsterID()
    local deathSkillID = 0
    if monsterIDCmpt then
        deathSkillID = monsterConfigData:GetMonsterDeathSkillID(monsterIDCmpt:GetMonsterID())
        if deathSkillID then
            ---@type SkillLogicService
            local skillLogicService = self._world:GetService("SkillLogic")
            skillLogicService:CalcSkillEffect(monsterEntity, deathSkillID)
            skillLogicService:UpdateRenderSkillRoutine(monsterEntity)
        end
    end
    return deathSkillID
end

---@param monsterEntity Entity
function MonsterShowLogicService:_DoLogicDead(monsterEntity)
    if not monsterEntity:HasDeadMark() then
        Log.exception("monster entity has not dead,", Log.traceback())
        return
    end

    ---@type DeadMarkComponent
    local deadMarkCmpt = monsterEntity:DeadMark()
    if deadMarkCmpt:HasDoLogicDead() then
        ---走到这里，说明重复执行了死亡逻辑
        --Log.warn("monster has do logic dead ", Log.traceback())
        return
    end

    ---@type MonsterIDComponent
    local monsterIDCmpt = monsterEntity:MonsterID()
    if not monsterIDCmpt then
        return
    end

    deadMarkCmpt:SetDoLogicDead(true)

    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")

    --buff
    sTrigger:Notify(NTMonsterDeadStart:New(monsterEntity)) --死亡开始触发通知

    --掉落技能
    self:CalcDropSkill(monsterEntity)

    --死亡技能
    self:_CalcMonsterDeathSkill(monsterEntity)

    --清除阻挡
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    sBoard:RemoveEntityBlockFlag(monsterEntity, monsterEntity:GridLocation().Position)

    --buff
    sTrigger:Notify(NTMonsterDead:New(monsterEntity)) --死亡触发通知
    --设置逻辑坐标
    monsterEntity:SetGridPosition(Vector2(BattleConst.CacheHeight, BattleConst.CacheHeight))

    sTrigger:Notify(NTMonsterDeadEnd:New(monsterEntity)) --死亡触发通知
end

---计算怪物掉落
function MonsterShowLogicService:_CalcMonsterDrop()
    ---找出所有带了DeadMark组件的目标
    local deadMonsterArray = self:_CalcDeadMonsterOrder() ---找出本轮死亡的怪
    ---@type DropService
    local dropService = self._world:GetService("Drop")
    local drops = {}
    for _, deadEntityID in ipairs(deadMonsterArray) do
        ---@type Entity
        local monsterEntity = self._world:GetEntityByID(deadEntityID)
        ---@type DropAssetComponent
        local dropCmpt = monsterEntity:DropAsset()
        if not dropCmpt:HasDoDrop() then
            dropCmpt:SetDoDrop(true)

            ---@type MonsterIDComponent
            local monsterIDCmpt = monsterEntity:MonsterID()
            if monsterIDCmpt then
                local monsterConfigID = monsterIDCmpt:GetMonsterID()
                local monsterConfigData = self._configService:GetMonsterConfigData()
                local dropArray = monsterConfigData:GetMonsterDropIDs(monsterConfigID)
                local dropAssetList = {}
                if dropArray ~= nil then
                    for _, v in ipairs(dropArray) do
                        local asset = dropService:DoActorDrop(v.dropID, deadEntityID, true)
                        if asset then
                            table.insert(dropAssetList, {asset = asset, effect = (v.dropEffectID or 0)})
                        end
                    end
                end

                local dropItem = {Drops = dropAssetList, Pos = monsterEntity:GridLocation():Center()}
                dropCmpt:SetDropAsset(dropItem)
                table.insert(drops, dropItem)
            end
        end
    end
    return drops
end

--region 怪物掉落技
---@param e Entity
function MonsterShowLogicService:CalcDropSkill(e)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local skillId = utilDataSvc:GetDropSkill(e)
    if skillId and skillId > 0 then
        skillLogicService:CalcSkillEffect(e, skillId)
        skillLogicService:UpdateRenderSkillRoutine(e)
    end
end

--endregion

local sort_world
local function Sort__CalcDeadMonsterOrder(entityID1, entityID2)
    local playerPos = sort_world:Player():GetLocalTeamEntity():GridLocation().Position
    local pos1 = sort_world:GetEntityByID(entityID1):GridLocation().Position
    local pos2 = sort_world:GetEntityByID(entityID2):GridLocation().Position
    local dis1 = Vector2.Distance(playerPos, pos1)
    local dis2 = Vector2.Distance(playerPos, pos2)
    return dis1 < dis2
end

---对本轮死亡的怪物进行排序
---@return array 排序后的数组
function MonsterShowLogicService:_CalcDeadMonsterOrder()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    local deadMonsterArray = {}
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if e:HasMonsterID() then
            deadMonsterArray[#deadMonsterArray + 1] = e:GetID()
        end
    end
    if self._world:Player():GetLocalTeamEntity() then
        sort_world = self._world
        table.sort(
            deadMonsterArray,Sort__CalcDeadMonsterOrder
        )
        sort_world= nil
    end

    return deadMonsterArray
end

---添加逻辑死亡标记
---@param entity Entity
function MonsterShowLogicService:AddMonsterDeadMark(entity, ignoreBattleStat)
    if not entity:HasMonsterID() then
        return
    end

    ---血量大于0，说明还没死
    local cAttributes = entity:Attributes()
    local curHp = cAttributes:GetCurrentHP()
    if curHp > 0 then
        return
    end

    ---如果已经挂上过逻辑死亡标记，不用再挂了
    if entity:HasDeadMark() then
        return
    end
    ---@type MainWorld
    local world = entity:GetOwnerWorld()
    ---@type BattleStatComponent
    local battleStatCmpt = world:BattleStat()
    --[[
    午蔚刚 4-8 16:31:26
        之前增加的三星条件：N回合内击杀指定怪物，现在使用在战棋关的时候发现一个问题：
        战棋关胜利条件是击杀赛车，想配置一个三星条件是中途击杀过麻子狗，但是我们击破赛车胜利的时候会杀死场上所有怪物，也就是说击杀麻子狗这个三星条件无论如何都会完成。。。
        这里有没有可能特殊处理一下，关卡胜利时杀的怪物不算作达成三星条件的击杀？
    ]]
    if not ignoreBattleStat then
        battleStatCmpt:AddDeadMonsterID(entity:MonsterID():GetMonsterID())
        battleStatCmpt:AddDeadMonsterBuffInfo(entity)
    end

    entity:AddDeadMark()
    return entity:DeadMark()
end

---是否所有怪都挂上了死亡组件
function MonsterShowLogicService:IsAllMonsterHasDeadMark()
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local team = self._world:Player():GetRemoteTeamEntity()
        return team:HasTeamDeadMark()
    end

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local isDead = e:HasDeadMark()
        if not isDead then
            return false
        end
    end

    return true
end

---实际清理死亡怪物的Entity
function MonsterShowLogicService:ClearMonsterDeadEntity()
    ---取出所有带了DeadFlag标签的怪物
    local toDestroyIDList = {}
    local monsterDeadGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    for _, e in ipairs(monsterDeadGroup:GetEntities()) do
        toDestroyIDList[#toDestroyIDList + 1] = e:GetID()
    end

    --清除buff
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    for _, entityID in ipairs(toDestroyIDList) do
        ---@type Entity
        local deadEntity = self._world:GetEntityByID(entityID)
        buffLogicService:RemoveAllBuffInstance(deadEntity)

        self._world:DestroyEntity(deadEntity)
    end
end

--变身逻辑，变身会替换五种属性：monsterID、攻、防、闪避、Element、AI
---@param result SkillTransformationEffectResult
---@param skillEffectParam SkillTransformationParam
---@return Entity
function MonsterShowLogicService:Transformation(result, skillEffectParam)
    if result:GetCaster() then
        ---@type Entity
        local caster = self._world:GetEntityByID(result:GetCaster())
        local elementType = 0
        local targetID = result:GetMonsterID()
        --怪物才能变身
        if not caster:HasMonsterID() then
            Log.fatal("[Skill] 严重错误，只有怪物才能变身")
            return
        end

        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        --ID
        local raceType = monsterConfigData:GetMonsterRaceType(targetID)
        local monsterType = monsterConfigData:GetMonsterType(targetID)
        local monsterGroupID = monsterConfigData:GetMonsterGroupID(targetID)
        local monsterClassID = monsterConfigData:GetMonsterClassID(targetID)
        local monsterCampType = monsterConfigData:GetMonsterCampType(targetID)
        caster:ReplaceMonsterID(targetID, raceType, monsterType, monsterGroupID, monsterClassID,monsterCampType)

        local attributeCmpt = caster:Attributes()

        --目标怪物的攻防闪
        local attack = monsterConfigData:GetMonsterAttack(targetID)
        local defense = monsterConfigData:GetMonsterDefense(targetID)
        local evade = monsterConfigData:GetMonsterEvade(targetID)

        --变身一般不改变生命上限，取当前施法者的
        local maxHP = attributeCmpt:CalcMaxHp()
        --结果生效的血量上限
        local resultMaxHP = maxHP

        --继承使用施法者属性，而不是目标怪物的属性
        local inherAttribute = skillEffectParam:GetInheritAttribute()
        if table.count(inherAttribute) > 0 then
            --
            if inherAttribute.Attack then
                local originalAttack = attributeCmpt:GetAttribute("Attack")
                attack = math.floor(originalAttack * inherAttribute.Attack)
            end
            if inherAttribute.Defense then
                local originalDefense = attributeCmpt:GetAttribute("Defense")
                defense = math.floor(originalDefense * inherAttribute.Defense)
            end
            if inherAttribute.MaxHP then
                resultMaxHP = math.floor(maxHP * inherAttribute.MaxHP)
            end
        end

        --当前血量
        local useHpPercent = result:GetUseHpPercent()
        if useHpPercent ~= 0 then
            --变身后的血量为：（当前血量百分数 + n%）*（变身目标血量最大值）
            local hp = attributeCmpt:GetCurrentHP()
            local curHpPercent = hp / maxHP
            -- 这里以前的目标血量使用的是目标怪物在class里的值，后来改成了施法者变身后的血量上限
            -- local targetHp = monsterConfigData:GetMonsterHealth(targetID)
            local TransformationHp = math.floor((curHpPercent + (useHpPercent / 100)) * resultMaxHP)
            if TransformationHp > resultMaxHP then
                TransformationHp = resultMaxHP
            end
            attributeCmpt:Modify("HP", TransformationHp)

            result:SetTransformationHp(TransformationHp)
            result:SetTransformationHpMax(resultMaxHP)

            --记录日志
            self._world:GetSyncLogger():Trace(
                {
                    key = "Transformation",
                    casterID = caster:GetID(),
                    beforeHp = hp,
                    beforeMaxHp = maxHP,
                    targetHp = resultMaxHP,
                    useHpPercent = useHpPercent,
                    transformationHp = TransformationHp
                }
            )
            self:LogNotice(
                "Transformation() caster=",
                caster:GetID(),
                " beforeHp=",
                hp,
                " beforeMaxHp=",
                maxHP,
                " targetHp=",
                resultMaxHP,
                " useHpPercent=",
                useHpPercent,
                " transformationHp=",
                TransformationHp
            )
        end

        --攻
        attributeCmpt:Modify("Attack", attack)
        --防
        attributeCmpt:Modify("Defense", defense)
        --闪避
        attributeCmpt:Modify("Evade", evade)

        --生命上限一般不会变，如果生效要在计算完当前血量百分比之后
        attributeCmpt:Modify("MaxHP", resultMaxHP)

        --属性
        elementType = monsterConfigData:GetMonsterElementType(targetID)
        --是否继承属性（QA：MSG45652）
        local nheritElement = skillEffectParam:GetInheritElement()
        if nheritElement then
            ---@type Entity
            local oriEntity = caster
            if caster:HasSuperEntity() then
                oriEntity = caster:GetSuperEntity()
            end
            if oriEntity:HasAttributes() then
                ---@type AttributesComponent
                local attrCmpt = oriEntity:Attributes()
                elementType = attrCmpt:GetAttribute("Element")
            end
        end
        caster:ReplaceElement(elementType, nil)
        attributeCmpt:SetSimpleAttribute("Element", elementType)
        result:SetElementType(elementType)
        local casterPos = caster:GetGridPosition()
        local oriCasterPos = casterPos
        local newPosIndexInOriBodyArea =  skillEffectParam:GetSetTargetPosByOriBodyAreaIndex()
        if newPosIndexInOriBodyArea ~= 0 then
            local oriBodyArea = caster:BodyArea():GetArea()
            if newPosIndexInOriBodyArea <= #oriBodyArea then
                local off = oriBodyArea[newPosIndexInOriBodyArea]
                casterPos = casterPos + off
                result:SetNewPos(casterPos)
            end
        end
        if skillEffectParam:IsUseTargetBodyArea() then
            ---@type BoardServiceLogic
            local sBoard = self._world:GetService("BoardLogic")
            local bodyArea, blockFlag =sBoard:RemoveEntityBlockFlag(caster, oriCasterPos)
            local areaArray = monsterConfigData:GetMonsterArea(targetID)
            caster:ReplaceBodyArea(areaArray) --重置格子占位
            sBoard:SetEntityBlockFlag(caster,casterPos,blockFlag)
        end
        caster:SetGridPosition(casterPos)
    --AI
    -- local aiList = monsterConfigData:GetMonsterAIID(targetID)
    -- caster:ReplaceAI(AILogicPeriodType.Main, aiList[1])
    end
end

---改变元素属性
---@param result SkillEffectResultChangeElement
function MonsterShowLogicService:ChangeElement(result)
    if result:GetTarget() then
        ---@type Entity
        local target = self._world:GetEntityByID(result:GetTarget())
        local attributeCmpt = target:Attributes()

        local elementType = result:GetElementType()
        target:ReplaceElement(elementType, nil)
        attributeCmpt:SetSimpleAttribute("Element", elementType)
    end
end

---@param monsterEntity Entity
---消亡，不发送buff，不执行通用死亡技能
function MonsterShowLogicService:DoLogicFeatureDead(monsterEntity)
    if not monsterEntity:HasDeadMark() then
        Log.exception("monster entity has not dead,", Log.traceback())
        return
    end

    ---@type DeadMarkComponent
    local deadMarkCmpt = monsterEntity:DeadMark()
    if deadMarkCmpt:HasDoLogicDead() then
        return
    end

    ---@type MonsterIDComponent
    local monsterIDCmpt = monsterEntity:MonsterID()
    if not monsterIDCmpt then
        return
    end

    deadMarkCmpt:SetDoLogicDead(true)

    -- --死亡技能
    -- self:_CalcMonsterDeathSkill(monsterEntity)

    --清除阻挡
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    sBoard:RemoveEntityBlockFlag(monsterEntity, monsterEntity:GetGridPosition())

    --设置逻辑坐标
    monsterEntity:SetGridPosition(Vector2(BattleConst.CacheHeight, BattleConst.CacheHeight))
end
