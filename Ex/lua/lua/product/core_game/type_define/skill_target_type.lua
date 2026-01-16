--[[------------------------------------------------------------------------------------------
    SkillTargetType : 技能目标类型
    注意不要和阵营混淆，是一个选敌时的辅助数据，表达的意义是单体目标选择策略
    SkillScopeCalculator计算出格子范围后，需要根据SkillTargetType来筛选技能目标
    比如最近的一只怪，SkillScopeCalculator算出来的是一个范围信息（全场格子），在选敌时
        从这个范围内先找出所有的怪，再挑出距离最近的那个。
    再比如，击退范围内的所有怪，这些怪在送给技能计算之前，需要首先按照距离进行排序，
        对所有目标是按照由远到近的顺序计算，这个排序是属于目标选择的职能，不属于技能效果计算
        因此这个目标排序功能也做为一种特殊的目标选择规则存在
    对目标带修饰词的，都会放在这里，比如最近的、最远的、血量最多的等
    目前的需求没必要把这些修饰词再提出来跟targetType做组合，直接枚举出来也就够了
]] --------------------------------------------------------------------------------------------

---@class SkillTargetType
SkillTargetType = {
    Monster = 1, --怪
    Pet = 2, --宝宝
    Self = 3, --自己
    AllMover = 4, --所有怪和宝宝
    Board = 5, ---以棋盘作为技能目标，一般转色的都是这个目标类型
    NearestMonster = 6, ---最近的一只怪
    PetAndTrap = 7, ---宝宝、机关
    Team = 8, ---队伍
    PetTeam = 9, ---宝宝全员
    MonsterTrap = 10, ---怪和机关
    AllMoverExcept = 11, ---所有怪和星灵，根据BuffEffect过滤
    PetMonsterTrap = 12, ---宝宝、怪、机关
    NearestPetMonsterTrap = 13, ---宝宝、怪、机关中最近的
    OneOfProtectTrapAndPet = 14, --守护机关和宝宝之一，如果有守护机关就不选宝宝，否则就选宝宝
    PetMonsterTrapExceptSelfFlyMultiBodyArea = 15, --宝宝、怪、机关（除自己、飞行怪、多格怪）
    TrapGridSplashPet = 16, --机关所在的格子  可以溅射到玩家
    OwnedPhantom = 17, --自己的幻象
    NearestMonsterTrap = 18, --怪和机关最近的
    TrapWithHP = 19, --带血机关
    SpecificMonster = 20, --特定的怪物，参数是一个数组
    MonsterGroup = 21, --同组的怪物，参数是否排除自己： 只能是怪物用
    PetAndTrapBomb = 22, ---玩家和可以击退的炸弹机关：跟7号的区别就是对机关做了“可以击退的炸弹”过滤
    HighestHPPercentMonster = 23, ---血量百分比最高的怪物
    SpecificPet = 24, -- 特定templateID的宝宝 统一需求中，SkillTargetType.Pet实际选中的是TeamLeader
    SpecificPrimaryElementPet = 25, -- 特定主属性宝宝
    HighestHPMonster = 26, ---真实血量最高的怪物
    LowestHPPercentMonster = 27, ---血量百分比最低的怪物
    LowestHPPercentMonsterParam = 28, ---血量百分比最低且低于参数指定值的怪物
    RandomNMonster = 29, ---随机N个怪，每个随出来的概率可配
    Captain = 30, --队长
    FarestMonster = 31, ---最远的一只怪
    Trap = 32, ---机关
    DeadMonsterWithBuff = 33, -- 死亡并且身上带有参数buff
    MonsterHaveBuffANoBuffB = 34, ---怪身上有buffA并且没有 Buff B
    NearestMonsterNoID = 35, ---离我最近的非指定类型的怪物
    NearestMonstersIsScope = 36, ---范围内最近的配置数量怪物
    SpecificTrap = 37, --特定的机关，参数是数组,只能怪物使用
    SpecificTrapAndFarthestHitBackPlayer = 38, --特定的机关，如果是多个那么选择其中能击退玩家最远的
    MonsterTrapDeadOrAlive = 39, -- 慎用！无论死活都被选中，雷文顿的一个特殊需求
    AntiAITriggerEntity = 40, --反制AI触发者
    MaxDamageDealerPetToCaster = 41, --对施法者造成伤害最高的宝宝，需配合对应Buff逻辑
    MonsterTrapAndTrapSuperEntityIsCaster = 42, ---怪和机关和施法者召唤的机关，  10的基础上添加施法者召唤的机关
    MonsterOrEnemyPets = 43, --怪物和敌方光灵
    NearestMonsterOneByOne = 44, ---最近的一只怪,初始从范围的中心点开始找，找下一个是从上一个选中的位置选，不选重复的
    LastActiveSkillCasterPet = 45, -- 最近一个放了主动技的光灵
    MonsterOnSpecificTrap = 46, --特定的机关上的怪物
    EntityWithBuff = 47, --具有某种buff的entity(怪或队伍) 爱洛拉专用
    CaptainInRange = 48, -- 30的添加范围判断的版本
    N15ChessMonsterMoveTarget = 49, --棋子的移动选取目标
    N15ChessMonsterAttackTargets = 50, --棋子的攻击选择目标,取决于参数
    NearestChessPet = 51, ---最近的一只棋子
    ChessPet = 52, --棋子
    MonsterAndChessPet = 53, --怪和棋子
    LessHPChessPet = 54, ---范围内血量最少的我方棋子
    MonsterOrTeam = 55, --有怪则选怪，没有则选队伍
    EntityWithBuffOrNearestMonster = 56, --先寻找有Buff的目标，没有就找距离最近的
    TrapSummonEntityIsCaster = 57, ---施法者召唤的机关
    NearestAndFarestMonsterInScope = 58, ---范围内最近的N个敌人和最远的N个敌人
    TrapPosByID = 59, ---特定机关，参数数组，与37不同的是它不做其他判断，任何单位都能用
    NearestMonsterSortByBodyArea = 60, ---范围内最近的N个敌人（优先按体型小到大排序）
    CasterSummoner = 61, ---施法者的召唤者（施法者是skillHolder则使用super作为施法者）
    MostVisibleBuffMonster = 62, ---可见buff数量最多的怪物
    NearestPetMonsterTrapAndFilter = 63, ---宝宝、怪、机关中最近的（13的基础上）做筛选
    MySpecificTrapOrAnyMonster = 64, ---范围内优先找指定id的机关，没有则找怪
    SelfInAttackRange = 65, --范围内的施法者本身，若不在范围内，则目标为空
    MonsterNotBoss = 66, ---范围内非Boss的怪物
    LastChainSkillRandomNMonster = 67, ---上一个连锁技的伤害结果中，随机N个怪，每个随出来的概率可配（29的连锁技版本）
    BuffLayerMostAndHighestHP = 68, --优先打指定buff层数最多并且血最高的人，要是有多个符合条件的就随机选一个
    MonsterAroundDamageTarget = 69, --一阶段伤害结果中目标周围一圈内的一个/所有怪物
    WorldBossMonster = 70, --世界boss
    SingleGridMonsterLowestHPPercent = 71, --范围内怪物中，血量百分比最低的单格怪物
    SelectMonsterCamp = 72, --选择指定阵营的怪物
    ----------------------------------------------------------------
    --新增基于阵营的目标选择方式
    AlignmentTargetEnemyTeam = 100, --敌方队伍
    AlignmentTargetFriendTeam = 101, --友方队伍
    AlignmentTargetFriendPet = 102, --友方光灵
    AlignmentTargetEnemyPet = 103, --敌方光灵
    AlignmentTargetEnemyTeamHaveBuffANoBuffB = 104,
    --敌方队伍有buffA没有buffB
    ----------------------------------------------------------------
    GridCanPurifyTrap = 105
}
_enum("SkillTargetType", SkillTargetType)

----------------------------------------------------------------
---@class EnumTargetEntity
EnumTargetEntity = {
    Monster = 1, --怪
    Pet = 2, --宝宝
    Trap = 4, --机关
    ChessPet = 5, --棋子
    All = 0xFF ---所有类型
}
_enum("EnumTargetEntity", EnumTargetEntity)
function EnumTargetEntity.IsEnumMatch(nCheckData, nMatchEnum)
    return nMatchEnum == nMatchEnum & nCheckData
end
----------------------------------------------------------------

--技能目标类型替换表
PvPSkillTargetTable = {
    [SkillTargetType.Monster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.MonsterTrap] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.NearestMonster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.FarestMonster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.HighestHPMonster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.LowestHPPercentMonster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.LowestHPPercentMonsterParam] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.MonsterTrapDeadOrAlive] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.NearestMonstersIsScope] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.RandomNMonster] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.MonsterHaveBuffANoBuffB] = SkillTargetType.AlignmentTargetEnemyTeamHaveBuffANoBuffB,
    [SkillTargetType.Pet] = SkillTargetType.AlignmentTargetFriendTeam,
    [SkillTargetType.Team] = SkillTargetType.AlignmentTargetFriendTeam,
    [SkillTargetType.PetTeam] = SkillTargetType.AlignmentTargetFriendPet,
    [SkillTargetType.MonsterOrEnemyPets] = SkillTargetType.AlignmentTargetEnemyPet,
    [SkillTargetType.NearestAndFarestMonsterInScope] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.NearestMonsterSortByBodyArea] = SkillTargetType.AlignmentTargetEnemyTeam,
    [SkillTargetType.MonsterNotBoss] = SkillTargetType.AlignmentTargetEnemyTeam,
}
