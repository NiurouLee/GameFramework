--[[----------------------------------------------------------
    SkillPickUpDiffPowerInstructionSystem_Render 指令化的PickUPSystem
    罗伊 点到指定机关和点到空格子，技能消耗不同
    处理：
        1.点到的格子没有指定机关，会给previewPickUpComponent添加标记
        2.点选时根据技能消耗通知ui是否能点确认
]] ------------------------------------------------------------
---@class SkillPickUpDiffPowerInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpDiffPowerInstructionSystem_Render", ReactiveSystem)
SkillPickUpDiffPowerInstructionSystem_Render = SkillPickUpDiffPowerInstructionSystem_Render

---@param world MainWorld
function SkillPickUpDiffPowerInstructionSystem_Render:Constructor(world)
    self._world = world
    self._pickUpType = nil

    self._IsRepeatPickupFunc = {}
    self._IsRepeatPickupFunc[SkillPickUpType.PickDiffPowerInstruction] = self.IsRepeatPickUP_PickGrid

    self._ProgressInvalidFunc = {}
    self._ProgressInvalidFunc[SkillPickUpType.PickDiffPowerInstruction] = self.ProgressInvalidGridList_PickGrid

    self._RemovePickUpGridPos = {}
    self._RemovePickUpGridPos[SkillPickUpType.PickDiffPowerInstruction] = self.RemovePickUpGridPos_PickGrid
end

---@param world World
function SkillPickUpDiffPowerInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpDiffPowerInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.PickDiffPowerInstruction then
        return true
    end
    return false
end

function SkillPickUpDiffPowerInstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

function SkillPickUpDiffPowerInstructionSystem_Render:_DoInstruction(instructionType,skillConfigData,petEntity,pickUpGridPos)
    GameGlobal.TaskManager():CoreGameStartTask(
                        self._DoPickUpInstruction,
                        self,
                        instructionType,
                        skillConfigData,
                        petEntity,
                        pickUpGridPos
                    )
end
function SkillPickUpDiffPowerInstructionSystem_Render:DoPickUp(entity)
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
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local entityID = 0
    --光灵主动技/机关主动技 按照不同的方式取
    if skillConfigData:GetSkillType() == SkillType.Active then
        entityID = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())
    elseif skillConfigData:GetSkillType() == SkillType.TrapSkill then
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
    self._pickUpNum = pickUpNum
    local musPickUpNum = nil
    if skillConfigData._pickUpParam[2] then
        musPickUpNum = tonumber(skillConfigData._pickUpParam[2])
    end
    self._mustPickUpNum = musPickUpNum

    local tarTrapId
    if skillConfigData._pickUpParam[3] then
        tarTrapId = tonumber(skillConfigData._pickUpParam[3])
    end
    self._tarTrapId = tarTrapId
    
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    ---重复点选
    if self:IsRepeatPickUP(previewPickUpComponent:GetAllValidPickUpGridPos(), pickUpGridPos) then
        self:_HandlePickRepeatPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickDiffPowerInsRepeat,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        return
    end
    ---点选有效范围
    if table.icontains(validGridList, pickUpGridPos) then
        ---只能点选一个格子的点选其余格子切换预览
        if pickUpNum == 1 and previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
            self:_HandleRePickPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
            return
        elseif pickUpNum > previewPickUpComponent:GetAllValidPickUpGridPosCount() then
            self:_HandlePickValidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
            return
        end
    else
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickDiffPowerInsInvalid,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        if table.icontains(invalidGridList, pickUpGridPos) then
            self:_HandlePickInvalidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
        else
            self:_HandlePickCancelPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
        end
    end
end
---通知ui
function SkillPickUpDiffPowerInstructionSystem_Render:UpdateUI(previewPickUpComponent,checkPowerEnough,activeSkillID)
    local leftPickUpNumber = self._pickUpNum - previewPickUpComponent:GetAllValidPickUpGridPosCount()
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
    if leftPickUpNumber < 0 then
        Log.fatal("leftPickUpNumber <=0 number:", leftPickUpNumber)
        leftPickUpNumber = 0
    end
    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, leftPickUpNumber)
    ---配置了必须点数量的要点够数量才能释放主动技
    if self._mustPickUpNum then
        ---没有配置的 只要点了就能放
        if pickUpCount == self._mustPickUpNum then
            self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, checkPowerEnough)
            return
        end
    elseif pickUpCount ~= 0 then
        self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, checkPowerEnough)
        return
    end
    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)

    GameGlobal:EventDispatcher():Dispatch(GameEventType.SetCurPickExtraParam, activeSkillID,previewPickUpComponent:GetAllPickExtraParam())
    --local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()

    -- local canCast = true
    -- local uiTextState = SkillPickUpTextStateType.Switch
	-- if self._pickUpNum and self._pickUpNum == 0 then
	-- 	uiTextState = SkillPickUpTextStateType.ChooseDir
	-- end
    -- self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, canCast)
    -- self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, uiTextState)
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandlePickRepeatPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")

    Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
    self:RemoveRepeatPickUpGrid(previewPickUpComponent, pickUpGridPos)
    ---用来判断是服务端还是客户端运行
    if previewActiveSkill then
        previewActiveSkill:ResetPreview()
        previewActiveSkill:_RevertAllConvertElement()

        if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 0 then
            self:_DoInstruction(PickUpInstructionType.Empty,skillConfigData,petEntity,pickUpGridPos)
        else
            self:_DoInstruction(PickUpInstructionType.Repeat,skillConfigData,petEntity,pickUpGridPos)
        end
    end
    local checkPowerEnough = true
    self:UpdateUI(previewPickUpComponent,checkPowerEnough,activeSkillID)
    --previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandleRePickPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")

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
    --点击的格子是否有指定机关 消耗能量不同
    local checkPowerEnough = self:_HandlePickTrap(petEntity,pickUpGridPos,previewPickUpComponent,skillConfigData)
    self:UpdateUI(previewPickUpComponent,checkPowerEnough,activeSkillID)
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandlePickValidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    

    Log.debug("本次点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
    previewPickUpComponent:AddGridPos(pickUpGridPos)
    --点击的格子是否有指定机关 消耗能量不同
    local checkPowerEnough = self:_HandlePickTrap(petEntity,pickUpGridPos,previewPickUpComponent,skillConfigData)

    utilScopeSvc:ChangeGameFSMState2PickUp()
    ---用来判断是服务端还是客户端运行
    if previewActiveSkill then
        previewActiveSkill:ResetPreview()
        self:_DoInstruction(PickUpInstructionType.Valid,skillConfigData,petEntity,pickUpGridPos)
    end
    self:UpdateUI(previewPickUpComponent,checkPowerEnough,activeSkillID)
    --previewActiveSkill:UpdateUI(pickUpNum, musPickUpNum, previewPickUpComponent)
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandlePickInvalidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")

    Log.debug("本次点选无效目标生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
    ---用来判断是服务端还是客户端运行
    if previewActiveSkill then
        self:_DoInstruction(PickUpInstructionType.Invalid,skillConfigData,petEntity,pickUpGridPos)
    end
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandlePickCancelPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    if previewActiveSkill then
        previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, pickUpTargetCmpt:GetPetPstid())
    end
end
function SkillPickUpDiffPowerInstructionSystem_Render:_HandlePickTrap(petEntity,pickUpGridPos,previewPickUpComponent,skillConfigData)
    local checkPowerEnough = true
    --点击的格子是否有指定机关
    if self._tarTrapId then
        local bPickTrap = false
        ---@type UtilDataServiceShare
        local udsvc = self._world:GetService("UtilData")
        local traps = udsvc:GetTrapsAtPos(pickUpGridPos)
        if traps then
            for index, e in ipairs(traps) do
                if self._tarTrapId == e:TrapRender():GetTrapID() then
                    bPickTrap = true
                end
            end
        end
        if bPickTrap then
            previewPickUpComponent:RemovePickExtraParam(SkillTriggerTypeExtraParam.PickPosNoCfgTrap)
            GameGlobal:EventDispatcher():Dispatch(GameEventType.SetCurPickExtraParam, skillConfigData:GetID(),previewPickUpComponent:GetAllPickExtraParam())
        else
            if not previewPickUpComponent:HasPickExtraParam(SkillTriggerTypeExtraParam.PickPosNoCfgTrap) then
                previewPickUpComponent:AddPickExtraParam(SkillTriggerTypeExtraParam.PickPosNoCfgTrap)
            end
            GameGlobal:EventDispatcher():Dispatch(GameEventType.SetCurPickExtraParam, skillConfigData:GetID(),previewPickUpComponent:GetAllPickExtraParam())
            local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
            if cfgExtraParam then
                if cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then--罗伊 点机关和空格子消耗能量不同
                    local newCost = cfgExtraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
                    local legendPower = udsvc:GetEntityAttributeByName(petEntity,"LegendPower")

                    if legendPower and legendPower < newCost then
                        checkPowerEnough = false
                    end
                end
            end
        end
    end
    return checkPowerEnough
end
---@param pickUpGridPos Vector2
function SkillPickUpDiffPowerInstructionSystem_Render:_DoPickUpInstruction(TT, type, skillConfigData, casterEntity, pickUpGirdPos)
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
function SkillPickUpDiffPowerInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
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

function SkillPickUpDiffPowerInstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpDiffPowerInstructionSystem_Render:ProcessInvalidGridList(validGridList, invalidGridList)
    local fun = self._ProgressInvalidFunc[self._pickUpType]
    return fun(self, validGridList, invalidGridList)
end

function SkillPickUpDiffPowerInstructionSystem_Render:ProgressInvalidGridList_PickGrid(validGridList, invalidGridList)
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

function SkillPickUpDiffPowerInstructionSystem_Render:ProgressInvalidGridList_PickColor(validGridList, invalidGridList)
    return validGridList
end
---@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpDiffPowerInstructionSystem_Render:IsRepeatPickUP(allPickUpPos, pickUpGridPos)
    return self._IsRepeatPickupFunc[self._pickUpType](self, allPickUpPos, pickUpGridPos)
end

----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpDiffPowerInstructionSystem_Render:IsRepeatPickUP_PickGrid(allPickUpPos, pickUpGridPos)
    return table.icontains(allPickUpPos, pickUpGridPos)
end

----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpDiffPowerInstructionSystem_Render:IsRepeatPickUP_PickColor(allPickUpPos, pickUpGridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if table.count(allPickUpPos) > 0 then
        local pickPieceType = utilDataSvc:GetPieceType(pickUpGridPos)
        for _, pos in pairs(allPickUpPos) do
            local alreadyPieceType = utilDataSvc:GetPieceType(pos)
            if pickPieceType == alreadyPieceType then
                return true
            end
        end
        return false
    else
        return false
    end
end

function SkillPickUpDiffPowerInstructionSystem_Render:RemovePickUpGridPos_PickGrid(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:RemoveGridPos(pickGridPos)
end
---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpDiffPowerInstructionSystem_Render:RemovePickUpGridPos_PickColor(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:ClearGridPos()
end

function SkillPickUpDiffPowerInstructionSystem_Render:RemoveRepeatPickUpGrid(previewPickUpComponent, pickGridPos)
    self._RemovePickUpGridPos[self._pickUpType](self, previewPickUpComponent, pickGridPos)
end
