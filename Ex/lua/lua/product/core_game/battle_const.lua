require "piece_type"
---@class BattleConst
---@field CandleLightKey string
---@field UIBossHPEliteInfoDefaultWidth number
---@field UIBossHPEnergyItemWidth number
---@field TeleportExitBoardOffsetX number
---@field TeleportExitBoardOffsetY number
BattleConst = {
    --局内一帧时间长度
    FrameTime = 1 / 30,
    --星灵移动速度
    MoveSpeed = 4.5,
    MoveInternal = 1000, ---普攻宝宝出战间隔
    CanMoveInternal = 1000, ---后一个宝宝跟前一个宝宝在一个格子后，前一个宝宝离开多久后后一个宝宝再移动的时间
    SuperChainCount = 15,--取进超级连锁的格子数需要用UtilDataServiceShare:GetCurrentTeamSuperChainCount()，倍率相关仍用SuperChainCount
    --直着移动一格的时间
    OneGridMoveTime = 1 / 4.5,
    --斜着移动一格的时间
    OneGridObliqueMoveTime = math.sqrt(2) / 4.5,
    ---场景暗屏layer
    NormalSceneLayer = 0,
    DarkSceneLayer = 16,
    ---暗屏shader参数值，1表示全黑
    DarkShaderValue = 0.4,
    ---暗屏shader 渐暗的时长，单位秒，可以小数
    DarkShaderDuration = 1,
    ---移轴虚化场景layer
    TiltShiftLayer = 20,
    --连锁技暗屏变暗时长
    ChainSkillToDarkTime = 300,
    ChainSkillDarkAlpha = 0.5,
    ChainSkillToNormalTime = 500,
    --大招暗屏
    ActiveSkillDarkAlpha = 0.5,
    ActiveSkillToNormalTime = 500,
    ---眩晕等待时间
    StunWaitTime = 2000,
    --默认的一个瞬移速度
    FlySpeed = 50,
    --攻击目标是被克制的
    Strong = 0.2,
    --攻击目标是克制自己的
    Counter = 0.2,
    ---低血量全屏泛红的血量百分比
    LowHpWarningPercent = 30,
    --点击玩家时的fov值
    FocusPlayerFov = 5.5,
    --相机变到聚焦模式下的时长
    FocusFovTimeLen = 0.2,
    ---点击后的等待时长
    FocusWaitTime = 10,
    --相机从聚焦模式到正常模式的时长
    FocusToNormalTimeLen = 0.3,
    --聚焦玩家时的变化值
    --FocusDeltaEuler = 10,
    FocusDeltaPos = 7,
    ---距离中心点的距离，判定是否在边缘
    BorderDistance = 4,
    ---相机推进的最大长度
    CameraMaxTranslate = 13,
    ---相机推进的正常长度
    CameraNormalTranslate = 13,
    --相机滑动时的移动速度
    TouchMoveCameraSpeed = 0.0020,
    --相机滑动到边缘的时候的移动速度
    TouchMoveCameraEdgeSpeed = 0.0040,
    --相机滑动时边界定义
    MoveCameraEdge = 7,
    --相机归原位时的时长
    MoveCameraToNormalTime = 0.3,
    --相机位置变化时长
    MoveCameraToDeltaTime = 0.25,
    --相机最大移动距离
    CameraMaxHorizatalLeft = 2.85,
    CameraMaxHorizatalRight = 2.85,
    CameraMaxVerticalUp = 1.6,
    CameraMaxVerticalDown = 1.6,
    CameraDefaultAspect = 1.77777, --相机默认的宽高比，小于这个值局内相机fov会在配置的基础上增大，以适配ipad
    --buff图标的高度偏移
    HeadBuffHeightOffset = 0.5,
    --慢放的scale
    FreezeTimeScale = 0.1,
    FreezeDuration = 300,
    --三星条件展示时长
    BonusShowDuration = 3000,
    --被击动作播放间隔 毫秒
    HitAnimationIntervalMs = 500,
    --击退速度
    HitbackSpeed = 30,
    --默认的被击退动画
    DefaultHitbackAnimName = "Hit",
    --手动转色数（临时配置）
    ManualConvertCount = 5,
    --子弹时间速度
    BulletTimeSpeed = 0.15,
    ---拾取事件
    CollectPanelShowTimeLen = 5000,
    CollectPanelDuration = 0.3,
    ---手指引导时长
    GuideFingerDuration = 5,
    ---引导路径点之间的间隔时长，单位秒
    GuidePathInternal = 0.2,
    ---引导结束一次后的等待时长
    GuidePathStepWaitTime = 1000,
    --最最最后一击
    LastPlayerFov = 4,
    LastFovTimeLen = 0.009,
    LastBackTimeLen = 0.8,
    --剧情StoryTips默认持续时长单位毫秒
    StoryTipsDuration = 2000,
    --连续的StoryTips消失间隔
    StoryTipsHideIntervalDuration = 800,
    ---站在这些格子上tips出现在右侧
    StoryTipsRightGridPosList = {
        {1, 3},
        {1, 4},
        {1, 5},
        {1, 6},
        {1, 7},
        {2, 2},
        {2, 3},
        {2, 4},
        {2, 5},
        {2, 6},
        {2, 7},
        {2, 8},
        {3, 1},
        {3, 2},
        {3, 3},
        {3, 4},
        {3, 5},
        {3, 6},
        {3, 7},
        {4, 1},
        {4, 2},
        {4, 3},
        {4, 4},
        {4, 5},
        {4, 6},
        {5, 1},
        {5, 2},
        {5, 3},
        {5, 4},
        {5, 5},
        {6, 1},
        {6, 2},
        {6, 3},
        {6, 4},
        {7, 1},
        {7, 2},
        {7, 3},
        {8, 2}
    },
    ---站在这些格子上tip出现在左侧
    StoryTipsLeftGridPosList = {
        {9, 3},
        {9, 4},
        {9, 5},
        {9, 6},
        {9, 7},
        {8, 3},
        {8, 4},
        {8, 5},
        {8, 6},
        {8, 7},
        {8, 8},
        {7, 4},
        {7, 5},
        {7, 6},
        {7, 7},
        {7, 8},
        {7, 9},
        {6, 5},
        {6, 6},
        {6, 7},
        {6, 8},
        {6, 9},
        {5, 6},
        {5, 7},
        {5, 8},
        {5, 9},
        {4, 7},
        {4, 8},
        {4, 9},
        {3, 8},
        {3, 9}
    },
    ---左侧偏移量
    StoryTipsLeftOffSet = -0.2,
    ---右侧偏移量
    StoryTipsRightOffSet = 0.2,
    ---怪物通用表现配置
    MonsterEffDelay = 0,
    MonsterShowEDelay = 500,
    MonsterDuration = 100,
    ---机关通用表现配置
    TrapEffDelay = 0,
    TrapEffId = 58,
    TrapShowEDelay = 500,
    TrapDuration = 100,
    TrapAni = "Brith",
    TrapAniDelay = 2000,
    ---单体伤害冒字初始高度
    SingleDamageNumberShowHeight = 0.5,
    ---格子伤害冒字高度
    GridDamageNumberShowHeight = 0.5,
    ---伤害字上升距离
    DamageUpHigh = 0.2,
    ---持续时长单位秒
    DamageDuration = 0.5,
    ---随机点集偏移组
    DamageHighestPointList = {
        Vector2(0.05, 0.2),
        Vector2(0.09, 0.2),
        Vector2(-0.09, 0.17),
        Vector2(0.1, 0.19),
        Vector2(-0.1, 0.16),
        Vector2(0.08, 0.2),
        Vector2(-0.08, 0.17),
        Vector2(0.11, 0.19),
        Vector2(-0.11, 0.16)
    },
    LockGridTrapID = 61, --锁格子机关ID
    PrismTrapID = 62, --棱镜机关ID
    ---加血特效
    AddHealthEffect = 9,
    --护盾受击特效
    ShieldHitEffect = 115,
    ---护盾破碎特效
    ShieldBrokenEffect = 116,
    ---风船专用-护盾破碎特效
    AircraftHitShieldEffect = 786,
    ---风船专用-护盾持续
    AircraftHoldShieldEffect = 759,
    ---信标减伤
    HarmReductionNormal = 976,
    ---信标减伤100%
    HarmReductionInvincible = 976,
    ---怪物行动范围文字提示特效
    MonsterAttackRangeTextEffect = 339,
    MonsterBornEffectList = {
        319,
        320,
        321,
        322,
        323
    }, --怪物出场通用特效id
    MonsterBornAudioList = {
        9033,
        9034,
        9035
    }, --怪物出场通用特效对应的音效
    TimeSpeedKeyStr = "UIBattleTimeSpeed", --倍速本地存储键字符串
    TimeSpeedList = {1.2, 1.8,3.5}, --倍速按钮游戏速率选择列表，多个值时点击按钮会依次取表中的值赋给Time.timeScale
    Speed2Index = 2;
    RimFlashTime = 0.3, --受击闪白效果时长
    GoBackStayTime = 750, ---点击回退需要的停留时长
    GridSideLength = 1, ---深渊格子边的长度
    AbyssBottomDepth = -1.5, ---深渊格子底的深度
    SpAbyssBottomDepth= -1,---特殊深渊格子底的深度
    GridSideYScale = 1.5, ---深渊格子边的Y轴拉伸
    SpGridSideYScale = 1, ---特殊深渊格子边的Y轴拉伸
    ---普攻 连锁技 的主副属性伤害系数
    LeaderPrimaryParam = 1, ---队长普攻连锁技 主属性匹配
    LeaderSecondaryParam = 1, ---队长普攻连锁技 副属性匹配
    LeaderNullParam = 1, ---队长普攻连锁技 属性不匹配
    LeaderAllParam = 1.05, ---队长普攻连锁技 主属性副属性都匹配
    PetPrimaryParam = 1, ---队员普攻连锁技 主属性匹配
    PetSecondaryParam = 0.35, ---队员普攻连锁技 副属性匹配
    PetAllParam = 1.05, ---队员普攻连锁技 属性都匹配
    PrimarySecondaryDefaultParam = 1, ---默认值
    PrimarySecondaryActiveParam = 1, ---主动技
    ---End
    ---棋盘一些默认参数
    DefaultMaxX = 9,
    DefaultMaxY = 9,
    DefaultAIAreaSize = 11,
    DefaultPlayerAreaSize = 9,
    GapTiles = {{1, 1}, {1, 2}, {2, 1}, {1, 8}, {1, 9}, {2, 9}, {8, 1}, {9, 1}, {9, 2}, {8, 9}, {9, 8}, {9, 9}},
    BoardCenterPos = Vector2(5, 5),
    StepPower = 1,
    RefreshPieceTick = 700, ---等待格子刷新动效时间
    RefreshPetInfoTick = 700, ---回合切换时，宝头像渐入渐出时间
    ---END
    WaringHeight = 0.01,
    --region 出口机关
    ExitTrapID = 702, --出口机关id
    ExitViewSkillID = 500083, --出口机关技能
    --endregion

    --技能释放摄像机移动参数
    MinScreenHeight = 0.6, --移动的最低屏幕高度
    MaxScreenHeight = 0.9, --移动的最高屏幕高度
    CameraOffsetArray = {{x = 0, y = 1, z = 0}, {x = 0, y = 3, z = 0}}, --偏移位置列表
    --region 传送带
    ConveySpeed = 3, --传送速度
    --endregion
    TractionSpeed = 10, -- 牵引速度
    ForceMovementPreviewSpeed = 10,
    --region 格子效果参数
    PrismEffectPieceCount = 2,
    --endregion
    FallGridTime = 0.7, --0.7秒全部下落完
    --双击生效的间隔事件
    DoubleClickIntervalTime = 1000,
    DefaultMovementSpeed = 2,
    DefaultMovementAnimatorBool = "Move",
    FlagBuffType = 10001, -- BuffEffectType.SetInternalFlag 加载顺序导致无法获取
    FlagBuffOverlayKeyFormatter = "Layer_%d",
    --麻痹特效ID
    BenumbGridEffectID = 969,
    PreAttackBuffId = 40801, --先制攻击buff
    PreAttackBuffIdForExtra = 40805, --附加技先制攻击buff
    ImmuneTransportBuffIds = {30184, 30185}, --免疫传送带和传送漩涡传送buff
    NotLoadHighMonsters = {2900301, 2900801, 2900811, 2903001}, --不加载到1000米高空的怪物classId
    NotShowHUDHPMonsters = {2900301, 2903001}, --不显示头顶血条的怪物classId
    MonsterDeadEffectLight = 1060, --怪物死亡特效 （DeathShowType.DissolveLight = 1, --光溶解的默认附带特效）
    MonsterDeadEffectDark = 1059, --怪物死亡特效 （DeathShowType.DissolveDark = 2, --暗溶解的默认附带特效）
    DefaultWarningAreaTextEffectID = 339, -- 默认预警区文字特效
    BaseGridRenderPos = Vector3(-4, 0, -3),--(1,1)格子的默认绘制位置，实际位置受配置影响，使用接口 BoardServiceRender:GetBaseGridRenderPos()
    AuroraFxExitTimeMs = 734, -- Animation Clip时长，采样30frame，持续22frame，0.73333 sec
    PickupInvalidAnimTimeMs = 500, -- Animation Clip时长，采样30frame，持续15frame，0.5 sec
    --region 阻挡信息
    BlockFlagCfgIDPet = 7, --宝宝阻挡信息配置ID
    BlockFlagCfgIDGapTile = 9, --GapTile阻挡信息配置ID
    --endregion
    --region 任意门
    DimensionPreviewInstructionSetId = 100, --任意门拾取表现，无连锁轮播（对应cfg_preview_instruction_set的主键）
    DimensionPreviewInstructionSetIdChain = 101, --任意门拾取表现，有连锁轮播（对应cfg_preview_instruction_set的主键）
    DimensionPreviewInstructionSetIdPrepare = 102, --任意门拾取准备表现（对应cfg_preview_instruction_set的主键）
    DimensionPreviewInstructionSetIdFinish = 103, --任意门拾取结束表现（对应cfg_preview_instruction_set的主键）
    DimensionPreviewCarouselDuration = 2000, --连锁轮播时长ms
    --endregion
    ChangeTeamLeaderEffect = {
        [PieceType.Blue] = 1322,
        [PieceType.Red] = 1323,
        [PieceType.Green] = 1324,
        [PieceType.Yellow] = 1325
    },
    CacheHeight = 1000,
    --逻辑计算分帧时间
    LogicYieldTime = 0.02,
    --自动战斗开启增强算法
    AutoFightMoveEnhanced = false,
    --自动战斗高连通率路径长度裁剪值
    AutoFightPathLengthCut = 4,
    --自动战斗连通图连通率大于X裁剪路径长度
    AutoFightPathLengthCutConnectRate = {3,3.8},
    --自动战斗连通图格子数大于X裁剪路径长度
    AutoFightPathLengthCutPosNum = 16,
    --自动战斗优选路径数量裁剪值
    AutoFightPathCountCut = 4,
    --自动战斗路径计算复杂度
    AutoFightPathComplexity = {100000,200000};
    --自动战斗不能普攻的点评估值
    AutoFightNoAttackPosValue = 7,
    --自动战斗可以普攻的点评估值
    AutoFightNormalAttackPosValue = 30,
    --自动战斗普攻chain系数
    AutoFightNormalAttackChainParam = 0.1,
    --自动战斗连锁技chain系数
    AutoFightChainAttackChainParam = 0.1,
    --自动战斗连锁技攻击次数评估值系数
    AutoFightChainAttackValue = 50,
    --自动战斗超级连锁达成增加权值
    AutoFightSuperChainAddPathValue = 200,
    AutoFightElementBuffFlagAddPosValue = {
        --自动战斗属性强化buff人克制怪时普攻连线的权值系数
        [0] = 50,
        --自动战斗属性强化buff怪克制人时普攻连线的权值系数
        [1] = 20,
        --自动战斗属性强化buff无克制时普攻连线的权值系数
        [2] = 30
    },
    FinalAttackSkillIdListOfTriggerTrap = {580222, 580232}, --触发型机表现有最后一击的技能id列表
    ScopeAngleFreeLineThreshold = 0.7, -- AngleFreeLine(46)的公式内常量
    --秘境特殊处理的特效ID
    MazeArchivedEffectID = {
        578, --卡拉肯出场特效
        1139, 1147, 1155, 1163, --马拉索尔
    },
    --秘境不存档关卡id列表
    MazeNoSaveArchiveLevelID = {
        99952001 --宝箱关
    },
	--米亚不收集灵魂的主动技
    PetMiyaNotCollectSoulsSkillIDs = {3100052, 3160052, 3300052, 3360052},
    -- BEGIN MSG12932 （QA_郭简宁）局内QA_血条显示不出屏_20201111
    HUDEdgeUpper = 0.96, -- 上边界
    HUDEdgeDown = 0.1, -- 下边界
    HUDEdgeLeft = 0.03, -- 左边界
    HUDEdgeRight = 0.9, -- 右边界
    -- END MSG12932 （QA_郭简宁）局内QA_血条显示不出屏_20201111

    --服务器检查到不同步后，true是踢人，false是不踢人
    Kick = true,
    ChainSkillSnipeEffectID = 1610,
    UIBattleTeamStateEnter_ShieldBarWidth = 211,
    -- 通用强化格子机关ID
    DefaultEnhanceGridTrapID = 14,
    BattleEnterIntroPresentation_CameraFovMultiplier = 30,
    BoardShowPieceGroupInternal = 75, --出场格子距离组播放间隔
    BoardShowPieceRandomRange = {min = 0, max = 120}, --出场格子每组中格子出现随机区间
    DamageBuffAnimatorHitDelay = 1000, --DOT buff受击等待时间
    CoroutineMaxWaitTime = 1000 * 1 * 60, ---协程最大等待时长 1分钟
    RoundAddLegendPower = 5, --每回合增加5点传说光灵的能量
    LegendPowerMax = 99, --传说光灵的能量上限
    UseObsoleteAI = false, ---AI使用旧的行动力机制，行动力重构后，可以删掉此配置
    WordBuffForMission = 7770001, --主线通关词缀
    EndDragEffect = 2471, --抬手扩散波特效
    ---MSG26037 为添加层数的逻辑额外记录一套数据，用来区分层数
    AddBuffLayerTotalKeyFormatter = "__TOTAL_%s",
    MonsterADHFormula2ParmaYDefault = 1, ---怪物攻防血计算公式2 中 参数Y的默认值
    MonsterADHFormula2ParmaZDefault = 1, ---怪物攻防血计算公式2 中 参数Y的默认值
    WorldBossHP = 99999999999, --世界Boss的血量
    ControlBuffEffectTypeArray = {1001, 1002, 3006},
    PreviewMonsterInternal = 3000,
    ---怪物预览间隔
    SingleDamageMaxValue = 3000000,
    TotalDamageMaxValue = 10000000000, ---世界Boss血量 10%
    TotalDamageMaxValueMod = 100000000,
    ---格茨德屏蔽列表
    DisableMonsterClassIDList = {2900415, 2900416, 2900417, 2900418, 3900411},

    ---不需要材质动画的怪物列表
    MonsterDontNeedMaterialAnimationClassIDList = {2002202},
    --精英怪物的永久特效
    EliteMonsterPermanentEffectBodyArea1 = 3086,
    EliteMonsterPermanentEffectBodyArea4 = 3087,
    EliteMonsterTrialEffect = "eff_jingying_01.asset",
    FallGridDirDefaultEffectId = 3508,--格子下落 场景播的箭头特效
    --MSG34442
    NonFormalPetWarningEnabled = true,
    --连通率系数
    BoardGenConnectRateParamTable={
        1.20,1.10,1.05,0.98,0.95,
        0.92,0.90,0.88,0.86,0.85,
        0.85,0.85,0.85,0.85,0.85,
        0.85,0.85,0.85,0.85,0.85,
        0.85,0.85,0.85,0.85,0.85,--20220224 地图扩大，新增一行
    },
    --其他棋盘面的连通率系数
    OtherBoardConnectRate = 0.85,
    E_HelpPet_EnableHelpSlotIndex = 5,
    NoShowCasterEntityOnPreview = {300144,302144,310144,312144,300146,303146,320146,323146,330146,333146},
    UIChangeTeamOrderTweenerTime = 0.5,

    -- 打乱出战顺序：phase1是所有头像运动到队长位置的时间，phase2是到这里分开的时间
    UIShuffleTeamOrderPhase1Time = 0.25,
    UIShuffleTeamOrderPhase1Pause = 0.1,
    UIShuffleTeamOrderPhase2Time = 0.25,

    ---白线材质的默认参数
    Wangge_WidthMin = 0,
    Wangge_WidthMax = 0.2,---网格白线最大宽度
    Wangge_GlobalWidth = 10.49,---网格白线全局宽度
    Wangge_HeightMin = 0,
    Wangge_HeightMax = 0.2,---网格白线最大高度
    Wangge_GlobalHeight = 10.49,---网格白线全局高度

    HUDUI_ChessHPSliderBuffOffset = 72,
    HUDUI_ChessHPSecondBarThreshold = 50,
    N15MaterialAnimAsset = "n15_shader_effects.asset",
    SanCameraEffID = 3531,--San系统 屏幕特效id
    SanViewEffDefaultStartVal = 70,--San系统 屏幕特效开始出现的默认san值
    DayNightToDayDefaultEffID = 3545,--昼夜系统 变白天时的场景特效ID
    DayNightToNightDefaultEffID = 3546,--昼夜系统 变夜晚时的场景特效ID
    BoardMaxLen = 11, ---取长宽里面的最大值
    RealFrameTime = 1/30, ---根据进局动态修改当前帧数

    EachSuperGridDamageParam = 0.05, --强化格子伤害系数，计算时用加法
    EachPoorGridDamageParam = -0.1, --弱化格子伤害系数，计算时用加法

    -- 回合数不足扣血
    PunishmentRoundHPPercent = {
        [1] = 0.1,
        [2] = 0.15,
        [3] = 0.2,
        [4] = 0.25,
        [5] = 0.3
    },

    BoardShowCameraAnimationByScript_TweenTime = 1.167, --DOTween相机动画的时间参数，单位为秒
    --region 传送预览
    PreviewConveySpeed = 2, --传送速度
    CandleLightKey = "CoffinMusumeCandleLight", --N23棺材娘专属：蜡烛点亮状态的BuffValueKey
    PartnerAttrCfgComponentID = 107602607,--取伙伴对应配置用到的活动组件ID

    UIBossHPEliteInfoDefaultWidth = 660,--UIBossHPEliteInfo的默认宽度
    UIBossHPEnergyItemWidth = 48, --UIBossHPEnergyItem的宽度
    TeleportExitBoardOffsetX = 1000, -- TeleportExitBoard: x axis offset
    TeleportExitBoardOffsetY = 1000, -- TeleportExitBoard: y axis offset

    HUDHPSliderDefaultWidth = 144, -- HPSlider的默认宽度
    HUDHPSliderBuffIconWidth = 39, -- HPSlider上单个buff图标的宽度
    HUDHPSliderBuffIconFullWidthOffset = 12, --原先宽度144，但最多显示4个buff图标，buff容器宽度156，因此原本就比血条长度多了这些
    AuroraTimeFxQuadHeight = -0.1,


    PlayerStunRenderYieldTimeMS = 1500, --玩家眩晕退出WaitInput时的延时，否则表现比较奇怪

    DestroyPieceEffectID = 290520115, --玩家连线结束时玻璃格子碎裂特效ID
    DestroyPieceEffectPlayInterval = 150, --格子碎裂特效播放间隔

    GridCellScale = 1,--棋盘网线默认大小
    
    --region 消灭星星
    --进度条
    PopStarProgressStart = 9, --进度条起点位置
    PopStarProgressLength = 766, --进度条总长度
    PopStarLastMark = 775, --最后一个星星所在位置，不放进度条最后
    PopStarPointWidth = 4, --进度条指针宽度
    PopStarMaskBaseWidth = 110, --进度条Mask基础宽度
    PopStarMaskEndAdd = 40, --进度条达到100%（764）后，需要补充的增长宽度，填充到进度条最后
    PopStarOneScoreTime = 50, --1分变化的时长，毫秒
    --其他
    PopStarPopWaitTime = 700, --点击消除后，等待格子下落的时长
    --endregion

    --region MSG64606/MSG64611 Weight of grids in calculation of PickUpPolicy.PickUpConvertWithWeight
    NormalMonsterAroundGridWeightWhenConverting = 10,
    EliteMonsterAroundGridWeightWhenConverting = 20,
    BossAroundGridWeightWhenConverting = 40,
    --endregion

    TrapShowLevelDefault = 0, ---机关显示层级，默认为0
    BuffCalcScopeKeyFormat = "BUFF_VALUE_CALC_SCOPE_%d", --配套逻辑专用key格式字符串，使用buff id拼接

    ---MSG70190 原版逻辑只在召唤时写入需要替换的信息，无法用来永久性判断是否需要统一处理
    AkexiyaScanTrap_MeantimeLimitID = {
        --吧噗
        15020811, 15020815, 15120811, 15120815, 15220811, 15220815, 15320811, 15320815,
        --罗伊
        150114911, 15014912
    },

    Tank2002901TowerEffectKey = "EFFECT_HOLDER_KEY_2002901_TANK_TOWER"
}

_enum("BattleConst", BattleConst)
