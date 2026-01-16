--[[----------------------------------------------------------
    SkillPickUpDirectionInstructionSystem_Render 指令化的PickUPSystem
]] ------------------------------------------------------------
---@class SkillPickUpDirectionInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpDirectionInstructionSystem_Render", ReactiveSystem)
SkillPickUpDirectionInstructionSystem_Render = SkillPickUpDirectionInstructionSystem_Render

---@param world World
function SkillPickUpDirectionInstructionSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function SkillPickUpDirectionInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpDirectionInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.DirectionInstruction then
        return true
    end
    return false
end

function SkillPickUpDirectionInstructionSystem_Render:ExecuteEntities(entities)
    ---@type PreviewActiveSkillService
    local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()

    local petPstID = pickUpTargetCmpt:GetPetPstid()
    ---@type Vector2[]
    local validGirdList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
	local musPickUpNum = nil
	if skillConfigData._pickUpParam[2] then
		musPickUpNum = tonumber(skillConfigData._pickUpParam[2])
	end


    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local casterPos = petEntity:GridLocation().Position
    local direction = scopeCalculator:GetDirection(pickUpGridPos, casterPos)

    ---点选有效范围
    if table.icontains(validGirdList, pickUpGridPos) then
        ---点选无效范围
        ---重复点选
        if previewPickUpComponent:IsRepeatDirection(direction) then
            Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            --previewPickUpComponent:RemoveGridPos(pickUpGridPos)
            previewPickUpComponent:RemoveDirection(direction)
            self:_ShowPickUpArrow(pickUpGridPos, casterPos, false)
            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
                if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 0 then
                    previewActiveSkill:_RevertAllConvertElement()
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
	        previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
            return
        end
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        ---只能点选一个格子的点选其余格子就执行取消
        if pickUpNum == 1 and previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
            ---引导---
            if guideService then
                if guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y) then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                else
                    return
                end
            end
            ---引导---
            local allValidPickUpGridPos = previewPickUpComponent:GetAllValidPickUpGridPos()
            local lastValidPickUPPos = allValidPickUpGridPos[1]
            self:_ShowPickUpArrow(lastValidPickUPPos, casterPos, false)
            Log.debug("本次点选其他格子生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)

            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:ClearDirection()
            self:_ShowPickUpArrow(pickUpGridPos, casterPos, true)

            previewPickUpComponent:AddGridPos(pickUpGridPos)
            previewPickUpComponent:AddDirection(direction, pickUpGridPos)

            ---用来判断是服务端还是客户端运行
            if previewActiveSkill then
                previewActiveSkill:ResetPreview()
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
            if guideService then
                if guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y) then
                    self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
                else
                    return
                end
            end
            ---引导---

            --同方向不能选2次
            local lastDir = previewPickUpComponent:GetLastPickUpDirection()
            if lastDir == direction then
                return
            end
            Log.debug("本次点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
            previewPickUpComponent:AddGridPos(pickUpGridPos)
            previewPickUpComponent:AddDirection(direction, pickUpGridPos)
            self:_ShowPickUpArrow(pickUpGridPos, casterPos, true)

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
	        previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
            return
        end
    else
        if previewActiveSkill then
            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        end
        if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickDirectionInsInvalid,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
        self:_ShowPickUpArrow(pickUpGridPos, casterPos, false)
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
        end
    end
end

---@param pickUpGirdPos Vector2
function SkillPickUpDirectionInstructionSystem_Render:_DoPickUpInstruction(
    TT,
    type,
    skillConfigData,
    casterEntity,
    pickUpGirdPos)
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
function SkillPickUpDirectionInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end

    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpDirectionInstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpDirectionInstructionSystem_Render:_ShowPickUpArrow(gridpos, casterPos, isSelect)
    local dis = gridpos - casterPos
    --Log.fatal("GridPos",gridpos,"Caster",casterPos,"dis",dis)
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        local arrowPos = e:GetRenderGridPosition()
        local arrowDir = arrowPos - casterPos
        local angle = Vector2.Angle(dis, arrowDir)
        --Log.fatal("arrowPos",arrowPos,"dir",arrowDir,"angle",angle)
        ---角度有误差
        local statTable = nil
        if math.abs(angle) <= 1 then
            --Log.fatal("Select arrow",arrowPos)
            if isSelect == true then
                statTable = {select = true, idle = false}
            else
                statTable = {select = false, idle = true}
            end
            e:SetAnimatorControllerBools(statTable)
        end
    end
end

function SkillPickUpDirectionInstructionSystem_Render:_GetPickUpDirect(gridpos, casterPos)
    local deltal = gridpos - casterPos

    if deltal.x == 0 and deltal.y <= -1 then
        return HitBackDirectionType.Down
    elseif deltal.x == 0 and deltal.y >= 1 then
        return HitBackDirectionType.Up
    elseif deltal.y == 0 and deltal.x >= 1 then
        return HitBackDirectionType.Right
    elseif deltal.y == 0 and deltal.x <= -1 then
        return HitBackDirectionType.Left
    elseif deltal.y >= 1 and deltal.x <= -1 then
        return HitBackDirectionType.LeftUp
    elseif deltal.y >= 1 and deltal.x >= 1 then
        return HitBackDirectionType.RightUp
    elseif deltal.y <= -1 and deltal.x >= 1 then
        return HitBackDirectionType.RightDown
    elseif deltal.y <= -1 and deltal.x <= -1 then
        return HitBackDirectionType.LeftDown
    else
        return HitBackDirectionType.None
    end
    --if dis.x > 0 and dis.y > 0 then
    --	--rightbottom
    --	return HitBackDirectionType.RightDown
    --elseif dis.x > 0 and dis.y < 0 then
    --	--leftbottom
    --	return HitBackDirectionType.LeftDown
    --elseif dis.x < 0 and dis.y < 0 then
    --	--leftup
    --	return HitBackDirectionType.LeftUp
    --elseif dis.x < 0 and dis.y > 0 then
    --	--rightup
    --	return HitBackDirectionType.RightUp
    --elseif dis.x == 0 and dis.y > 0 then
    --	--right
    --	return HitBackDirectionType.Right
    --elseif dis.x == 0 and dis.y < 0 then
    --	--left
    --	return HitBackDirectionType.Left
    --elseif dis.x > 0 and dis.y == 0 then
    --	--bottom
    --	return HitBackDirectionType.Down
    --elseif dis.x < 0 and dis.y == 0 then
    --	--up
    --	return HitBackDirectionType.Up
    --end
end
---@param state string
function SkillPickUpDirectionInstructionSystem_Render:ChangeAllPickArrow(state)
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        local statTable = nil
        if state == "Show" then
            statTable = {select = true, idle = false}
        elseif state == "Hide" then
            statTable = {select = false, idle = true}
        end
        e:SetAnimatorControllerBools(statTable)
    end
end
