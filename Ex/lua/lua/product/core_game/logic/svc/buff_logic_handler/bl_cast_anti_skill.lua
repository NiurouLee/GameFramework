--[[
    按回合锁血
]]
---@class AntiAttackSkillType
local AntiAttackSkillType = {
    Normal = 1, ---普通的
    AfterLoadSomeRound = 2,---在挂在N回合之后才会执行
    NightKing=3,  ---夜王判断逻辑
}
_enum("AntiAttackSkillType",AntiAttackSkillType)
_class("BuffLogicCastAntiSkill", BuffLogicBase)
---@class BuffLogicCastAntiSkill:BuffLogicBase
BuffLogicCastAntiSkill = BuffLogicCastAntiSkill



function BuffLogicCastAntiSkill:Constructor(buffInstance, logicParam)
    self._type = logicParam.type or AntiAttackSkillType.Normal
    self._lockRound =logicParam.lockRound
    ---@type BattleStatComponent
    local battleStat = self._world:BattleStat()
    self._loadRoundCount = battleStat:GetLevelTotalRoundCount()
    self._skillID = logicParam.skillID
    self._startTask = logicParam.startTask or 0
end

function BuffLogicCastAntiSkill:DoLogic()
    if self._type == AntiAttackSkillType.AfterLoadSomeRound then
        ---@type BattleStatComponent
        local battleStat = self._world:BattleStat()
        local curRound = battleStat:GetLevelTotalRoundCount()
        if ( curRound - self._loadRoundCount) < self._lockRound then
            return
        end
    end
    if self._type == AntiAttackSkillType.NightKing then
        if not self:IsNightKingCanCounterAttack() then
            return
        end
    end
    local e = self._buffInstance:Entity()
    local curHp = e:Attributes():GetCurrentHP()
    --Log.fatal("BuffLogicCastAntiSkill HP:",curHp,"LogicEnd:",e:AI():IsLogicEnd())
    ---怪物死了就不放反制技能
    if  curHp<= 0 then
        return
    end
    ---@type Entity
    local skillHolder = e
    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    skillLogicSvc:CalcSkillEffect(skillHolder, self._skillID)
    local result = skillHolder:SkillContext():GetResultContainer()
    skillHolder:ReplaceSkillContext()
    local buffResult =
    BuffResultCastAntiSkill:New(self._skillID, skillHolder:GetID(), result,self._startTask)
    return buffResult
end

function BuffLogicCastAntiSkill:IsNightKingCanCounterAttack()
    ---@type Entity
    local ownEntity = self._buffInstance:Entity()
    ---@type Vector2
    local myPos = ownEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    if not utilScopeSvc:IsNightKingCanCounterAttack(ownEntity,teamEntity) then
        Log.fatal("NightKingCanCounterAttack Failure")
        return false
    end
    local newDir,newBodyArea =utilScopeSvc:GetCounterAttackSwitchBodyArea(ownEntity,teamEntity)
    for i=2 ,#newBodyArea do
        local area = newBodyArea[i]
        local newPos = area+myPos
        if utilScopeSvc:IsPosBlock(newPos,BlockFlag.MonsterLand) then
            Log.fatal("NightKingCanCounterAttack Failure")
            return false
        end
    end
    return true
end