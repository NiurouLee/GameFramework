_staticClass("SystemFilter")

SystemFilter.LogicSystems = {
    CommandSendSystem = true,
    CommandReceiveSystem = true,
    --主状态机
    MainFSMSystem = true,
    GameFSMSystem = true,
    LoadingSystem = true,
    BattleEnterSystem = true,
    WaveEnterSystem = true,
    RoundEnterSystem = true,
    FirstWaveEnterSystem = true,
    WaitInputSystem = true,

    WaveResultSystem = true,
    WaveResultAwardSystem = true,
    WaveResultAwardApplySystem = true,
    RoleMovementSystem = true,
    RoleTurnResultStateSystem = true,
    PreChainStateSystem = true,
    ActiveSkillSystem = true,
    PersonaSkillSystem = true,
    MonsterBuffCalcSystem = true,
    RoundResultSystem = true,
    ChainAttackStateSystem = true,
    PieceRefreshSystem = true,
    MonsterMoveSystem = true,
    BattleResultSystem = true,
    WaveSwitchSystem = true,
    PieceEffectSystem = true,
    WaitInputChainSystem = true,
    BuffUnloadSystem = true,

    ChessPetMoveSystem = true,
    ChessPetAttackSystem = true,
    ChessPetMoveAndAttackSystem = true,
    ChessPetResultSystem = true,
    ---拾取类型主动技，这几个System现在还是逻辑，需要改成表现
    --SkillPickUpDirectionInstructionSystem_Render = true,
    --SkillPickUpInstructionSystem_Render = true,
    --SkillPickUpChainInstructionSystem_Render = true,
    ---自动战斗
    AutoFightSystem = true,
    -- Sys_TestRobot = true,

    ---幻境
    MirageEnterSystem = true,
    MirageWaitInputSystem = true,
    MirageRoleTurnSystem = true,
    MirageMonsterTurnSystem = true,
    MirageEndSystem = true,

    --region 消灭星星
    PopStarLoadingSystem = true,
    PopStarBattleEnterSystem = true,
    PopStarWaveEnterSystem = true,
    PopStarRoundEnterSystem = true,
    PopStarPieceRefreshSystem = true,
    PopStarTrapTurnSystem = true,
    PopStarRoundResultSystem = true,
    PopStarWaveResultSystem = true,
    PopStarBattleResultSystem = true,
    --endregion
}

function SystemFilter:CheckSystem(system_name, world_running_postion)
    if self.LogicSystems[system_name] and world_running_postion == WorldRunPostion.AtServer then
        return true
    elseif world_running_postion == WorldRunPostion.AtClient then
        return true
    else
        return false
    end
end
