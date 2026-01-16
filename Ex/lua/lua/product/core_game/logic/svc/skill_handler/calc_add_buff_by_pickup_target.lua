--[[
    AddBuffByPickupTarget = 143, --根据点选对象选择附加buff
]]
---@class SkillEffectCalc_AddBuffByPickupTarget: Object
_class("SkillEffectCalc_AddBuffByPickupTarget", Object)
SkillEffectCalc_AddBuffByPickupTarget = SkillEffectCalc_AddBuffByPickupTarget

function SkillEffectCalc_AddBuffByPickupTarget:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBuffByPickupTarget:DoSkillEffectCalculator(skillEffectCalcParam)
    local skillID = skillEffectCalcParam:GetSkillID()
    local attackRange = skillEffectCalcParam:GetSkillRange()
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()

    ---@type SkillEffectAddBuffByPickupTargetParam
    local param = skillEffectCalcParam.skillEffectParam
    local buffID = param:GetBuffID()
    local trapIDList = param:GetTrapIDList()
    local matchPieceType = param:GetMatchPieceType()

    local pickUpPos = attackRange[1]
    --检测配置的机关ID，是否和点选格子上的机关ID相同
    local boardCmpt = self._world:GetBoardEntity():Board()
    local traps =
    boardCmpt:GetPieceEntities(
        pickUpPos,
        function(e)
            local isOwner = false
            if e:HasSummoner() then
                local summonEntityID = e:Summoner():GetSummonerEntityID()
                ---@type Entity
                local summonEntity = e:GetSummonerEntity()
                --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
                if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                    summonEntityID = summonEntity:GetSuperEntity():GetID()
                end
                if summonEntityID == casterEntityID then
                    isOwner = true
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrap() and table.icontains(trapIDList, e:TrapID():GetTrapID()) and not e:HasDeadMark()
        end
    )

    local isMatchPieceType = false
    if matchPieceType then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local pieceType = utilData:FindPieceElement(pickUpPos)
        if (pieceType == matchPieceType) then
            isMatchPieceType = true
        end
    end

    --若点选到机关，则更改Buff ID
    if #traps > 0 then
        ---@type Entity
        local pickUpTrap = traps[1]
        if isMatchPieceType then
            buffID = param:GetMatchPieceTypeBuffIDByTrapID(pickUpTrap:TrapID():GetTrapID())
        else
            buffID = param:GetBuffIDByTrapID(pickUpTrap:TrapID():GetTrapID())
        end
    end


    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type SkillBuffEffectResult
    local buffResult = SkillBuffEffectResult:New(casterEntityID)

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local cfgNewBuff = Cfg.cfg_buff[buffID]
    if cfgNewBuff then
        local nt = NTEachAddBuffStart:New(skillID, casterEntity, casterEntity, attackRange)
        triggerSvc:Notify(nt)
        local buff = buffLogicService:AddBuff(
            buffID,
            casterEntity,
            { casterEntity = casterEntity }
        )
        local seqID
        if buff then
            seqID = buff:BuffSeq()
            buffResult:AddBuffResult(seqID)
        end
        triggerSvc:Notify(NTEachAddBuffEnd:New(skillID, casterEntity, casterEntity, attackRange, buffID, seqID))
    end

    return { buffResult }
end
