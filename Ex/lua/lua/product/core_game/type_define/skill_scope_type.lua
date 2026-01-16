---@class SkillScopeType
SkillScopeType = {
    SkillScopeTypeStart = 0,
    None = 0,
    Cross = 1, --十字
    NRowsMColumns = 2, --N排M列
    DoubleCross = 3, --米字型
    FullScreen = 4, --全屏
    SquareRing = 5, --方形环
    XScopeType = 6, --X型
    Rhombus = 7, --12格菱形
    Square = 8, --方形
    Team = 9, --队伍脚下
    AroundBodyArea = 10, --环绕BodyArea的格子【可包括BodyArea】
    Nearest = 11, --距离最近的
    FixedPos = 12, --固定位置
    SuperCross = 13, --周围8格及十字最大范围
    NearestGrid = 14, --距离最近的某几种颜色的格子
    DirectLine = 15, --朝向的直线方向
    WidthCrossWithPickUp = 16, --带宽度和方向选择的十字,以施法者为中心点只支持奇数宽度
    EmptyRandGrid = 17, --场景内任意可站立区域随机N个格子
    NRowsMColumnsSpreadAlongRow = 18, --N排M列从中心按行展开*有方向*
    CrossExceptBlock = 19, --受阻挡物阻挡的十字范围
    OneColumeWithBlock = 20, --一整列，沿中心展开，可被阻挡
    DoubleCrossBeBlocked = 21, --可被阻挡的米字
    DirectLineBlocked = 22, --朝向的直线方向，阻挡技能BlockFlag.Skill
    DirectLineExpand = 23, --朝向的直线方向（长宽可配）
    FixedArea = 24, --固定范围 只有一个参数表示具体范围含义 1:麦格芬横扫范围 2:麦格芬落地击退范围
    MultiCenterCross = 25, -- 多中心点的十字范围 暂时只有樱龙使使用
    RandomRectAndCount = 26, --全屏中有效的格子范围中随机次数一个范围
    MultiCenterSquare = 27, ---多中心点的方形范围
    NRowMColSpread = 28, --N行M列从中心展开【支持左右/上下铺开】
    RandomGrids = 29, --从给定的N组格子中随机出N个格子
    UnderFoot = 31, --脚下，即BodyArea
    AllMonster = 32, --全屏所有怪
    TrainAttackScope = 33, --施法者->点选方向（仅四方向）的x行y列范围 原始注释：火车的攻击范围,由点选方向决定
    TrainConvertScope = 34, --火车的转色范围,由点选方向决定
    CenterPos = 35, --范围就是点选的坐标
    CanMovePos = 36, --全屏可行走范围
    TrapEddyPair = 37, ---传送漩涡出口
    CasterCross = 38, ---施法者周边的四格子,不判断是否是合法格
    PickUpDoubleCross = 39, ---点选用米字型,实际范围由点选决定
    HeroLastAttackMonster = 40, ---队长上次攻击的怪
    CanMoveSquareRing = 41, -- 与SquareRing类似，只是会额外剔除不可行走的格子
    AllMonsterGrid = 42, --所有怪物脚下格子
    MonsterWithBuffType = 43, --所有带某类buff的敌人
    AroundBodyAmplifyCross = 44, --扩大BodyArea的格子  交叉
    FaceFrontRange = 45, ---面前的N行M列，以自己基准位置为中心对其
    AngleFreeLine = 46, -- 万向直线，根据通用公式计算[施法者]至[点选位置]的路线和宽度，带路径上周边的格子
    SelectPieceByType = 47, -- 选取全屏特定颜色的格子
    MultiRandomRange = 48, --在距离自己的一定范围内 随机多个范围（鸣灼）
    SelectFarthestFormPlayer = 49, --从指定怪物的身形下的坐标中，选择距离玩家最远的,如果距离相等，顺时针选择（映镜）
    AllTrapGrid = 50, --所有机关占据格子，用来限制点选
    SelectPosDistanceFormPlayer = 51, --从几个点中，选择距离玩家最近或者最远的点
    PickGridColor = 52, --所有点选的颜色格子坐标
    PlayerToCasterDirection = 53, --玩家坐标向施法者坐标的方向 向前
    NearestInSquareRing = 54, --M圈内N个目标
    PickUpDoubleCrossBlocked = 55, ---可阻挡的 点选用米字型,实际范围由点选决定（39的阻挡版）
    XScopeTypeAndGridPiece = 56, --X型范围内指定颜色的格子（契法连锁）
    PickUpRect = 57, --根据点选的点和施法者坐标的矩形范围(初步只支持单点)(渡 主动技)
    WalkableGridOnEdge = 58,
    CasterToPickUpAndRightAngleDiffusion = 59, --从施法者到点选坐标，然后从点选坐标选择与施法者成直角的2个方向扩散（泷 主动技）
    XingshanStep = 60,
    ForwardPyramid = 61,
    RandomGridsAndTypeSize = 62, --29的范围基础上加上 范围的类型和范围尺寸
    DoubleCrossMoveBlock = 63, --米字型被移动阻挡。和常规阻挡最大不同是，以前阻挡技能，这个是阻挡移动。（象棋后）   21的移动阻挡类型
    ChessKnight = 64,
    XScopeMoveAndCrossAttack = 65, --X型范围内瞬移(需要判断移动阻挡)到最远的可以正对玩家行/列 ，然后十字攻击范围(需要判断技能阻挡)。（象棋象）
    CrossRowColMoveBlock = 66, --受移动阻挡的十字范围，或正对玩家行列。用于瞬移结果，返回一个点。1找距离玩家最近的点，2找可以正对玩家行列的点，3距离玩家最近的点（象棋车）
    DoubleNRowMColSpread = 67, --计算2次的N行M列从中心展开【支持左右/上下铺开】。28的范围算了2次。用于行列不同的宽度。
    FrontAndObliqueOffset = 68, --固定向自己面前移动。若前方阻挡移动，则斜向一格移动，有固定顺序的偏移。(象棋兵)
    SpecifyRowsColumns = 69, --指定的行列的坐标。
    SchummerActiveTower = 70, -- 选中激活塔所属范围，角色专属，关卡定制
    SelectPieceByTrapType = 71, -- 根据机关类型选格子
    SquareRingRemoveAngle = 72, --方形环去掉角
    AroundBodyAndNearestPlayer = 73, ---钻地怪使用,从4方向距离自己{参数}距离的格子中选择一个离玩家最近的无阻挡格子，如果都有阻挡那么原地
    TrapCenterWithScope = 74, ---指定机关作为技能中心，然后二次计算范围
    PickUpFrontExtendWithDamage = 75, ---选取的第一个点为中心，选取第二个点作为方向，直线到版边。中间如果遇到怪物并造成伤害（MISS不算），根据规则做扩展范围（普律玛主动技）
    DoubleCrossMoveBlockHitBackFarthest = 76, ---带阻挡米字型中贴近玩家的最远击退位置
    DoubleCrossLinkLine = 77, ---从施法者到目标做米字型连线
    PickUpCross = 78, ---点选坐标的十字范围,实际范围由点选决定
    DoubleCrossWithCenter = 79, --如题的范围，单独拿出来是因为旧范围参数都不是数组型的，打包当天不敢加
    DirectLineBlockedEdgeFree = 80,
    FriendTeamGrid = 81, --黑拳赛模式下友方队伍脚下格子
    EnemyTeamGrid = 82, --黑拳赛模式敌方队伍脚下格子
    FourValidPointDistanceCaster = 83, --钻地怪预览箭头使用，距离施法者四个方向两格的坐标
    FarthestBoardRowOrColumn = 84, --从距离玩家最远的版边选择的行列
    AllMonsterAroundBodyNearest = 85, --所有怪物周围格子距离施法者最近的，先从周围格子的十字里找，找不到再从米字里找
    TowScopeCollection = 86, --两个范围的合集
    PickUpRotateReflect = 87, --点选一个位置旋转反射面
    CasterToPlayerRange = 88, ---自己与玩家间的行/列，可以配置宽度，配置如果范围范围内没有有效格子，在外面寻找
    BoardNineAreas = 89, --将棋盘切成九个区域
    CanConvertElementRange = 90, ---全屏可转色区域
    SelectPosByPlayerPos1 = 91, --祭剑座特殊技能瞬移使用,根据玩家位置选择一个瞬移位置
    NearestOneByOne = 92, --最近的怪，然后从已经选择的最后这个目标找距离它最近的。
    ExpectedPlayerInArea = 93, --祭剑座特殊技能删除机关的范围，是全屏除了玩家所在区域
    TwoScopeDifference = 94, --两个范围的差值，第一个减第二个
    PickUpCrossAndDirToSector = 95, --十字方向上选择第一个点，然后选择两侧方向，根据技能角度参数行成扇形（艾露玛 主动技）
    TargetUnderFootColorGrid = 96, --从点选的怪物脚下，就近选出N个某几种颜色的格子
    TargetUnderFoot = 97, --点选的怪物脚下所有格子
    ScopeByPickNum = 98, --没有点击格子时，返回参数[1]配置的范围，点第N个点后，返回范围参数[N+1]配置的范围
    RectInDoublePick = 99, --两个点选格子之间的矩形
    SelectDirectionAndExtendWithTrap = 100, --选择一个方向，遇到特殊的机关可以扩展范围，排重。
    NRowMColSpreadAndLimit = 101, --N行M列从中心展开【支持左右/上下铺开】计算后，添加限制范围，去掉范围外的坐标
    BowlingerSummonArea = 102, --危机合约鲍林格-分区召唤范围
    RectExceptFixPosAndTrap = 103, --矩形范围，去除规则：1、去除固定点；2、去除特定机关米字型范围（若去除后无点，则不执行2）
    ScopeByPickDirType = 104, --根据点选的方向类型使用不同的范围
    PosOffsetXAndYEqualN = 105, --相对中心点的坐标偏移X+Y=N的一圈格子
    RhombusRemoveAngle = 106, --菱形去掉角
    NearestPlayerAroundBody = 107, --玩家周围8个点中没有阻挡的，距离施法者/centerpos最近的点
    LimitRingNearestToSelectPos = 108, --限制圈数距离指定点最近的点
    TwoScopeProgressive = 109, --两个范围递进，使用第一个技能范围的结果作为centerPos，去计算第二个范围
    BoardSummonSixAreas = 110, --棋盘上特定的六块区域 鬼王boss召唤技能范围
    OneScopeRangeNearestPlayer = 111, --在一个范围结果中距离玩家最近的点
    RelativeFixedPos = 112, -- 以自身为中心的相对固定位置构成的范围
    TwoScopeIntersection = 113, --两个范围的交集
    XScopeTypeExceptBlock = 114, --X型 考虑阻挡
    RandomPosEmptyOrTrap = 115, --随机一个位置；优先空格子，其次是非阻挡的机关格子（除召唤的机关ID）
    AllChessPet = 116, --战棋模式下的全部棋子
    FaceFrontLineBlocked = 117, --朝向的直线方向，阻挡技能BlockFlag.Skill(棋子关钩子怪)
    SelectPieceByTrapID = 118, --指定id的机关脚下
    N16NightKingSkill1A = 119, --夜王技能1的A范围,等同于爪击范围
    N16NightKingSkill1B = 120, --夜王技能1用来判断，是否能释放前扑的范围
    N16NightKingSkill1C = 121, --夜王技能1用来判断，是否能释放甩尾的范围
    SquareRingOn2BodyArea = 122, --支持两格BodyArea的方形环
    N16NightKingForwardSkillPre = 123, --夜王技能1前扑用来预览的范围，两格点
    N16NightKingForwardSkill = 124, --夜王技能1实际前扑用来显示的范围，两格点
    MonsterBuffTypeSelect = 125, --选择带或者不带所有带某类buff的敌人
    CrossABackBNearCaster = 126, --返回两个点：A点是目标十字格中之一，B点是A后撤N个格；选取规则：合法格子且距离施法者最近
    FullscreenExceptSafeZone = 127, --全屏除配置安全区（另一个范围）外的所有格子
    BoardSummonNineAreas = 128, --棋盘上特定的九块区域 世界boss克娜莉召唤技能范围,世界Boss特化版本
    TrapCenterWithScopeCanRepeat = 129, ---指定机关作为技能中心，然后二次计算范围,不去掉重复格子版本
    CrossOnTeleportedDirection = 130, ---根据本回合自己的瞬移记录确定选取十字的哪些格子，SP卡莲-主动技-点选无效范围
    TeleportTargetPosFrontAndBack = 131, ---当前计算出来的瞬移结果位置的前1格与后1格，SP卡莲-主动技-转色，只能用于子范围，且在瞬移逻辑之后
    SquareRingRemove3Angle = 132, --鬼王范围，三圈去掉三个角
    CrossEdges = 133, ---鬼王使用的，召唤机关刀的最终位置
    Trap2CasterCenterLine = 134, --鬼王使用的从刀到施法者的攻击路径
    BoardEdgeDirectLineBlock = 135, --棋盘上以某一边为起点往对面逐渐计算范围，计算阻挡
    PickupPosFrontAndBack = 136, --131的类似版本，用于预览使用
    QierMonsterRoundRandom = 137, --对(该技能内)(已经造成伤害的每个怪物)周围【几圈，仍然是方形环】随机n个格子
    TrapCenterWithScopeRepeatScope = 138, ---指定机关作为技能中心，然后二次计算范围,获取重复格子数量大于配置值的格子作为范围
    SquareRingExtendByGridType = 139, --固定周围八格，然后每个判断周围4/8方向格子是否是配置颜色，颜色相同就放进去
    ColOrRowByPickUp = 140, ---由第一个中心点确定位置，第二个中心点确认方向，一行或者一列
    CrossReboundOnBlock = 141, --卡斯特觉醒连锁技范围，@seealso: //depot_matchsrpg/mr/项目管理/策划/宝宝技能需求/n22/N22角色开发需求.xlsx
    TShapeByPosCenterAndDir = 142, --施法者逻辑中心位置前的T型四格（N22机械信使Boss主动技2）
    FanShapeByPosCenterOffsetAndDir = 143, --施法者逻辑中心配置偏移点前的扇形区域，宽度按长度每增三格加两格（N22机械信使Boss主动技3——左右肩炮）
    BuffValueRecordedPos = 144, --buff value里记录的坐标（法官连线移动中召唤机关）
    PickupAngleFreeLine = 145, --47的需求类似版本，区别是47计算的起点一定是施法者位置，145由配置决定到底用哪两个点选连线
    FirstCenterPos = 146, ---区别于35，配合技能中心4使用，只取点选的第一个格子
    AroundRandNoBlockNoChainPath = 147, ---周围随机一个没有阻挡、不在连线路径上的点 （光灵米洛斯 幻影位置）
    TrapsCenterWithScope = 148, ---74号范围的多机关版本
    TrapsCenterWithScopeByCenterPos = 149, --计算机关的融合范围，选择中心点所在的范围。
    CasterAcrossTeam = 150, --施法者穿过队伍的位置
    MonsterLineCantAcross = 151, --怪物间的连线，不能留下连线穿过的位置
    CustomizableAllMonsterGrid = 152, --42的可加参数版本。42因各种历史原因，修改时的负担太大
    AkexiyaPickupValidRange = 153, --阿克希亚主动技点选专属范围，过于复杂请直接看需求
    Monster2903501FindPlayerType = 154, ---癫蹄用来查找玩家的范围
    SelectPieceTypeAndExclude = 155, -- 选取全屏特定颜色的格子并排除一些特定格子
    UseMoveScopeRecord = 156, -- 使用MoveScopeRecord组件记录的范围作为技能范围
    ZhongxuForceMovementPickRange = 157, -- 仲胥 强制位移点选范围 怪/机关周围四向可强制位移的范围 最大距离受能量限制（机关有额外消耗）
    PickUpCrossIgnoreValidity = 158, --点选格子的周围四格，忽略有效性判断，需搭配范围中心类型为点选的使用
    PyramidByPickUpDirAndBuffLayer = 159, --点选方向的锥形区域，区域长度根据Buff层数确定（每N层增加1）（醒山技能范围的扩展版）
    TargetAroundFarestExtend = 160, --目标周围一圈中，自己身形有一格可以放进就可以，选择最远的点，但是要保持中心点朝向玩家。如果周围一圈没有位置可以扩散圈数。配置参数计算连线格子（N28蜘蛛BOSS）
    BoardSelectEdgeRandomAndExtend = 161, --棋盘的指定边上计算随机点的基础范围 以及其追加计算的5种范围
    DrillerMoveTargetPos = 162, --N29boss 钻探者 移动目标点 地图分成9个区域，除boss所在区域外，包含指定机关最少的区域为最空旷区域，按区域中心点选最近的作为目标位置
    DrillerMovePathWithExtendRange = 163, --N29boss 钻探者 预览用 以162算出的点为目标点，计算移动路径（用ai移动的计算方式）作为attackRange，每一步计算一个额外范围（一格十字），合并作为wholeRange
    PickUpDoubleCrossWithDistance = 164, ---点选用米字型,实际范围由点选决定
    FakeBodyArea = 165, ---相对中心点的偏移坐标列表（临时的bodyArea），可设置按朝向旋转（以（0，-1）为默认朝向 N29 钻探者召唤平台怪用
    UseScopeByTeleportCalcState = 166, ---根据瞬移结果中的终点和计算阶段使用不同的范围
    BuffLayerMostAndHighestHPAndNearest = 167, --优先打指定buff层数最多并且血最高的人，要是有多个符合条件的就从最近的开始选
    Boss2904001TeleportPreview = 168, --伯努戈尔登的瞬移预览
    SquareWithoutBodyArea = 169, --不根据身形计算的方形，8号变体
    MonsterQuadGridCustomRangeByDirection = 170, --https://wiki.h3d.com.cn/pages/viewpage.action?pageId=86363411
    RandomGridsByPieceType = 171, --全屏范围内随机指定颜色的X个格子
    ColOrRowByPickUpCount = 172, ---点选一次选择列，点选两次选择行
    TScope = 173, ---T型范围，面前两排四格
    SkillScopeTypeEnd = 999
}

--黑拳赛模式下的技能范围替换表
PvPSkillScopeTable = {
    [SkillScopeType.Team] = SkillScopeType.FriendTeamGrid,
    [SkillScopeType.AllMonster] = SkillScopeType.EnemyTeamGrid,
    [SkillScopeType.Nearest] = SkillScopeType.EnemyTeamGrid,
    [SkillScopeType.AllMonsterGrid] = SkillScopeType.EnemyTeamGrid,
    [SkillScopeType.NearestOneByOne] = SkillScopeType.EnemyTeamGrid,
    [SkillScopeType.TargetUnderFoot] = SkillScopeType.EnemyTeamGrid,
    [SkillScopeType.BuffLayerMostAndHighestHPAndNearest] = SkillScopeType.EnemyTeamGrid
}

function IsRandomSkillScopeType(scopeType)
    return scopeType == SkillScopeType.EmptyRandGrid or scopeType == SkillScopeType.RandomRectAndCount or
        scopeType == SkillScopeType.RandomGrids or
        scopeType == SkillScopeType.MultiRandomRange or
        scopeType == SkillScopeType.RandomPosEmptyOrTrap or
        scopeType == SkillScopeType.QierMonsterRoundRandom or
        scopeType == SkillScopeType.RandomGridsByPieceType
end

---@class SkillScopeDefaultFilter:Object
_class("SkillScopeDefaultFilter", Object)
SkillScopeDefaultFilter = SkillScopeDefaultFilter
function SkillScopeDefaultFilter:CalcCenterPosAndBodyArea(centerType, playerGridPos, playerBodyArea, scopeParam)
    return playerGridPos, playerBodyArea
end

function SkillScopeDefaultFilter:CalcPreviewCenterPosAndBodyArea(centerType, playerGridPos, playerBodyArea, scopeParam)
    return playerGridPos, playerBodyArea
end

function SkillScopeDefaultFilter:IsValidPiecePos(pos)
    local x = pos.x
    local y = pos.y
    if (x < 1 or x > BattleConst.DefaultMaxX or y < 1 or y > BattleConst.DefaultMaxY) then
        return false
    end
    local gapTiles = BattleConst.GapTiles
    for _, v in ipairs(gapTiles) do
        if x == v[1] and y == v[2] then
            return false
        end
    end
    return true
end

function SkillScopeDefaultFilter:IsPosBlock(pos, blockFlag)
    return self:IsValidPiecePos(pos)
end

function SkillScopeDefaultFilter:SelectNearestMonsterOnPos(target_pos, limit)
    return {}, {}
end

function SkillScopeDefaultFilter:IsPosHaveMonsterOrPet()
    return false
end

function SkillScopeDefaultFilter:GetBlockGridTrapPosList(blockType)
    return {}
end

function SkillScopeDefaultFilter:FindPieceElementByTypeCountAndCenter(centerPos, pieceTypeList, maxCount)
    return {}
end

function SkillScopeDefaultFilter:GetBoardMaxX()
    return BattleConst.DefaultMaxX
end

function SkillScopeDefaultFilter:GetBoardMaxY()
    return BattleConst.DefaultMaxY
end

function SkillScopeDefaultFilter:_GetRandomNumber(m, n)
    return math.random(m, n)
end
