--[[
    检查是否可以释放反制主动技，通过就释放
]]
--------------------------------

--------------------------------
_class("BuffLogicCheckAndCastAntiSkill", BuffLogicBase)
---@class BuffLogicCheckAndCastAntiSkill:BuffLogicBase
BuffLogicCheckAndCastAntiSkill = BuffLogicCheckAndCastAntiSkill

function BuffLogicCheckAndCastAntiSkill:Constructor(buffInstance, logicParam)
    -- self._buffID = logicParam.buffID
    self._skillID = logicParam.skillID
end

function BuffLogicCheckAndCastAntiSkill:DoLogic()
    local entity = self._buffInstance:Entity()
    if not entity then
        return
    end

    ---@type AttributesComponent
    local attributeCmpt = entity:Attributes()

    --反制是否激活，默认1激活
    local antiSkillEnabled = attributeCmpt:GetAttribute("AntiSkillEnabled")
    if antiSkillEnabled == 0 then
        return
    end

    --当前反制CD已经减到0了 就不判断后面的了
    local activeSkillCount = attributeCmpt:GetAttribute("WaitActiveSkillCount")
    if activeSkillCount == 0 then
        return
    end

    --本回合剩余可以反制的次数
    local curRoundAntiCount = attributeCmpt:GetAttribute("MaxAntiSkillCountPerRound")
    if curRoundAntiCount == 0 then
        return
    end

    local checkActiveSkillType = attributeCmpt:GetAttribute("AntiActiveSkillType")
    if checkActiveSkillType == {-1} then
        -- {-1}是所有都通过
    else
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        ---@type ActiveSkillComponent
        local activeSkillCmpt = teamEntity:ActiveSkill()
        local activeSkillID = activeSkillCmpt:GetActiveSkillID()
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(activeSkillID, entity)
        local skillTags = skillConfigData:GetSkillTag()

        local hasTag = false
        for i, v in ipairs(checkActiveSkillType) do
            --如果是-1 则所有主动技都符合
            if v == -1 then
                hasTag = true
                break
            end

            if table.icontains(skillTags, v) then
                hasTag = true
                break
            end
        end
        if hasTag == false then
            return
        end
    end

    --成功以后赋值新的值，主要表现的就是漏斗1到0
    local newActiveSkillCount = activeSkillCount - 1
    if newActiveSkillCount < 0 then
        newActiveSkillCount = 0
    end
    attributeCmpt:Modify("WaitActiveSkillCount", newActiveSkillCount)

    local buffResult = BuffResultCheckAndCastAntiSkill:New(entity:GetID())

    --减少到0 可以释放技能
    if newActiveSkillCount == 0 then
        -- ---@type BuffLogicService
        -- local buffSvc = self._world:GetService("BuffLogic")
        -- local buffInstance = buffSvc:AddBuff(self._buffID, entity, {casterEntity = entity})
        -- if buffInstance then
        --     buffResult:SetBuffSeq({buffInstance:BuffSeq()})
        -- end

        --默认反制技能就是挂载者释放的
        ---@type Entity
        local skillHolder = self._buffInstance:Entity()

        ---@type SkillLogicService
        local skillLogicSvc = self._world:GetService("SkillLogic")
        skillLogicSvc:CalcSkillEffect(skillHolder, self._skillID)
        local result = skillHolder:SkillContext():GetResultContainer()
        buffResult:SetSkillResult(result)
        buffResult:SetSkillID(self._skillID)
        skillHolder:ReplaceSkillContext()

        --反制参数
        local roundCount = "MaxAntiSkillCountPerRound"
        local curValue = attributeCmpt:GetAttribute(roundCount)
        local newValue = curValue - 1
        if newValue < 0 then
            newValue = 0
        end

        attributeCmpt:Modify(roundCount, newValue)

        --放完主动技当前CD回复到最大CD
        local originalAntiCount = attributeCmpt:GetAttribute("OriginalWaitActiveSkillCount")
        attributeCmpt:Modify("WaitActiveSkillCount", originalAntiCount)
    end

    return buffResult
end
