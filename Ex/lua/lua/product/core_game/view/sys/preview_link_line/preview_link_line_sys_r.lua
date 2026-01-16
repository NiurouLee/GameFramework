--[[----------------------------------------------------------
    主动技预览阶段的渲染划线system
]]
------------------------------------------------------------
---@class PreviewLinkLineSystem_Render:ReactiveSystem
_class("PreviewLinkLineSystem_Render", ReactiveSystem)
PreviewLinkLineSystem_Render = PreviewLinkLineSystem_Render

function PreviewLinkLineSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function PreviewLinkLineSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
            {
                world:GetGroup(world.BW_WEMatchers.PreviewLinkLine)
            },
            {
                "Added"
            }
        )
    return c
end

---@param entity Entity
function PreviewLinkLineSystem_Render:Filter(entity)
    return entity:HasPreviewLinkLine()
end

function PreviewLinkLineSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:RenderChainPath(entities[i])
    end
end

---@param e Entity
function PreviewLinkLineSystem_Render:RenderChainPath(e)
    --取出所有当前划的线，比较是否还在当前划线队列里，不在的要删除
    local exist_pos = self:RefreshLinkLine(e)

    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = e:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return
    end

    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:PreviewOnLinkLine(chainPath)
    end

    local pathCount = #chainPath

    self:_RemoveUnLinkedGridEffectEntity(chainPath)

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    ---@type PreviewLinkLineService
    local preLinkLineSvc = self._world:GetService("PreviewLinkLine")
    for i, v in ipairs(chainPath) do
        if i ~= 1 then
            local dir = chainPath[i - 1] - chainPath[i]
            if not table.icontains(exist_pos, v) then
                local pieceType = preLinkLineSvc:ConvertLinkPosPieceType(chainPath[i])
                linkageRenderService:CreateLineRender(chainPath[i - 1], chainPath[i], i, v, dir, pieceType)
                linkageRenderService:ShowLinkDot(chainPath[i])
            end

            --处理手指按下位置的特效
            if i == pathCount then
                ---@type PreviewEnvComponent
                local env = self._world:GetPreviewEntity():PreviewEnv()
                local curType = env:GetPieceType(chainPath[i])
                linkageRenderService:RefreshTouchPosGridEffect(chainPath[i], -dir, curType)
            end
        end
    end

    if pathCount <= 1 then
        linkageRenderService:RefreshTouchPosGridEffect()
    end
end

function PreviewLinkLineSystem_Render:RefreshLinkLine(previewEntity)
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()
    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

    local remove_list = {}
    local exist_pos = {}
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    for _, link_line_entity in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(link_line_entity)
        table.insert(exist_pos, pos)

        if not table.icontains(chainPath, pos) then
            table.insert(remove_list, link_line_entity)
        end
    end

    ---@type RenderChainPathComponent
    local renderChainPathComponent = reBoard:RenderChainPath()
    local chainAcrossMonster = renderChainPathComponent:GetChainMonsterShadowPosList() or {}
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---@type PreviewLinkLineService
    local preLinkLineSvc = self._world:GetService("PreviewLinkLine")
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    ---@type GridTouchComponent
    local gridTouchCmpt = self._world:GridTouch()
    local touchStateID = gridTouchCmpt:GetGridTouchStateID()
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    for _, e in ipairs(remove_list) do
        local chainPos = boardServiceRender:GetRealEntityGridPos(e)
        linkageRenderService:HideLinkDot(chainPos)
        linkageRenderService:DestroyLinkLine(e)
        preLinkLineSvc:CancelLinkPosPieceType(chainPos)

        --处理，划入一个格子，抬手后，怪物脚下的还是normal的情况
        if touchStateID == GridTouchStateID.PLLEndDrag and table.intable(chainAcrossMonster, chainPos) then
            pieceService:SetPieceAnimDown(chainPos)
        end

        --检查棱镜还原
        if env:IsPrismPiece(chainPos) then
            pieceService:SetPieceAnimNormal(chainPos)
        end
    end

    return exist_pos
end

---回退时，要删除不需要的格子特效
function PreviewLinkLineSystem_Render:_RemoveUnLinkedGridEffectEntity(chainPath)
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
                table.insert(remove_list, gridEffectEntity)
            end
        end
    end

    for _, e in ipairs(remove_list) do
        self._world:DestroyEntity(e)
    end
end
