--[[----------------------------------------------------------
    耶利亚主动技点选 点到指定机关时可以继续点 后续每次点击后的范围以最后一个点为中心重算
]] ------------------------------------------------------------
---@class SkillPickUpYeliyaSystem_Render:ReactiveSystem
_class("SkillPickUpYeliyaSystem_Render", ReactiveSystem)
SkillPickUpYeliyaSystem_Render = SkillPickUpYeliyaSystem_Render

---@param world MainWorld
function SkillPickUpYeliyaSystem_Render:Constructor(world)
    self._world = world
    self._isGuide = false
    self._pickUpType = nil

    self._IsRepeatPickupFunc = {}
    self._IsRepeatPickupFunc[SkillPickUpType.Yeliya] = self.IsRepeatPickUP_PickGrid

    self._ProgressInvalidFunc = {}
    self._ProgressInvalidFunc[SkillPickUpType.Yeliya] = self.ProgressInvalidGridList_PickGrid

    self._RemovePickUpGridPos = {}
    self._RemovePickUpGridPos[SkillPickUpType.Yeliya] = self.RemovePickUpGridPos_PickGrid
end

---@param world World
function SkillPickUpYeliyaSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpTarget)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function SkillPickUpYeliyaSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.Yeliya then
        return true
    end
    return false
end

function SkillPickUpYeliyaSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

function SkillPickUpYeliyaSystem_Render:DoPickUp(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()

    ---@type PreviewActiveSkillService
    local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local entityID = 0
    --光灵主动技/机关主动技 按照不同的方式取
    if skillConfigData:GetSkillType() == SkillType.Active then
        entityID = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())
        local entity = self._world:GetEntityByID(entityID)
        skillConfigData = configService:GetSkillConfigData(activeSkillID, entity) -- 施法者为光灵时，技能可能被替换
    elseif skillConfigData:GetSkillType() == SkillType.TrapSkill then
        entityID = pickUpTargetCmpt:GetEntityID()
    elseif skillConfigData:GetSkillType() == SkillType.FeatureSkill then
        entityID = pickUpTargetCmpt:GetEntityID()
    end

    local petEntity = self._world:GetEntityByID(entityID)
    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    --[[
		点选有效范围内的无效格子为明确禁止格
		点选有效范围外的任何格子为取消点选格
	]]
    ----这里有个逻辑 去掉有效范围里的无效格子 ----
    validGridList = self:ProcessInvalidGridList(validGridList, invalidGridList)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    local musPickUpNum = nil
    if skillConfigData._pickUpParam[2] then--sjs_todo 去掉
        --musPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    local isPickRepeatRemoveRest = false--重复点击时 取消这个点及之后的几个点
    if skillConfigData._pickUpParam[3] then
        local param3 = tonumber(skillConfigData._pickUpParam[3])
        isPickRepeatRemoveRest = (param3 == 1)
    end
    local addPickNumTrapID = 0--点到指定机关，可以再点
    if skillConfigData._pickUpParam[4] then
        local param4 = tonumber(skillConfigData._pickUpParam[4])
        addPickNumTrapID = param4
    end
    if addPickNumTrapID and addPickNumTrapID > 0 then
        pickUpNum = self:_CalcPickUpNumByPickTrap(petEntity,addPickNumTrapID)
    end
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    ---重复点选
    if self:IsRepeatPickUP(previewPickUpComponent:GetAllValidPickUpGridPos(), pickUpGridPos) then
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        if guideService then
            local isValid = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
            if not isValid then
                return
            end
            -- if isValid and self._isGuide then
            --     return
            -- end
        end
        Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickYeliyaRepeat,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        if isPickRepeatRemoveRest then --重复点击时 取消这个点及之后的几个点
            local allPick = previewPickUpComponent:GetAllValidPickUpGridPos()
            if allPick then
                local tmpPosList = {}
                for index, pickedPos in ipairs(allPick) do
                    if pickedPos == pickUpGridPos then
                        break
                    else
                        table.insert(tmpPosList,pickedPos)
                    end
                end
                previewPickUpComponent:ClearGridPos()
                previewPickUpComponent:AddGridPosList(tmpPosList)
            end
        else
            self:RemoveRepeatPickUpGrid(previewPickUpComponent, pickUpGridPos)
        end
        ---用来判断是服务端还是客户端运行
        if previewActiveSkill then
            previewActiveSkill:ResetPreview()
            previewActiveSkill:_RevertAllConvertElement()

            if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 0 then
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Empty,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            else
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Repeat,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
        end
        if addPickNumTrapID and addPickNumTrapID > 0 then
            pickUpNum = self:_CalcPickUpNumByPickTrap(petEntity,addPickNumTrapID)
        end
        previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
        return
    end

    ---点选有效范围
    if table.icontains(validGridList, pickUpGridPos) then
        ---点选无效范围
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        ---只能点选一个格子的点选其余格子就执行取消
        if pickUpNum == 1 and previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
            ---引导---
            local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
            if isValid then
                if isGuide then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                end
                self._isGuide = isGuide
            else
                return
            end

            ---引导---
            Log.debug("本次点选其他格子生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:AddGridPos(pickUpGridPos)

            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
                previewActiveSkill:_RevertAllConvertElement()
                GameGlobal.TaskManager():CoreGameStartTask(
                    function(TT)
                        self:_DoPickUpInstruction(
                            TT,
                            PickUpInstructionType.Empty,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                        )
                        previewActiveSkill:_RevertAllConvertElement()
                        self:_DoPickUpInstruction(
                            TT,
                            PickUpInstructionType.Valid,
                            skillConfigData,
                            petEntity,
                            pickUpGridPos
                        )
                    end
                )
            end
            return
        elseif pickUpNum > previewPickUpComponent:GetAllValidPickUpGridPosCount() then
            ---引导---
            local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
            if isValid then
                if isGuide then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                end
                self._isGuide = isGuide
            else
                return
            end
            ---引导---

            Log.debug("本次点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:AddGridPos(pickUpGridPos)

            utilScopeSvc:ChangeGameFSMState2PickUp()
            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Valid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
            if addPickNumTrapID and addPickNumTrapID > 0 then
                pickUpNum = self:_CalcPickUpNumByPickTrap(petEntity,addPickNumTrapID)
            end
            previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
            return
        end
    else
        local guideService = self._world:GetService("Guide")
        ---引导---
        local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
        if not isValid then
            return
        end
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickYeliyaInvalid,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        if table.icontains(invalidGridList, pickUpGridPos) then
            Log.debug("本次点选无效目标生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                GameGlobal.TaskManager():CoreGameStartTask(
                    self._DoPickUpInstruction,
                    self,
                    PickUpInstructionType.Invalid,
                    skillConfigData,
                    petEntity,
                    pickUpGridPos
                )
            end
        else
            if previewActiveSkill then
                previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, pickUpTargetCmpt:GetPetPstid())
            end
        end
    end
end

---@param pickUpGridPos Vector2
function SkillPickUpYeliyaSystem_Render:_DoPickUpInstruction(TT, type, skillConfigData, casterEntity, pickUpGirdPos)
    ---@type number[]
    local taskIDList = {}
    ----@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    for i, v in ipairs(skillConfigData._previewParamList) do
        if v:GetPreviewType() == SkillPreviewType.Instruction then
            ---@type SkillPreviewParamInstruction
            local instructionParam = v
            for _, skillPreviewConfigData in ipairs(instructionParam._previewList) do
                local instructionSet = self:_GetInstructSet(type, skillPreviewConfigData)
                if instructionSet then
                    ---@type SkillPreviewContext
                    local previewContext =
                        self:_GetPreviewContext(
                        type,
                        skillPreviewConfigData,
                        casterEntity,
                        skillPreviewConfigData:GetID(),
                        pickUpGirdPos
                    )
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(
                        previewActiveSkillService.DoPreviewInstruction,
                        previewActiveSkillService,
                        instructionSet,
                        casterEntity,
                        previewContext
                    )
                    table.insert(taskIDList, taskID)
                end
            end
        end
    end
    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---@param skillPreviewConfigData SkillPreviewConfigData
function SkillPickUpYeliyaSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end

    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end

    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpYeliyaSystem_Render:_GetPreviewContext(
    type,
    skillPreviewConfigData,
    casterEntity,
    id,
    pickUpGridPos)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local context = previewPickUpComponent:GetPreviewContext(id)
    if not context then
        if type == PickUpInstructionType.Invalid then
            context =
                previewActiveSkillService:CreatePreviewContext(
                skillPreviewConfigData,
                casterEntity,
                pickUpGridPos,
                {pickUpGridPos}
            )
        else
            context =
                previewActiveSkillService:CreatePreviewContext(skillPreviewConfigData, casterEntity, pickUpGridPos)
        end
    end
    return context
end

function SkillPickUpYeliyaSystem_Render:ProcessInvalidGridList(validGridList, invalidGridList)
    local fun = self._ProgressInvalidFunc[self._pickUpType]
    return fun(self, validGridList, invalidGridList)
end

function SkillPickUpYeliyaSystem_Render:ProgressInvalidGridList_PickGrid(validGridList, invalidGridList)
    local tv2FilteredInvalidGridList = {}
    for _, v2 in ipairs(invalidGridList) do
        if table.icontains(validGridList, v2) then
            table.insert(tv2FilteredInvalidGridList, v2)
        end
    end

    local tv2FilteredValidGridList = {}
    for _, v2 in ipairs(validGridList) do
        if not table.icontains(tv2FilteredInvalidGridList, v2) then
            table.insert(tv2FilteredValidGridList, v2)
        end
    end

    validGridList = tv2FilteredValidGridList
    return tv2FilteredValidGridList
end

---@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpYeliyaSystem_Render:IsRepeatPickUP(allPickUpPos, pickUpGridPos)
    return self._IsRepeatPickupFunc[self._pickUpType](self, allPickUpPos, pickUpGridPos)
end

----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpYeliyaSystem_Render:IsRepeatPickUP_PickGrid(allPickUpPos, pickUpGridPos)
    return table.icontains(allPickUpPos, pickUpGridPos)
end

function SkillPickUpYeliyaSystem_Render:RemovePickUpGridPos_PickGrid(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:RemoveGridPos(pickGridPos)
end

function SkillPickUpYeliyaSystem_Render:RemoveRepeatPickUpGrid(previewPickUpComponent, pickGridPos)
    self._RemovePickUpGridPos[self._pickUpType](self, previewPickUpComponent, pickGridPos)
end
function SkillPickUpYeliyaSystem_Render:_CalcPickUpNumByPickTrap(petEntity,addPickNumTrapID)
    local canPickNum = 1
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    if previewPickUpComponent then
        local lastPos = previewPickUpComponent:GetLastPickUpGridPos()
        if lastPos then
            local bPickTrap = false
            ---@type UtilDataServiceShare
            local udsvc = self._world:GetService("UtilData")
            local traps = udsvc:GetTrapsAtPos(lastPos)
            if traps then
                for index, e in ipairs(traps) do
                    if addPickNumTrapID == e:TrapRender():GetTrapID() then
                        bPickTrap = true
                        break
                    end
                end
            end
            if bPickTrap then
                local curPickCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
                canPickNum = curPickCount + 1
            else
                local curPickCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
                canPickNum = curPickCount
            end
        end
    end
    return canPickNum
end
