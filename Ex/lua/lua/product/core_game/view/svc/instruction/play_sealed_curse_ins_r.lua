require("base_ins_r")

---@class PlaySealedCurseInstruction: BaseInstruction
_class("PlaySealedCurseInstruction", BaseInstruction)
PlaySealedCurseInstruction = PlaySealedCurseInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySealedCurseInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    -- 同一技能内不存在多重牵引
    ---@type SkillEffectResult_SealedCurse
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.SealedCurse)

    if not result then
        return
    end

    local oldLeaderPstID = result:GetOldLeaderPstID()
    local newLeaderPstID = result:GetNewLeaderPstID()

    if oldLeaderPstID and newLeaderPstID then
        ---@type RenderBattleService
        local battleRenderSvc = world:GetService("RenderBattle")
        battleRenderSvc:RenderChangeTeamLeader(newLeaderPstID, oldLeaderPstID)
        YIELD(TT, 1000)
    end

    local targetEntity = world:GetEntityByID(result:GetTargetID())
    ---@type BuffViewInstance
    local buffViewInst = targetEntity:BuffView():GetBuffViewInstance(result:GetBuffInsSeq())
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    playBuffService:PlayAddBuff(TT, buffViewInst, casterEntity:GetID())

    if not newLeaderPstID then
        return
    end

    ---@type ConfigService
    --local configService = world:GetService("Config")
    --local leftChangeTeamLeaderCount = configService:GetChangeTeamLeaderCount()

    local request = BattleTeamOrderViewRequest:New(
        result:GetOldTeamOrder(),
        result:GetNewTeamOrder(),
        BattleTeamOrderViewType.Exchange_ChangeTeamLeader
    )

    local ePet = world:GetEntityByID(result:GetTargetID())
    local eTeam = ePet:Pet():GetOwnerTeamEntity()
    local tOldTeamOrder = result:GetOldTeamOrder()
    local tNewTeamOrder = result:GetNewTeamOrder()
    ---@type PlayBuffService
    local playBuffSvc = world:GetService("PlayBuff")
    local ntTeamOrderChange = NTTeamOrderChange:New(eTeam, tOldTeamOrder, tNewTeamOrder)
    playBuffSvc:PlayBuffView(TT, ntTeamOrderChange)

    local renderBattleService = world:GetService("RenderBattle")
    renderBattleService:RequestUIChangeTeamOrderView(request)
end
