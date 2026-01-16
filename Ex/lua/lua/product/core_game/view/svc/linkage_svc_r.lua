--[[------------------------------------------------------------------------------------------
    LinkageRenderService 处理连线表现效果
]] --------------------------------------------------------------------------------------------

_class("LinkageRenderService", Object)
---@class LinkageRenderService:Object
LinkageRenderService = LinkageRenderService

function LinkageRenderService:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function LinkageRenderService:_ClearLinkageInfo()
    local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
        ---@type LinkageInfoComponent
        local linkageInfoCmpt = linkageEntity:LinkageInfo()
        linkageInfoCmpt:SetLinkCount(0)
        linkageEntity:SetViewVisible(false)
    end
end

function LinkageRenderService:ShowChainSkillIcon(petEntityID)
    local petEntity = self._world:GetEntityByID(petEntityID)
    if not petEntity then
        return
    end

    ---@type Entity[]
    local teLinkageInfo = self._world:GetGroupEntities(self._world.BW_WEMatchers.LinkageInfo)
    for _, eLinkageInfo in ipairs(teLinkageInfo) do
        ---@type LinkageInfoComponent
        local cLinkageInfo = eLinkageInfo:LinkageInfo()
        cLinkageInfo:SetChainSkillPet(petEntity)
    end
end

function LinkageRenderService:HideChainSkillIcon()
    ---@type Entity[]
    local teLinkageInfo = self._world:GetGroupEntities(self._world.BW_WEMatchers.LinkageInfo)
    for _, eLinkageInfo in ipairs(teLinkageInfo) do
        ---@type LinkageInfoComponent
        local cLinkageInfo = eLinkageInfo:LinkageInfo()
        cLinkageInfo:HideChainSkillPet()
    end
end

function LinkageRenderService:ShowLinkageInfo(chainPath, pieceType)
    if #chainPath <= 0 then
        self:_RemoveAllLinkedNumEntity()
        self:_ClearLinkageInfo()
        return
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---这个就是连线数
    local chainCount, superGridNum = utilCalcSvc:GetChainDamageRateAtIndex(chainPath, #chainPath)
    chainCount = chainCount + 1
    self:_ShowLinkageNum(chainPath, pieceType)

    local lastChainPos = chainPath[#chainPath]
    local hudWorldPos = self:_CalcGridHUDWorldPos(lastChainPos)
    if hudWorldPos == nil then
        --加一个判空操作
        return
    end
    --if chainCount <= 1 then
    --    self:_ClearLinkageInfo()
    --    --local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    --    --for _,linkageEntity in ipairs(linkageGroup:GetEntities()) do
    --    --    ---@type LinkageInfoComponent
    --    --    local linkageInfoCmpt = linkageEntity:LinkageInfo()
    --    --    linkageEntity:SetViewVisible(false)
    --    --end
    --else
    local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    if chainCount > 1 then
        for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
            ---@type LinkageInfoComponent
            local linkageInfoCmpt = linkageEntity:LinkageInfo()
            linkageEntity:SetViewVisible(true)
            linkageInfoCmpt:SetLinkCount(chainCount)
            linkageInfoCmpt:SetLinkagePos(hudWorldPos)
        end
    else
        for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
            ---@type LinkageInfoComponent
            local linkageInfoCmpt = linkageEntity:LinkageInfo()
            linkageEntity:SetViewVisible(false)
        end
    end

    -- if chainCount > 1 then
    --     self:ShowPathGridEffect(lastChainPos, chainCount)
    -- end
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowLinkageData,chainCount,screenPos)
end

function LinkageRenderService:UpdateLinkageInfoPos()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    if previewEntity == nil then
        return
    end

    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    if previewChainPathCmpt == nil then
        return
    end

    local chainPathArray = previewChainPathCmpt:GetPreviewChainPath()
    if chainPathArray == nil then
        return
    end

    local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
        if linkageEntity:HasViewExtension() then
            local visible = linkageEntity:IsViewVisible()
            if visible ~= true then
                return
            end
        else
            return
        end
    end

    local chainPathCount = #chainPathArray
    if chainPathCount < 2 then
        return
    end

    local lastChainPos = chainPathArray[chainPathCount]
    local hudWorldPos = self:_CalcGridHUDWorldPos(lastChainPos)
    if hudWorldPos == nil then
        return
    end

    local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
        ---@type LinkageInfoComponent
        local linkageInfoCmpt = linkageEntity:LinkageInfo()
        linkageInfoCmpt:SetLinkagePos(hudWorldPos)
    end
end

function LinkageRenderService:_RemoveAllLinkedNumEntity()
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()

    local remove_list = {}
    for _, linkageNumEntity in ipairs(allEntities) do
        table.insert(remove_list, linkageNumEntity)
    end
    for _, e in ipairs(remove_list) do
        self:DestroyLinkNum(e)
        -----@type LinkageNumComponent
        --local linkageNumCmpt = e:LinkageNum()
        --local entityConfigId = linkageNumCmpt:GetEntityConfigId()
        --entityPoolService:DestroyCacheEntity(e, entityConfigId)
        --entityPoolService:GetCacheEntityCountByID(entityConfigId)
        --Log.notice("RemoveLinkNum ID:",e:GetID())
        --linkRendererDataCmpt:RemoveLinkageNumEntity(e)
    end
end

function LinkageRenderService:_HasLinkageNumIndex(linkageNumIndex)
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()

    for _, linkageNumEntity in ipairs(allEntities) do
        ---@type LinkageNumComponent
        local linkageNumCmpt = linkageNumEntity:LinkageNum()
        local linkIndex = linkageNumCmpt:GetLinkageIndex()
        if linkIndex == linkageNumIndex then
            return true
        end
    end

    return false
end

function LinkageRenderService:_RemoveUnLinkedNumEntity(chainPath)
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local remove_list = {}
    local lastPos = chainPath[#chainPath]
    local alreadyOnScreenList = {}
    for _, linkageNumEntity in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(linkageNumEntity)

        if (not table.icontains(chainPath, pos)) then
            table.insert(remove_list, linkageNumEntity)
        end
    end

    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    --删掉已经不需要在连线数量队列里的实体
    for _, e in ipairs(remove_list) do
        self:DestroyLinkNum(e)
    end
end

function LinkageRenderService:_ShowLinkageNum(chainPath, pieceType)
    self:_RemoveUnLinkedNumEntity(chainPath)

    local chainPathCount = #chainPath
    ---大于3个格子时才需要显示
    if chainPathCount < 2 then
        return
    end

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    for chainIndex, v in ipairs(chainPath) do
        ---玩家脚底下的格子不显示索引号
        if chainIndex >= 2 then
            local hasLinkageNum = self:_HasLinkageNumIndex(chainIndex)
            if hasLinkageNum == false then
                local linkageNumPoint = chainPath[chainIndex]
                local chainRate, superGrid, poorGrid = utilCalcSvc:GetChainDamageRateAtIndex(chainPath, chainIndex)
                self:CreateLinkNumEntity(linkageNumPoint, chainIndex, chainRate + superGrid - poorGrid, pieceType)
            end
        end
    end
end

function LinkageRenderService:_CalcGridHUDWorldPos(gridPos)
    ---@type Entity
    local lastPieceEntity = self._world:GetService("Piece"):FindPieceEntity(gridPos)
    if lastPieceEntity == nil then
        return
    end

    ---@type LocationComponent
    local locationCmpt = lastPieceEntity:Location()
    if locationCmpt == nil then
        return
    end

    local gridRenderPos = lastPieceEntity:GetPosition()
    --Log.fatal("gridRenderPos:",gridRenderPos.x," ",gridRenderPos.y," ",gridRenderPos.z)
    local camera = self._world:MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(gridRenderPos)

    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = hudCamera:ScreenToWorldPoint(screenPos)

    return hudWorldPos
end

function LinkageRenderService:CreateLinkNumEntity(linkageNumPoint, linkageNum, chainRate, pieceType)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local entityConfigId = self:_GetLinkageNumIDByPieceType(pieceType)
    ---@type Entity
    local linkageNumEntity = entityPoolService:GetCacheEntityByConfigID(entityConfigId)
    entityPoolService:GetCacheEntityCountByID(entityConfigId)
    --Log.notice("CreateLinkNum Type:",pieceType,"ID:",linkageNumEntity:GetID(),"Rate:",chainRate,"Pos:", tostring(linkageNumPoint)," ",Log.traceback())
    linkageNumEntity:SetViewVisible(false)
    linkageNumEntity:SetLocation(linkageNumPoint, Vector2(0, 0))

    ---@type LinkageNumComponent
    local linkageNumCmpt = linkageNumEntity:LinkageNum()
    linkageNumCmpt:SetEntityConfigId(entityConfigId)
    linkageNumCmpt:SetLinkNum(linkageNum)
    linkageNumCmpt:SetLinkChainRate(chainRate)
    self:_SetLinkNumRate(linkageNumEntity)

    --添加实体
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    linkRendererDataCmpt:AddLinkageNumEntity(linkageNumEntity)

    return linkageNumEntity
end

function LinkageRenderService:_SetLinkNumRate(linknumEntity)
    ---@type ViewComponent
    local viewCmpt = linknumEntity:View()
    if viewCmpt == nil then
        return
    end
    local viewObj = viewCmpt:GetGameObject()
    if viewObj == nil then
        return
    end
    ---@type LinkageNumComponent
    local linkageNumCmpt = linknumEntity:LinkageNum()
    linknumEntity:SetViewVisible(true)
    local viewWrapper = viewCmpt.ViewWrapper
    local viewRoot = viewWrapper.GameObject
    viewRoot.transform.rotation = Quaternion.Euler(90, -90, 0)
    linkageNumCmpt:SetLinkCount(viewRoot)
end

function LinkageRenderService:_GetLinkageNumIDByPieceType(pieceType)
    local res = EntityConfigIDRender.LinkNum_Any
    if pieceType == PieceType.Red then
        res = EntityConfigIDRender.LinkNum_Red
    elseif pieceType == PieceType.Green then
        res = EntityConfigIDRender.LinkNum_Green
    elseif pieceType == PieceType.Blue then
        res = EntityConfigIDRender.LinkNum_Blue
    elseif pieceType == PieceType.Yellow then
        res = EntityConfigIDRender.LinkNum_Yellow
    end
    return res
end

--格子上找不到"xd/plane_3"，所以这个函数没用了
function LinkageRenderService:ShowPathGridEffect(gridPos, pathIndex)
    ---@type Entity
    local pieceEntity = self._world:GetService("Piece"):FindPieceEntity(gridPos)

    if not self._gridMpb then
        self._gridMpb = UnityEngine.MaterialPropertyBlock:New()
        self._gridColorIntensityStart = 0
        self._gridColorIntensityEnd = 1
        self._baseColorDicGrid = {}
    end

    local go = pieceEntity:View():GetGameObject()
    local trans = go.transform:Find("xd/plane_3")
    if not trans then
        return
    end
    local renderer = trans.gameObject:GetComponentInChildren(typeof(UnityEngine.Renderer))
    if not renderer then
        return
    end

    local pieceType = pieceEntity:Piece().Type
    local baseColor = self._baseColorDicGrid[pieceType]
    if not baseColor then
        baseColor = renderer.sharedMaterial:GetVector("_MainColor")
        self._baseColorDicGrid[pieceType] = baseColor
    end

    local t = pathIndex - 2
    local max = BattleConst.SuperChainCount - 1
    if t > max then
        t = max
    end

    if t >= 0 then
        local res = Mathf.Lerp(self._gridColorIntensityStart, self._gridColorIntensityEnd, t / max)
        local resColor = baseColor * (1 + res)
        resColor.w = baseColor.w
        self._gridMpb:SetVector("_MainColor", resColor)
        renderer:SetPropertyBlock(self._gridMpb)
    end
end

function LinkageRenderService:ShowSelectGridEffect(gridPos, pieceType, pathIndex)
    local hasGridEffect = self:_HasGridEffect(gridPos)
    if hasGridEffect == true then
        return
    end
    ---@type RenderEntityService
    local sEntity = self._world:GetService("RenderEntity")
    ---@type Entity
    local inPathGridEffectEntity = sEntity:CreateRenderEntity(self:_GetGridEffectIDByPieceType(pieceType))

    inPathGridEffectEntity:SetViewVisible(true)
    --inPathGridEffectEntity:SetGridLocation(gridPos, Vector2(0, 0))
    inPathGridEffectEntity:SetLocation(gridPos, Vector2(0, 0))
    inPathGridEffectEntity:GridEffect():SetPathIndex(pathIndex)
    inPathGridEffectEntity:GridEffect():SetPieceType(pieceType)

    return inPathGridEffectEntity
end

function LinkageRenderService:_GetGridEffectIDByPieceType(pieceType)
    local res = EntityConfigIDRender.LinkGridInPath_Any
    if pieceType == PieceType.Red then
        res = EntityConfigIDRender.LinkGridInPath_Red
    elseif pieceType == PieceType.Green then
        res = EntityConfigIDRender.LinkGridInPath_Green
    elseif pieceType == PieceType.Blue then
        res = EntityConfigIDRender.LinkGridInPath_Blue
    elseif pieceType == PieceType.Yellow then
        res = EntityConfigIDRender.LinkGridInPath_Yellow
    end
    return res
end

function LinkageRenderService:_HasGridEffect(targetGridPos)
    local gridEffectGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridEffect)
    for _, gridEffectEntity in ipairs(gridEffectGroup:GetEntities()) do
        ---@type GridEffectComponent
        local gridEffectCmpt = gridEffectEntity:GridEffect()
        local gridEffectType = gridEffectCmpt:GetGridEffectType()
        if gridEffectType == "InPath" then
            if gridEffectEntity:GridLocation() then
                local gridEffectPos = gridEffectEntity:GridLocation().Position
                if gridEffectPos == targetGridPos then
                    return true
                end
            end
        end
    end

    return false
end

function LinkageRenderService:RefreshTouchPosGridEffect(gridPos, dir, pieceType)
    ---@type Entity
    local curTouchPosGridEffect = nil
    local gridEffectGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridEffect)
    for _, gridEffectEntity in ipairs(gridEffectGroup:GetEntities()) do
        ---@type GridEffectComponent
        local gridEffectCmpt = gridEffectEntity:GridEffect()
        local gridEffectType = gridEffectCmpt:GetGridEffectType()
        if gridEffectType == "TouchPos" then
            if gridEffectCmpt:GetPieceType() ~= pieceType then
                self._world:DestroyEntity(gridEffectEntity)
            else
                curTouchPosGridEffect = gridEffectEntity
            end
            break
        end
    end

    if curTouchPosGridEffect and not gridPos then
        self._world:DestroyEntity(curTouchPosGridEffect)
    elseif curTouchPosGridEffect and gridPos then
        --curTouchPosGridEffect:SetGridLocation(gridPos, dir)
        curTouchPosGridEffect:SetLocation(gridPos, dir)
    elseif gridPos then
        ---@type RenderEntityService
        local sEntity = self._world:GetService("RenderEntity")
        ---@type Entity
        local touchPosEffect = sEntity:CreateRenderEntity(self:_GetTouchPosEffectIDByPieceType(pieceType))
        touchPosEffect:SetLocation(gridPos, dir)
        --touchPosEffect:SetGridLocation(gridPos, dir)
        touchPosEffect:GridEffect():SetPieceType(pieceType)
    end
end

function LinkageRenderService:_GetTouchPosEffectIDByPieceType(pieceType)
    local res = EntityConfigIDRender.LinkPos_Any
    if pieceType == PieceType.Red then
        res = EntityConfigIDRender.LinkPos_Red
    elseif pieceType == PieceType.Green then
        res = EntityConfigIDRender.LinkPos_Green
    elseif pieceType == PieceType.Blue then
        res = EntityConfigIDRender.LinkPos_Blue
    elseif pieceType == PieceType.Yellow then
        res = EntityConfigIDRender.LinkPos_Yellow
    end
    return res
end

---创建连线
function LinkageRenderService:CreateLineRender(headGridPos, endGridPos, idx, gridPos, dir, pieceType)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local entityConfigId = self:_GetLinkLineRenderIDByPieceType(pieceType)
    ---@type Entity
    local linkLineRenderEntity = entityPoolService:GetCacheEntityByConfigID(entityConfigId)
    entityPoolService:GetCacheEntityCountByID(entityConfigId)
    --Log.notice("Create LinkLine type:",pieceType,"ID:",linkLineRenderEntity:GetID()," Pos:", tostring(gridPos),"Index:",idx," ",Log.traceback())
    linkLineRenderEntity:SetLocation(gridPos, Vector2(0, 0))
    --linkLineRenderEntity:SetGridLocation(gridPos, Vector2(0, 0))
    linkLineRenderEntity:ReplaceLinkLineIndex(idx)

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local headRenderPos = nil
    if headGridPos ~= nil then
        headRenderPos = boardServiceRender:GridPos2RenderPos(headGridPos)
    end

    local endRenderPos = boardServiceRender:GridPos2RenderPos(endGridPos)

    local lineHeight = 0.01
    headRenderPos.y = lineHeight
    endRenderPos.y = lineHeight

    linkLineRenderEntity:ReplaceLinkLineRender(headRenderPos, endRenderPos)
    ---@type GridEffectComponent
    local gridEffectCmp = linkLineRenderEntity:GridEffect()
    local gridEffectType = gridEffectCmp:GetGridEffectType()
    linkLineRenderEntity:ReplaceGridEffect(gridEffectType)
    gridEffectCmp = linkLineRenderEntity:GridEffect()
    gridEffectCmp:SetPieceType(pieceType)
    gridEffectCmp:SetPathIndex(idx)

    ---@type LinkLineIndexComponent
    local linkLineIndexCmp = linkLineRenderEntity:LinkLineIndex()
    if linkLineIndexCmp then
        linkLineIndexCmp:SetEntityConfigId(entityConfigId)
    end

    --添加实体
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    linkRendererDataCmpt:AddLinkLineEntity(linkLineRenderEntity)

    return linkLineRenderEntity
end

function LinkageRenderService:_GetLinkLineRenderIDByPieceType(pieceType)
    local res = EntityConfigIDRender.LinkLine_Any
    if pieceType == PieceType.Red then
        res = EntityConfigIDRender.LinkLine_Red
    elseif pieceType == PieceType.Green then
        res = EntityConfigIDRender.LinkLine_Green
    elseif pieceType == PieceType.Blue then
        res = EntityConfigIDRender.LinkLine_Blue
    elseif pieceType == PieceType.Yellow then
        res = EntityConfigIDRender.LinkLine_Yellow
    end
    return res
end
---@param e Entity
function LinkageRenderService:DestroyLinkNum(e)
    --Log.notice("RemoveLinkNum ID:",e:GetID(),"Pos", tostring(e:GetRenderGridPosition())," ",Log.traceback())
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    ---@type LinkageNumComponent
    local linkageNumCmpt = e:LinkageNum()
    local entityConfigId = linkageNumCmpt:GetEntityConfigId()
    entityPoolService:DestroyCacheEntity(e, entityConfigId)
    entityPoolService:GetCacheEntityCountByID(entityConfigId)
    linkRendererDataCmpt:RemoveLinkageNumEntity(e)
end

---@param e Entity
function LinkageRenderService:DestroyLinkLine(e)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    --Log.notice("RemoveLinkLineEntity ID:",e:GetID(),"Pos:", tostring(e:GetRenderGridPosition())," ",Log.traceback())
    ---@type LinkLineIndexComponent
    local linkLineCmpt = e:LinkLineIndex()
    local entityConfigId = linkLineCmpt:GetEntityConfigId()
    self:ResetLinkLineEntity(e)
    entityPoolService:DestroyCacheEntity(e, entityConfigId)
    entityPoolService:GetCacheEntityCountByID(entityConfigId)
    linkRendererDataCmpt:RemoveLinkLineEntity(e)
end

---删除所有连线
function LinkageRenderService:DestroyAllLinkLine()
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()
    local remove_list = {}

    for _, link_line_entity in ipairs(allEntities) do
        table.insert(remove_list, link_line_entity)
    end

    for _, e in ipairs(remove_list) do
        self:DestroyLinkLine(e)
    end
end

---删除所有连线
function LinkageRenderService:HideAllLinkDot()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    for _, e in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(e)
        self:HideLinkDot(pos)
    end
end

---隐藏连线节点
function LinkageRenderService:HideLinkDot(pos)
    self._world:GetService("Piece"):SetPieceAnimLinkOut(pos)
end

---显示连线节点
function LinkageRenderService:ShowLinkDot(pos)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:SetPieceAnimLinkIn(pos)
end

function LinkageRenderService:ShowLinkNormal(pos)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:SetPieceAnimNormal(pos)
end

---创建连线节点
function LinkageRenderService:CreateLinkDot(pos, idx, pieceType)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local entityConfigId = self:_GetLinkDotRenderIDByPieceType(pieceType)
    ---@type Entity
    local dotEntity = entityPoolService:GetCacheEntityByConfigID(entityConfigId)

    dotEntity:SetLocation(pos, Vector2(1, 0))
    --dotEntity:SetGridLocation(pos, Vector2(1, 0))
    dotEntity:ReplaceLinkLineIndex(idx)

    ---@type LinkLineIndexComponent
    local linkLineIndexCmp = dotEntity:LinkLineIndex()
    if linkLineIndexCmp then
        linkLineIndexCmp:SetEntityConfigId(entityConfigId)
    end

    --添加实体
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    linkRendererDataCmpt:AddLinkageNumEntity(dotEntity)

    return dotEntity
end

function LinkageRenderService:_GetLinkDotRenderIDByPieceType(pieceType)
    local res = EntityConfigIDRender.LinkGridDot_Any
    if pieceType == PieceType.Red then
        res = EntityConfigIDRender.LinkGridDot_Red
    elseif pieceType == PieceType.Green then
        res = EntityConfigIDRender.LinkGridDot_Green
    elseif pieceType == PieceType.Blue then
        res = EntityConfigIDRender.LinkGridDot_Blue
    elseif pieceType == PieceType.Yellow then
        res = EntityConfigIDRender.LinkGridDot_Yellow
    end
    return res
end

function LinkageRenderService:DestroyAllLinkedNum()
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = self:GetLinkRenderDataComponent()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()

    local remove_list = {}
    for _, linkageNumEntity in ipairs(allEntities) do
        table.insert(remove_list, linkageNumEntity)
    end

    for _, e in ipairs(remove_list) do
        self:DestroyLinkNum(e)
        -----@type LinkageNumComponent
        --local linkageNumCmpt = e:LinkageNum()
        --local entityConfigId = linkageNumCmpt:GetEntityConfigId()
        --entityPoolService:DestroyCacheEntity(e, entityConfigId)
        --linkRendererDataCmpt:RemoveLinkageNumEntity(e)
    end
end

function LinkageRenderService:DestroyLinkedGridEffect()
    local gridEffectGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridEffect)
    local remove_list = {}
    for _, gridEffectEntity in ipairs(gridEffectGroup:GetEntities()) do
        ---@type GridEffectComponent
        local gridEffectCmpt = gridEffectEntity:GridEffect()
        local gridEffectType = gridEffectCmpt:GetGridEffectType()
        if gridEffectType == "InPath" then
            table.insert(remove_list, gridEffectEntity)
        end
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
end

function LinkageRenderService:ClearLinkRender()
    --临时把清除连线数量信息放在这里
    self:ClearLinkageInfo()

    --清楚连线
    self:DestroyTouchPosEffect()

    self:_DisablePreviewChainSkillRange()

    --清除麻痹tips
    self:HideBenumbTips()
    --self:_DisablePreviewPieceEffect()

    --清除怪物预警范围
    ---self:_ClearWarningArea()
end

function LinkageRenderService:ClearLinkageInfo()
    local linkageGroup = self._world:GetGroup(self._world.BW_WEMatchers.LinkageInfo)
    for _, linkageEntity in ipairs(linkageGroup:GetEntities()) do
        linkageEntity:LinkageInfo():SetLinkCount(0)
    end

    -- 放在chan move system中每走一格清除一格
    -- self:_ClearLinkageNum()
end

function LinkageRenderService:DestroyTouchPosEffect()
    local gridEffectGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridEffect)
    for _, gridEffectEntity in ipairs(gridEffectGroup:GetEntities()) do
        ---@type GridEffectComponent
        local gridEffectCmpt = gridEffectEntity:GridEffect()
        local gridEffectType = gridEffectCmpt:GetGridEffectType()
        if gridEffectType == "TouchPos" then
            self._world:DestroyEntity(gridEffectEntity)
            break
        end
    end
end

function LinkageRenderService:_DisablePreviewChainSkillRange()
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type PreviewChainSkillRangeComponent
    local previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()
    previewChainSkillRangeCmpt:EnablePreviewChainSkillRange(false)

    ---@type ChainPreviewMonsterBehaviorComponent
    local chainPreviewMonsterBehaviorCmpt = reBoard:ChainPreviewMonsterBehavior()
    chainPreviewMonsterBehaviorCmpt:SetChainPath({})
end

--[[
function LinkageRenderService:_DisablePreviewPieceEffect()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.PieceEffect)

    local effectPieceList = group:GetEntities()
    for i = 1, #effectPieceList do
        effectPieceList[i]:ReplacePieceEffectPreview(false)
    end
end]]
function LinkageRenderService:ShowBenumbTips(endPos, pieceType)
    local buffC = self._world:Player():GetPreviewTeamEntity():BuffView()
    if not buffC:HasBuffEffect(BuffEffectType.Benumb) then
        return
    end

    local effectService = self._world:GetService("Effect")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local previewEntity = self._world:GetPreviewEntity()
    local previewEnv = previewEntity:PreviewEnv()

    --麻痹tips
    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideBenumbTips, true)
    --麻痹格子特效
    local roundPosList = utilDataSvc:GetRoundGrid(endPos)
    for _, pos in ipairs(roundPosList) do
        local piece_type = previewEnv:GetPieceType(pos) --必须用预览层的格子颜色
        if
            CanMatchPieceType(pieceType, piece_type) and utilDataSvc:IsValidPiecePos(pos) and
                not utilDataSvc:IsPosBlockLinkLineForChain(pos)
         then
            local effEntity =
                effectService:CreateWorldPositionEffect(BattleConst.BenumbGridEffectID, Vector2(pos.x, pos.y), true)
            effEntity:AddBenumbEffect()
        end
    end
end

function LinkageRenderService:HideBenumbTips()
    local buffC = self._world:Player():GetPreviewTeamEntity():BuffView()
    if not buffC:HasBuffEffect(BuffEffectType.Benumb) then
        return
    end

    --麻痹tips
    self._world:EventDispatcher():Dispatch(GameEventType.ShowHideBenumbTips, false)
    --删除特效
    local group = self._world:GetGroup(self._world.BW_WEMatchers.BenumbEffect)
    for i, e in ipairs(group:GetEntities()) do
        self._world:DestroyEntity(e)
    end
end

---@param e Entity
function LinkageRenderService:ResetLinkLineEntity(e)
    ---@type ViewComponent
    local viewCmpt = e:View()
    if not viewCmpt then
        Log.fatal("re1 ID:", e:GetID())
        return
    end

    local gameObj = viewCmpt.ViewWrapper.GameObject
    if not gameObj then
        Log.fatal("re2 ID:", e:GetID())
        return
    end

    ---@type UnityEngine.LineRenderer
    local lineRender = gameObj:GetComponent("LineRenderer")
    if lineRender == nil then
        lineRender = gameObj:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
        if lineRender == nil then
            Log.fatal("Line render is null ID:", e:GetID())
            return
        end
    end
    local pos = Vector3(0, 1000, 0)
    lineRender:SetPosition(0, pos)
    lineRender:SetPosition(1, pos)
    e:ReplaceLinkLineRender(pos, pos)
end

---@param e Entity
function LinkageRenderService:AssembleChainPath(e)
    ---@type LinkLineRenderComponent
    local linkLineRenderCmpt = e:LinkLineRender()
    local headPos = linkLineRenderCmpt:GetHeadPos()
    local endPos = linkLineRenderCmpt:GetEndPos()

    ---@type ViewComponent
    local viewCmpt = e:View()
    if not viewCmpt then
        return
    end
    local gameObj = viewCmpt.ViewWrapper.GameObject
    ---@type UnityEngine.LineRenderer
    local lineRender = gameObj:GetComponent("LineRenderer")
    if lineRender == nil then
        lineRender = gameObj:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
        if lineRender == nil then
            Log.fatal("Line render is null")
            return
        end
    end

    gameObj.transform.rotation = Quaternion.Euler(90, 0, 0)
    lineRender:SetPosition(0, headPos)
    lineRender:SetPosition(1, endPos)
end

function LinkageRenderService:GetLinkRenderDataComponent()
    local reBoard = self._world:GetRenderBoardEntity()
    return reBoard:LinkRendererData()
end
