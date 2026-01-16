--[[----------------------------------------------------------
    渲染划线system
]] ------------------------------------------------------------
---@class LinkLineRenderSystem_Render:ReactiveSystem
_class("LinkLineRenderSystem_Render", ReactiveSystem)
LinkLineRenderSystem_Render = LinkLineRenderSystem_Render

function LinkLineRenderSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function LinkLineRenderSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PreviewChainPath)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function LinkLineRenderSystem_Render:Filter(entity)
    return entity:HasPreviewChainPath()
end

function LinkLineRenderSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:RenderChainPath(entities[i])
    end
end

---@param e Entity
function LinkLineRenderSystem_Render:RenderChainPath(e)
    --取出所有当前划的线，比较是否还在当前划线队列里，不在的要删除
    local exist_pos = self:RefreshLinkLine(e)

    ---@type PreviewChainPathComponent
    local chain_path_cmpt = e:PreviewChainPath()
    local chain_path = chain_path_cmpt:GetPreviewChainPath()
    if chain_path == nil then
        return
    end

    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:PreviewOnLinkLine(chain_path)
    end

    local pathCount = #chain_path
    local pieceType = chain_path_cmpt:GetPreviewPieceType()

    self:_RemoveUnLinkedGridEffectEntity(chain_path)
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    for i, v in ipairs(chain_path) do
        if i ~= 1 then
            local dir = chain_path[i - 1] - chain_path[i]
            if not table.icontains(exist_pos, v) then
                --新版linerender
                linkageRenderService:CreateLineRender(chain_path[i - 1], chain_path[i], i, v, dir, pieceType)
                --linkageRenderService:CreateLinkDot(v,dir,i,pathCount,pieceType)
                linkageRenderService:ShowLinkDot(chain_path[i])
            end
            --self:_RemoveSensingArea(v)
            --测试用数据，在最后的格子上画响应区域
            --self:_DarwSensingArea(v)

            --处理手指按下位置的特效
            if i == pathCount then
                linkageRenderService:RefreshTouchPosGridEffect(chain_path[i], -dir, pieceType)
                linkageRenderService:ShowBenumbTips(chain_path[i], pieceType)
            end
        end
    end
    local firstElementType = nil
    if pathCount <= 1 then
        linkageRenderService:RefreshTouchPosGridEffect()
    else
        firstElementType = chain_path_cmpt:GetFirstElementData()
    end

    local isLocal = self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.FlushPetChainSkillItem,
        isLocal,
        pathCount,
        pieceType,
        firstElementType
    )
end

function LinkLineRenderSystem_Render:RefreshLinkLine(chain_path_entity)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chain_path = previewChainPathCmpt:GetPreviewChainPath()

    local remove_list = {}
    local exist_pos = {}
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    for _, link_line_entity in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(link_line_entity)
        table.insert(exist_pos, pos)

        if not table.icontains(chain_path, pos) then
            --Log.fatal("destroy link line entity>>>>>>>>>>>>>>",pos.x," ",pos.y)
            table.insert(remove_list, link_line_entity)
        end
    end

    ---@type RenderChainPathComponent
    local renderChainPathComponent = reBoard:RenderChainPath()
    local chainAcrossMonster = renderChainPathComponent:GetChainMonsterShadowPosList() or {}
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    for _, e in ipairs(remove_list) do
        ---Log.fatal("RemoveLinkLineEntity ID:",e:GetID(),"RefreshLinkLine")
        linkageRenderService:HideLinkDot(boardServiceRender:GetRealEntityGridPos(e))
        local chainPos = boardServiceRender:GetRealEntityGridPos(e)
        --处理，划入一个格子，抬手后，怪物脚下的还是normal的情况
        if table.intable(chainAcrossMonster, chainPos) then
            pieceService:SetPieceAnimDown(chainPos)
        end

        linkageRenderService:DestroyLinkLine(e)
    end

    return exist_pos
end

---回退时，要删除不需要的格子特效
function LinkLineRenderSystem_Render:_RemoveUnLinkedGridEffectEntity(chainPath)
    local gridEffectGroup = self._world:GetGroup(self._world.BW_WEMatchers.GridEffect)
    local remove_list = {}
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    for _, gridEffectEntity in ipairs(gridEffectGroup:GetEntities()) do
        ---@type GridEffectComponent
        local gridEffectCmpt = gridEffectEntity:GridEffect()
        local gridEffectType = gridEffectCmpt:GetGridEffectType()
        if gridEffectType == "InPath" then
            local pos = boardServiceRender:GetRealEntityGridPos(gridEffectEntity)
            if not table.icontains(chainPath, pos) then
                --Log.fatal("destroy grid effect entity>>>>>>>>>>>>>>",pos.x," ",pos.y)
                table.insert(remove_list, gridEffectEntity)
            --self:_RemoveSensingArea(pos)
            end
        end
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
end
---@private
---@return number[]
function LinkLineRenderSystem_Render:_CreateSensingAreaAngle()
    ---@type string
    local str_angle = Cfg.cfg_link_line_sensing_area[1].angle
    ---@type number[]
    local angles = string.split(str_angle, "|")
    ---@type number[]
    local line_angles = {}

    local count_angles = 0

    count_angles = tonumber(angles[1])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[2])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[3])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[4])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[5])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[6])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[7])
    table.insert(line_angles, count_angles)
    count_angles = count_angles + tonumber(angles[8])
    table.insert(line_angles, count_angles)
    return line_angles
end

---@private
---@param pos Vector2
---在格子上划滑动响应区域
function LinkLineRenderSystem_Render:_DarwSensingArea(pos)
    local onoff = Cfg.cfg_link_line_sensing_area[1].drawonoff
    if not onoff or onoff == 0 then
        return
    end
    local e = self._world:GetService("Piece"):FindPieceEntity(pos)
    local gridLoc = e:GridLocation()
    local CirClePointCount = 360
    --线宽度
    local linewidth = 0.02
    --线比格子表面高的高度
    local lineheight = 0.005
    local view_cmpt = e:View()
    local view_wrapper = view_cmpt.ViewWrapper
    local view_transform = view_wrapper.Transform
    local root = GameObjectHelper.FindChild(view_transform, "Root")
    local line_render = root:GetComponent("LineRenderer")
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local real_pos = boardServiceRender:GridPos2RenderPos(pos) + Vector3(0, gridLoc.Height + lineheight, 0)
    local angle = 360 / CirClePointCount
    CirClePointCount = CirClePointCount + 16
    line_render.positionCount = CirClePointCount + 1
    line_render.startWidth = linewidth
    line_render.endWidth = linewidth
    local radius = Cfg.cfg_link_line_sensing_area[1].Radius
    local x, y
    line_render:SetPosition(0, Vector3(real_pos.x + radius, real_pos.y, real_pos.z))
    local line_angles = self:_CreateSensingAreaAngle()
    local i = 0
    local line_count = 0
    while i <= CirClePointCount do
        local point_count = i - line_count * 2
        local angle_tmp = angle * (point_count)
        x = Mathf.Sin(angle_tmp * Mathf.Deg2Rad) * radius
        y = Mathf.Cos(angle_tmp * Mathf.Deg2Rad) * radius
        line_render:SetPosition(i, Vector3(real_pos.x + x, real_pos.y, real_pos.z + y))
        if table.icontains(line_angles, angle_tmp) then
            line_render:SetPosition(i + 1, Vector3(real_pos.x, real_pos.y, real_pos.z))
            line_render:SetPosition(i + 2, Vector3(real_pos.x + x, real_pos.y, real_pos.z + y))
            i = i + 3
            line_count = line_count + 1
        else
            i = i + 1
        end
    end
end
---@private
function LinkLineRenderSystem_Render:_RemoveSensingArea(pos)
    return
end
