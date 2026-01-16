require "play_skill_phase_base_r"

---@class PlaySkillInstructionPhase: PlaySkillPhaseBase
_class("PlaySkillInstructionPhase", PlaySkillPhaseBase)
PlaySkillInstructionPhase = PlaySkillInstructionPhase

--指令类型的表现段，需要执行phase param里的指令集合
---@param casterEntity Entity
function PlaySkillInstructionPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillPhaseContext
    local phaseContext = SkillPhaseContext:New(world,casterEntity)
    ---@type SkillPhaseInstructionParam
    local instructionParam = phaseParam
    local insArray = instructionParam:GetInstructionSet()
    local insIndex = 1
    local insSetCount = table.count(insArray)
    while insIndex > 0 and insIndex <= insSetCount do 
        ---@type BaseInstruction
        local instruction = insArray[insIndex]
        Log.debug("play skill instruction start:",instruction._className,' cast=',casterEntity:GetID())
        local nextInsLabel = instruction:DoInstruction(TT,casterEntity,phaseContext)
        --Log.debug("play skill instruction finish:",instruction._className)
        if nextInsLabel then 
            insIndex = self:_CalcNextLabel(insArray,nextInsLabel)
        else
            insIndex = insIndex + 1
        end
    end
    local phaseTaskList = phaseContext:GetPhaseTaskList()
    while not TaskHelper:GetInstance():IsAllTaskFinished(phaseTaskList) do
        YIELD(TT)
    end
end

function PlaySkillInstructionPhase:PrepareToPlay(TT, casterEntity, phaseParam)
    local insArray = phaseParam:GetInstructionSet()
    for i = 1, #insArray do
        local instruction = insArray[i]
        if instruction.Prepare then
            instruction:Prepare(TT,casterEntity)
        end
    end
end

--[[ 暂时不需要 如果需要可以打开
function PlaySkillInstructionPhase:BeginPlay(TT, casterEntity, firstPhaseParam)
    PlaySkillInstructionPhase.super.BeginPlay(self, TT, casterEntity, firstPhaseParam)

    local insArray = firstPhaseParam:GetInstructionSet()
    for i = 1, #insArray do
        local instruction = insArray[i]
        if instruction.BeginInstruction then
            instruction:BeginInstruction(TT,casterEntity)
        end
    end
end

function PlaySkillInstructionPhase:EndPlay(TT, casterEntity, phaseParam)
    local insArray = phaseParam:GetInstructionSet()
    for i = 1, #insArray do
        local instruction = insArray[i]
        if instruction.EndInstruction then
            instruction:EndInstruction(TT,casterEntity)
        end
    end
end
]]

---insArray指令队列
---计算label指定的下一条指令
---phase结束，返回-1
function PlaySkillInstructionPhase:_CalcNextLabel(insArray,nextInsLabel)
    --Log.fatal("nextInsLabel:>>>>>>>>>>>>>>>>>>>>>>>>",nextInsLabel)
    if nextInsLabel == InstructionConst.PhaseEnd then 
        return -1
    else
        ---查找下一个phaseindex
        for k,v in ipairs(insArray) do 
            ---@type BaseInstruction
            local ins = v
            local insLabel = ins:GetInstructionLabel()
            if insLabel ~= nil and insLabel == nextInsLabel then 
                return k
            end
        end
    end

    Log.fatal("instruction label not match:",nextInsLabel)
    return -1
end