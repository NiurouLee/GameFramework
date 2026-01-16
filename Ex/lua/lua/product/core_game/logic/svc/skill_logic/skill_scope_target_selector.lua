--[[------------------------------------------------------------------------------------------
    SkillScopeTargetSelector :技能目标选择器
    使用格子范围、阵营信息计算出目标列表，这种目标可能是星灵、怪、机关等实体
    星灵主动技、怪物技能等都使用这个目标选择器
]] --------------------------------------------------------------------------------------------

---@class TargetSelectFilterAttackType
local TargetSelectFilterAttackType = {
    NormalAttack = 1, ---普攻
    SingleSkillAttack = 2, ---打单体技能攻击
    GridSkillAttack = 3 ---打格子技能攻击
}
_enum("TargetSelectFilterAttackType", TargetSelectFilterAttackType)

_class("SkillScopeTargetData", Object)
---@class SkillScopeTargetData: Object
SkillScopeTargetData = SkillScopeTargetData

---@param world MainWorld
function SkillScopeTargetData:Constructor(pos, entity)
    self.m_pos = pos
    ---@type Entity
    self.m_entity = entity
    self.m_nID = entity:GetID()
end

--------------------------------

_class("SkillScopeTargetSelector", Object)
---@class SkillScopeTargetSelector: Object
---@field New fun(MainWorld):SkillScopeTargetSelector
SkillScopeTargetSelector = SkillScopeTargetSelector

---@param world MainWorld
function SkillScopeTargetSelector:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---对目标选择的函数集
    ---所有函数都返回一个EntityID的数组，注意是有序的
    self._selectFuncDic = {}
    self._selectFuncDic[SkillTargetType.Self] = self._SelectSelf
    self._selectFuncDic[SkillTargetType.Pet] = self._SelectPet
    self._selectFuncDic[SkillTargetType.Monster] = self._SelectMonster
    self._selectFuncDic[SkillTargetType.AllMover] = self._SelectAllMover
    self._selectFuncDic[SkillTargetType.Board] = self._SelectBoard
    self._selectFuncDic[SkillTargetType.NearestMonster] = self._SelectNearestMonster
    self._selectFuncDic[SkillTargetType.PetAndTrap] = self._SelectPetAndTrap
    self._selectFuncDic[SkillTargetType.Team] = self._SelecTeam
    self._selectFuncDic[SkillTargetType.PetTeam] = self._SelectPetTeam
    self._selectFuncDic[SkillTargetType.MonsterTrap] = self._SelectMonsterTrap
    self._selectFuncDic[SkillTargetType.AllMoverExcept] = self._SelectAllMoverExceptBuff
    self._selectFuncDic[SkillTargetType.PetMonsterTrap] = self._SelectPetMonsterTrap
    self._selectFuncDic[SkillTargetType.NearestPetMonsterTrap] = self._SelectNearestPetMonsterTrap
    self._selectFuncDic[SkillTargetType.OneOfProtectTrapAndPet] = self._SelectOneOfProtectTrapAndPet
    self._selectFuncDic[SkillTargetType.PetMonsterTrapExceptSelfFlyMultiBodyArea] = self._SelectPetMonsterTrapGridExceptConveyorFlyMultiBodyArea
    self._selectFuncDic[SkillTargetType.OwnedPhantom] = self._SelectOwnedPhantom
    self._selectFuncDic[SkillTargetType.NearestMonsterTrap] = self._SelectNearestMonsterTrap
    self._selectFuncDic[SkillTargetType.TrapWithHP] = self._SelectTrapWithHP
    self._selectFuncDic[SkillTargetType.SpecificMonster] = self._SelectSpecificMonster
    self._selectFuncDic[SkillTargetType.MonsterGroup] = self._SelectMonsterGroup
    self._selectFuncDic[SkillTargetType.PetAndTrapBomb] = self._SelectPetAndTrapBomb
    self._selectFuncDic[SkillTargetType.HighestHPPercentMonster] = self._SelectHighestHPPercentMonster
    self._selectFuncDic[SkillTargetType.SpecificPet] = self._SelectSpecificPet
    self._selectFuncDic[SkillTargetType.SpecificPrimaryElementPet] = self._SelectSpecificPrimaryElementPet
    self._selectFuncDic[SkillTargetType.HighestHPMonster] = self._SelectHighestHPMonster
    self._selectFuncDic[SkillTargetType.LowestHPPercentMonster] = self._SelectLowestHPPercentMonster
    self._selectFuncDic[SkillTargetType.LowestHPPercentMonsterParam] = self._SelectLowestHPPercentMonsterParam
    self._selectFuncDic[SkillTargetType.RandomNMonster] = self._SelectRandomNMonster
    self._selectFuncDic[SkillTargetType.Captain] = self._SelecCaptain
    self._selectFuncDic[SkillTargetType.FarestMonster] = self._SelectFarestMonster
    self._selectFuncDic[SkillTargetType.Trap] = self._SelectTrap
    self._selectFuncDic[SkillTargetType.DeadMonsterWithBuff] = self._SelectDeadMonsterWithBuff
    self._selectFuncDic[SkillTargetType.MonsterHaveBuffANoBuffB] = self._SelectMonsterHaveBuffANoBuffB
    self._selectFuncDic[SkillTargetType.NearestMonsterNoID] = self._SelectNearestMonsterNoID
    self._selectFuncDic[SkillTargetType.NearestMonstersIsScope] = self._SelectNearestMonstersIsScope
    self._selectFuncDic[SkillTargetType.SpecificTrap] = self._SelectSpecificTrap
    self._selectFuncDic[SkillTargetType.SpecificTrapAndFarthestHitBackPlayer] = self._SelectSpecificTrapAndFarthestHitBackPlayer
    self._selectFuncDic[SkillTargetType.MonsterTrapDeadOrAlive] = self._SelectMonsterTrapDeadOrAlive
    self._selectFuncDic[SkillTargetType.AlignmentTargetEnemyTeam] = self._SelectAlignmentTargetEnemyTeam
    self._selectFuncDic[SkillTargetType.AlignmentTargetFriendTeam] = self._SelectAlignmentTargetFriendTeam
    self._selectFuncDic[SkillTargetType.AlignmentTargetFriendPet] = self._SelectAlignmentTargetFriendPet
    self._selectFuncDic[SkillTargetType.AlignmentTargetEnemyPet] = self._SelectAlignmentTargetEnemyPet
    self._selectFuncDic[SkillTargetType.AlignmentTargetEnemyTeamHaveBuffANoBuffB] = self._SelectAlignmentTargetEnemyTeamHaveBuffANoBuffB
    self._selectFuncDic[SkillTargetType.GridCanPurifyTrap] = self._SelectGridCanPurifyTrap
    self._selectFuncDic[SkillTargetType.AntiAITriggerEntity] = self._SelectAntiAITriggerEntity
    self._selectFuncDic[SkillTargetType.MaxDamageDealerPetToCaster] = self._SelectMaxDamageDealerPetToCaster
    self._selectFuncDic[SkillTargetType.MonsterTrapAndTrapSuperEntityIsCaster] = self._SelectMonsterTrapAndTrapSuperEntityIsCaster
    self._selectFuncDic[SkillTargetType.MonsterOrEnemyPets] = self._SelectMonsterOrEnemyPets
    self._selectFuncDic[SkillTargetType.NearestMonsterOneByOne] = self._SelectNearestMonsterOneByOne
    self._selectFuncDic[SkillTargetType.LastActiveSkillCasterPet] = self._SelectLastActiveSkillCasterPet
    self._selectFuncDic[SkillTargetType.EntityWithBuff] = self._SelectEntityWithBuff
    self._selectFuncDic[SkillTargetType.MonsterOnSpecificTrap] = self._SelectMonsterOnSpecificTrap
    self._selectFuncDic[SkillTargetType.CaptainInRange] = self._SelectCaptainInRange
    self._selectFuncDic[SkillTargetType.N15ChessMonsterMoveTarget] = self._SelectN15ChessMonsterMoveTarget
    self._selectFuncDic[SkillTargetType.N15ChessMonsterAttackTargets] = self._SelectN15ChessMonsterAttackTargets
    self._selectFuncDic[SkillTargetType.NearestChessPet] = self._SelectNearestChessPet
    self._selectFuncDic[SkillTargetType.ChessPet] = self._SelectChessPet
    self._selectFuncDic[SkillTargetType.MonsterAndChessPet] = self._SelectMonsterAndChessPet
    self._selectFuncDic[SkillTargetType.LessHPChessPet] = self._SelectLessHPChess
    self._selectFuncDic[SkillTargetType.MonsterOrTeam] = self._SelectMonsterOrTeam
    self._selectFuncDic[SkillTargetType.EntityWithBuffOrNearestMonster] = self._SelectEntityWithBuffOrNearestMonster
    self._selectFuncDic[SkillTargetType.TrapSummonEntityIsCaster] = self._SelectTrapSummonEntityIsCaster
    self._selectFuncDic[SkillTargetType.NearestAndFarestMonsterInScope] = self._SelectNearestAndFarestMonsterInScope
    self._selectFuncDic[SkillTargetType.TrapPosByID] = self._SelectTrapPosByID
    self._selectFuncDic[SkillTargetType.NearestMonsterSortByBodyArea] = self._SelectNearestMonsterSortByBodyArea
    self._selectFuncDic[SkillTargetType.CasterSummoner] = self._SelectCasterSummoner
    self._selectFuncDic[SkillTargetType.MostVisibleBuffMonster] = self._SelectMostVisibleBuffMonster
    self._selectFuncDic[SkillTargetType.NearestPetMonsterTrapAndFilter] = self._SelectNearestPetMonsterTrapAndFilter
    self._selectFuncDic[SkillTargetType.MySpecificTrapOrAnyMonster] = self._SelectMySpecificTrapOrAnyMonster
    self._selectFuncDic[SkillTargetType.SelfInAttackRange] = self._SelectSelfInAttackRange
    self._selectFuncDic[SkillTargetType.MonsterNotBoss] = self._SelectMonsterNotBoss
    self._selectFuncDic[SkillTargetType.LastChainSkillRandomNMonster] = self._SelectLastChainSkillRandomNMonster
    self._selectFuncDic[SkillTargetType.BuffLayerMostAndHighestHP] = self._SelectBuffLayerMostAndHighestHP
    self._selectFuncDic[SkillTargetType.MonsterAroundDamageTarget] = self._SelectMonsterAroundDamageTarget
    self._selectFuncDic[SkillTargetType.WorldBossMonster] = self._SelectWorldBossMonster
    self._selectFuncDic[SkillTargetType.SingleGridMonsterLowestHPPercent] = self._SelectSingleGridMonsterLowestHPPercent
    self._selectFuncDic[SkillTargetType.SelectMonsterCamp] = self._SelectMonsterCamp
end

---选择技能可作用的目标，这个目标是个实体对象
---同一个目标可能会被作用多次
---每个技能只有一个范围，所以对应只有一个SkillScopeResultconf
---@param casterEntity Entity 施法者
---@param targetType SkillTargetType 技能目标类型
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
---@return number[] 返回的是一个entityID列表
function SkillScopeTargetSelector:DoSelectSkillTarget(
    casterEntity,
    targetType,
    skillScopeResult,
    skillID,
    targetTypeParam)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    --黑拳赛模式替换目标类型
    targetType = world:ReplaceSkillTarget(targetType)

    local selectFunc = self._selectFuncDic[targetType]
    if selectFunc ~= nil then
        --local t1 = os.clock()
        ---只有计算技能的目标时传SkillID,计算技能效果的子范围不要穿SkillID
        if skillID then
            ---@type ConfigService
            local configService = world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
            -- TODO 阿克希亚扫描模块处理
            local skillTargetTypeParam = skillConfigData:GetSkillTargetTypeParam()
            if not targetTypeParam then
                targetTypeParam = skillTargetTypeParam
            end
        end

        local targetEntityIDArray = selectFunc(self, casterEntity, skillScopeResult, skillID, targetTypeParam)
        --local usetime = (os.clock() - t1) * 1000
        --Log.prof("[AutoFight] DoSelectSkillTarget() usetime=", usetime)

        -- ---特殊处理！！！！骑乘！！！
        -- local needCollectEntityIDs = {}
        -- for _, value in ipairs(targetEntityIDArray) do
        --     ---@type Entity
        --     local entity = world:GetEntityByID(value)
        --     if entity:HasRide() then
        --         ---@type RideComponent
        --         local rideCmpt = entity:Ride()
        --         local rideID = rideCmpt:GetRiderID()
        --         local mountID = rideCmpt:GetMountID()
        --         if not table.icontains(targetEntityIDArray, rideID) then
        --             table.insert(needCollectEntityIDs, rideID)
        --         end
        --         if not table.icontains(targetEntityIDArray, mountID) then
        --             ---@type Entity
        --             local entity = world:GetEntityByID(mountID)
        --             if entity:HasMonsterID() then
        --                 table.insert(needCollectEntityIDs, mountID)
        --             end
        --         end
        --     end
        -- end

        -- if #needCollectEntityIDs > 0 then
        --     table.appendArray(targetEntityIDArray, needCollectEntityIDs)
        -- end
        return targetEntityIDArray
    else
        Log.fatal("SkillScopeTargetSelector no skill target selector:", targetType)
    end
    return {}
end

--可以选择为目标的条件
---@param targetEntity Entity 被选择的目标
function SkillScopeTargetSelector:SelectConditionFilter(targetEntity, isNormalAttack)
    local canBeSelected = true

    --在其他棋盘面
    if targetEntity:HasOutsideRegion() then
        return false
    end

    --离场状态
    if targetEntity:HasOffBoardMonster() then
        return false
    end

    ---@type BuffComponent
    local buffComponent = targetEntity:BuffComponent()
    if buffComponent then
        canBeSelected = not buffComponent:HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget)
    end

    if isNormalAttack then
        --骑乘特殊处理：若是骑乘者，则不能被普通攻击
        if targetEntity:HasRide() then
            ---@type RideComponent
            local rideCmpt = targetEntity:Ride()
            canBeSelected = rideCmpt:GetRiderID() ~= targetEntity:GetID()
        end
    end

    return canBeSelected
end

--选择队伍
function SkillScopeTargetSelector:_SelecTeam(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamEntityID = teamEntity:GetID()
    local targetIDArray = {}
    targetIDArray[#targetIDArray + 1] = teamEntityID
    return targetIDArray
end

--选择队长
function SkillScopeTargetSelector:_SelecCaptain(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if casterEntity:HasPet() then
        teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    end
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    local targetIDArray = {}
    targetIDArray[#targetIDArray + 1] = teamLeaderEntityID
    return targetIDArray
end

---将施法者自己选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectSelf(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local casterEntityID = casterEntity:GetID()
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        local superEntity = casterEntity:SuperEntityComponent():GetSuperEntity()
        casterEntityID = superEntity:GetID()
    end
    local targetIDArray = {}
    targetIDArray[#targetIDArray + 1] = casterEntityID

    return targetIDArray
end

---将攻击范围内的施法者自己选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectSelfInAttackRange(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local casterEntityID = casterEntity:GetID()
    local casterPos = casterEntity:GetGridPosition()

    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    for _, pos in ipairs(attackRange) do
        if pos == casterPos then            
            targetIDArray[#targetIDArray + 1] = casterEntityID
        end
    end

    return targetIDArray
end

---优先判断是否有守护机关  如果有打机关  打机关的同时 如果技能覆盖了队长 就顺带上队长
---没有守护机关 直接打队长
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    if casterEntity then
        if casterEntity:HasTrap() then
            local isDimensionDoor = casterEntity:Trap():IsDimensionDoor()
            if isDimensionDoor then
                --传送门和守护机关同时在场 传送门失效 MSG59292
                return self:_SelectPetOnly(casterEntity, skillScopeResult, skillID, targetTypeParam)
            end
        end
    end
    if utilSvc:GetProtectedTrap() and utilSvc:EntityAITargetTypeIsNormal(casterEntity) then
        --如果有守护机关
        return self:_SelectTrapAndAoeSelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    else
        --没有守护机关 直接打队长（此处原有旧方法）
        return self:_SelectPetOnly(casterEntity, skillScopeResult, skillID, targetTypeParam)
    end
end

---首要目标是选择机关  如果机关在范围内 在根据技能类型 技能方向 将队长选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectTrapAndAoeSelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}

    local listTrapMap = self:_SelectTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)

    -- local trapTargetID = nil
    local trapTargetEntity = nil
    for trapId, trapEntity in pairs(listTrapMap) do
        ---@type TrapComponent
        local trapCmpt = trapEntity:Trap()
        if trapCmpt:GetTrapType() == TrapType.Protected then
            trapTargetEntity = trapEntity
        end
    end

    --有守护机关做攻击目标 再判断技能覆盖队长
    if trapTargetEntity then
        table.insert(targetIDArray, trapTargetEntity:GetID())

        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
        local skillType = SkillType.SKillTypeEnd
        if skillConfigData then
            skillType = skillConfigData:GetSkillType()
        end

        local petIDArray = {}
        if skillType == SkillType.Normal then
            --是普通攻击  判断技能 方向 必须 v2(x,y) 2个参数的符号一样 在同一象限内  才可以选择
            local dir = self:_GetSkillDir(casterEntity, trapTargetEntity, skillScopeResult)
            petIDArray = self:_SelectPetOnlyWithDir(casterEntity, skillScopeResult, skillID, dir)
        else
            --是技能  不需要判断方向
            petIDArray = self:_SelectPetOnly(casterEntity, skillScopeResult, skillID, targetTypeParam)
        end

        for _, petId in ipairs(petIDArray) do
            table.insert(targetIDArray, petId)
        end
    else
        --有守护机关在场  如果技能不能打到机关  就算可以打到队长  也不能打
    end

    return targetIDArray
end

--计算 攻击目标在自己的 那个象限方向
function SkillScopeTargetSelector:_GetSkillDir(casterEntity, trapTargetEntity, skillScopeResult)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local listTarget = {}
    local attackRange = skillScopeResult:GetAttackRange()

    local curDir

    for _, skillRangePos in ipairs(attackRange) do
        local listTrap = utilSvc:GetTrapsAtPos(skillRangePos)
        for i = 1, #listTrap do
            local targetEntityID = listTrap[i]:GetID()
            if targetEntityID then
                local selectTrapFilter = self:_SelectTrapFilter(casterEntity, targetEntityID, true)
                if selectTrapFilter then
                    for j, bodyArea in ipairs(casterEntity:BodyArea():GetArea()) do
                        local curMonsterBodyPos = casterEntity:GridLocation().Position + bodyArea

                        local dir = GameHelper.ComputeLogicDir(skillRangePos - curMonsterBodyPos)

                        if dir.x == 0 or dir.y == 0 then
                            curDir = dir
                            break
                        end
                    end
                end
            end
            if curDir then
                break
            end
        end
        if curDir then
            break
        end
    end

    return curDir
end

---将队长选入目标列表  根据方向
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectPetOnlyWithDir(casterEntity, skillScopeResult, skillID, dir)
    local targetIDArray = {}
    --如果目标是星灵，单人模式下可直接判断本地玩家是否在技能范围内
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GridLocation().Position
    local attackRange = skillScopeResult:GetAttackRange()
    for i = 1, #attackRange do
        if playerPos == attackRange[i] then
            local curDir

            for j, bodyArea in ipairs(casterEntity:BodyArea():GetArea()) do
                local curMonsterBodyPos = casterEntity:GridLocation().Position + bodyArea

                local dir = GameHelper.ComputeLogicDir(playerPos - curMonsterBodyPos)

                if dir.x == 0 or dir.y == 0 then
                    curDir = dir
                    break
                end
            end

            if curDir == dir then
                targetIDArray[#targetIDArray + 1] = teamEntity:GetID()
            end

            break
        end
    end
    return targetIDArray
end

---将队长选入目标列表
---也许还会有比如选出所有的水系星灵之类的
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectPetOnly(casterEntity, skillScopeResult, skillID)
    local targetIDArray = {}
    --如果目标是星灵，单人模式下可直接判断本地玩家是否在技能范围内
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GridLocation().Position
    local attackRange = skillScopeResult:GetAttackRange()
    for i = 1, #attackRange do
        if playerPos == attackRange[i] then
            targetIDArray[#targetIDArray + 1] = teamEntity:GetID()
            break
        end
    end
    return targetIDArray
end

--守护机关和宝宝之一，如果有守护机关就不选宝宝，否则就选宝宝
function SkillScopeTargetSelector:_SelectOneOfProtectTrapAndPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local protectTrapEntity = utilSvc:GetProtectedTrap()
    if protectTrapEntity and utilSvc:EntityAITargetTypeIsNormal(casterEntity) then
        --如果有守护机关
        return { protectTrapEntity:GetID() }
    else --没有守护机关 直接打队长
        return self:_SelectPetOnly(casterEntity, skillScopeResult, skillID, targetTypeParam)
    end
end

---选择怪物
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    for _, skillRangePos in ipairs(attackRange) do
        local targetIDInSkillRangeList = self:_CalcMonsterInSkillRange(skillRangePos)
        for _, v in ipairs(targetIDInSkillRangeList) do
            if v > 0 then
                targetIDArray[#targetIDArray + 1] = v
            end
        end
    end

    if targetTypeParam and type(targetTypeParam) == "table" and table.count(targetTypeParam) > 0 then
        local targetCount = targetTypeParam[1] or 1
        --给懒的改配置的策划做容错，不写默认值是0，Ai默认值是0。如果是0默认找所有，就是999
        if targetCount == 0 then
            targetCount = 999
        end
        local newTargetIDArray = {}
        for i = 1, table.count(targetIDArray) do
            if i <= targetCount then
                table.insert(newTargetIDArray, targetIDArray[i])
            end
        end
        targetIDArray = newTargetIDArray
    end

    return targetIDArray
end

---选所有攻击范围内的怪物和玩家
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectAllMover(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID)
    for _, v in ipairs(pets) do
        table.insert(targetIDArray, v)
    end
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    for _, v in ipairs(monsters) do
        table.insert(targetIDArray, v)
    end
    return targetIDArray
end

---选最近的一只怪
---以后需要在格子范围的基础上，再选最近的怪
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectNearestMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local casterPos = casterEntity:GridLocation().Position
    local allMonsters = {}
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local selectTargetData = utilScopeSvc:SortMonstersByPos(casterPos)
    for _, element in ipairs(selectTargetData) do
        ---@type Entity
        local monsterEntity = element.monster_e
        allMonsters[#allMonsters + 1] = monsterEntity:GetID()
    end

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    local isFind = false
    if selectedMonsterIds then
        for i = 1, #allMonsters do
            local monsterId = allMonsters[i]
            for _, v in ipairs(selectedMonsterIds) do
                if v == monsterId then
                    targetIDArray[#targetIDArray + 1] = monsterId
                    isFind = true
                    break
                end
            end
            if isFind then
                break
            end
        end
    end

    return targetIDArray
end

---选最远的一只怪
---以后需要在格子范围的基础上，再选最近的怪
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectFarestMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local casterPos = casterEntity:GridLocation().Position
    local allMonsters = {}
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local selectTargetData = utilScopeSvc:SortMonstersByPos(casterPos)
    local selectHpZero = 1 --是否可以选择血量是0的目标，默认1选择
    --因为子技能范围的配置默认值是0，所以只有table的时候才重新取值
    if targetTypeParam and type(targetTypeParam) == "table" then
        selectHpZero = targetTypeParam[1] or 1
    end
    for _, element in ipairs(selectTargetData) do
        ---@type Entity
        local monsterEntity = element.monster_e
        allMonsters[#allMonsters + 1] = monsterEntity:GetID()
    end
    local allMonstersFar = {}
    for i = #allMonsters, 1, -1 do
        allMonstersFar[#allMonstersFar + 1] = allMonsters[i]
    end

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    local isFind = false
    if selectedMonsterIds then
        for i = 1, #allMonstersFar do
            local monsterId = allMonstersFar[i]
            for _, v in ipairs(selectedMonsterIds) do
                if v == monsterId then
                    local e = self._world:GetEntityByID(v)
                    local percent = self:_GetHPPercent(e)
                    local hpIsSatisfied = true
                    --一些特殊的技能，会选择血量不是0的，血量百分比最低的目标
                    if selectHpZero == 0 and percent == 0 then
                        hpIsSatisfied = false
                    end

                    if hpIsSatisfied then
                        targetIDArray[#targetIDArray + 1] = monsterId
                        isFind = true
                        break
                    end
                end
            end
            if isFind then
                break
            end
        end
    end

    return targetIDArray
end

---根据指定的一个坐标位置，判断该位置上是否有怪物
---@param skillRangePos Vector2 这个参数也有可能是个vector2的数组，需要处理下
---默认情况下，这个参数是个Vector2，如果没有_className，说明就是个数组了
function SkillScopeTargetSelector:_CalcMonsterInSkillRange(skillRangePos, withDead)
    local targetIDList = {}
    if skillRangePos._className == nil then
        ---说明是个数组，这样是种临时处理，因为单翼天使的选目标是这种形式
        ---后续这种嵌套不应该有
        for _, v in ipairs(skillRangePos) do
            local checkPos = v
            -- local targetEntityID = self:_FindTargetEntityInPos(checkPos, withDead)
            -- if targetEntityID > 0 then
            --     targetIDList[#targetIDList + 1] = targetEntityID
            -- end
            local targetEntityIDs = self:_FindTargetEntityInPos(checkPos, withDead)
            if #targetEntityIDs > 0 then
                table.appendArray(targetIDList, targetEntityIDs)
            end
        end
    else
        ---说明是个vector2
        -- local targetEntityID = self:_FindTargetEntityInPos(skillRangePos, withDead)
        -- if targetEntityID > 0 then
        --     targetIDList[#targetIDList + 1] = targetEntityID
        -- end
        local targetEntityIDs = self:_FindTargetEntityInPos(skillRangePos, withDead)
        if #targetEntityIDs > 0 then
            table.appendArray(targetIDList, targetEntityIDs)
        end
    end

    return targetIDList
end

---@param pos Vector2
function SkillScopeTargetSelector:_FindTargetEntityInPos(checkPos, withDead)
    --local targetEntityID = -1
    local targetEntityID = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if (withDead or (not e:HasDeadMark())) and self:SelectConditionFilter(e) then
            local monsterEntityID = e:GetID()
            local monster_grid_location_cmpt = e:GridLocation()
            local monster_body_area_cmpt = e:BodyArea()
            local monster_body_area = monster_body_area_cmpt:GetArea()
            for i, bodyArea in ipairs(monster_body_area) do
                local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                if curMonsterBodyPos == checkPos then
                    --targetEntityID = monsterEntityID
                    if e:HasRide() and e:Ride():GetRiderID() == monsterEntityID then
                        table.insert(targetEntityID, 1, monsterEntityID)
                    else
                        table.insert(targetEntityID, monsterEntityID)
                    end
                    break
                end
            end

            --没有加进来的再判断一下
            if not table.intable(targetEntityID, monsterEntityID) then
                --bodyArea不包括坐标中点的也要加进来(n20魔方BOSS瘫痪后)
                if monster_grid_location_cmpt:GetGridPos() == checkPos then
                    table.insert(targetEntityID, monsterEntityID)
                end
            end
        end
    end
    --下面这种方式依赖阻挡信息，击退的时候触发机关时阻挡还没更新
    -- ---@type BoardServiceLogic
    -- local svc = self._world:GetService("BoardLogic")
    -- local es = svc:GetMonstersAtPos(checkPos)
    -- local e = es[1]
    -- if e and (withDead or (not e:HasDeadMark())) and self:SelectConditionFilter(e) then
    --     targetEntityID = e:GetID()
    -- end
    return targetEntityID
end

---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectBoard(casterEntity, skillScopeResult, skillID, targetTypeParam)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()

    local targetIDArray = {}
    targetIDArray[#targetIDArray + 1] = boardEntity:GetID()

    return targetIDArray
end

---将全部星灵选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectPetTeam(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    local targetIDArray = {}
    local pets = teamEntity:Team():GetTeamPetEntities()
    for _, e in ipairs(pets) do
        if not targetTypeParam then
            targetIDArray[#targetIDArray + 1] = e:GetID()
        else
            if self:_CheckPetElement(e, targetTypeParam) then
                targetIDArray[#targetIDArray + 1] = e:GetID()
            end
        end
    end

    return targetIDArray
end

function SkillScopeTargetSelector:_CheckPetElement(e, elements)
    if elements == 0 or table.count(elements) <= 0 then
        return true
    end
    if 1 == nCount and 0 == elements[1] then
        return true
    end
    ---@type ElementComponent
    local elementCmpt = e:Element()
    local primaryType = elementCmpt:GetPrimaryType()
    for _, pieceType in ipairs(elements) do
        if CanMatchPieceType(primaryType, pieceType) then
            return true
        end
    end
    return false
end

---@param pos Vector2
function SkillScopeTargetSelector:_FindTargetEntityInPosByFilter(checkPos, filter) --TODO和_FindTargetEntityInPos合并
    local targetEntityID = -1
    local g = self._world:GetGroup(filter)
    for _, e in ipairs(g:GetEntities()) do
        local entityID = e:GetID()
        local cGridLocation = e:GridLocation()
        local cBodyArea = e:BodyArea()
        local area = cBodyArea:GetArea()
        for i, bodyArea in ipairs(area) do
            local curMonsterBodyPos = cGridLocation.Position + bodyArea
            if curMonsterBodyPos == checkPos then
                targetEntityID = entityID
                break
            end
        end
    end
    return targetEntityID
end

function SkillScopeTargetSelector:_SelectTrap(casterEntity, skillScopeResult, skillID, targetTypeParam, isAttack)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local listTarget = {}
    local attackRange = skillScopeResult:GetAttackRange()
    ---2020-07-02 韩玉信 机关会重叠，所以某一个位置的机关会有多个
    for _, skillRangePos in ipairs(attackRange) do
        local listTrap = utilSvc:GetTrapsAtPos(skillRangePos)
        for i = 1, #listTrap do
            local targetEntityID = listTrap[i]:GetID()
            if targetEntityID then
                local selectTrapFilter = self:_SelectTrapFilter(casterEntity, targetEntityID, isAttack)
                if selectTrapFilter then
                    --机关可能是多个格子
                    listTarget[targetEntityID] = listTrap[i]
                end
            end
        end
    end
    return listTarget
end

---选择可以被攻击的机关： 带血或者可以被击退（比如炸弹）
function SkillScopeTargetSelector:_SelectTrapWithHP(casterEntity, skillScopeResult, skillID)
    local mapTrap = self:_SelectTrapByHit(casterEntity, skillScopeResult, skillID)
    local targetIDArray = {}
    for key, value in pairs(mapTrap) do
        table.insert(targetIDArray, key)
    end
    return targetIDArray
end

---选择可以被攻击的机关： 带血或者可以被击退（比如炸弹）
function SkillScopeTargetSelector:_SelectTrapByHit(casterEntity, skillScopeResult, skillID)
    local listTarget = {}
    local listTargetByRange =
    self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.Trap, skillScopeResult:GetAttackRange())
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        local entityTrap = value.m_entity
        local id = entityTrap:GetID()
        if id > 0 and self:_SelectTrapFilter(casterEntity, id, true) then
            listTarget[id] = entityTrap
        end
    end
    return listTarget
end

--选择机关作为目标的时候  做筛选
function SkillScopeTargetSelector:_SelectTrapFilter(casterEntity, trapEntityID, isAttack, isDeadOrAlive)
    if isAttack == nil then
        isAttack = true
    end
    ---@type Entity
    local trapEntity = self._world:GetEntityByID(trapEntityID)
    ---@type TrapComponent
    local trapCmpt = trapEntity:Trap()

    if (isDeadOrAlive) or trapEntity:HasDeadMark() then
        return false
    end

    if trapEntity:Trap():GetTrapType() == TrapType.BombByHitBack then
        return true
    end

    --机关表的CanBeAttack字段  and  本技能是攻击技能(在15的时候传false)
    if trapEntity:Attributes():GetAttribute("CanBeAttacked") == 0 and isAttack then
        return false
    end

    --攻击者是玩家 不可以选择被守护的机关
    if casterEntity:HasPetPstID() and trapCmpt:GetTrapType() == TrapType.Protected then
        return false
    end

    return true
end

---技能范围内的怪和机关
function SkillScopeTargetSelector:_SelectMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    for _, v in ipairs(monsters) do
        table.insert(targetIDArray, v)
    end
    local mapTrap = self:_SelectTrapByHit(casterEntity, skillScopeResult, skillID, targetTypeParam)
    for key, value in pairs(mapTrap) do
        if value:Trap():GetTrapType() ~= TrapType.Protected then
            table.insert(targetIDArray, key)
        end
    end
    return targetIDArray
end

---技能范围内的所有怪和宝宝，除去体挂有某类Buff的目标（对某类buff无效）
function SkillScopeTargetSelector:_SelectAllMoverExceptBuff(casterEntity, skillScopeResult, skillID, filterBuffEffect)
    local targetIDArray = {}
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID, filterBuffEffect)
    local validatePets = self:_FilterByBuffEffect(pets, filterBuffEffect)
    for _, v in ipairs(validatePets) do
        table.insert(targetIDArray, v)
    end

    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    local validateMonsters = self:_FilterByBuffEffect(monsters, filterBuffEffect)
    for _, v in ipairs(validateMonsters) do
        table.insert(targetIDArray, v)
    end
    return targetIDArray
end

function SkillScopeTargetSelector:_FilterByBuffEffect(movers, filterBuffEffect)
    local targetIDArray = {}
    for _, v in ipairs(movers) do
        local buffCpt = self._world:GetEntityByID(v):BuffComponent()
        local validate = true --默认技能生效，在挂有某种buff效果时不生效
        if buffCpt then
            for _, value in ipairs(filterBuffEffect) do
                if buffCpt:HasBuffEffect(value) then
                    validate = false
                    break
                end
            end
        end
        if validate then
            table.insert(targetIDArray, v)
        end
    end
    return targetIDArray
end

---技能范围内的怪和机关
function SkillScopeTargetSelector:_SelectPetMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local arr = {}
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if pets then
        for i, v in ipairs(pets) do
            table.insert(arr, v)
        end
    end
    local monsterTrap = self:_SelectMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if monsterTrap then
        for i, v in ipairs(monsterTrap) do
            table.insert(arr, v)
        end
    end
    return arr
end

---技能范围内的Pet和机关
function SkillScopeTargetSelector:_SelectPetAndTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local arr = {}
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    table.appendArray(arr, pets)

    local mapTrap = self:_SelectTrapByHit(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if mapTrap then
        for key, value in pairs(mapTrap) do
            table.insert(arr, key)
        end
    end
    return arr
end

---@param casterEntity Entity
function SkillScopeTargetSelector:_SelectNearestPetMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targets = self:_SelectPetMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local nearestIds, nearestMagnitude = {}, 999
    local center = casterEntity:GridLocation():Center()
    if targets then
        for i, id in ipairs(targets) do
            local e = self._world:GetEntityByID(id)
            local pos = e:GridLocation().Position
            local bodyArea = e:BodyArea():GetArea()
            for j, grid in ipairs(bodyArea) do
                local absPos = pos + grid
                local magnitude = Vector2.Magnitude(absPos - center)
                if nearestMagnitude > magnitude then
                    nearestMagnitude = magnitude
                    nearestIds = { id }
                elseif nearestMagnitude == magnitude then
                    table.insert(nearestIds, id)
                end
            end
        end
    end

    -- Log.error("SkillScopeTargetSelector:_SelectNearestPetMonsterTrap() return ids:")
    -- dump(nearestIds)
    return nearestIds
end

---@param casterEntity Entity
function SkillScopeTargetSelector:_SelectNearestPetMonsterTrapAndFilter(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local targets = self:_SelectPetMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local nearestIds, nearestMagnitude = {}, 999
    local center = casterEntity:GridLocation():Center()
    if table.count(targets) > 1 then
        ---@type Entity
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if table.intable(targets, teamEntity:GetID()) then
            ---@type LogicChainPathComponent
            local logicChainPathCmpt = teamEntity:LogicChainPath()
            --连线可以穿过怪物脚下
            local chainAcrossMonster = logicChainPathCmpt:GetChainAcrossMonster()
            if chainAcrossMonster then
                table.removev(targets, teamEntity:GetID())
            end
        end
    end
    if targets then
        for i, id in ipairs(targets) do
            local e = self._world:GetEntityByID(id)
            local pos = e:GridLocation().Position
            local bodyArea = e:BodyArea():GetArea()
            for j, grid in ipairs(bodyArea) do
                local absPos = pos + grid
                local magnitude = Vector2.Magnitude(absPos - center)
                if nearestMagnitude > magnitude then
                    nearestMagnitude = magnitude
                    nearestIds = {id}
                elseif nearestMagnitude == magnitude then
                    table.insert(nearestIds, id)
                end
            end
        end
    end

    return nearestIds
end

---选最近的一只怪或者机关
---以后需要在格子范围的基础上，再选最近的怪
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectNearestMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targets = self:_SelectMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local nearestIds, nearestMagnitude = {}, 999
    local center = casterEntity:GridLocation():Center()
    if targets then
        for i, id in ipairs(targets) do
            local e = self._world:GetEntityByID(id)
            local pos = e:GridLocation().Position
            local bodyArea = e:BodyArea():GetArea()
            for j, grid in ipairs(bodyArea) do
                local absPos = pos + grid
                local magnitude = Vector2.Magnitude(absPos - center)
                if nearestMagnitude > magnitude then
                    nearestMagnitude = magnitude
                    nearestIds = { id }
                elseif nearestMagnitude == magnitude then
                    table.insert(nearestIds, id)
                end
            end
        end
    end
    return nearestIds
end

---@param casterEntity Entity
function SkillScopeTargetSelector:_SelectPetMonsterTrapGridExceptConveyorFlyMultiBodyArea(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local arr = {}
    --Pet
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if pets then
        for i, v in ipairs(pets) do
            table.insert(arr, v)
        end
    end
    --Monster
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    if monsters then
        for i, v in ipairs(monsters) do
            local e = self._world:GetEntityByID(v)
            local bodyArea = e:BodyArea():GetArea()
            local monsterID = e:MonsterID():GetMonsterID()
            local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)
            if table.count(bodyArea) == 1 and monsterRaceType ~= MonsterRaceType.Fly then
                table.insert(arr, v)
            end
        end
    end
    --Trap
    local listTrapMap = self:_SelectTrap(casterEntity, skillScopeResult, skillID, targetTypeParam, false)
    if listTrapMap then
        for id, trapEntity in pairs(listTrapMap) do
            local cTrap = trapEntity:Trap()
            if id ~= casterEntity:GetID() then --传送带本身和传送带箭头
                table.insert(arr, id)
            end
        end
    end

    return arr
end

---@param casterEntity Entity
---@param skillScopeResult SkillScopeResult
---@param skillID number
function SkillScopeTargetSelector:_SelectOwnedPhantom(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDs = {}
    local phantoms = self._world:GetGroup(self._world.BW_WEMatchers.Phantom)
    if phantoms and #phantoms:GetEntities() > 0 then
        ---@type table<number,Entity>
        local entitys = phantoms:GetEntities()
        for _, entity in ipairs(entitys) do
            if entity:PhantomComponent():GetOwnerEntityID() == casterEntity:GetID() then
                if not entity:HasDeadMark() then
                    targetIDs[#targetIDs + 1] = entity:GetID()
                end
            end
        end
    else
        Log.fatal("场上没有幻象")
    end
    return targetIDs
end

---判断一个Entity是否在attackRange内，返回在范围内的Pos列表
---@param entityWork Entity
---@return boolean Vector2[]
function SkillScopeTargetSelector:_IsEntityInRange(entityWork, attackRange)

    local posBase = entityWork:GetGridPosition()
    local listBodyArea = entityWork:BodyArea():GetArea()
    local posList = table.create(#listBodyArea,0)
    for key, value in pairs(listBodyArea) do
        local posWork = posBase + value
        if attackRange._className == nil then --说明是个数组，这样是种临时处理，因为单翼天使的选目标是这种形式
            if table.icontains(attackRange, posWork) then
                table.insert(posList, posWork)
            end
        else --说明是个vector2
            if attackRange == posWork then
                table.insert(posList, posWork)
            end
        end
    end
    return table.count(posList) > 0, posList
end

---通过Entity类型和位置是否在技能范围内来查找目标
function SkillScopeTargetSelector:_SelectEntityByTypeAndRange(nEntityGroupType, attackRange)
    local group = self._world:GetGroup(nEntityGroupType)
    local entityList = group:GetEntities()

    ---@type SkillScopeTargetData[]
    local listTarget = {}
    for _, skillRangePos in ipairs(attackRange) do
        ---@param value Entity
        for key, value in ipairs(entityList) do
            if not value:HasDeadMark() and self:SelectConditionFilter(value) then
                local bIsInRange, listPos = self:_IsEntityInRange(value, skillRangePos)
                if bIsInRange then
                    for i = 1, #listPos do
                        local targetData = SkillScopeTargetData:New(listPos[i], value)
                        table.insert(listTarget, targetData)
                    end
                end
            end
        end
    end
    return listTarget
end

---@param casterEntity Entity
---@param skillScopeResult SkillScopeResult
---@param skillID number
function SkillScopeTargetSelector:_SelectSpecificMonster(casterEntity, skillScopeResult, skillID, listSpecificMonsterID)
    local listTargetByRange =
    self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.MonsterID, skillScopeResult:GetAttackRange())

    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    local listReturn = {}
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        local entityWork = value.m_entity
        local nMonsterID = entityWork:MonsterID():GetMonsterID()
        local nMonsterClassID = monsterConfigData:GetMonsterClassID(nMonsterID)
        if table.icontains(listSpecificMonsterID, nMonsterClassID) then
            local nEntityID = entityWork:GetID()
            if not table.icontains(listReturn, nEntityID) then
                table.insert(listReturn, nEntityID)
            end
        end
    end
    return listReturn
end

---@param casterEntity Entity
---@param skillScopeResult SkillScopeResult
---@param skillID number
function SkillScopeTargetSelector:_SelectMonsterGroup(casterEntity, skillScopeResult, skillID, nIncludeSelf)
    local listTargetByRange =
    self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.MonsterID, skillScopeResult:GetAttackRange())

    local listReturn = {}
    ---@type MonsterIDComponent
    local cmptCasterMonster = casterEntity:MonsterID()
    if cmptCasterMonster then
        local nSelfGroupID = cmptCasterMonster:GetMonsterGroupID()

        ---@param value SkillScopeTargetData
        for key, value in ipairs(listTargetByRange) do
            local entityWork = value.m_entity
            local nMonsterGroupID = entityWork:MonsterID():GetMonsterGroupID()
            local bFind = false
            if nSelfGroupID == nMonsterGroupID then
                bFind = true
                if not nIncludeSelf and entityWork == casterEntity then
                    bFind = false
                end
            end
            if bFind then
                local nEntityID = entityWork:GetID()
                if not table.icontains(listReturn, nEntityID) then
                    table.insert(listReturn, nEntityID)
                end
            end
        end
    end

    return listReturn
end

---技能范围内的Pet和机关
function SkillScopeTargetSelector:_SelectPetAndTrapBomb(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local arr = {}
    local pets = self:_SelectPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    table.appendArray(arr, pets)

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posPlayer = teamEntity:GetGridPosition()
    local posSelf = casterEntity:GetGridPosition()
    local mapTrap = self:_SelectTrapByHit(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if mapTrap then
        ---@param entityBomb Entity
        for key, entityBomb in pairs(mapTrap) do
            if GameHelper.IsPointOneLine(posSelf, entityBomb:GetGridPosition(), posPlayer) then
                table.insert(arr, key)
            end
        end
    end
    return arr
end

function SkillScopeTargetSelector:_SelectHighestHPPercentMonster(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    if not monsters then
        return {}
    end
    local count = table.count(monsters)
    if count == 0 then
        return {}
    end
    local fstId = monsters[1]
    if count == 1 then
        return { fstId }
    end
    local highestHPPercent = 0
    local highestHPPercentId = 0
    for i = 1, count do
        local id = monsters[i]
        local e = self._world:GetEntityByID(id)
        local percent = self:_GetHPPercent(e)
        if highestHPPercent < percent then
            highestHPPercent = percent
            highestHPPercentId = id
        end
    end
    return { highestHPPercentId }
end

function SkillScopeTargetSelector:_SelectSpecificPet(casterEntity, skillScopeResult, skillID, tSpecificPetID)
    local tPetEntityID = {}
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local publicPetEntities = teamEntity:Team():GetTeamPetEntities()
    for _, entity in ipairs(publicPetEntities) do
        local cPetPst = entity:PetPstID()
        local templateID = cPetPst:GetTemplateID()
        if table.icontains(tSpecificPetID, templateID) then
            table.insert(tPetEntityID, entity:GetID())
        end
    end

    return tPetEntityID
end

function SkillScopeTargetSelector:_SelectSpecificPrimaryElementPet(casterEntity, skillScopeResult, skillID, tElement)
    local dicElement = {}
    for _, nElement in ipairs(tElement) do
        dicElement[nElement] = true
    end
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local publicPetEntities = teamEntity:Team():GetTeamPetEntities()
    local tPetEntityID = {}
    for _, entity in ipairs(publicPetEntities) do
        local cElement = entity:Element()
        local nMainElement = cElement:GetPrimaryType()
        if dicElement[nMainElement] then
            table.insert(tPetEntityID, entity:GetID())
        end
    end

    return tPetEntityID
end

function SkillScopeTargetSelector:_SelectHighestHPMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    if not monsters then
        return {}
    end
    local count = table.count(monsters)
    if count == 0 then
        return {}
    end
    local fstId = monsters[1]
    if count == 1 then
        return { fstId }
    end
    local highestHP = 0
    local highestHPId = 0
    for i = 1, count do
        local id = monsters[i]
        local e = self._world:GetEntityByID(id)
        local hp = e:Attributes():GetCurrentHP()
        if highestHP < hp then
            highestHP = hp
            highestHPId = id
        end
    end
    return { highestHPId }
end

function SkillScopeTargetSelector:_GetHPPercent(e)
    local hp = e:Attributes():GetCurrentHP()
    local maxHP = e:Attributes():CalcMaxHp()
    local percent = hp / maxHP
    return percent
end

function SkillScopeTargetSelector:_SelectLowestHPPercentMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    local count = table.count(monsters)
    if not monsters or count == 0 then
        return {}, 1
    end
    if count == 1 then
        local fstId = monsters[1]
        local e = self._world:GetEntityByID(fstId)
        local percent = self:_GetHPPercent(e)
        return { fstId }, percent
    end
    local hpPercent = 999
    local hpPercentId = 0
    local selectHpZero = 1 --是否可以选择血量是0的目标，默认1选择
    --因为子技能范围的配置默认值是0，所以只有table的时候才重新取值
    if targetTypeParam and type(targetTypeParam) == "table" then
        selectHpZero = targetTypeParam[1] or 1
    end
    for i = 1, count do
        local id = monsters[i]
        local e = self._world:GetEntityByID(id)
        local percent = self:_GetHPPercent(e)
        local hpIsSatisfied = true
        --一些特殊的技能，会选择血量不是0的，血量百分比最低的目标
        if selectHpZero == 0 and percent == 0 then
            hpIsSatisfied = false
        end
        if hpIsSatisfied and hpPercent >= percent then
            hpPercent = percent
            hpPercentId = id
        end
    end

    --配置了不选择血量0的情况下，有可能要打多个目标，但是多个目标都血量0了，那么开始随机打
    if hpPercentId == 0 then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local idx = utilScopeSvc:_GetRandomNumber(1, count)
        local id = monsters[idx]
        local e = self._world:GetEntityByID(id)
        local percent = self:_GetHPPercent(e)
        hpPercent = percent
        hpPercentId = id
    end

    return { hpPercentId }, hpPercent
end

function SkillScopeTargetSelector:_SelectLowestHPPercentMonsterParam(casterEntity, skillScopeResult, skillID, param)
    local ids, percent = self:_SelectLowestHPPercentMonster(casterEntity, skillScopeResult, skillID, param)
    local percentParam = 0
    if param then
        percentParam = param[1]
    end
    if percent < percentParam then
        return ids
    end
    return {}
end

function SkillScopeTargetSelector:_SelectRandomNMonster(casterEntity, skillScopeResult, skillID, param)
    local monsterIdList = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    monsterIdList = table.unique(monsterIdList)
    local ids = {}
    if monsterIdList and table.count(monsterIdList) > 0 then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local count = param[1]
        if count and count > 0 then
            for i = 1, count do
                if #monsterIdList == 0 then
                    break
                end
                local rate = param[1 + i]
                local needCal = false
                if rate >= 1 then
                    needCal = true
                else
                    local randomNum = utilScopeSvc:_GetRandomNumber()
                    needCal = (rate > randomNum)
                end
                if needCal then
                    local idx = utilScopeSvc:_GetRandomNumber(1, table.count(monsterIdList))
                    table.insert(ids, monsterIdList[idx])
                    table.remove(monsterIdList, idx)
                end
            end
        end
    end
    return ids
end

---选择怪物
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectDeadMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    ----@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for _, skillRangePos in ipairs(attackRange) do
        local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(skillRangePos)
        if isHasMonster then
            local monsterEntity = self._world:GetEntityByID(monsterID)
            local curHp = monsterEntity:Attributes():GetCurrentHP()
            if curHp and curHp <= 0 then
                targetIDArray[#targetIDArray + 1] = monsterID
            end
        end
    end

    return targetIDArray
end

function SkillScopeTargetSelector:_SelectDeadMonsterWithBuff(casterEntity, skillScopeResult, skillID, filterBuffEffect)
    local monsterIdList = self:_SelectDeadMonster(casterEntity, skillScopeResult, skillID, filterBuffEffect)
    monsterIdList = table.unique(monsterIdList)
    local validateMonsters = self:_FilterMustHaveBuffEffect(monsterIdList, filterBuffEffect)
    local retTargetID = {}

    return validateMonsters
end

function SkillScopeTargetSelector:_FilterMustHaveBuffEffect(movers, filterBuffEffect)
    local targetIDArray = {}
    for _, v in ipairs(movers) do
        local buffCpt = self._world:GetEntityByID(v):BuffComponent()
        local validate = true --默认技能生效，在挂有某种buff效果时不生效
        if buffCpt then
            for _, value in ipairs(filterBuffEffect) do
                if not buffCpt:HasBuffEffect(value) then
                    validate = false
                    break
                end
            end
        end
        if validate then
            table.insert(targetIDArray, v)
        end
    end
    return targetIDArray
end

function SkillScopeTargetSelector:_SelectMonsterHaveBuffANoBuffB(
    casterEntity,
    skillScopeResult,
    skillID,
    filterBuffEffect)
    local monsterIdList = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    monsterIdList = table.unique(monsterIdList)
    ---必须拥有参数1的buff
    local validateMonsters = self:_FilterMustHaveBuffEffect(monsterIdList, { filterBuffEffect[1] })
    ---必须没有参数2的buff
    validateMonsters = self:_FilterByBuffEffect(validateMonsters, { filterBuffEffect[2] })

    return validateMonsters
end

function SkillScopeTargetSelector:_SelectNearestMonsterNoID(casterEntity, skillScopeResult, skillID, monsterIDList)
    ---@type Vector2
    local ownPos = skillScopeResult:GetCenterPos()
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")
    local targetIDArray = {}
    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID, nil)
    if selectedMonsterIds then
        local monsterList = utilScopeCalc:SortMonstersListByPos(ownPos, selectedMonsterIds)
        for _, element in ipairs(monsterList) do
            ---@type Entity
            local monsterEntity = element.monster_e
            if not table.icontains(monsterIDList, monsterEntity:MonsterID():GetMonsterClassID()) and
                not monsterEntity:HasDeadMark()
            then
                targetIDArray[#targetIDArray + 1] = monsterEntity:GetID()
                break
            end
        end
    end
    return targetIDArray
end

---@param skillScopeResult SkillScopeResult 技能的范围结果
function SkillScopeTargetSelector:_SelectNearestMonstersIsScope(casterEntity, skillScopeResult, skillID, param)
    local nMonsterCount = param[1]
    ---@type Vector2
    local ownPos = skillScopeResult:GetCenterPos()
    if #ownPos ~= 0 then
        if EDITOR then
            Log.exception("CenterPosIsTable SkillID:", skillID)
        else
            Log.fatal("CenterPosIsTable SkillID:", skillID)
        end
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    ---去重
    selectedMonsterIds = table.unique(selectedMonsterIds)
    local sortMonsterList = utilScopeCalc:SortMonstersListByPos(ownPos, selectedMonsterIds)
    local targetIDArray = {}
    for i, id in ipairs(sortMonsterList) do
        if i > nMonsterCount then
            break
        end
        table.insert(targetIDArray, id.monster_e:GetID())
    end
    return targetIDArray
end

---@param skillScopeResult SkillScopeResult 技能的范围结果
function SkillScopeTargetSelector:_SelectSpecificTrap(casterEntity, skillScopeResult, skillID, param)
    if type(param) == "number" then
        param = { param }
    end
    ---@type UtilDataServiceShare
    local utilDatSvc = self._world:GetService("UtilData")
    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)

    local resultList = {}
    for _, entity in pairs(trapEntityList) do
        if entity:Trap() and table.intable(param, entity:Trap():GetTrapID()) then
            if utilDatSvc:IsTrapPosCanMoveMonster(entity, casterEntity) then
                table.insert(resultList, entity:GetID())
                break
            end
        end
    end
    return resultList
end

---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param casterEntity Entity
function SkillScopeTargetSelector:_SelectSpecificTrapAndFarthestHitBackPlayer(
    casterEntity,
    skillScopeResult,
    skillID,
    param)
    if type(param) == "number" then
        param = { param }
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)
    ---@type Entity[]
    local tempEntityList = {}
    local resultList = {}
    for _, entity in pairs(trapEntityList) do
        if entity:Trap() and table.intable(param, entity:Trap():GetTrapID()) then
            table.insert(tempEntityList, entity)
        end
    end
    if #tempEntityList > 1 then
        ---@type UtilCalcServiceShare
        local utilCalcSvc = self._world:GetService("UtilCalc")
        local posList = {}
        for _, entity in ipairs(tempEntityList) do
            local attackerPos = entity:GetGridPosition()
            table.insert(posList, attackerPos)
        end
        local pos =
        utilCalcSvc:GetHitBackPlayerFarthestPos(posList, casterEntity, HitBackDirectionType.EightDir, teamEntity)
        for _, entity in ipairs(tempEntityList) do
            local attackerPos = entity:GetGridPosition()
            if attackerPos.x == pos.x and attackerPos.y == pos.y then
                resultList[1] = entity:GetID()
                break
            end
        end
    elseif #tempEntityList == 1 then
        resultList[1] = tempEntityList[1]:GetID()
    end
    return resultList
end

---选择怪物，生死不限，和基本的选择怪物类似，但_SelectMonster用的地方比较多
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectMonsterDeadOrAlive(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    for _, skillRangePos in ipairs(attackRange) do
        local targetIDInSkillRangeList = self:_CalcMonsterInSkillRange(skillRangePos, true)
        for _, v in ipairs(targetIDInSkillRangeList) do
            if v > 0 then
                targetIDArray[#targetIDArray + 1] = v
            end
        end
    end
    return targetIDArray
end

---选择可以被攻击的机关： 带血或者可以被击退（比如炸弹）
function SkillScopeTargetSelector:_SelectTrapByHitDeadOrAlive(casterEntity, skillScopeResult, skillID)
    local listTarget = {}
    local listTargetByRange =
    self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.Trap, skillScopeResult:GetAttackRange())
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        local entityTrap = value.m_entity
        local id = entityTrap:GetID()
        if id > 0 and self:_SelectTrapFilter(casterEntity, id, true, true) then
            listTarget[id] = entityTrap
        end
    end
    return listTarget
end

function SkillScopeTargetSelector:_SelectMonsterTrapDeadOrAlive(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local monsters = self:_SelectMonsterDeadOrAlive(casterEntity, skillScopeResult, skillID, targetTypeParam)
    for _, v in ipairs(monsters) do
        table.insert(targetIDArray, v)
    end
    local mapTrap = self:_SelectTrapByHitDeadOrAlive(casterEntity, skillScopeResult, skillID, targetTypeParam)
    for key, value in pairs(mapTrap) do
        if value:Trap():GetTrapType() ~= TrapType.Protected then
            table.insert(targetIDArray, key)
        end
    end
    return targetIDArray
end

function SkillScopeTargetSelector:_SelectAlignmentTargetEnemyTeam(casterEntity, skillScopeResult, skillID)
    local team1 = self._world:Player():GetLocalTeamEntity()
    local team2 = self._world:Player():GetRemoteTeamEntity()
    local teams = { team1, team2 }
    local match = MatchAlignmentType
    local casterAlignment = casterEntity:Alignment():GetAlignmentType()
    local attackRange = skillScopeResult:GetAttackRange()
    local range = {}
    for i, v in ipairs(attackRange) do
        if v._className == "Vector2" then
            range[#range + 1] = v
        else --单翼天使的技能范围特殊处理
            table.appendArray(range, v)
        end
    end
    local es = {}
    ---@param e Entity
    for i, e in ipairs(teams) do
        local targetAlignment = e:Alignment():GetAlignmentType()
        local targetType = match(casterAlignment, targetAlignment)
        if targetType == AlignmentTargetType.Enemy then
            if not e:HasTeamDeadMark() and table.icontains(range, e:GetGridPosition()) then
                es[#es + 1] = e:GetID()
            end
        end
    end

    ---解决MSG41293
    local mapTrap = self:_SelectTrapByHit(casterEntity, skillScopeResult, skillID)
    for key, value in pairs(mapTrap) do
        if value:Trap():GetTrapType() ~= TrapType.Protected then
            es[#es + 1] = key
        end
    end

    return es
end

--无视技能范围
function SkillScopeTargetSelector:_SelectAlignmentTargetFriendTeam(casterEntity, skillScopeResult, skillID)
    local team1 = self._world:Player():GetLocalTeamEntity()
    local team2 = self._world:Player():GetRemoteTeamEntity()
    local teams = { team1, team2 }
    local match = MatchAlignmentType
    local casterAlignment = casterEntity:Alignment():GetAlignmentType()
    -- local attackRange = skillScopeResult:GetAttackRange()
    -- local range = {}
    -- for i, v in ipairs(attackRange) do
    --     if v._className == "Vector2" then
    --         range[#range + 1] = v
    --     else --单翼天使的技能范围特殊处理
    --         table.appendArray(range, v)
    --     end
    -- end
    local es = {}
    for i, e in ipairs(teams) do
        local targetAlignment = e:Alignment():GetAlignmentType()
        local targetType = match(casterAlignment, targetAlignment)
        if targetType == AlignmentTargetType.Friend then
            --if table.icontains(range, e:GetGridPosition()) then
            es[#es + 1] = e:GetID()
            --end
        end
    end
    return es
end

function SkillScopeTargetSelector:_SelectAlignmentTargetFriendPet(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local team1 = self._world:Player():GetLocalTeamEntity()
    local team2 = self._world:Player():GetRemoteTeamEntity()
    local teams = { team1, team2 }
    local match = MatchAlignmentType
    local casterAlignment = casterEntity:Alignment():GetAlignmentType()
    local attackRange = skillScopeResult:GetAttackRange()
    local targetPieceType = targetTypeParam
    local range = {}
    for i, v in ipairs(attackRange) do
        if v._className == "Vector2" then
            range[#range + 1] = v
        else --单翼天使的技能范围特殊处理
            table.appendArray(range, v)
        end
    end

    local es = {}
    for i, eTeam in ipairs(teams) do
        local targetAlignment = eTeam:Alignment():GetAlignmentType()
        local targetType = match(casterAlignment, targetAlignment)
        if targetType == AlignmentTargetType.Friend then
            if table.icontains(range, eTeam:GetGridPosition()) then
                for i, e in ipairs(eTeam:Team():GetTeamPetEntities()) do
                    if not targetPieceType or self:_CheckPetElement(e, targetPieceType) then
                        es[#es + 1] = e:GetID()
                    end
                end
            end
            break
        end
    end
    return es
end

function SkillScopeTargetSelector:_SelectAlignmentTargetEnemyPet(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local team1 = self._world:Player():GetLocalTeamEntity()
    local team2 = self._world:Player():GetRemoteTeamEntity()
    local teams = { team1, team2 }
    local match = MatchAlignmentType
    local casterAlignment = casterEntity:Alignment():GetAlignmentType()
    local targetPieceType = targetTypeParam
    local attackRange = skillScopeResult:GetAttackRange()
    local range = {}
    for i, v in ipairs(attackRange) do
        if v._className == "Vector2" then
            range[#range + 1] = v
        else --单翼天使的技能范围特殊处理
            table.appendArray(range, v)
        end
    end

    local es = {}
    for i, eTeam in ipairs(teams) do
        local targetAlignment = eTeam:Alignment():GetAlignmentType()
        local targetType = match(casterAlignment, targetAlignment)
        if targetType == AlignmentTargetType.Enemy then
            if not eTeam:HasTeamDeadMark() and table.icontains(range, eTeam:GetGridPosition()) then
                for i, e in ipairs(eTeam:Team():GetTeamPetEntities()) do
                    if not targetPieceType or self:_CheckPetElement(e, targetPieceType) then
                        es[#es + 1] = e:GetID()
                    end
                end
            end
            break
        end
    end
    return es
end

function SkillScopeTargetSelector:_SelectAlignmentTargetEnemyTeamHaveBuffANoBuffB(
    casterEntity,
    skillScopeResult,
    skillID,
    filterBuffEffect)
    local team1 = self._world:Player():GetLocalTeamEntity()
    local team2 = self._world:Player():GetRemoteTeamEntity()
    local teams = { team1, team2 }
    local match = MatchAlignmentType
    local casterAlignment = casterEntity:Alignment():GetAlignmentType()
    local attackRange = skillScopeResult:GetAttackRange()
    local range = {}
    for i, v in ipairs(attackRange) do
        if v._className == "Vector2" then
            range[#range + 1] = v
        else --单翼天使的技能范围特殊处理
            table.appendArray(range, v)
        end
    end
    local es = {}
    for i, e in ipairs(teams) do
        local targetAlignment = e:Alignment():GetAlignmentType()
        local targetType = match(casterAlignment, targetAlignment)
        if targetType == AlignmentTargetType.Enemy then
            if not e:HasTeamDeadMark() and table.icontains(range, e:GetGridPosition()) then
                es[#es + 1] = e:GetID()
            end
        end
    end

    ---必须拥有参数1的buff
    es = self:_FilterMustHaveBuffEffect(es, { filterBuffEffect[1] })
    ---必须没有参数2的buff
    es = self:_FilterByBuffEffect(es, { filterBuffEffect[2] })

    return es
end

---
function SkillScopeTargetSelector:_SelectEntityWithBuff(casterEntity, skillScopeResult, skillID, filterBuffEffect)
    if not filterBuffEffect then
        filterBuffEffect = {}
    end
    local targetBuffEffect = filterBuffEffect[1] or 0
    local filterRange = filterBuffEffect[2]

    local team1 = self._world:Player():GetLocalTeamEntity()
    local es = {team1}
    local team2 = self._world:Player():GetRemoteTeamEntity()
    if team2 then
        es[#es + 1] = team2
    end
    local monsters = self._world:GetGroupEntities(self._world.BW_WEMatchers.AliveMonster)
    table.appendArray(es, monsters)

    local attackRange = skillScopeResult:GetAttackRange()
    local range = {}
    for i, v in ipairs(attackRange) do
        if v._className == "Vector2" then
            range[#range + 1] = v
        else --单翼天使的技能范围特殊处理
            table.appendArray(range, v)
        end
    end

    local ret = {}
    for i, e in ipairs(es) do
        if filterRange then 
            local inRange = self:_IsEntityInRange(e,attackRange)
            if inRange then 
                if e:BuffComponent():HasBuffEffect(targetBuffEffect) then
                    ret[#ret + 1] = e:GetID()
                end
            end
        else
            if e:BuffComponent():HasBuffEffect(targetBuffEffect) then
                ret[#ret + 1] = e:GetID()
            end
        end
    end
    return ret
end

function SkillScopeTargetSelector:_SelectGridCanPurifyTrap(casterEntity, skillScopeResult, skillID, effectParam)
    local es = {}

    local tv2Candidate = {}

    for _, v2GridPos in ipairs(skillScopeResult:GetAttackRange()) do
        table.insert(tv2Candidate, v2GridPos)
    end
    if #tv2Candidate == 0 then
        return es
    end

    ---@type UtilDataServiceShare
    local udsvc = self._world:GetService("UtilData")

    for _, v2 in ipairs(tv2Candidate) do
        local array = udsvc:GetTrapsAtPos(v2)
        for _, eTrap in ipairs(array) do
            local cTrap = eTrap:Trap()
            if (not eTrap:HasDeadMark()) and cTrap:CanBePurified() then
                table.insert(es, eTrap:GetID())
            end
        end
    end

    return es
end

function SkillScopeTargetSelector:_SelectAntiAITriggerEntity(casterEntity, skillScopeResult, skillID, effectParam)
    local cBattleStat = casterEntity:GetOwnerWorld():BattleStat()
    local e = casterEntity:GetOwnerWorld():GetEntityByID(cBattleStat:GetLastAntiTriggerEntityID())
    if e then
        return { e:GetID() }
    end

    return {}
end

function SkillScopeTargetSelector:_SelectMaxDamageDealerPetToCaster(casterEntity, skillScopeResult, skillID, effectParam)
    local cDamageStatistics = casterEntity:DamageStatisticsComponent()
    if not cDamageStatistics then
        return {}
    end

    local es = {}

    local array = cDamageStatistics:GetDamageSourceArray()

    for i = #array, 1, -1 do
        local e = self._world:GetEntityByID(array[i].entityID)
        if not e:HasPetPstID() then
            goto SKILL_SCOPE_TARGET_SELECTOR_MAX_DAMAGE_DEALER_PET_TO_SELF_CONTINUE
        end

        if e:HasBuffFlag(BuffFlags.SealedCurse) then
            Log.info("MaxDamageDealerPetToCaster: skip already cursed target: ", e:GetID())
            goto SKILL_SCOPE_TARGET_SELECTOR_MAX_DAMAGE_DEALER_PET_TO_SELF_CONTINUE
        end

        table.insert(es, e:GetID())
        Log.info("MaxDamageDealerPetToCaster: curse target: ", e:GetID())
        break

        ::SKILL_SCOPE_TARGET_SELECTOR_MAX_DAMAGE_DEALER_PET_TO_SELF_CONTINUE::
    end

    return es
end

---10的基础上，添加范围内施法者召唤的机关
function SkillScopeTargetSelector:_SelectMonsterTrapAndTrapSuperEntityIsCaster(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local targetIDArray = {}
    --10
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local es = self:_SelectAlignmentTargetEnemyTeam(casterEntity, skillScopeResult, skillID)
        table.appendArray(targetIDArray, es)
    else
        local monsterTrapID = self:_SelectMonsterTrap(casterEntity, skillScopeResult, skillID, targetTypeParam)
        table.appendArray(targetIDArray, monsterTrapID)
    end

    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)
    for _, entity in pairs(trapEntityList) do
        if entity:HasSummoner() then
            local superEntityID = entity:Summoner():GetSummonerEntityID()
            if superEntityID == casterEntity:GetID() and not table.intable(targetIDArray, entity:GetID()) then
                table.insert(targetIDArray, entity:GetID())
            end
        end
    end

    return targetIDArray
end

function SkillScopeTargetSelector:_SelectMonsterOrEnemyPets(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local ret = self:_SelectMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    return ret
end

---NearestMonsterOneByOne = 44, ---最近的一只怪,初始从范围的中心点位置开始找，找下一个是从上一个选中的位置选，不选重复的
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectNearestMonsterOneByOne(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}

    --黑拳赛直接返回对方队伍
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local targetIDArray = self:_SelectAlignmentTargetEnemyTeam(casterEntity, skillScopeResult, skillID)
        return targetIDArray
    end

    --想要选取的目标数量
    local targetIDCount = targetTypeParam[1]

    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID, nil)
    if table.count(monsters) == 0 then
        return targetIDArray
    end

    --第一次的选择点是范围的中心点
    ---@type Vector2
    local selectCenterPos = skillScopeResult:GetCenterPos()
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")

    --当目标没有选完  or  已经选够
    local calcCount = 0
    while table.count(monsters) > 0 do
        local monsterList = utilScopeCalc:SortMonstersListByPos(selectCenterPos, monsters)
        for _, element in ipairs(monsterList) do
            ---@type Entity
            local monsterEntity = element.monster_e
            --添加进入一个就可以返回
            if not table.icontains(targetIDArray, monsterEntity:GetID()) and not monsterEntity:HasDeadMark() then
                targetIDArray[#targetIDArray + 1] = monsterEntity:GetID()

                --策划说，距离是从怪物的身形0,0去找，多格怪物也是
                selectCenterPos = monsterEntity:GetGridPosition()

                while table.intable(monsters, monsterEntity:GetID()) do
                    table.removev(monsters, monsterEntity:GetID())
                end

                break
            end
        end

        if table.count(targetIDArray) >= targetIDCount then
            break
        end

        calcCount = calcCount + 1
        if calcCount > 10 then
            break
        end
    end

    return targetIDArray
end

---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectLastActiveSkillCasterPet(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local cBattleStat = casterEntity:GetOwnerWorld():BattleStat()
    local e = casterEntity:GetOwnerWorld():GetEntityByID(cBattleStat:GetLastActiveSkillCasterID())
    if e then
        return { e:GetID() }
    end

    return {}
end

---@param skillScopeResult SkillScopeResult 技能的范围结果
function SkillScopeTargetSelector:_SelectMonsterOnSpecificTrap(casterEntity, skillScopeResult, skillID, param)
    if type(param) == "number" then
        param = { param }
    end
    ---@type UtilDataServiceShare
    local utilDatSvc = self._world:GetService("UtilData")
    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)

    local resultList = {}

    local trapPosList = {}
    for _, entity in pairs(trapEntityList) do
        if entity:Trap() and not entity:HasDeadMark() and table.intable(param, entity:Trap():GetTrapID()) then
            local trapPos = entity:GetGridPosition()
            table.insert(trapPosList, trapPos)
        end
    end

    --Monster
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    if monsters then
        for i, v in ipairs(monsters) do
            local e = self._world:GetEntityByID(v)
            local bodyArea = e:BodyArea():GetArea()
            local pos = e:GridLocation().Position

            for j, grid in ipairs(bodyArea) do
                local workPos = pos + grid
                if table.intable(trapPosList, workPos) and not table.intable(resultList, v) then
                    table.insert(resultList, v)
                end
            end
        end
    end

    return resultList
end

---选择范围结果内的队长
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectCaptainInRange(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if casterEntity:HasPet() then
        teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    end
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    local targetIDArray = {}
    local teamLeaderGridPos = teamEntity:GetGridPosition()
    local attackRange = skillScopeResult:GetAttackRange()
    if table.icontains(attackRange, teamLeaderGridPos) then
        targetIDArray[#targetIDArray + 1] = teamLeaderEntityID
    end
    return targetIDArray
end

---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
---
function SkillScopeTargetSelector:_SelectN15ChessMonsterMoveTarget(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type number[]
    local entityIDList = utilScopeCalc:GetSortChessPetByMonsterPos(casterPos)
    if #entityIDList >= 1 then
        return { entityIDList[1] }
    else
        return {}
    end
end

---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
---
function SkillScopeTargetSelector:_SelectN15ChessMonsterAttackTargets(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")
    local attackRange = skillScopeResult:GetAttackRange()
    ---@type number[]
    local entityIDList = utilScopeCalc:ChessMonsterSelectTarget(attackRange, targetTypeParam[1])
    return entityIDList
end

---最近的一只棋子
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectNearestChessPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local casterPos = casterEntity:GridLocation().Position
    local AllChessPet = {}
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    local chessPetGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    local chessPetIDList = {}
    for _, e in ipairs(chessPetGroup:GetEntities()) do
        table.insert(chessPetIDList, e:GetID())
    end
    local selectTargetData = utilScopeSvc:SortMonstersListByPos(casterPos, chessPetIDList)

    if selectTargetData ~= nil and #selectTargetData > 0 then
        local firstData = selectTargetData[1]
        ---@type Entity
        local entity = firstData.monster_e
        targetIDArray[#targetIDArray + 1] = entity:GetID()
    end

    return targetIDArray
end

---选择范围内的棋子光灵
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectChessPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    for _, skillRangePos in ipairs(attackRange) do
        local targetIDInSkillRangeList = self:_CalcChessPetInSkillRange(skillRangePos)
        for _, v in ipairs(targetIDInSkillRangeList) do
            if v > 0 then
                targetIDArray[#targetIDArray + 1] = v
            end
        end
    end
    return targetIDArray
end

---根据指定的一个坐标位置，判断该位置上是否有棋子
---@param skillRangePos Vector2
function SkillScopeTargetSelector:_CalcChessPetInSkillRange(skillRangePos, withDead)
    local targetIDList = {}

    local targetEntityID = -1
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if (withDead or (not e:HasDeadMark())) and self:SelectConditionFilter(e) then
            local monsterEntityID = e:GetID()
            local monster_grid_location_cmpt = e:GridLocation()
            local monster_body_area_cmpt = e:BodyArea()
            local monster_body_area = monster_body_area_cmpt:GetArea()
            for i, bodyArea in ipairs(monster_body_area) do
                local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                if curMonsterBodyPos == skillRangePos then
                    targetEntityID = monsterEntityID
                    break
                end
            end
        end
    end

    if targetEntityID > 0 then
        targetIDList[#targetIDList + 1] = targetEntityID
    end

    return targetIDList
end

---选择怪物和棋子
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectMonsterAndChessPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    for _, v in ipairs(monsters) do
        table.insert(targetIDArray, v)
    end
    local chessPets = self:_SelectChessPet(casterEntity, skillScopeResult, skillID, targetTypeParam)
    for _, v in ipairs(chessPets) do
        table.insert(targetIDArray, v)
    end
    return targetIDArray
end

---选择范围内的血量值最少的棋子光灵
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectLessHPChess(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetEntityID = nil
    local hp = 1000
    local attackRange = skillScopeResult:GetAttackRange()
    for _, skillRangePos in ipairs(attackRange) do
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            if not e:HasDeadMark() and self:SelectConditionFilter(e) then
                local monsterEntityID = e:GetID()
                local monster_grid_location_cmpt = e:GridLocation()
                local monster_body_area_cmpt = e:BodyArea()
                local monster_body_area = monster_body_area_cmpt:GetArea()
                local curHp = e:Attributes():GetCurrentHP()
                for i, bodyArea in ipairs(monster_body_area) do
                    local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                    if curMonsterBodyPos == skillRangePos and curHp < hp then
                        targetEntityID = monsterEntityID
                        hp = curHp
                        break
                    end
                end
            end
        end
    end

    return { targetEntityID }
end

--有怪选怪 没怪选队伍
function SkillScopeTargetSelector:_SelectMonsterOrTeam(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    if #monsters > 0 then
        return monsters
    else
        return self:_SelecTeam(casterEntity, skillScopeResult, skillID, targetTypeParam)
    end
end

--先寻找有Buff的目标，没有就找距离最近的
function SkillScopeTargetSelector:_SelectEntityWithBuffOrNearestMonster(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local buffTargets = self:_SelectEntityWithBuff(casterEntity, skillScopeResult, skillID, targetTypeParam)
    if #buffTargets > 0 then
        return buffTargets
    else
        return self:_SelectNearestMonsterWithScopeCenter(casterEntity, skillScopeResult, skillID, targetTypeParam)
    end
end

--使用技能范围的中心计算最近的怪物
function SkillScopeTargetSelector:_SelectNearestMonsterWithScopeCenter(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local targetIDArray = {}
    local casterPos = skillScopeResult:GetCenterPos()
    local allMonsters = {}
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local selectTargetData = utilScopeSvc:SortMonstersByPos(casterPos, true)
    for _, element in ipairs(selectTargetData) do
        ---@type Entity
        local monsterEntity = element.monster_e
        allMonsters[#allMonsters + 1] = monsterEntity:GetID()
    end

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    local isFind = false
    if selectedMonsterIds then
        for i = 1, #allMonsters do
            local monsterId = allMonsters[i]
            for _, v in ipairs(selectedMonsterIds) do
                if v == monsterId then
                    targetIDArray[#targetIDArray + 1] = monsterId
                    isFind = true
                    break
                end
            end
            if isFind then
                break
            end
        end
    end

    return targetIDArray
end
---施法者召唤的机关
function SkillScopeTargetSelector:_SelectTrapSummonEntityIsCaster(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local targetIDArray = {}
    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)
    for _, entity in pairs(trapEntityList) do
        if entity:HasSummoner() then
            local summonEntityID = entity:Summoner():GetSummonerEntityID()
            ---@type Entity
            local summonEntity = entity:GetSummonerEntity()
            --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
            if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                summonEntityID = summonEntity:GetSuperEntity():GetID()
            end
            if summonEntityID == casterEntity:GetID() and not table.intable(targetIDArray, entity:GetID()) then
                table.insert(targetIDArray, entity:GetID())
            end
        end
    end

    return targetIDArray
end


---@param skillScopeResult SkillScopeResult 技能的范围结果
function SkillScopeTargetSelector:_SelectNearestAndFarestMonsterInScope(casterEntity, skillScopeResult, skillID, param)
    local nMonsterCount = param[1]
    ---@type Vector2
    local ownPos = skillScopeResult:GetCenterPos()
    if #ownPos ~= 0 then
        if EDITOR then
            Log.exception("CenterPosIsTable SkillID:", skillID)
        else
            Log.fatal("CenterPosIsTable SkillID:", skillID)
        end
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalc = self._world:GetService("UtilScopeCalc")

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    ---去重
    selectedMonsterIds = table.unique(selectedMonsterIds)
    local sortMonsterList = utilScopeCalc:SortMonstersListByPos(ownPos, selectedMonsterIds)
    local targetIDArray = {}
    for i, id in ipairs(sortMonsterList) do
        if i > nMonsterCount then
            break
        end
        table.insert(targetIDArray, id.monster_e:GetID())
    end
    local findFarestCount = 1
    local monsterListCount = #sortMonsterList
    for i = monsterListCount, 1, -1 do
        if findFarestCount > nMonsterCount then
            break
        end
        table.insert(targetIDArray, sortMonsterList[i].monster_e:GetID())
        findFarestCount = findFarestCount + 1
    end
    return targetIDArray
end

---@param skillScopeResult SkillScopeResult 技能的范围结果
function SkillScopeTargetSelector:_SelectTrapPosByID(casterEntity, skillScopeResult, skillID, param)
    if type(param) == "number" then
        param = { param }
    end
    ---@type UtilDataServiceShare
    local utilDatSvc = self._world:GetService("UtilData")
    ---@type Entity[]
    local trapEntityList = self:_SelectTrap(casterEntity, skillScopeResult, skillID, nil, false)

    local resultList = {}
    for _, entity in pairs(trapEntityList) do
        if entity:Trap() and table.intable(param, entity:Trap():GetTrapID()) then
            table.insert(resultList, entity:GetID())
        end
    end
    return resultList
end
---范围内最近的N个敌人（优先按体型小到大排序）
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectNearestMonsterSortByBodyArea(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local nMonsterCount = targetTypeParam[1] or 1
    ---@type Vector2
    local casterPos = skillScopeResult:GetCenterPos()
    if not casterPos then
        casterPos = casterEntity:GridLocation().Position
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    local selectedMonsterIds = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
    ---去重
    selectedMonsterIds = table.unique(selectedMonsterIds)
    local sortMonsterList = utilScopeSvc:SortMonstersListByBodyAreaAndPos(casterPos,selectedMonsterIds,true)

    local targetIDArray = {}
    for i, id in ipairs(sortMonsterList) do
        if i > nMonsterCount then
            break
        end
        table.insert(targetIDArray, id.monster_e:GetID())
    end
    return targetIDArray
end


---将施法者的召唤者选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectCasterSummoner(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local useEntity = casterEntity
    local casterEntityID = casterEntity:GetID()
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        local superEntity = casterEntity:SuperEntityComponent():GetSuperEntity()
        if superEntity then
            casterEntityID = superEntity:GetID()
            useEntity = superEntity
        end
    end
    local ownerID = nil
    if useEntity:HasSummoner() then
        local ownerEntity = useEntity:GetSummonerEntity()
        if ownerEntity then
            ownerID = ownerEntity:GetID()
        end
    end
    local targetIDArray = {}
    if ownerID then
        targetIDArray[#targetIDArray + 1] = ownerID
    end
    return targetIDArray
end

---将施法者的召唤者选入目标列表
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectMostVisibleBuffMonster(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local selectHpZero = 1 --是否可以选择血量是0的目标，默认1选择
    --因为子技能范围的配置默认值是0，所以只有table的时候才重新取值
    if targetTypeParam and type(targetTypeParam) == "table" then
        selectHpZero = targetTypeParam[1] or 1
    end

    local maxVal = 0
    local maxTarget = {}
    local globalMonsterGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(globalMonsterGroup) do
        if (not e:HasDeadMark()) and (self:SelectConditionFilter(e)) then
            local cBuff = e:BuffComponent()
            local buffArray = cBuff:GetBuffArray()
            local count = 0
            for _, instance in ipairs(buffArray) do
                local buffID = instance:BuffID()
                local cfgBuff = Cfg.cfg_buff[buffID]
                if cfgBuff.ShowBuffIcon then
                    count = count + 1
                end
            end

            local isHPValid = true
            if selectHpZero == 0 then
                local percent = self:_GetHPPercent(e)
                isHPValid = percent > 0
            end

            if isHPValid then
                if (maxVal == count) then
                    table.insert(maxTarget, e:GetID())
                elseif count > maxVal then
                    maxTarget = {}
                    maxVal = count
                    table.insert(maxTarget, e:GetID())
                end
            end
        end
    end

    if #maxTarget == 0 then
        return {}
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local idx = utilScopeSvc:_GetRandomNumber(1, #maxTarget)

    return {maxTarget[idx]}
end
---@param casterEntity Entity
function SkillScopeTargetSelector:_SelectMySpecificTrapOrAnyMonster(
    casterEntity,
    skillScopeResult,
    skillID,
    targetTypeParam)
    local arr = {}
    local specificTrapIds = {}
    if targetTypeParam and type(targetTypeParam) == "table" then
        specificTrapIds = targetTypeParam
    end
    --Trap
    local listTrapMap = self:_SelectTrap(casterEntity, skillScopeResult, skillID, targetTypeParam, false)
    if listTrapMap then
        for id, trapEntity in pairs(listTrapMap) do
            local cTrap = trapEntity:Trap()
            local trapId = cTrap:GetTrapID()
            if trapEntity:HasSummoner() then
                local summonerEntityID = trapEntity:Summoner():GetSummonerEntityID()
                if summonerEntityID == casterEntity:GetID() and table.icontains(specificTrapIds, trapId) then
                    table.insert(arr, id)
                end
            end
        end
    end
    if #arr > 0 then
        --找到机关就不找怪了
        return arr
    end
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local es = self:_SelectAlignmentTargetEnemyTeam(casterEntity, skillScopeResult, skillID)
        table.appendArray(arr, es)
    else
        local monsters = self:_SelectMonster(casterEntity, skillScopeResult, skillID)
        table.appendArray(arr, monsters)
    end

    return arr
end

---选择非Boss的怪物
---@param casterEntity Entity 施法者
---@param skillScopeResult SkillScopeResult 技能的范围结果
---@param skillID number 技能ID
function SkillScopeTargetSelector:_SelectMonsterNotBoss(casterEntity, skillScopeResult, skillID, targetTypeParam)
    local targetIDArray = {}
    local attackRange = skillScopeResult:GetAttackRange()
    for _, skillRangePos in ipairs(attackRange) do
        local targetIDInSkillRangeList = self:_CalcMonsterInSkillRange(skillRangePos)
        for _, v in ipairs(targetIDInSkillRangeList) do
            if v > 0 then
                local monsterEntity = self._world:GetEntityByID(v)
                if not monsterEntity:HasBoss() then
                    targetIDArray[#targetIDArray + 1] = v
                end
            end
        end
    end

    if targetTypeParam and type(targetTypeParam) == "table" and table.count(targetTypeParam) > 0 then
        local targetCount = targetTypeParam[1] or 1
        --给懒的改配置的策划做容错，不写默认值是0，Ai默认值是0。如果是0默认找所有，就是999
        if targetCount == 0 then
            targetCount = 999
        end
        local newTargetIDArray = {}
        for i = 1, table.count(targetIDArray) do
            if i <= targetCount then
                table.insert(newTargetIDArray, targetIDArray[i])
            end
        end
        targetIDArray = newTargetIDArray
    end

    return targetIDArray
end

function SkillScopeTargetSelector:_SelectLastChainSkillRandomNMonster(casterEntity, skillScopeResult, skillID, param)
    if casterEntity:HasSuperEntity() then
        casterEntity = casterEntity:GetSuperEntity()
    end

    local monsterIdList = {}

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    local chainAttackDataList = petAttackDataCmpt:GetChainAttackDataList()
    if chainAttackDataList then
        for k, skillChainAttackData in ipairs(chainAttackDataList) do
            ---@type SkillChainAttackData
            local attdata = skillChainAttackData
            local damageResultArray = attdata:GetEffectResultByArrayAll(SkillEffectType.Damage)
            if damageResultArray then
                for k, res in ipairs(damageResultArray) do
                    local targetEntityID = res:GetTargetID()
                    if targetEntityID > 0 and not table.intable(monsterIdList, targetEntityID) then
                        table.insert(monsterIdList, targetEntityID)
                    end
                end
            end
        end
    end

    local ids = {}
    if monsterIdList and table.count(monsterIdList) > 0 then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local count = param[1]
        if count and count > 0 then
            for i = 1, count do
                if #monsterIdList == 0 then
                    break
                end
                local rate = param[1 + i]
                local needCal = false
                if rate >= 1 then
                    needCal = true
                else
                    local randomNum = utilScopeSvc:_GetRandomNumber()
                    needCal = (rate > randomNum)
                end
                if needCal then
                    local idx = utilScopeSvc:_GetRandomNumber(1, table.count(monsterIdList))
                    table.insert(ids, monsterIdList[idx])
                    table.remove(monsterIdList, idx)
                end
            end
        end
    end
    return ids
end

function SkillScopeTargetSelector:_SelectBuffLayerMostAndHighestHP(casterEntity, skillScopeResult, skillID, param)
    local targetIDArray = {}
    local targetBuffEffect = param[1] or 0

    local es = {}
    local monsters = self._world:GetGroupEntities(self._world.BW_WEMatchers.AliveMonster)
    for _, monster in ipairs(monsters) do
        ---@type BuffComponent
        local buffComponent = monster:BuffComponent()
        if buffComponent then
            if buffComponent:HasBuffEffect(targetBuffEffect) then
                table.insert(es, monster)
            end
        end
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    if table.count(es) > 0 then
        ---@type BuffLogicService
        local buffLogicService = self._world:GetService("BuffLogic")

        table.sort(
            es,
            function(a, b)
                local buffLayerA = buffLogicService:GetBuffLayer(a, targetBuffEffect)
                local buffLayerB = buffLogicService:GetBuffLayer(b, targetBuffEffect)

                if buffLayerA == buffLayerB then
                    local hpA = a:Attributes():GetCurrentHP()
                    local hpB = b:Attributes():GetCurrentHP()
                    return hpA > hpB
                end
                return buffLayerA > buffLayerB
            end
        )

        local mostBuffLayer = 0
        local mostHP = 0

        local randomEntityList = {}

        for i, e in ipairs(es) do
            local curBuffLayer = buffLogicService:GetBuffLayer(e, targetBuffEffect)
            local curHP = e:Attributes():GetCurrentHP()

            if i == 1 then
                if curBuffLayer == 0 then
                    break
                end
                mostBuffLayer = curBuffLayer
                mostHP = curHP
            else
                if mostBuffLayer == curBuffLayer and mostHP == curHP then
                    table.insert(randomEntityList, e)
                end
            end
        end

        if table.count(randomEntityList) > 0 then
            table.insert(randomEntityList, es[1])
            local idx = utilScopeSvc:_GetRandomNumber(1, table.count(randomEntityList))
            local monster = randomEntityList[idx]
            table.insert(targetIDArray, monster:GetID())
        else
            table.insert(targetIDArray, es[1]:GetID())
        end
    end

    if table.count(es) == 0 and table.count(monsters) > 0 then
        targetIDArray = self:_SelectNearestMonster(casterEntity, skillScopeResult, skillID, param)
    end

    return targetIDArray
end

function SkillScopeTargetSelector:_SelectMonsterAroundDamageTarget(casterEntity, skillScopeResult, skillID, param)
    local targetIDArray = {}
    local selectCount = param[1] or -1

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local preDamageStageIndex = 1
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, preDamageStageIndex)
    if not damageResultArray or table.count(damageResultArray) == 0 then
        return targetIDArray
    end
    ---@type RandomServiceLogic
    local randomService = self._world:GetService("RandomLogic")
    for _, v in ipairs(damageResultArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local targetEntityID = damageResult:GetTargetID()
        local defenderEntity = self._world:GetEntityByID(targetEntityID)
        if defenderEntity then
            local monsterIDListAroundDefender = {}
            local defenderBodyArea = defenderEntity:BodyArea():GetArea()
            local bodyAreaCount = #defenderBodyArea
            local onlyMaxRing = true
            local ringCount = 1
            local defenderPos = defenderEntity:GetGridPosition()
            local defenderRingPosList = ComputeScopeRange.ComputeRange_SquareRing(defenderPos, bodyAreaCount, ringCount,onlyMaxRing)
            for index, ringPos in ipairs(defenderRingPosList) do
                local withDead = false
                local targetEntityIDs = self:_FindTargetEntityInPos(ringPos, withDead)
                if #targetEntityIDs > 0 then
                    for idIndex, targetEntityID in ipairs(targetEntityIDs) do
                        if not table.icontains(monsterIDListAroundDefender,targetEntityID) then
                            table.insert(monsterIDListAroundDefender,targetEntityID)
                        end
                    end
                    --table.appendArray(monsterIDListAroundDefender, targetEntityIDs)
                end
            end
            if #monsterIDListAroundDefender > 0 then
                if (selectCount == -1) or (selectCount >= #monsterIDListAroundDefender) then--全部
                    table.appendArray(targetIDArray,monsterIDListAroundDefender)
                else
                    monsterIDListAroundDefender = randomService:Shuffle(monsterIDListAroundDefender)
                    for monsterIndex, monsterID in ipairs(monsterIDListAroundDefender) do
                        if monsterIndex <= selectCount then
                            table.insert(targetIDArray,monsterID)
                        else
                            break
                        end
                    end
                end
            end
        end
    end
    return targetIDArray
end
---@param casterEntity Entity
---@param skillScopeResult SkillScopeResult
function SkillScopeTargetSelector:_SelectWorldBossMonster(casterEntity, skillScopeResult)
    local targetIDArray = {}
    local listTargetByRange = self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.MonsterID, skillScopeResult:GetAttackRange())
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        local monsterEntity = value.m_entity
        local monsterIdCmpt = monsterEntity:MonsterID()
        if monsterIdCmpt then
            local isWorldBoss = monsterIdCmpt:IsWorldBoss()
            if isWorldBoss then
                local id = monsterEntity:GetID()
                table.insert(targetIDArray,id)
            end
        end
    end
    return targetIDArray
end

---@param casterEntity Entity
---@param skillScopeResult SkillScopeResult
function SkillScopeTargetSelector:_SelectSingleGridMonsterLowestHPPercent(casterEntity, skillScopeResult)
    local listTargetByRange = self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.MonsterID, skillScopeResult:GetAttackRange())

    local lowestHPPercent = 1
    local lowestHPEntity
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        local monsterEntity = value.m_entity
        if (not monsterEntity:HasDeadMark()) and (monsterEntity:GetID() ~= casterEntity:GetID()) then
            local bodyArea = monsterEntity:BodyArea():GetArea()
            if #bodyArea == 1 then
                local cAttribute = monsterEntity:Attributes()
                local maxHP = cAttribute:CalcMaxHp()
                local currentHP = cAttribute:GetCurrentHP()
                local percent = currentHP / maxHP
                -- 需求上不强求结果一定是随机的，因此只拿计算逻辑上的第一个
                if percent < lowestHPPercent then
                    lowestHPPercent = percent
                    lowestHPEntity = monsterEntity
                end
            end
        end
    end

    local ret = {}
    if lowestHPEntity then
        ret[1] = lowestHPEntity:GetID()
    end

    return ret
end



function SkillScopeTargetSelector:_SelectMonsterCamp(casterEntity, skillScopeResult, skillID, param)
    local listTargetByRange = self:_SelectEntityByTypeAndRange(self._world.BW_WEMatchers.MonsterID, skillScopeResult:GetAttackRange())
    local ret ={}
    ---@param value SkillScopeTargetData
    for key, value in ipairs(listTargetByRange) do
        ---@type Entity
        local monsterEntity = value.m_entity
        if not monsterEntity:HasDeadMark() then
            ---@type MonsterIDComponent
            local monsterIDCmpt =monsterEntity:MonsterID()
            local campType = monsterIDCmpt:GetCampType()
            if table.icontains(param, campType) then
                table.insert(ret,monsterEntity:GetID())
            end
        end
    end

    return ret
end
