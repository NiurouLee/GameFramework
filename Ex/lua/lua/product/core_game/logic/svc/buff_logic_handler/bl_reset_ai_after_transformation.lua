--[[
    在变身后刷新AI和技能，用变身后的monster的技能和ai
]]
--设置AI
_class("BuffLogicResetAIAfterTransformation", BuffLogicBase)
BuffLogicResetAIAfterTransformation = BuffLogicResetAIAfterTransformation

function BuffLogicResetAIAfterTransformation:Constructor(buffInstance, logicParam)

end

function BuffLogicResetAIAfterTransformation:DoLogic()
    ---@type Entity
    local myCasterEntity = self._buffInstance:Entity()
    if not myCasterEntity:HasAI() then
        return
    end
    myCasterEntity:AI():SetRuntimeData("RoundCount", 0)
    myCasterEntity:AI():SetRuntimeData("NextRoundCount", 1)
    --已经变身，取出变身后的id
    local MonsterID = myCasterEntity:MonsterID():GetMonsterID()
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    local monsterStep = monsterConfigData:GetMonsterStep(MonsterID)
    local attributeCmpt = myCasterEntity:Attributes()
    attributeCmpt:Modify("Mobility", monsterStep, 1, MultModifyOperator.PLUS)
    myCasterEntity:AI():SetMobilityTotal(monsterStep)
    local aiList = monsterConfigData:GetMonsterAIID(MonsterID)
    myCasterEntity:ReplaceAI(AILogicPeriodType.Main, aiList[1],nil,true)
    local monsterAntiAttackAIIDList = monsterConfigData:GetMonsterAntiAttackAIID(MonsterID)
    if monsterAntiAttackAIIDList then
        myCasterEntity:ReplaceAI(AILogicPeriodType.Anti, monsterAntiAttackAIIDList[1],nil,true)
    else
        myCasterEntity:ClearAI(AILogicPeriodType.Anti)
    end
    myCasterEntity:AI():ReSelectWorkSkill()
end