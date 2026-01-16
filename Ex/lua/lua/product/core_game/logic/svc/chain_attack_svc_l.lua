require("base_service")

_class("ChainAttackServiceLogic", BaseService)
---@class ChainAttackServiceLogic:BaseService
ChainAttackServiceLogic = ChainAttackServiceLogic

function ChainAttackServiceLogic:_DoLogicCalcChainSkill(teamEntity)
    if self._world:RunAtServer() then
        ---先清理上次选的数据
        local pets = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(pets) do
            ----@type SkillPetAttackDataComponent
            local skillPetData = e:SkillPetAttackData()
            skillPetData:ClearPetChainAttackData()
        end
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    ---@type PieceType
    local chainPieceType = logicChainPathCmpt:GetLogicPieceType()

    utilScopeSvc:SelectTarget(teamEntity, chainPieceType)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    ---@type Vector2[]
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    --统计超级连锁次数
    local chainNum = logicChainPathCmpt:GetChainRateAtIndex(#chainPath)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()
    local isSuperChain = chainNum >= superChainCount
    if isSuperChain then
        battleStatCmpt:AddSuperChainCount(teamEntity)
    end
    battleStatCmpt:SetRoundSuperChain(isSuperChain)
    battleStatCmpt:SetRoundChainPath(chainPath)
    if self:CanCalcChainSkill(teamEntity) then
        local skillCastPos = teamEntity:GridLocation():GetGridPos() --施法位置为当前位置
        skillLogicService:CalcChainSkillDamage(teamEntity, skillCastPos)
    else
        local ntChainSkip = NTChainSkillTurnStartSkipped:New(teamEntity)
        self._world:GetService("Trigger"):Notify(ntChainSkip)
    end
  
    ---普攻杀死的怪物数量
    local normalSkillKillCount = battleStatCmpt:GetNormalAttackKillCount()
    --统计一次连锁技杀怪
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.DeadMark)
    local chainSkillKill = #monsterGroup:GetEntities() - normalSkillKillCount
    battleStatCmpt:SetOneChainKillCount(teamEntity,chainSkillKill)
end

---@param teamEntity Entity
---判断是否能计算连锁技
function ChainAttackServiceLogic:CanCalcChainSkill(teamEntity)
    if teamEntity:HasTeamDeadMark() then
        return false
    end
    if teamEntity:BuffComponent():HasFlag(BuffFlags.Benumb) then
        return false
    end
    return true
end


