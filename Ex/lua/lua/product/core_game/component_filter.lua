_staticClass("ComponentFilter")

ComponentFilter.LogicComponents = {
    ---基础组件
    PlayerComponent = true,
    GameFSMComponent = true,
    CommandSenderComponent = true,
    CommandReceiverComponent = true,
    BattleStatComponent = true,
    AttributesComponent = true,
    GridLocationComponent = true,
    AIComponentNew = true,
    BodyAreaComponent = true,
    LogicChainPathComponent = true,
    BoardComponent = true,
    SkillInfoComponent = true,
    BuffComponent = true,
    PetComponent = true,
    EntityTypeComponent = true,
    BlockFlagComponent = true,
    SkillPetAttackDataComponent = true,
    TeamComponent = true,
    TrapComponent = true,
    BossComponent = true,
    MonsterIDComponent = true,
    PetPstIDComponent = true,
    TrapIDComponent = true,
    ElementComponent = true,
    SkillRoutineComponent = true,
    ActiveSkillComponent = true,
    FeatureSkillComponent = true,
    LogicPickUpComponent = true,
    SuperEntityComponent = true,
    SummonerComponent = true,
    SkillContextComponent = true,
    ActiveSkillPickUpComponent = true,
    SkillHolderComponent = true,
    PhantomComponent = true,
    DeadMarkComponent = true,
    BattleFlagsComponent = true,
    AlignmentComponent = true,
    GameTurnComponent = true,
    SkinComponent = true,
    LogicChessPathComponent = true,
    LogicFeatureComponent = true,
    RideComponent = true,
    ---这几个逻辑组件应拆到表现层
    ScopeCenterComponent = true,
    PetDeadMarkComponent = true,
    AttackAreaComponent = true,
    DimensionFlagComponent = true,
    MatchPetComponent = true,
    SkillRoutineHolderComponent = true,
    LogicRoundTeamComponent = true,
    AIRecorderComponent = true,
    DropAssetComponent = true,
    AffixDataComponent = true,
    ChessPetComponent = true,
    SyncMoveWithTeamComponent = true,
    TeleportRecordComponent = true,
    LogicChainDamageComponent = true,
    ShareSkillResultComponent = true,
    --多面棋盘
    BoardMultiComponent = true,
    AuraRangeComponent = true,
    OutsideRegionComponent = true,
    BoardSpliceComponent = true,
    --伙伴
    LogicPartnerComponent = true,
    TalentComponent = true,
    MirageComponent = true,
    MoveScopeRecordComponent = true,

    ---装备精炼
    EquipRefineComponent = true,
    ---消灭星星
    PopStarLogicComponent = true,
}

---逻辑表现共享组件
ComponentFilter.ShareComponents = {}

function ComponentFilter:CheckComponent(component_name, world_running_postion)
    if self.LogicComponents[component_name] and world_running_postion == WorldRunPostion.AtServer then
        return true
    elseif world_running_postion == WorldRunPostion.AtClient or world_running_postion == WorldRunPostion.Cutscene then
        return true
    else
        return false
    end
end
