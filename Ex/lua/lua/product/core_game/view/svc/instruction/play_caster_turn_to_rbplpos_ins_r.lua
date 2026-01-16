require("base_ins_r")

_class("PlayCasterTurnToRoundBeginPlayerPosInstruction", BaseInstruction)
---@class PlayCasterTurnToRoundBeginPlayerPosInstruction: BaseInstruction
PlayCasterTurnToRoundBeginPlayerPosInstruction = PlayCasterTurnToRoundBeginPlayerPosInstruction

function PlayCasterTurnToRoundBeginPlayerPosInstruction:Constructor(paramList)

end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterTurnToRoundBeginPlayerPosInstruction:DoInstruction(TT,casterEntity,phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local targetPos = BattleStatHelper.GetRoundBeginPlayerPos()

    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    if not playSkillService:CheckSourceCanTurn(casterEntity) then
        Log.fatal("CasterID:",casterEntity:GetID(),"can't turn ")
        return
    end

    if casterEntity:HasTeam() then
        casterEntity = casterEntity:GetTeamLeaderPetEntity()
    end

    ---@type Vector3
    local castPos = casterEntity:GetRenderGridPosition()

    local dir = targetPos - castPos
    local gridDir = Vector2(dir.x, dir.y)
    --source_entity:SetGridDirection(gridDir)
    casterEntity:SetDirection(gridDir)
end