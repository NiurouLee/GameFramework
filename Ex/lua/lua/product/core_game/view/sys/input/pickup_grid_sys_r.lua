--[[------------------------------------------------------------------------------------------
    拾取格子系统
    Actor对象也是基于格子来拾取
]] --------------------------------------------------------------------------------------------

---@class PickUpGridSystem_Render:UniqueReactiveSystem
_class("PickUpGridSystem_Render", UniqueReactiveSystem)
PickUpGridSystem_Render = PickUpGridSystem_Render

function PickUpGridSystem_Render:IsInterested(index, previousComponent, component)
    if component == nil then
        return false
    end
    if not PickUpComponent:IsInstanceOfType(component) then
        return false
    end
    return true
end

function PickUpGridSystem_Render:Filter(world)
    return true
end

---@param world MainWorld
function PickUpGridSystem_Render:ExecuteWorld(world)
    self._world = world

    ---@type PickUpComponent
    local cPickUp = world:PickUp()
    local clickRenderPos = cPickUp:GetClickPos()

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPos = boardServiceRender:BoardRenderPos2GridPos(clickRenderPos)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()

    if stateId == GameStateID.PickUpActiveSkillTarget or stateId == GameStateID.PreviewActiveSkill then
        --只有技能预览状态机检查SkillID
        local curSkillID = cPickUp:GetCurActiveSkillID()
        if not curSkillID then
            Log.debug("Handle pick up activeSkillID is nil")
            return
        end

        if curSkillID < 0 then
            Log.debug("Handle pick up activeSkillID is invalid ", curSkillID)
            return
        end
        self:SetPickUpGrid(cPickUp, gridPos)
    elseif stateId == GameStateID.PickUpChainSkillTarget then
        --传送漩涡只设置了坐标没有设置SkillID，不检测
        self:SetChainSkillPickUpGrid(cPickUp, gridPos)
    else
        Log.fatal("### invalid state. stateId=", stateId)
    end
end

function PickUpGridSystem_Render:SetPickUpGrid( cPickUp, gridPos)
	---查询当前技能类型，通知不同的active skill pick up system执行
	local activeSkillID = cPickUp:GetCurActiveSkillID()
	local casterPetPstID = cPickUp:GetCurActiveSkillPetPstID()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    ---@type SkillPickUpType
    local activeSkillPickUpType = skillConfigData:GetSkillPickType()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    pickUpTargetCmpt:SetPickUpTargetType(activeSkillPickUpType)
    pickUpTargetCmpt:SetPickUpGridPos(gridPos)

    if  utilData:IsValidPiecePos(gridPos) and not utilData:IsPosBlock(gridPos, BlockFlag.LinkLine)  then
        pickUpTargetCmpt:SetPickUpGridSafePos(gridPos)
    end

    pickUpTargetCmpt:SetCurActiveSkillInfo(activeSkillID, casterPetPstID)

    renderBoardEntity:ReplacePickUpTarget()
end


function PickUpGridSystem_Render:SetChainSkillPickUpGrid(cPickUp, gridPos)
	---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
	if utilData:GetBoardIsPosNil(gridPos) then
		return
	end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
	pickUpTargetCmpt:SetPickUpTargetType(SkillPickUpType.ChainInstruction)
	pickUpTargetCmpt:SetPickUpGridPos(gridPos)

	if utilData:IsValidPiecePos(gridPos) and
		not utilData:IsPosBlock(gridPos, BlockFlag.LinkLine) and
		not utilData:IsPosDimensionDoor(gridPos)	then
		pickUpTargetCmpt:SetPickUpGridSafePos(gridPos)
	else
		Log.fatal("GridPos:", tostring(gridPos)," Is Invalid ")
	end
	renderBoardEntity:ReplacePickUpTarget()
end
