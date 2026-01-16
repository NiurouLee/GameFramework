--[[------------------------------------------------------------------------------------------
    逻辑组件
]] --------------------------------------------------------------------------------------------

require("enum_lookup")

LogicComponentsRegister =
    ComponentsLookup:New(
    {
        "LogicStartIndex",
        -----------------------
        "CommandReceiver",
        "CommandSender",
        "Attributes",
        "Board",
        "Buff",
        "Trap",
        "AI",
        "CrazyMode",
        "MonsterEscape",
        "SkillContext",
        "SkillHolder",
        "Phantom",
        "ActiveSkill",
        "FeatureSkill",
        "DimensionFlag",

        "ScopeCenter",
        "LogicChainPath",
        "LogicRoundTeam",
        "LogicPickUp",
        "LogicChessPath",
        
        "SkillPetAttackData",
        "AffixData",
        "CurseTower",
        "DamageStatistics",
        "LogicFeature",
        "SyncMoveWithTeam",
        "TeleportRecord",
        --
        "BoardMulti",
        "AuraRange",
        "LogicChainDamage",
        "ShareSkillResult",
        "Talent",
        "MoveScopeRecord",
        "EquipRefine",
        "BoardSplice",
        "PopStarLogic",
        --Count
        "TotalLogicComponents",
    }
)

LogicUniqueComponentsRegister =
    ComponentsLookup:New(
    {
        "LogicUniqueStartIndex",
        -----
        "GameFSM",
        "BattleStat",
        "BattleFlags",
        --Count
        "TotalLogicUniqueComponents"
    }
)
