--[[
    此buff触发时entity释放一个技能
]]
---@class BuffLogicCastSkill:BuffLogicBase
_class("BuffLogicCastSkill", BuffLogicBase)
BuffLogicCastSkill = BuffLogicCastSkill

function BuffLogicCastSkill:Constructor(buffInstance, logicParam)
    self._skillID = logicParam.skillID
    self._skillHolderName = logicParam.skillHolderName
    self._skillHolderType = logicParam.skillHolderType or SkillHolderType.DefaultSkillRoutine
    self._useNotifyEntityPos = logicParam.useNotifyEntityPos or 0 --使用触发者的坐标
    self._notSetLocation = logicParam.notSetLocation or 0 ---表现里不设置Location
    self._useNotifyPos = logicParam.useNotifyPos or 0 --使用notify传的坐标
    self._startTask = logicParam.startTask or 0 --是否在表现的时候另起协程 默认0不开
    self._useSuperView = logicParam.useSuperView or 0 --是否在技能表现中使用super的模型
    self._useSuperAttr = logicParam.useSuperAttr or 1 --是否使用super的属性，默认开启
    self._useSuperPetAttackData = logicParam.useSuperPetAttackData or 0 ---是否使用Super的攻击数据，当释放的技能是连锁机或者普攻的时候有用
    self._checkFinalAttack = logicParam.checkFinalAttack or 0 --星灵用buff放的技能，需要最后一击的表现
    self._viewMatchUseLayerCount = logicParam.viewMatchUseLayerCount or 0 --view在表现的时候使用当前层数匹配，而不是totleCount
    self._notifyIsOwnerSummoner = logicParam.notifyIsOwnerSummoner or 0 --buff通知的entity是buff持有者的召唤者
    self._checkTrapDie = logicParam.checkTrapDie --是否检查机关死亡并通知加deadflag（不加的话被击表现不会表现机关销毁）早苗开始
    self._checkMonsterDie = logicParam.checkMonsterDie --是否检查怪物死亡并通知加deadflag 约书亚斩杀用
    self._useNotifyEntityTeamPos = logicParam.useNotifyEntityTeamPos or 0 --使用触发者的队伍的坐标（普攻移动过程中，队伍的位置是对的，光灵不是）
    self._useNotifyBodyArea =logicParam.useNotifyBodyArea or 0 --使用触发者的身体区域
    self._createSkillHolderEveryTime = logicParam.createSkillHolderEveryTime or 0 --每次释放都需要新建SkillHolder
    self._useBuffCasterAlignment = logicParam.useBuffCasterAlignment
    self._overrideSkillScopeByBuff = logicParam.overrideSkillScopeByBuff
    self._viewMatchUseLayerCountAndTotalCount = logicParam.viewMatchUseLayerCountAndTotalCount or 0 --view在表现的时候使用当前层数匹配和totleCount
end

function BuffLogicCastSkill:DoLogic(notify, triggers)
    local e = self._buffInstance:Entity()
    ---@type Entity
    local skillHolder = nil
    if self._skillHolderName == "self" then --技能持有者是自己
        skillHolder = e
    else
        if not self._skillHolderName then
            ---@type LogicEntityService
            local entityService = self._world:GetService("LogicEntity")
            skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.SkillHolder)
            local skillHolderName = "SkillHolder" .. skillHolder:GetID()
            if self._createSkillHolderEveryTime == 0 then
                self._skillHolderName = skillHolderName
            end
            
            e:AddSkillHolder(skillHolderName, skillHolder:GetID())
            skillHolder:AddSuperEntity(e)
            local alignmentEntity = e
            if self._useBuffCasterAlignment then
                local context = self._buffInstance:Context()
                if context then
                    local casterEntity = context.casterEntity
                    if casterEntity then
                        alignmentEntity = casterEntity
                    end
                end
            end
            skillHolder:ReplaceAlignment(alignmentEntity:Alignment():GetAlignmentType())
            skillHolder:ReplaceGameTurn(alignmentEntity:GameTurn():GetGameTurn())
        else
            local skillHolderID = e:GetSkillHolder(self._skillHolderName)
            if not skillHolderID then
                ---@type LogicEntityService
                local entityService = self._world:GetService("LogicEntity")
                skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.SkillHolder)
                e:AddSkillHolder(self._skillHolderName, skillHolder:GetID())
                skillHolder:AddSuperEntity(e)
                local alignmentEntity = e
                if self._useBuffCasterAlignment then
                    local context = self._buffInstance:Context()
                    if context then
                        local casterEntity = context.casterEntity
                        if casterEntity then
                            alignmentEntity = casterEntity
                        end
                    end
                end
                skillHolder:ReplaceAlignment(alignmentEntity:Alignment():GetAlignmentType())
                skillHolder:ReplaceGameTurn(alignmentEntity:GameTurn():GetGameTurn())
            else
                skillHolder = self._world:GetEntityByID(skillHolderID)
            end
        end

        if self._useSuperAttr == 1 then
            --战斗属性
            local superAttributesComponent = e:Attributes()
            if not skillHolder:HasAttributes() then
                skillHolder:AddAttributes()
            end
            local modifierDic = superAttributesComponent:CloneAttributes()
            skillHolder:Attributes():SetModifierDic(modifierDic)

            --ReplaceAttributes是把本体的组件引用给新创建的skillHolder。会导致skillHolder如果被攻击，本体也会被攻击。BUG：37384 鲍格林锁血死亡
            --预期解决：复制本体的锁血和无敌buff给skillHolder
            --实际解决：buff配置施法者改成self
            -- self:_OnSyncBuffFormSuperToSkillHolder(e, skillHolder)

            local element = e:Element()
            --region KZY20230705
            -- Bug：1631589修改后副属性启用不生效，但由于已上线很久，策划决定不改，故注掉以下两行代码
            -- skillHolder:ReplaceElement(element:GetPrimaryType(), element:GetSecondaryType())
            -- skillHolder:Element():SetUseSecondaryType(element:IsUseSecondaryType())
            --endregion

            skillHolder:ReplaceElement(element:GetPrimaryType(), element:GetSecondaryType())
        end

        if self._useSuperView == 1 then
            skillHolder:SuperEntityComponent():SetUseSuperEntityViewState(true)
        end
        if self._useSuperPetAttackData == 1 then
            skillHolder:SuperEntityComponent():SetUseSuperPetAttackData(true)
        end
    end

    --释放技能的位置
    if self._useNotifyEntityPos == 1 then
        local posEntity = e
        --套娃：e是SkillHolder的话，用它的super位置
        if e:HasSuperEntity() then
            posEntity = e:GetSuperEntity()
        end
        skillHolder:SetGridPosition(posEntity:GetGridPosition())
        skillHolder:ReplaceBodyArea(posEntity:BodyArea():GetArea()) --重置格子占位
    end
    if self._useNotifyEntityTeamPos == 1 then
        local posEntity = e
        --套娃：e是SkillHolder的话，用它的super位置
        if e:HasSuperEntity() then
            posEntity = e:GetSuperEntity()
        end
        if posEntity:HasPet() then
            skillHolder:ReplaceBodyArea(posEntity:BodyArea():GetArea()) --重置格子占位
            posEntity = posEntity:Pet():GetOwnerTeamEntity()
            skillHolder:SetGridPosition(posEntity:GetGridPosition())
        end
    end
    if self._useNotifyPos == 1 then
        skillHolder:SetGridPosition(notify:GetNotifyPos())
        skillHolder:ReplaceBodyArea(e:BodyArea():GetArea()) --重置格子占位
    end
    if self._useNotifyBodyArea == 1 then
        skillHolder:ReplaceBodyArea(notify:GetNotifyBodyArea())
    end

    local overrideScopeResult
    if self._overrideSkillScopeByBuff then
        --这个数据应该记录在本体身上，数据来源是BuffLogicCalcScope
        --注意在CalcSkillEffect逻辑里，这个overrideScopeResult是高于其他范围修改逻辑的
        local cBuff = self:GetEntity():BuffComponent()
        overrideScopeResult = cBuff:GetBuffValue(string.format(BattleConst.BuffCalcScopeKeyFormat, self._overrideSkillScopeByBuff))
    end

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    skillLogicSvc:CalcSkillEffect(skillHolder, self._skillID, nil--[[枚举有SkillType.BuffSkill但完全没用]], overrideScopeResult)
    ---@type BuffResultCastSkill
    local buffResult = BuffResultCastSkill:New(self._skillID, skillHolder:GetID(), self._skillHolderType,
        e:GetGridPosition())
    buffResult:SetTrigger(triggers)
    buffResult:SetStartTask(self._startTask)
    buffResult:SetUseSuperEntityView(self._useSuperView)
    buffResult:SetCheckFinalAttack(self._checkFinalAttack)
    buffResult:SetNotifyIsOwnerSummoner(self._notifyIsOwnerSummoner)

    local attackPos = nil
    local targetId = nil
    if self._skillHolderType == SkillHolderType.AttackPosTargetId then
        local castSkillOnPosAndTarget = BuffResultCastSkillOnPosAndTarget:New()
        attackPos = notify:GetAttackPos()
        targetId = notify:GetDefenderEntity():GetID()
        local result = skillHolder:SkillContext():GetResultContainer()
        castSkillOnPosAndTarget:AddSkillResult(attackPos, targetId, result)
        skillHolder:ReplaceSkillContext()
        buffResult:SetTarget(targetId, attackPos)
        buffResult:SetSkillResultOnPosAndTarget(castSkillOnPosAndTarget)
    else
        local result = skillHolder:SkillContext():GetResultContainer()
        buffResult:SetSkillResult(result)
        skillHolder:ReplaceSkillContext()
    end

    if notify then
        if notify:GetNotifyType() == NotifyType.Teleport then
            buffResult:SetTeleportPos(notify:GetPosOld(), notify:GetPosNew())
        end
        if notify:GetNotifyType() == NotifyType.PlayerHPChange then
            buffResult:SetPlayerHPChangeData(
                notify:GetNotifyEntity():GetID(),
                notify:GetDamageSrcEntity(),
                notify:GetHPPercent(),
                notify:GetChangeHP()
            )
        end
        if notify:GetNotifyType() == NotifyType.MonsterDead then
            local deadMonsterEntity = notify:GetNotifyEntity()
            buffResult:SetDeadEntityID(deadMonsterEntity:GetID())
        end
        if notify:GetNotifyType() == NotifyType.NotifyLayerChange then
            ---@type BuffLogicService
            local lbsvc = self._world:GetService("BuffLogic")
            local count = lbsvc:GetBuffTotalLayer(e, notify:GetLayerName())
            buffResult:SetTotalLayer(count)

            buffResult:SetLayerName(notify:GetLayerName())
            local curLayer = lbsvc:GetBuffLayer(e, notify:GetLayerType())
            buffResult:SetCurLayer(curLayer)
            buffResult:SetUseCurAndTotalLayer(self._viewMatchUseLayerCountAndTotalCount)

            if self._viewMatchUseLayerCount == 1 then
                ---这里值错误的，使用的是当前的变化层数，但是由于有逻辑使用了，就不改了
                local layer = notify:GetLayer()
                buffResult:SetViewMatchUseLayerCount(self._viewMatchUseLayerCount)
                buffResult:SetLayer(layer)
            end
        end

        if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
            buffResult:SetNotifyMoveEndPos(notify:GetPos())
        end

        if notify:GetNotifyType() == NotifyType.SyncMoveEachMoveEnd then
            buffResult:SetNotifyMoveEndPos(notify:GetPos())
            local pathIndex = notify:GetPathIndex()
            buffResult:SetNotifySyncMovePathIndex(pathIndex)
        end

        if notify:GetNotifyType() == NotifyType.HitBackEnd then
            buffResult:SetNotifyMoveEndPos(notify:GetPosEnd())
        end

        if notify:GetNotifyType() == NotifyType.GridConvert then
            local attackPos = {}
            local oldPosIndexPieceType = {}
            local newPosIndexPieceType = {}
            for _, info in ipairs(notify:GetConvertInfoArray()) do
                table.insert(attackPos, info:GetPos())

                local posIndex = Vector2.Pos2Index(info:GetPos())
                local oldPieceType = info:GetBeforePieceType()
                local newPieceType = info:GetAfterPieceType()
                oldPosIndexPieceType[posIndex] = oldPieceType
                newPosIndexPieceType[posIndex] = newPieceType
            end

            buffResult:SetAttackPosArray(attackPos)
            buffResult:SetGridConvertOldPosIndexPieceType(oldPosIndexPieceType)
            buffResult:SetGridConvertNewPosIndexPieceType(newPosIndexPieceType)
            buffResult:SetNotifyEntityID(notify:GetNotifyEntity():GetID())
        end

        if notify:GetNotifyType() == NotifyType.SuperGridTriggerEnd then
            buffResult:SetSuperGridTriggerEndPos(notify:GetTriggerPos())
        end

        if notify:GetNotifyType() == NotifyType.PoorGridTriggerEnd then
            buffResult:SetPoorGridTriggerEndPos(notify:GetTriggerPos())
        end
        if notify:GetNotifyType() == NotifyType.TrapSkillStart then--光灵米洛斯处理
            local superGridTriggerSkillID = 500202--强化格子触发技能ID 用于模拟通知，触发现有光灵被动
            if notify:GetSkillID() == superGridTriggerSkillID then
                buffResult:SetIsSuperGridTriggerStart(true)
                buffResult:SetSuperGridTriggerStartPos(notify:GetNotifyPos())
                if notify:GetIsActiveSkillFake() then
                    buffResult:SetSuperGridTriggerStartByActiveSkill(true)
                end
            end
        end
        local pet1601671 = {
            NotifyType.Pet1601781SkillHolder1,
            NotifyType.Pet1601781SkillHolder2,
            NotifyType.Pet1601781SkillHolder3,
        }

        if table.icontains(pet1601671, notify:GetNotifyType()) then
            buffResult:ReplaceCasterPos(notify:GetCasterPos())
            buffResult:SetPet1601781MultiCastCount(notify:GetMultiCastCount())
        end
        if notify:GetNotifyType() == NotifyType.PetMinosAbsorbTrap then--耶利亚 主动技 吸收强化格 造成伤害
            buffResult:SetPetAbsorbSuperGridTrapPos(notify:GetNotifyPos())
        end
        if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
            buffResult:SetMonsterWalkPos(notify:GetWalkPos())
        end
        if notify:GetNotifyType() == NotifyType.ChainSkillAttackEnd then
            buffResult:SetNotifyEntityID(notify:GetNotifyEntity():GetID())
            buffResult:SetNotifyChainSkillId(notify:GetChainSkillId())
            buffResult:SetNotifyChainSkillIndex(notify:GetChainSkillIndex())
        end
    end

    buffResult:SetNotSetLocation(self._notSetLocation)
    if self._checkTrapDie then
        self:_DoLogicTrapDie() --导致机关死亡 通知加deadflag
    end
    if self._checkMonsterDie then
        local deadIDList = self:_DoLogicMonsterDead() --导致机关死亡 通知加deadflag
        buffResult:SetSkillDeadMonsterEntityIDList(deadIDList)
    end
    return buffResult
end

function BuffLogicCastSkill:_DoLogicTrapDie()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    trapServiceLogic:CalcAllTrapDeadMark()

    local data = DataDeadMarkResult:New()
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if e:HasDeadMark() then
            data:AddDeadEntityID(e:GetID())
        end
    end
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
end
function BuffLogicCastSkill:_DoLogicMonsterDead()
    local drops = {}
    local deadEntityIDList = {}
    self:_DoLogicRecursMonsterDead(drops, deadEntityIDList)

    --表现立即刷死亡标记
    --local data = DataDeadMarkResult:New(deadEntityIDList)
    --self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, data)
    local deadEntityList = {}
    for _, id in ipairs(deadEntityIDList) do
        deadEntityList[#deadEntityList + 1] = self._world:GetEntityByID(id)
    end
    return deadEntityIDList
end
function BuffLogicCastSkill:_DoLogicCheckNewDead()
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        ---血量大于0，说明还没死
        local cAttributes = e:Attributes()
        local curHp = cAttributes:GetCurrentHP()
        if curHp <= 0 and not e:HasDeadMark() then
            return true
        end
    end

    return false
end
function BuffLogicCastSkill:_DoLogicRecursMonsterDead(drops, deadEntityIDList)
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        sMonsterShowLogic:AddMonsterDeadMark(e)
    end
    local tmpDrops, tmpDeadEntityIDList = sMonsterShowLogic:DoAllMonsterDeadLogic()
    table.appendArray(drops, tmpDrops)
    table.appendArray(deadEntityIDList, tmpDeadEntityIDList)

    local hasNewDead = self:_DoLogicCheckNewDead()
    if hasNewDead then
        self:_DoLogicRecursMonsterDead(drops, deadEntityIDList)
    end
end
---把本体的buff同步给skillHolder
function BuffLogicCastSkill:_OnSyncBuffFormSuperToSkillHolder(e, skillHolder)
    ---@type BuffComponent
    local superBuffCmpt = e:BuffComponent()

    ---@type BuffComponent
    local skillHolderBuffCmpt = skillHolder:BuffComponent()

    --锁血
    local lockHPAlways = superBuffCmpt:GetBuffValue("LockHPAlways")
    local lockHPByRound = superBuffCmpt:GetBuffValue("LockHPByRound")
    local lockHPType = superBuffCmpt:GetBuffValue("LockHPType")
    local lockHPList = superBuffCmpt:GetBuffValue("LockHPList")

    skillHolderBuffCmpt:SetBuffValue("LockHPAlways", lockHPAlways)
    skillHolderBuffCmpt:SetBuffValue("LockHPByRound", lockHPByRound)
    skillHolderBuffCmpt:SetBuffValue("LockHPType", lockHPType)
    skillHolderBuffCmpt:SetBuffValue("LockHPList", lockHPList)
end

----------------------------------------------------------------
