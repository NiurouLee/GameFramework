--[[------------------------------------------------------------------------------------------
    ChainPathTargetSelector :划线目标选择器，
    根据连线，选择队伍，并为出战队伍的每一位成员选择攻击目标
    局内玩法的核心对象之一
]] --------------------------------------------------------------------------------------------

_class("ChainPathTargetSelector", Object)
---@class ChainPathTargetSelector: Object
ChainPathTargetSelector = ChainPathTargetSelector

---@param world MainWorld
function ChainPathTargetSelector:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillScopeTargetSelector
    self._skillScopeTargetSelector = world:GetSkillScopeTargetSelector()
end

---选择出战队伍
---@param teamEntity Entity 玩家Entity
---@param pieceType PieceType 划线颜色
function ChainPathTargetSelector:DoSelectTeam(teamEntity, pieceType)
    self:_SelectRoundTeam(teamEntity, pieceType, SkillType.Normal)
end

---@param teamEntity Entity 玩家Entity
---@param pieceType PieceType 划线颜色
function ChainPathTargetSelector:DoSelectTarget(teamEntity, pieceType)
    self:_SelectRoundTeam(teamEntity, pieceType, SkillType.Chain)

    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petRoundTeam = logicTeamCmpt:GetPetRoundTeam()

    for _, petEntityID in ipairs(petRoundTeam) do
        local pet_entity = self._world:GetEntityByID(petEntityID)
        ---@type SkillPetAttackDataComponent
        local petAttackDataCmpt = pet_entity:SkillPetAttackData()
        --连锁技每次都要重算
        petAttackDataCmpt:ClearPetChainAttackData()
        ---@type BuffComponent
        local petBuffCmpt = pet_entity:BuffComponent()
        local chain_count = petBuffCmpt:GetBuffValue("ChainSkillCount") or 1
        --根据buff  计算多次连锁技
        for idx = 1, chain_count do
            --为当前宝宝选取连锁技攻击列表
            self:_CalcChainSkillAttackTarget(teamEntity, petEntityID, idx)
        end
    end
end

---选择普攻目标
---在客户端每次连接到一个点，在客户端由于要表现连锁技是否能攻击到目标
---因此都会执行一次连锁技目标选择操作
---在服务端，连接到一个点并没有同步，因此在执行抬手操作时，会先算普攻，再算连锁技
function ChainPathTargetSelector:DoSelectNormalAttackTarget(teamEntity)
    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petRoundTeam = logicTeamCmpt:GetPetRoundTeam()

    for _, petEntityID in ipairs(petRoundTeam) do
        --为当前宝宝选取普通攻击列表
        self:_CalcPathNormalAttackTarget(teamEntity, petEntityID)
    end
end

---根据连线，选择出战队伍
---@param teamEntity Entity
---@param pieceType PieceType
function ChainPathTargetSelector:_SelectRoundTeam(teamEntity, pieceType, skillType)
    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()

    ---先清空队列
    logicTeamCmpt:ClearLogicRoundTeam()

    --先把队长加进去
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    ---@type Entity
    local teamLeaderEntity = self._world:GetEntityByID(teamLeaderEntityID)
    logicTeamCmpt:AddPetToRoundTeam(teamLeaderEntityID)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = teamLeaderEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:SetFinalAttack(false)
    skillEffectResultContainer:SetNormalAttack(false)

    ---@type ElementComponent
    local playerElementCmpt = teamLeaderEntity:Element()

    ---@type AffixService
    local affixSvc = self._world:GetService("Affix")
    if affixSvc:IsTeamLeaderUseSecondaryType(teamEntity, pieceType) then
        self:SelectPetPrimarySecondaryParam(teamLeaderEntity, pieceType, PrimarySecondaryParamType.Pet)
        playerElementCmpt:SetUseSecondaryType(true)
    else
        self:SelectPetPrimarySecondaryParam(teamLeaderEntity, pieceType, PrimarySecondaryParamType.TeamLeader)
        playerElementCmpt:SetUseSecondaryType(false)
    end
    ---计算双色连线时的第一个非万色颜色
    local firstElementType = self:_CalcFirstElementTypeForTwoColorChain(teamEntity,pieceType)
 
    local teamOrder = teamEntity:Team():GetTeamOrder()
    for i = 2, #teamOrder do
        local petPstID = teamOrder[i]
        local entityID = self:_CheckPetBattle(petPstID, pieceType, teamEntity)
        if entityID ~= nil then
            logicTeamCmpt:AddPetToRoundTeam(entityID)
        else
            --强制连锁连锁出战插入出战队列
            local forceChainEntityID = self:_CheckPetBattleForceChain(petPstID, pieceType, teamEntity, skillType)
            if forceChainEntityID ~= nil then
                logicTeamCmpt:AddPetToRoundTeam(forceChainEntityID)
            end

            if firstElementType ~= PieceType.None then 
                local firstElementEntityID = self:_CheckPetBattle(petPstID, firstElementType, teamEntity)
                if firstElementEntityID ~= nil then 
                    logicTeamCmpt:AddPetToRoundTeam(firstElementEntityID)
                end
            end
        end
    end

    --排序，根据buff设置的优先级强制排序
    local changeOrderList = {}
    local orderBuffKey = "PetRoundTeamOrder_" .. skillType
    local normalOrder = 100 --默认值100+
    local hasChangrOrder = false
    local petRoundTeam = teamEntity:LogicRoundTeam():GetPetRoundTeam()

    ---@type SortedArray
    local sortedArray = SortedArray:New(Algorithm.COMPARE_LESS, nil)

    for petIndex = 1, #petRoundTeam do
        local petEntityID = petRoundTeam[petIndex]
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        ---@type BuffComponent
        local buffCmpt = petEntity:BuffComponent()
        local orderBuffValue = buffCmpt:GetBuffValue(orderBuffKey)
        if orderBuffValue then
            changeOrderList[orderBuffValue] = petEntityID
            hasChangrOrder = true
            sortedArray:Insert(orderBuffValue)
        else
            changeOrderList[normalOrder] = petEntityID
            sortedArray:Insert(normalOrder)
            normalOrder = normalOrder + 1
        end
    end
    if hasChangrOrder then
        logicTeamCmpt:ClearLogicRoundTeam()
        teamEntity:Team():SetOriginalTeamLeaderID(teamLeaderEntityID)
        local setTeamLeader = false
        for i = 1, sortedArray:Size() do
            local keySort = sortedArray:GetAt(i)
            local petEntityID = changeOrderList[keySort]
            if not setTeamLeader then
                setTeamLeader = true
                ---@type Entity
                local petEntity = self._world:GetEntityByID(petEntityID)
                teamEntity:SetTeamLeaderPetEntity(petEntity)
            end
            logicTeamCmpt:AddPetToRoundTeam(petEntityID)
        end
    end
end

function ChainPathTargetSelector:_CalcFirstElementTypeForTwoColorChain(teamEntity,cmdElementType)
    local firstElementType = PieceType.None
    
    local isTwoColorChain = self:IsTwoColorChain(teamEntity)
    if not isTwoColorChain then 
        return firstElementType
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPathData = logicChainPathCmpt:GetLogicChainPath()
    for chainIndex,v in ipairs(chainPathData) do 
        local curPieceType = boardCmpt:GetPieceType(v)
        if chainIndex == 2 then --连线第一步视为某种颜色
            local firstLinkMapPiece = utilDataSvc:GetMapForFirstChainPath()
            if firstLinkMapPiece then
                curPieceType = firstLinkMapPiece
            end
        end
        if curPieceType ~= PieceType.None and curPieceType ~= PieceType.Any and curPieceType ~= cmdElementType then 
            firstElementType = curPieceType
			break
        end
    end

    return firstElementType
end

function ChainPathTargetSelector:IsTwoColorChain(teamEntity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local useTwoColorChain = utilDataSvc:GetEntityBuffValue(teamEntity,"TwoColorChain")

    return useTwoColorChain
end

function ChainPathTargetSelector:_CheckPetBattleForceChain(petPstID, pieceType, teamEntity, skillType)
    --强制连锁不管普攻出战
    if skillType == SkillType.Normal then
        return
    end

    local e = teamEntity:Team():GetPetEntityByPetPstID(petPstID)
    if not e:HasPetDeadMark() then
        if e:HasBuffFlag(BuffFlags.SealedCurse) then
            goto CHAINPATHTARGETSELECTOR_CHECKPETBATTLE_SEALEDCURSE_CONTINUE
        end

        ---@type BuffComponent
        local buffComponent = e:BuffComponent()
        local petForceChain = buffComponent:GetBuffValue("PetForceChain") == 1

        if petForceChain then
            --强制连锁出战的一定使用主属性，这里要把前面如果通过副属性检测的星灵，设置回主属性
            ---@type ElementComponent
            local elementCmpt = e:Element()
            elementCmpt:SetUseSecondaryType(false)

            -- self:SelectPetPrimarySecondaryParam(e, pieceType, PrimarySecondaryParamType.Pet)
            e:Attributes():Modify("PrimarySecondaryParam", BattleConst.PrimarySecondaryDefaultParam)

            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = e:SkillContext():GetResultContainer()
            skillEffectResultContainer:SetFinalAttack(false)
            skillEffectResultContainer:SetNormalAttack(false)
            return e:GetID()
        end
        ::CHAINPATHTARGETSELECTOR_CHECKPETBATTLE_SEALEDCURSE_CONTINUE::
    end
    return nil
end

---检查星灵是否要加入本次回合的战斗队伍
---@param petPstID number
---@param teamEntity Entity
function ChainPathTargetSelector:_CheckPetBattle(petPstID, pieceType, teamEntity)
    local e = teamEntity:Team():GetPetEntityByPetPstID(petPstID)

    if not e:HasPetDeadMark() then
        if e:HasBuffFlag(BuffFlags.SealedCurse) then
            goto CHAINPATHTARGETSELECTOR_CHECKPETBATTLE_SEALEDCURSE_CONTINUE
        end
        ---@type ElementComponent
        local elementCmpt = e:Element()
        local primaryType = elementCmpt:GetPrimaryType()
        local sencondardType = elementCmpt:GetSecondaryType()

        local primaryMatch = CanMatchPieceType(primaryType, pieceType)
        local secondaryMatch = CanMatchPieceType(sencondardType, pieceType)
        ---@type BuffComponent
        local buffComponent = e:BuffComponent()
        local petForceChain = buffComponent:GetBuffValue("PetForceChain") == 1
        ---检查强制使用主属性
        local forceMatch = buffComponent:GetBuffValue("PetForceMatch")
        if forceMatch then 
            primaryMatch = true
        end

        if primaryMatch or secondaryMatch then
            if petForceChain or forceMatch then
                elementCmpt:SetUseSecondaryType(false)
            elseif primaryMatch == true then
                elementCmpt:SetUseSecondaryType(false)
            elseif secondaryMatch == true then
                elementCmpt:SetUseSecondaryType(true)
            end

            self:SelectPetPrimarySecondaryParam(e, pieceType, PrimarySecondaryParamType.Pet, petForceChain)
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = e:SkillContext():GetResultContainer()
            skillEffectResultContainer:SetFinalAttack(false)
            skillEffectResultContainer:SetNormalAttack(false)

            return e:GetID()
        end

        ::CHAINPATHTARGETSELECTOR_CHECKPETBATTLE_SEALEDCURSE_CONTINUE::
    end

    return nil
end

---遍历划线队列，为宝宝在每个划线点的普通攻击选目标
---@param teamEntity Entity
---@param petEntityID number
function ChainPathTargetSelector:_CalcPathNormalAttackTarget(teamEntity, petEntityID)
    local petEntity = self._world:GetEntityByID(petEntityID)
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = petEntity:SkillPetAttackData()

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPathData = logicChainPathCmpt:GetLogicChainPath()
    local chainPathType = logicChainPathCmpt:GetLogicPieceType()
    local posActor = teamEntity:GetGridPosition()

    for chainPathIndex, piecePosition in ipairs(chainPathData) do
        local hasAttackData = petAttackDataCmpt:HasNormalAttackData(piecePosition)
        if not hasAttackData then
            --Log.fatal("_CalcPathNormalAttackTarget add piece_location ",piecePosition.x," ",piecePosition.y," ",pet_entity_id)
            local pathPointNormalAttackData = SkillPathPointNormalAttackData:New(self._world)
            petAttackDataCmpt:AddNormalAttackData(piecePosition, pathPointNormalAttackData)
            self:_CalcPathPointNormalAttackTarget(
                teamEntity,
                petEntityID,
                piecePosition,
                pathPointNormalAttackData,
                chainPathType,
                chainPathData,
                chainPathIndex
            )
        end
    end

    --处理回退的情况，删掉上次连接，但本次没有连接的点数据
    petAttackDataCmpt:RemoveUnusedPathPointData(chainPathData)
end

--在单个划线点为宝宝的普通攻击选目标
---@param petEntityID number 攻击者的ID
---@param casterPos Vector2 选目标的位置
---@param pathPointNormalAttackData SkillPathPointNormalAttackData 要存放攻击数据的对象
function ChainPathTargetSelector:_CalcPathPointNormalAttackTarget(
    teamEntity,
    petEntityID,
    casterPos,
    pathPointNormalAttackData,
    chainPathType,
    chainPath,
    chainPathIndex)
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    if petEntityID == teamLeaderEntityID then
        ---@type AffixService
        local affixSvc = self._world:GetService("Affix")
        if not affixSvc:IsTeamLeaderCanAttack(teamEntity, chainPathType) then
            return
        end
    end
	
    --原本该位置是阻挡连线的，因为有特殊buff进入了连线。那么该位置只是可以走，并不能选择目标攻击
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if utilData:IsPosBlock(casterPos, BlockFlag.LinkLine) then
        return
    end
	
    local pet_entity = self._world:GetEntityByID(petEntityID)

    --取出宝宝的普通攻击技能ID
    ---@type SkillInfoComponent
    local skill_info_cmpt = pet_entity:SkillInfo()
    local normal_skill_id = skill_info_cmpt:GetNormalSkillID()
    local canRepeatAdd = false

    --这里只是计算，不是实际改变普攻，实际改变SetNormalSkillID在普攻计算器
    ---@type BuffComponent
    local petBuffCmpt = pet_entity:BuffComponent()
    local calcChainPathRightAngle = petBuffCmpt:GetBuffValue("ChangeNormalSkillIDWithChainPathRightAngle")
    if calcChainPathRightAngle then
        normal_skill_id = calcChainPathRightAngle[1]
        canRepeatAdd = true

        if chainPathIndex > 1 and chainPathIndex < table.count(chainPath) then
            --上一步移动到当前这步的朝向
            local lastPos = chainPath[chainPathIndex - 1]
            local lastDir = casterPos - lastPos

            --真实的下个坐标
            local nextPos = chainPath[chainPathIndex + 1]
            local curDir = nextPos - casterPos

            local diffAngle = Vector2.Angle(lastDir, curDir)
            --四舍五入取整 精度问题
            diffAngle = math.floor(diffAngle + 0.5)

            if diffAngle >= 90 then
                normal_skill_id = calcChainPathRightAngle[2]
            end
        end
    end

    --
    local calcBuffLayerAndTrap = petBuffCmpt:GetBuffValue("ChangeNormalSkillWithBuffLayerAndTrap")
    if calcBuffLayerAndTrap then
        local curLayerCount = calcBuffLayerAndTrap.curLayerCount
        local trapIDs = calcBuffLayerAndTrap.trapIDs
        local addLayer = calcBuffLayerAndTrap.addLayer

        ---@type UtilDataServiceShare
        local udsvc = self._world:GetService("UtilData")
        local findTrap = false
        local traps = udsvc:GetTrapsAtPos(casterPos)
        if traps then
            for index, e in ipairs(traps) do
                if table.intable(trapIDs, e:Trap():GetTrapID()) then
                    findTrap = true
                    break
                end
            end
        end

        if findTrap then
            curLayerCount = curLayerCount + addLayer
            if curLayerCount < 0 then
                curLayerCount = 0
            end
            calcBuffLayerAndTrap.curLayerCount = curLayerCount
        end

        local skillList = calcBuffLayerAndTrap.skillList
        for k, v in pairs(skillList) do --不能改ipairs
            if curLayerCount <= k then
                normal_skill_id = v
                break
            end
        end

        petBuffCmpt:SetBuffValue("ChangeNormalSkillWithBuffLayerAndTrap", calcBuffLayerAndTrap)
    end

    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(normal_skill_id)
    local skillTargetType = skillConfigData:GetSkillTargetType()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    --Log.fatal("_CalcPathPointNormalAttackTarget for ",petEntityID, " caster pos ",casterPos.x," ",casterPos.y)
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, pet_entity)
    local skill_range_grid_list = scopeResult:GetAttackRange()
    --因为取出来是乱序的  会造成在8方向的时候  斜方向在前  十字方向在后。十字的技能伤害就计算不成功
    --排序 先十字 后X字
    skill_range_grid_list = HelperProxy:SortPosByCenterArrow(casterPos, skill_range_grid_list)
    local targetEntities = nil
    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntities = {self._world:Player():GetCurrentEnemyTeamEntity()}
    else
        local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        targetEntities = monster_group:GetEntities()
    end
    --为每个攻击到的格子统计目标entity

    if pet_entity:BuffComponent():GetBuffValue("ForcePetNormalAttackAfterMove") then
        for i = 2, #chainPath do
            local v2 = chainPath[i]
            pathPointNormalAttackData:AddAttackGridDataOnlyCheckPos(
                    v2,
                    petEntityID,
                    normal_skill_id,
                    petEntityID,
                    casterPos
            )
        end
    else
        for _, e in ipairs(targetEntities) do
            if self._skillScopeTargetSelector:SelectConditionFilter(e, true) then
                local monster_grid_location_cmpt = e:GridLocation()
                local monster_body_area_cmpt = e:BodyArea()
                local monster_body_area = monster_body_area_cmpt:GetArea()
                if canRepeatAdd then
                    for i, bodyArea in ipairs(monster_body_area) do
                        local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                        if table.icontains(skill_range_grid_list, curMonsterBodyPos) then
                            --添加普攻数据有2个条件。targetID没被添加过  beHitPos没被添加过
                            --这个参数表述不检查重复的targetID，只要beHitPos不重复就可以（需求是一个普攻打周围一圈怪物，可以给四格怪物攻击2次）
                            pathPointNormalAttackData:AddAttackGridDataOnlyCheckPos(
                                curMonsterBodyPos,
                                e:GetID(),
                                normal_skill_id,
                                petEntityID,
                                casterPos
                            )
                        end
                    end
                else
                    local attackPosCandidate = {}
                    for i, bodyArea in ipairs(monster_body_area) do
                        local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
                        if table.icontains(skill_range_grid_list, curMonsterBodyPos) then
                            -- 对同一个单位进行普攻时，位置选择具有优先级，因此先记录...
                            table.insert(attackPosCandidate, {
                                index = table.ikey(skill_range_grid_list, curMonsterBodyPos),
                                pos = curMonsterBodyPos,
                                sortIndex = #attackPosCandidate
                            })
                        end
                    end
                    if #attackPosCandidate > 0 then
                        -- ...再排序...
                        table.sort(attackPosCandidate, function (a, b)
                            if a.index ~= b.index then
                                return a.index < b.index
                            else
                                return a.sortIndex < b.sortIndex
                            end
                        end)
                        -- ...再选择
                        local finalAttackPos = attackPosCandidate[1].pos
                        pathPointNormalAttackData:AddAttackGridData(
                            finalAttackPos,
                            e:GetID(),
                            normal_skill_id,
                            petEntityID,
                            casterPos
                        )
                    end
                end
            end
        end
    end
end

---为宝宝的连锁技选取攻击格子
function ChainPathTargetSelector:_CalcChainSkillAttackTarget(teamEntity, petEntityID, idx)
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chain_path_data = logicChainPathCmpt:GetLogicChainPath()
    local chain_path_count = #chain_path_data
    local chain_rate = logicChainPathCmpt:GetChainRateAtIndex(chain_path_count)

    ---@type Entity
    local pet_entity = self._world:GetEntityByID(petEntityID)
    ---@type SkillInfoComponent
    local skill_info_cmpt = pet_entity:SkillInfo()

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = pet_entity:SkillPetAttackData()

    ---@type SkillEffectResultContainer
    local petSkillRoutine = pet_entity:SkillContext():GetResultContainer()
    --连锁技每次都要重算
    -- petAttackDataCmpt:ClearPetChainAttackData()

    local chainCountFix = pet_entity:Attributes():GetAttribute("ChainSkillReleaseFix")
    local chainCountMul = pet_entity:Attributes():GetAttribute("ChainSkillReleaseMul")
    local realChainCount = math.ceil((chain_rate + chainCountFix) * (1 + chainCountMul))
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local chainExtraFix = utilData:GetEntityBuffValue(pet_entity, "ChangeExtraChainSkillReleaseFixForSkill")
    local chain_skill_config_id = skill_info_cmpt:GetChainSkillConfigID(realChainCount, chainExtraFix)
    if chain_skill_config_id <= 0 then
        return
    end
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = pet_entity:SkillPetAttackData()
    petAttackDataCmpt:SetChainSkillID(chain_skill_config_id)
    petSkillRoutine:SetSkillID(chain_skill_config_id)
    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(chain_skill_config_id)
    local skillTargetType = skillConfigData:GetSkillTargetType()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    --取划线路径的最后一个点
    local caster_pos = chain_path_data[chain_path_count]

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    ---@type BuffLogicService
    local buffService = self._world:GetService("BuffLogic")
    if buffService:IsChainSkillUseChainScope(pet_entity) and not self._world:BattleStat():IsCastChainByDimensionDoor() then
        local chainPathPieceType = logicChainPathCmpt:GetLogicPieceType()
        boardCmpt:AddTmpPieceType(chain_path_data[1],PieceType.None)
        for i = 2, #chain_path_data do
            local pos = chain_path_data[i]
            boardCmpt:AddTmpPieceType(pos,chainPathPieceType)
        end
    end
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, caster_pos, pet_entity)
    local attack_range = scopeResult:GetAttackRange()
    local whole_range = scopeResult:GetWholeGridRange()
    boardCmpt:ClearTmpPieceType()
    ---@type BuffComponent
    local petBuffCmpt = pet_entity:BuffComponent()
    petAttackDataCmpt:SetCastChainSkill(false)

    --为每个攻击到的格子统计目标entity
    petAttackDataCmpt:AddChainAttackData(idx)
    local chainAttackData = petAttackDataCmpt:GetChainAttackData(idx)
    chainAttackData:SetScopeResult(scopeResult)

    self:_SelectScopeResultTarget(pet_entity, skillTargetType, scopeResult, chain_skill_config_id, attack_range)
end

---选择范围内的目标
---@param petEntity Entity 施法者
---@param targetType SkillTargetType 技能目标类型
---@param scopeResult SkillScopeResult 技能范围
---@param skillID number 施法技能ID
function ChainPathTargetSelector:_SelectScopeResultTarget(petEntity, targetType, scopeResult, skillID, attackRange)
    ---先选技能目标
    local targetEntityIDArray =
        self._skillScopeTargetSelector:DoSelectSkillTarget(petEntity, targetType, scopeResult, skillID)
    for _, gridPos in ipairs(attackRange) do
        for _, targetEntityID in ipairs(targetEntityIDArray) do
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            ---@type GridLocationComponent
            local gridLocationCmpt = targetEntity:GridLocation()
            ---@type BodyAreaComponent
            local bodyAreaCmpt = targetEntity:BodyArea()
            local bodyAreaList = bodyAreaCmpt:GetArea()

            for i, bodyArea in ipairs(bodyAreaList) do
                local curBodyPos =
                    Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                if curBodyPos == gridPos then
                    scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                end
            end
        end
    end
end

---@param petEntity Entity
function ChainPathTargetSelector:SelectPetPrimarySecondaryParam(petEntity, pieceType, type, petForceChain)
    ---@type ElementComponent
    local elementCmpt = petEntity:Element()
    local primaryType = elementCmpt:GetPrimaryType()
    local sencondardType = elementCmpt:GetSecondaryType()

    local primaryMatch = CanMatchPieceType(primaryType, pieceType)
    local secondaryMatch = CanMatchPieceType(sencondardType, pieceType)
    ---主副属性攻击系数
    local primarySecondaryParam = BattleConst.PrimarySecondaryDefaultParam

    ---@type BuffComponent
    local buffComponent = petEntity:BuffComponent()
    local forceMatch = buffComponent:GetBuffValue("PetForceMatch")
    if forceMatch then 
        primaryMatch = true
    end

    ---队长
    if type == PrimarySecondaryParamType.TeamLeader then
        ---队员
        if primaryMatch and not secondaryMatch then
            --Log.fatal("Leader primaryMatch and not secondaryMatch")
            primarySecondaryParam = BattleConst.LeaderPrimaryParam
        elseif not primaryMatch and secondaryMatch then
            --Log.fatal("Leader not primaryMatch and  secondaryMatch")
            primarySecondaryParam = BattleConst.LeaderSecondaryParam
        elseif primaryMatch and secondaryMatch then
            --Log.fatal("Leader primaryMatch and  secondaryMatch")
            primarySecondaryParam = BattleConst.LeaderAllParam
        elseif not primaryMatch and not secondaryMatch then
            primarySecondaryParam = BattleConst.LeaderNullParam
        --Log.fatal("Leader not primaryMatch and not secondaryMatch")
        end
    elseif type == PrimarySecondaryParamType.Pet then
        if primaryMatch and not secondaryMatch then
            --Log.fatal("Pet primaryMatch and not secondaryMatch")
            primarySecondaryParam = BattleConst.PetPrimaryParam
        elseif petForceChain then
            primarySecondaryParam = BattleConst.PrimarySecondaryDefaultParam
        elseif not primaryMatch and secondaryMatch then
            --Log.fatal("Pet not primaryMatch and  secondaryMatch")
            --primarySecondaryParam = BattleConst.PetSecondaryParam
            ---@type AttributesComponent
            local petAttriCmpt = petEntity:Attributes()
            primarySecondaryParam = petAttriCmpt:GetAttribute("SecondaryAttackParam")
        elseif primaryMatch and secondaryMatch then
            primarySecondaryParam = BattleConst.PetAllParam
        --Log.fatal("Pet primaryMatch and  secondaryMatch")
        end
    end

    --Log.debug(
    --    "SelectPetPrimarySecondaryParam,entityID:",
    --    entity:GetID(),
    --    " PieceType:",
    --    pieceType,
    --    " type:",
    --    type,
    --    " primaryMatch:",
    --    primaryMatch,
    --    " secondaryMatch:",
    --    secondaryMatch,
    --    " result:",
    --    primarySecondaryParam
    --)

    petEntity:Attributes():Modify("PrimarySecondaryParam", primarySecondaryParam)
end
