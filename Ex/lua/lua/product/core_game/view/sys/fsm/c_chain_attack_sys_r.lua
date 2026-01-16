--[[------------------------------------------------------------------------------------------
    ClientChainAttackSystem_Render：客户端实现连锁技表现阶段
]] --------------------------------------------------------------------------------------------

require "chain_attack_state_system"

---@class ClientChainAttackSystem_Render:ChainAttackStateSystem
_class("ClientChainAttackSystem_Render", ChainAttackStateSystem)
ClientChainAttackSystem_Render = ClientChainAttackSystem_Render

function ClientChainAttackSystem_Render:_DoRenderBeforeCalcChain(TT)
    local ntBeforeCalcChainSkill = NTBeforeCalcChainSkill:New()
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntBeforeCalcChainSkill)
end

function ClientChainAttackSystem_Render:_DoRenderShowSuperChainSkill(TT)
    ---@type ChainAttackServiceRender
    local chainAttackServiceRender = self.world:GetService("ChainAttackRender")
    chainAttackServiceRender:_DoRenderShowSuperChainSkill(TT)
end

function ClientChainAttackSystem_Render:_DoRenderShowChainAttack(TT, teamEntity)
    ---@type ChainAttackServiceRender
    local chainAttackServiceRender = self.world:GetService("ChainAttackRender")
    chainAttackServiceRender:_DoRenderShowChainAttack(TT, teamEntity)

    ---@type PlaySkillService
    local playSkillSvc = self._world:GetService("PlaySkill")
    playSkillSvc:ShowPlayerEntity(teamEntity)

    TaskManager:GetInstance():CoreGameStartTask(
        function(TT)
            chainAttackServiceRender:_StopFocusEffect()
        end
    )

    playSkillSvc:_ClearCombo()
end

function ClientChainAttackSystem_Render:_DoRenderClearLastAttack()
    ---@type RenderBattleService
    local renderBattleSvc = self._world:GetService("RenderBattle")
    local comboNum = 0
    renderBattleSvc:SetComboNum(comboNum)
end

function ClientChainAttackSystem_Render:_DoRenderInWave(TT, traps, monsters)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    sMonsterShowRender:PlaySpawnInWave(TT, traps, monsters)
end

function ClientChainAttackSystem_Render:_DoRenderClearChainPath()
    local rBoardEntity = self._world:GetRenderBoardEntity()
    rBoardEntity:RenderChainPath():ClearRenderChainPath()

    ---@type PlaySkillService
    local playSkillSvc = self._world:GetService("PlaySkill")
    playSkillSvc:_ClearCombo()

    ---@type RenderBattleService
    local renderBattleSvc = self._world:GetService("RenderBattle")
    local comboNum = 0
    renderBattleSvc:SetComboNum(comboNum)
end

function ClientChainAttackSystem_Render:_DoRenderWaitPlaySkillTaskFinish(TT)
    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")
    local listWaitTask = playSkillService:GetWaitFreeList()
    self:_WaitTasksEnd(TT, listWaitTask)
end

function ClientChainAttackSystem_Render:_DoRenderPlayerBuffDelayed(TT, teamEntity)
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    playBuffService:PlayPlayerTurnStartBuff(TT, teamEntity, nil, true)
end

function ClientChainAttackSystem_Render:_DoRenderResetAuroraTimeState(TT)
    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()
    battleRenderCmpt:SetReEnterAuroraTimePlayed(false)
end