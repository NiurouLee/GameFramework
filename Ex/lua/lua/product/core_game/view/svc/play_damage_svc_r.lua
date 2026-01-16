--[[
    伤害飘字和血条刷新
]]
---@class DamageShowType
DamageShowType = {
    Single = 1, ---单体伤害
    Grid = 2 ---格子伤害
}

require("battle_svc_l")
require("play_skill_svc_r")

_class("PlayDamageService", BaseService)
---@class PlayDamageService:BaseService
PlayDamageService = PlayDamageService

function PlayDamageService:Constructor(world)
    self._damageType2EntityID = {
        [DamageType.Normal] = EntityConfigIDRender.NormalDamage,
        [DamageType.Real] = EntityConfigIDRender.RealDamage,
        [DamageType.RealReflexive] = EntityConfigIDRender.RealDamage,
        [DamageType.RealDead] = EntityConfigIDRender.RealDamage,
        [DamageType.Recover] = EntityConfigIDRender.RecoverDamage,
        [DamageType.Guard] = EntityConfigIDRender.GuardDamage,
        [DamageType.Miss] = EntityConfigIDRender.MissDamage,
        [DamageType.Burn] = EntityConfigIDRender.DeBuffDamage,
        [DamageType.Poison] = EntityConfigIDRender.DeBuffDamage,
        [DamageType.Bleed] = EntityConfigIDRender.DeBuffDamage,
        [DamageType.Explode] = EntityConfigIDRender.DeBuffDamage,
        [DamageType.Critical] = EntityConfigIDRender.CriticalDamage,
        [DamageType.NoElementNormal] = EntityConfigIDRender.NormalDamage,
        [DamageType.RealTransmit] = EntityConfigIDRender.RealDamage,
        [DamageType.RecoverTransmit] = EntityConfigIDRender.RecoverDamage
    }

    self._damageElementType = {
        [ElementType.ElementType_Blue] = "water",
        [ElementType.ElementType_Red] = "fire",
        [ElementType.ElementType_Green] = "wood",
        [ElementType.ElementType_Yellow] = "thunder"
    }

    self._deBuffElementType = {
        [DamageType.Real] = "real",
        [DamageType.Burn] = "burn",
        [DamageType.Poison] = "poison",
        [DamageType.Bleed] = "bleed",
        [DamageType.Explode] = "bleed"
    }

    self._isDamageTypeNoFigure = {
        [DamageType.Guard] = true,
        [DamageType.Miss] = true
    }

    self.__NTMonsterHPCChangeCount = 0

    --局内作弊 隐藏飘字
    self._cheatHideDamageDisplay = false
end

--异步加血飘字防止卡流程
---@param damageInfo DamageInfo
function PlayDamageService:AsyncUpdateHPAndDisplayDamage(defenderEntity, damageInfo)

    if defenderEntity:MonsterID() and defenderEntity:MonsterID():GetDamageSyncMonsterID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        ---@type Entity[]
        local damageSyncEntityList =  utilDataSvc:FindMonsterByMonsterID(defenderEntity:MonsterID():GetDamageSyncMonsterID())
        for i, entity in ipairs(damageSyncEntityList) do
            local pos = entity:GetRenderGridPosition()
            ---@type DamageInfo
            local newDamageInfo = DamageInfo:New()
            newDamageInfo:Clone(damageInfo)
            newDamageInfo:SetShowPosition(pos)
            newDamageInfo:SetRenderGridPos(pos)
            newDamageInfo:SetTargetEntityID(entity:GetID())
            ----Log.fatal("DamageInfo Pos:",pos,"DamageInfoTargetID:",newDamageInfo:GetTargetEntityID(),"DamageInfoTargetPos:",newDamageInfo:GetShowPosition())
            self:AsyncUpdateHPAndDisplayDamage(entity, newDamageInfo)
        end
    end

    return GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            --血条刷新
            self:UpdateTargetHPBar(TT, defenderEntity, damageInfo)
            --血量变化的buff通知表现
            self:_OnHpChangeNotifyBuff(TT, defenderEntity, damageInfo:GetChangeHP(), damageInfo)
            --伤害飘字
            self:DisplayDamage(TT, defenderEntity, damageInfo)
        end
    )
end

--多阶段伤害飘字
function PlayDamageService:AsyncUpdateHPAndDisplayDamageMultiStage(
    defenderEntity,
    damageInfoList,
    damageStageValueList,
    intervalTime)
    if defenderEntity:MonsterID() and defenderEntity:MonsterID():GetDamageSyncMonsterID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local damageSyncEntityList =  utilDataSvc:FindMonsterByMonsterID(defenderEntity:MonsterID():GetDamageSyncMonsterID())
        for i, entity in ipairs(damageSyncEntityList) do
            local pos = entity:GetRenderGridPosition()
            ---@type
            local newDamageInfoList = {}
            for i, info in ipairs(damageInfoList) do
                ---@type DamageInfo
                local newDamageInfo = DamageInfo:New()
                newDamageInfo:Clone(info)
                newDamageInfo:SetShowPosition(pos)
                newDamageInfo:SetRenderGridPos(pos)
                newDamageInfo:SetTargetEntityID(entity:GetID())
                table.insert(newDamageInfoList, newDamageInfo)
            end
            self:AsyncUpdateHPAndDisplayDamageMultiStage(entity,newDamageInfoList,damageStageValueList,intervalTime)
        end
    end

    GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                --血条刷新
                --因为血条要和飘字同时播放，血条表现不能阻塞，所以新开协程
                -- GameGlobal.TaskManager():CoreGameStartTask(
                --     self.UpdateTargetHPBarMultiStage,
                --     self,
                --     defenderEntity,
                --     damageInfoList,
                --     intervalTime,
                --     damageStageValueList
                -- )

                --血量变化的buff通知表现
                self:_OnHpChangeNotifyBuff(TT, defenderEntity, damageStageValueList[#damageStageValueList], damageInfoList[#damageInfoList])

                --多段伤害飘字
                self:DisplayDamage(TT, defenderEntity, damageInfoList[#damageInfoList], damageStageValueList, intervalTime)
            end
    )
end

--无论加血还是扣血都用这个函数刷血条
---@param damageInfoList DamageInfo[] 伤害数据
function PlayDamageService:UpdateTargetHPBarMultiStage(
        TT,
        defenderEntity,
        damageInfoList,
        intervalTime,
        damageStageValueList)
    --每一个伤害都即时刷新
    -- for i = 1, table.count(damageInfoList) do
    --     local damageInfo = damageInfoList[i]
    --     --血条刷新
    --     self:UpdateTargetHPBar(TT, defenderEntity, damageInfo)

    --     YIELD(TT, intervalTime)
    -- end

    --只刷新最后一个伤害
    for i = 1, table.count(damageStageValueList) - 1 do
        YIELD(TT, intervalTime)
    end
    self:UpdateTargetHPBar(TT, defenderEntity, damageInfoList[#damageInfoList])
end
--无论加血还是扣血都用这个函数刷血条
---@param damageInfo DamageInfo 伤害数据
function PlayDamageService:UpdateTargetHPBar(TT, defenderEntity, damageInfo)
    --刷新HUD血条
    self:_RefreshHudHpBar(TT, defenderEntity, damageInfo)

    --刷新bossUI血条
    self:_RefreshBossHP(TT, defenderEntity, damageInfo)

    --刷新队伍UI血条
    self:_RefreshTeamHP(TT, defenderEntity, damageInfo)
end

---血量变化的buff通知表现
function PlayDamageService:_OnHpChangeNotifyBuff(TT, defenderEntity, changeHP, damageInfo)
    --血量变化通知表现
    local svcPlayBuff = self._world:GetService("PlayBuff")
    ---@type HPComponent
    local hp_cmpt = defenderEntity:HP()
    local maxhp = hp_cmpt:GetMaxHP()
    local redhp = hp_cmpt:GetRedHP()
    local attackerID = damageInfo:GetAttackerEntityID()
    if defenderEntity:PetPstID() or defenderEntity:HasTeam() then
        local nt = NTPlayerHPChange:New(defenderEntity, redhp, maxhp, nil, changeHP, attackerID)
		nt:SetAttackPos(damageInfo:GetAttackPos())
		nt:SetDamageInfo(damageInfo)
        svcPlayBuff:PlayBuffView(TT, nt)
    elseif defenderEntity:HasMonsterID() then
        local nt =  NTMonsterHPCChange:New(defenderEntity, redhp, maxhp, self.__NTMonsterHPCChangeCount)
        nt:SetChangeHP(changeHP)
        nt:SetDamageSrcEntityID(attackerID)
		nt:SetAttackPos(damageInfo:GetAttackPos())
		nt:SetDamageInfo(damageInfo)
        svcPlayBuff:PlayBuffView(TT,nt)
        self.__NTMonsterHPCChangeCount = self.__NTMonsterHPCChangeCount + 1
    elseif defenderEntity:HasTrapID() then
        local nt =  NTTrapHpChange:New(defenderEntity, redhp, maxhp)
        nt:SetChangeHP(changeHP)
        nt:SetDamageSrcEntityID(attackerID)
		nt:SetAttackPos(damageInfo:GetAttackPos())
		nt:SetDamageInfo(damageInfo)
        svcPlayBuff:PlayBuffView(TT,nt)
    elseif defenderEntity:HasChessPet() then
        local nt = NTChessHPChange:New(defenderEntity, redhp, maxhp)
        nt:SetChangeHP(changeHP)
        nt:SetDamageSrcEntityID(attackerID)
		nt:SetAttackPos(damageInfo:GetAttackPos())
		nt:SetDamageInfo(damageInfo)
        svcPlayBuff:PlayBuffView(TT,nt)
    end
end

--刷新HUD血条[秘境刷血条重载]
---@param defenderEntity Entity
function PlayDamageService:_RefreshHudHpBar(TT, defenderEntity, damageInfo)
    if defenderEntity:PetPstID() then
        defenderEntity = defenderEntity:Pet():GetOwnerTeamEntity()
    end
    ---世界Boss走单独的表现血量结算
    if defenderEntity:MonsterID() and defenderEntity:MonsterID():IsWorldBoss() then
        self:_RefreshWorldBossHP(defenderEntity, damageInfo)
        return
    end
    ---@type HPComponent
    local hp_cmpt = defenderEntity:HP()
    if hp_cmpt == nil then
        Log.fatal("UpdateTargetHPBar() hp cmpt is nil defenderEntity=", defenderEntity:GetID())
        return
    end
    local svcPlayBuff = self._world:GetService("PlayBuff")

    --修改HUD红血条
    local damageType = damageInfo:GetDamageType()
    local maxhp = hp_cmpt:GetMaxHP()
    local changeHP = damageInfo:GetChangeHP()
    local redhp = hp_cmpt:GetRedHP()
    redhp = math.floor(math.max(math.min(redhp + changeHP, maxhp), 0))
    defenderEntity:ReplaceRedHPAndWhitHP(redhp)
    Log.debug("UpdateTargetHPBar() entityID=", defenderEntity:GetID(), " changeHP=", changeHP, " redhp=", redhp)

    --血条盾
    local curShield = damageInfo:GetHPShield()
    if curShield then
        --因为表现顺序与逻辑顺序不一致 改用delta的方式--只处理伤害相关的护盾修改
        local shieldDelta = damageInfo:GetHPShieldDelta()
        if shieldDelta then--非伤害情况下这个是nil
            local newShieldValue = hp_cmpt:GetShieldValue() + shieldDelta
            hp_cmpt:SetShieldValue(newShieldValue)
        else
            hp_cmpt:SetShieldValue(curShield)
        end
    end

    --诅咒血条
    local curCurseHp = damageInfo:GetCurseHp()
    if curCurseHp then
        --因为表现顺序与逻辑顺序不一致 改用delta的方式--只处理伤害相关的护盾修改
        local curseHpDelta = damageInfo:GetCurseHpDelta()
        if curseHpDelta then--非伤害情况下这个是nil
            local newCurseHpValue = hp_cmpt:GetCurseHpValue() + curseHpDelta
            hp_cmpt:SetCurseHpValue(newCurseHpValue)
        else
            hp_cmpt:SetCurseHpValue(curCurseHp)
        end
    end

    --即死buff血条破碎特效
    local percent = defenderEntity:BuffView():GetBuffValue("SecKillHPPercent")
    if (redhp == 0 and percent) or damageType == DamageType.RealDead then
        self._world:EventDispatcher():Dispatch(GameEventType.HPSliderBroken, defenderEntity:GetID())
    end

    --锁血表现通知
    if damageInfo:IsTriggerHPLock() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        utilDataSvc:UpdateRenderHPLockInfoByLogic(defenderEntity)
        local nt = NTHPLock:New()
        nt:SetNotifyEntity(defenderEntity)
        svcPlayBuff:PlayBuffView(TT, nt)
    end

    ---伤害被护盾抵挡的表现效果
    if damageType == DamageType.Guard then
        if defenderEntity:HasTrapID() and defenderEntity:TrapRender():GetTrapType() == TrapType.Protected then
            self:GetService("Effect"):CreateEffect(BattleConst.AircraftHitShieldEffect, defenderEntity)
        end
        if damageInfo:GetShieldLayer() then
            svcPlayBuff:PlayBuffView(TT, NTReduceShieldLayer:New(defenderEntity, damageInfo:GetShieldLayer()))
        end
    end
end

---@param defenderEntity Entity
---@param damageInfo DamageInfo
function PlayDamageService:_RefreshWorldBossHP(defenderEntity, damageInfo)
    --修改HUD红血条
    ---@type HPComponent
    local hp = defenderEntity:HP()

    local damageType = damageInfo:GetDamageType()
    local changeHP = damageInfo:GetChangeHP()
    if damageType == DamageType.RealDead then
        if EDITOR then
            Log.exception("WorldBoss  DamageType Is RealDead ")
        end
    end
    local damage = changeHP * -1

    local changeInfoList = {}
    while changeHP < 0 do
        local curStageHP = hp:GetCurStageHP()
        local changeStage = false
        local newHP = curStageHP + changeHP
        if newHP < 0 then
            changeStage = true
            hp:SwitchStage()
            local redImageID = hp:GetCurStageImage()
            local yellowImageID = hp:GetPreStageImage()
            table.insert(
                changeInfoList,
                {redHP = 0, whiteHP = 0, changeStage = true, redImageID = redImageID, yellowImageID = yellowImageID}
            )
        else
            hp:SetStageHP(newHP)
            local hpPercent = 1 - hp:GetCurStageHPPercent()
            table.insert(changeInfoList, {redHP = hpPercent, whiteHP = hpPercent, changeStage = false})
        end
        changeHP = curStageHP + changeHP
    end
    local stage = hp:GetCurStage()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.UpdateWorldBossHP,
        defenderEntity:GetID(),
        changeInfoList,
        damage,
        stage
    )
end

--刷新bossUI血条
---@param defenderEntity Entity
function PlayDamageService:_RefreshBossHP(TT, defenderEntity, damageInfo)
    local hasBoss = defenderEntity:HasBoss()

    --身上有buff标志 自己显示在BOSS血条（映镜的墙壁）
    local curShowBossHP = defenderEntity:BuffView():HasBuffEffect(BuffEffectType.CurShowBossHP)
    if hasBoss or curShowBossHP then
        if not defenderEntity:MonsterID():IsWorldBoss() then
            local maxhp = defenderEntity:HP():GetMaxHP()
            local redhp = defenderEntity:HP():GetRedHP()
            local hpPercent = redhp / maxhp
            --当血量<1%时，显示1%
            if redhp > 0 and hpPercent < 0.01 then
                hpPercent = 0.01
            end
            --血条盾
            --local curShield = damageInfo:GetHPShield()
            local curShield = defenderEntity:HP():GetShieldValue()

            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, defenderEntity:GetID(), hpPercent, redhp, maxhp)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, defenderEntity:GetID(), hpPercent, redhp, maxhp)
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.UpdateBossShield,
                defenderEntity:GetID(),
                curShield,
                redhp,
                maxhp
            )

            local greyVal = defenderEntity:HP():GetGreyHP()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossGreyHP, defenderEntity:GetID(), greyVal, redhp, maxhp)
            local showCurseHp = defenderEntity:HP():GetShowCurseHp()
            local curseHpValue = defenderEntity:HP():GetCurseHpValue()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossCurseHP, defenderEntity:GetID(), showCurseHp, curseHpValue, redhp, maxhp)
        end
    end
end

--刷新队伍UI血条
---@param entity Entity
function PlayDamageService:_RefreshTeamHP(TT, entity, damageInfo)
    ---@type Entity
    local teamEntity = nil
    if entity:HasPetPstID() then
        teamEntity = entity:Pet():GetOwnerTeamEntity()
    else
        teamEntity = entity
    end
    if teamEntity:HasTeam() then
        ---@type HPComponent
        local hpCmpt = teamEntity:HP()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.TeamHPChange,
            {
                isLocalTeam = self._world:Player():IsLocalTeamEntity(teamEntity),
                currentHP = hpCmpt:GetRedHP(),
                maxHP = hpCmpt:GetMaxHP(),
                hitpoint = hpCmpt:GetWhiteHP(),
                shield = hpCmpt:GetShieldValue(),
                entityID = teamEntity:GetID(),
                showCurseHp = hpCmpt:GetShowCurseHp(),
                curseHpVal = hpCmpt:GetCurseHpValue()
            }
        )
    end
end

---显示飘字
---@param defenderEntity Entity
---@param damageInfo DamageInfo
function PlayDamageService:DisplayDamage(TT, defenderEntity, damageInfo, damageStageValueList, intervalTime)
    if self._cheatHideDamageDisplay then
        return
    end
    ---@type TrapRenderComponent
    local trapRenderCmpt = defenderEntity:TrapRender()
    if trapRenderCmpt and trapRenderCmpt:GetTrapType() ~= TrapType.Protected then
        return --是机关，不是保护机关不显示伤害
    end

    --飘字格子渲染坐标
    local beAttackPos = damageInfo:GetShowPosition()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local beAttackRenderPos
    ---单体伤害 打在被击目标中心
    if damageInfo:GetShowType() == DamageShowType.Single then
        local gridPos = defenderEntity:GetDamageCenter()
        if not gridPos then
            Log.fatal("PlayDamageService displayDamage defenderEntity has no damage center ", defenderEntity:GetID())
            return
        end

        --local gridPos = defenderEntity:GetRenderGridPosition()
        local tmpPos = boardServiceRender:GridPos2RenderPos(gridPos)
        beAttackRenderPos = Vector3(tmpPos.x, tmpPos.y + BattleConst.SingleDamageNumberShowHeight, tmpPos.z)
    else
        local gridPos = damageInfo:GetRenderGridPos()
        if not gridPos then
            gridPos = defenderEntity:GetDamageCenter()
            Log.debug("SkillDamageNoPos")
        end
        if not gridPos then
            Log.fatal("PlayDamageService displayDamage defenderEntity has no damage center ", defenderEntity:GetID())
            return
        end

        local tmpPos = boardServiceRender:GridPos2RenderPos(gridPos)
        beAttackRenderPos = Vector3(tmpPos.x, tmpPos.y + BattleConst.GridDamageNumberShowHeight, tmpPos.z)
    end

    --region MSG56570
    local eAvatar
    if defenderEntity:HasTeam() then
        local eTeamLeader = defenderEntity:Team():GetTeamLeaderEntity()
        local cEffectHolder = eTeamLeader:EffectHolder()
        if cEffectHolder then
            ---@type Entity[]
            local tAvatar = cEffectHolder:GetEffectList("BuffViewShowHidePetRoot") or {}
            eAvatar = tAvatar[1]
        end
    else
        local cEffectHolder = defenderEntity:EffectHolder()
        if cEffectHolder then
            ---@type Entity[]
            local tAvatar = cEffectHolder:GetEffectList("BuffViewShowHidePetRoot") or {}
            eAvatar = tAvatar[1]
        end
    end

    if eAvatar then
        local damageCenter = eAvatar:GetDamageCenter()
        local tmpPos = boardServiceRender:GridPos2RenderPos(damageCenter)
        beAttackRenderPos = Vector3.New(tmpPos.x, tmpPos.y + BattleConst.GridDamageNumberShowHeight, tmpPos.z)
    end
    --endregion MSG56570

    damageInfo:SetShowPosition(beAttackRenderPos)

    ---在秘境中受击是队伍飘字是队长的
    if self._world:MatchType() == MatchType.MT_Maze and defenderEntity:HasTeam() then
        defenderEntity = defenderEntity:GetTeamLeaderPetEntity()
        local showDamage = math.abs(damageInfo:GetMazeDamageValue(defenderEntity:GetID()) or 0)
        damageInfo:SetDamageValue(showDamage)
    end
    ----HUD飘字过程
    if not damageStageValueList then
        GameGlobal.TaskManager():CoreGameStartTask(self._ShowDamageTask, self, damageInfo)
    else
        --HUD连续飘字
        GameGlobal.TaskManager():CoreGameStartTask(
            self._ShowDamageTaskMultiStage,
            self,
            damageInfo,
            damageStageValueList,
            intervalTime
        )
    end

    --掉落
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    if damageInfo and damageInfo:GetDropAssetList() then
        local beAttackPos = boardServiceRender:BoardRenderPos2GridPos(beAttackRenderPos)
        playSkillService:DoDropAnimation(damageInfo:GetDropAssetList(), beAttackPos)
    end
end

function PlayDamageService:SingleOrGrid(skillID)
    if not skillID then
        return DamageShowType.Grid
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local selectMode = skillConfigData:GetTargetSelectionModeConfig()
    if selectMode and selectMode == SkillTargetSelectionMode.Entity then
        return DamageShowType.Single
    else
        return DamageShowType.Grid
    end
    --local scopeType = skillConfigData:GetSkillScopeType()
    --if scopeType ~= SkillScopeType.Nearest and scopeType ~= SkillScopeType.NearestGrid then
    --    return DamageShowType.Grid
    --else
    --    return DamageShowType.Single
    --end
end

---@param hudEntity Entity
---HUD飘字过程
function PlayDamageService:_ShowDamageTask(TT, damageInfo)
    --如果是真实伤害 and 伤害数值是0。则返回
    if damageInfo:GetDamageType() == DamageType.RealDead and damageInfo:GetDamageValue() == 0 then
        return
    end

    --1 HUD创建
    ---@type Entity
    local hudEntity, uiview, viewObj = self:_PlayHudDamageCreate(TT, damageInfo)

    --2 初始坐标
    local damagePos = damageInfo:GetShowPosition()
    if not damagePos then
        damagePos = hudEntity:Location().Position
    end
    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    local pos = renderBattleService:GridRenderPos2HudWorldPos(damagePos)
    pos.z = 0
    viewObj.transform.position = pos

    YIELD(TT)
    YIELD(TT)

    --3 飘字的表现
    viewObj.transform:DOScale(Vector3(1, 1, 1), 0.16)
    if not self._damageCount then
        self._damageCount = 0
    end
    if self._damageCount == 1000 * (#BattleConst.DamageHighestPointList) then
        self._damageCount = 0
    end
    self._damageCount = self._damageCount + 1
    local damagePosIndex = self._damageCount % (#BattleConst.DamageHighestPointList) + 1
    local damagePos = BattleConst.DamageHighestPointList[damagePosIndex]

    damagePos =
        Vector3(
        viewObj.transform.position.x + damagePos.x,
        damagePos.y + viewObj.transform.position.y,
        viewObj.transform.position.z
    )
    ----Log.fatal("Damage:",damageInfo:GetDamageValue(),"damageCount:",self._damageCount,"OldPos:",tostring(viewObj.transform.position),"NewPosOffSet:", tostring(BattleConst.DamageHighestPointList[damagePosIndex]),"NewPos:",damagePos)
    viewObj.transform:DOMove(damagePos, 0.16)

    YIELD(TT, 160)

    -- 4 HUD消失
    self:_PlayHudDamageDisappear(TT, uiview, hudEntity)
end

---@param hudEntity Entity
---HUD连续飘字过程
function PlayDamageService:_ShowDamageTaskMultiStage(TT, damageInfo, damageStageValueList, intervalTime)
    --1 HUD创建
    local hudEntity, uiview, viewObj = self:_PlayHudDamageCreate(TT, damageInfo)

    --2 初始坐标（和单独飘字不同，有坐标补充）
    local damagePos = damageInfo:GetShowPosition()
    if not damagePos then
        damagePos = hudEntity:Location().Position
    end
    --字体不移动 这里补充下位置
    damagePos = damagePos + Vector3(-0.5, 0.5, 0)
    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    local pos = renderBattleService:GridRenderPos2HudWorldPos(damagePos)
    pos.z = 0
    viewObj.transform.position = pos

    YIELD(TT)
    YIELD(TT)

    --3 连续飘字的表现
    local damageType = damageInfo:GetDamageType()
    if not self._isDamageTypeNoFigure[damageType] then
        local textCtrl = uiview:GetUIComponent("UILocalizationText", "Text")
        for i = 1, #damageStageValueList do
            textCtrl:SetText(tostring(damageStageValueList[i]))

            viewObj.transform.position = pos
            local moveToPos = pos + Vector3(0, 0.1, 0)
            local tweenerMove = viewObj.transform:DOMove(moveToPos, intervalTime / 1000)

            viewObj.transform.localScale = Vector3(1, 1, 1)
            local tweenerScale = viewObj.transform:DOScale(Vector3(1.5, 1.5, 1), intervalTime / 1000)

            YIELD(TT, intervalTime)
            tweenerMove:Kill()
            tweenerScale:Kill()
        end
    end

    YIELD(TT, 160)

    -- 4 HUD消失
    self:_PlayHudDamageDisappear(TT, uiview, hudEntity)
end

---HUD飘字创建
---@return Entity,UIView,UnityEngine.GameObject
function PlayDamageService:_PlayHudDamageCreate(TT, damageInfo)
    local damageType = damageInfo:GetDamageType()
    local entityID = self._damageType2EntityID[damageType]
    ---@type RenderEntityService
    local entityService = self._world:GetService("RenderEntity")
    local hudEntity = entityService:CreateRenderEntity(entityID, true)

    ---@type ViewComponent
    local viewCmpt = hudEntity:View()
    ---@type UnityEngine.GameObject
    local viewObj = viewCmpt:GetGameObject()
    viewObj.transform.localScale = Vector3(2, 2, 1)
    viewCmpt.ViewWrapper:SetVisible(true)
    ---@type UIView
    local uiview = viewObj:GetComponent("UIView")
    ---@type UnityEngine.UI.Text
    local textCtrl = nil
    ---@type UnityEngine.UI.Image
    local elementImage = nil
    --护盾效果没有伤害数字
    ---@type UnityEngine.UI.Image
    elementImage = uiview:GetUIComponent("Image", "elementIcon")
    if not self._isDamageTypeNoFigure[damageType] then
        textCtrl = uiview:GetUIComponent("UILocalizationText", "Text")
        if textCtrl then
            textCtrl:SetText(tostring(math.floor(damageInfo:GetDamageValue())))
            textCtrl.color = Color(1, 1, 1, 1)
        end
        elementImage.color = Color(1, 1, 1, 1)
        if damageType ~= DamageType.Recover then
            local elementIconName = nil
            if damageType == DamageType.Normal then ---攻击伤害
                elementIconName = self._damageElementType[damageInfo:GetElementType()]
            else
                elementIconName = self._deBuffElementType[damageType]
            end
            if elementIconName ~= nil then
                elementImage.sprite = InnerGameHelperRender:GetInstance():GetImageFromInnerUI(elementIconName)
                elementImage.color = Color(1, 1, 1, 1)
            end
            if damageType == DamageType.NoElementNormal then
                elementImage.gameObject:SetActive(false)
            end
        end
    end

    return hudEntity, uiview, viewObj
end

---@param hudEntity Entity
---HUD飘字消失
function PlayDamageService:_PlayHudDamageDisappear(TT, uiview, hudEntity)
    ---@type UnityEngine.UI.Text
    local textCtrl = uiview:GetUIComponent("UILocalizationText", "Text")

    ---@type UnityEngine.UI.Image
    local elementImage = uiview:GetUIComponent("Image", "elementIcon")

    local frame = 1
    local fadeFrame = 20
    while frame <= fadeFrame do
        if textCtrl then
            textCtrl.color = Color(1, 1, 1, (fadeFrame - frame) / fadeFrame)
        end
        if elementImage then
            elementImage.color = Color(1, 1, 1, (fadeFrame - frame) / fadeFrame)
        end
        frame = frame + 1
        YIELD(TT)
    end
    if textCtrl then
        textCtrl.color = Color(1, 1, 1, 0)
    --Log.fatal("Text Alpha:",textCtrl.color.a)
    end
    if elementImage then
        elementImage.color = Color(1, 1, 1, 0)
    --Log.fatal("Image Alpha:",elementImage.color.a)
    end
    self._world:DestroyEntity(hudEntity)
end

function PlayDamageService:TTUpdateHPAndDisplayDamage(TT, defenderEntity, damageInfo)
    if defenderEntity:MonsterID() and defenderEntity:MonsterID():GetDamageSyncMonsterID() then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        ---@type Entity[]
        local damageSyncEntityList =  utilDataSvc:FindMonsterByMonsterID(defenderEntity:MonsterID():GetDamageSyncMonsterID())
        for i, entity in ipairs(damageSyncEntityList) do
            local pos = entity:GetRenderGridPosition()
            ----@type DamageInfo
            local newDamageInfo = DamageInfo:New()
            newDamageInfo:Clone(damageInfo)
            newDamageInfo:SetShowPosition(pos)
            newDamageInfo:SetRenderGridPos(pos)
            newDamageInfo:SetTargetEntityID(entity:GetID())
            ---Log.fatal("DamageInfo Pos:",pos,"DamageInfoTargetID:",newDamageInfo:GetTargetEntityID(),"DamageInfoTargetPos:",newDamageInfo:GetShowPosition())
            self:TTUpdateHPAndDisplayDamage(TT, entity, newDamageInfo)
        end
    end

    --血条刷新
    self:UpdateTargetHPBar(TT, defenderEntity, damageInfo)
    --血量变化的buff通知表现
    self:_OnHpChangeNotifyBuff(TT, defenderEntity, damageInfo:GetChangeHP(), damageInfo)
    --伤害飘字
    self:DisplayDamage(TT, defenderEntity, damageInfo)
end
---局内作弊用 隐藏伤害飘字
function PlayDamageService:CheatHideDamageDisplay(bHide)
    self._cheatHideDamageDisplay = bHide
end
