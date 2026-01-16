require "command_base_handler"

_class("MiragePickUpCommandHandler", CommandBaseHandler)
---@class MiragePickUpCommandHandler: CommandBaseHandler
MiragePickUpCommandHandler = MiragePickUpCommandHandler

---@param cmd MiragePickUpCommand
function MiragePickUpCommandHandler:DoHandleCommand(cmd)
    Log.notice("Handle MiragePickUpCommand")

    local gridPos = cmd:GetPickUpGridPos()

    ---校验
    local isValid = self:CheckPickUpPosValid(gridPos)
    if not isValid then
        return
    end


    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type MirageComponent
    local mirageCmpt = boardEntity:Mirage()
    mirageCmpt:SetMovePos(gridPos)
    mirageCmpt:SetRoundCount(mirageCmpt:GetRoundCount() + 1)

    if self._world:RunAtClient() then
        local remainStep = mirageCmpt:GetRemainRoundCount()
        self._world:EventDispatcher():Dispatch(GameEventType.RefreshMirageStep, remainStep)
    end

    --切到下个状态
    self._world:EventDispatcher():Dispatch(GameEventType.MirageWaitInputFinish, 1)
end

function MiragePickUpCommandHandler:CheckPickUpPosValid(gridPos)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type MirageComponent
    local mirageCmpt = boardEntity:Mirage()
    if not mirageCmpt then
        return false
    end

    ---幻境是否开启
    if not mirageCmpt:IsMirageOpen() then
        Log.fatal("MiragePickUpCommand Invalid Mirage is close")
        return false
    end

    ---幻境回合是否结束
    if mirageCmpt:IsRoundOver() then
        Log.fatal("MiragePickUpCommand Invalid round is over")
        return false
    end

    ---点选位置的有效性
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local validGrids = utilData:GetRoundGrid(teamPos)
    local roundGridPosList = {}
    for _, grid in ipairs(validGrids) do
        local pos = Vector2(grid.x, grid.y)
        table.insert(roundGridPosList, pos)
    end
    if not table.icontains(roundGridPosList, gridPos) then
        Log.fatal("MiragePickUpCommand Invalid pos error, pick pos: ", Vector2.Pos2Index(gridPos),
            ", team pos: ", Vector2.Pos2Index(teamPos))
        return false
    end

    return true
end
