--[[----------------------------------------------------------
    定制化的点选效果 针对 普律玛 的技能效果 定制化处理逻辑
]] ------------------------------------------------------------
---@class SkillPickUpPickAndDirection2InstructionSystem_Render:ReactiveSystem
_class("SkillPickUpPickAndDirection2InstructionSystem_Render", ReactiveSystem)
SkillPickUpPickAndDirection2InstructionSystem_Render = SkillPickUpPickAndDirection2InstructionSystem_Render

---@param world MainWorld
function SkillPickUpPickAndDirection2InstructionSystem_Render:Constructor(world)
    self._world = world

    self._pickUpType = nil

    self._pickUpArrowOffset= {}
    self._pickUpArrowOffset[ShowArrowType.LeftAndRight]={Vector2(1,0),Vector2(-1,0)}
    self._pickUpArrowOffset[ShowArrowType.UpAndDown]={Vector2(0,1),Vector2(0,-1)}
    self._pickUpArrowOffset[ShowArrowType.Four]={ Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0) }

end



---@param world World
function SkillPickUpPickAndDirection2InstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpPickAndDirection2InstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.PickAndDirectionInstruction2 then
        return true
    end
    return false
end

function SkillPickUpPickAndDirection2InstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

---初始状态的显示，有效点击0个点，什么都没有
function SkillPickUpPickAndDirection2InstructionSystem_Render:_OnInitializeShow(petEntity, skillConfigData, pickUpGridPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()

    self._previewActiveSkill:ResetPreview()

    --删除箭头
    -- previewActiveSkillService:DestroyPickUpArrow()

    GameGlobal.TaskManager():CoreGameStartTask(
            self._DoPickUpInstruction,
            self,
            PickUpInstructionType.Empty,
            skillConfigData,
            petEntity,
            pickUpGridPos
    )

    -- self._previewActiveSkill:UpdateUI(picckUpNum, musPickUpNum, previewPickUpComponent)
    self:UpdateUI(previewPickUpComponent)
end

---准备选择方向状态的显示，有效点击1个点，
---@param skillConfigData SkillConfigData
function SkillPickUpPickAndDirection2InstructionSystem_Render:_OnReadyToSelectDirectionShow(
        petEntity,
        skillConfigData,
        pickUpGridPos,
        lastPickUpPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local firstPickUpPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
    local pickUpParam = skillConfigData:GetSkillPickParam()
    ---@type ShowArrowType
    local arrowType =pickUpParam[2]
    --点击的点银色
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:DoConvert({firstPickUpPos}, "Normal", "Dark")

    if not lastPickUpPos then
        --删掉旧的  创建新箭头
        self._previewActiveSkill:DestroyPickUpArrow()
    end

    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    if table.count(arrowEntities) == 0 then
        self._previewActiveSkill:ShowPickUpArrowByType(arrowType,true, firstPickUpPos)
    end

    --删掉上一次的点(也分情况，第一次进入这个状态  是没有上一次点击点的)
    if lastPickUpPos then
        self:_ShowPickUpArrow(lastPickUpPos, firstPickUpPos, false)
    end
    self:_ShowPickUpArrow(pickUpGridPos, firstPickUpPos, false)

    self:UpdateUI(previewPickUpComponent)
end

---已经选择方向状态的显示，有效点击2个点，
function SkillPickUpPickAndDirection2InstructionSystem_Render:_OnHadToSelectDirectionShow(
        petEntity,
        skillConfigData,
        pickUpGridPos,
        lastPickUpPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local firstPickUpPos = previewPickUpComponent:GetFirstValidPickUpGridPos()

    self:_ShowPickUpArrow(lastPickUpPos, firstPickUpPos, false)
    self:_ShowPickUpArrow(pickUpGridPos, firstPickUpPos, true)

    GameGlobal.TaskManager():CoreGameStartTask(
            self._DoPickUpInstruction,
            self,
            PickUpInstructionType.Valid,
            skillConfigData,
            petEntity,
            pickUpGridPos
    )

    self:UpdateUI(previewPickUpComponent)
end

function SkillPickUpPickAndDirection2InstructionSystem_Render:IsDirValid(lastPickUpPos,curPickUpPos)

    local directionGridList = {}
    local offSetList = self._pickUpArrowOffset[self._pickUpArrowType]

    for i, v in ipairs(offSetList) do
        table.insert(directionGridList,v+lastPickUpPos)
    end

    return  table.Vector2Include(directionGridList,curPickUpPos)
end

function SkillPickUpPickAndDirection2InstructionSystem_Render:DoPickUp(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    self._pickUpType = pickUpTargetCmpt:GetPickUpTargetType()


    ---@type PreviewActiveSkillService
    self._previewActiveSkill = self._world:GetService("PreviewActiveSkill")

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

    if pickUpGridPos then
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        local isGuide, isValid = guideService:IsGuideAndPieceValid(pickUpGridPos.x, pickUpGridPos.y)
        if isGuide then
            if isValid then
                self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
            else
                return
            end
        end
    end

    local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

    local petEntity = self._world:GetEntityByID(petEntityId)

    local petPstID = pickUpTargetCmpt:GetPetPstid()
    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end
    ---@type number[]
    local pickUpParam = skillConfigData:GetSkillPickParam()
    self._pickUpArrowType =pickUpParam[2]
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local alreadyPickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()

    ---技能表配置的点选有效范     PickUpScopeType 点选有效范围类型
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)

    -- local skillScopeGridList = utilScopeSvc:CalcSkillResultByConfigData(skillConfigData, petEntity)

    --不可以点的范围
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    --第二次点选的时候  不检测无效点击点
    if alreadyPickUpCount == 0 then
        for _, pos in ipairs(invalidGridList) do
            if table.intable(validGridList, pos) then
                table.removev(validGridList, pos)
            end
        end
    end

    --[[
		点选有效范围内的无效格子为明确禁止格
		点选有效范围外的任何格子为取消点选格
	]]
    -- self:ProcessInvalidGridList(validGridList, invalidGridList)

    ---方向点选的索引
    local pickTelIndex = tonumber(skillConfigData._pickUpParam[1])

    --上一次点击的点
    local lastPickUpPos = previewPickUpComponent:GetLastPickUpGridPos()
    local firstPickUpPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
    if self._pickUpType== SkillPickUpType.PickAndDirectionInstruction2 then
        if (not table.Vector2Include(validGridList, pickUpGridPos) and alreadyPickUpCount==0 ) or

                (alreadyPickUpCount == 2 and not self:IsDirValid(firstPickUpPos, pickUpGridPos) )  then
            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
            return
        end
            --            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
            --            return
        --if alreadyPickUpCount== 0 then
        --    ---点选有效范围
        --    if not table.Vector2Include(validGridList, pickUpGridPos)  then
        --        previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        --        return
        --    end
        --else
        --    if not self:IsDirValid(firstPickUpPos, pickUpGridPos) then
        --        previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        --        return
        --    else
        --        if not table.Vector2Include(validGridList, pickUpGridPos) then
        --            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
        --            return
        --        else
        --            previewPickUpComponent:ClearGridPos()
        --            alreadyPickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
        --        end
        --    end
        --end
    end

    utilScopeSvc:ChangeGameFSMState2PickUp()

    if alreadyPickUpCount == 0 then
        -- 如果已经点了0个点  本次是基础点

        --数据
        previewPickUpComponent:AddGridPos(pickUpGridPos)

        ---准备选择方向状态的显示，有效点击1个点，
        self:_OnReadyToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
    else

        --本次点击的点是第一次点击的点
        if pickUpGridPos == firstPickUpPos then
            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:ClearDirection()

            ---初始状态的显示，有效点击0个点，什么都没有
            self:_OnInitializeShow(petEntity, skillConfigData, pickUpGridPos)
        else
            -- end
            --选中点为中心的周围4个方向的点
            local directionGridList = {}
            local offSetList = self._pickUpArrowOffset[self._pickUpArrowType]
            for i, v in ipairs(offSetList) do
                table.insert(directionGridList,v+firstPickUpPos)
            end

            -- 当前点击的点是方向中的一个点
            if table.Vector2Include(directionGridList, pickUpGridPos) then
                --重新刷新点选后的状态
                if pickUpGridPos == lastPickUpPos then
                    --重复的点  会移除刚点的坐标
                    previewPickUpComponent:RemoveGridPos(lastPickUpPos)


                    if self._pickUpType== SkillPickUpType.PickAndDirectionInstruction2 then

                        GameGlobal.TaskManager():CoreGameStartTask(function(TT)
                            self:_DoPickUpInstruction(TT,PickUpInstructionType.Repeat,
                                    skillConfigData,
                                    petEntity,
                                    pickUpGridPos)
                            ---准备选择方向状态的显示，有效点击1个点，
                            self:_OnReadyToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
                        end)
                    end

                else
                    --选择过方向的 删除上一个方向 添加新的方向坐标
                    if alreadyPickUpCount == 2 then
                        previewPickUpComponent:RemoveGridPos(lastPickUpPos)
                    end

                    previewPickUpComponent:AddGridPos(pickUpGridPos)
                    self:_OnHadToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
                end
            ----点选了其余格子那么更新数据这个格子作为第一个点选的格子
            else
                if not table.Vector2Include(validGridList, pickUpGridPos) then
                    return
                end
                previewPickUpComponent:ClearGridPos()
                --数据
                previewPickUpComponent:AddGridPos(pickUpGridPos)

                ---准备选择方向状态的显示，有效点击1个点，
                self:_OnReadyToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, nil)
            end
        end
    end
end

---判断是重复点击
---@param lastPickUpPos Vector2
---@param pickUpGridPos Vector2
function SkillPickUpPickAndDirection2InstructionSystem_Render:IsRepeatPickUP(lastPickUpPos, pickUpGridPos)
    if lastPickUpPos then
        return lastPickUpPos.x == pickUpGridPos.x and lastPickUpPos.y == pickUpGridPos.y
    else
        return false
    end
end

---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpPickAndDirection2InstructionSystem_Render:UpdateUI(previewPickUpComponent)
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
    ----@type Vector2[]
    local pickUpGridList = previewPickUpComponent:GetAllValidPickUpGridPos()
    local leftPickUpNum = 0
    local canCast = false
    local uiTextState = SkillPickUpTextStateType.Normal

    if pickUpCount == 1 then
        uiTextState = SkillPickUpTextStateType.Direction
        leftPickUpNum = 1
        canCast = false
    elseif pickUpCount == 2 then
        uiTextState = SkillPickUpTextStateType.Direction
        leftPickUpNum = 0
        canCast = true
    elseif pickUpCount == 0 then
        canCast = false
        leftPickUpNum = 1
        uiTextState = SkillPickUpTextStateType.Normal
    end

    self._world:EventDispatcher():Dispatch(GameEventType.RefreshPickUpNum, leftPickUpNum)
    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, canCast)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, uiTextState)
end

----------------------------------------------------------

function SkillPickUpPickAndDirection2InstructionSystem_Render:_DoPickUpInstruction(
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
function SkillPickUpPickAndDirection2InstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
    if type == PickUpInstructionType.Invalid then
        return skillPreviewConfigData:GetOnSelectInvalidInstructionSet()
    end
    if type == PickUpInstructionType.Repeat then
        return skillPreviewConfigData:GetOnSelectCancelInstructionSet()
    end
    if type == PickUpInstructionType.Valid then
        return skillPreviewConfigData:GetOnSelectValidInstructionSet()
    end
    if type == PickUpInstructionType.Empty then
        return skillPreviewConfigData:GetOnSelectEmptyInstructionSet()
    end
    return nil
end

function SkillPickUpPickAndDirection2InstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpPickAndDirection2InstructionSystem_Render:_ShowPickUpArrow(gridpos, centerPos, isSelect)
    local dis = gridpos - centerPos
    --Log.fatal("GridPos",gridpos,"Caster",casterPos,"dis",dis)
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        local arrowPos = e:GetRenderGridPosition()
        local arrowDir = arrowPos - centerPos
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
