--[[
    此buff触发时entity释放一个技能
]]
---@class BuffLogicCastSkillWithChainCount:BuffLogicBase
_class("BuffLogicCastSkillWithChainCount", BuffLogicBase)
BuffLogicCastSkillWithChainCount = BuffLogicCastSkillWithChainCount

function BuffLogicCastSkillWithChainCount:Constructor(buffInstance, logicParam)
    self._chainCountMultiple = logicParam.chainCountMultiple --连线数量倍数
    self._petTempleteID = logicParam.petTempleteID --目标星灵
    self._skillList = logicParam.skillList
    --这个buff逻辑本意是使用配置的技能，但实际逻辑用了光灵当前使用的连锁技，且已上线，用这个参数来指定使用配置的技能
    self._useAgentSkill = logicParam.useAgentSkill or 0
end

function BuffLogicCastSkillWithChainCount:DoLogic(notify)

    local e = self._buffInstance:Entity()

    local skillList = {}
    for k, v in pairs(self._skillList) do--不能改ipairs
        local skill = {}
        skill.chainCount = k
        skill.skill = v
        table.insert(skillList, skill)
    end

    table.sort(
        skillList,
        function(e1, e2)
            return e1.chainCount > e2.chainCount
        end
    )

    local petEntity
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if e:HasSummoner() then 
        local ownerPet = e:GetSummonerEntity()
        if ownerPet:HasPet() then
            teamEntity = ownerPet:Pet():GetOwnerTeamEntity()
        end
    end

    local pets = teamEntity:Team():GetTeamPetEntities()
    for i, e in ipairs(pets) do
        local cPetPstID = e:PetPstID()
        if self._petTempleteID == cPetPstID:GetTemplateID() then
            petEntity = e
            break
        end
    end

    if not petEntity then
        return
    end

    ---修改指定星灵的buffValue
    ---@type BuffComponent
    local buffComponent = petEntity:BuffComponent()
    buffComponent:SetBuffValue("AgentChainEntityID", e:GetID())
    buffComponent:SetBuffValue("AgentChainCountMultiple", self._chainCountMultiple)
    buffComponent:SetBuffValue("AgentChainSkillList", skillList)
    if self._useAgentSkill == 1 then
        buffComponent:SetBuffValue("AgentChainSkillUseCfgID", 1)
    else
        buffComponent:SetBuffValue("AgentChainSkillUseCfgID", 0)
    end

    local buffResult = BuffResultCastSkillWithChainCount:New(petEntity:GetID())
    return buffResult
end
