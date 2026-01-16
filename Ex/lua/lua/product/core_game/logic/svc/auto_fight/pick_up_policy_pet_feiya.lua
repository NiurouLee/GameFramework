require("pick_up_policy_base")

_class("PickUpPolicy_PetFeiYa", PickUpPolicy_Base)
---@class PickUpPolicy_PetFeiYa: PickUpPolicy_Base
PickUpPolicy_PetFeiYa = PickUpPolicy_PetFeiYa

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetFeiYa:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    --local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicyPetFeiYa(petEntity, activeSkillID)
    return pickPosList, atkPosList, targetIds, extraParam
end
--菲雅：能量>=2，释放两次主动技
---@param petEntity Entity
---@param activeSkillID number
function PickUpPolicy_PetFeiYa:_CalPickPosPolicyPetFeiYa(petEntity, activeSkillID)
    local pickPosList = {}
    local targetIDs = {}
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    --主动技释放次数检查
    ---@type AutoFightService
    local autoFightSvc = self._world:GetService("AutoFight")
    local castCount = autoFightSvc:GetCastActiveSkillCount()
    if castCount == 0 then
        --未释放过，需要当前能量值>=2才允许释放
        if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
            local legendPower = petEntity:Attributes():GetAttribute("LegendPower")
            local canCast = legendPower >= 2 * skillConfigData:GetSkillTriggerParam()
            if not canCast then
                autoFightSvc:SetCastActiveSkillCount(0)
                return pickPosList, pickPosList, targetIDs
            end
        end
    end

    --将所有怪物按血量排序
    ---@type Entity[]
    local enemyEntities = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for i, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            table.insert(enemyEntities, e)
        end
    end

    --黑拳赛特殊处理
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if petEntity then
        if petEntity:HasTeam() then
            teamEntity = petEntity
        elseif petEntity:HasPet() then
            teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        end
    end    
    if self._world:MatchType() == MatchType.MT_BlackFist then
        table.insert(enemyEntities, teamEntity:Team():GetEnemyTeamEntity())
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()

    local minHPEntityID = 0
    local minHP = MAX_INT_32
    local minHPEntityPos = nil
    for _, e in ipairs(enemyEntities) do
        ---@type GridLocationComponent
        local gridLocCmpt = e:GridLocation()
        local pickPos = gridLocCmpt:GetGridPos()        
        if utilData:IsValidPiecePos(pickPos) then
            local isCanPickPos = self:_IsPosCanPick(pickPos, true, true, utilData, extraBoardPosRange)
            if not isCanPickPos then
                local bodyArea = e:BodyArea():GetArea()
                for _, value in pairs(bodyArea) do
                    local workPos = pickPos + value
                    isCanPickPos = self:_IsPosCanPick(workPos, true, true, utilData, extraBoardPosRange)
                    if isCanPickPos then
                        pickPos = workPos
                        break
                    end
                end
            end
            if isCanPickPos then
                local hp = e:Attributes():GetCurrentHP()
                if minHP > hp then
                    minHP = hp
                    minHPEntityPos = pickPos
                    minHPEntityID = e:GetID()
                end
            end
        end  
    end

    if minHPEntityPos then
        table.insert(pickPosList, minHPEntityPos)
        table.insert(targetIDs, minHPEntityID)
        local newCount = autoFightSvc:GetCastActiveSkillCount() + 1
        if newCount == 2 then
            newCount = 0
        end
        autoFightSvc:SetCastActiveSkillCount(newCount)
    end

    return pickPosList, pickPosList, targetIDs
end