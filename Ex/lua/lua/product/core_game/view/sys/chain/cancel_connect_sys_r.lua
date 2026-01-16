--[[----------------------------------------------------------
    CancelConnectSystem_Render 取消连线
]] ------------------------------------------------------------
require("reactive_system")

---@class CancelConnectSystem_Render:ReactiveSystem
_class("CancelConnectSystem_Render", ReactiveSystem)
CancelConnectSystem_Render = CancelConnectSystem_Render

---@param world World
function CancelConnectSystem_Render:Constructor(world)
    self.world = world
end

---@param world World
function CancelConnectSystem_Render:GetTrigger(world)
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
function CancelConnectSystem_Render:Filter(entity)
    return true
end

function CancelConnectSystem_Render:ExecuteEntities(entities)
    ---@type Entity
    local renderBoardEntity = self.world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()

    ---@type LinkLineService
    local linkLineService = self.world:GetService("LinkLine")

    ---GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    for _, e in ipairs(entities) do
        ---@type PreviewChainPathComponent
        local previewChainPathCmpt = e:PreviewChainPath()
        local chain_path = previewChainPathCmpt:GetPreviewChainPath()

        if not chain_path or #chain_path == 1 then
            linkLineService:ShowChainPathCancelArea(false)
        elseif #chain_path >= 2 and not renderBoardCmpt:GetChainPathCancelAreaActive() then
            if self.world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
                linkLineService:ShowChainPathCancelArea(true)

                local guideService = self.world:GetService("Guide")
                local guideTaskId = guideService:Trigger(GameEventType.ShowGuideCancelArea)
            end
        end
    end
end
