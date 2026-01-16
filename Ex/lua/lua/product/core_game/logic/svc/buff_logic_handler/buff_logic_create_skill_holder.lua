--[[
    创建技能施法实体
]]

BuffLogicCreateSkillHolder_AbsolutePositionMode = {
    BoardCenter = 1, ---
}

_enum("BuffLogicCreateSkillHolder_AbsolutePositionMode", BuffLogicCreateSkillHolder_AbsolutePositionMode)

_class("BuffLogicCreateSkillHolder", BuffLogicBase)
BuffLogicCreateSkillHolder = BuffLogicCreateSkillHolder

function BuffLogicCreateSkillHolder:Constructor(buffInstance, logicParam)
    self._element = logicParam.element
    self._attackType = logicParam.attackType
    self._name = logicParam.name
    self._absolutePositionMode = logicParam.absolutePositionMode
    self._hideOnDefault = logicParam.hideOnDefault
    self._uesPetTempleteID = logicParam.uesPetTempleteID
    self._useBlackFistEnemyTeam = logicParam.useBlackFistEnemyTeam or 0
end

function BuffLogicCreateSkillHolder:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---@type Entity
    local skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.SkillHolder)
    --阵营用宿主的
    skillHolder:ReplaceAlignment(e:Alignment():GetAlignmentType())
    skillHolder:ReplaceGameTurn(e:GameTurn():GetGameTurn())

    if self._uesPetTempleteID then
        ---@type Entity
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        ---黑拳赛特殊处理，按需取队伍
        if self._world:MatchType() == MatchType.MT_BlackFist and self._useBlackFistEnemyTeam == 1 then
            local ownerAlignmentType = e:Alignment():GetAlignmentType()
            local teamAlignmentType = teamEntity:Alignment():GetAlignmentType()
            local targetType = MatchAlignmentType(ownerAlignmentType, teamAlignmentType)
            if targetType ~= MatchAlignmentType.Enemy then
                teamEntity = self._world:Player():GetCurrentEnemyTeamEntity()
            end
        end

        ---获取对应的Pet
        local petList = teamEntity:Team():GetTeamPetEntities()
        ---@type Entity
        local petEntity = nil
        for _, e in ipairs(petList) do
            local cPetPstID = e:PetPstID()
            if self._uesPetTempleteID == cPetPstID:GetTemplateID() then
                petEntity = e
                break
            end
        end
        if not petEntity then
            Log.error("BuffLogicCreateSkillHolder cfg error: PetTemplateID = ", self._uesPetTempleteID, ", BuffID = ",
                self._buffInstance:BuffID())
            return
        end

        --战斗属性
        local superAttributesComponent = petEntity:Attributes()
        if not skillHolder:HasAttributes() then
            skillHolder:AddAttributes()
        end
        local modifierDic = superAttributesComponent:CloneAttributes()
        skillHolder:Attributes():SetModifierDic(modifierDic)

        --元素属性：只用主属性
        local element = petEntity:Element()
        skillHolder:ReplaceElement(element:GetPrimaryType())
    else
        --添加元素属性
        if self._element then
            skillHolder:ReplaceElement(self._element)
        else
            local element = e:Element()
            skillHolder:ReplaceElement(element:GetPrimaryType())
        end

        --计算攻击力
        if self._attackType then
            local attack = self:CalcSkillAttack(e, self._attackType)
            skillHolder:AddAttributes()
            skillHolder:Attributes():SetSimpleAttribute("Attack", attack)
        else
            --战斗属性
            local superAttributesComponent = e:Attributes()
            if not skillHolder:HasAttributes() then
                skillHolder:AddAttributes()
            end
            local modifierDic = superAttributesComponent:CloneAttributes()
            skillHolder:Attributes():SetModifierDic(modifierDic)
        end
    end

    --默认继承位置
    skillHolder:GridLocation().Position = e:GetGridPosition()
    if self._absolutePositionMode == BuffLogicCreateSkillHolder_AbsolutePositionMode.BoardCenter then
        skillHolder:SetGridLocation(BattleConst.BoardCenterPos, Vector2.down)
    end

    --记录到entity身上
    e:AddSkillHolder(self._name, skillHolder:GetID())

    skillHolder:AddSuperEntity(e)

    local result = BuffResultCreateSkillHolder:New(skillHolder:GetID())
    result:SetAbsolutePositionMode(self._absolutePositionMode)
    result:SetHideOnDefault(self._hideOnDefault)
    return result
end

--计算攻击力
function BuffLogicCreateSkillHolder:CalcSkillAttack(entity, attackType)
    local formulaSvc = self._world:GetService("Formula")
    local ret = 0
    if attackType == BuffSkillAttackType.TeamAttack then
        local teamMembers = entity:Team():GetTeamPetEntities()
        for _, pet in ipairs(teamMembers) do
            local att = formulaSvc:_CalcFinalAtk(pet)
            ret = ret + att
        end
    end
    if ret == 0 then
        Log.error("CalcSkillAttack() error attack=0!")
    end
    return ret
end

--[[
    删除施法实体
]]
_class("BuffLogicRemoveSkillHolder", BuffLogicBase)
BuffLogicRemoveSkillHolder = BuffLogicRemoveSkillHolder

function BuffLogicRemoveSkillHolder:Constructor(buffInstance, logicParam)
    self._name = logicParam.name
end

function BuffLogicRemoveSkillHolder:DoLogic()
    local e = self._buffInstance:Entity()
    local id = e:GetSkillHolder(self._name)
    local holder = self._world:GetEntityByID(id)
    if holder then
        e:RemoveSkillHolder(self._name)
        return BuffResultCreateSkillHolder:New(holder:GetID())
    end
end
