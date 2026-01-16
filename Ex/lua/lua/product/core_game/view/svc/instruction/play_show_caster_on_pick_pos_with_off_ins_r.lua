--表现上将施法者移动到点选位置，带偏移（点选方向上离目标点的距离）
_class("PlayShowCasterOnPickPosWithOffInstruction", BaseInstruction)
---@class PlayShowCasterOnPickPosWithOffInstruction : BaseInstruction
PlayShowCasterOnPickPosWithOffInstruction = PlayShowCasterOnPickPosWithOffInstruction

function PlayShowCasterOnPickPosWithOffInstruction:Constructor(paramList)
    self._reset = tonumber(paramList.reset)
    self._disToPickPos = tonumber(paramList.disToPickPos)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayShowCasterOnPickPosWithOffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    if self._reset and (self._reset == 1) then
        local targetGridPos = casterEntity:GetGridPosition()
        casterEntity:SetPosition(targetGridPos)
    else
        ---@type RenderEntityService
        local entitySvc = world:GetService("RenderEntity")
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        if not renderPickUpComponent then
            return
        end
        local pickUpPos = renderPickUpComponent:GetLastPickUpGridPos()
        if self._disToPickPos and self._disToPickPos ~= 0 then
            local startGridPos = casterEntity:GetGridPosition()
            local dir = pickUpPos - startGridPos
            local v3Dir = boardServiceRender:GridDir2LocationDir(dir)
            v3Dir = Vector3.Normalize(v3Dir)
            local pickUpRenderPos = boardServiceRender:GridPos2RenderPos(pickUpPos)
            local targetPos = pickUpRenderPos + (v3Dir * self._disToPickPos)
            casterEntity:SetLocation(targetPos,v3Dir)
        else
            casterEntity:SetPosition(pickUpPos)
        end
    end
    YIELD(TT)
end
