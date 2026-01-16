require "command_base_handler"

_class("CastPickUpSkillCommandHandler", CommandBaseHandler)
---@class CastPickUpSkillCommandHandler: CommandBaseHandler
CastPickUpSkillCommandHandler = CastPickUpSkillCommandHandler

---@param cmd CastPickUpActiveSkillCommand
function CastPickUpSkillCommandHandler:DoHandleCommand(cmd)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local activeSkillID = cmd:GetCmdActiveSkillID()
    local activeSkillData = BattleSkillCfg(activeSkillID)
    local petPstID = cmd:GetCmdCasterPstID()
    local casterPetEntity, casterPos, casterDir
    if petPstID and (petPstID > 0) then
        casterPetEntity = teamEntity:Team():GetPetEntityByPetPstID(petPstID)
        casterPos = casterPetEntity:GridLocation().Position
        casterDir = casterPetEntity:GridLocation().Direction
    end

    local pickUpGridList = cmd:GetCmdPickUpResult()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local round = battleStatCmpt:GetLevelTotalRoundCount()
    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    local skillcfg = cfgsvc:GetSkillConfigData(activeSkillID, casterPetEntity)

    --根据技能id 读取技能类型
    if activeSkillData.Type == SkillType.Active then
        local castPetEntity = self:GetEntityByPstID(petPstID)

        --点选组件拆分
        --region 点选组件拆分暂时屏蔽
        --     ---@type ActiveSkillPickUpComponent
        --     local activeSkillPickUpComponent = castPetEntity:ActiveSkillPickUpComponent()
        --     if not activeSkillPickUpComponent then
        --         castPetEntity:AddActiveSkillPickUpComponent()
        --         activeSkillPickUpComponent = castPetEntity:ActiveSkillPickUpComponent()
        --     end
        --     activeSkillPickUpComponent:ClearGridPos()
        --     activeSkillPickUpComponent:AddGridPosList(pickUpGridList)
        --     activeSkillPickUpComponent:AddDirectionList(cmd:GetDirectionPickupData())
        --     activeSkillPickUpComponent:SetReflectDir(cmd:GetReflectDir())
        --     activeSkillPickUpComponent:AddPickExtraParamList(cmd:GetCmdPickUpExtraParamResult())
        --region end

        if
            self:CheckActiveSkillCastCondition(petPstID, activeSkillID) and
                self:CheckPickUpValid(castPetEntity, activeSkillID, cmd)
         then
            --点选组件拆分 设置移到检查前 --region 点选组件拆分暂时屏蔽
            --region 点选组件拆分暂时屏蔽
            ---@type ActiveSkillPickUpComponent
            local activeSkillPickUpComponent = castPetEntity:ActiveSkillPickUpComponent()
            if not activeSkillPickUpComponent then
                castPetEntity:AddActiveSkillPickUpComponent()
                activeSkillPickUpComponent = castPetEntity:ActiveSkillPickUpComponent()
            end
            activeSkillPickUpComponent:ClearGridPos()
            activeSkillPickUpComponent:AddGridPosList(pickUpGridList)
            activeSkillPickUpComponent:AddDirectionList(cmd:GetDirectionPickupData())
            activeSkillPickUpComponent:SetReflectDir(cmd:GetReflectDir())
            activeSkillPickUpComponent:AddPickExtraParamList(cmd:GetCmdPickUpExtraParamResult())
            --region end
            
            --region MSG70205
            ---MSG70205 世界BOSS，格兹德，局内使用伊芙，可以刷房间词条导致无限cd
            ---此接口前禁止添加任何Notify通知
            self:_ResetSkillGrayWatch(teamEntity, petPstID, activeSkillID)
            --endregion MSG70205

            self:_ClearActivePower(teamEntity, petPstID,activeSkillID)
            battleStatCmpt:AddActiveSkillCount(teamEntity)
            ---@type UtilDataServiceShare
            local utilData = self._world:GetService("UtilData")
            local isExtraSkill,extraSkillIndex = utilData:IsPetExtraActiveSkill(castPetEntity,activeSkillID)
            if not isExtraSkill then
                battleStatCmpt:SetLastDoActiveSkillRound(petPstID, round)
            else
                battleStatCmpt:SetLastDoActiveSkillRound(petPstID, round,extraSkillIndex)
            end
            battleStatCmpt:SetPetDoActiveSkillRecord(petPstID, round, activeSkillID)

            self._world:GetDataLogger():AddDataLog("OnLinkEnd")
            self._world:GetDataLogger():AddDataLog("OnShowStart")

            local casterPetEntityID = castPetEntity:GetID()

            ---@type ActiveSkillComponent
            local activeSkillCmpt = teamEntity:ActiveSkill()
            activeSkillCmpt:SetActiveSkillID(activeSkillID, casterPetEntityID)
            ---@type LogicPickUpComponent
            local logicPickUpCmpt = teamEntity:LogicPickUp()
            logicPickUpCmpt:SetLogicCurActiveSkillInfo(activeSkillID, castPetEntity:PetPstID():GetPstID())

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

            battleStatCmpt:RecordCurRoundDoActiveSkillTimes(petPstID)

            ---@type L2RService
            local svc = self._world:GetService("L2R")
            svc:L2RPickUpComponentData(castPetEntity:GetID(),pickUpGridList,cmd:GetDirectionPickupData(),cmd:GetReflectDir(),cmd:GetCmdPickUpExtraParamResult())

            if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
                self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 2)
            else
                self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 2)
            end
        else
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
            --@type UtilDataServiceShare
            local utilData = self._world:GetService("UtilData")
            local ready = utilData:GetPetSkillReadyAttr(casterPetEntity,activeSkillID)
            --local ready = castPetEntity:Attributes():GetAttribute("Ready")

            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(localSkillID)

            local errorMsg
            if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
                local legendPower = castPetEntity:Attributes():GetAttribute("LegendPower")
                errorMsg =
                    "LegendPet CastPickUpSkill failed,logic legendPower:" ..
                    tostring(legendPower) .. " ReadyState:" .. tostring(ready) .. " localSkillID:" .. localSkillID
            else
                --local power = castPetEntity:Attributes():GetAttribute("Power")
                local power = utilData:GetPetPowerAttr(casterPetEntity,activeSkillID)
                --主动技
                errorMsg =
                    " CastPickUpSkill failed,logic power: " ..
                    tostring(power) .. " ReadyState:" .. tostring(ready) .. " localSkillID:" .. localSkillID
            end
            self:_HandleServerSyncFailed(BattleFailedType.ActiveSkillCDError, errorMsg)
            --castPetEntity:RemoveActiveSkillPickUpComponent() --点选组件拆分暂时屏蔽
        end
        --castPetEntity:RemovePreviewPickUpComponent() --点选组件拆分暂时屏蔽
    elseif activeSkillData.Type == SkillType.TrapSkill then
        --机关技能

        local casterTrapEntityID = cmd:GetCmdCasterTrapEntityID()
        ---@type Entity
        local casterTrapEntity = self._world:GetEntityByID(casterTrapEntityID)

        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterTrapEntity:ActiveSkillPickUpComponent()
        if not activeSkillPickUpComponent then
            casterTrapEntity:AddActiveSkillPickUpComponent()
            activeSkillPickUpComponent = casterTrapEntity:ActiveSkillPickUpComponent()
        end
        activeSkillPickUpComponent:ClearGridPos()
        activeSkillPickUpComponent:AddGridPosList(pickUpGridList)
        activeSkillPickUpComponent:AddDirectionList(cmd:GetDirectionPickupData())
        activeSkillPickUpComponent:SetReflectDir(cmd:GetReflectDir())

        ---@type AttributesComponent
        local attributeCmpt = casterTrapEntity:Attributes()
        local curPower = attributeCmpt:GetAttribute("TrapPower")
        local count = attributeCmpt:GetAttribute("SkillCount")
        if (curPower <= 0 or count <= 0) and activeSkillData.TriggerParam ~= 0 then
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

        self._world:GetDataLogger():AddDataLog("OnLinkEnd")
        self._world:GetDataLogger():AddDataLog("OnShowStart")

        ---@type ActiveSkillComponent
        local activeSkillCmpt = teamEntity:ActiveSkill()
        activeSkillCmpt:SetActiveSkillID(activeSkillID, casterTrapEntityID)
        ---@type LogicPickUpComponent
        local logicPickUpCmpt = teamEntity:LogicPickUp()
        logicPickUpCmpt:SetLogicCurActiveSkillInfo(activeSkillID, -1)
        logicPickUpCmpt:SetEntityID(casterTrapEntityID)

        ---@type L2RService
        local svc = self._world:GetService("L2R")
        svc:L2RPickUpComponentData(casterTrapEntityID,pickUpGridList,cmd:GetDirectionPickupData(),cmd:GetReflectDir(),cmd:GetCmdPickUpExtraParamResult())

        if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
            self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 2)
        else
            self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 2)
        end
        --casterTrapEntity:RemovePreviewPickUpComponent() --点选组件拆分暂时屏蔽
    elseif activeSkillData.Type == SkillType.FeatureSkill then
        local bCanCast = false
        local useFeatureType = FeatureType.PersonaSkill
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
            end
        end
        if not bCanCast then
            self:_HandleServerSyncFailed(BattleFailedType.ActiveSkillCDError, "persona skill cd error")
            return
        end
        local casterEntity = lsvcFeature:GetFeatureSkillHolderEntity(useFeatureType)
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if not activeSkillPickUpComponent then
            casterEntity:AddActiveSkillPickUpComponent()
            activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        end
        activeSkillPickUpComponent:ClearGridPos()
        activeSkillPickUpComponent:AddGridPosList(pickUpGridList)
        activeSkillPickUpComponent:AddDirectionList(cmd:GetDirectionPickupData())
        activeSkillPickUpComponent:SetReflectDir(cmd:GetReflectDir())
        activeSkillPickUpComponent:AddPickExtraParamList(cmd:GetCmdPickUpExtraParamResult())

        --battleStatCmpt:AddActiveSkillCount()
        --battleStatCmpt:SetLastDoActiveSkillRound(petPstID, round)

        self._world:GetDataLogger():AddDataLog("OnLinkEnd")
        self._world:GetDataLogger():AddDataLog("OnShowStart")

        local casterEntityID = casterEntity:GetID()

        ---@type FeatureSkillComponent
        local featureSkillCmpt = teamEntity:FeatureSkill()
        featureSkillCmpt:SetFeatureSkillID(useFeatureType,activeSkillID, casterEntityID)
        ---@type LogicPickUpComponent
        local logicPickUpCmpt = teamEntity:LogicPickUp()
        local pstid = -1
        logicPickUpCmpt:SetLogicCurActiveSkillInfo(activeSkillID, pstid)
        logicPickUpCmpt:SetEntityID(casterEntityID)

        ---@type L2RService
        local svc = self._world:GetService("L2R")
        svc:L2RPickUpComponentData(casterEntityID,pickUpGridList,cmd:GetDirectionPickupData(),cmd:GetReflectDir(),cmd:GetCmdPickUpExtraParamResult())


        if self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
            self._world:EventDispatcher():Dispatch(GameEventType.PickUpActiveSkillTargetFinish, 4)
        else
            --self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 11)
            if self._world:MatchType() == MatchType.MT_PopStar then
                self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 4)
            else
                self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 11)
            end
        end
        --casterEntity:RemovePreviewPickUpComponent() --点选组件拆分暂时屏蔽
    end
end
