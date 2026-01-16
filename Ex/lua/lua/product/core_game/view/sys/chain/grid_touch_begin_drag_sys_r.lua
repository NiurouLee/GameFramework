--[[------------------------------------------------------------------------------------------
    点选格子system
]] --------------------------------------------------------------------------------------------

---@class GridBeginDragSystem_Render:UniqueReactiveSystem
_class("GridBeginDragSystem_Render", UniqueReactiveSystem)
GridBeginDragSystem_Render = GridBeginDragSystem_Render

function GridBeginDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:GetGridTouchStateID() ~= GridTouchStateID.BeginDrag) then
        return false
    end

    return true
end

function GridBeginDragSystem_Render:ExecuteWorld(world)
    self.world = world
    local playerGridLocation = world:Player():GetLocalTeamEntity():GridLocation()

    ---@type GridTouchComponent
    local gridTouchComponent = world:GridTouch()
    local touchPosition = gridTouchComponent:GetGridTouchBeginPosition()
    local offset = gridTouchComponent:GetGridTouchOffset()
    --local touchPlayer = self:NearCenter(playerGridLocation.Position, touchPosition, offset)
    ---@type LinkLineService
    local linkLineService = self.world:GetService("LinkLine")
    local touchPlayer = linkLineService:IsTouchInPlayerTouchArea(touchPosition, offset)
    gridTouchComponent:SetTouchPlayer(touchPlayer)
	---@type Entity
	local previewEntity = self._world:GetPreviewEntity()
	---@type PreviewChainPathComponent
	local previewChainPathCmpt = previewEntity:PreviewChainPath()
	previewChainPathCmpt:ClearPreviewChainPath()
    Log.debug(
        "[touch] GridBeginDragSystem_Render player position:",
        playerGridLocation.Position.x,
        " ",
        playerGridLocation.Position.y,
        " ",
        playerGridLocation.Position.z
    )
    Log.debug(
        "[touch] GridBeginDragSystem_Render touchPosition:",
        touchPosition.x,
        " ",
        touchPosition.y,
        " ",
        touchPosition.z,
        " Time:",
        UnityEngine.Time.frameCount
    )
    Log.debug("[touch] GridBeginDragSystem_Render offset:", offset.x, " ", offset.y, " ", offset.z)

    if touchPlayer then
        linkLineService:StartLinkLine(touchPosition, offset)

        ---@type PreviewMonsterTrapService
        local prvwSvc = self._world:GetService("PreviewMonsterTrap")
        prvwSvc:ClearMonsterTrapPreview()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.MatchLineDragStart)
    else
        Log.notice("[touch] GridBeginDragSystem_Render no touch player ")
        ---@type GuideServiceRender
        local guideService = self.world:GetService("Guide")
        if not guideService:IsGuidePathInvokeType() then
            ---@type PreviewMonsterTrapService
            local prvwSvc = self._world:GetService("PreviewMonsterTrap")
            prvwSvc:CheckPreviewMonsterAction(touchPosition, offset)

            ---@type PreviewActiveSkillService
            local previewActiveSkillSvc = world:GetService("PreviewActiveSkill")
            --previewActiveSkillSvc:AllPieceDoConvert("Normal")
            world:GetService("MonsterShowRender"):MonsterGridAnimDown()
        end
    end
end

function GridBeginDragSystem_Render:Filter(world)
    --Log.debug("GridBeginDragSystem_Render Filter")
    return true
end

function GridBeginDragSystem_Render:NearCenter(centerPos, checkPos, offset)
    local diff = checkPos - centerPos
    if math.abs(diff.x) >= 1 or math.abs(diff.y) >= 1 then
        return false
    end
    return math.abs(offset.x) < 1 and math.abs(offset.y) < 1
end
