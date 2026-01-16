require("pick_up_policy_base")

_class("PickUpPolicy_PetYuSen", PickUpPolicy_Base)
---@class PickUpPolicy_PetYuSen: PickUpPolicy_Base
PickUpPolicy_PetYuSen = PickUpPolicy_PetYuSen

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetYuSen:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    --结果
    local env = self:_GetPickUpPolicyEnv()
    local casterPos = petEntity:GridLocation().Position
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    --获取技能中配置的机关ID
    local trapID = 0
    ---@type SkillSummonTrapEffectParam
    local stpSummonTrap = nil
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local skillEffectArray = skillConfigData:GetSkillEffect()
    for _, skillEffect in ipairs(skillEffectArray) do
        if skillEffect:GetEffectType() == SkillEffectType.SummonTrap then
            stpSummonTrap = skillEffect
            trapID = stpSummonTrap:GetTrapID()
            if type(trapID) == "table" then
                trapID = trapID[1]
            end
            break
        end
    end

    --获取攻击目标
    ---@type Entity[]
    local targetEntityList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
        table.insert(targetEntityList, enemyTeam)
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(targetEntityList, monsterEntity)
            end
        end
    end

    --获取雨森召唤的机关（刀）
    ---@type Entity[]
    local trapEntityList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID and e:HasSummoner() and
            e:Summoner():GetSummonerEntityID() == petEntity:GetID()
        then
            table.insert(trapEntityList, e)
        end
    end

    --检查目标周围一圈是否存在召唤的机关并保存机关格子
    local pickupPosList = {}
    for _, targetEntity in pairs(targetEntityList) do
        ---@type Vector2[]
        local posList = self:GetPosListAroundBodyArea(targetEntity, 1)
        for _, trapEntity in pairs(trapEntityList) do
            ---@type Vector2
            local trapPos = trapEntity:GridLocation():GetGridPos()
            if table.icontains(posList, trapPos) then
                ---@type BoardComponent
                local boardCmpt = self._world:GetBoardEntity():Board()
                local es =
                boardCmpt:GetPieceEntities(
                    trapPos,
                    function(e)
                        return e:HasTeam() or e:HasMonsterID()
                    end
                )
                if #es == 0 and not boardService:IsPosBlock(trapPos, BlockFlag.LinkLine) then
                    table.insert(pickupPosList, trapPos)
                end
            end
        end
    end

    local pickPosList = {}
    --雨森主动技为伤害技能，需有一个目标，此处特殊处理，将自身填充进目标，只为计数，不会作为目标ID使用
    local targetIDs = {}
    table.insert(targetIDs, petEntity:GetID())

    --格子数量>0, 随机一个，并返回
    if #pickupPosList > 0 then
        pickPosList = table.randomn(pickupPosList, 1)
        return pickPosList, pickPosList, targetIDs
    end

    --找到距离玩家最近的目标
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeTargetSelector
    local tarSelector = self._world:GetSkillScopeTargetSelector()
    local posList = utilSvc:GetCloneBoardGridPos()
    ---@type SkillScopeResult
    local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, petEntity, posList, posList)
    local nearstTargetIDs = tarSelector:DoSelectSkillTarget(petEntity, SkillTargetType.NearestMonster, skillScopeResult)
    if #nearstTargetIDs < 1 then
        return pickPosList, pickPosList, targetIDs
    end
    local targetID = nearstTargetIDs[1]
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)

    --怪物周围一圈距离玩家最近的可召唤机关的点
    ---@type Vector2[]
    local posList = self:GetPosListAroundBodyArea(targetEntity, 1)
    for _, pickPos in pairs(posList) do
        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        if stpSummonTrap:GetBlock() == 0 or trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
            table.insert(pickupPosList, pickPos)
        end
    end
    HelperProxy:SortPosByCenterPosDistance(casterPos, pickupPosList)
    for i = 2, #pickupPosList do
        pickupPosList[i] = nil
    end
    return pickupPosList, pickupPosList, targetIDs
end