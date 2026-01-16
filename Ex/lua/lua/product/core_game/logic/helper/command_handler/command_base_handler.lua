_class("CommandBaseHandler", Object)
---@class CommandBaseHandler: Object
CommandBaseHandler = CommandBaseHandler

function CommandBaseHandler:Constructor(world)
    ---@type Entity
    self._cmdOwnerEntity = nil

    ---@type MainWorld
    self._world = world
end

---@param owner Entity
function CommandBaseHandler:SetCommandOwner(owner)
    self._cmdOwnerEntity = owner

    self._world = owner:GetOwnerWorld()
end

---@param cmd IEntityCommand
function CommandBaseHandler:DoHandleCommand(cmd)
end

---服务端处理同步失败的方式是以失败的结果结束对局
---@param world MainWorld
function CommandBaseHandler:_HandleServerSyncFailed(failedType, failedMsg)
    Log.fatal("[SyncLog],type:", failedType, " info:", failedMsg)
    if self._world:RunAtServer() then
        ---@type ServerWorld
        local serverWorld = self._world
        serverWorld:HandleSyncFailed(failedType, failedMsg)
    end
end

---MSG70205 世界BOSS，格兹德，局内使用伊芙，可以刷房间词条导致无限cd
---新增加的光灵CD类的handler，需要第一个执行此接口
---放技能时清理之前保存过的灰标状态
function CommandBaseHandler:_ResetSkillGrayWatch(teamEntity, castSkillPetPstID, castSkillID)    
    ---点击主动技释放时  需要将之前标记过的技能灰标状态重置
    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local curRound = battleStatComponent:GetLevelTotalRoundCount()

    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    for _, e in ipairs(teamMembers) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == castSkillPetPstID then
            ---@type BuffComponent
            local buffComponent = e:BuffComponent()
            local keyStr = "HadSaveSkillGrayWatch" ..
                "_Round_" .. tostring(curRound) .. "_Skill_" .. tostring(castSkillID)
            local hadSaveSkillGrayWatch = buffComponent:GetBuffValue(keyStr)
            if hadSaveSkillGrayWatch then
                buffComponent:SetBuffValue(keyStr, nil)
            end
        end
    end
end

---@param teamEntity Entity
function CommandBaseHandler:_ClearActivePower(teamEntity, castSkillPetPstID,castSkillID)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    for _, e in ipairs(teamMembers) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == castSkillPetPstID then
            ---@type AttributesComponent
            local attributeCmpt = e:Attributes()

            local bHasVariantSkill = false--有变体技能 就按当前技能id重置maxPower
            local localSkillID = e:SkillInfo():GetActiveSkillID()
            local extraSkillList = e:SkillInfo():GetExtraActiveSkillIDList()--是附加主动技
            if extraSkillList and table.icontains(extraSkillList,castSkillID) then
                localSkillID = castSkillID
            else
                --变体
                local variantActiveSkillInfo = e:SkillInfo():GetVariantActiveSkillInfo()
                if variantActiveSkillInfo then
                    bHasVariantSkill = true--有变体技能 就按当前技能id重置maxPower
                    local variantList = variantActiveSkillInfo[localSkillID]
                    if variantList and table.icontains(variantList,castSkillID) then
                        localSkillID = castSkillID
                    end
                end
            end
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(localSkillID, e)
            if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
                local legendPower = attributeCmpt:GetAttribute("LegendPower")
                local costLegendPower = skillConfigData:GetSkillTriggerParam()
                local cfgCostLegendPower = costLegendPower--罗伊 技能根据点选 消耗不同
                local zhongxuForceMoveStep = 0--仲胥强制位移 记录本次移动步数
                --罗伊 根据点选不同 消耗能量不同
                costLegendPower,zhongxuForceMoveStep = self:_GetLegendPowerConstByExtraParam(costLegendPower,skillConfigData, castSkillPetPstID)
                
                --最低消耗可能需要计算（仲胥）
                cfgCostLegendPower = utilData:CalcMinCostLegendPowerByExtraParam(e,cfgCostLegendPower,skillConfigData,zhongxuForceMoveStep,false)

                --能量点消耗统计，消耗值处理请在这之前完成
                local cSkillInfo = e:SkillInfo()
                if cSkillInfo:IsActiveSkillEnergyCount() then
                    local cBuff = e:BuffComponent()
                    local activeSkillRecord = cBuff:GetBuffValue("ActiveSkillEnergyCostCountByRound") or {}
                    local currentRoundCount = self._world:BattleStat():GetLevelTotalRoundCount()
                    if not activeSkillRecord[currentRoundCount] then
                        activeSkillRecord[currentRoundCount] = cfgCostLegendPower
                    else
                        activeSkillRecord[currentRoundCount] = activeSkillRecord[currentRoundCount] + cfgCostLegendPower
                    end
                    cBuff:SetBuffValue("ActiveSkillEnergyCostCountByRound", activeSkillRecord)
                end

                legendPower = legendPower - costLegendPower
                if legendPower < cfgCostLegendPower then
                    if legendPower < 0 then
                        legendPower = 0
                    end
                    --attributeCmpt:Modify("Ready", 0)
                    ---@type BuffLogicService
                    local blsvc = self._world:GetService("BuffLogic")
                    blsvc:ChangePetActiveSkillReady(e, 0,localSkillID)
                end
                attributeCmpt:Modify("LegendPower", legendPower)
            elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
                local costLayer = skillConfigData:GetSkillTriggerParam()
                local extraParam = skillConfigData:GetSkillTriggerExtraParam()
                local buffEffectType = extraParam.buffEffectType
                ---@type BuffLogicService
                local blsvc = self._world:GetService("BuffLogic")
                local currentVal = blsvc:GetBuffLayer(e, buffEffectType)
                local finalVal = math.max(currentVal - costLayer, 0) --纯保底，看能量分支有处理所以也加了一个
                blsvc:SetBuffLayer(e, buffEffectType, finalVal, true)
                if finalVal < costLayer then
                    self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillCancelReady, pstID, false)
                    ---@type BuffLogicService
                    local blsvc = self._world:GetService("BuffLogic")
                    blsvc:ChangePetActiveSkillReady(e, 0, localSkillID)
                end
            else
                self._world:GetSyncLogger():Trace({key = "_ClearActivePower", casterPstID = pstID})

                --变体cd可能与maxPower属性不同，这里改一下
                if bHasVariantSkill then
                    local cfgMaxPower = skillConfigData:GetSkillTriggerParam()
                    utilData:SetPetMaxPowerAttr(e,cfgMaxPower,localSkillID)
                end
                local maxPower = utilData:GetPetMaxPowerAttr(e,localSkillID)
                utilData:SetPetPowerAttr(e,maxPower,localSkillID)
                --attributeCmpt:Modify("Power", maxPower)
                --attributeCmpt:Modify("Ready", 0)
                ---@type BuffLogicService
                local blsvc = self._world:GetService("BuffLogic")
                blsvc:ChangePetActiveSkillReady(e, 0,localSkillID)
            end

            --主动技cd积攒回合数清零
            teamEntity:ActiveSkill():ClearPowerfullRoundCount(e:GetID())
            teamEntity:ActiveSkill():ClearPreviousReadyRoundCount(e:GetID())
        else
            --Log.fatal("other pet")
        end
    end
end
---@param skillConfigData SkillConfigData
function CommandBaseHandler:_GetLegendPowerConstByExtraParam(defaultCost,skillConfigData,castSkillPetPstID)
    local cost = defaultCost
    local step = 0--仲胥强制位移 移动了几格
    local castPetEntity = self:GetEntityByPstID(castSkillPetPstID)
    if castPetEntity and skillConfigData then
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        ---@type ActiveSkillPickUpComponent
        local pickCmpt = castPetEntity:ActiveSkillPickUpComponent()
        if cfgExtraParam and pickCmpt then
            if cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then--罗伊 点机关和空格子消耗能量不同
                if pickCmpt:HasPickExtraParam(SkillTriggerTypeExtraParam.PickPosNoCfgTrap) then
                    cost = cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
                end
            elseif cfgExtraParam[SkillTriggerTypeExtraParam.CostByForceMoveStep] then--仲胥，能量消耗需要根据位移步数（回合内累加）计算
                ---@type UtilDataServiceShare
                local utilData = self._world:GetService("UtilData")
                cost,step = utilData:CalcZhongxuForceMovementCostByPick(castPetEntity,skillConfigData:GetID())
                if cost < 0 then
                    cost = defaultCost
                end
                if step < 0 then
                    step = 0
                end
            end
        end
    end
    return cost,step
end
function CommandBaseHandler:GetEntityIDByPstID(checkPstID)
    local casterPetEntityID = -1
    local petPstIDGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
    for i, e in ipairs(petPstIDGroup:GetEntities()) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == checkPstID then
            casterPetEntityID = e:GetID()
        end
    end

    return casterPetEntityID
end

----@return Entity
function CommandBaseHandler:GetEntityByPstID(checkPstID)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    return utilData:GetEntityByPstID(checkPstID)
end

---检查是否能施放主动技
---合法返回true，非法返回false
function CommandBaseHandler:CheckActiveSkillCastCondition(petPstID, skillID)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    return utilData:CheckActiveSkillCastCondition(petPstID, skillID)
end

function CommandBaseHandler:CheckDirectionPickUpValid(petEntity, activeSkillID, cmd)
    local directionPickupPos, pickUpDirection, lastPickUpDirection = cmd:GetDirectionPickupData()
    if table.count(directionPickupPos) ~= table.count(pickUpDirection) then
        Log.fatal(
            "CheckPickUpDirection Failed table.count(directionPickupPos):",
            table.count(directionPickupPos),
            "~= table.count(pickUpDirection):",
            table.count(pickUpDirection),
            "SkillID:",
            activeSkillID
        )
        return false
    end
    local posList = {}
    for direction, pos in pairs(directionPickupPos) do
        if not self:CheckDirection(direction) then
            Log.fatal("CheckPickUpDirection Failed DirectionType:", direction, " Invalid", "SkillID:", activeSkillID)
            return false
        end
        table.insert(posList, pos)
    end
    if not self:CheckPickUpGridValid(petEntity, activeSkillID, posList) then
        Log.fatal("CheckPickUpDirection Failed Pos Invalid ", "SkillID:", activeSkillID)
        return false
    end
    return true
end

function CommandBaseHandler:CheckAkexiyaPickUpValid(petEntity, activeSkillID, cmd)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    local mustPickUpNum = nil
    if skillConfigData._pickUpParam[2] then
        mustPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    if skillConfigData._pickUpParam[2] then
        mustPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    local pickUpGridList = cmd:GetCmdPickUpResult()
    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    if #pickUpGridList > pickUpNum then
        Log.fatal(
                "#pickUpGridList> pickUpNum PickUpNum:",
                pickUpNum,
                "PickUpGridListCount:",
                #pickUpGridList,
                "SkillID:",
                activeSkillID
        )
        return false
    end
    if mustPickUpNum and #pickUpGridList ~= mustPickUpNum then
        Log.fatal(
                "#pickUpGridList ~= mustPickUpNum MustPickUpNum:",
                mustPickUpNum,
                "PickUpGridListCount:",
                #pickUpGridList,
                "SkillID:",
                activeSkillID
        )
        return false
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    --region 第一个点
    local firstPickupPos = pickUpGridList[1]
    local firstPickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.firstPickValidScopeList or {})
    local firstPickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.firstPickInvalidScopeList or {})
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(firstPickUpValidScopeList, petEntity) or {}
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(firstPickUpInvalidScopeList, petEntity) or {}
    if not table.Vector2Include(validGridList, firstPickupPos) then
        Log.fatal("Pos is not in ValidGridList Pos:", tostring(firstPickupPos), "SkillID:", "SkillID:", activeSkillID)
        return false
    end
    if table.Vector2Include(invalidGridList, firstPickupPos) then
        Log.fatal("Pos is  in InValidGridList Pos:", tostring(firstPickupPos), "SkillID:", "SkillID:", activeSkillID)
        return false
    end

    ---黑魔法：服务端在这个函数返回true的时候才会承认点选结果
    ---但这里后面的计算需要前面验证通过的点选结果
    ---如果整个点选验证通过，则activeSkillPickUpComponent的数据将被清空，此处的操作将被撤销
    if self._world:RunAtServer() then
        -- ---@type ActiveSkillPickUpComponent
        -- local activeSkillPickUpComponent = petEntity:ActiveSkillPickUpComponent()
        -- if not activeSkillPickUpComponent then
        --     petEntity:AddActiveSkillPickUpComponent()
        --     activeSkillPickUpComponent = petEntity:ActiveSkillPickUpComponent()
        -- end
        -- activeSkillPickUpComponent:AddGridPos(firstPickupPos)

        ---@type PreviewPickUpComponent
        local previewPickUpComponent = petEntity:PreviewPickUpComponent()
        if not previewPickUpComponent then
            petEntity:AddPreviewPickUpComponent()
            previewPickUpComponent = petEntity:PreviewPickUpComponent()
        end
        previewPickUpComponent:AddGridPos(firstPickupPos)
    end
    --endregion
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pickUpValidScopeList = {}
    local pickUpInvalidScopeList = {}
    local firstPickMonster = utilData:GetMonsterAtPos(firstPickupPos)
    local trapID = 0
    if skillConfigData._pickUpParam[5] then
        trapID = tonumber(skillConfigData._pickUpParam[5])
    end

    local isPickTrap = false
    local pickHasMonster = false
    if trapID and (trapID ~= 0) then
        local tTrapEntities = utilData:GetTrapsAtPos(firstPickupPos)
        for _, e in ipairs(tTrapEntities) do
            if e:TrapID():GetTrapID() == trapID then
                isPickTrap = true
                break
            end
        end
    end
    -- if not isPickTrap then
    --     local pickPosMonster = utilData:GetMonsterAtPos(firstPickupPos)
    --     pickHasMonster = (pickPosMonster ~= nil)
    -- end
    
    if isPickTrap then
        pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickValidScopeList or {})
        pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickInvalidScopeList or {})
    else
        pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickValidScopeList or {})
        pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickInvalidScopeList or {})
    end
    -- if utilData:IsPosListHaveMonster({firstPickupPos}) then
        
    -- else
        
    -- end
    ---@type Vector2[]
    local secondValidGridList = utilScopeSvc:BuildScopeGridList(pickUpValidScopeList, petEntity) or {}
    ---@type Vector2[]
    local secondInvalidGridList = utilScopeSvc:BuildScopeGridList(pickUpInvalidScopeList, petEntity) or {}

    for index, v2 in ipairs(secondValidGridList) do
        Log.error("pos index ", index, "v2=", tostring(v2))
    end
    local secondPickupPos = pickUpGridList[2]
    if not table.Vector2Include(secondValidGridList, secondPickupPos) then
        Log.fatal("second Pos is not in ValidGridList Pos:", tostring(secondPickupPos), "SkillID:", "SkillID:", activeSkillID)
        return false
    end
    if table.Vector2Include(secondInvalidGridList, secondPickupPos) then
        Log.fatal("second Pos is  in InValidGridList Pos:", tostring(secondPickupPos), "SkillID:", "SkillID:", activeSkillID)
        return false
    end

    return true
end

---@param cmd CastPickUpActiveSkillCommand
function CommandBaseHandler:CheckPickUpValid(petEntity, activeSkillID, cmd)
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    ---@type SkillPickUpType
    local activeSkillPickUpType = skillConfigData:GetSkillPickType()
    if activeSkillPickUpType == SkillPickUpType.DirectionInstruction then
        if not self:CheckDirectionPickUpValid(petEntity, activeSkillID, cmd) then
            return false
        end
    end
    if activeSkillPickUpType == SkillPickUpType.Akexiya then
        return self:CheckAkexiyaPickUpValid(petEntity, activeSkillID, cmd)
    end
    if activeSkillPickUpType == SkillPickUpType.Yeliya then
        return self:CheckYeliyaPickUpValid(petEntity, activeSkillID, cmd)
    end
    if activeSkillPickUpType == SkillPickUpType.PickAndTeleportInst then
        if not self:CheckPickUpAndTelValid(petEntity, activeSkillID, cmd) then
            return false
        end
        return true
    elseif activeSkillPickUpType == SkillPickUpType.LinkLine then
        return self:CheckPickUpLinkLineValid(petEntity, activeSkillID, cmd)
    else
        local pickUpGridList = cmd:GetCmdPickUpResult()
        return self:CheckPickUpGridValid(petEntity, activeSkillID, pickUpGridList)
    end
end

function CommandBaseHandler:CheckPickUpAndTelValid(petEntity, activeSkillID, cmd)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    ---@type SkillPickUpType
    local activeSkillPickUpType = skillConfigData:GetSkillPickType()
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local skillScopeGridList = utilScopeSvc:CalcSkillResultByConfigData(skillConfigData, petEntity)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])

    local telPickIndex = tonumber(skillConfigData._pickUpParam[2])

    ---@type Vector2[]
    local monsterPosList = {}
    local pickUpGridList = cmd:GetCmdPickUpResult()
    if not pickUpGridList or #validGridList == 0 or #skillScopeGridList == 0 then
        Log.fatal("pickUpGridList is Nil SkillID:", "SkillID:", activeSkillID)
        return false
    elseif #pickUpGridList == 0 then
        Log.fatal("pickUpGridList is Empty SkillID:", "SkillID:", activeSkillID)
        return false
    elseif #pickUpGridList > 0 then
        local monsterPos = pickUpGridList[1]
        if not table.Vector2Include(validGridList, monsterPos) then
            Log.fatal("Pos is not in ValidGridList Pos:", tostring(monsterPos), "SkillID:", "SkillID:", activeSkillID)
            return false
        end
        ---@type Entity
        local monsterEntity = utilDataSvc:GetMonsterAtPos(monsterPos)
        if not monsterEntity then
            Log.fatal("Pos is not Monster in Pos:", tostring(monsterPos), "SkillID:", "SkillID:", activeSkillID)
            return false
        end
        if #pickUpGridList > 1 then
            local newPos = pickUpGridList[2]
            local areaCmpt = monsterEntity:BodyArea()
            ---不可击退或者不是单格怪不能移动
            if not buffLogicService:CheckCanBeHitBack(monsterEntity) or #areaCmpt:GetArea() ~= 1 then
                Log.fatal(
                    "Monster can't HitBack Pos :",
                    tostring(monsterPos),
                    "BodyAreaCount:",
                    #areaCmpt:GetArea(),
                    "SkillID:",
                    "SkillID:",
                    activeSkillID
                )
                return false
            end
            if not table.Vector2Include(skillScopeGridList, newPos) then
                Log.fatal(
                    "MonsterNewPos is not in SkillScopeList Pos:",
                    tostring(newPos),
                    "SkillID:",
                    "SkillID:",
                    activeSkillID
                )
                return false
            end
            if not utilDataSvc:IsMonsterCanTel2TargetPos(monsterEntity, newPos) then
                Log.fatal("MonsterNewPos  is invalid Pos:", tostring(newPos), "SkillID:", "SkillID:", activeSkillID)
            end
        end
    end
    return true
    --for index, pos in ipairs(pickUpGridList) do
    --	---点选的位置
    --	if index <= pickUpNum then
    --		if not validGridList and table.Vector2Include(validGridList,pos) then
    --			Log.fatal("Pos is not in ValidGridList Pos:", tostring(pos), "SkillID:", "SkillID:", activeSkillID)
    --			return false
    --		end
    --		table.insert(monsterPosList,pos)
    --	end
    --	if index >= telPickIndex then
    --		if not skillScopeGridList and table.Vector2Include(skillScopeGridList,pos) then
    --			Log.fatal("Pos is not in ValidGridList Pos:", tostring(pos), "SkillID:", "SkillID:", activeSkillID)
    --			return false
    --		end
    --	end
    --end
    --if not utilDataSvc:IsPosMonsterCanMove(monsterPosList[1])  and not #pickUpGridList >= telPickIndex then
    --	Log.fatal("PickUp Monster Tel Invalid Monster Pos:", tostring(monsterPosList[1])," TelPos: ", tostring(pickUpGridList[telPickIndex]), " SkillID:", "SkillID:", activeSkillID)
    --	return false
    --end
    --if not utilDataSvc:PosIsSingleMonster(monsterPosList[1]) then
    --	Log.fatal("Pos is not in ValidGridList Pos:", tostring(monsterPosList[1]), "SkillID:", "SkillID:", activeSkillID)
    --	return false
    --end
    --return true
end

function CommandBaseHandler:CheckPickUpGridValid(petEntity, activeSkillID, pickUpGridList)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])

    local mustPickUpNum = nil
    if skillConfigData._pickUpParam[2] then
        mustPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    if #pickUpGridList > pickUpNum then
        Log.fatal(
            "#pickUpGridList> pickUpNum PickUpNum:",
            pickUpNum,
            "PickUpGridListCount:",
            #pickUpGridList,
            "SkillID:",
            activeSkillID
        )
        return false
    end
    if mustPickUpNum and #pickUpGridList ~= mustPickUpNum then
        Log.fatal(
            "#pickUpGridList ~= mustPickUpNum MustPickUpNum:",
            mustPickUpNum,
            "PickUpGridListCount:",
            #pickUpGridList,
            "SkillID:",
            activeSkillID
        )
        return false
    end
    for _, pos in ipairs(pickUpGridList) do
        ---这里不能校验是否是合法格子 因为有些技能可以点非棋盘坐标
        --if not self:IsGridPosValid(pos) or self:IsPosNil(pos) then
        --	Log.fatal("Pos is Invalid Pos:", tostring(pos),"SkillID:","SkillID:",activeSkillID)
        --	return false
        --end
        if not validGridList and not table.Vector2Include(validGridList, pos) then
            Log.fatal("Pos is not in ValidGridList Pos:", tostring(pos), "SkillID:", "SkillID:", activeSkillID)
            return false
        end
        if not invalidGridList and table.Vector2Include(invalidGridList, pos) then
            Log.fatal("Pos is  in InValidGridList Pos:", tostring(pos), "SkillID:", "SkillID:", activeSkillID)
            return false
        end
    end
    return true
end
function CommandBaseHandler:CheckYeliyaPickUpValid(petEntity, activeSkillID, cmd)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)
    local pickUpGridList = cmd:GetCmdPickUpResult()
    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])

    local mustPickUpNum = nil
    if skillConfigData._pickUpParam[2] then
        mustPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    if mustPickUpNum and #pickUpGridList < mustPickUpNum then
        Log.fatal(
            "#pickUpGridList < mustPickUpNum MustPickUpNum:",
            mustPickUpNum,
            "PickUpGridListCount:",
            #pickUpGridList,
            "SkillID:",
            activeSkillID
        )
        return false
    end
    --sjs_todo 第一个点判断范围（点选清空后计算） 后续每个点判断范围加有没有指定机关
    -- for index, pos in ipairs(pickUpGridList) do
    -- end
    return true
end

---@param petEntity Entity
---@param activeSkillID number
---@param cmd CastPickUpActiveSkillCommand
function CommandBaseHandler:CheckPickUpLinkLineValid(petEntity, activeSkillID, cmd)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    
    local pickUpGridList = cmd:GetCmdPickUpResult()

    ---检查连线数量是否足够
    if #pickUpGridList < 2 then
        Log.fatal("PickCount < MustPickNum! MustNum: 2, PickCount:", #pickUpGridList, ", SkillID:", activeSkillID)
        return false
    end

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    ---可连怪脚下
    local canLinkMonster = false
    if skillConfigData._pickUpParam[2] then
        canLinkMonster = tonumber(skillConfigData._pickUpParam[2]) == 1
    end

    local needSubCount = 1
    local endPos = pickUpGridList[#pickUpGridList]
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if (utilDataSvc:GetMonsterAtPos(endPos)) then
        needSubCount = needSubCount + 1
    end
    local linkCount = #pickUpGridList - needSubCount

    ---检查可连格子数量是否合法（去除连线起点和怪物终点）
    if linkCount < 0 or linkCount > pickUpNum then
        Log.fatal("Link count error, link:", linkCount, ", cfgNum:", pickUpNum, ", SkillID:", activeSkillID)
        return false
    end

    ---检查第一个位置是否合法，是否是服务端玩家所在位置
    ---@type Vector2
    local startPos = pickUpGridList[1]
    local playerPos = petEntity:GetGridPosition()
    if startPos.x ~= playerPos.x or startPos.y ~= playerPos.y then
        Log.fatal("Link path start pos invalid, client:", startPos:Pos2Index(), " server:", playerPos:Pos2Index())
        return false
    end

    ---检查连通性
    for i = 1, #pickUpGridList - 1 do
        local pos1 = pickUpGridList[i]
        local pos2 = pickUpGridList[i + 1]
        local isCanConnect = false
        for i = -1, 1 do
            for j = -1, 1 do
                if pos1.x + i == pos2.x and pos1.y + j == pos2.y then
                    if not utilDataSvc:IsPosBlockForPreviewLinkLine(pos2, canLinkMonster) then
                        isCanConnect = true
                    end
                end
            end
        end
        if isCanConnect == false then
            Log.fatal("Pos not connect, pos1:", pos1:Pos2Index(), " pos2:", pos2:Pos2Index())
            return false
        end
    end
    return true
end

function CommandBaseHandler:IsPosNil(pos)
    local cBoard = self._world:GetBoardEntity():Board()
    return cBoard:IsPosNil(pos)
end

--在版边内，并且无障碍物
function CommandBaseHandler:IsGridPosValid(pos)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(pos) then
        return false
    end
    if utilData:IsPosBlock(pos, BlockFlag.LinkLine) then
        return false
    end
    return true
end

function CommandBaseHandler:CheckDirection(direction)
    if
        direction ~= HitBackDirectionType.Down and direction ~= HitBackDirectionType.Up and
            direction ~= HitBackDirectionType.Left and
            direction ~= HitBackDirectionType.Right and
            direction ~= HitBackDirectionType.LeftUp and
            direction ~= HitBackDirectionType.LeftDown and
            direction ~= HitBackDirectionType.RightUp and
            direction ~= HitBackDirectionType.RightDown
     then
        return false
    end
    return true
end

function CommandBaseHandler:GetCurState()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    return utilDataSvc:GetCurMainStateID()
end

function CommandBaseHandler:_ParseScopeList(list)
    local parser = SkillScopeParamParser:New()

    local t = {}
    for _, v in ipairs(list) do
        ---@type SkillPreviewScopeParam
        local param = SkillPreviewScopeParam:New(v)
        local data = parser:ParseScopeParam(v.ScopeType, v.ScopeParam)
        param:SetScopeParamData(data)
        table.insert(t, param)
    end
    return t
end