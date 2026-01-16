--[[------------------------------------------------------------------------------------------
    主动技预览阶段的连线起始system
]]
--------------------------------------------------------------------------------------------

---@class PreviewLinkLineBeginDragSystem_Render:UniqueReactiveSystem
_class("PreviewLinkLineBeginDragSystem_Render", UniqueReactiveSystem)
PreviewLinkLineBeginDragSystem_Render = PreviewLinkLineBeginDragSystem_Render

function PreviewLinkLineBeginDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:GetGridTouchStateID() ~= GridTouchStateID.PLLBeginDrag) then
        return false
    end

    return true
end

function PreviewLinkLineBeginDragSystem_Render:ExecuteWorld(world)
    local playerGridLocation = world:Player():GetLocalTeamEntity():GridLocation()

    ---@type GridTouchComponent
    local gridTouchComponent = world:GridTouch()
    local touchPosition = gridTouchComponent:GetGridTouchBeginPosition()
    local offset = gridTouchComponent:GetGridTouchOffset()
    ---@type PreviewLinkLineService
    local linkLineService = world:GetService("PreviewLinkLine")
    local touchPlayer = linkLineService:IsTouchInPlayerTouchArea(touchPosition, offset)
    gridTouchComponent:SetTouchPlayer(touchPlayer)
    if not touchPlayer then
        return
    end
    ---@type Entity
    local previewEntity = world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    linkLineService:CancelAllLinkPosPieceType(chainPath)
    previewLinkLineCmpt:ClearPreviewChainPath()
    Log.debug(
        "[touch] PreviewLinkLineBeginDragSystem_Render player position:",
        playerGridLocation.Position.x,
        " ",
        playerGridLocation.Position.y,
        " ",
        playerGridLocation.Position.z
    )
    Log.debug(
        "[touch] PreviewLinkLineBeginDragSystem_Render touchPosition:",
        touchPosition.x,
        " ",
        touchPosition.y,
        " ",
        touchPosition.z,
        " Time:",
        UnityEngine.Time.frameCount
    )
    Log.debug("[touch] PreviewLinkLineBeginDragSystem_Render offset:", offset.x, " ", offset.y, " ", offset.z)

    if touchPlayer then
        linkLineService:StartLinkLine(touchPosition, offset)

        ---@type PreviewMonsterTrapService
        local prvwSvc = world:GetService("PreviewMonsterTrap")
        prvwSvc:ClearMonsterTrapPreview()
    end
end

function PreviewLinkLineBeginDragSystem_Render:Filter(world)
    return true
end
