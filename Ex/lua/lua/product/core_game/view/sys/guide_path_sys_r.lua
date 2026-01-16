--[[------------------------------------------------------------------------------------------
    GuidePathSystem_Render : 划线引导system
]] --------------------------------------------------------------------------------------------

---@class GuidePathSystem_Render:ReactiveSystem
_class("GuidePathSystem_Render", ReactiveSystem)
GuidePathSystem_Render = GuidePathSystem_Render

function GuidePathSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._fingerTweener = nil

    self._guideLineEntityArray = {}
    self._guideDotEntityArray = {}
    self._guideLineNumEntityArray = {}
    self._guideGridEffectEntityArray = {}

    self._showGuideMark = false

    self._guideStepEvent = nil
end

function GuidePathSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.GuidePath)
    local c = Collector:New({group}, {"Added"})
    return c
end

function GuidePathSystem_Render:Filter(entity)
    return entity:HasGuidePath()
end

function GuidePathSystem_Render:TearDown()
    if self._fingerTweener ~= nil then
        self._fingerTweener:Kill()
        self._fingerTweener = nil
    end
    if self._guideStepEvent ~= nil then
        GameGlobal.Timer():CancelEvent(self._guideStepEvent)
        self._guideStepEvent = nil
    end
end

function GuidePathSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:OnGuidePath(entities[i])
    end
end

function GuidePathSystem_Render:OnGuidePath(entity)
    local reBoard = self._world:GetRenderBoardEntity()

    local fingerGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuideFinger)
    local fingerEntities = fingerGroup:GetEntities()
    local fingerEntity = fingerEntities[1]

    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    ---@type GuideRefreshType
    local refreshType = guidePathCmpt:GetGuideRefreshType()
    --Log.fatal("RefreshType",refreshType," frame",UnityEngine.Time.frameCount)

    if refreshType == GuideRefreshType.StopGuidePath then
        if self._fingerTweener ~= nil then
            self._fingerTweener:Kill()
            self._fingerTweener = nil
        end
        if self._guideStepEvent ~= nil then
            GameGlobal.Timer():CancelEvent(self._guideStepEvent)
            self._guideStepEvent = nil
        end

        ---@type LinkageRenderService
        -- local linkageRenderService = self._world:GetService("LinkageRender")
        -- linkageRenderService:DestroyAllLinkLine()
        -- linkageRenderService:DestroyAllLinkedNum()
        -- linkageRenderService:DestroyLinkedGridEffect()
        self:_DestroyGuideLinkDot()
        self:_DestroyGuideLinkLine()

        fingerEntity:SetViewVisible(false)
    elseif refreshType == GuideRefreshType.StartGuidePath then
        ---@type GuidePathComponent
        local guidePathCmpt = reBoard:GuidePath()
        local guidePath = guidePathCmpt:GetGuidePath()
        fingerEntity:SetViewVisible(true)
        self._showGuideMark = true
        if self._showGuideMark == true then
            self:_CreateGuideMarkEntity(guidePath)
            self._showGuideMark = false
        end
        self:_GuideTargetPath()
    elseif refreshType == GuideRefreshType.ShowGuideLine then
        if self._fingerTweener ~= nil then
            self._fingerTweener:Kill()
            self._fingerTweener = nil
        end

        if self._guideStepEvent ~= nil then
            GameGlobal.Timer():CancelEvent(self._guideStepEvent)
            self._guideStepEvent = nil
        end

        ---@type LinkageRenderService
        local linkageRenderService = self._world:GetService("LinkageRender")
        --linkageRenderService:DestroyAllLinkLine()
        --linkageRenderService:DestroyAllLinkedNum()
        --linkageRenderService:DestroyLinkedGridEffect()
        local guidePath = self:_GetGuidePath()
        for index, value in ipairs(guidePath) do
            linkageRenderService:ShowLinkNormal(value)
        end
        fingerEntity:SetViewVisible(false)
    elseif refreshType == GuideRefreshType.RestartGuidePath then
        fingerEntity:SetViewVisible(true)
        if self._showGuideMark == true then
            local guidePath = self:_GetGuidePath()
            self:_CreateGuideMarkEntity(guidePath)
            self._showGuideMark = false
        end
        self:_GuideTargetPath()

        ---@type CanMoveArrowService
        local arrowService = self._world:GetService("CanMoveArrow")
        arrowService:ShowCanMoveArrow(true)
    end
end

function GuidePathSystem_Render:_GuideTargetPath()
    local reBoard = self._world:GetRenderBoardEntity()

    local fingerGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuideFinger)
    local fingerEntities = fingerGroup:GetEntities()
    local fingerEntity = fingerEntities[1]
    local hasView = self:_HasView(fingerEntity)
    if hasView == false then
        return
    end

    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local guidePath = guidePathCmpt:GetGuidePath()

    local guidePointCount = #guidePath
    local duration = guidePointCount * BattleConst.GuidePathInternal

    self:_StartDotweenGuide(guidePath, duration)

    ---启动一个监听event，每隔一段时间执行一次引导
    if self._guideStepEvent == nil then
        self._guideStepEvent =
            GameGlobal.Timer():AddEventTimes(
            duration * 1000 + BattleConst.GuidePathStepWaitTime,
            TimerTriggerCount.Infinite,
            function()
                local refreshType = guidePathCmpt:GetGuideRefreshType()
                if refreshType == GuideRefreshType.StartGuidePath or refreshType == GuideRefreshType.RestartGuidePath then
                    self:_OnGuideComplete()
                    self:_StartDotweenGuide(guidePath, duration)
                end
            end
        )
    end
end

function GuidePathSystem_Render:_StartDotweenGuide(guidePath, duration)
    local fingerEntity = self:_GetFingerEntity()
    fingerEntity:SetViewVisible(true)
    ---@type ViewComponent
    local viewCmpt = fingerEntity:View()
    ---@type Transform
    local fingerTrans = viewCmpt:GetGameObject().transform
    local rectTrans = viewCmpt:GetGameObject():GetComponent("RectTransform")
    if rectTrans ~= nil then
        rectTrans:SetAsLastSibling()
    end

    local guideHudPosArray = self:_CalcGuideFingerPath(guidePath)
    fingerTrans.position = guideHudPosArray[1]
    self._fingerTweener =
        fingerTrans:DOPath(guideHudPosArray, duration):SetEase(DG.Tweening.Ease.Linear):OnWaypointChange(
        function(waypointIndex)
            local guidePathIndex = waypointIndex + 1
            self:_OnGuideWayPointChange(guidePathIndex)
        end
    )
end

function GuidePathSystem_Render:_OnGuideWayPointChange(guidePosIndex)
    --Log.fatal("guidePosIndex",guidePosIndex,UnityEngine.Time.frameCount)
    if guidePosIndex <= 1 then
        return
    end

    local guidePath = self:_GetGuidePath()
    local headPos = guidePath[guidePosIndex - 1]
    local endPos = guidePath[guidePosIndex]

    if endPos == nil then
        return
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieceType = utilData:FindPieceElement(endPos)

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:CreateLineRender(headPos, endPos, guidePosIndex, endPos, nil, pieceType)
    --linkageRenderService:CreateLinkDot(endPos,guidePosIndex,guidePosIndex)
    linkageRenderService:ShowLinkDot(endPos)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local chainRate,superGrid = utilCalcSvc:GetChainDamageRateAtIndex(guidePath, guidePosIndex)
    -- CreateLinkNumEntity添加了chain倍率参数，这里使用和正常逻辑一致的逻辑
    linkageRenderService:CreateLinkNumEntity(endPos, guidePosIndex, chainRate+superGrid, pieceType)
    --linkageRenderService:ShowSelectGridEffect(endPos)
end

function GuidePathSystem_Render:_OnGuideComplete()
    Log.notice("_OnGuideComplete",UnityEngine.Time.frameCount)
    local guidePath = self:_GetGuidePath()
    if self._showGuideMark == true then
        self:_CreateGuideMarkEntity(guidePath)
        self._showGuideMark = false
    end

    local fingerEntity = self:_GetFingerEntity()
    fingerEntity:SetViewVisible(false)
    fingerEntity:View():GetGameObject():SetActive(false)

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:DestroyAllLinkLine()
    linkageRenderService:DestroyAllLinkedNum()
    linkageRenderService:DestroyLinkedGridEffect()

    for i = 2, #guidePath do
        linkageRenderService:HideLinkDot(guidePath[i])
    end

    self._fingerTweener:Kill()
end

function GuidePathSystem_Render:_GetGuidePath()
    local reBoard = self._world:GetRenderBoardEntity()

    ---@type GuidePathComponent
    local guidePathCmpt = reBoard:GuidePath()
    local guidePath = guidePathCmpt:GetGuidePath()
    return guidePath
end

function GuidePathSystem_Render:_GetFingerEntity()
    local fingerGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuideFinger)
    local fingerEntities = fingerGroup:GetEntities()
    local fingerEntity = fingerEntities[1]

    return fingerEntity
end

---创建引导的细线
function GuidePathSystem_Render:_CreateGuideMarkEntity(guidePath)
    local guidePathMaxCount = #guidePath
    for guidePosIndex = 2, guidePathMaxCount do
        self:_CreateGuideLinkDot(guidePath[guidePosIndex])

        local headPos = guidePath[guidePosIndex - 1]
        local endPos = guidePath[guidePosIndex]
        self:_CreateGuideLineRender(headPos, endPos, endPos)
    end
end

function GuidePathSystem_Render:_HasView(e)
    local viewCmpt = e:View()
    if viewCmpt == nil then
        return false
    end

    local gameObj = viewCmpt:GetGameObject()
    if gameObj == nil then
        return false
    end

    return true
end

---计算出划线的路径点的HUD坐标值
---@param guideGridPath array 要划线的格子坐标数组
function GuidePathSystem_Render:_CalcGuideFingerPath(guideGridPath)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local fingerPath = {}
    for k, v in ipairs(guideGridPath) do
        local gridRenderPos = boardServiceRender:GridPos2RenderPos(v)
        local hudPos = self:_CalcGridHUDWorldPos(gridRenderPos)
        fingerPath[#fingerPath + 1] = hudPos
    end

    return fingerPath
end

function GuidePathSystem_Render:_CalcGridHUDWorldPos(gridRenderPos)
    local camera = self._world:MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(gridRenderPos)

    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = hudCamera:ScreenToWorldPoint(screenPos)

    return hudWorldPos
end

function GuidePathSystem_Render:_CreateGuideLinkDot(pos)
end

function GuidePathSystem_Render:_DestroyGuideLinkDot()
    local guideSpotGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuideSpot)
    local remove_list = {}
    for _, guideSpotEntity in ipairs(guideSpotGroup:GetEntities()) do
        table.insert(remove_list, guideSpotEntity)
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
end

function GuidePathSystem_Render:_DestroyGuideLinkLine()
    local guideLineGroup = self._world:GetGroup(self._world.BW_WEMatchers.GuideLinkLine)
    local remove_list = {}
    for _, guideSpotEntity in ipairs(guideLineGroup:GetEntities()) do
        table.insert(remove_list, guideSpotEntity)
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
end

function GuidePathSystem_Render:_CreateGuideLineRender(headGridPos, endGridPos, gridPos)
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    ---@type Entity
    local linkLineRenderEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.GuideLinkLine)

    --linkLineRenderEntity:SetGridLocation(gridPos, Vector2(1, 0))
    linkLineRenderEntity:SetLocation(gridPos, Vector2(1, 0))
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local headRenderPos = boardServiceRender:GridPos2RenderPos(headGridPos)
    local endRenderPos = boardServiceRender:GridPos2RenderPos(endGridPos)

    local lineHeight = 0.01
    headRenderPos.y = lineHeight
    endRenderPos.y = lineHeight

    linkLineRenderEntity:ReplaceLinkLineRender(headRenderPos, endRenderPos)

    return linkLineRenderEntity
end
