--[[
    减少伤害
]]
_class("BuffLogicHarmReduction", BuffLogicBase)
BuffLogicHarmReduction = BuffLogicHarmReduction

function BuffLogicHarmReduction:Constructor(buffInstance, logicParam)
    self._harmReduction = logicParam.harmReduction
    self._stage = logicParam.stage
    self._monsterClassIDArray = logicParam.monsterClassIDArray
    self._previewSkill = logicParam.previewSkill
    self._previewSkillHolderName = logicParam.previewSkillHolderName or "self"
    self._uiText = logicParam.uiText or "str_battle_harm_reduction" --不写默认使用“信标减伤”
end

function BuffLogicHarmReduction:DoLogic()
    local e = self._buffInstance:Entity()

    --在场有指定模版怪物多少个
    local layer = 0
    --白线的UI顺序
    local lineList = {}
    --减伤
    local harmReduction = 0

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        -- if self._monsterClassID == monsterEntity:MonsterID():GetMonsterID() then
        --     layer = layer + 1
        -- end

        if not monsterEntity:HasDeadMark() then
            local monsterID = monsterEntity:MonsterID():GetMonsterID()

            local monsterClassID = 0
            local cfg = Cfg.cfg_monster[monsterID]
            if cfg and cfg.ClassID then
                monsterClassID = cfg.ClassID
            end

            if table.intable(self._monsterClassIDArray, monsterClassID) then
                layer = layer + 1
            end
        end
    end

    local curStage = 1
    if layer > 0 and layer <= #self._stage then
        for i = 1, layer do
            if self._stage[i] > curStage then
                curStage = self._stage[i]
                --线的顺序= 已经打开的层数 + 已经有的线数量
                local lineIndex = i + #lineList
                table.insert(lineList, lineIndex)
            end
        end

        --减伤
        harmReduction = self._harmReduction[layer]
    end

    ---@type AttributesComponent
    local cpt = e:Attributes()
    --设置减伤属性
    cpt:Modify("FinalBehitDamageParam", -harmReduction / 100)

    --设置技能选择参数
    local oldStage = cpt:GetAttribute("BuffStageFixSkillSelectRound")
    cpt:SetSimpleAttribute("BuffStageFixSkillSelectRound", curStage)

    local skillHolder = nil
    local previewSkillID = 0
    if self._previewSkill and table.count(self._previewSkill) > 0 then
        if self._previewSkillHolderName == "self" then --技能持有者是自己
            skillHolder = e
        else
            local skillHolderName = self._previewSkillHolderName .. e:GetID()
            local skillHolderID = e:GetSkillHolder(skillHolderName)
            if not skillHolderID then
                ---@type LogicEntityService
                local entityService = self._world:GetService("LogicEntity")
                skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.SkillHolder)
                skillHolder:SetGridPosition(e:GetGridPosition())
                e:AddSkillHolder(skillHolderName, skillHolder:GetID())
                skillHolder:AddSuperEntity(e)
                skillHolder:ReplaceAlignment(e:Alignment():GetAlignmentType())
                skillHolder:ReplaceGameTurn(e:GameTurn():GetGameTurn())
            else
                skillHolder = self._world:GetEntityByID(skillHolderID)
            end
        end

        skillHolder:SetGridPosition(e:GetGridPosition())

        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = skillHolder:SkillContext():GetResultContainer()
        ---@type SkillEffectResult_ShowWarningArea
        local effectResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ShowWarningArea)

        if effectResult and oldStage ~= curStage then
            skillEffectResultContainer:Clear()
            previewSkillID = self._previewSkill[curStage]

            if previewSkillID > 0 then
                local skillLogicSvc = self._world:GetService("SkillLogic")
                skillLogicSvc:CalcSkillEffect(skillHolder, previewSkillID)
            end
        end
    end

    --设置layer 在显示的时候对比 view的层  决定周身特效
    self._buffInstance:SetLayerCount(layer)

    --将计算结果设置到result中
    local buffResult =
        BuffResultHarmReduction:New(layer, lineList, harmReduction, previewSkillID, skillHolder, self._uiText)
    return buffResult
end
