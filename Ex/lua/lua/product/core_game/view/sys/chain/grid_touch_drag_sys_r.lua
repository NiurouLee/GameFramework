--[[------------------------------------------------------------------------------------------
    划线选取格子system
]] --------------------------------------------------------------------------------------------

---@class GridDragSystem_Render:UniqueReactiveSystem
_class("GridDragSystem_Render", UniqueReactiveSystem)
GridDragSystem_Render = GridDragSystem_Render

function GridDragSystem_Render:Constructor(world)
    self.world = world
    self._CancelChainPathCallBack = GameHelper:GetInstance():CreateCallback(self.CancelChainPath, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.CancelChainPath, self._CancelChainPathCallBack)
end

function GridDragSystem_Render:TearDown()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.CancelChainPath, self._CancelChainPathCallBack)
end

function GridDragSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:GetGridTouchStateID() ~= GridTouchStateID.Drag) then
        return false
    end

    return true
end
---@param world MainWorld
function GridDragSystem_Render:ExecuteWorld(world)
    self.world = world
    
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()

    ---@type GridTouchComponent
    local gridTouchComponent = world:GridTouch()
    local posArray = gridTouchComponent:GetGridMovePositionArray()
    local offsetArray = gridTouchComponent:GetGridMoveOffsetArray()
    ---@type LinkLineService
    local linkLineService = world:GetService("LinkLine")
    if chainPath == nil then
        return
    end

    if #chainPath == 0 then
        local beginIndex = 0
        for touchIndex = 1, #posArray do
            local touchPosition = posArray[touchIndex]
            local touchOffset = offsetArray[touchIndex]
            if beginIndex == 0 then
                local touchPlayer = linkLineService:IsTouchInPlayerTouchArea(touchPosition, touchOffset)
                if touchPlayer then
                    
                    ---@type PreviewMonsterTrapService
                    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
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

function GridDragSystem_Render:Filter(world)
    --Log.debug("GridDragSystem_Render Filter")
    return true
end

function GridDragSystem_Render:CancelChainPath()
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    if inputCmpt:IsPreviewActiveSkill() then
        return
    end
    
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end
    local linkLineService = self.world:GetService("LinkLine")
    linkLineService:CancelChainPath()

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()    
    previewEntity:ReplacePreviewChainPath({}, PieceType.None, PieceType.None)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem,true, 0, nil)

    ---@type LinkageRenderService
    local linkageRenderService = self.world:GetService("LinkageRender")
    linkageRenderService:ShowLinkageInfo({})
    linkageRenderService:HideBenumbTips()
    self:_DisablePreviewChainSkillRange()
end

function GridDragSystem_Render:_DisablePreviewChainSkillRange()
    local reBoard = self._world:GetRenderBoardEntity()

    ---@type PreviewChainSkillRangeComponent
    local previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()
    previewChainSkillRangeCmpt:EnablePreviewChainSkillRange(false)
end
