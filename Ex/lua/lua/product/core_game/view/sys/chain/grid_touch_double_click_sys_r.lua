--[[------------------------------------------------------------------------------------------
    双击格子
]] --------------------------------------------------------------------------------------------

---@class GridDoubleClickSystem_Render:UniqueReactiveSystem
_class("GridDoubleClickSystem_Render", UniqueReactiveSystem)
GridDoubleClickSystem_Render = GridDoubleClickSystem_Render

function GridDoubleClickSystem_Render:IsInterested(index, previousComponent, component)
    if (component == nil) then
        return false
    end

    if (not GridTouchComponent:IsInstanceOfType(component)) then
        return false
    end

    if (component:GetGridTouchStateID() ~= GridTouchStateID.DoubleClick) then
        return false
    end

    return true
end

---@param world World
function GridDoubleClickSystem_Render:Constructor(world)
    ---@type TimeService
    self._timeService = world:GetService("Time")

    self._lastClickTime = 0
end

function GridDoubleClickSystem_Render:ExecuteWorld(world)
    local currentTimeMS = self._timeService:GetCurrentTimeMs()
    if currentTimeMS - self._lastClickTime < BattleConst.DoubleClickIntervalTime then
        return
    end
    self._lastClickTime = currentTimeMS

    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    ---@type ConfigService
    self._configService = world:GetService("Config")

    ---@type  GuideServiceRender
    local guideService = world:GetService("Guide")
    local isGuide = guideService:HandleDoubleClickTrigger()
    if isGuide == true then
        return
    end

    --Log.fatal("handle double click>>>>>>>",UnityEngine.Time.frameCount)
    self.world = world
    ---@type Entity
    local teamEntity = world:Player():GetLocalTeamEntity()
    local playerPos = teamEntity:GetGridPosition()

    local gridTouchComponent = world:GridTouch()
    local touchPosition = gridTouchComponent:GetDoubleClickPos()
    if touchPosition ~= playerPos then
        Log.fatal("touchPosition ~= playerpos>>>>>>>")
        return
    end
	---@type Entity
	local previewEntity = world:GetPreviewEntity()
	---@type PreviewChainPathComponent
	local previewChainPathCmpt = previewEntity:PreviewChainPath()
	previewChainPathCmpt:ClearPreviewChainPath()

    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end
    ---@type LinkLineService
    local linkLineSvc = self._world:GetService("LinkLine")
    linkLineSvc:FinishBulletTime()

    ---@type PreviewMonsterTrapService
    local prvwSvc = self._world:GetService("PreviewMonsterTrap")
    prvwSvc:ClearMonsterTrapPreview()
    
    ---@type MainCameraComponent
    local cameraCmpt = self.world:MainCamera()
    cameraCmpt:DoMoveCamera(false)

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()

    if #chainPath ~= 0 then
        table.clear(chainPath)
    end
    table.insert(chainPath, touchPosition)

    local elementType = PieceType.None
    self:SendMovePathDoneCommand(chainPath, elementType)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
    self.world:EventDispatcher():Dispatch(GameEventType.FinishGuideWeakLine,{[1] = elementType, [2] = 1})

    local teamLeaderEntity =teamEntity:GetTeamLeaderPetEntity()
    --这里不需要指定进入普攻（如果指定了，会出现两次普攻的问题），在移动状态里，会进入普攻状态
    GameGlobal.EventDispatcher():Dispatch(GameEventType.IdleEnd, 1, teamLeaderEntity:GetID())
end

function GridDoubleClickSystem_Render:Filter(world)
    --Log.debug("GridBeginDragSystem Filter")
    return true
end

function GridDoubleClickSystem_Render:SendMovePathDoneCommand(chainPath, elementType)
    local cmd = MovePathDoneCommand:New()
    cmd:SetChainPath(chainPath)
    cmd:SetElementType(elementType)
    self.world:Player():SendCommand(cmd)
end
