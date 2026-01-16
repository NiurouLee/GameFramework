--[[----------------------------------------------------------
    定制化的点选效果 针对 库斯库塔 的技能效果 定制化处理逻辑
    库斯库塔的点选效果是  点击范围内的怪物  点选后技能可释放
    如果 怪物可位移 那么 可以再次点选位置  创建怪物虚影
]] ------------------------------------------------------------
---@class SkillPickUpAndTeleportInstructionSystem_Render:ReactiveSystem
_class("SkillPickUpAndTeleportInstructionSystem_Render", ReactiveSystem)
SkillPickUpAndTeleportInstructionSystem_Render = SkillPickUpAndTeleportInstructionSystem_Render

---@param world MainWorld
function SkillPickUpAndTeleportInstructionSystem_Render:Constructor(world)
	self._world = world
	self._isGuide = false
	self._pickUpType = nil

	self._IsRepeatPickupFunc = {}
	self._IsRepeatPickupFunc[SkillPickUpType.PickAndTeleportInst] = self.IsRepeatPickUP_PickGrid

	self._ProgressInvalidFunc = {}
	self._ProgressInvalidFunc[SkillPickUpType.PickAndTeleportInst] = self.ProgressInvalidGridList_PickGrid

	self._RemovePickUpGridPos = {}
	self._RemovePickUpGridPos[SkillPickUpType.PickAndTeleportInst] = self.RemovePickUpGridPos_PickGrid
end

---@param world World
function SkillPickUpAndTeleportInstructionSystem_Render:GetTrigger(world)
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
function SkillPickUpAndTeleportInstructionSystem_Render:Filter(entity)
	---@type PickUpTargetComponent
	local pickUpTargetCmpt = entity:PickUpTarget()
	local skillHandleType = pickUpTargetCmpt:GetPickUpTargetType()
	if skillHandleType == SkillPickUpType.PickAndTeleportInst then
		return true
	end
	return false
end

function SkillPickUpAndTeleportInstructionSystem_Render:ExecuteEntities(entities)
	for i = 1, #entities do
		self:DoPickUp(entities[i])
	end
end

function SkillPickUpAndTeleportInstructionSystem_Render:DoPickUp(entity)
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
	local petEntityId = utilDataSvc:GetEntityIDByPstID(pickUpTargetCmpt:GetPetPstid())

	local petEntity = self._world:GetEntityByID(petEntityId)

	local petPstID = pickUpTargetCmpt:GetPetPstid()

	if not petEntity:HasPreviewPickUpComponent() then
		petEntity:AddPreviewPickUpComponent()
	end

	---@type Vector2[]
	local validGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)

	local skillScopeGridList = utilScopeSvc:CalcSkillResultByConfigData(skillConfigData,petEntity)

	---@type Vector2[]
	local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

	--[[
		点选有效范围内的无效格子为明确禁止格
		点选有效范围外的任何格子为取消点选格
	]]
	self:ProcessInvalidGridList(validGridList, invalidGridList)

	---可点选的数量
	local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
	---瞬移位置点选的索引
	local pickTelIndex = tonumber(skillConfigData._pickUpParam[2])


	---@type PreviewPickUpComponent
	local previewPickUpComponent = petEntity:PreviewPickUpComponent()
	previewPickUpComponent:SetIgnorePickCheck(true)--库斯库塔，第二个点点不上也可以放
	local alreadyPickUpCount = 	previewPickUpComponent:GetAllValidPickUpGridPosCount()


	if self:IsRepeatPickUP(previewPickUpComponent:GetLastPickUpGridPos(), pickUpGridPos) then
		Log.debug("本次重复点选生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
		previewPickUpComponent:RemoveGridPos(pickUpGridPos)
		local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
		self:UpdateUI(previewPickUpComponent)
		if pickUpCount == 0 then
			Log.debug("本次重复点选 清空点选列表，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
			GameGlobal.TaskManager():CoreGameStartTask(
					previewActiveSkill._DoPickUpInstruction,
					previewActiveSkill,
					PickUpInstructionType.Empty,
					skillConfigData,
					petEntity,
					pickUpGridPos
			)
		else
			Log.debug("本次重复点选 去掉瞬移位置，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
			GameGlobal.TaskManager():CoreGameStartTask(
					previewActiveSkill._DoPickUpInstruction,
					previewActiveSkill,
					PickUpInstructionType.Repeat,
					skillConfigData,
					petEntity,
					pickUpGridPos
			)
		end
		if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
            AutoPickCheckHelperRender.ReportAutoFightPickError(
                ActivePickSkillCheckErrorStep.PickAndTelInsRepeat,ActivePickSkillCheckErrorType.None,
                activeSkillID,pickUpGridPos)
        end
	else
		if alreadyPickUpCount + 1 >= pickTelIndex then
			---已经点了一个瞬移位置 再次点位置的处理
			if alreadyPickUpCount + 1 > pickTelIndex then
				---点选择的怪物直接返回
				if self:IsRepeatPickUP(previewPickUpComponent:GetFirstValidPickUpGridPos(), pickUpGridPos) then
					Log.debug("本次点选位置无效,没有取消瞬移位置就点选怪物，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
					return
				end
				if  self:IsPosCanTel(skillScopeGridList,pickUpGridPos,previewPickUpComponent) then
					Log.debug("本次点选新瞬移位置生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
					local lastPickUpPos = previewPickUpComponent:GetLastPickUpGridPos()
					previewPickUpComponent:RemoveGridPos(lastPickUpPos)
				end
			end

			if self:_CheckMonsterSingleAndCanHitBack(previewPickUpComponent) then
				if  self:IsPosCanTel(skillScopeGridList,pickUpGridPos,previewPickUpComponent) then
					Log.debug("本次怪物放置位置生效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
					previewPickUpComponent:AddGridPos(pickUpGridPos)
					self:UpdateUI(previewPickUpComponent)
					GameGlobal.TaskManager():CoreGameStartTask(
							previewActiveSkill._DoPickUpInstruction,
							previewActiveSkill,
							PickUpInstructionType.Repeat,
							skillConfigData,
							petEntity,
							pickUpGridPos
					)
				else
					if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
						AutoPickCheckHelperRender.ReportAutoFightPickError(
							ActivePickSkillCheckErrorStep.PickAndTelInsCanNotTel,ActivePickSkillCheckErrorType.None,
							activeSkillID,pickUpGridPos)
					end
				end
			else
				Log.debug("本次怪物放置位置无效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
				-- if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
				-- 	AutoPickCheckHelperRender.ReportAutoFightPickError(
				-- 		ActivePickSkillCheckErrorStep.PickAndTelInsMonsterError,ActivePickSkillCheckErrorType.None,
				-- 		activeSkillID,pickUpGridPos)
				-- end
			end
		else
			if table.Vector2Include(validGridList,pickUpGridPos) then
				utilScopeSvc:ChangeGameFSMState2PickUp()
				previewPickUpComponent:AddGridPos(pickUpGridPos)
				self:UpdateUI(previewPickUpComponent)
				GameGlobal.TaskManager():CoreGameStartTask(
						previewActiveSkill._DoPickUpInstruction,
						previewActiveSkill,
						PickUpInstructionType.Repeat,
						skillConfigData,
						petEntity,
						pickUpGridPos
				)
			else
				previewActiveSkill:PickUpInvalidGridCancelPreview(activeSkillID, petPstID)
				Log.debug("本次重复点选无效，坐标：", tostring(pickUpGridPos), "SkillID:", activeSkillID)
				if AutoPickCheckHelperRender.IsAutoFightRunning() then--自动战斗下点选异常上报
					AutoPickCheckHelperRender.ReportAutoFightPickError(
						ActivePickSkillCheckErrorStep.PickAndTelInsInvalid,ActivePickSkillCheckErrorType.None,
						activeSkillID,pickUpGridPos)
				end
			end
		end
	end
end

function SkillPickUpAndTeleportInstructionSystem_Render:ProcessInvalidGridList(validGridList, invalidGridList)
	local fun = self._ProgressInvalidFunc[self._pickUpType]
	return fun(self, validGridList, invalidGridList)
end

function SkillPickUpAndTeleportInstructionSystem_Render:ProgressInvalidGridList_PickGrid(validGridList, invalidGridList)
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
	invalidGridList = tv2FilteredInvalidGridList
end

---@param lastPickUpPos Vector2
---@param pickUpGridPos Vector2
function SkillPickUpAndTeleportInstructionSystem_Render:IsRepeatPickUP(lastPickUpPos, pickUpGridPos)
	if lastPickUpPos then
		return lastPickUpPos.x == pickUpGridPos.x and lastPickUpPos.y == pickUpGridPos.y
	else
		return false
	end
end
----@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpAndTeleportInstructionSystem_Render:_CheckMonsterSingleAndCanHitBack(previewPickUpComponent)
	if previewPickUpComponent:GetAllValidPickUpGridPosCount() == 1 then
		----@type UtilDataServiceShare
		local utilDataSvc = self._world:GetService("UtilData")
		local pos = previewPickUpComponent:GetLastPickUpGridPos()
		local entity =utilDataSvc:GetMonsterAtPos(pos)
		---@type BodyAreaComponent
		local areaCmpt = entity:BodyArea()
		---@type PreviewEnvComponent
		local env = self._world:GetPreviewEntity():PreviewEnv()
		---可击退并且是单格怪
		if not env:IsImmuneHitback(entity) and #areaCmpt:GetArea() ==1 then
			return true
		end
	end
	return false
end

---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpAndTeleportInstructionSystem_Render:UpdateUI( previewPickUpComponent)
	local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
	----@type Vector2[]
	local pickUpGridList =previewPickUpComponent:GetAllValidPickUpGridPos()
	local leftPickUpNum = 0
	local canCast = false
	local uiTextState = SkillPickUpTextStateType.Normal
	---点击了怪物
	if pickUpCount == 1 then
		if self:_CheckMonsterSingleAndCanHitBack(previewPickUpComponent) then
			uiTextState = SkillPickUpTextStateType.Tel
			leftPickUpNum = 1
		end
		canCast = true
	----点击了怪物并且指定了瞬移位置
	elseif pickUpCount == 2 then
		uiTextState = SkillPickUpTextStateType.Tel
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
---@param previewPickUpComponent PreviewPickUpComponent
function SkillPickUpAndTeleportInstructionSystem_Render:IsPosCanTel(skillGridList,pos,previewPickUpComponent)
	if not table.Vector2Include(skillGridList,pos) then
		return false
	end
	------@type Vector2[]
	--local pickUpGridList = previewPickUpComponent:GetFirstValidPickUpGridPos()
	--local monsterPos =pickUpGridList[1]
	local monsterPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
	----@type UtilDataServiceShare
	local utilDataSvc = self._world:GetService("UtilData")
	local entity =utilDataSvc:GetMonsterAtPos(monsterPos)
	return 	utilDataSvc:IsMonsterCanTel2TargetPos(entity,pos)
end