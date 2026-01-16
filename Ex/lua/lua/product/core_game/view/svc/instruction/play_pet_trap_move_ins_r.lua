require("base_ins_r")

---@class PlayPetTrapMoveInstruction: BaseInstruction
_class("PlayPetTrapMoveInstruction", BaseInstruction)
PlayPetTrapMoveInstruction = PlayPetTrapMoveInstruction

function PlayPetTrapMoveInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPetTrapMoveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultPetTrapMove[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PetTrapMove)

    if not resultArray or table.count(resultArray) == 0 then
        return
    end

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")

    for _, result in ipairs(resultArray) do
        local posOld = result:GetPosOld()
        local posNew = result:GetPosNew()
        local dirNew = result:GetDirNew()

        --离开旧位置显示机关
        -- trapServiceRender:ShowHideTrapAtPos(posOld, true)
        casterEntity:SetAnimatorControllerBools({Move = true})
        casterEntity:AddGridMove(BattleConst.MoveSpeed, posNew, posOld)

        casterEntity:SetDirection(dirNew)

        while casterEntity:HasGridMove() do
            YIELD(TT)
        end

        casterEntity:SetAnimatorControllerBools({Move = false})
        casterEntity:SetLocation(posNew, dirNew)
        -- trapServiceRender:ShowHideTrapAtPos(posNew, false)

        ---触发机关的表现
        local trapIDList = result:GetTriggerTrapIDList()
        local trapEntityList = {}
        for _, trapID in ipairs(trapIDList) do
            local trapEntity = world:GetEntityByID(trapID)
            trapEntityList[#trapEntityList + 1] = trapEntity
        end

        sPlaySkillInstruction:PlayTrapTrigger(TT, casterEntity, trapEntityList)

        playBuffService:PlayBuffView(TT, NTTeleport:New(casterEntity, posOld, posNew))
    end
end
