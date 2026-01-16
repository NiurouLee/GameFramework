require("base_ins_r")
---怪物逃脱 通知ui
---@class PlayEscapeAndUpdateUIInstruction: BaseInstruction
_class("PlayEscapeAndUpdateUIInstruction", BaseInstruction)
PlayEscapeAndUpdateUIInstruction = PlayEscapeAndUpdateUIInstruction

function PlayEscapeAndUpdateUIInstruction:Constructor(paramList)
    self._addNum = tonumber(paramList["addNum"]) or 1
    self._chessClassID = tonumber(paramList["chessClassID"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEscapeAndUpdateUIInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Escape[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Escape)
    if not resultArray then
        return
    end

    for _, v in ipairs(resultArray) do
        ---@type SkillEffectResult_Escape
        local result = v
        local targetID = result:GetTargetID()
        local targetEntity = world:GetEntityByID(targetID)
        if targetEntity then
            local disappear = result:GetDisappear()
            local addNum = result:GetAddNum()
            local posNew = result:GetPosNew()

            if disappear then
                targetEntity:SetLocation(posNew)
            end
            if addNum then
                world:EventDispatcher():Dispatch(GameEventType.UIUpdateChessEscape, 1)
                world:EventDispatcher():Dispatch(GameEventType.BattleUIRefreshCombinedWaveInfoOnRoundResult)
            end
        end
    end
end
