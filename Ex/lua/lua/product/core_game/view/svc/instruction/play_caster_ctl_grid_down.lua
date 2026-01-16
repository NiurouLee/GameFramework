require("base_ins_r")
---@class PlayCasterControlGridDownInstruction: BaseInstruction
_class("PlayCasterControlGridDownInstruction", BaseInstruction)
PlayCasterControlGridDownInstruction = PlayCasterControlGridDownInstruction

function PlayCasterControlGridDownInstruction:Constructor(paramList)
    self._enable = tonumber(paramList["enable"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterControlGridDownInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local entity = casterEntity
    if casterEntity:HasSuperEntity() then
        local super = casterEntity:GetSuperEntity()
        if super then
            entity = super
        end
    end
    if entity:MonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = entity:MonsterID()
        monsterIDCmpt:SetNeedGridDownEnable(self._enable == 1)
    elseif entity:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRender = entity:TrapRender()
        trapRender:SetNeedGridDownEnable(self._enable == 1)
    end
    ---@type MainWorld
    local world = entity:GetOwnerWorld()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = entity:BodyArea()
    local areaArray = bodyAreaCmpt:GetArea()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local monsterGridPos = entity:GetRenderGridPosition()

    for i = 1, #areaArray do
        local curAreaPos = areaArray[i]
        local pos = Vector2(curAreaPos.x + monsterGridPos.x, curAreaPos.y + monsterGridPos.y)
        if self._enable == 1 then
            pieceSvc:SetPieceAnimDark(pos)
        else
            pieceSvc:SetPieceAnimNormal(pos)
        end
    end
end
