require "command_base_handler"

_class("CastActiveSkillCommandHandler", CommandBaseHandler)
---@class CastActiveSkillCommandHandler: CommandBaseHandler
CastActiveSkillCommandHandler = CastActiveSkillCommandHandler

---@param cmd CastActiveSkillCommand
function CastActiveSkillCommandHandler:DoHandleCommand(cmd)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local activeSkillID = cmd:GetCmdActiveSkillID()
    local activeSkillData = BattleSkillCfg(activeSkillID)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local round = battleStatCmpt:GetLevelTotalRoundCount()

    local casterPetEntityID = 0

    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    local skillcfg = cfgsvc:GetSkillConfigData(activeSkillID)
    
    local useFeatureType = nil
    --根据技能id 读取技能类型
    if (activeSkillData.Type == SkillType.Active) then
        --玩家主动技能
        local petPstID = cmd:GetCmdCasterPstID()
        casterPetEntityID = self:GetEntityIDByPstID(petPstID)
        ---@type Entity
        local casterPetEntity = self._world:GetEntityByID(casterPetEntityID)
        local casterPos = casterPetEntity:GridLocation().Position
        local casterDir = casterPetEntity:GridLocation().Direction

        local localSkillID = casterPetEntity:SkillInfo():GetActiveSkillID()
        local extraSkillList = casterPetEntity:SkillInfo():GetExtraActiveSkillIDList()--是附加主动技
        if extraSkillList and table.icontains(extraSkillList,activeSkillID) then
            localSkillID = activeSkillID
        else
            --变体
            local variantActiveSkillInfo = casterPetEntity:SkillInfo():GetVariantActiveSkillInfo()
            if variantActiveSkillInfo then
                local variantList = variantActiveSkillInfo[localSkillID]
                if variantList and table.icontains(variantList,activeSkillID) then
                    localSkillID = activeSkillID
                end
            end
        end
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(localSkillID, casterPetEntity)
        activeSkillID = skillConfigData:GetID()

        --region MSG70205
        ---MSG70205 世界BOSS，格兹德，局内使用伊芙，可以刷房间词条导致无限cd
        ---此接口前禁止添加任何Notify通知
        self:_ResetSkillGrayWatch(teamEntity, petPstID, activeSkillID)
        --endregion MSG70205

        --region CD检查
        if not self:CheckActiveSkillCastCondition(petPstID, activeSkillID) then
            ---@type AttributesComponent
            local attributeCmpt = casterPetEntity:Attributes()
            ---@type UtilDataServiceShare
            local utilData = self._world:GetService("UtilData")
            local ready = utilData:GetPetSkillReadyAttr(casterPetEntity,activeSkillID)
            --local ready = attributeCmpt:GetAttribute("Ready")

            local errorMsg
            if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
                local curLegendPower = attributeCmpt:GetAttribute("LegendPower")

                errorMsg = "LegendPet ActiveSkill failed,logic LegendPower:" ..
                    tostring(curLegendPower) .. " ReadyState:" .. tostring(ready) .. " localSkillID:" .. localSkillID
            else
                --local curPower = attributeCmpt:GetAttribute("Power")
                local curPower = utilData:GetPetPowerAttr(casterPetEntity,activeSkillID)
                --主动技
                errorMsg = " ActiveSkill failed,logic power:" ..
                    tostring(curPower) .. " ReadyState:" .. tostring(ready) .. " localSkillID:" .. localSkillID
            end
            self:_HandleServerSyncFailed(BattleFailedType.ActiveSkillCDError, errorMsg)
            return
        end
        --endregion

        --region 特殊条件：对于特殊主动技，宝宝是队长时不能释放
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        if utilData:IsSkillDisabledWhenCasterIsTeamLeader(petPstID, activeSkillID) then
            local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
            if teamLeaderEntityID == casterPetEntityID then
                self:_HandleServerSyncFailed(BattleFailedType.HeboBaseActiveSkillCannotCastAsTeamLeader, "Cannot cast when caster is team leader! ")
                return
            end
        end
        --endregion

        --region San值
        ---@type FeatureServiceLogic
        local lsvcFeature = self._world:GetService("FeatureLogic")
        if lsvcFeature:HasFeatureType(FeatureType.Sanity) then
            ---@type FeatureSanActiveSkillCanCastContext
            local context = {}
            local utilScopeSvc = self._world:GetService("UtilScopeCalc")
            ---@type SkillScopeResult
            local scopeResult = utilScopeSvc:CalcSkillScope(skillcfg, casterPos, casterPetEntity, casterDir)
            local attackRange = scopeResult:GetAttackRange() or {}
            context.scopeGridCount = #attackRange
            if not lsvcFeature:IsActiveSkillCanCast(casterPetEntity, activeSkillID, context) then
                self:_HandleServerSyncFailed(BattleFailedType.NotEnoughSan, "not enough san")
                return
            end
            local san, hpPercent, hpConvertSan = lsvcFeature:CalcActiveSkillSanCost(casterPetEntity, activeSkillID, context)
            local curSanValue,oldSanValue,realModifyValue,debtVal,modifyTimes = lsvcFeature:DecreaseSanValue(san)
            local nt = NTSanValueChange:New(curSanValue, oldSanValue,debtVal,modifyTimes)
            self._world:GetService("Trigger"):Notify(nt)
            if self._world:RunAtClient() then
                ---@type FeatureServiceRender
                local rsvcFeature = self._world:GetService("FeatureRender")
                rsvcFeature:NotifySanValueChange(curSanValue, oldSanValue, realModifyValue)
                GameGlobal.TaskManager():CoreGameStartTask(function (TT)
                    self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)
                end)
            end
            if hpPercent > 0 then
                local eTeam = casterPetEntity:Pet():GetOwnerTeamEntity()
                local maxHP = eTeam:Attributes():CalcMaxHp()
                local val = maxHP * hpPercent
                ---@type CalcDamageService
                local lsvcCalcDamage = self._world:GetService("CalcDamage")
                local damageInfo = lsvcCalcDamage:DoCalcDamage(casterPetEntity, eTeam, {
                    formulaID = 130,
                    hp = val,
                    skillID = activeSkillID
                })
                if self._world:RunAtClient() then
                    ---@type PlayDamageService
                    local rsvcPlayDamage = self._world:GetService("PlayDamage")
                    rsvcPlayDamage:AsyncUpdateHPAndDisplayDamage(eTeam, damageInfo)
                end
            end
        end
        --endregion
        --region 释放主动技时扣除生命值
        ---@type table<SkillTriggerTypeExtraParam, any>
        local triggerExtraParam = skillcfg:GetSkillTriggerExtraParam()
        if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.HPValPercent] then
            local paramHPVal = triggerExtraParam[SkillTriggerTypeExtraParam.HPValPercent]
            if paramHPVal then
                local eTeam = casterPetEntity:Pet():GetOwnerTeamEntity()
                local maxHPPercent = paramHPVal[1]
                local remainHPPercent = paramHPVal[2]
                -- local ignoreShieldParam = paramHPVal[3] or 0
                -- local ignoreShield = (ignoreShieldParam == 1)
                local casterCurrentHP = eTeam:Attributes():GetCurrentHP()
                local casterMaxHP = eTeam:Attributes():CalcMaxHp()
                local requiredMaxVal = math.ceil(casterMaxHP * maxHPPercent)
                local remainHP = casterCurrentHP - requiredMaxVal
                -- 先判断按最大生命值扣除的量
                if remainHP <= 0 then
                    self:_HandleServerSyncFailed(BattleFailedType.NotEnoughHP, table.concat({"remainHP:",tostring(remainHP),"currentHP:",casterCurrentHP}))
                    return
                end
                -- 再判断按剩余生命值扣除的量
                local requiredRemainHP = math.ceil(remainHP * remainHPPercent)
                if requiredRemainHP >= remainHP then
                    self:_HandleServerSyncFailed(BattleFailedType.NotEnoughHP, table.concat({"remainHP:",tostring(remainHP),"currentHP:",casterCurrentHP}))
                    return
                end
                -- HPValPercent 不再执行扣血，只用于判断，扣血用技能效果85
                -- -- 执行阶段
                -- ---@type CalcDamageService
                -- local lsvcCalcDamage = self._world:GetService("CalcDamage")
                -- local damageInfo = lsvcCalcDamage:DoCalcDamage(casterPetEntity, eTeam, {
                --     formulaID = 130,
                --     hp = (requiredMaxVal + requiredRemainHP),
                --     skillID = activeSkillID
                -- },ignoreShield)
                -- if self._world:RunAtClient() then
                --     ---@type PlayDamageService
                --     local rsvcPlayDamage = self._world:GetService("PlayDamage")
                --     rsvcPlayDamage:AsyncUpdateHPAndDisplayDamage(eTeam, damageInfo)
                -- end
            end
        end
        --endregion
        --region 杰诺 卡牌不能满
        if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.CardNotFull] then
            ---@type FeatureServiceLogic
            local lsvcFeature = self._world:GetService("FeatureLogic")
            if lsvcFeature:HasFeatureType(FeatureType.Card) then
                if not lsvcFeature:CanAddCard() then
                    self:_HandleServerSyncFailed(BattleFailedType.CardFull, "card full")
                    return
                end
            end
        end
        --endregion

        self:_ClearActivePower(teamEntity, petPstID,activeSkillID)
        battleStatCmpt:AddActiveSkillCount(teamEntity)
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local isExtraSkill,extraSkillIndex = utilData:IsPetExtraActiveSkill(casterPetEntity,activeSkillID)
        if not isExtraSkill then
            battleStatCmpt:SetLastDoActiveSkillRound(petPstID, round)
        else
            battleStatCmpt:SetLastDoActiveSkillRound(petPstID, round,extraSkillIndex)
        end
        battleStatCmpt:SetPetDoActiveSkillRecord(petPstID, round, activeSkillID)
        battleStatCmpt:RecordCurRoundDoActiveSkillTimes(petPstID)
    elseif activeSkillData.Type == SkillType.TrapSkill then
        --机关技能
        casterPetEntityID = cmd:GetCmdCasterTrapEntityID()
        ---@type Entity
        local casterPetEntity = self._world:GetEntityByID(casterPetEntityID)
        --判定是否是玩家召唤的机关且机关被覆盖，若被覆盖，则无法释放技能
        local isPetTrapOverlap = false
        ---@type UtilScopeCalcServiceShare
        local utilScopeCalc = self._world:GetService("UtilScopeCalc")
        local trapPos = casterPetEntity:GetGridPosition()
        if casterPetEntity:Trap():IsPetTrapCastSkill() and utilScopeCalc:IsPosHaveMonsterOrPet(trapPos) then
            isPetTrapOverlap = true
        end
        ---@type AttributesComponent
        local attributeCmpt = casterPetEntity:Attributes()
        local curPower = attributeCmpt:GetAttribute("TrapPower")
        local count = attributeCmpt:GetAttribute("SkillCount")
        if (curPower <= 0 or count <= 0 or isPetTrapOverlap) and activeSkillData.TriggerParam ~= 0 then
            local errorMsg =
            "CastActiveSkillCommandHandler cast trap skill error! curPower" .. curPower .. " skillCount=" .. count

            self:_HandleServerSyncFailed(BattleFailedType.ActiveSkillCDError, errorMsg)
            return
        end
        --设置新的能量
        local newTrapPower = curPower - activeSkillData.TriggerParam
        attributeCmpt:Modify("TrapPower", newTrapPower)
        --记录释放技能的回合
        local castSkillRound = attributeCmpt:GetAttribute("CastSkillRound")
        table.insert(castSkillRound, round)
        attributeCmpt:Modify("CastSkillRound", castSkillRound)

        --减少一次使用技能次数
        local skillCount = attributeCmpt:GetAttribute("SkillCount")
        skillCount = skillCount - 1
        if skillCount <= 0 then
            skillCount = 0
        end
        attributeCmpt:Modify("SkillCount", skillCount)
    elseif activeSkillData.Type == SkillType.FeatureSkill then
        local bCanCast = false
        useFeatureType = FeatureType.PersonaSkill
        ---@type FeatureServiceLogic
        local lsvcFeature = self._world:GetService("FeatureLogic")
        if lsvcFeature then
            ---@type table<SkillTriggerTypeExtraParam, any>
            local triggerExtraParam = skillcfg:GetSkillTriggerExtraParam()
            if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType] then
                useFeatureType = triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType]
            end
            if lsvcFeature:CheckFeatureSkillCastCondition(useFeatureType,activeSkillID) then
                lsvcFeature:OnFeatureSkillCast(useFeatureType,activeSkillID)
                bCanCast = true
                casterPetEntityID = lsvcFeature:GetFeatureSkillHolderEntityID(useFeatureType)
            end
        end
        if not bCanCast then
            self:_HandleServerSyncFailed(BattleFailedType.ActiveSkillCDError, "persona skill cd error")
            return
        end
    end

    self._world:GetDataLogger():AddDataLog("OnLinkEnd")
    self._world:GetDataLogger():AddDataLog("OnShowStart")

    if activeSkillData.Type == SkillType.FeatureSkill then
        ---@type FeatureSkillComponent
        local featureSkillCmpt = teamEntity:FeatureSkill()
        featureSkillCmpt:SetFeatureSkillID(useFeatureType,activeSkillID, casterPetEntityID)
        if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
            self._world:EventDispatcher():Dispatch(GameEventType.PreviewActiveSkillFinish, 4)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 11)
        end
    else
        ---@type ActiveSkillComponent
        local activeSkillCmpt = teamEntity:ActiveSkill()
        activeSkillCmpt:SetActiveSkillID(activeSkillID, casterPetEntityID)
        if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
            self._world:EventDispatcher():Dispatch(GameEventType.PreviewActiveSkillFinish, 2)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 2)
        end
    end
    
end
