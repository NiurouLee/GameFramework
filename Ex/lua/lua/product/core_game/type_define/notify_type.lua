--触发时机
---@class NotifyType
local NotifyType = {
    None = 0, --无通知
    BuffLoad = 1, --buff挂载
    BuffUnload = 999, --buff卸载
    GameStart = 2, --开场
    MonsterTurnStart = 3, --怪物回合开始
    MonsterTurnEnd = 4, --怪物回合结束
    MonsterShow = 5, --怪物生成
    MonsterDead = 6, --怪物死亡
    PlayerShow = 7, --玩家生成
    PlayerHPChange = 8, --队伍或星灵的血量变化  --已用
    PlayerTurnStart = 9, --玩家回合开始
    PlayerTurnEnd = 10, --玩家回合结束
    PlayerPickDrop = 11, --拾取掉落
    PlayerSuperChain = 12, --超级连锁
    NormalEachAttackStart = 13, --玩家每次普攻攻击之前 --已用
    NormalEachAttackEnd = 14, --玩家每次普攻攻击之后 --已用
    MonsterEachAttackStart = 15, --怪物攻击前
    MonsterEachAttackEnd = 16, --怪物攻击命中目标后
    ChainSkillEachAttackStart = 17, --连锁技攻击一个目标之前 --已用
    ChainSkillEachAttackEnd = 18, --连锁技攻击一个目标之后 --已用
    ActiveSkillEachAttackStart = 19, --主动技攻击一个目标之前 --已用
    ActiveSkillEachAttackEnd = 20, --主动技攻击一个目标之后 --已用
    PlayerBeHit = 21, --玩家受击
    MonsterBeHit = 22, --怪物受击
    MonsterHPCChange = 23, --怪物血量变化
    NormalAttackStart = 25, ---玩家普攻攻击之前
    NormalAttackEnd = 26, ---玩家普攻攻击之后
    ChainSkillAttackStart = 27, --连锁技释放之前
    ChainSkillAttackEnd = 28, --连锁技释放之后
    ActiveSkillAttackStart = 29, --主动技释放之前
    ActiveSkillAttackEnd = 30, --主动技释放之后
    RoundTurnEnd = 31, ---回合结束 --已用
    WaveTurnEnd = 32, ---波次结束 --已用
    MonsterMoveOneFinish = 33, ---怪物移动完一个格子
    PlayerEachMoveStart = 35, --玩家移动每个格子开始
    PlayerEachMoveEnd = 36, ---玩家移动每个格子之后
    TrapSkillStart = 37, ---机关技能触发前 (和ai无关)
    TrapSkillEnd = 38, ---机关技能触发后
    MonsterEachDamageEnd = 39, --怪物每次造成伤害之后（无论普攻或其他技能）
    PlayerFirstMoveEnd = 40, ---玩家移动第一步结束
    HitBackEnd = 41, --击退结束
    MonsterSkillDamageStart = 42, --怪物技能结算前（非普攻）
    -- NormalAttackOnTarget = 43, --玩家普攻命中
    WaveTurnStart = 44, --波次刷完怪开始
    MonsterSkillDamageEnd = 45, --怪物技能结算后
    PlayerTurnStartLast = 47, --玩家回合开始的最后阶段，开始输入之前
    ActiveSkillDamageEnd = 48, --主动技造成伤害
    ChainSkillDamageEnd = 49, --联锁技造成伤害
    MonsterAttackOrSkillDamageEnd = 50, --怪物普攻或者技能伤害
    BreakHPLock = 51, ---锁血Buff破的时候
    PowerReady = 52, --能量满时
    CollectSouls = 53, --收集灵魂了(目前用于米亚主动技第一阶段杀人，只通知米亚)
    HPLock = 54, ---锁血生效的时候
    NotifyTriggerBuff = 56, --通知触发buff
    NotifyTrainFirstRowPos = 57, ---通知火车撞到的第一排坐标
    TrapEachAttackStart = 59, ---机关每格伤害前
    TrapEachAttackEnd = 60, ---机关每格伤害后
    EachAddBuffStart = 61, ---每个实体加buff前[技能]
    EachAddBuffEnd = 62, ---每个实体加buff后【技能】
    TrapHpChange = 63, --机关血量变化
    RandAttackBegin = 64, --灵魂冲击计算前
    RandAttackEnd = 65, --灵魂冲击计算后
    MonsterIsMoving = 66, ---怪物移动中
    TrapAction = 69, ---机关动作
    ChainSkillTurnStart = 70, ---所有人的连锁技准备开始前
    ChainSkillTurnEnd = 71, ---所有人的连锁技结束
    MonsterDeadStart = 72, --怪物死亡开始
    GridConvert = 73, --发生转色时
    Teleport = 74, --技能瞬移
    NormalAttackCalcEnd = 75, --单次普攻计算完毕
    EnterAuroraTime = 76, --进入极光时刻
    RefreshGridOnPetMoveDone = 77, --玩家移动后生成格子后
    ResetGridElement = 78, --重置格子技能效果通知
    GameOver = 80, --战斗结束（胜利/失败）
    ChainSkillAttack = 81, --连锁技能释放
    NotifyLayerChange = 82, --通知层数变化
    PetCreate = 83, --通知每个Pet的属性和阵营
    PetActiveSkillPreviousReady = 84, --宝宝主动技在回合开始前已就绪
    ReduceShieldLayer = 85, --删除护盾层数
    MonsterDeadEnd = 86, --怪物死亡结束
    ChainPathSelectTarget = 87, --连锁技选目标前
    WaitInput = 88, --waitInput
    SecondChainSkillAttackEnd = 89, --第二次连锁技结束 对应28
    BuffCastSkillEachAttackBegin = 91, --buff释放的技能
    BuffCastSkillEachAttackEnd = 92, --buff释放的技能
    EachPetChainSkillFinish = 93, --每一个星灵释放连锁技完毕（和87对应）
    NormalAttackCalcStart = 94,
    AttachMonster = 95, ---附身怪物
    TeamLeaderEachMoveStart = 96, --队长移动每个格子开始
    TeamLeaderEachMoveEnd = 97, ---队长移动每个格子之后
    ChangeTeamLeader = 98, ---替换队长
    AddBuffEnd = 99, --挂buff后
    RemoveBuffEnd = 100, --删buff后
    DimensionTransport = 101, --技能传送门
    AddMatchLog = 102, --生成一份战斗日志，用于白盒测试
    SecondChainSkillAttackStart = 103, --第二次连锁技释放前 对应27
    ActiveSkillAttackEndBeforeMonsterDead = 104, -- 30的复制版，区别是表现在清理尸体之前
    BeforeHighFrequencyDamageHit = 105, -- 高频攻击造成一次伤害前
    BeforeMazeTeamLeaderSucceed = 106, -- 秘境内队长继位前，时机是当前队长死亡后，下一个光灵成为队长前
    AfterHighFrequencyDamageHit = 107, -- 高频攻击造成一次伤害后
    PlayerTurnBuffAddRoundEnd = 108,
    WaveEnter = 109, --波次刷怪前  （44的前面）
    TractionEnd = 110, --牵引结束
    MonsterTurnAfterAddBuffRound = 111, --怪物回合开始，结算buff回合后。和3的区别是多等待了一个结算buff回合
    WaveSwitch = 112, --波次切换阶段
    WorldBossStageSwitch = 113, --世界Boss阶段切换
    ResetGridFlushTrap = 114, --洗板洗掉的机关
    ActiveSkillAntiAttack = 115, --主动技反制
    MonsterPostAntiAttack = 116, --怪物反制AI执行后
    ExitAuroraTime = 117, --极光时刻结束
    TrapDead = 118, --机关死亡通知
    TrapShow = 119, --机关出生通知
    EnemyTurnStart = 120, --敌方回合开始（用于黑拳赛）
    EnemyTurnEnd = 121, --敌方回合结束
    TrapDeadStart = 123, --机关死亡通知开始
    PlayerBeHitStart = 124, --玩家受击前
    MonsterBeHitStart = 125, --怪物受击前
    MonsterBuffDamageEnd = 126, --怪物受到buff伤害后
    NormalAttackChangeBefore = 127, --替换普攻之前
    TeamEachMoveEnd = 128, ---队伍每次移动结束
    TeamEachMoveStart = 129, ---队伍每次移动开始
    BeforeEntityAddBuff = 130, ---实体加buff前（计算免疫前）
    TeamOrderChange = 131, ---队伍顺序变化
    --TransportEachMoveStart = 131, ---传送带每次传送前
    TransportEachMoveEnd = 132, ---传送带每次传送结束
    EntityMoveEnd = 133, ---统一移动结束通知
    PlayerMoveStart = 134, ---玩家回合中划线结束或双击后
    PlayerTurnBuffAddRoundEndAfter = 1081, ---108，但在108触发之后，用来解决多个光灵用同一个通知时会出现的顺序冲突
    -- TrapActiveSkillStart = 135, ---机关主动技前
    TrapActiveSkillEnd = 136, ---机关主动技后
    ChessPetSkillAttackStart = 137, --棋子主动技释放之前
    ChessPetSkillAttackEnd = 138, --棋子主动技释放之后
    SanValueChange = 139, ---San值变化
    DayNightStateChange = 140, ---昼夜切换
    SyncMoveEachMoveEnd = 141, ---(机关)同步移动每个格子之后
    BeforeActiveSkillAttackStart = 142, ---主动技开始前，在29的前面
    RideStateChange = 143, --骑乘状态变化
    Effect156MoveOneGrid = 145, --技能效果156通过一个格子
    Effect156MoveFinish = 146, ---技能效果156移动结束
    SaveRoundBeginPlayerPosEnd = 147, --玩家回合开始-记录开始位置后-吞罗特殊需求
    NormalAttackCalcEndUseOriPos = 148, --单次普攻计算完毕 与75的区别是溅射攻击时beAttackPos是原被击位置
    SingleChainSkillAttackFinish = 149, --单次连锁技释放完成（包括本体、投影、代理）
    MinosAbsorbTrap = 150, --米诺斯吸收机关
    Effect156MoveFinishBegin = 151, ---技能效果156移动结束开始
    Effect156MoveFinishEnd = 152, ---技能效果156移动结束结束
    Effect156MoveOneGridBegin = 153, --技能效果156通过一个格子开始
    Effect156MoveOneGridEnd = 154, --技能效果156通过一个格子结束
    Effect158AttackBegin = 155, --技能效果158伤害计算开始
    Effect158AttackEnd = 156, --技能效果158伤害计算结束
    SuperGridTriggerEnd = 157, --强化格子触发技能结束
    PoorGridTriggerEnd = 158, --弱化格子触发技能结束
    SelectRoundTeamNormalBefore = 159, --选择普攻出战队列前，只有逻辑无表现
    FeatureSkillAttackEnd = 160, --模块技释放之后
    PetChainMoveBegin = 161, ---光灵连线移动开始
    PetMinosAbsorbTrap = 162, --光灵米诺斯吸收强化格子机关
    CoffinMusumeSkillChangeLight = 163, --棺材娘技能修改蜡烛状态
    CoffinMusumeLightChanged = 164, --棺材娘蜡烛状态修改后，用于触发防御计算
    ExChangeGridColor = 165, --86技能效果通知。
    ForceMovement = 166, --强制位移
    BuffCastSkillAttackEnd = 167, --buff释放的技能释放之后
    Pet1601781SkillHolder1 = 168, --N25维克小动物buff执行逻辑触发notify1
    Pet1601781SkillHolder2 = 169, --N25维克小动物buff执行逻辑触发notify1
    Pet1601781SkillHolder3 = 170, --N25维克小动物buff执行逻辑触发notify1
    --SelectRoundTeamNormalWithView = 171, --废弃
    BuffCastSkillAttackBegin = 172, --167对应，技能正式释放前
    SE189NormalEachAttackEnd = 173, --技能效果189的每次普攻攻击之后
    ChainSkillTurnStartSkipped = 174, ---所有人的连锁技准备开始前(但因为buff状态被跳过)
    Benumbed = 175, --单位被麻痹，MSG56006
    SnakeHeadMoved = 176, --贪吃蛇 头移动 --仲胥转色用
    SnakeTailMoved = 177, --贪吃蛇 尾部移动 --仲胥转色用
    MonsterTurnAfterDelayedAddBuffRound = 178, --MSG55703，延后处理怪物回合buff回合数之后的通知，延后的111
    CovCrystalPrism = 179, --转色水晶使用的棱镜格子通知
    ChessBeHit = 180, --棋子受击
    ChessDead = 181, --棋子死亡
    ChessHPChange = 182, --棋子血量变化
    EquipRefineUIStateChange = 183, --装备精炼UI开关状态改变
    AddControlBuffEnd = 184, --挂载控制类Buff后
    ActiveSkillCostCasterHPEnd = 185,--主动技能 对自己造成伤害后（技能效果85）
    SpliceBoardBegin = 186, --拼接棋盘分离前
    SpliceBoardEnd = 187, --拼接棋盘分离后
    TrapShowEnd = 188, --机关出生结束,在机关出生行为完成后发送
    PopStarScoreChange = 189, ---消灭星星分数变化通知
    TeamNormalAttackStart = 190, --队伍普攻开始,在队伍普攻行为开始前发送,
    PopStarEnd = 191, ---消灭星星消除格子结束
    MoveTrap = 192, --移动机关,仅支持通过11召唤机关触发的移动机关，不支持118
    ChangeTeamLeaderEnd = 194, --替换队长结束后，不要用本通知去套娃替换队长的操作。本通知要用来判断替换结束后的结果
    RoleTurnResultState = 195, --RoleTurnResultState
    MonsterRoundBeforeTrapRoundCount = 196,
    BuffLogicCastSkillCalcEffectEnd = 197, --buffLogicCastSkill 技能效果计算后 不区分施法者类型
    BeforeCalcChainSkill = 198,  --计算连锁技之前
    MAX = 9999 --
}
_enum("NotifyType", NotifyType)

PvPNotifyTypeTable = {
    [NotifyType.MonsterTurnStart] = NotifyType.EnemyTurnStart,
    [NotifyType.MonsterTurnEnd] = NotifyType.EnemyTurnEnd
}

--接口
_class("INotifyBase", Object)
---@class INotifyBase:Object
INotifyBase = INotifyBase
function INotifyBase:GetNotifyType()
    error("notify object not have notify type!")
end

---@return Entity
function INotifyBase:GetNotifyEntity()
end

function INotifyBase:NeedCheckGameTurn()
    return false
end

--本通知衍生的次级通知
function INotifyBase:GetSubordinateNotify()
end
