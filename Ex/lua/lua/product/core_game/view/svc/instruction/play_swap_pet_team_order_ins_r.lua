require("base_ins_r")

---@class PlaySwapPetTeamOrderInstruction: BaseInstruction
_class("PlaySwapPetTeamOrderInstruction", BaseInstruction)
PlaySwapPetTeamOrderInstruction = PlaySwapPetTeamOrderInstruction

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySwapPetTeamOrderInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    -- 同一技能内不存在多重牵引
    ---@type SkillEffectResult_SwapPetTeamOrder
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.SwapPetTeamOrder)

    if not result then
        return
    end

    local oldOrder = result:GetOldTeamOrder()
    local newOrder = result:GetNewTeamOrder()
    local oldLeaderPstID = oldOrder[1]
    local newLeaderPstID = newOrder[1]

    if oldLeaderPstID and newLeaderPstID and oldLeaderPstID ~= newLeaderPstID then
        ---@type RenderBattleService
        local battleRenderSvc = world:GetService("RenderBattle")
        battleRenderSvc:RenderChangeTeamLeader(newLeaderPstID, oldLeaderPstID)
    end

    ---@type ConfigService
    --local configService = world:GetService("Config")
    --local leftChangeTeamLeaderCount = configService:GetChangeTeamLeaderCount()

    local request = BattleTeamOrderViewRequest:New(
        result:GetOldTeamOrder(),
        result:GetNewTeamOrder(),
        BattleTeamOrderViewType.Exchange_SwapTeamOrder
    )

    local renderBattleService = world:GetService("RenderBattle")
    renderBattleService:RequestUIChangeTeamOrderView(request)

    local eTarget = world:GetEntityByID(result:GetTargetEntityID())
    local eTeam = eTarget:Pet():GetOwnerTeamEntity()

    ---@type PlayBuffService
    local playBuffSvc = world:GetService("PlayBuff")
    local ntTeamOrderChange = NTTeamOrderChange:New(eTeam, oldOrder, newOrder)
    playBuffSvc:PlayBuffView(TT, ntTeamOrderChange)
end
