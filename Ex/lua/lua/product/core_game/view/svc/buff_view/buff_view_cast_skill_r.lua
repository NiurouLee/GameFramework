--[[
    播放技能表现
]]
_class("BuffViewCastSkill", BuffViewBase)
BuffViewCastSkill = BuffViewCastSkill

--是否匹配参数
function BuffViewCastSkill:IsNotifyMatch(notify)
    ---@type BuffResultCastSkill
    local result = self._buffResult
    local skillID = result:GetSkillID()
    local skillHolder = self._world:GetEntityByID(result:GetSkillHolderID())
    local skillHolderType = result:GetSkillHolderType()
    local attackPos = result:GetTargetPos()
    local targetId = result:GetTargetID()
    local casterPos = result:GetCastPos()
    if skillHolderType == SkillHolderType.AttackPosTargetId then
        local entity = self._entity
        if self._entity:HasTeam() then
            entity = self._entity:GetTeamLeaderPetEntity()
        end
        return attackPos == notify:GetAttackPos() and targetId == notify:GetDefenderEntity():GetID() and
                notify:GetNotifyEntity():GetID() == entity:GetID()
    end

    if notify:GetNotifyType() == NotifyType.GridConvert then
        --娜丁的灯自己不能触发自己
        local notifyEntity=notify:GetNotifyEntity()
        if notifyEntity == self._entity then
            return false
        end
        if not notifyEntity:HasRenderBoard()  and result:GetNotifyEntityID() ~= notifyEntity:GetID() then
            return false
        end
        -- 判断trigger位置限定
        if self:HasTriggerType(TriggerType.PossessedGridConverted) then
            local convertInfoArray = notify:GetConvertInfoArray()
            for _, convertInfo in ipairs(convertInfoArray) do
                local pos = convertInfo:GetPos()
                if pos == casterPos then
                    local oldPieceType = convertInfo:GetBeforePieceType()
                    local newPieceType = convertInfo:GetAfterPieceType()
                    local posIndex2OldPieceType = result:GetGridConvertOldPosIndexPieceType()
                    local posIndex2NewPieceType = result:GetGridConvertNewPosIndexPieceType()
                    local posIndex = Vector2.Pos2Index(pos)
                    if (oldPieceType == posIndex2OldPieceType[posIndex]) and (newPieceType == posIndex2NewPieceType[posIndex]) then
                        return true
                    end
                end
            end
            return false
        end
    end

    if notify:GetNotifyType() == NotifyType.Teleport then
        local posOld, posNew = result:GetTeleportPos()
        return posOld == notify:GetPosOld() and posNew == notify:GetPosNew()
    end

    if notify:GetNotifyType() == NotifyType.PlayerHPChange then
        local defenderID, casterID, hPPercent, changeHP = result:GetPlayerHPChangeData()
        return defenderID == notify:GetNotifyEntity():GetID() and casterID == notify:GetDamageSrcEntity() and
                (notify:GetMaxHP() == 0 or hPPercent == notify:GetHPPercent()) and
                changeHP == notify:GetChangeHP()
    end

    if notify:GetNotifyType() == NotifyType.MonsterDead then
        local deadEntityID = result:GetDeadEntityID()
        local deadMonsterEntity = notify:GetNotifyEntity()
        return deadEntityID == deadMonsterEntity:GetID()
    end

    if notify.__attackPosMatchRequired and (notify:GetNotifyType() == NotifyType.GridConvert) then
        local attackPos = {}
        for _, info in ipairs(notify:GetConvertInfoArray()) do
            table.insert(attackPos, info:GetPos())
        end
        local attackPosMatch = false
        for _, v2 in ipairs(attackPos) do
            attackPosMatch = attackPosMatch or (table.icontains(result:GetAttackPosArray(), v2))
        end
        return attackPosMatch
    end

    if notify:GetNotifyType() == NotifyType.NotifyLayerChange then
        ---@type NTNotifyLayerChange
        local n = notify

        if notify:GetLayerName() ~= result:GetLayerName() then
            return false
        end

        local viewMatchUseLayerCount = result:GetViewMatchUseLayerCount()
        if viewMatchUseLayerCount then
            return result:GetLayer() == n:GetLayer()
        else
            if result:IsUseCurAndTotalLayer() then
                if  result:GetCurLayer() ~= n:GetLayer() then
                    return false
                end
            end
            if result:GetTotalLayer() ~= n:GetTotalCount() then
                return false
            end
        end
    end

    if notify and notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        return result:GetNotifyMoveEndPos() == notify:GetPos()
    end
    if notify and notify:GetNotifyType() == NotifyType.SyncMoveEachMoveEnd then
        local bMatch = (result:GetNotifyMoveEndPos() == notify:GetPos())
                and (result:GetNotifySyncMovePathIndex() == notify:GetPathIndex())
        return bMatch
    end

    if notify:GetNotifyType() == NotifyType.HitBackEnd then
        return result:GetNotifyMoveEndPos() == notify:GetPosEnd()
    end

    if notify and notify:GetNotifyType() == NotifyType.SuperGridTriggerEnd then
        return result:GetSuperGridTriggerEndPos() == notify:GetTriggerPos()
    end

    if notify and notify:GetNotifyType() == NotifyType.PoorGridTriggerEnd then
        return result:GetPoorGridTriggerEndPos() == notify:GetTriggerPos()
    end
    if notify and notify:GetNotifyType() == NotifyType.TrapSkillStart then--光灵米洛斯处理
        local superGridTriggerSkillID = 500202--强化格子触发技能ID 用于模拟通知，触发现有光灵被动
        if notify:GetSkillID() == superGridTriggerSkillID then
            if result:GetIsSuperGridTriggerStart() then
                if notify:GetIsActiveSkillFake() then
                    if result:IsSuperGridTriggerStartByActiveSkill() then
                        return true
                    else
                        return false
                    end
                else
                    if result:GetSuperGridTriggerStartPos() == notify:GetNotifyPos() then
                        return true
                    else
                        return false
                    end
                end
            end
        end
    end

    local pet1601671 = {
        NotifyType.Pet1601781SkillHolder1,
        NotifyType.Pet1601781SkillHolder2,
        NotifyType.Pet1601781SkillHolder3,
    }

    if notify and table.icontains(pet1601671, notify:GetNotifyType()) then
        local chainSkillTypes = {
            SkillEffect_WeikeNotify_SkillType.ChainSkill1,
            SkillEffect_WeikeNotify_SkillType.ChainSkill2,
            SkillEffect_WeikeNotify_SkillType.ChainSkill3,
        }

        local triggerSkillType = notify:GetSkillType()
        if not table.icontains(chainSkillTypes, triggerSkillType) then
            return notify:GetCasterPos() == casterPos
        else
            local isPosValid = notify:GetCasterPos() == casterPos
            local isMultiCastCountValid = notify:GetMultiCastCount() == result:GetPet1601781MultiCastCount()
            return isPosValid and isMultiCastCountValid
        end
    end
    if notify and notify:GetNotifyType() == NotifyType.PetMinosAbsorbTrap then--耶利亚 主动技 吸收强化格 造成伤害
        return result:GetPetAbsorbSuperGridTrapPos() == notify:GetNotifyPos()
    end
    if notify and notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        return result:GetMonsterWalkPos() == notify:GetWalkPos()
    end
    if notify and notify:GetNotifyType() == NotifyType.ChainSkillAttackEnd then
        local entityCheckPass = false
        local atkEntity = notify:GetNotifyEntity()
        if atkEntity then
            entityCheckPass = (result:GetNotifyEntityID() == atkEntity:GetID())
        end
        local skillIndexPass = result:GetNotifyChainSkillIndex() == notify:GetChainSkillIndex()
        local skillIdPass = result:GetNotifyChainSkillId() == notify:GetChainSkillId()
        return entityCheckPass and skillIndexPass and skillIdPass
    end

    if result:GetNotifyIsOwnerSummoner() == 1 then
        ---@type Entity
        local ownerSummonerEntity = self._entity:GetSummonerEntity()
        if not ownerSummonerEntity then
            return false
        end

        return notify:GetNotifyEntity():GetID() == ownerSummonerEntity:GetID()
    end

    local triggers = result:GetTrigger()
    if triggers then
        for i = 1, #triggers do
            ---@type TriggerBase
            local trigger = triggers[i]
            if trigger:GetTriggerType() == TriggerType.NotifyMe then
                if notify:GetNotifyEntity() == self._entity then
                    return true
                else
                    return false
                end
            end
        end
    end

    return true
end

function BuffViewCastSkill:PlayView(TT, notify)
    ---@type BuffResultCastSkill
    local result = self._buffResult

    local skillID = result:GetSkillID()
    ---@type Entity
    local skillHolder = self._world:GetEntityByID(result:GetSkillHolderID())
    local skillHolderType = result:GetSkillHolderType()
    local attackPos = result:GetTargetPos()
    local targetId = result:GetTargetID()
    local casterPos = result:GetCastPos()
    local startTask = result:GetStartTask()
    local useSuperView = result:GetUseSuperEntityView()

    local deadMonsterEntityIdList = result:GetSkillDeadMonsterEntityIDList()
    --刷新死亡标记
    if deadMonsterEntityIdList then
        for _, eid in ipairs(deadMonsterEntityIdList) do
            local e = self._world:GetEntityByID(eid)
            e:AddDeadFlag()
        end
    end


    if skillHolderType == SkillHolderType.AttackPosTargetId then
        ---@type BuffResultCastSkillOnPosAndTarget
        local castSkillOnPosAndTarget = result:GetSkillResultOnPosAndTarget()
        local attackPos = notify:GetAttackPos()
        local targetId = notify:GetDefenderEntity():GetID()
        local skillResult = castSkillOnPosAndTarget:GetSkillResult(attackPos, targetId)
        if not skillResult then
            Log.error("BuffViewCastSkill AttackPosTargetId no result! attackPos=", attackPos, " targetId=", targetId)
            return
        end
        skillHolder:SkillRoutine():SetResultContainer(skillResult)
        Log.debug("BuffViewCastSkill skillID=", skillID, " attackPos=", attackPos, " targetId=", targetId)
    else
        local skillResult = result:GetSkillResult()
        skillHolder:SkillRoutine():SetResultContainer(skillResult)
    end

    --浮游炮特效的位置跟着人走，所以不能用逻辑坐标修改表现坐标
    if not skillHolder:HasEffectController() then
        --加上Offset，以解决炸弹BOSS被击晕时会向前挪一格的问题MSG15587
        if (result:GetNotSetLocationState() == 0) then
            skillHolder:SetPosition(skillHolder:GetGridPosition() + skillHolder:GetGridOffset())
        end
    end

    local playSkillSvc = self._world:GetService("PlaySkill")
    local configSvc = self._world:GetService("Config")
    local skillConfigData = configSvc:GetSkillConfigData(skillID, skillHolder)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray()

    self:_PatchFinalAttackForSpecificPet(skillHolder, result)
    
    if startTask == 0 then
        playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, skillID)
        if deadMonsterEntityIdList and #deadMonsterEntityIdList > 0 then
            ---@type MonsterShowRenderService
            local sMonsterShowRender = self._world:GetService("MonsterShowRender")
            sMonsterShowRender:DoAllMonsterDeadRender(TT)
        end
    else
        --在buff表里配置 startTask=1 的技能不会卡传进来的TT
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, skillID)
                if deadMonsterEntityIdList and #deadMonsterEntityIdList > 0 then
                    ---@type MonsterShowRenderService
                    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
                    sMonsterShowRender:DoAllMonsterDeadRender(TT)
                end
            end
        )
    end
end

---@param skillHolder Entity
---@param result BuffResultCastSkill
function BuffViewCastSkill:_PatchFinalAttackForSpecificPet(skillHolder, result)
    if not skillHolder:EntityType():IsSkillHolder() then
        return
    end

    ---@type SkillEffectResultContainer
    local container = skillHolder:SkillRoutine():GetResultContainer()

    ---@type UtilDataServiceShare
    local utilData = skillHolder:GetOwnerWorld():GetService("UtilData")

    --星灵用buff放的技能，施法者不是星灵，但是需要最后一击的表现
    local checkFinalAttack = result:GetCheckFinalAttack()
    if checkFinalAttack == 1 and utilData:IsFinalAttack() then
        container:SetFinalAttack(true)
    end

    ---@type Entity
    local casterEntity = skillHolder:GetSuperEntity()
    if not casterEntity:HasPetPstID() then
        return
    end

    --[[
        最后一击表现的所有相关代码，到现在为止都称不上对：
        * 判断时使用逻辑状态；
        * 在普攻/连锁/主动技计算阶段内控制具体播不播，超出这三个控制的部分无法正确判断
        * DeadMark添加会直接触发DeadFlag表现，ShowDeath在允许鞭尸的阶段也无法用来判断
        * 有没有触发过最后一击没有表现层的记录

        有意者自可削竹，行过时万望珍重
    ]]
    --米迦勒最后一击特殊处理-代码移除留念：MSG59653
end
