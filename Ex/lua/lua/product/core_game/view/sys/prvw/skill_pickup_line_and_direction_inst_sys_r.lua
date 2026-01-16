--[[----------------------------------------------------------
    定制化的点选效果 针对 艾露玛 的技能效果 定制化处理逻辑
    类似 SkillPickUpPickAndDirectionInstructionSystem_Render
    首先十字方向点一个点确认主方向，然后在第一个点两侧显示箭头，第二次点击两个箭头处确认扩展方向
]] ------------------------------------------------------------
---@class SkillPickUpLineAndDirectionInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpLineAndDirectionInstructionSystem_Render", ReactiveSystem)
SkillPickUpLineAndDirectionInstructionSystem_Render = SkillPickUpLineAndDirectionInstructionSystem_Render

---@param world MainWorld
function SkillPickUpLineAndDirectionInstructionSystem_Render:Constructor(world)
    self._world = world

    self._pickUpType = nil
end

---@param world World
function SkillPickUpLineAndDirectionInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpLineAndDirectionInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.LineAndDirectionInstruction then
        return true
    end
    return false
end

function SkillPickUpLineAndDirectionInstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

---初始状态的显示，有效点击0个点，什么都没有
function SkillPickUpLineAndDirectionInstructionSystem_Render:_OnInitializeShow(petEntity, skillConfigData, pickUpGridPos)
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
---@param dir Vector2
local function GetLogicDirection(dir)
    local ret = Vector2.zero
    if dir.x > 0 then
        ret.x = 1
    elseif dir.x < 0 then
        ret.x = -1
    end

    if dir.y > 0 then
        ret.y = 1
    elseif dir.y < 0 then
        ret.y = -1
    end

    return ret
end
---@param centerPos Vector2 
---@param dir Vector2
local function GetTwoSideOffset(centerPos,dir)
    local ret = {}

    if dir.x ~= 0 then
        table.insert(ret,Vector2(centerPos.x,centerPos.y + 1))
        table.insert(ret,Vector2(centerPos.x,centerPos.y - 1))
    elseif dir.y ~= 0 then
        table.insert(ret,Vector2(centerPos.x + 1,centerPos.y))
        table.insert(ret,Vector2(centerPos.x - 1,centerPos.y))
    end
    return ret
end
---@param centerPos Vector2 
---@param dir Vector2
local function GetTwoSideArrowDirIndex(centerPos,dir)
    local ret = {}

    if dir.x ~= 0 then
        table.insert(ret,1)--上
        table.insert(ret,5)--下
    elseif dir.y ~= 0 then
        table.insert(ret,3)--右
        table.insert(ret,7)--左
    end
    return ret
end
---准备选择方向状态的显示，有效点击1个点，
function SkillPickUpLineAndDirectionInstructionSystem_Render:_OnReadyToSelectDirectionShow(
    petEntity,
    skillConfigData,
    pickUpGridPos,
    lastPickUpPos)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = petEntity:PreviewPickUpComponent()
    local firstPickUpPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
    local casterPos = petEntity:GetRenderGridPosition()

    local mainDir = GetLogicDirection(firstPickUpPos - casterPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local lineResult = 
        scopeCalculator:ComputeScopeRange(
            SkillScopeType.DirectLineBlockedEdgeFree, 
            {9,0,1},
            casterPos,
            {Vector2(0,0)},
            mainDir,
            nil,
            casterPos
            )
    local convGrids = lineResult:GetAttackRange()
    --点击的点银色
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillService:DoConvert(convGrids, "Silver", "Dark")

    --删掉旧的  创建新箭头
    -- self._previewActiveSkill:DestroyPickUpArrow()

    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    if table.count(arrowEntities) == 0 then
        local arrowIndexs = GetTwoSideArrowDirIndex(firstPickUpPos,mainDir)
        self._previewActiveSkill:ShowDynamicPickUpArrow(arrowIndexs,true, firstPickUpPos)
    end

    --删掉上一次的点(也分情况，第一次进入这个状态  是没有上一次点击点的)
    if lastPickUpPos then
        self:_ShowPickUpArrow(lastPickUpPos, firstPickUpPos, false)
    end
    self:_ShowPickUpArrow(pickUpGridPos, firstPickUpPos, false)

    self:UpdateUI(previewPickUpComponent)
end

---已经选择方向状态的显示，有效点击2个点，
function SkillPickUpLineAndDirectionInstructionSystem_Render:_OnHadToSelectDirectionShow(
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

function SkillPickUpLineAndDirectionInstructionSystem_Render:DoPickUp(entity)
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
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)

    local petPstID = pickUpTargetCmpt:GetPetPstid()
    if not petEntity:HasPreviewPickUpComponent() then
        petEntity:AddPreviewPickUpComponent()
    end

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

    ---点选有效范围
    if alreadyPickUpCount == 0 then --第二次点击不在这判断范围
        if not table.Vector2Include(validGridList, pickUpGridPos) then
            previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
            if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
                AutoPickCheckHelperRender.ReportAutoFightPickError(
                    ActivePickSkillCheckErrorStep.PickLineAndDirectionInsInvalid,ActivePickSkillCheckErrorType.None,
                    activeSkillID,pickUpGridPos)
            end
            return
        end
    end

    utilScopeSvc:ChangeGameFSMState2PickUp()

    if alreadyPickUpCount == 0 then
        -- 如果已经点了0个点  本次是基础点

        --数据
        previewPickUpComponent:AddGridPos(pickUpGridPos)

        ---准备选择方向状态的显示，有效点击1个点，
        self:_OnReadyToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
        if skillConfigData._pickUpParam[2] then
            local turnToPick = tonumber(skillConfigData._pickUpParam[3])
            if turnToPick == 1 then
                local casterPos = petEntity:GetRenderGridPosition()
                local mainDir = GetLogicDirection(pickUpGridPos - casterPos)
                petEntity:SetDirection(mainDir)
            end
        end
    else
        local firstPickUpPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
        --本次点击的点是第一次点击的点
        if pickUpGridPos == firstPickUpPos then
            previewPickUpComponent:ClearGridPos()
            previewPickUpComponent:ClearDirection()

            ---初始状态的显示，有效点击0个点，什么都没有
            self:_OnInitializeShow(petEntity, skillConfigData, pickUpGridPos)
            if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
                AutoPickCheckHelperRender.ReportAutoFightPickError(
                    ActivePickSkillCheckErrorStep.PickLineAndDirectionInsRepeat,ActivePickSkillCheckErrorType.None,
                    activeSkillID,pickUpGridPos)
            end
        else
            -- end
            local casterPos = petEntity:GetRenderGridPosition()
            local mainDir = GetLogicDirection(firstPickUpPos - casterPos)
            --选中点为中心的周围4个方向的点
            local directionGridList = {}
            local sidePos = GetTwoSideOffset(firstPickUpPos,mainDir)
            for _, sideGrid in ipairs(sidePos) do
                table.insert(directionGridList, sideGrid)
            end
            -- table.insert(directionGridList, Vector2(firstPickUpPos.x + 0, firstPickUpPos.y + 1))
            -- table.insert(directionGridList, Vector2(firstPickUpPos.x + 1, firstPickUpPos.y + 0))
            -- table.insert(directionGridList, Vector2(firstPickUpPos.x + 0, firstPickUpPos.y - 1))
            -- table.insert(directionGridList, Vector2(firstPickUpPos.x - 1, firstPickUpPos.y + 0))

            -- 当前点击的点是方向中的一个点
            if table.Vector2Include(directionGridList, pickUpGridPos) then
                --重新刷新点选后的状态
                if pickUpGridPos == lastPickUpPos then
                    --重复的点  会移除刚点的坐标
                    previewPickUpComponent:RemoveGridPos(lastPickUpPos)

                    ---准备选择方向状态的显示，有效点击1个点，
                    self:_OnReadyToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
                else
                    --选择过方向的 删除上一个方向 添加新的方向坐标
                    if alreadyPickUpCount == 2 then
                        previewPickUpComponent:RemoveGridPos(lastPickUpPos)
                    end

                    previewPickUpComponent:AddGridPos(pickUpGridPos)

                    self:_OnHadToSelectDirectionShow(petEntity, skillConfigData, pickUpGridPos, lastPickUpPos)
                end
            end
        end
    end
end

---判断是重复点击
---@param lastPickUpPos Vector2
---@param pickUpGridPos Vector2
function SkillPickUpLineAndDirectionInstructionSystem_Render:IsRepeatPickUP(lastPickUpPos, pickUpGridPos)
    if lastPickUpPos then
        return lastPickUpPos.x == pickUpGridPos.x and lastPickUpPos.y == pickUpGridPos.y
    else
        return false
    end
end

---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpLineAndDirectionInstructionSystem_Render:UpdateUI(previewPickUpComponent)
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

function SkillPickUpLineAndDirectionInstructionSystem_Render:_DoPickUpInstruction(
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
function SkillPickUpLineAndDirectionInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
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

function SkillPickUpLineAndDirectionInstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpLineAndDirectionInstructionSystem_Render:_ShowPickUpArrow(gridpos, centerPos, isSelect)
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
