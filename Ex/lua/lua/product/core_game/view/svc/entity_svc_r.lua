--[[------------------------------------------------------------------------------------------
    RenderEntityService 渲染用Entity相关Service
]] --------------------------------------------------------------------------------------------

_class("RenderEntityService", Object)
---@class RenderEntityService:Object
RenderEntityService = RenderEntityService

---@class OutLineType
local OutlineType = {
    Short = 1,
    LeftShort = 2,
    RightShort = 3,
    Long = 4
}
_enum("OutlineType", OutlineType)

function RenderEntityService:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._outLineResPathList = {
        [OutlineType.Short] = "eff_gezi_bossyj_short.prefab",
        [OutlineType.LeftShort] = "eff_gezi_bossyj_L.prefab",
        [OutlineType.RightShort] = "eff_gezi_bossyj_R.prefab",
        [OutlineType.Long] = "eff_gezi_bossyj_long.prefab"
    }
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end
---@class OutlineDirType
local OutlineDirType = {Up = 1, Down = 2, Left = 3, Right = 4, LeftUp = 5, RightUp = 6, RightDown = 7, LeftDown = 8}
_enum("OutlineDirType",OutlineDirType)
function RenderEntityService:CreateRenderBoardEntity()
    local reBoard = self:CreateRenderEntity(EntityConfigIDRender.RenderBoard)
    self._world:SetRenderBoardEntity(reBoard)
end

---创建怪物移动的图标
function RenderEntityService:CreateMoveRangeArrowEntity(pos, dir, entityID)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local arrowEntity = entityPoolService:GetCacheEntityByConfigID(entityID)
    arrowEntity:SetLocation(pos, dir)
    ---@type MonsterAttackRangeComponent
    local monsterAttackRangeCmpt = arrowEntity:MonsterAttackRange()
    monsterAttackRangeCmpt:SetUseState(true)
end

function RenderEntityService:CreateDeathRangeEntity(pos, entityID)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local arrowEntity = entityPoolService:GetCacheEntityByConfigID(entityID)
    arrowEntity:SetLocation(pos, Vector2(0, 0))
    ---@type MonsterAttackRangeComponent
    local monsterAttackRangeCmpt = arrowEntity:MonsterAttackRange()
    ---可能没有,预览和预警区都用了这个，预警区没有这个组件。
    if monsterAttackRangeCmpt then
        monsterAttackRangeCmpt:SetUseState(true)
    end
    return arrowEntity
end

function RenderEntityService:CreateAreaEntityFromEntityPool(gridPos, entityID)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    local areaEntity = entityPoolService:GetCacheEntityByConfigID(entityID)
    areaEntity:SetPosition(gridPos)
    ---@type MonsterAttackRangeComponent
    local monsterAttackRangeCmpt = areaEntity:MonsterAttackRange()
    monsterAttackRangeCmpt:SetUseState(true)
    return areaEntity
end

---创建怪物攻击范围特效
function RenderEntityService:CreateAreaEntity(gridPos, entityID, resPath)
    if string.isnullorempty(resPath) then
        return
    end
    local areaEntity = self:CreateRenderEntity(entityID)
    --areaEntity:SetGridLocation(gridPos, nil)
    areaEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath))
    areaEntity:SetLocation(gridPos, nil)
    return areaEntity
end
----必须用这里删除怪物和机关预览
function RenderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
    ---@type Entity[]
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterAttackRange)
    -----@type EntityPoolServiceRender
    --local entityPoolService = self._world:GetService("EntityPool")
    for i, entity in ipairs(entityList) do
        ---@type MonsterAttackRangeComponent
        local monsterAttackRangeCmpt = entity:MonsterAttackRange()
        if monsterAttackRangeCmpt:IsUse() then
            self:DestroyAreaOutlineEntity({entity}, monsterAttackRangeCmpt:GetEntityConfigID())
            monsterAttackRangeCmpt:SetUseState(false)
        end
        --entityPoolService:DestroyCacheEntity(entity,monsterAttackRangeCmpt:GetEntityConfigID())
    end
end

function RenderEntityService:DestroyAreaOutlineEntity(entityList, entityID)
    if not entityID then
        entityID = EntityConfigIDRender.SkillRangeOutline
    end
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    for i, entity in ipairs(entityList) do
        entityPoolService:DestroyCacheEntity(entity, entityID)
    end
end

----必须用这里创建怪物和机关预览
function RenderEntityService:CreatePreviewAreaOutlineEntity(gridList, entityID)
    local entityList = self:CreateAreaOutlineEntity(gridList, entityID)
    for i, entity in ipairs(entityList) do
        ---@type MonsterAttackRangeComponent
        local monsterAttackRangeCmpt = entity:MonsterAttackRange()
        monsterAttackRangeCmpt:SetUseState(true)
    end
end

---创建攻击范围边框
function RenderEntityService:CreateAreaOutlineEntity(gridList, entityID, resPath, pieceType, height, radius)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")

    local outlineEntityList = {}
    for _, pos in ipairs(gridList) do
        local roundPosList = boardServiceRender:GetRoundPosList(pos)
        for i = 1, #roundPosList do
            local roundPos = roundPosList[i]
            if not table.icontains(gridList, roundPos) then
                ---@type Entity
                local outlineEntity = nil
                if entityID then
                    outlineEntity = entityPoolService:GetCacheEntityByConfigID(entityID)
                    if resPath then
                        outlineEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath))
                    end
                else
                    outlineEntity = entityPoolService:GetCacheEntityByConfigID(EntityConfigIDRender.SkillRangeOutline)
                end

                --播放动画
                if pieceType then
                    outlineEntity:ReplaceSkillRangeOutline(pieceType, false)
                end

                local gridOutlineHeight = 0
                if height then
                    gridOutlineHeight = height
                end
                local outlineDir = roundPos - pos
                local outlineDirType = boardServiceRender:GetOutlineDirType(outlineDir)
                outlineEntity:SetLocationHeight(gridOutlineHeight)
                self:_SetOutlineEntityPosAndDir(pos, outlineEntity, outlineDirType, radius)
                outlineEntityList[#outlineEntityList + 1] = outlineEntity
            end
        end
    end
    return outlineEntityList
end

function RenderEntityService:_SetOutlineEntityPosAndDir(pos, outlineEntity, outlineDirType, radius)
    local outlinePos, outlineDir = self:_GetOutlineEntityPosAndDir(pos, outlineEntity, outlineDirType, radius)
    --outlineEntity:SetGridLocation(outlinePos, outlineDir)
    outlineEntity:SetLocation(outlinePos, outlineDir)
end
----@param outlineEntity Entity
function RenderEntityService:GetOutlineSourcePos(outlineEntity,radius)
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    local renderPos = outlineEntity:GetPosition()
    local gridOutlineRadius = radius or 0.5
    ---@type Vector2
    local renderGridPos =boardRenderSvc:BoardRenderPos2FloatGridPos_New(renderPos)
    ---@type Vector2
    local renderDir = outlineEntity:GetRenderGridDirection()
    local sourcePos
    if renderDir.x == 0 and renderDir.y == -1 then
        sourcePos = Vector2(renderGridPos.x,renderGridPos.y-gridOutlineRadius)
    elseif renderDir.x == 0 and renderDir.y == 1 then
        sourcePos = Vector2(renderGridPos.x,renderGridPos.y+gridOutlineRadius)
    elseif renderDir.x == 1 and renderDir.y == 0 then
        sourcePos = Vector2(renderGridPos.x+gridOutlineRadius,renderGridPos.y)
    elseif renderDir.x == -1 and renderDir.y == 0 then
        sourcePos = Vector2(renderGridPos.x-gridOutlineRadius,renderGridPos.y)
    end
    return sourcePos
end



function RenderEntityService:_GetOutlineEntityPosAndDir(pos, outlineEntity, outlineDirType, radius)
    local gridOutlineRadius = 0.5
    if radius then
        gridOutlineRadius = radius
    end
    local outlinePos = pos
    local outlineDir = Vector2(0, 0)
    if outlineDirType == OutlineDirType.Up then
        outlinePos = pos + Vector2(0, gridOutlineRadius)
        outlineDir = Vector2(0, -1)
    elseif outlineDirType == OutlineDirType.Down then
        outlinePos = pos + Vector2(0, -gridOutlineRadius)
        outlineDir = Vector2(0, 1)
    elseif outlineDirType == OutlineDirType.Left then
        outlinePos = pos + Vector2(-gridOutlineRadius, 0)
        outlineDir = Vector2(1, 0)
    elseif outlineDirType == OutlineDirType.Right then
        outlinePos = pos + Vector2(gridOutlineRadius, 0)
        outlineDir = Vector2(-1, 0)
    end

    return outlinePos, outlineDir
end
---新创建攻击范围边框
function RenderEntityService:CreateAreaOutlineEntity_New(gridList, entityID)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local outlineInfoList = {}
    local outlineEntityList = {}
    for _, pos in ipairs(gridList) do
        local roundPosList = boardServiceRender:GetRoundPosList(pos)
        for i = 1, #roundPosList do
            local roundPos = roundPosList[i]
            if not table.icontains(gridList, roundPos) then
                local outlineDir = roundPos - pos
                local outlineDirType = boardServiceRender:GetOutlineDirType(outlineDir)
                table.insert(outlineInfoList, {pos = roundPos, sourcePos = pos, dirType = outlineDirType})
            end
        end
    end
    for k, v in pairs(outlineInfoList) do
        ---@type Entity
        local outlineEntity = self:CreateRenderEntity(entityID)
        local resourcePathType = self:_GetOutlineType(outlineInfoList, v)
        outlineEntity:ReplaceAsset(NativeUnityPrefabAsset:New(self._outLineResPathList[resourcePathType]))

        local gridOutlineHeight = BattleConst.WaringHeight
        self:_SetOutlineEntityPosAndDir(v.sourcePos, outlineEntity, v.dirType)
        outlineEntity:SetLocationHeight(gridOutlineHeight)

        outlineEntityList[#outlineEntityList + 1] = outlineEntity
    end
    return outlineEntityList
end
---@return number
function RenderEntityService:_GetOutlineType(outlineInfoList, element)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local roundPosList = boardServiceRender:GetRoundPosList(element.pos)

    if element.dirType == OutlineDirType.Up then
        if
            self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Left], OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Up)
         then
            return OutlineType.Long
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, -1), OutlineDirType.Left)
         then
            return OutlineType.RightShort
        end
        --if (self:_IsHasOutLine(outlineInfoList,roundPosList[OutlineDirType.Left],OutlineDirType.Right) or self:_IsHasOutLine(outlineInfoList,element.pos,OutlineDirType.Right)) and
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, -1), OutlineDirType.Right)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, -1), OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Up)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Left], OutlineDirType.Up)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Up)
         then
            return OutlineType.LeftShort
        end
        --if self:_IsHasOutLine(outlineInfoList,element.pos+Vector2(1,-1),OutlineDirType.Right) and
        --	self:_IsHasOutLine(outlineInfoList,roundPosList[OutlineDirType.Left],OutlineDirType.Up) then
        --	return OutlineType.LeftShort
        --end
        return OutlineType.Short
    end
    if element.dirType == OutlineDirType.Down then
        if
            self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Left], OutlineDirType.Down) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Down)
         then
            return OutlineType.Long
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, 1), OutlineDirType.Right)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, 1), OutlineDirType.Left)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, 1), OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Left], OutlineDirType.Down)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, 1), OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Down)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Left], OutlineDirType.Down)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Right], OutlineDirType.Down)
         then
            return OutlineType.RightShort
        end

        return OutlineType.Short
    end

    if element.dirType == OutlineDirType.Left then
        if
            self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Up], OutlineDirType.Left) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Left)
         then
            return OutlineType.Long
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, 1), OutlineDirType.Up)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Down) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, -1), OutlineDirType.Down)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(1, 1), OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Left)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Up], OutlineDirType.Left)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Down) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Left)
         then
            return OutlineType.RightShort
        end

        --if self:_IsHasOutLine(outlineInfoList,roundPosList[OutlineDirType.Up],OutlineDirType.Left) and
        --		self:_IsHasOutLine(outlineInfoList,element.pos+Vector2(1,-1),OutlineDirType.Down) then
        --	return OutlineType.RightShort
        --end
        return OutlineType.Short
    end
    if element.dirType == OutlineDirType.Right then
        if
            self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Up], OutlineDirType.Right) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Right)
         then
            return OutlineType.Long
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Down) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, -1), OutlineDirType.Down)
         then
            return OutlineType.LeftShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, 1), OutlineDirType.Up)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos + Vector2(-1, 1), OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Right)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Up) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Up], OutlineDirType.Right)
         then
            return OutlineType.RightShort
        end
        if
            self:_IsHasOutLine(outlineInfoList, element.pos, OutlineDirType.Down) and
                self:_IsHasOutLine(outlineInfoList, roundPosList[OutlineDirType.Down], OutlineDirType.Right)
         then
            return OutlineType.LeftShort
        end
        --if self:_IsHasOutLine(outlineInfoList,roundPosList[OutlineDirType.Up],OutlineDirType.RightShort) and
        --		self:_IsHasOutLine(outlineInfoList,element.pos+Vector2(-1,-1),OutlineDirType.Down) then
        --	return OutlineType.LeftShort
        --end
        return OutlineType.Short
    end
end

function RenderEntityService:_IsHasOutLine(outlineInfoList, pos, dirType)
    for k, v in pairs(outlineInfoList) do
        if v.pos.x == pos.x and v.pos.y == pos.y and v.dirType == dirType then
            return true
        end
    end
    return false
end

function RenderEntityService:DestroyRenderEntities(matcher)
    local rangeGroup = self._world:GetGroup(matcher)
    local removeEntities = {}
    for _, e in ipairs(rangeGroup:GetEntities()) do
        removeEntities[#removeEntities + 1] = e
    end

    for i = 1, #removeEntities do
        self._world:DestroyEntity(removeEntities[i])
    end
end
function RenderEntityService:SetHudPosition(ownEntity, hudEntity, offsetVector3)
    local ownerObj = ownEntity:View().ViewWrapper.GameObject
    local owner_entity_render_pos = self:_CalcGridHUDWorldPos(ownerObj.transform.position + offsetVector3)

    local go = hudEntity:View().ViewWrapper.GameObject

    local owner_foot_pos = owner_entity_render_pos
    go.transform.position = owner_foot_pos

    -- hudEntity:View().ViewWrapper:SetVisible(true) --TODO 设置显隐需另外加接口，否则对于每帧设置位置的实体，就隐藏不了了
end
function RenderEntityService:_CalcGridHUDWorldPos(gridRenderPos)
    local camera = self._world:MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(gridRenderPos)

    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = hudCamera:ScreenToWorldPoint(screenPos)

    return hudWorldPos
end

-------------------------------------LineRender -----------------------
-- 左上 左下 右下 右上
function RenderEntityService:GetGridPackageRoundPos(pos, radius)
    local offset = radius
    if not radius then
        offset = 0.5
    end
    return {
        Vector2(pos.x - offset, pos.y + offset),
        Vector2(pos.x - offset, pos.y - offset),
        Vector2(pos.x + offset, pos.y - offset),
        Vector2(pos.x + offset, pos.y + offset)
    }
end
---生成包裹格子特效
---gridList:格子坐标
---effectId:特效id
function RenderEntityService:GetGridPackagePosList(gridList, radius)
    local lines, source2RealMap = self:_GetGridPackagePosList_MakeLines(gridList, radius)
    local sameLines = {}
    for index, line1 in ipairs(lines) do
        for index, line2 in ipairs(lines) do
            if line1 ~= line2 then
                if line1.head == line2.trail and line1.trail == line2.head then
                    table.insert(sameLines, line1)
                    table.insert(sameLines, line2)
                end
            end
        end
    end
    for _, line in ipairs(sameLines) do
        for i = #lines, 1, -1 do
            if lines[i] == line then
                table.remove(lines, i)
            end
        end
    end
    local sortPos = {}
    local sortPosIndexs = {}
    local target = lines[1].trail
    table.insert(sortPos, target)
    table.insert(sortPosIndexs, lines[1].trailPosIndex)
    while (#sortPos <= #lines) do
        for _, line in ipairs(lines) do
            if line.head == target then
                target = line.trail
                table.insert(sortPos, target)
                table.insert(sortPosIndexs, line.trailPosIndex)
                break
            end
        end
    end
    local realSortPos = {}
    for i, tmp in ipairs(sortPos) do
        local posIndex = sortPosIndexs[i]
        local realPos = source2RealMap[posIndex]
        if realPos then
            realSortPos[i] = realPos:Clone()
        end
    end
    return realSortPos
end
---构建出线段数据，和根据点的index查到带有配置半径所得的实际的点
function RenderEntityService:_GetGridPackagePosList_MakeLines(gridList, radius)
    local lines = {}
    local source2RealMap = {}
    for gridIndex, pos in ipairs(gridList) do
        local sourcePosList = self:GetGridPackageRoundPos(pos)
        local realPosList = self:GetGridPackageRoundPos(pos, radius)
        for i = 1, #sourcePosList do
            local _roundPos = sourcePosList[i]
            local posIndex = gridIndex * 10 + i
            source2RealMap[posIndex] = realPosList[i]
            local _trail
            local _trailPosIndex
            if i + 1 <= #sourcePosList then
                _trail = sourcePosList[i + 1]
                _trailPosIndex = gridIndex * 10 + i + 1
            else
                _trail = sourcePosList[1]
                _trailPosIndex = gridIndex * 10 + 1
            end
            table.insert(
                lines,
                {head = _roundPos, headPosIndex = posIndex, trail = _trail, trailPosIndex = _trailPosIndex}
            )
        end
    end
    return lines, source2RealMap
end
function RenderEntityService:GetEdgePosList()
    local lines = {}
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local edgePieces = boardServiceRender:GetEdgePosList()
    for _, data in ipairs(edgePieces) do
        local roundPosList = self:GetGridPackageRoundPos(data.pos)
        for i = 1, #roundPosList do
            local _roundPos = roundPosList[i]
            local _trail = i + 1 <= #roundPosList and roundPosList[i + 1] or roundPosList[1]
            for index, value in ipairs(data.dirs) do
                if i == value then
                    table.insert(lines, {head = _roundPos, trail = _trail})
                end
            end
        end
    end
    local sortPos = {}
    local target = lines[1].trail
    table.insert(sortPos, target)
    while (#sortPos <= #lines) do
        for _, line in ipairs(lines) do
            if line.head == target then
                target = line.trail
                table.insert(sortPos, target)
                break
            end
        end
    end
    return sortPos
end

function RenderEntityService:CreateBoardOutlineEntity(TT)
    local effectEntity = self:CreateRenderEntity(EntityConfigIDRender.TurnChangeEffect, false)
    return effectEntity
end

function RenderEntityService:ShowBoardOutline(isPlayerTurn)
    local sortPos = {}
    local group = self._world:GetGroup(self._world.BW_WEMatchers.BoardOutline)
    local entities = group:GetEntities()
    if not next(entities) then
        local e = self:CreateBoardOutlineEntity()
        --首次创建的时候等一帧再播放动画，否则view没初始化
        TaskManager:GetInstance():CoreGameStartTask(
            function(TT)
                YIELD(TT)
                YIELD(TT)
                e:ReplaceBoardOutline(isPlayerTurn)

                sortPos = self:GetEdgePosList()
                local go = e:View():GetGameObject()
                ---@type UnityEngine.LineRenderer
                local child = GameObjectHelper.FindChild(go.transform, "biankuang")
                ---@type UnityEngine.LineRenderer
                local lineRender = child:GetComponent("LineRenderer")
                local count = #sortPos
                lineRender.positionCount = count
                ---@type BoardServiceRender
                local boardServiceRender = self._world:GetService("BoardRender")
                for index = 1, count do
                    local realPos = boardServiceRender:GridPos2RenderPos(sortPos[index])
                    lineRender:SetPosition(index - 1, realPos)
                end
                e:SetViewVisible(true)
            end
        )
        return
    end

    local e = entities[1]
    e:ReplaceBoardOutline(isPlayerTurn)
end

function RenderEntityService:ShowUITurnTips(isPlayerTurn, isAuroraTime)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowTurnTips, isPlayerTurn, isAuroraTime)
end

function RenderEntityService:GetScreenHeadPos(entity)
    local go = entity:View():GetGameObject()
    return self:_CalcSkinnedMeshPos(go)
end

function RenderEntityService:_CalcSkinnedMeshPos(ownerObj, camera)
    local hudWorldPos = ownerObj.transform.position
    local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(ownerObj)
    if skinnedMeshRender ~= nil then
        local skinnedMeshPosition = skinnedMeshRender.transform.position
        local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(ownerObj)
        local convertExtents = Vector3(0, meshExtents.x * 2, 0)
        local targetPos = skinnedMeshPosition + convertExtents

        local cameraMain = self._world:MainCamera():Camera()
        local screenPos = cameraMain:WorldToScreenPoint(targetPos)
        hudWorldPos = screenPos
        if camera then
            hudWorldPos = camera:ScreenToWorldPoint(screenPos)
        end
    else
        Log.fatal("ownerObj", ownerObj.name, "has no skinned mesh")
    end

    return hudWorldPos
end

---@param entity Entity
---@param isVisible boolean
function RenderEntityService:SetEntityVisible(entity, isVisible)
    local view = entity:View()
    if not view then
        return
    end
    view.ViewWrapper:SetVisible(isVisible)

    if isVisible then
        --早苗等切换动作形态的光灵 隐藏再显示,layerweight状态丢失，恢复一下
        self:RefreshAnimatoreLayerWeight(entity)
    end
end
function RenderEntityService:RefreshAnimatoreLayerWeight(entity)
    local view = entity:View()
    if not view then
        return
    end
    local cAnimatorController = entity:AnimatorController()
    if cAnimatorController then
        ---@type UnityEngine.GameObject
        local gameObject = view.ViewWrapper.GameObject
        ---@type UnityEngine.Animator
        local rootTF = gameObject.transform:Find("Root")
        if (rootTF == nil) then
            return
        end
        local animator = rootTF:GetComponent("Animator")
        if not animator then
            animator = gameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
        end
        if not animator then
            return
        end
        for layerIndex, weight in pairs(cAnimatorController.AnimatorLayerWeightTable) do
            animator:SetLayerWeight(layerIndex, weight)
        end
    end
end

function RenderEntityService:CreateBoardGridEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local gridEntityData = utilData:GetReplicaGridEntityData()
    if gridEntityData then
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        for pos, pieceType in pairs(gridEntityData) do
            local gridEntity = boardServiceRender:CreateGridEntity(pieceType, pos, true)
        end
    end
end

function RenderEntityService:CreateBoardSpliceGridEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local gridEntityData = utilData:GetReplicaSpliceGridEntityData()
    if gridEntityData then
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        for pos, pieceType in pairs(gridEntityData) do
            local gridEntity = boardServiceRender:CreateGridFakeEntity(pieceType, pos, false)
        end
    end
end

---
function RenderEntityService:CreateBoardMultiGridEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local gridEntityDataList = utilData:GetReplicaBoardMultiGridEntityData()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderMultiBoardComponent
    local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
    if gridEntityDataList then
        for boardIndex, gridEntityData in pairs(gridEntityDataList) do
            local boardInfo = utilData:GetMultiBoardInfo(boardIndex)
            local boardRoot = UnityEngine.GameObject:New("board_" .. boardIndex)
            boardRoot.transform.localPosition = Vector3(boardInfo.pos[1], boardInfo.pos[2], boardInfo.pos[3])
            local targetAngle =
                Vector3(
                math.floor(boardInfo.rotation[1] + 0.5),
                math.floor(boardInfo.rotation[2] + 0.5),
                math.floor(boardInfo.rotation[3] + 0.5)
            )
            --这种直接设置会数值不准  有小数点的误差
            boardRoot.transform.localEulerAngles = targetAngle

            -- boardRoot.transform:DORotate(targetAngle, 0.01)

            renderMultiBoardCmpt:SetMultiBoardRootGameObject(boardIndex, boardRoot)

            for pos, pieceType in pairs(gridEntityData._gridEntityTable) do
                ---@type BoardMultiServiceRender
                local boardMultiServiceRender = self._world:GetService("BoardMultiRender")
                local gridEntity = boardMultiServiceRender:CreateGridEntity(boardIndex, pieceType, pos, true, boardRoot)
            end
        end
    end
end

---创建一个虚影
---@param ownerEntity Entity
function RenderEntityService:CreateGhost(pos, ownerEntity, anim, prefab, disableAlpha)
    local configSvc = self._world:GetService("Config")
    local ghostEntity = self:CreateRenderEntity(EntityConfigIDRender.Ghost)
    if ownerEntity:HasTeam() then
        ownerEntity = ownerEntity:GetTeamLeaderPetEntity()
    end
    ---@type GridLocationComponent
    local cGridLocation = ownerEntity:GridLocation()
    local casterPos = cGridLocation:GetGridPos()
    ghostEntity:SetGridLocationAndOffset(pos, cGridLocation:GetGridDir(), cGridLocation:GetGridOffset())

    ---施法者ID
    ghostEntity:ReplaceGhost(ownerEntity:GetID())
    ghostEntity:ReplaceBodyArea(ownerEntity:BodyArea():GetArea())
    ---拿模型资源
    local prefabResPath = ""
    if ownerEntity:HasPetPstID() then
        ---@type PetPstIDComponent
        local petPstIDCmpt = ownerEntity:PetPstID()
        local petPstID = petPstIDCmpt:GetPstID()
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        prefabResPath = petData:GetPetPrefab(PetSkinEffectPath.MODEL_INGAME)
    elseif ownerEntity:HasMonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = ownerEntity:MonsterID()
        local monsterID = monsterIDCmpt:GetMonsterID()
        ---@type MonsterConfigData
        local monsterConfigData = configSvc:GetMonsterConfigData()
        --prefabResPath = monsterConfigData:GetMonsterResPath(monsterID)
        prefabResPath = ownerEntity:Asset():GetResPath()
        ghostEntity:AddMonsterID()
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local elementType = utilDataSvc:GetEntityElementPrimaryType(ownerEntity)
        ghostEntity:AddElement(elementType)
        Log.debug("Create Ghost monster, owner:",ownerEntity:GetID()," monsterID:",monsterID, " res:", prefabResPath)
    elseif ownerEntity:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRenderCmpt = ownerEntity:TrapRender()
        ---@type TrapConfigData
        local trapConfigData = configSvc:GetTrapConfigData()
        prefabResPath = trapConfigData:GetTrapResPath(trapRenderCmpt:GetTrapID())
    elseif ownerEntity:HasChessPet() then
        prefabResPath = ownerEntity:Asset():GetResPath()
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local elementType = utilDataSvc:GetEntityElementPrimaryType(ownerEntity)
        ghostEntity:AddElement(elementType)
    else
        Log.fatal("### PreviewActiveSkillService unknwon entity.")
    end

    --召唤指定模型的虚影
    if prefab then
        prefabResPath = prefab
    end

    ghostEntity:ReplaceAsset(NativeUnityPrefabAsset:New(prefabResPath, true))

    if not ownerEntity:HasPetPstID() then
        self:ModifyElementMaterial(ghostEntity)
    end

    local dir = ownerEntity:Location():GetDirection()
    ghostEntity:SetLocation(pos + cGridLocation:GetGridOffset(), Vector2(dir.x, dir.z))

    ---材质动画
    ---@type UnityEngine.GameObject
    local gameObject = ghostEntity:View().ViewWrapper.GameObject
    local csMaterialAnimation = gameObject:GetComponent(typeof(MaterialAnimation))
    if (not csMaterialAnimation) or tostring("csMaterialAnimation") == "null" then
        csMaterialAnimation = gameObject:AddComponent(typeof(MaterialAnimation))
    end

    local resServ = self._world.BW_Services.ResourcesPool
    local container = resServ:LoadAsset("globalShaderEffects.asset")
    ghostEntity:AddMaterialAnimationComponent(container, csMaterialAnimation)
    if not disableAlpha then
        ghostEntity:NewEnableGhost()
    end

    --幻象材质，本体在播，虚影就播
    ---@type MaterialAnimationComponent
    local materialAnimationComponent = ownerEntity:MaterialAnimationComponent()
    if
        materialAnimationComponent and materialAnimationComponent:MaterialAnimation() and
            materialAnimationComponent:MaterialAnimation():IsPlaying("common_shadoweff")
     then
        ghostEntity:PlayMaterialAnim("common_shadoweff")
    end

    --本体怪物，使用星灵模型，重新设置动画状态机
    ---@type BuffViewComponent
    local buffViewCmpt = ownerEntity:BuffView()
    local modelPetIndex = buffViewCmpt:GetBuffValue("ChangeModelWithPetIndex")
    if modelPetIndex and prefabResPath then
        local ancName = HelperProxy:GetPetAnimatorControllerName(prefabResPath, PetAnimatorControllerType.Battle)
        if ancName then
            local req2 = ResourceManager:GetInstance():SyncLoadAsset(ancName, LoadType.GameObject)
            ---@type UnityEngine.Animator
            local anim = req2.Obj:GetComponent(typeof(UnityEngine.Animator))
            if anim then
                local pet = ghostEntity:View().ViewWrapper.GameObject
                local petAnim = pet:GetComponentInChildren(typeof(UnityEngine.Animator))
                petAnim.runtimeAnimatorController = anim.runtimeAnimatorController
            end
        end
    end

    --虚影动作
    ---@type UnityEngine.Animator
    local rootTF = gameObject.transform:Find("Root")
    if rootTF then
        ---@type UnityEngine.Animator
        local animator = rootTF:GetComponent("Animator")
        if not animator then
            animator = gameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
        end

        if animator then
            animator:CrossFade("idle", 0)
            if anim then
                ghostEntity:SetAnimatorControllerTriggers({anim})
            end
        end
    end

    --虚影阻挡
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    if env then
        --将Ghost本体脚下的阻挡设为LinkLine
        local pos = ownerEntity:GetRenderGridPosition()
        for _, area in ipairs(ownerEntity:BodyArea():GetArea()) do
            local blockData = env:GetPosBlockData(pos + area)
            blockData:AddBlock(ownerEntity:GetID(), BlockFlag.LinkLine)
        end
    end

    --精英虚影
    if ownerEntity:HasMonsterID() and rootTF then
        ---Bug：MSG67234 gameObject如果添加过TrailEffectEx，
        ---不删除的话，会使无精英效果的小怪也播放精英材质动画
        local trailEffectExCmpt = rootTF.gameObject:GetComponent(typeof(TrailsFX.TrailEffectEx))
        if trailEffectExCmpt then
            UnityEngine.Object.Destroy(trailEffectExCmpt)
        end
        ghostEntity:RemoveTrailEffectEx()

        ---QA：MSG57883 精英词缀显示效果优化
        ---精英词条没配置特效列表，则使用原精英材质动画
        local eliteEffIDList = {}
        ---@type MonsterIDComponent
        local monsterIDCmpt = ownerEntity:MonsterID()
        if monsterIDCmpt then
            local eliteIDs = monsterIDCmpt:GetEliteIDArray()
            for _, eliteID in ipairs(eliteIDs) do
                local cfgElite = Cfg.cfg_monster_elite[eliteID]
                if cfgElite and cfgElite.EffectID then
                    table.insert(eliteEffIDList, cfgElite.EffectID)
                end
            end
        end
        if #eliteEffIDList == 0 then
            local cfg_monster = Cfg.cfg_monster[ownerEntity:MonsterID():GetMonsterID()]
            local cfg_monster_class = Cfg.cfg_monster_class[cfg_monster.ClassID]
            local eliteIDs = cfg_monster.EliteID
            local trailEffect = cfg_monster_class.TrailEffect
            -- local trailEffect = "eff_jingying_01.asset"
            if eliteIDs and table.count(eliteIDs) > 0 and trailEffect then
                trailEffectExCmpt = rootTF.gameObject:AddComponent(typeof(TrailsFX.TrailEffectEx))

                local containerTrailEffect = resServ:LoadAsset(trailEffect)
                ghostEntity:AddTrailEffectEx(containerTrailEffect, trailEffectExCmpt)
            end
        end
    end

    return ghostEntity
end

---清理ghost
function RenderEntityService:DestroyGhost()
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---删掉创建的玩家虚影
    local ghostEntities = self._world:GetGroup(self._world.BW_WEMatchers.Ghost):GetEntities()
    local removeList = {}
    for _, e in ipairs(ghostEntities) do
        removeList[#removeList + 1] = e:GetID()
    end
    for _, entityID in ipairs(removeList) do
        local ghostEntity = self._world:GetEntityByID(entityID)
        if env then
            local ownerID = ghostEntity:Ghost():GetOwnerID()
            local ownerEntity = self._world:GetEntityByID(ownerID)
            env:DelEntityBlockFlag(ownerEntity, ghostEntity:GridLocation():GetGridPos())
            env:AddEntityBlockFlag(ownerEntity, ownerEntity:GridLocation():GetGridPos())
        end

        -- 销毁ghost时，需恢复被ghost隐藏的掉落物
        local gridPos = Vector2.zero
        if ghostEntity:HasGridMove() then
            gridPos = ghostEntity:GridMove():GetTargetPos()
        else
            if ghostEntity:HasLocation() then 
                gridPos = self._world:GetService("BoardRender"):GetEntityRealTimeGridPos(ghostEntity, false)
            end
        end

        local bodyArea = ghostEntity:BodyArea():GetArea()
        local traprsvc = self._world:GetService("TrapRender")
        for _, v2RelativePos in ipairs(bodyArea) do
            local v2 = gridPos + v2RelativePos
            traprsvc:ShowHideTrapAtPos(v2, true)
        end
        --耶利亚 连线特效
        if ghostEntity:HasViewExtension() then
            ghostEntity:SetViewVisible(false)
        end
        ---@type EffectLineRendererComponent
        local effectLineRenderer = ghostEntity:EffectLineRenderer()
        if effectLineRenderer then
            ghostEntity:RemoveEffectLineRenderer()
        end
        ---@type EffectService
        local sEffect = self._world:GetService("Effect")
        sEffect:DestroyStaticEffect(ghostEntity)

        --耶利亚 预览 ghost 数字指示
        local headRoundInfoRender = ghostEntity:TrapRoundInfoRender()
        if headRoundInfoRender then
            local eId = headRoundInfoRender:GetRoundInfoEntityID()
            local eRound = self._world:GetEntityByID(eId)
            if eRound then
                self._world:DestroyEntity(eRound)
                ghostEntity:RemoveTrapRoundInfoRender()
            end
        end

        self._world:DestroyEntity(ghostEntity)
    end
end

function RenderEntityService:CreateBattleTeamMemberRender()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_LoadingResult
    local loadingResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.Loading)
    local teamCreateResult = loadingResCmpt:GetTeamCreationResult()
    for i, teamRes in ipairs(teamCreateResult) do
        local creationList = teamRes:GetPetCreationResultList()
        for _, v in ipairs(creationList) do
            ---@type DataPetCreationResult
            local creationRes = v
            local resPath = creationRes:GetPetCreationRes()
            local logicEntityID = creationRes:GetPetCreationLogicEntityID()
            local petEntity = self._world:GetEntityByID(logicEntityID)
            Log.info("load res path: "..tostring(resPath))
            petEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, false))
            local id = string.gsub(resPath, ".prefab", "")
            petEntity:PetPstID():SetResID(tonumber(id))

            self:_InitRenderAttributes(petEntity,creationRes)
        end
    end
end

---@param entity Entity
---@param creationRes DataPetCreationResult
function RenderEntityService:_InitRenderAttributes(entity,creationRes)
    local hp = creationRes:GetPetCreation_CurHp()
    local maxHP = creationRes:GetPetCreation_MaxHp()

    entity:ReplaceRedAndMaxHP(hp, maxHP)
end

function RenderEntityService:CreateRenderEntity(entityConstId, bShow)
    local ctx = EntityCreationContext:New()
    ctx.entity_config_id = entityConstId
    if bShow == nil then
        ctx.bShow = true
    else
        ctx.bShow = bShow
    end
    ---@type Entity
    local entity = self._world:CreateEntity()
    self._world:SetEntityIdByEntityConfigId(entity, entityConstId)
    EntityAssembler.AssembleEntityComponents(entity, ctx)
    return entity
end

---@param renderEntity Entity
function RenderEntityService:AssembleRenderEntity(renderEntity, entityConstId, bShow)
    local ctx = EntityCreationContext:New()
    ctx.entity_config_id = entityConstId
    if bShow == nil then
        ctx.bShow = true
    else
        ctx.bShow = bShow
    end

    self._world:SetEntityIdByEntityConfigId(renderEntity, entityConstId)
    EntityAssembler.AssembleEntityComponents(renderEntity, ctx)
    return renderEntity
end

function RenderEntityService:CreateBattleTeamRender()
    self:_CreateTeamRender()
end

function RenderEntityService:_CreateTeamRender()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_LoadingResult
    local res = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.Loading)
    ---@type TeamCreationResult[]
    local teamResults = res:GetTeamCreationResult()

    for i, teamRes in ipairs(teamResults) do
        local teamEntityID = teamRes:GetCreationResultTeamEntityID()
        ---@type Entity
        local teamEntity = self._world:GetEntityByID(teamEntityID)

        ---@type HPComponent
        local hpCmpt = teamEntity:HP()
        --主角血条UI资源
        local hpSliderEntity
        if self._world:Player():IsLocalTeamEntity(teamEntity) then
            hpSliderEntity = self:CreateRenderEntity(EntityConfigIDRender.PlayerHPSlider)
        else
            hpSliderEntity = self:CreateRenderEntity(EntityConfigIDRender.BossHPSlider)
        end
        hpCmpt:SetHPSliderEntityID(hpSliderEntity:GetID())

        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        if not previewEntity:HasConnectPieces() then
            previewEntity:AddConnectPieces({}, PieceType.None)
        end

        local hpOffset = teamRes:GetCreationResultHPOffset()
        hpCmpt:SetHPOffset(hpOffset)

        local element = teamRes:GetCreationResultElement()
        TaskManager:GetInstance():CoreGameStartTask(
            InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
            InnerGameHelperRender:GetInstance(),
            hpSliderEntity,
            element
        )

        local hp = teamRes:GetCreationResultHP()
        local maxHP = teamRes:GetCreationResultMaxHP()
        teamEntity:ReplaceRedAndMaxHP(hp, maxHP)

        local heroPos = teamRes:GetCreationResultBornPos()
        local heroRotation = teamRes:GetCreationResultBornRotation()
        --设置表现坐标
        teamEntity:SetLocation(heroPos, heroRotation)

        local firstPetEnityID = teamRes:GetCreationResultFirstPetEntityID()
        ---@type Entity
        local firstPetEntity = self._world:GetEntityByID(firstPetEnityID)
        firstPetEntity:SetLocation(heroPos, heroRotation)

        --血条关闭显示
        hpSliderEntity:SetViewVisible(false)

        --秘境不显示血条
        if self._world:MatchType() == MatchType.MT_Maze then
            teamEntity:HP():SetShowHPSliderState(false)
        end
    end
end

---@param petEntity Entity
function RenderEntityService:SetTeamLeaderRender(petEntity, showEffect)
    ---@type Entity
    local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
    ---@type PetPstIDComponent
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
    --血条血量
    ---@type HPComponent
    local hpComponent = teamEntity:HP()
    --血条高度
    local hpOffset = petData:GetHPOffset()
    hpComponent:SetHPOffset(hpOffset)
    hpComponent:SetHPPosDirty(true)
    local hpSliderEntity = self._world:GetEntityByID(hpComponent:GetHPSliderEntityID())

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local firstElement = utilDataSvc:GetEntityElementPrimaryType(teamEntity)

    TaskManager:GetInstance():CoreGameStartTask(
        InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
        InnerGameHelperRender:GetInstance(),
        hpSliderEntity,
        firstElement
    )
    if showEffect then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local effectID = BattleConst.ChangeTeamLeaderEffect[firstElement]
        local pos = petEntity:GetRenderGridPosition()
        effectService:CreateWorldPositionEffect(effectID, pos)
    end

    ---@type EffectAttachedComponent
    local cEffectAttached = teamEntity:EffectAttached()
    local tFxCtrlEntity = cEffectAttached:GetAttachedEntityIDArray()
    local mapFxEntity, mapFxID = cEffectAttached:GetAttachedFxMap()
    cEffectAttached:ClearAttachedEntityIDArray()
    if #tFxCtrlEntity > 0 then
        for _, id in ipairs(tFxCtrlEntity) do
            local e = self._world:GetEntityByID(id)
            if e then
                ---@type EffectControllerComponent
                local cEffectController = e:EffectController()
                local bindPos = cEffectController.BindPos
                local duration = cEffectController.Duration
                local type = cEffectController:GetEffectType()
                local followMove = cEffectController:GetFollowMove()
                local followRotate = cEffectController:GetFollowRotate()
                local bindLayer = cEffectController:GetBindLayer()
                local followRotateCaster = cEffectController:GetFollowRotateCaster()
                e:RemoveEffectController()

                e:AddEffectController(petEntity, bindPos, duration, type)
                local cNewController = e:EffectController()
                cNewController:SetFollowMove(followMove)
                cNewController:SetFollowRotate(followRotate)
                cNewController:SetBindLayer(bindLayer)
                cNewController:SetFollowRotateCaster(followRotateCaster)

                if not mapFxID[id] then
                    cEffectAttached:AddAttachedEntityID(id)
                else
                    local effectID = mapFxID[id]
                    cEffectAttached:AddAttachedEffectEntityID(id, effectID)
                end
            end
        end
    end
end

function RenderEntityService:_GetOutlinePointPos(pos, outlineDirType, radius, gridList)
    local gridOutlineRadius = 0.6

    local outlinePos1, outlinePos2

    if outlineDirType == OutlineDirType.Up then
        if table.icontains(gridList, Vector2(pos.x + 1, pos.y)) then
            outlinePos1 = Vector2(pos.x + gridOutlineRadius, pos.y + radius)
        else
            outlinePos1 = Vector2(pos.x + radius, pos.y + radius)
        end
        if table.icontains(gridList, Vector2(pos.x - 1, pos.y)) then
            outlinePos2 = Vector2(pos.x - gridOutlineRadius, pos.y + radius)
        else
            outlinePos2 = Vector2(pos.x - radius, pos.y + radius)
        end
    elseif outlineDirType == OutlineDirType.Down then
        if table.icontains(gridList, Vector2(pos.x + 1, pos.y)) then
            outlinePos1 = Vector2(pos.x + gridOutlineRadius, pos.y - radius)
        else
            outlinePos1 = Vector2(pos.x + radius, pos.y - radius)
        end
        if table.icontains(gridList, Vector2(pos.x - 1, pos.y)) then
            outlinePos2 = Vector2(pos.x - gridOutlineRadius, pos.y - radius)
        else
            outlinePos2 = Vector2(pos.x - radius, pos.y - radius)
        end
    elseif outlineDirType == OutlineDirType.Left then
        if table.icontains(gridList, Vector2(pos.x, pos.y + 1)) then
            outlinePos1 = Vector2(pos.x - radius, pos.y + gridOutlineRadius)
        else
            outlinePos1 = Vector2(pos.x - radius, pos.y + radius)
        end
        if table.icontains(gridList, Vector2(pos.x, pos.y - 1)) then
            outlinePos2 = Vector2(pos.x - radius, pos.y - gridOutlineRadius)
        else
            outlinePos2 = Vector2(pos.x - radius, pos.y - radius)
        end
    elseif outlineDirType == OutlineDirType.Right then
        if table.icontains(gridList, Vector2(pos.x, pos.y + 1)) then
            outlinePos1 = Vector2(pos.x + radius, pos.y + gridOutlineRadius)
        else
            outlinePos1 = Vector2(pos.x + radius, pos.y + radius)
        end
        if table.icontains(gridList, Vector2(pos.x, pos.y - 1)) then
            outlinePos2 = Vector2(pos.x + radius, pos.y - gridOutlineRadius)
        else
            outlinePos2 = Vector2(pos.x + radius, pos.y - radius)
        end
    end

    return outlinePos1, outlinePos2
end
---@param sortPos Vector2[]
function RenderEntityService:SetLineRendererPoint(outlineEntity, sortPos)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type UnityEngine.GameObject
    local go = outlineEntity:View():GetGameObject()
    if go then
        local newPos = Vector3(0, 0, 0)
        go.transform.position = newPos
        ---@type UnityEngine.LineRenderer
        local lineRender = go:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
        local count = #sortPos
        lineRender.positionCount = count
        for index = 1, count do
            local realPos = boardServiceRender:GridPos2RenderPos(sortPos[index])
            lineRender:SetPosition(index - 1, realPos)
        end
        outlineEntity:SetViewVisible(true)
    end
end
---创建怪物占据范围边框
function RenderEntityService:_CreateMonsterAreaOutlineEntity(gridList, entityID)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")

    local edgeGridList = gridList
    local sortPos = self:GetGridPackagePosList(edgeGridList, 0.4)
    ---@type Entity
    local outlineEntity = nil
    outlineEntity = entityPoolService:GetCacheEntityByConfigID(entityID)
    ---@type UnityEngine.GameObject
    local go = outlineEntity:View():GetGameObject()
    if go then
        local newPos = Vector3(0, 0, 0)
        go.transform.position = newPos
        ---@type UnityEngine.LineRenderer
        local lineRender = go:GetComponentInChildren(typeof(UnityEngine.LineRenderer))
        local count = #sortPos
        lineRender.positionCount = count
        for index = 1, count do
            local realPos = boardServiceRender:GridPos2RenderPos(sortPos[index])
            lineRender:SetPosition(index - 1, realPos)
        end
        outlineEntity:SetViewVisible(true)
    end

    return {outlineEntity}
end

---@param monsterEntity Entity
function RenderEntityService:CreateMonsterAreaOutlineEntity(monsterEntity)
    if not monsterEntity then
        Log.fatal("entity is null Trace", Log.traceback())
    end
    if not monsterEntity:MonsterID() then
        return
    end

    --在其他面不创建
    if monsterEntity:HasOutsideRegion() then
        return
    end

    --如果怪物的身形中的某一点在额外棋盘范围中
    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    local extraBoardPosRange = utilDataService:GetExtraBoardPosList()
    if extraBoardPosRange and table.count(extraBoardPosRange) > 0 then
        local gridPos = monsterEntity:GetGridPosition()
        local bodyAreaList = monsterEntity:BodyArea():GetArea()
        for _, bodyArea in ipairs(bodyAreaList) do
            local workPos = gridPos + bodyArea
            if table.intable(extraBoardPosRange, workPos) then
                return
            end
        end
    end

    local areaGridList = utilDataService:GetMonsterGridAreaList(monsterEntity)
    local areaOutLineEntityList =
        self:_CreateMonsterAreaOutlineEntity(areaGridList, EntityConfigIDRender.MonsterAreaOutLine)
    if not monsterEntity:HasMonsterAreaOutLineComponent() then
        monsterEntity:AddMonsterAreaOutLineComponent()
    end
    ---@type MonsterAreaOutLineComponent
    local monsterAreaOutLineCmpt = monsterEntity:MonsterAreaOutLineComponent()
    for k, e in pairs(areaOutLineEntityList) do
        monsterAreaOutLineCmpt:AddEntityID(e:GetID())
    end
end

function RenderEntityService:DestroyMonsterAreaOutLineEntity(monsterEntity)
    ---@type MonsterAreaOutLineComponent
    local monsterAreaOutLineCmpt = monsterEntity:MonsterAreaOutLineComponent()
    if monsterAreaOutLineCmpt then
        local entityIDList = monsterAreaOutLineCmpt:GetEntityIDList()
        ---@type EntityPoolServiceRender
        local entityPoolService = self._world:GetService("EntityPool")
        for k, id in pairs(entityIDList) do
            --@type Entity
            local entity = self._world:GetEntityByID(id)
            entityPoolService:DestroyCacheEntity(entity, EntityConfigIDRender.MonsterAreaOutLine)
        end
        monsterAreaOutLineCmpt:ClearEntityIDList()
    end
    --Log.fatal("CreateLine ID:",monsterEntity:GetID(),"Trace:",Log.traceback())
end

---根据entity的element类型修改材质
---@param targetEntity Entity
function RenderEntityService:ModifyElementMaterial(targetEntity)
    --冒烟报错 加日志
    local monsterViewCmpt = targetEntity:View()
    if not monsterViewCmpt then
        Log.error("ModifyElementMaterial entity has no view ,entityID:", targetEntity:GetID())
        local monsterIDCmpt = targetEntity:MonsterID()
        if monsterIDCmpt then
            local monsterID = monsterIDCmpt:GetMonsterID()
            Log.error("ModifyElementMaterial entity has no view ,monsterID:", monsterID)
        end
    end
    local monsterObj = targetEntity:View().ViewWrapper.GameObject
    ---@type UnitResourceHolder
    local resHolderCmpt = monsterObj:GetComponent("UnitResourceHolder")
    if resHolderCmpt == nil then
        return
    end

    local elementBodyMat = nil
    local elementWeaponMat = nil

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local elementType = utilDataSvc:GetEntityElementPrimaryType(targetEntity)

    if elementType == ElementType.ElementType_Blue then
        elementBodyMat = resHolderCmpt.elementBodyMaterial_Blue
        elementWeaponMat = resHolderCmpt.elementWeaponMaterial_Blue
    elseif elementType == ElementType.ElementType_Red then
        elementBodyMat = resHolderCmpt.elementBodyMaterial_Red
        elementWeaponMat = resHolderCmpt.elementWeaponMaterial_Red
    elseif elementType == ElementType.ElementType_Green then
        elementBodyMat = resHolderCmpt.elementBodyMaterial_Green
        elementWeaponMat = resHolderCmpt.elementWeaponMaterial_Green
    elseif elementType == ElementType.ElementType_Yellow then
        elementBodyMat = resHolderCmpt.elementBodyMaterial_Yellow
        elementWeaponMat = resHolderCmpt.elementWeaponMaterial_Yellow
    end

    if elementBodyMat == nil then
        Log.notice("element material is nil ", monsterObj.name)
        return
    end
    ---@type FadeComponent
    --local fadeCmpt = monsterObj:GetComponent("FadeComponent")

    ---@type UnityEngine.SkinnedMeshRenderer
    local bodyRender = GameObjectHelper.FindFirstSkinedMeshRender(monsterObj)
    if bodyRender ~= nil then
        local sharedMaterials = bodyRender.sharedMaterials
        local curMat = sharedMaterials[0]
        if string.find(curMat.name, "Instance") then
            UnityEngine.Object.Destroy(curMat)
        end

        -- if fadeCmpt ~= nil then
        --     fadeCmpt:RefreshData()
        -- end

        local newBodyMat = UnityEngine.Material:New(elementBodyMat)
        local newMats = {}
        newMats[#newMats + 1] = newBodyMat
        bodyRender.sharedMaterials = newMats
    end

    if elementWeaponMat == nil then
        return
    end

    ---@type UnityEngine.SkinnedMeshRenderer
    local weaponRender = GameObjectHelper.FindSecondSkinedMeshRender(monsterObj)
    if weaponRender ~= nil then
        local sharedMaterials = weaponRender.sharedMaterials
        local curMat = sharedMaterials[0]
        if string.find(curMat.name, "Instance") then
            UnityEngine.Object.Destroy(curMat)
        end

        -- if fadeCmpt ~= nil then
        --     fadeCmpt:RefreshData()
        -- end

        local newWeaponMat = UnityEngine.Material:New(elementWeaponMat)
        local newMats = {}
        newMats[#newMats + 1] = newWeaponMat
        weaponRender.sharedMaterials = newMats
    end
end

---@param ownerEntity Entity
function RenderEntityService:CreateStuntMonster(ownerEntity, stuntTag, monsterClassID)
    if (not ownerEntity:HasMonsterID()) and (not monsterClassID) then
        Log.error("CreateStuntMonster: monster ID is required. ")
        return
    end
    local e = self:CreateRenderEntity(EntityConfigIDRender.StuntMonster)

    local resPath = ownerEntity:Asset():GetResPath()
    if monsterClassID then
        local cfg = Cfg.cfg_monster_class[monsterClassID]
        if cfg then
            resPath = cfg.ResPath
        else
            Log.error(self._className, "invalid monsterClassID: ", monsterClassID)
        end
    end
    e:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, true))
    e:SetAnimatorControllerTriggers({"idle"})

    ---@type UnityEngine.GameObject
    local gameObject = e:View().ViewWrapper.GameObject
    local csMaterialAnimation = gameObject:GetComponent(typeof(MaterialAnimation))
    if (not csMaterialAnimation) or tostring("csMaterialAnimation") == "null" then
        csMaterialAnimation = gameObject:AddComponent(typeof(MaterialAnimation))
    end

    local resServ = self._world.BW_Services.ResourcesPool
    local container = resServ:LoadAsset("globalShaderEffects.asset")
    e:AddMaterialAnimationComponent(container, csMaterialAnimation)

    if not ownerEntity:StuntOwnerComponent() then
        ownerEntity:AddStuntOwnerComponent()
    end

    local cStunt = ownerEntity:StuntOwnerComponent()
    if cStunt:GetStuntByTag(stuntTag) then
        cStunt:RemoveStunt(stuntTag)
    end
    cStunt:AddStunt(stuntTag, e)

    return e
end

---@param truePosList Vector2[]
function RenderEntityService:CreateSideEffects(truePosList, sideEffectID, v3SideScale)
    local retEntity = {}
    for _, pos in ipairs(truePosList) do
        local entityList = {}
        local sideList = {}
        if not table.icontains(truePosList, pos + Vector2(0, 1)) then
            local tmp = {
                gridPos = pos + Vector2(0, BattleConst.GridSideLength / 2),
                gridDir = Vector3(0, 0, -1)
            }
            table.insert(
                sideList,
                {gridPos = pos + Vector2(0, BattleConst.GridSideLength / 2), gridDir = Vector3(0, 0, -1)}
            )
        end
        if not table.icontains(truePosList, pos + Vector2(0, -1)) then
            local tmp = {
                gridPos = pos + Vector2(0, -BattleConst.GridSideLength / 2),
                gridDir = Vector3(0, 0, 1)
            }
            table.insert(
                sideList,
                {gridPos = pos + Vector2(0, -BattleConst.GridSideLength / 2), gridDir = Vector3(0, 0, 1)}
            )
        end
        if not table.icontains(truePosList, pos + Vector2(1, 0)) then
            local tmp = {
                gridPos = pos + Vector2(BattleConst.GridSideLength / 2, 0),
                gridDir = Vector3(-1, 0, 0)
            }
            table.insert(
                sideList,
                {gridPos = pos + Vector2(BattleConst.GridSideLength / 2, 0), gridDir = Vector3(-1, 0, 0)}
            )
        end
        if not table.icontains(truePosList, pos + Vector2(-1, 0)) then
            local tmp = {
                gridPos = pos + Vector2(-BattleConst.GridSideLength / 2, 0),
                gridDir = Vector3(1, 0, 0)
            }
            table.insert(
                sideList,
                {gridPos = pos + Vector2(-BattleConst.GridSideLength / 2, 0), gridDir = Vector3(1, 0, 0)}
            )
        end
        for _, v in pairs(sideList) do
            local entity = self:CreateSideEffect(v.gridPos, v.gridDir, v3SideScale, sideEffectID)
            table.insert(retEntity, entity)
        end
    end
    return retEntity
end

---@param scale Vector3
function RenderEntityService:CreateSideEffect(girdPos, girdDir, scale, sideEffectID)
    --Log.fatal("CreateSideEffect GridPos:",tostring(girdPos),"Dir:",tostring(girdDir))
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    local effEntitySide = sEffect:CreateWorldPositionDirectionEffect(sideEffectID, girdPos, girdDir)
    effEntitySide:SetViewVisible(true)
    effEntitySide:SetScale(scale)
    return effEntitySide
end

----@param source_entity Entity
---@param target_entity Entity
function RenderEntityService:AttackTurn(source_entity, target_entity)
    if target_entity == nil then
        Log.notice("TurnToTarget ,targetEntity is nil")
        return
    end

    ---@type TrapRenderComponent
    local trapRenderCmpt = source_entity:TrapRender()
    if trapRenderCmpt then
        return --是机关，不会转
    end

    ---@type BuffViewComponent
    local buff = source_entity:BuffView()
    if buff:HasBuffEffect(BuffEffectType.Stun) then
        return --有眩晕buff，不会转
    end

    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    if source_entity:HasMonsterID() then
        ---@type MonsterConfigData
        local mstcfg = cfgsvc:GetMonsterConfigData()

        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local buffVal = utilData:GetEntityBuffValue(source_entity, "MONSTER_VIEW_CAN_TURN")
        if buffVal == nil then
            local cMonsterID = source_entity:MonsterID()
            if not mstcfg:CanTurn(cMonsterID:GetMonsterID()) then
                return false
            end
        elseif buffVal == 0 then
            return false
        end
    end

    if not source_entity:HasBodyArea() then
        return
    end
    local body_area = source_entity:BodyArea()._area

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    if #body_area == 4 then
        ---@type Vector2
        local targetGridPos = boardServiceRender:GetEntityRealTimeGridPos(target_entity, true)
        ---@type Vector2
        local sourceGridPos = boardServiceRender:GetEntityRealTimeGridPos(source_entity, true)
        local tmpV = targetGridPos - sourceGridPos
        local arrDir = {Vector2.left, Vector2.right, Vector2.up, Vector2.down}
        local minIdx = 1
        local min = Vector2.Angle(arrDir[minIdx], tmpV)
        for i = 2, #arrDir do
            local angle = Vector2.Angle(arrDir[i], tmpV)
            if min > angle then
                min = angle
                minIdx = i
            end
        end
        local minDir = arrDir[minIdx]
        --source_entity:SetGridDirection(minDir)
        source_entity:SetDirection(minDir)
    else
        --转向effect slot�?
        local castPos = source_entity:Location().Position
        local holderTf = target_entity:View().ViewWrapper.Transform
        local targetPos = holderTf.position
        local bindTf = GameObjectHelper.FindChild(holderTf, "EffectSlot")
        if bindTf then
            targetPos = bindTf.position
        end
        local dir = targetPos - castPos
        local gridDir = Vector2(dir.x, dir.z)
        --source_entity:SetGridDirection(gridDir)
        source_entity:SetDirection(gridDir)
    end
end

---让source_entity转向target_entity
---@param source_entity Entity
---@param target_entity Entity
---@param damagePos Vector3
function RenderEntityService:TurnToTarget(source_entity, target_entity, forceTurn, damagePos, turnToTargetType)
    if source_entity == nil or target_entity == nil or target_entity:HasView() == false then
        Log.notice("TurnToTarget ,targetEntity is nil")
        return
    end
    ---@type PlaySkillService
    local playSkillSvc = self._world:GetService("PlaySkill")
    if not playSkillSvc:CheckSourceCanTurn(source_entity) and not forceTurn then
        return
    end
    if source_entity:HasTeam() then
        source_entity = source_entity:GetTeamLeaderPetEntity()
    end

    --转向effect slot

    ---@type Vector3
    local castPos = source_entity:Location().Position

    local holderTf = target_entity:View().ViewWrapper.Transform
    local targetPos = holderTf.position
    if damagePos then
        --普攻表现，指定第一个伤害坐标，否则会朝向目标的中点
        targetPos = damagePos
    elseif turnToTargetType == TurnToTargetType.PickupPos then
        ----@type RenderPickUpComponent
        local renderPickUpComponent = target_entity:RenderPickUpComponent()
        local firstPickUpPos = renderPickUpComponent:GetFirstValidPickUpGridPos()
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        targetPos = boardServiceRender:GridPos2RenderPos(firstPickUpPos)
    else
        local bindTf = GameObjectHelper.FindChild(holderTf, "EffectSlot")
        if bindTf then
            targetPos = bindTf.position
        end
    end
    local dir = targetPos - castPos
    local gridDir = Vector2(dir.x, dir.z)
    --source_entity:SetGridDirection(gridDir)
    source_entity:SetDirection(gridDir)
end

---让sourceEntity转向targetEntity所在的格子位置
---@param sourceEntity Entity
---@param targetEntity Entity
function RenderEntityService:TurnToTargetGrid(sourceEntity, targetEntity)
    if sourceEntity == nil or targetEntity == nil then
        Log.notice("TurnToTarget, entity is nil")
        return
    end
    ---@type PlaySkillService
    local playSkillSvc = self._world:GetService("PlaySkill")
    if not playSkillSvc:CheckSourceCanTurn(sourceEntity) then
        return
    end
    if sourceEntity:HasTeam() then
        sourceEntity = sourceEntity:GetTeamLeaderPetEntity()
    end

    ---@type Vector3
    local casterPos = sourceEntity:Location().Position
    ---@type Vector2
    local targetPosVec2 = targetEntity:GetGridPosition()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type Vector3
    local targetPos = boardServiceRender:GridPosition2LocationPos(targetPosVec2, targetEntity)

    local dir = targetPos - casterPos
    local gridDir = Vector2(dir.x, dir.z)
    sourceEntity:SetDirection(gridDir)
end

-------------------------------------------------------------------

function RenderEntityService:CreateChessPet()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_LoadingResult
    local res = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.Loading)
    ---@type DataChessPetCreationResult[]
    local chessPetResults = res:GetChessPetCreationResult()

    for i, v in ipairs(chessPetResults) do
        ---@type DataChessPetCreationResult
        local chessPetRes = v

        local chessPetEntityID = chessPetRes:GetChessPetEntityIID()
        ---@type Entity
        local chessPetEntity = self._world:GetEntityByID(chessPetEntityID)

        --
        local resPath = chessPetRes:GetChessPetResPath()
        chessPetEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, false))

        ---@type HPComponent
        local hpCmpt = chessPetEntity:HP()
        hpCmpt:SetHPBarTempHide(true)
        --主角血条UI资源
        local hpSliderEntity = self:CreateRenderEntity(EntityConfigIDRender.PlayerHPSlider)
        hpCmpt:SetHPSliderEntityID(hpSliderEntity:GetID())

        local hpOffset = chessPetRes:GetChessPetHPOffset()
        hpCmpt:SetHPOffset(hpOffset)

        local element = chessPetRes:GetChessPetElement()
        TaskManager:GetInstance():CoreGameStartTask(
            InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
            InnerGameHelperRender:GetInstance(),
            hpSliderEntity,
            element
        )

        local hp = chessPetRes:GetChessPetHP()
        local maxHP = chessPetRes:GetChessPetMaxHP()
        chessPetEntity:ReplaceRedAndMaxHP(hp, maxHP)

        -----------
        ---@type DataGridLocationResult
        local gridLocRes = chessPetRes:GetChessPetGridLocResult()
        local heroPos = gridLocRes:GetGridLocResultBornPos()
        local bornOffset = gridLocRes:GetGridLocResultBornOffset()
        local heroRotation = gridLocRes:GetGridLocResultBornDir()

        --设置表现坐标
        chessPetEntity:SetLocation(heroPos + bornOffset, heroRotation)

        --血条关闭显示
        hpSliderEntity:SetViewVisible(false)
    end
end

---@param gridList Vector2[]
function RenderEntityService:CreateTrapAreaOutlineEntity(gridList, resPath)
    local gridIndexBoolDic = {}
    for _, pos in ipairs(gridList) do
        gridIndexBoolDic[Vector2.Pos2Index(pos)] = true
    end

    local tTaskIDs = {}

    for _, pos in ipairs(gridList) do
        local posIndex = Vector2.Pos2Index(pos)
        if not gridIndexBoolDic[posIndex + 100] then
            self:_CreateTrapAreaOutlineEntityAtPos(resPath, pos, Vector2.right)
        end
        if not gridIndexBoolDic[posIndex - 100] then
            self:_CreateTrapAreaOutlineEntityAtPos(resPath, pos, Vector2.left)
        end
        if not gridIndexBoolDic[posIndex + 1] then
            self:_CreateTrapAreaOutlineEntityAtPos(resPath, pos, Vector2.up)
        end
        if not gridIndexBoolDic[posIndex - 1] then
            self:_CreateTrapAreaOutlineEntityAtPos(resPath, pos, Vector2.down)
        end
    end
end

function RenderEntityService:_CreateTrapAreaOutlineEntityAtPos(resPath, v2Pos, v2Dir)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")

    local eOutline = self:CreateRenderEntity(EntityConfigIDRender.TrapAreaOutline)
    eOutline:ReplaceAsset(NativeUnityPrefabAsset:New(resPath))
    eOutline:SetLocation(v2Pos, v2Dir)

    return eOutline
end

function RenderEntityService:ClearTrapAreaOutlineEntity()
    self:DestroyRenderEntities(self._world.BW_WEMatchers.TrapAreaElement)
end
