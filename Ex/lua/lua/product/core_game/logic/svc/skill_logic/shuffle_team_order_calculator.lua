_class("ShuffleTeamOrderCalculator", Object)
---@class ShuffleTeamOrderCalculator : Object
ShuffleTeamOrderCalculator = ShuffleTeamOrderCalculator

---@param world MainWorld
function ShuffleTeamOrderCalculator:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_ShuffleTeamOrder
function ShuffleTeamOrderCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIDs = scopeResult:GetTargetIDs()

    for _, entityID in ipairs(targetIDs) do
        local entity = self._world:GetEntityByID(entityID)
        local result = self:_CalculateTeam(casterEntity, effectParam, entity)
        if result then
            skillEffectResultContainer:AddEffectResult(result)
        end
    end
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_ShuffleTeamOrder
---@param teamEntity Entity
function ShuffleTeamOrderCalculator:_CalculateTeam(casterEntity, effectParam, teamEntity)
    if not teamEntity:HasTeam() then
        return
    end

    local oldLeaderPstID = teamEntity:Team():GetTeamLeaderEntity():PetPstID():GetPstID()
    local newLeaderPstID = nil

    local tOldTeamOrder = {}
    for k, v in ipairs(teamEntity:Team():GetTeamOrder()) do
        tOldTeamOrder[k] = v
    end

    -- 首先尝试找一个队长换上去
    ---@type BattleService
    local svcBattle = self._world:GetService("Battle")
    local candidate = svcBattle:GetFirstLeaderCandidate(teamEntity)
    if candidate then
        newLeaderPstID = candidate:PetPstID():GetPstID()
        svcBattle:ChangeLocalTeamLeader(newLeaderPstID)
    end

    -- 这个必须放在换队长之后，，且是一个复制的数据，因为换队长也涉及顺序调换
    local tTeamOrder = {}
    for k, v in ipairs(teamEntity:Team():GetTeamOrder()) do
        tTeamOrder[k] = v
    end
    local nNonShuffledLeaderPstID = tTeamOrder[1]

    -- 按配置顺序进行一波乱的打
    local cTeam = teamEntity:Team()
    -- 1. 取出要打乱的pstID，保持原order内的先后
    local cfgShufflePos = effectParam:GetShufflePos()
    local shuffleData = {}
    local helpPstID
    for _, pos in ipairs(cfgShufflePos) do
        if tTeamOrder[pos] then
            local pstID = tTeamOrder[pos]
            local e = cTeam:GetPetEntityByPetPstID(pstID)
            if (not e:PetPstID():IsHelpPet()) then
                table.insert(shuffleData, pstID)
            else
                helpPstID = pstID
            end
        end
    end

    -- 2. 对取出的pstID进行一次随机
    ---@type RandomServiceLogic
    local randomLSvc = self._world:GetService("RandomLogic")
    local shuffledPstIDs = {}
    while(#shuffleData > 0) do
        local index = randomLSvc:LogicRand(1, #shuffleData)
        table.insert(shuffledPstIDs, table.remove(shuffleData, index))
    end

    local tNewTeamOrder = {}
    -- 3. 组成新的TeamOrder：没被换顺序的人从原order内取，可能被换顺序的人从shuffledPstIDs获取
    for orderIndex, pstID in ipairs(tTeamOrder) do
        if not table.icontains(cfgShufflePos, orderIndex) then
            table.insert(tNewTeamOrder, pstID)
        else
            table.insert(tNewTeamOrder, table.remove(shuffledPstIDs))
        end
    end
    if helpPstID then
        table.insert(tNewTeamOrder, helpPstID)
    end
    local cTeam = teamEntity:Team()

    cTeam:SetTeamOrder(tNewTeamOrder)

    self._world:GetService("Trigger"):Notify(NTTeamOrderChange:New(teamEntity,tOldTeamOrder,tNewTeamOrder))

    -- 乱序逻辑不考虑shuffle操作内导致第二次队长更换的情况，乱序逻辑到此结束
    local result = SkillEffectResult_ShuffleTeamOrder:New(teamEntity:GetID(), oldLeaderPstID, newLeaderPstID, tOldTeamOrder, tNewTeamOrder)
    casterEntity:SkillContext():GetResultContainer():AddEffectResult(result)
end
