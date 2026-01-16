--[[----------------------------------------------------------
    TimeSpeedSystemRender_Render 倍速按钮状态系统
]] ------------------------------------------------------------
---@class TimeSpeedSystemRender_Render:ReactiveSystem
_class("TimeSpeedSystemRender_Render", ReactiveSystem)
TimeSpeedSystemRender_Render = TimeSpeedSystemRender_Render

function TimeSpeedSystemRender_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function TimeSpeedSystemRender_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PreviewChainPath)
        },
        {
            "AddedOrRemoved"
        }
    )
    return c
end

function TimeSpeedSystemRender_Render:Filter(entity)
    if self._world:GetGameTurn() == GameTurnType.RemotePlayerTurn then
        return false
    end

    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    return not utilStatSvc:GetStatAutoFight()
end

function TimeSpeedSystemRender_Render:ExecuteEntities(entities)
    local e = self._world:Player():GetLocalTeamEntity()
    if not e then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
        return
    end

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    if not chainPath then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
        return
    end

    if #chainPath > 0 then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        ---@type GameStateID
        local curMainStateID = utilDataSvc:GetCurMainStateID()

        if curMainStateID == GameStateID.WaitInput then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, false, true)
        else
            GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, false)
        end
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    end
end
