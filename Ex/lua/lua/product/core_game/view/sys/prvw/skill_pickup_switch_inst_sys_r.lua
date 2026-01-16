--[[----------------------------------------------------------
    定制化的点选效果 针对 露比 的技能效果 定制化处理逻辑
	点击脚下格子以切换技能效果
	未点击格子也可以释放技能
]] ------------------------------------------------------------
---@class SkillPickUpSwitchInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpSwitchInstructionSystem_Render", ReactiveSystem)
SkillPickUpSwitchInstructionSystem_Render = SkillPickUpSwitchInstructionSystem_Render

---@param world MainWorld
function SkillPickUpSwitchInstructionSystem_Render:Constructor(world)
    self._world = world
    self._isGuide = false
    self._pickUpType = nil

    self._IsRepeatPickupFunc = {}
    self._IsRepeatPickupFunc[SkillPickUpType.PickSwitchInstruction] = self.IsRepeatPickUP_PickGrid

    self._ProgressInvalidFunc = {}
    self._ProgressInvalidFunc[SkillPickUpType.PickSwitchInstruction] = self.ProgressInvalidGridList_PickGrid

    self._RemovePickUpGridPos = {}
    self._RemovePickUpGridPos[SkillPickUpType.PickSwitchInstruction] = self.RemovePickUpGridPos_PickGrid

	self._IsRepeatPickDirTypeFunc = {}
    self._IsRepeatPickDirTypeFunc[SkillPickUpType.PickSwitchInstruction] = self.IsRepeatPickDirType_PickGrid
end

---@param world World
function SkillPickUpSwitchInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpSwitchInstructionSystem_Render:Filter(entity)
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = entity:PickUpTarget()
    local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
    if skillHandleType == SkillPickUpType.PickSwitchInstruction then
        return true
    end
    return false
end

function SkillPickUpSwitchInstructionSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:DoPickUp(entities[i])
    end
end

function SkillPickUpSwitchInstructionSystem_Render:DoPickUp(entity)
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

	---@type PreviewPickUpComponent
	local previewPickUpComponent = petEntity:PreviewPickUpComponent()
	previewPickUpComponent:SetIgnorePickCheck(true)--露比 点选类型，可以不选，点方向时没有同步记录点选位置
	local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
	local casterPos = petEntity:GridLocation().Position
	
	--点击光灵位置切换效果，点击方向（十字方向、斜向）切换范围
	---点选有效范围
	if table.icontains(validGridList, pickUpGridPos) then
		--点击的是光灵脚下
		if pickUpGridPos == casterPos then
			--重复点选 取消点选记录
			if self:IsRepeatPickUP(previewPickUpComponent:GetAllValidPickUpGridPos(), pickUpGridPos) then
				self:_HandlePickRepeatPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
			else
				--有效
				if pickUpNum > previewPickUpComponent:GetAllValidPickUpGridPosCount() then
					self:_HandlePickValidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
				end
			end
		else
		--点击非光灵脚下（八方向的点）
			local direction = scopeCalculator:GetDirection(pickUpGridPos, casterPos)
			--十字或斜向
			if self:_IsCrossDir(direction) or self:_IsXDir(direction) then
				--方向类型重复 取消方向记录
				if self:IsRepeatPickDirType(previewPickUpComponent:GetAllDirection(),direction) then
					self:_HandlePickRepeatDirType(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
				else
					--有效 新增
					self:_HandlePickValidDirType(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent,direction)
				end
			end
		end
	else
		--点击非有效范围内点
		self:_HandlePickInvalid(pickUpTargetCmpt,skillConfigData,petEntity)
	end
end

function SkillPickUpSwitchInstructionSystem_Render:_HandlePickInvalid(pickUpTargetCmpt,skillConfigData,petEntity)
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
	local guideService = self._world:GetService("Guide")
	---引导---
	local isValid, isGuide = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
	if not isValid then
		return
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
			previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
		end
	end
end
function SkillPickUpSwitchInstructionSystem_Render:_HandlePickRepeatPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
	---@type GuideServiceRender
	local guideService = self._world:GetService("Guide")
	if guideService then
		local isValid = guideService:IsValidGuidePiecePos(pickUpGridPos.x, pickUpGridPos.y)
		if isValid and self._isGuide then
			return
		end
	end
	Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
	self:RemoveRepeatPickUpGrid(previewPickUpComponent, pickUpGridPos)

	---要切换效果计算了，去掉虚影，sjs_todo
	---@type RenderEntityService
	local svc = self._world:GetService("RenderEntity")
	svc:DestroyGhost()

	---用来判断是服务端还是客户端运行
	if previewActiveSkill then
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
	self:UpdateUI(previewPickUpComponent)
	--previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
	return
end
function SkillPickUpSwitchInstructionSystem_Render:_HandlePickValidPos(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
	local guideService = self._world:GetService("Guide")
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

	---要切换效果计算了，去掉虚影，sjs_todo
	---@type RenderEntityService
	local svc = self._world:GetService("RenderEntity")
	svc:DestroyGhost()
	---@type UtilScopeCalcServiceShare
	local utilScopeSvc = self._world:GetService("UtilScopeCalc")
	utilScopeSvc:ChangeGameFSMState2PickUp()
	---用来判断是服务端还是客户端运行
	if previewActiveSkill then
		GameGlobal.TaskManager():CoreGameStartTask(
				self._DoPickUpInstruction,
				self,
				PickUpInstructionType.Valid,
				skillConfigData,
				petEntity,
				pickUpGridPos
		)
	end
	self:UpdateUI(previewPickUpComponent)
	--previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
	return
end
function SkillPickUpSwitchInstructionSystem_Render:_HandlePickRepeatDirType(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent)
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")

	Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
	--previewPickUpComponent:RemoveDirection(direction)
	previewPickUpComponent:ClearDirection()
	---@type RenderEntityService
	local svc = self._world:GetService("RenderEntity")
	svc:DestroyGhost()
	--self:_ShowPickUpArrow(pickUpGridPos, casterPos, false)
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
				PickUpInstructionType.Valid,
				skillConfigData,
				petEntity,
				pickUpGridPos
			)
		end
	end
	self:UpdateUI(previewPickUpComponent)
	--previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
	return
end
function SkillPickUpSwitchInstructionSystem_Render:_HandlePickValidDirType(pickUpTargetCmpt,skillConfigData,petEntity,previewPickUpComponent,direction)
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
	local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
	local petPstID = pickUpTargetCmpt:GetPetPstid()
	---@type PreviewActiveSkillService
	local previewActiveSkill = self._world:GetService("PreviewActiveSkill")
	---@type UtilScopeCalcServiceShare
	local utilScopeSvc = self._world:GetService("UtilScopeCalc")
	local guideService = self._world:GetService("Guide")
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
	--previewPickUpComponent:AddGridPos(pickUpGridPos)
	previewPickUpComponent:AddDirection(direction, pickUpGridPos)
	--self:_ShowPickUpArrow(pickUpGridPos, casterPos, true)
	---@type RenderEntityService
	local svc = self._world:GetService("RenderEntity")
	svc:DestroyGhost()
	
	utilScopeSvc:ChangeGameFSMState2PickUp()
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
				PickUpInstructionType.Valid,
				skillConfigData,
				petEntity,
				pickUpGridPos
			)
		end
	end
	self:UpdateUI(previewPickUpComponent)
	--previewActiveSkill:UpdateUI(pickUpNum,musPickUpNum, previewPickUpComponent)
	return
end
function SkillPickUpSwitchInstructionSystem_Render:_IsCrossDir(dirType)
	if dirType == HitBackDirectionType.Down or
		dirType == HitBackDirectionType.Up or
		dirType == HitBackDirectionType.Left or
		dirType == HitBackDirectionType.Right
	 then
		return true
	end
	return false
end
function SkillPickUpSwitchInstructionSystem_Render:_IsXDir(dirType)
if dirType == HitBackDirectionType.RightUp or
		dirType == HitBackDirectionType.RightDown or
		dirType == HitBackDirectionType.LeftUp or
		dirType == HitBackDirectionType.LeftDown
	 then
		return true
	end
	return false
end
function SkillPickUpSwitchInstructionSystem_Render:_IsSameDirType(dirTypeA,dirTypeB)
	if self._IsCrossDir(dirTypeA) and self._IsCrossDir(dirTypeB) then
		return true
	end
	if self._IsXDir(dirTypeA) and self._IsXDir(dirTypeB) then
		return true
	end
	return false
end
---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpSwitchInstructionSystem_Render:UpdateUI(previewPickUpComponent)
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()

    local canCast = true
    local uiTextState = SkillPickUpTextStateType.Switch
	if self._pickUpNum and self._pickUpNum == 0 then
		uiTextState = SkillPickUpTextStateType.ChooseDir
	end
    self._world:EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, canCast)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangePickUpText, uiTextState)
end

---@param pickUpGridPos Vector2
function SkillPickUpSwitchInstructionSystem_Render:_DoPickUpInstruction(TT, type, skillConfigData, casterEntity, pickUpGirdPos)
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
function SkillPickUpSwitchInstructionSystem_Render:_GetInstructSet(type, skillPreviewConfigData)
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

function SkillPickUpSwitchInstructionSystem_Render:_GetPreviewContext(
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

function SkillPickUpSwitchInstructionSystem_Render:ProcessInvalidGridList(validGridList, invalidGridList)
    local fun = self._ProgressInvalidFunc[self._pickUpType]
    return fun(self, validGridList, invalidGridList)
end

function SkillPickUpSwitchInstructionSystem_Render:ProgressInvalidGridList_PickGrid(validGridList, invalidGridList)
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
function SkillPickUpSwitchInstructionSystem_Render:IsRepeatPickUP(allPickUpPos, pickUpGridPos)
    return self._IsRepeatPickupFunc[self._pickUpType](self, allPickUpPos, pickUpGridPos)
end

function SkillPickUpSwitchInstructionSystem_Render:IsRepeatPickDirType(allPickUpDir, pickUpDir)
    return self._IsRepeatPickDirTypeFunc[self._pickUpType](self, allPickUpDir, pickUpDir)
end
----@param allPickUpPos Vector2[]
---@param pickUpGridPos Vector2
function SkillPickUpSwitchInstructionSystem_Render:IsRepeatPickUP_PickGrid(allPickUpPos, pickUpGridPos)
    return table.icontains(allPickUpPos, pickUpGridPos)
end
function SkillPickUpSwitchInstructionSystem_Render:IsRepeatPickDirType_PickGrid(allPickUpDir, pickUpDir)
	for key, value in pairs(allPickUpDir) do
		if self:_IsSameDirType(value,pickUpDir) then
			return true
		end
	end
	return false
end

function SkillPickUpSwitchInstructionSystem_Render:RemovePickUpGridPos_PickGrid(previewPickUpComponent, pickGridPos)
    previewPickUpComponent:RemoveGridPos(pickGridPos)
end

function SkillPickUpSwitchInstructionSystem_Render:RemoveRepeatPickUpGrid(previewPickUpComponent, pickGridPos)
    self._RemovePickUpGridPos[self._pickUpType](self, previewPickUpComponent, pickGridPos)
end
