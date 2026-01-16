--[[------------------------------------------------------------------------------------------
    主动技预览阶段的连线拖拽system
]]
--------------------------------------------------------------------------------------------

---@class PreviewLinkLineDragSystem_Render:UniqueReactiveSystem
_class("PreviewLinkLineDragSystem_Render", UniqueReactiveSystem)
PreviewLinkLineDragSystem_Render = PreviewLinkLineDragSystem_Render

function PreviewLinkLineDragSystem_Render:Constructor(world)
    self._world = world
    self._CancelChainPathCallBack = GameHelper:GetInstance():CreateCallback(self.CancelChainPath, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.CancelChainPath, self._CancelChainPathCallBack)
end

function PreviewLinkLineDragSystem_Render:TearDown()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.CancelChainPath, self._CancelChainPathCallBack)
end

function PreviewLinkLineDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:GetGridTouchStateID() ~= GridTouchStateID.PLLDrag) then
        return false
    end

    return true
end

---@param world MainWorld
function PreviewLinkLineDragSystem_Render:ExecuteWorld(world)
    ---@type GridTouchComponent
    local gridTouchComponent = world:GridTouch()
    local touchPlayer = gridTouchComponent:IsTouchPlayer()
    if not touchPlayer then
        return
    end
    ---@type Entity
    local previewEntity = world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewChainPathCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return
    end

    ---@type GridTouchComponent
    local gridTouchComponent = world:GridTouch()
    local posArray = gridTouchComponent:GetGridMovePositionArray()
    local offsetArray = gridTouchComponent:GetGridMoveOffsetArray()
    ---@type PreviewLinkLineService
    local linkLineService = world:GetService("PreviewLinkLine")

    if #chainPath == 0 then
        local beginIndex = 0
        for touchIndex = 1, #posArray do
            local touchPosition = posArray[touchIndex]
            local touchOffset = offsetArray[touchIndex]
            if beginIndex == 0 then
                local touchPlayer = linkLineService:IsTouchInPlayerTouchArea(touchPosition, touchOffset)
                if touchPlayer then
                    ---@type PreviewMonsterTrapService
                    local prvwSvc = world:GetService("PreviewMonsterTrap")
                    prvwSvc:ClearMonsterTrapPreview()

                    gridTouchComponent:SetTouchPlayer(touchPlayer)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
                    local ret = linkLineService:StartLinkLine(touchPosition, touchOffset)
                    beginIndex = touchIndex
                    if ret ~= nil and ret == false then
                        break
                    end
                end
            elseif touchIndex > beginIndex then
                linkLineService:CalcPathPoint(touchPosition, touchOffset)
            end
        end
    else
        for touchIndex = 1, #posArray do
            local touchPosition = posArray[touchIndex]
            local touchOffset = offsetArray[touchIndex]
            linkLineService:CalcPathPoint(touchPosition, touchOffset)
        end
    end
end

function PreviewLinkLineDragSystem_Render:Filter(world)
    return true
end

function PreviewLinkLineDragSystem_Render:CancelChainPath()
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    if not inputCmpt:IsPreviewActiveSkill() then
        return
    end

    ---@type PreviewLinkLineService
    local linkLineService = self._world:GetService("PreviewLinkLine")
    linkLineService:CancelChainPath()

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    previewEntity:ReplacePreviewLinkLine({}, PieceType.None, PieceType.None)
    linkLineService:NotifyPickUpTargetChange()
end
