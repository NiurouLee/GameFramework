require("base_ins_r")
---@class PlaySuicideByResultInstruction: BaseInstruction
_class("PlaySuicideByResultInstruction", BaseInstruction)
PlaySuicideByResultInstruction = PlaySuicideByResultInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySuicideByResultInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillSuicideEffectResult[]
    local resultArray = routineComponent:GetEffectResultByArrayAll(SkillEffectType.Suicide)
    if not resultArray then
        return
    end

    ---@type MonsterShowRenderService
    local svc = world:GetService("MonsterShowRender")

    for _, result in ipairs(resultArray) do
        local targetID = result:GetTargetID()
        local e = world:GetEntityByID(targetID)
        if e then
            TaskManager:GetInstance():CoreGameStartTask(
                    function(TT)
                        svc:_DoOneMonsterDead(TT, e)
                    end
            )
        end
    end

    --道理上一次就行
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    pieceService:RefreshPieceAnim()
end
