require("base_ins_r")
---@class PlayCasterSuicideInstruction: BaseInstruction
_class("PlayCasterSuicideInstruction", BaseInstruction)
PlayCasterSuicideInstruction = PlayCasterSuicideInstruction

function PlayCasterSuicideInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterSuicideInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    if casterEntity:HasMonsterID() and casterEntity:HasDeadMark() then
        ---@type MonsterShowRenderService
        local svc = world:GetService("MonsterShowRender")
        TaskManager:GetInstance():CoreGameStartTask(
            function(TT)
                svc:_DoOneMonsterDead(TT, casterEntity)
            end
        )

        ---@type PieceServiceRender
        local pieceService = world:GetService("Piece")
        pieceService:RefreshPieceAnim()
    end
end
