--[[
    计算下回合使用的技能范围，存在Ai组件上
]]
_class("BuffLogicSetAISkillScope", BuffLogicBase)
BuffLogicSetAISkillScope = BuffLogicSetAISkillScope

function BuffLogicSetAISkillScope:Constructor(buffInstance, logicParam)
    self._addRoundCount = logicParam.addRoundCount or 1
    self._skillIndexX = logicParam.skillIndexX or 1
    self._skillIndexY = logicParam.skillIndexY or 1
end

function BuffLogicSetAISkillScope:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type AIComponentNew
    local aiCmpt = e:AI()
    if not aiCmpt then
        return
    end

    local configService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfig = configService:GetMonsterConfigData()
    ---@type MonsterIDComponent
    local cMonsterID = e:MonsterID()
    if not cMonsterID then
        return
    end

    local monsterID = cMonsterID:GetMonsterID()
    local listSkill = monsterConfig:GetMonsterSkillIDs(monsterID)
    if not listSkill then
        return
    end

    local skillID = listSkill[self._skillIndexX][self._skillIndexY]
    if not skillID then
        return
    end

    aiCmpt:SetCurSkillScopeResult(self._addRoundCount, skillID)
end
