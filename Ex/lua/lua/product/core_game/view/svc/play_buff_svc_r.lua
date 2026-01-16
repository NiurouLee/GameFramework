--[[------------------------------------------------------------------------------------------
    PlayBuffService 负责buff的纯表现演播
]] --------------------------------------------------------------------------------------------

_class("PlayBuffService", BaseService)
---@class PlayBuffService:BaseService
PlayBuffService = PlayBuffService

function PlayBuffService:Constructor(world)
    self._configService = world:GetService("Config")
end

---@param entity Entity
function PlayBuffService:_OnGetPlayUnitTurnBuffViewTaskIDs(entity, notify, isDelay)
    local taskIDs = {}

    local viewIns = entity:BuffView():GetBuffViewInstanceArray()
    local views = {}
    ---@param inst BuffViewInstance
    for _, inst in ipairs(viewIns) do
        local buffEffectType = inst:GetBuffEffectType()
        local qualified = false
        if isDelay and table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType) then
            qualified = true
        elseif (not isDelay) and (not table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType)) then
            qualified = true
        end

        if qualified then
            local vs = inst:GetBuffView(notify)
            if vs then
                for index, value in ipairs(vs) do
                    views[#views + 1] = value
                end
            end
        end
    end
    if #views > 0 then
        local taskId =
        GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    for _, view in ipairs(views) do
                        Log.notice("play buff view ", view:ViewName(), " entityID=", entity:GetID())
                        view:PlayView(TT, notify)
                    end
                end
        )
        taskIDs[#taskIDs + 1] = taskId
    end

    return taskIDs
end

local canDelayNotifyType = {
    NotifyType.MonsterTurnStart, NotifyType.PlayerTurnStart
}

function PlayBuffService:PlayUnitTurnBuffView(TT, notify, isDelay, notRemove)
    -- wrong call, but we got you covered :)
    if (not table.icontains(canDelayNotifyType, notify:GetNotifyType())) then
        return self:PlayBuffView(TT, notify, notRemove)
    end

    local notifyEntity = notify:GetNotifyEntity()
    local notifyEntityID = 0
    if notifyEntity then
        notifyEntityID = notifyEntity:GetID()
    end
    Log.debug(
            "PlayUnitTurnBuffView() notify ",
            notify:GetNotifyType(),
            GetEnumKey("NotifyType", notify:GetNotifyType()),
            " notifyEntity=",
            notifyEntityID
    )

    local group = self._world:GetGroup(self._world.BW_WEMatchers.BuffView)
    local taskIDsAll = {}
    for _, e in ipairs(group:GetEntities()) do
        --检查目标死亡阶段 检查buff配置的触发时机
        if self:_OnCheckPlayConditions(e, notify) then
            local taskIDs = self:_OnGetPlayUnitTurnBuffViewTaskIDs(e, notify, isDelay)
            table.appendArray(taskIDsAll, taskIDs)
        end
    end

    JOIN_TASK_ARRAY(TT, taskIDsAll)

    local nt = notify:GetSubordinateNotify()
    if nt then
        self:PlayBuffView(TT, nt, notRemove)
    end

    if notRemove then
        return
    end
    --自动删除buff
    self:PlayAutoRemoveBuff(TT, notify)
end

--buffview表现
function PlayBuffService:PlayBuffView(TT, notify, notRemove)
    local notifyEntity = notify:GetNotifyEntity()
    local notifyEntityID = 0
    if notifyEntity then
        notifyEntityID = notifyEntity:GetID()
    end
    Log.debug(
        "PlayBuffView() notify ",
        notify:GetNotifyType(),
        GetEnumKey("NotifyType", notify:GetNotifyType()),
        " notifyEntity=",
        notifyEntityID
    )

    local group = self._world:GetGroup(self._world.BW_WEMatchers.BuffView)
    local taskIDsAll = {}
    for _, e in ipairs(group:GetEntities()) do
        --检查目标死亡阶段 检查buff配置的触发时机
        if self:_OnCheckPlayConditions(e, notify) then
            local taskIDs = self:_OnGetPlayBuffViewTaskIDs(e, notify)
            table.appendArray(taskIDsAll, taskIDs)
        end
    end

    JOIN_TASK_ARRAY(TT, taskIDsAll)

    local nt = notify:GetSubordinateNotify()
    if nt then
        self:PlayBuffView(TT, nt, notRemove)
    end

    if notRemove then
        return
    end
    --自动删除buff
    self:PlayAutoRemoveBuff(TT, notify)
end

---@param entity Entity
function PlayBuffService:_OnGetPlayBuffViewTaskIDs(entity, notify)
    local taskIDs = {}

    local viewIns = entity:BuffView():GetBuffViewInstanceArray()
    local views = {}
    ---@param inst BuffViewInstance
    for _, inst in ipairs(viewIns) do
        local vs = inst:GetBuffView(notify)
        if vs then
            for index, value in ipairs(vs) do
                views[#views + 1] = value
            end
        end
    end
    if #views > 0 then
        local taskId =
        GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    for _, view in ipairs(views) do
                        Log.notice("play buff view ", view:ViewName(), " entityID=", entity:GetID())
                        view:PlayView(TT, notify)
                    end
                end
        )
        taskIDs[#taskIDs + 1] = taskId
    end

    return taskIDs
end

---检查目标死亡阶段 检查buff配置的触发时机
---@param entity Entity
function PlayBuffService:_OnCheckPlayConditions(entity, notify)
    local play = false

    --如果buff的表现时机配置的是死亡播放
    if entity:HasShowDeath() then
        if
            notify:GetNotifyType() == NotifyType.MonsterDead or notify:GetNotifyType() == NotifyType.MonsterDeadStart or
                notify:GetNotifyType() == NotifyType.MonsterDeadEnd or
                notify:GetNotifyType() == NotifyType.ReduceShieldLayer
         then
            play = true
        end
    else
        play = true
    end

    return play
end

--播放全场所有entity的被动挂buff效果
function PlayBuffService:PlayAutoAddBuff(TT)
    Log.notice("PlayAutoAddBuff()!!!")
    local group = self._world:GetGroup(self._world.BW_WEMatchers.BuffView)
    for _, e in ipairs(group:GetEntities()) do
        local viewIns = e:BuffView():GetBuffViewInstanceArray()
        for _, inst in ipairs(viewIns) do
            self:PlayAddBuff(TT, inst)
        end
    end
end

function PlayBuffService:PlayBuffSeqs(TT, buffseqs)
    for _, v in ipairs(buffseqs) do
        local e = v[1]
        local seq = v[2]
        local buffViewInstance = e:BuffView():GetBuffViewInstance(seq)
        self:PlayAddBuff(TT, buffViewInstance)
    end
end

--自动移除buff阶段
function PlayBuffService:PlayAutoRemoveBuff(TT, notify)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.BuffView)
    for _, e in ipairs(group:GetEntities()) do
        local viewIns = e:BuffView():GetBuffViewInstanceArray()
        for i = #viewIns, 1, -1 do
            local inst = viewIns[i]
            if inst:IsUnload(notify) and not inst:HasBuffView() then
                self:PlayRemoveBuff(TT, inst, notify)
            end
        end
    end
end

---添加buff，技能挂buff的时候需要指定来源casterEntityID
---@param buffViewInstance BuffViewInstance
function PlayBuffService:PlayAddBuff(TT, buffViewInstance, casterEntityID)
    buffViewInstance:SetShow()

    local entity = buffViewInstance:Entity()
    --控制类buff按优先级互斥
    self:AttachBuffEffect(buffViewInstance)

    --view表现
    local views = buffViewInstance:GetBuffView(NTBuffLoad:New(buffViewInstance:Entity(), casterEntityID))
    if views then
        for index, view in ipairs(views) do
            Log.notice("play add buff: view ", view:ViewName())
            view:PlayView(TT, nil, Log.traceback())
        end
    end

    --头顶特效
    self:PlayBuffHeadEffect(entity)

    --UI表现
    self:PlayUIChangeBuff(entity)

    local ntAddBuffEnd =
        NTAddBuffEnd:New(entity, buffViewInstance:BuffSeq(), buffViewInstance:BuffID(), buffViewInstance:GetBuffType())
    self:PlayBuffView(TT, ntAddBuffEnd)

    if buffViewInstance:GetBuffType() == BuffType.Control then
        ---@type NTAddControlBuffEnd
        local nt = NTAddControlBuffEnd:New(entity, buffViewInstance:BuffSeq(), buffViewInstance:BuffID(), buffViewInstance:GetBuffType())
        self:PlayBuffView(TT, nt)
    end
end

function PlayBuffService:PlayUIChangeBuff(entity)
    ---@type Entity
    local team
    if entity:HasTeam() then
        team = entity
    elseif entity:HasPet() then
        team = entity:Pet():GetOwnerTeamEntity()
    end
    if team and self._world:Player():IsLocalTeamEntity(team) then
        local teamBuffList = team:BuffView():GetBuffTeamStateShowList()
        self._world:EventDispatcher():Dispatch(GameEventType.ChangeTeamBuff, teamBuffList)
    end

    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff, entity:GetID())
end

---播放buff移除表现
---@param buffViewInstance BuffViewInstance
function PlayBuffService:PlayRemoveBuff(TT, buffViewInstance, notify)
    if notify then
        --手动删除buff的view表现要播一下，注意防止无限递归
        self:PlayBuffView(TT, notify, true)
    end
    --特效移除
    self:DetachBuffEffect(buffViewInstance)

    local entity = buffViewInstance:Entity()
    --移除view
    entity:RemoveBuffViewInstance(buffViewInstance)
    --头顶特效处理
    self:PlayBuffHeadEffect(entity)

    --UI表现
    self:PlayUIChangeBuff(entity)
end

function PlayBuffService:PlayPlayerTurnStartBuff(TT, teamEntity, formerTeamOrder, isDelayed)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:PlayUnitTurnBuffView(TT, NTPlayerTurnStart:New(teamEntity, formerTeamOrder), isDelayed)
end

--玩家回合结算表现
function PlayBuffService:PlayPlayerTurnBuff(TT, teamEntity, formerTeamOrder, isDelayed)
    --DOT结算
    --self:PlayDOTDamage(TT, {playerEntity}, NTPlayerTurnStart:New())

    --通知回合开始，进行buff表现
    -- MSG57649 如果你正在查的东西没在这播，你得看一下ChainAttackStateSystem
    self:PlayPlayerTurnStartBuff(TT, teamEntity, formerTeamOrder, isDelayed)
    --self:PlayBuffView(TT, NTPlayerTurnStart:New(teamEntity, formerTeamOrder))

    self:PlayBuffView(TT, NTEnemyTurnStart:New(teamEntity))
    self:PlayBuffView(TT, NTPlayerTurnStartLast:New())

    self:PlayBuffView(TT, NTPlayerTurnBuffAddRoundEnd:New(teamEntity))
    self:PlayBuffView(TT, NTPlayerTurnBuffAddRoundEndAfter:New(teamEntity))
end

--怪物回合结算表现
function PlayBuffService:PlayMonsterTurnBuff(TT, isDelay)
    --因MSG55703要求同一个通知在不同时机触发，复制了一套PlayBuffView的逻辑，加入了根据配置筛选的功能
    self:PlayUnitTurnBuffView(TT, NTMonsterTurnStart:New(), isDelay)
    self:PlayBuffView(TT, NTMonsterTurnAfterAddBuffRound:New())
end

function PlayBuffService:PlayChessTurnBuff(TT)
    self:PlayBuffView(TT, NTPlayerTurnStart:New())
end

function PlayBuffService:PlayMonsterTurnDelayedBuff(TT)
    self:PlayBuffView(TT, NTMonsterTurnAfterDelayedAddBuffRound:New())
end

---给目标挂上buff特效
---@param buffViewInstance BuffViewInstance
function PlayBuffService:AttachBuffEffect(buffViewInstance)
    local targetEntity = buffViewInstance:Entity()
    if 0 == buffViewInstance:GetBuffEffectEntityID() then
        local targetEffectID = buffViewInstance:BuffConfigData():GetLoadEffectID()
        if targetEffectID == nil then
            return
        end

        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local effectEntity = effectService:CreateEffect(targetEffectID, targetEntity)
        buffViewInstance:SetBuffEffectEntityID(effectEntity:GetID())
    end
end

---删除目标身上的buff特效
function PlayBuffService:DetachBuffEffect(buffViewInstance)
    if not buffViewInstance then
        return
    end
    local buffEffectEntityID = buffViewInstance:GetBuffEffectEntityID()
    local buffEffectEntity = self._world:GetEntityByID(buffEffectEntityID)
    if buffEffectEntity then
        self._world:DestroyEntity(buffEffectEntity)
    end
    buffViewInstance:SetBuffEffectEntityID(0)
end

--无条件删除全部buff
function PlayBuffService:RemoveAllBuff(TT, entity)
    ---@type BuffViewComponent
    local buffViewCom = entity:BuffView()
    if not buffViewCom then
        return
    end
    local t = table.shallowcopy(buffViewCom:GetBuffViewInstanceArray())
    for i = #t, 1, -1 do
        local buffv = t[i]
        self:PlayRemoveBuff(TT, buffv, NTBuffUnload:New())
    end
end

--处理头顶buff
function PlayBuffService:PlayBuffHeadEffect(entity)
    if not entity:BuffView() then
        return
    end
    local head_buff = entity:BuffView():GetHeadBuff()
    local com = entity:BuffHeadEffect()
    if not com then
        entity:AddBuffHeadEffect(head_buff)
    else
        local oldbv = com:GetBuffViewInstance()
        if oldbv ~= head_buff then
            --删除特效
            self:DetachBuffEffect(oldbv)
            com:SetBuffViewInstance(head_buff)
        end
    end
end

--处理DOT伤害结算
-- function PlayBuffService:PlayDOTDamage(TT, es, notify)
--     --找出所有dot buff
--     local dot_dic = {}
--     for _, e in ipairs(es) do
--         local dot1 = {}
--         for _, buff in ipairs(e:BuffView():GetBuffArray()) do
--             if buff:GetBuffType() == BuffType.DOT then
--                 local priority = buff:GetBuffPriority()
--                 local dot = dot_dic[priority] or {}
--                 dot[#dot + 1] = buff
--                 dot_dic[priority] = dot
--             end
--         end
--     end

--     local get_dotes = function(dots)
--         local dotes = {}
--         for _, buff in ipairs(dots) do
--             dotes[buff:Entity()] = 1
--         end
--         return dotes
--     end

--     --合并优先级
--     local dot_merge = {}
--     local idx = 1
--     for priority, dots in pairs(dot_dic) do
--         local prev_dots = dot_merge[idx]
--         if prev_dots then
--             --如果本集合dot和上个集合dot的entity没有交集就可以合并
--             local es1 = get_dotes(prev_dots)
--             local es2 = get_dotes(dots)
--             local es3 = table.union(es1, es2)
--             if #es3 == 0 then
--                 table.appendArray(dot_merge[idx], dots)
--             else
--                 dot_merge[idx] = dots
--                 idx = idx + 1
--             end
--         else
--             dot_merge[idx] = dots
--             idx = idx + 1
--         end
--     end
--     if #dot_merge > 0 then
--         --按照dot组播放DOT伤害
--         for i, dots in ipairs(dot_merge) do
--             for _, buff in ipairs(dots) do
--                 local views = buff:ViewInstance():GetBuffView(notify)
--                 for index, view in ipairs(views) do
--                     self:PlayDamageBuff(TT, view)
--                 end
--             end
--             YIELD(TT, 1000)
--         end
--     end
-- end

--通用伤害飘字
function PlayBuffService:PlayDamageBuff(TT, buffView)
    local buffResult = buffView:GetBuffResult()
    if buffResult == nil then
        return
    end
    ---@type PlayDamageService
    local PlayDamageService = self._world:GetService("PlayDamage")

    ---@type DamageInfo
    local damageInfo = buffResult:GetDamageInfo()

    ---@type DamageType
    local damageType = damageInfo:GetDamageType()
    local targetId = damageInfo:GetTargetEntityID()
    local targetEntity = buffView:Entity()
    if targetId then
        targetEntity = self._world:GetEntityByID(targetId)
    end
    PlayDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)

    if damageType == DamageType.Guard then
    elseif damageType == DamageType.Miss then
    else
        local hitAnim = "Hit"
        targetEntity:SetAnimatorControllerTriggers({hitAnim})
        if buffView:BuffViewInstance():GetBuffType() == BuffType.DOT then
            YIELD(TT, BattleConst.DamageBuffAnimatorHitDelay)
        end
    end
end

function PlayBuffService:RefreshLockHPView(TT, gsmState)
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local round = utilStatSvc:GetStatCurWaveTotalRoundCount()
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        ---@type BuffViewComponent
        local buffView = monsterEntity:BuffView()
        if buffView and not buffView:IsAlwaysHPLock() then
            if buffView:IsHPNeedUnLock(round - 1, gsmState) then
                local index = buffView:GetHPLockIndex()
                ---@type HPComponent
                local hpComponent = monsterEntity:HP()
                if hpComponent:IsShowHPSlider() then
                    local sepPoolWidget = hpComponent:GetSepPoolWidget()
                    if sepPoolWidget then
                        local sepPool = sepPoolWidget:GetAllSpawnList()
                        sepPool[index]:GetGameObject():SetActive(false)
                    else
                        Log.fatal("monster has no lockhp res,ID:", monsterEntity:GetID())
                    end
                end
                hpComponent:AddHPLockUnlockedIndex(index)--点击怪物时显示的ui血条上的锁血信息 需要从hpcomt里读

                GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPLock, index, false)
                Log.warn(" View NotifyBreakHPLock Index:", index)
                self._world:GetService("PlayBuff"):PlayBuffView(TT, NTBreakHPLock:New(monsterEntity))
                buffView:ResetHPLockState()
            end
        end
    end
end

function PlayBuffService:LoadArchivedLockHPView(TT, arch)
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        ---@type BuffViewComponent
        local buffView = monsterEntity:BuffView()
        local unlockIndex = buffView:GetUnlockHPIndex()
        if unlockIndex then
            for _, idx in ipairs(unlockIndex) do
                ---@type HPComponent
                local hpComponent = monsterEntity:HP()
                if hpComponent:IsShowHPSlider() then
                    local sepPoolWidget = hpComponent:GetSepPoolWidget()
                    if sepPoolWidget then
                        local sepPool = sepPoolWidget:GetAllSpawnList()
                        sepPool[idx]:GetGameObject():SetActive(false)
                    else
                        Log.fatal("monster has no lockhp res,ID:", monsterEntity:GetID())
                    end
                end
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeBossHPLock, idx, false)
            end
        end
    end
end

--通知技能开始
function PlayBuffService:_OnAttackStart(TT, skillID, attacker, defender, attackPos, beAttackPos, damageInfo)
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, attacker)
    local isMatch = false
    if attacker:HasPetPstID() then
        isMatch = true
        ---@type SkillConfigData
        local skillConfigData = self._configService:GetSkillConfigData(skillID, attacker)
        if skillConfigData:GetSkillType() == SkillType.Normal then
            self:PlayBuffView(TT, NTNormalAttackChangeBefore:New(attacker, attackPos, beAttackPos))
            self:PlayBuffView(TT, NTNormalEachAttackStart:New(attacker, defender, attackPos, beAttackPos))
        end
        if skillConfigData:GetSkillType() == SkillType.Chain then
            local skillResult = attacker:SkillRoutine():GetResultContainer()
            local chainIndex = skillResult:GetCurChainSkillIndex()
            local notify = NTChainSkillEachAttackStart:New(attacker, defender, attackPos, beAttackPos)
            notify:SetChainSkillIndex(chainIndex)
            if damageInfo and damageInfo.GetRandHalfDamageIndex then
                local randHalfDamageIndex = damageInfo:GetRandHalfDamageIndex()
                if randHalfDamageIndex then
                    notify:SetRandHalfDamageIndex(randHalfDamageIndex)
                end
            end
            self:PlayBuffView(TT, notify)
        end
        if skillConfigData:GetSkillType() == SkillType.Active then
            self:PlayBuffView(TT, NTActiveSkillEachAttackStart:New(attacker, defender, attackPos, beAttackPos))
        end
    elseif attacker:HasMonsterID() then
        isMatch = true
        self:PlayBuffView(TT, NTMonsterEachAttackStart:New(attacker, defender, attackPos, beAttackPos))
    elseif attacker:HasTrapID() then
        isMatch = true
        self:PlayBuffView(TT, NTTrapEachAttackStart:New(attacker, defender, attackPos, beAttackPos))
    end
    if not isMatch then
        self:PlayBuffView(TT, NTBuffCastSkillEachAttackBegin:New(attacker, defender, attackPos, beAttackPos))
    end
    if defender:HasMonsterID() then
        local nt = NTMonsterBeHitStart:New(attacker, defender, attackPos, beAttackPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillConfigData:GetSkillType())
        self:PlayBuffView(TT, nt)
    end
    if defender:HasPetPstID() or defender:HasTeam() then
        local nt = NTPlayerBeHitStart:New(attacker, defender, attackPos, beAttackPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillConfigData:GetSkillType())
        self:PlayBuffView(TT, nt)
    end
end

--通知技能结束
---@param attacker Entity
function PlayBuffService:_OnAttackEnd(TT, skillID, attacker, defender, attackPos, beAttackPos, damageIndex, damageInfo)
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID, attacker)
    if attacker:HasPetPstID() then
        if skillConfigData:GetSkillType() == SkillType.Normal then
            self:PlayBuffView(TT, NTNormalEachAttackEnd:New(attacker, defender, attackPos, beAttackPos))
        end
        if skillConfigData:GetSkillType() == SkillType.Chain then
            local skillResult = attacker:SkillRoutine():GetResultContainer()
            local chainIndex = skillResult:GetCurChainSkillIndex()
            local notify = NTChainSkillEachAttackEnd:New(attacker, defender, attackPos, beAttackPos)
            notify:SetChainSkillIndex(chainIndex)
            if damageInfo and damageInfo.GetRandHalfDamageIndex then
                local randHalfDamageIndex = damageInfo:GetRandHalfDamageIndex()
                if randHalfDamageIndex then
                    notify:SetRandHalfDamageIndex(randHalfDamageIndex)
                end
            end
            self:PlayBuffView(TT, notify)
        end
        if skillConfigData:GetSkillType() == SkillType.Active then
            self:PlayBuffView(TT, NTActiveSkillEachAttackEnd:New(attacker, defender, attackPos, beAttackPos))
        end
    elseif attacker:HasMonsterID() then
        --怪物伤害区分普攻与其他技能
        if skillConfigData:GetSkillType() == SkillType.Normal then
            self:PlayBuffView(TT, NTMonsterEachAttackEnd:New(attacker, defender, attackPos, beAttackPos))
        end
        self:PlayBuffView(TT, NTMonsterEachDamageEnd:New(attacker, defender, attackPos, beAttackPos))
    elseif attacker:HasTrapID() then
        self:PlayBuffView(TT, NTTrapEachAttackEnd:New(attacker, defender, attackPos, beAttackPos))
    elseif attacker:EntityType():IsSkillHolder() then
        self:PlayBuffView(TT, NTBuffCastSkillEachAttackEnd:New(attacker, defender, attackPos, beAttackPos))
    end

    if defender:HasMonsterID() then
        local nt = NTMonsterBeHit:New(attacker, defender, attackPos, beAttackPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillConfigData:GetSkillType())
        if damageInfo and damageInfo.GetDamageStageIndex then
            local damageStageIndex = damageInfo:GetDamageStageIndex()
            if damageStageIndex then
                nt:SetDamageStageIndex(damageStageIndex)
            end
        end
        if damageInfo and damageInfo.GetCurSkillDamageIndex then
            local curSkillDamageIndex = damageInfo:GetCurSkillDamageIndex()
            if curSkillDamageIndex then
                nt:SetCurSkillDamageIndex(curSkillDamageIndex)
            end
        end
        self:PlayBuffView(TT, nt)
    end
    if defender:HasPetPstID() or defender:HasTeam() then
        local nt = NTPlayerBeHit:New(attacker, defender, attackPos, beAttackPos)
        nt:SetDamageIndex(damageIndex)
        self:PlayBuffView(TT, nt)
    end
    if defender:HasChessPet() then
        local nt = NTChessBeHit:New(attacker, defender, attackPos, beAttackPos)
        nt:SetSkillID(skillID)
        nt:SetSkillType(skillConfigData:GetSkillType())
        self:PlayBuffView(TT, nt)
    end
end

function PlayBuffService:_SendNTGridConvertRender(TT, pos, pieceType, effectType)
    local boardEntity = self._world:GetRenderBoardEntity()
    local tConvertInfo = {}

    local convertInfo = NTGridConvert_ConvertInfo:New(Vector2(pos.x, pos.y), PieceType.None, pieceType)
    table.insert(tConvertInfo, convertInfo)
    local ntGridConvert = NTGridConvert:New(boardEntity, tConvertInfo)
    ntGridConvert:SetConvertEffectType(effectType)
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")
    svcPlayBuff:PlayBuffView(TT, ntGridConvert)
end
