require("logic_entity_id")
require("pet_info")
require("mission_info")
require("game_turn_type")

LogicEntityConfig = {
    ---network
    [EntityConfigIDConst.Network] = {
        EntityConfigID = EntityConfigIDConst.Network,
        EntityConfigName = "Network",
        EntityConfigComponents = {
            EntityType = {Type = "Network"},
            CommandReceiver = {DispatcherType = "PlayerCommandDispatcher"},
            CommandSender = {PreHandlerType = "PlayerCommandPreHandler"}
        }
    },
    --board
    [EntityConfigIDConst.Board] = {
        EntityConfigID = EntityConfigIDConst.Board,
        EntityConfigName = "Board",
        EntityConfigComponents = {
            EntityType = {Type = "Board"},
            Board = {},
            BoardMulti = {},
            BoardSplice = {},
            AIRecorder = {}, ---AI结果
            AffixData = {},
            LogicChessPath = {}, ---棋子关数据，棋子不好取，改到board上
            LogicFeature = {}, ---逻辑feature
            AuraRange = {}, ---光环范围组件
            Talent = {}, ---天赋
            Mirage = {}, ---幻境
            PopStarLogic = {}, ---消灭星星
            Attributes = {
                ---存放全局属性
                {AttributeName = "San", AttrModifyType = "MultModifyValue_Last", DefaultValue = -1}
            },
            ShareSkillResult = {},
        }
    },
    [EntityConfigIDConst.Team] = {
        EntityConfigID = EntityConfigIDConst.Team,
        EntityConfigName = "Team",
        EntityConfigComponents = {
            EntityType = {Type = "Team"},
            HP = {MaxHP = 1000, HPOffset = {0.0, 0.3, 0}},
            Team = {},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            Element = {},
            BodyArea = {{0, 0}},
            Attributes = {
                {AttributeName = "HP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "MaxHP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "Defense", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                ---防御百分比加成
                {AttributeName = "DefencePercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---防御固定加成值
                {AttributeName = "DefenceConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限百分比加成
                {AttributeName = "MaxHPPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限固定加成值
                {AttributeName = "MaxHPConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---回血加成系数
                {AttributeName = "AddBloodRate", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --最终收到伤害的增伤系数
                {AttributeName = "FinalBehitDamageParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --换队长次数 挪到队伍属性中 20220124
                {AttributeName = "ChangeTeamLeaderCount", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                ---额外属性克制系数--黑拳赛处理
                {AttributeName = "ExBeHitElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --受单体技能攻击时的增伤系数--黑拳赛敌方
                {AttributeName = "DmgParamSingleTypeSkill", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --调整进极光所需的格子数
                {AttributeName = "SuperChainCountAddValue", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
            },
            Buff = {},
            BuffView = {},
            EffectAttached = {},
            LogicPickUp = {}, ---存储表现层发过来的点选数据
            LogicRoundTeam = {}, ---存储逻辑层用于计算的出战队伍信息
            LogicChainPath = {}, ---存储表现发过来的连线数据
            ActiveSkill = {},
            FeatureSkill = {}
        }
    },
    --Pet
    [EntityConfigIDConst.Pet] = {
        EntityConfigID = EntityConfigIDConst.Pet,
        EntityConfigName = "Pet",
        EntityConfigComponents = {
            EntityType = {Type = "Pet"},
            Asset = {AssetType = "NativeUnityPrefabAsset", ResPath = ""},
            GridLocation = {Pos = {4, 2}, Dir = {0, 1}},
            Pet = {},
            PetRender = {},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            Element = {PrimaryType = ElementType.ElementType_Green},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.PlayerArea},
            MoveFSM = {FSMID = "1"},
            HP = {MaxHP = 1000, HPOffset = {0.0, 0.3, 0}},
            SkillInfo = {
                NormalSkillConfigID = 100001,
                SuperSkillConfigID = 10,
                ChainSkillConfigID = {
                    [1] = {Chain = 6, Skill = 200011}
                }
            },
            RenderAttributes = {},
            Attributes = {
                {AttributeName = "HP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "MaxHP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "Attack", AttrModifyType = "MultModifyValue_Last", DefaultValue = 100},
                {AttributeName = "Defense", AttrModifyType = "MultModifyValue_Last", DefaultValue = 50},
                {AttributeName = "LegendPower", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --传奇星灵能量
                {AttributeName = "Power", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "MaxPower", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "Ready", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                ---主副属性系数
                {AttributeName = "PrimarySecondaryParam", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1},
                ---攻击百分比加成
                {AttributeName = "AttackPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---攻击固定加成值
                {AttributeName = "AttackConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---防御百分比加成
                {AttributeName = "DefencePercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---防御固定加成值
                {AttributeName = "DefenceConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限百分比加成
                {AttributeName = "MaxHPPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限固定加成值
                {AttributeName = "MaxHPConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---普攻技能系数
                {AttributeName = "NormalSkillParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---连锁技技能系数
                {AttributeName = "ChainSkillParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---主动技技能系数
                {AttributeName = "ActiveSkillParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---普攻伤害倍率
                {AttributeName = "NormalSkillIncreaseParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---连锁技伤害倍率
                {AttributeName = "ChainSkillIncreaseParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---主动技伤害倍率
                {AttributeName = "ActiveSkillIncreaseParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---普攻技能系数
                {AttributeName = "NormalSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---连锁技技能系数
                {AttributeName = "ChainSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---主动技技能系数
                {AttributeName = "ActiveSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --- san值技能系数
                {AttributeName = "SanSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---额外属性克制系数
                {AttributeName = "ExElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                {AttributeName = "ExBeHitElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---回血加成系数
                {AttributeName = "AddBloodRate", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --伤害后处理
                {AttributeName = "AfterDamage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---连锁技释放条件补正
                {AttributeName = "ChainSkillReleaseFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---真实伤害修正百分比
                {AttributeName = "TrueDamageFixParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --最终收到伤害的增伤系数
                {AttributeName = "FinalBehitDamageParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --额外暴击率，仅在技能有暴击参数时生效
                {AttributeName = "AdditionalCritProb", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --额外暴击倍率，加到技能参数的crit上 N16词条用
                {AttributeName = "AdditionalCritParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --光灵的副属性伤害倍率
                {AttributeName = "SecondaryAttackParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = BattleConst.PetSecondaryParam},
                ---连锁技释放条件补正【百分比】 判定值 val = (连线chain + this.ChainSkillReleaseFix) * (1 + this.ChainSkillReleaseMul)
                {AttributeName = "ChainSkillReleaseMul", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
            },
            SkillPetAttackData = {},
            SkillRoutine = {},
            Buff = {},
            BuffView = {},
            PetPstID = {},
            SkillContext = {},
            MatchPet = {},
            EquipRefine = {},
        }
    },
    --Monster
    [EntityConfigIDConst.Monster] = {
        --20001
        EntityConfigID = EntityConfigIDConst.Monster,
        EntityConfigName = "Monster",
        EntityConfigComponents = {
            EntityType = {Type = "Monster"},
            BlockFlag = {},
            Alignment = {AlignmentType = AlignmentType.Monster},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            Asset = {AssetType = "NativeUnityPrefabAsset", ResPath = ""},
            GridLocation = {Offset = {0.5, 0.5}},
            BodyArea = {{0, 0}, {0, 1}, {1, 0}, {1, 1}},
            HP = {MaxHP = 1000, HPOffset = {0, 0.0, 0}},
            SkillInfo = {NormalSkillEntityID = 12},
            AttackArea = {Type = AttackAreaType.AIArea},
            Element = {PrimaryType = ElementType.ElementType_Blue},
            Attributes = {
                {AttributeName = "HP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "MaxHP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "Attack", AttrModifyType = "MultModifyValue_Last", DefaultValue = 50},
                {AttributeName = "Defense", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "Evade", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                --基础行动力
                {AttributeName = "Mobility", AttrModifyType = "MultModifyValue_Complex", DefaultValue = 0},
                --行动力上限
                {AttributeName = "MaxMobility", AttrModifyType = "MultModifyValue_Last", DefaultValue = 99},
                ---攻击百分比加成
                {AttributeName = "AttackPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---攻击固定加成值
                {AttributeName = "AttackConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---防御百分比加成
                {AttributeName = "DefencePercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---防御固定加成值
                {AttributeName = "DefenceConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限百分比加成
                {AttributeName = "MaxHPPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---血量上限固定加成值
                {AttributeName = "MaxHPConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---怪物技能系数
                {AttributeName = "MonsterSkillParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---怪物技能伤害倍率
                {AttributeName = "MonsterSkillIncreaseParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --最终伤害系数
                {AttributeName = "MonsterSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                ---额外属性克制系数
                {AttributeName = "ExElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                {AttributeName = "ExBeHitElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                {AttributeName = "DamagePercentAmpfily", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                ---回血加成系数
                {AttributeName = "AddBloodRate", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --最终收到伤害的增伤系数
                {AttributeName = "FinalBehitDamageParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --受到控制效果时额外增加的回合数
                {AttributeName = "ControlIncrease", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --普攻吸收系数
                {AttributeName = "AbsorbNormal", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --连锁吸收系数
                {AttributeName = "AbsorbChain", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --主动技吸收系数
                {AttributeName = "AbsorbActive", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
                --受到队长伤害的增伤系数
                {
                    AttributeName = "FinalBehitByTeamLeaderDamageParam",
                    AttrModifyType = "MultModifyValue_Add",
                    DefaultValue = 1
                },
                --受到队员伤害的增伤系数
                {
                    AttributeName = "FinalBehitByTeamMemberDamageParam",
                    AttrModifyType = "MultModifyValue_Add",
                    DefaultValue = 1
                },
                --受单体技能攻击时的增伤系数
                {AttributeName = "DmgParamSingleTypeSkill", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1},
                --反制AI 是否激活计算参数，默认1计算
                {AttributeName = "AntiSkillEnabled", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1},
                --反制AI 配置 光灵技能施放次数
                {AttributeName = "OriginalWaitActiveSkillCount", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                --反制AI 配置 每回合最大触发次数
                {AttributeName = "OriginalMaxAntiSkillCountPerRound", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                --反制AI 当前 光灵技能施放次数
                {AttributeName = "WaitActiveSkillCount", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                --反制AI 当前 每回合最大触发次数
                {AttributeName = "MaxAntiSkillCountPerRound", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                --反制AI 反制主动技类型列表
                {AttributeName = "AntiActiveSkillType", AttrModifyType = "MultModifyValue_Last", DefaultValue = {}}
            },
            SkillPetAttackData = {}, --临时用这个组件处理技能
            SkillRoutine = {},
            Buff = {},
            BuffView = {},
            MonsterID = {},
            MonsterRender = {},
            SkillContext = {},
            EffectHolder = {},
            MonsterAreaOutline = {},
            DropAsset = {}
        }
    },
    --星灵影子
    [EntityConfigIDConst.PetShadow] = {
        EntityConfigID = EntityConfigIDConst.PetShadow,
        EntityConfigName = "PetShadow",
        EntityConfigComponents = {
            EntityType = {Type = "PetShadow"},
            Asset = {AssetType = "NativeUnityPrefabAsset", ResPath = ""},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            GridLocation = {Pos = {4, 2}, Dir = {0, 1}},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.PlayerArea},
            SkillPetAttackData = {},
            SkillRoutine = {},
            SkillContext = {}
        }
    },
    --buff释放技能的实体
    [EntityConfigIDConst.SkillHolder] = {
        EntityConfigID = EntityConfigIDConst.SkillHolder,
        EntityConfigName = "SkillHolder",
        EntityConfigComponents = {
            EntityType = {Type = "SkillHolder"},
            GridLocation = {Pos = {4, 2}, Dir = {0, 1}},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.AIArea},
            SkillPetAttackData = {},
            SkillRoutine = {},
            SkillContext = {},
            Buff = {},
            BuffView = {}
        }
    },
    --Trap
    [EntityConfigIDConst.Trap] = {
        EntityConfigID = EntityConfigIDConst.Trap,
        EntityConfigName = "Trap",
        EntityConfigComponents = {
            EntityType = {Type = "Trap"},
            Asset = {AssetType = "NativeUnityPrefabAsset", ResPath = ""},
            Alignment = {AlignmentType = AlignmentType.Monster},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            GridLocation = {},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.AIArea},
            HP = {MaxHP = 1, HPOffset = {0.0, 0.7, 0}},
            Buff = {},
            BuffView = {},
            Trap = {},
            TrapID = {},
            Attributes = {
                --机关伤害计算依赖HP属性是否存在，应该增加一个配置标记机关是否可被攻击
                {AttributeName = "HP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1},
                {AttributeName = "MaxHP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1},
                {AttributeName = "TrapPower", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --当前能量
                {AttributeName = "TrapPowerMax", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --能量上限，UI上显示的
                {AttributeName = "OneRoundLimit", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1}, --一回合限制使用技能的次数
                {AttributeName = "CastSkillRound", AttrModifyType = "MultModifyValue_Last", DefaultValue = {}}, --放过技能的回合(如果第2回合放过3个技能，就是{2,2,2})
                {AttributeName = "SkillCount", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --剩余可以使用技能的次数，减到0则不可用
                {AttributeName = "SkillCountMax", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "ShowSkillCostPower", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --在技能界面显示技能消耗能量值
                {AttributeName = "CanBeAttacked", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --默认不能被攻击
                {AttributeName = "Mobility", AttrModifyType = "MultModifyValue_Complex", DefaultValue = 0}, --基础行动力
                {AttributeName = "MaxMobility", AttrModifyType = "MultModifyValue_Last", DefaultValue = 99}, --行动力上限
                {AttributeName = "Attack", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "AttackConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --攻击固定加成值
                {AttributeName = "AttackPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --攻击力百分比加成
                {AttributeName = "Defense", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0},
                {AttributeName = "DefenceConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --防御固定加成值
                {AttributeName = "DefencePercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --防御百分比加成
                {AttributeName = "MaxHPConstantFix", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --血量上限固定加成值
                {AttributeName = "MaxHPPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0}, --血量上限百分比加成
                {AttributeName = "TrapSkillIncreaseParam", AttrModifyType = "MultModifyValue_Mul", DefaultValue = 1},
                {AttributeName = "FinalBehitDamageParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1}, --最终收到伤害的增伤系数
                {AttributeName = "ChainSkillFinalParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 1}, ---连锁技技能系数（红与黑机关释放连锁技）
                {AttributeName = "TotalRound", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0}, --总合数
                {AttributeName = "CurrentRound", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1}, --当前回合数
                --{AttributeName = "ModelLevel", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1}, --等级（N22光灵-法官 石膏像机关）
                {AttributeName = "OpenState", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1}, --开关
                { AttributeName = "SummonTrapLimit", AttrModifyType = "MultModifyValue_Last", DefaultValue = 0 }, --默认为0，表示不限制召唤数量
                ---额外属性克制系数
                {AttributeName = "ExElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0 },
                {AttributeName = "ExBeHitElementParam", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0 },
            },
            RenderAttributes = {},
            SkillRoutine = {},
            SkillContext = {},
            EffectHolder = {},
            TrapRender = {},
            DropAsset = {}
        }
    },
    ---棋子光灵
    [EntityConfigIDConst.ChessPet] = {
        EntityConfigID = EntityConfigIDConst.ChessPet,
        EntityConfigName = "ChessPet",
        EntityConfigComponents = {
            EntityType = {Type = "ChessPet"},
            Asset = {AssetType = "NativeUnityPrefabAsset", ResPath = ""},
            GridLocation = {Pos = {4, 2}, Dir = {0, 1}},
            ChessPet = {},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            Element = {PrimaryType = ElementType.ElementType_Green},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.PlayerArea},
            HP = {MaxHP = 1000, HPOffset = {0.0, 0.3, 0}},
            RenderAttributes = {}, ---可能不需要
            Attributes = {
                {AttributeName = "HP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "MaxHP", AttrModifyType = "MultModifyValue_Last", DefaultValue = 1000},
                {AttributeName = "Attack", AttrModifyType = "MultModifyValue_Last", DefaultValue = 100}
            },
            SkillRoutine = {},
            Buff = {},
            BuffView = {},
            SkillContext = {},
            -- LogicChessPath = {}, ---存储表现发过来的连线数据 --改到board上
            ChessPetRender = {}
        }
    },
    --P5模块释放技能的实体
    [EntityConfigIDConst.PersonaSkillHolder] = {
        EntityConfigID = EntityConfigIDConst.PersonaSkillHolder,
        EntityConfigName = "PersonaSkillHolder",
        EntityConfigComponents = {
            EntityType = {Type = "PersonaSkillHolder"},
            GridLocation = {Pos = {4, 2}, Dir = {0, 1}},
            Alignment = {AlignmentType = AlignmentType.LocalPlayer},
            GameTurn = {gameTurnType = GameTurnType.LocalPlayerTurn},
            BodyArea = {{0, 0}},
            AttackArea = {Type = AttackAreaType.AIArea},
            SkillPetAttackData = {},
            SkillRoutine = {},
            SkillContext = {},
            Buff = {},
            BuffView = {},
            Attributes = {
                {AttributeName = "Attack", AttrModifyType = "MultModifyValue_Last", DefaultValue = 100},
                ---攻击百分比加成
                {AttributeName = "AttackPercentage", AttrModifyType = "MultModifyValue_Add", DefaultValue = 0},
            },
            Element = {PrimaryType = ElementType.ElementType_Green},
        }
    }
}
