require("base_ins_r")
---面向到pick up选择的方向
---@class PlayTurnToPickUpDirectionInstruction: BaseInstruction
_class("PlayTurnToPickUpDirectionInstruction", BaseInstruction)
PlayTurnToPickUpDirectionInstruction = PlayTurnToPickUpDirectionInstruction

function PlayTurnToPickUpDirectionInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTurnToPickUpDirectionInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type Vector2
    local lastPickUpGridPos = nil
    ---@type RenderPickUpComponent
    local selectComponent = casterEntity:RenderPickUpComponent()
    if selectComponent ~= nil then
        lastPickUpGridPos =  selectComponent:GetLastPickUpGridPos()
    end
    if lastPickUpGridPos == nil  then
        return
    end
    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceRender  = world:GetService("BoardRender")
    local casterPos = boardServiceRender:GetRealEntityGridPos(casterEntity)
    local dir = lastPickUpGridPos - casterPos
	casterEntity:SetDirection(dir)
end
