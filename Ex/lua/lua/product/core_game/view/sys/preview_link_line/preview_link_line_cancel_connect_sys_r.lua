--[[----------------------------------------------------------
    PreviewLinkLineCancelConnectSystem_Render 主动技预览阶段取消连线区域的显隐渲染system
]]------------------------------------------------------------
require("reactive_system")

---@class PreviewLinkLineCancelConnectSystem_Render:ReactiveSystem
_class("PreviewLinkLineCancelConnectSystem_Render", ReactiveSystem)
PreviewLinkLineCancelConnectSystem_Render = PreviewLinkLineCancelConnectSystem_Render

---@param world World
function PreviewLinkLineCancelConnectSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function PreviewLinkLineCancelConnectSystem_Render:GetTrigger(world)
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
function PreviewLinkLineCancelConnectSystem_Render:Filter(entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curMainStateID = utilDataSvc:GetCurMainStateID()

    if curMainStateID == GameStateID.Loading or curMainStateID == GameStateID.BattleEnter then
        return false
    end
    return true
end

function PreviewLinkLineCancelConnectSystem_Render:ExecuteEntities(entities)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()

    ---@type PreviewLinkLineService
    local linkLineService = self._world:GetService("PreviewLinkLine")

    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    for _, e in ipairs(entities) do
        ---@type PreviewLinkLineComponent
        local previewLinkLineCmpt = e:PreviewLinkLine()
        local chain_path = previewLinkLineCmpt:GetPreviewChainPath()

        if not chain_path or #chain_path == 1 then
            linkLineService:ShowChainPathCancelArea(false)
        elseif #chain_path >= 2 and not renderBoardCmpt:GetChainPathCancelAreaActive() then
            if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
                linkLineService:ShowChainPathCancelArea(true)

                --local guideService = self._world:GetService("Guide")
                --local guideTaskId = guideService:Trigger(GameEventType.ShowGuideCancelArea)
            end
        end
    end
end
