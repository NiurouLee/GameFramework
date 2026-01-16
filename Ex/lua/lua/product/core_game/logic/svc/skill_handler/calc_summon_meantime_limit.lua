--[[
    SummonMeantimeLimit = 117, ---限制同时存在数量的召唤，当新的召唤成功后，如果同时存在的数量超过了限制，销毁最先召唤的。
]]
---@class SkillEffectCalc_SummonMeantimeLimit: Object
_class("SkillEffectCalc_SummonMeantimeLimit", Object)
SkillEffectCalc_SummonMeantimeLimit = SkillEffectCalc_SummonMeantimeLimit

function SkillEffectCalc_SummonMeantimeLimit:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonMeantimeLimit:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamSummonMeantimeLimit
    local skillEffectParamSummon = skillEffectCalcParam.skillEffectParam
    local trapID = skillEffectParamSummon:GetTrapID()
    local limitCount = skillEffectParamSummon:GetLimitCount()
    local trapDieSkillID = skillEffectParamSummon:GetTrapDieSkillID()
    local absPosArray = skillEffectParamSummon:GetAbsPosArray()
    local ignoreBlock = skillEffectParamSummon:IgnoreBlock()
    local replaceAttr = skillEffectParamSummon:GetReplaceAttr()
    local blockFlag = BlockFlag.SummonTrap
    if ignoreBlock then
        blockFlag = 0
    end

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local posRange = skillEffectCalcParam.skillRange
    if absPosArray and #absPosArray > 0 then
        posRange = absPosArray
    end
    
    --1 召唤结果
    local summonPosList = {}
    for _, gridPos in ipairs(posRange) do
        if
            trapServiceLogic:CanSummonTrapOnPos(gridPos, trapID, blockFlag, false) and
                table.count(summonPosList) <= limitCount
         then
            if self:_CheckOverlapCanSummon(gridPos,trapID,skillEffectCalcParam) then--检查重叠
                table.insert(summonPosList, gridPos)
            end
        end
    end
    if #summonPosList == 0 then
        return
    end
    local result = SkillEffectResultSummonMeantimeLimit:New(trapID, summonPosList)

    --2 删除结果
    local destroyEntityID = {}
    local skillResultList = {}
    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()
    local summonMeantimeLimitEntityID = {}
    local checkTrapIDs =  skillEffectParamSummon:GetCheckTrapID()
    for i, checkTrapID in ipairs(checkTrapIDs) do
        local entityIDList = battleFlags:GetSummonMeantimeLimitEntityID(checkTrapID)
        table.appendArray(summonMeantimeLimitEntityID,entityIDList)
    end

    table.sort(summonMeantimeLimitEntityID,function(a,b)return (a <  b) end)

    --直接使用现有的召唤队列和本次召唤成功计算的不对。因为刚召唤成功的可能因为和以前的某一个坐标重合而销毁以前的某一个
    local meantimeCount = table.count(summonMeantimeLimitEntityID) + table.count(summonPosList)
    for _, gridPos in ipairs(summonPosList) do
        for _, entityID in ipairs(summonMeantimeLimitEntityID) do
            local targetEntity = self._world:GetEntityByID(entityID)
            if targetEntity and not targetEntity:HasDeadMark() and targetEntity:GetGridPosition() == gridPos then
                meantimeCount = meantimeCount - 1
            end
        end
    end

    local curIndex = 1
    while meantimeCount > limitCount do
        local curEntityID = summonMeantimeLimitEntityID[curIndex]
        meantimeCount = meantimeCount - 1
        curIndex = curIndex + 1
        table.insert(destroyEntityID, curEntityID)

        if trapDieSkillID and trapDieSkillID > 0 then
            local curEntity = self._world:GetEntityByID(curEntityID)
            ---@type SkillLogicService
            local skillLogicSvc = self._world:GetService("SkillLogic")
            skillLogicSvc:CalcSkillEffect(curEntity, trapDieSkillID)
            ---@type SkillEffectResultContainer
            local skillResult = curEntity:SkillContext():GetResultContainer()
            table.insert(skillResultList, skillResult)
        end
    end

    result:SetDestroyEntityID(destroyEntityID)
    result:SetTrapDieSkillResult(skillResultList)
    result:SetReplaceAttr(replaceAttr)
    return result
end
---根据机关重叠配置判断该位置是否可召唤
function SkillEffectCalc_SummonMeantimeLimit:_CheckOverlapCanSummon(pos,trapId,skillEffectCalcParam)
    ---@type SkillEffectParamSummonMeantimeLimit
    local skillEffectParamSummon = skillEffectCalcParam.skillEffectParam
    --查看召唤位置上是否可以重复召唤相同ID的机关
    if not skillEffectParamSummon:IsTrapOverlap() then
        local boardCmpt = self._world:GetBoardEntity():Board()
        local repeatTraps =
            boardCmpt:GetPieceEntities(
                pos,
            function(e)
                local isOwner = false
                --配置上保证了被选中的机关一定有SummonerComponent，因此不考虑没有该组件的机关
                --注：这里没有SummonerComponent时的结果与SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget不一致
                if e:HasSummoner() then
                    if e:Summoner():GetSummonerEntityID() == skillEffectCalcParam.casterEntityID then
                        isOwner = true
                    else
                        --[[
                            修改前代码是只判断机关是不是施法者自己的
                            但N24加入的阿克希亚也可以召唤别人的机关，并需要被认为是施法者的
                            考虑到该判断原先的目的是防止吸收【被世界boss化的光灵】和【黑拳赛的对方光灵】所属机关
                            这里添加判断：当施法者是光灵时，自己队伍内的其他光灵召唤的机关，也视为施法者自己召唤的
                        ]]
                        local summonerID = e:Summoner():GetSummonerEntityID()
                        local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
                        if casterEntity:HasPet() then
                            local cTeam = casterEntity:Pet():GetOwnerTeamEntity():Team()
                            local entities = cTeam:GetTeamPetEntities()
                            for _, petEntity in ipairs(entities) do
                                if summonerID == petEntity:GetID() then
                                    isOwner = true
                                    break
                                end
                            end
                        end
                    end
                else
                    isOwner = true
                end
                return isOwner and e:HasTrap() and e:Trap():GetTrapID() == trapId and not e:HasDeadMark()
            end
        )
        if #repeatTraps > 0 then
            return false
        else
            return true
        end
    else
        return true
    end
end