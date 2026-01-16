--------------------------引导步骤类型----------------------------------region引导步骤类型
---@class GuideType
local GuideType = {
    Button = 1, -- UI引导
    Model = 2,
    -- new --
    Line = 3,               -- 连线引导
    StoryBanner = 4,        -- 引导剧情横幅(UIStoryBanner)
    Warn = 5,               -- 提示类
    Pop = 6,                -- 弹窗
    Piece = 7,              -- 格子引导
    OpenUI = 8,             -- 打开界面
    InnerAttrIcon = 9,      -- 局内属性按钮
    BattleComplete = 10,    -- 结算直接done 用于局内最后一步
    Circle = 11,            -- 圆形引导
    UnLock = 12,            -- 解锁引导
    Story = 13,             --剧情
    Buff = 14,              -- buff
    Entity = 15,            -- Entity
    AirCameraFocusPet = 16, -- 风船相机聚焦
    GameCommand = 17,       -- 局内指令
    OperationFinish = 18,   -- 操作完成
    PreviewLinkLine = 19    --主动技预览阶段连线引导
}
_enum("GuideType", GuideType)

------------------------- 引导触发类型-----------------------------
---@class GuideRoundTurn
local GuideRoundTurn = {
    PlayerTurn = 0,  -- 我方行动
    MonsterTurn = 1, -- 敌方行动
    AuroraTime = 2,  -- 激光时刻
    BuffEnd = 3,     --回合内Buff表现结束时
}
_enum("GuideRoundTurn", GuideRoundTurn)

---@class GuideOpenUI
local GuideOpenUI = {
    "UIShop",                                   -- 1商城
    "UIAircraft",                               -- 2风船
    "MazeRoomType_Normal",                      -- 3一般区域
    "MazeRoomType_Battery",                     -- 4休息室
    "MazeRoomType_XRoot",                       -- 5根须取义
    "UIMazeBag",                                -- 6 圣物背包
    "MazeRoomType_Elite",                       -- 7 精英区域
    "UIDispatchMap",                            -- 8 风船派遣界面
    "UIAircraftDecorate",                       -- 9 风船装修界面
    "UIDiscovery",                              -- 10 大地图界面
    "UIHelpPetSelect",                          -- 11 选择助战星灵界面
    "UITalePetList",                            -- 12 传说光灵列表界面
    "UITalePetMissionController",               -- 13 传说光灵召集任务界面
    "UISakuraEntryController",                  --14 樱龙使主界面
    "UISummer1",                                --15 夏活1
    "UIActivityBattlePassMainController",       --16 战斗通行证
    "UIMiniGameController",                     --17 夏活1小游戏
    "UISummerActivityTwoMainController",        --18 夏活2
    "UISummerActivityTwoSelectEntryController", --19 夏活2难度选择
    "UIN5MainController",                       --20 N5活动
    "UIActivityNPlusSixMainController",         --21 N6活动
    "UIActivityNPlusSixMainControllerBuilding", --22 N6活动驿站重建
    "UIWorldBossController_Obsolete",           --23 世界boss --旧版本灾典，新版本不再使用此触发，其它引导可占用此23id
    "UIActivityN7MainController",               --24 N7活动
    "UIActivityN8MainController",               --25 N8活动
    "UIAircraftTactic",                         --26 --风船战术室
    "UITacticTapeInfo",                         --27 --风船战术室关卡信息
    "UIActivityN9MainController",               --28 N9活动
    "UIN10MainController",                      --29 N10活动
    "UIN11Main",                                --30 N11活动
    "UIN12MainController",                      --31 N12活动
    "UIN13MainController",                      --32 N13活动
    "UIN14MainController",                      --33 N14活动
    "UIN14FishingGameController",               --34 N14钓鱼
    "UIN15MainController",                      --35 N15活动
    "UIActivityN16MainController",              --36 N16活动
    "UIHomelandBreed",                          --37 N17家园培育
    "UIHomelandShopController",                 --38 N17家园商店
    "UIHomelandLevel",                          --39 N17家园等级
    "UIHomelandFishing",                        --40 N17家园钓鱼
    "UIHomelandFelling",                        --41 N7家园砍树
    "UIHomelandMining",                         --42 N17家园挖矿
    "UIHomelandMain",                           --43 N17家园基础操作
    "UIForgeCreateDomitory",                    --44 N17家园建造宿舍
    "HomelandUnlock",                           --45 N17家园解锁
    "UIN17MainController",                      --46 N17活动
    "UIDiscoveryHardLevel",                     --47 困难关
    "UIForge",                                  --48 建造培育地块
    "UIN18MainController",                      --49 N18活动
    "UIN19MainController",                      --50 N19活动
    "UIN19P5Controller",                        --51 N19 P5活动
    "UIActivityN20MainController",              --52 N20活动
    "UIN20MiniGameController",                  --53 N20小游戏
    "UIN21Controller",                          -- 54 N21主活动
    "UIActivityN22MainController",              -- 55N22主活动
    "UIN23Main",                                -- 56 N23主活动
    "UIActivityN24MainController",              -- 57 N24主活动
    "UIActivityN25MainController",              -- 58 N25主活动
    "UIN25IdolLogin",                           -- 59 N25偶像养成登录页
    "UIN25IdolGame",                            -- 60 N25偶像养成游戏
    "UIN25VampireMain",                         -- 61 N25吸血鬼主界面
    "UIN25VampireTalentTree",                   -- 62 N25吸血鬼游戏
    "UIMiniMazeChooseRelicController",          --63 N25吸血鬼局内圣物选择
    "UIMiniMazeChoosePartnerController",        -- 64 N25吸血鬼局内伙伴选择
    "UIActivityN26MainController",              -- 65 N26主活动
    "UIN27Controller",                          -- 66 N27主活动
    "UIN27PostInnerGameController",             -- 67 N27信使游戏
    "UIActivityN28MainController",              --68 N28主活动
    "UIN28AVGMain",                             -- 69 N28AVG主界面
    "UIN28AVGStoryGainEvidence",                -- 70 N28AVG游戏中获得证据界面
    "UIN28AVGStoryShowEvidence",                -- 71 N28AVG游戏中举证界面
    "UIN28AVGStoryEvidenceBook",                -- 72 N28AVG游戏中审判官笔记界面
    "UIN28GronruGameSelectPlayer",              -- 73 N28Gronru小游戏
    "UIN28GronruGameLevel",                     -- 74 N28Gronru小游戏Map
    "UIBounceMainController",                   -- 75 N28弹跳小游戏 关卡1
    "UIBounceMainController2",                  -- 76 N28弹跳小游戏 关卡2
    "UIBounceMainControllerBoss1",              -- 77 N28弹跳小游戏 关卡6 boss1
    "UIBounceMainControllerBoss2",              -- 78 N28弹跳小游戏 关卡6 boss2
    "UIBounceMainControllerBoss3",              -- 79 N28弹跳小游戏 关卡6 boss3
    "UIActivityN29MainController",              -- 80 N29 主活动
    "UIN29DetectiveLogin",                      -- 81 N29侦探小游戏 主界面
    "UIActivityN29DetectiveMapController",      -- 82 N29侦探小游戏 地图界面
    "UIN29DetectivePersonController",           -- 83 N29侦探小游戏 对话界面
    "UIN29DetectiveSuspectController",          -- 84 N29侦探小游戏 搜索界面
    "UIN29DetectiveReasoning",                  -- 85 N29侦探小游戏 灵感制作界面
    "UIPetEquipControllerLock",                 -- 86 光灵装备界面-精炼引导-精炼条件未解锁
    "UIPetEquipControllerUnLock",               -- 87 光灵装备界面-精炼引导-精炼条件已解锁
    "UIActivityN30MainController",              -- 88 N30主活动
    "UIActivityN31MainController",              -- 89 N31主活动
    "UIWorldBossController_B",                  --90 世界boss --新版灾典，如果旧版已引导过，则触发此新手
    "UIWorldBossController_C",                  --91 世界boss --新版灾典，如果旧版伟引导过，则触发此新手
    "UIActivityN32MainController",              --92 N32主活动
    "UIN32MultiLineMain",                       --93 多周目水晶球界面
    "UIN32MultiLineMapController",              --94 多周目地图界面
    "UIN32MultiLineMapController_Doc",          --95 多周目地图界面_首次获得档案
    "UIUpLevelInterfaceController",             ----96 光灵升级引导觉醒(国服55)
    "UIActivityN33DateMainController1",         ----97 N33小游戏主页面1
    "UIActivityN33DateMainController2",         ----98 N33小游戏主页面2
    "UIActivityN33DateMainController3",         ----99 N33小游戏主页面3
    "UIActivityN33LevelController",             ----100 N33小游戏线性关页面
    "UIActivityN33BuildingInfo1",               ----101 N33小游戏建筑升级页面1
    "UIActivityN33BuildingInfo2",               ----102 N33小游戏建筑升级页面2
    "UIActivityN33ArchUpgradeReward",           ----103 N33小游戏建筑升级提示页面
    "UIActivityN33DatePetController",           ----104 N33小游戏光灵界面
    "UIActivityN33MainController",              ----105 N33活动主页面
    "UIS1MainController",                       --106 赛季活动S1
    "UISeasonMain",                             --107 赛季地图
    "UISeasonBuffLevelUp",                      --108 赛季Buff第一次升级
    "UISeasonBuffLevelUp2",                     --109 赛季Buff升级到指定等级
    "UISeasonBubble",                           --110 赛季表现气泡结束
    "SeasonRewardShowEnd",                      --111 赛季表现奖励展示结束
    "SeasonDaily"                               --112 赛季日常关
}
_autoEnum("GuideOpenUI", GuideOpenUI)

---@class GuidePlayerHandle
--------：玩家操作结束（播放动画之前）
local GuidePlayerHandle = {
    LinkEnd = 1,        -- 连线操作结束
    MainSkillFinish = 2 -- 某角色的主动技能操作结束
}
_enum("GuidePlayerHandle", GuidePlayerHandle)

---@class GuidePlayerHandle
-- 释放技能完毕（播放动画之后）
local GuidePlaySkillFinish = {
    LinkEnd = 1,         -- 连线操作结束
    MainSkillFinish = 2, -- 某角色的主动技能操作结束
    ChainSkillFinish = 3 --某角色的连线技能释放完毕
}
_enum("GuidePlaySkillFinish", GuidePlaySkillFinish)

-----------------------------引导cfg_inner_guide相关----------------------------------------------------------------
---引导的时机类型
---@class GuideInvokeType
GuideInvokeType = {
    None = 0,
    GuidePath = 1,                   --划线引导
    CastActiveSkill = 2,             ---主动技
    GuideWeakPath = 3,               --弱划线引导
    GuidePiece = 4,                  -- 有限时间的格子引导
    GuidePieceInfinity = 5,          -- 无限时间的格子引导
    GuidePieceInfinityDontYield = 6, -- 无限时间的格子引导不阻塞
    GuidePreviewLinkLine = 7         --主动技预览阶段的连线引导
}
_enum("GuideInvokeType", GuideInvokeType)

---引导的时机类型
---@class GuideRefreshType
GuideRefreshType = {
    None = 0,
    StartGuidePath = 1,  --开始划线引导
    PauseGuidePath = 2,  -- 暂停划线引导
    StopGuidePath = 3,   --停止划线引导
    ShowGuideLine = 4,   --只显示引导细线
    RestartGuidePath = 5 --重新开始引导
}
_enum("GuideRefreshType", GuideRefreshType)
---------------------------------------button 引导---------------
--region引导步骤完成类型
---@class GuideCompleteType
---@field Click int 单击
---@field DoubeClick int 双击
---@field AnyClickOnlyTrigger int 任意点击
---@field HideCancelLineBtn int 隐藏取消连线按钮
---@field ReleaseActiveSkill int 释放主动技
---@field PressOrAction int 长按弹出界面或者该回合行动后消失
---@field SelfClick int 释放主动技
---@field CompleteImmediately int 立即完成
---@field OperationComplete int 操作完成
---@field TaskState int 任务状态
local GuideCompleteType = {
    "Click",
    "DoubeClick",
    "AnyClickOnlyTrigger",
    "HideCancelLineBtn",
    "ReleaseActiveSkill",
    "PressOrAction",
    "SelfClick",
    "CompleteImmediately",
    "OperationComplete",
    "TaskState"
}
_autoEnum("GuideCompleteType", GuideCompleteType)
--endregion

--region引导特殊类型按钮
---@class GuideBtnType
local GuideBtnType = {
    "UIMapNodeItem",                          -- 1
    "UIWidgetBattlePet",                      --2
    "UIWidgetPetSkill",                       --3
    "UIBattleTeamStateEnter",                 --4
    "UIWidgetBattlePetWeak",                  --5
    "UIWidgetBattlePetPress",                 --6
    "UIHeartItem",                            --7
    "UIConsumableMaterialItem",               -- 8
    "UITeamItem",                             -- 9
    "UIPetItem",                              -- 10
    "UIQuestStoryListItem",                   -- 11
    "UIQuestStoryDetailItemGet",              -- 12
    "UIQuestStoryDetailItemGoto",             -- 13
    "UIQuestTypeBtnItem",                     -- 14
    "UIQuestGrowthLook",                      -- 15
    "UIDrawCardAwardItem",                    --  16 抽卡
    "UIResEntry",                             -- 17 资源本入口
    "UIDrawCardBack",                         -- 18抽卡返回按钮
    "UITurnInfo",                             -- 19回合数
    "UIShopMainTab",                          -- 20商城主页签
    "UIShopSecretGood",                       -- 21黑市商品
    "UIBattleCollect",                        -- 22情报背景
    "UIBattleRound",                          -- 23情报背景
    "UITrapSkillIcon",                        -- 24机关技能icon
    "UITrapSkillBtn",                         -- 25机关技能发动
    "UIResDetailGOBtn",                       -- 26资源详情前往
    "UIExtRoot",                              -- 27番外详情
    "UIAircraft3DUI",                         --28风船3dUI
    "UIAircraftFireIcon",                     -- 29萤火货币栏
    "UIAircraftLightIcon",                    -- 30星能货币栏
    "UIAircraftRoomLB",                       -- 31房间左下角
    "UIAircraftRoomBtnFacility",              -- 32房间设施按钮
    "UIAircraftRoomBtnSettle",                --  -- 33房间入驻按钮
    "UIAircraftRoomAddCell",                  -- 34房间 addcell
    "UIAircraftEnterBuildIcon",               -- 35 入驻星灵界面选icon
    "UIQuestGrowthAward",                     -- 36 成长任务宝箱
    "UIResEntryBtn",                          -- 37资源副本入口
    "UIMazsEntryBtn",                         -- 38秘境副本入口
    "UIExtEntryBtn",                          -- 39番外副本入口
    "UIMazeHp",                               -- 40货币栏Hp
    "UIMazeLight",                            -- 41货币栏光
    "UIAircraftLevelUp",                      -- 42风船升级
    "UIResDouble",                            -- 43资源本货币栏
    "UIBattleChangeLeader",                   -- 44 战斗右上角点击切换队长
    "UIChangeLeader",                         -- 45 点击切换
    "UITowerHome",                            -- 46 爬塔首页
    "UIShengWuPackItem",                      -- 47 圣物背包第一个物品
    "UIGoChainPreview",                       -- 48 旋涡发动d
    "UITowerEntry",                           -- 49 爬塔入口
    "UIQuestSideGotoBtn",                     -- 50 任务支线前往
    "UITeamChangeItemHP",                     -- 51 选队员的hp
    "UIBattleItemHP",                         -- 52 战斗头像的hp
    "UIBattleSpeed",                          -- 53 战斗加速
    "UIAirBackBtn",                           -- 54 风船退出按钮
    "UIWeChatRole",                           -- 55 终端人
    "UITeamHelpPetIcon",                      -- 56 助战图标
    "UITeamItemHelpPet",                      -- 57 助战item
    "UIDispatchMapTaskBG",                    -- 58 风船派遣界面任务bg
    "UIDispatchDetailItem",                   -- 59 风船派遣任务详情界面
    "UIDispatchDetailItemExtraReward",        -- 60 风船派遣任务详情界面额外奖励
    "UIAircraftDecorateListItem",             -- 61 装修界面家具类别某个标签
    "UIAircraftDecorateFurnitureItem",        -- 62 装修界面某个家具物品
    "UIAircraftRoomDecorateBtn",              -- 63 风船房间界面装修按钮
    "UIDiscoveryGuideToNode",                 -- 64 大地图引导到指定关卡并拿到关卡按钮
    "UIDispatchRoomInfo",                     -- 65 派遣室左下键房间信息框
    "UIAirHomeBtn",                           -- 66 风船Home按钮
    "UIMiniGameGuest",                        --67 夏活小游戏客人
    "UIMiniGameOrderformItem",                ----68 夏活小游戏客人订单
    "UITacticDiffBtn",                        ----69 卡带关卡难度选择
    "UIHomeLandShopOrderTag",                 ----70 家园商店订单页签
    "UIHomeLandShopOrderSubmitBtn",           ----71 家园商店订单提交按钮
    "UIHomeLandShopShopTag",                  ----72 家园商店商店页签
    "UIHomeLandShopShopBuyBtn",               ----73 家园商店商店购买按钮
    "UIHomeLandDomitoryMember",               ----74 家园宿舍成员
    "UIHomeDomitorySettle",                   ----75 家园宿舍成员Pet
    "UIInteractPointController",              ----76 家园交互按钮
    "UIForgeItem",                            ----77 家园建造宿舍Item
    "UIForgeSequenceItem",                    ----78 家园建造宿舍Item详情
    "UIForgeSequenceItemSpeedBtn",            ----79 家园建造加速
    "UIHomelandBuild",                        ----80 家园建造模式宿舍
    "DiffStage1",                             ----81 困难关1
    "DiffStage2",                             ----82 困难关2
    "UIForgeSequenceItemGet",                 ----83 家园建造宿舍GetBtn
    "UIForgeSpecialTag",                      ----84 建造特殊页签
    "UIForgeSpecialLandTag",                  ----85 建造特殊页签地块
    "UIEditSpecialTag",                       ----86 布置特殊页签
    "UIEditSpecialLand",                      ----87 布置特殊页签地块
    "UIN20MiniGameGuest",                     ----88 N20小游戏客人
    "UIN20MiniGameOrderformItem",             ----89 N20小游戏客人订单
    "UISailingChapter",                       ----90 大航海引导
    "UIFeatureScanControllerStep1",           --91 阿克希亚试用关机关列表点选1
    "UIFeatureScanControllerStep2",           --92 阿克希亚试用关机关列表点选2
    "UIN25VampireTalentTreeFirstItem",        --93 天赋树第一天天赋条目
    "UIN25VampireTalentTreeFirstItemTalent",  --94 天赋树第一条天赋的第一个天赋
    "UIBattleMultiSkillIndex1",               --95 仲胥 多主动技 技能1
    "UIBattleMultiSkillIndex2",               --96 仲胥 多主动技 技能2
    "UIN27PostInnerGameControllerFirstOrder", --97 信使小游戏第一个订单
    "UIN27PostInnerGameControllerFirstItem",  --98 信使小游戏第一个道具
    "UIN29DetectivePersonController",         --99 侦探小游戏保育员
    "UIActivityN29DetectiveMapController",    -- 100 侦探小游戏，第一个item
    "UIN29DetectiveReasoningOption1",         -- 101 侦探小游戏，选项1
    "UIN29DetectiveReasoningOption2",         -- 102 侦探小游戏，选项2
    "UIN29DetectiveReasoningOption4",         -- 103 侦探小游戏，选项3
    "UIBattleMultiSkillIndex3",               --104 多主动技 技能3
    "UIN32MultiLineMainFirstFolder",          --105 多周目，周目1
    "UIN32MultiLineMapControllerFirstDialog", --106 多周目，周目1
    "UIGradeInterfaceController_item_3rd",    ----107 觉醒界面，第三个物品（国服98）
    "UIActivityN33DateMainControllerBtn1",    ----108 N33小游戏建筑按钮1
    "UIActivityN33DateMainControllerBtn2",    ----109 N33小游戏建筑按钮2
    "UIActivityN33DateMainControllerBtn3",    ----110 N33小游戏建筑按钮3
    "UIActivityN33DateMainControllerBtn4",    ----111 N33小游戏建筑按钮4
    "UIActivityN33DateMainControllerBtn5",    ----112 N33小游戏建筑按钮5
    "UIActivityN33DateMainControllerBtn6",    ----113 N33小游戏提示按钮1
    "UIActivityN33DateMainControllerBtn7",    ----114 N33小游戏光灵按钮1
    "UISeasonS1CollectionTab",                ----115 赛季收藏品第一个
}
_autoEnum("GuideBtnType", GuideBtnType)
--endregion

---@class GuideTriggerClassName
local GuideTriggerClassName = {
    "BattleStartTrigger",                                   -- 1战斗开始
    "RoundTrigger",                                         -- 2回合
    "OpenUITrigger",                                        -- 3打开UI
    "PlayerHandleFinishTrigger",                            -- 4 玩家操作结束（播放动画之前）
    "PlaySkillFinishTrigger",                               -- 5释放技能完毕（播放动画之后，已过期）
    "LevelFinishTrigger",                                   -- 6关卡结束触发（回到关卡界面的时候触发）
    "GuideDoneTrigger",                                     -- 7触发后续引导
    "ShowGuideCancelAreaTrigger",                           -- 8显示取消连线按钮
    "PowerReadyTrigger",                                    -- 9主动技可释放
    "LoginTrigger",                                         -- 10登录触发
    "BattleCompleteTrigger",                                -- 11结算触发
    "PetGradeTrigger",                                      -- 12星灵觉醒
    "PetAwakeTrigger",                                      -- 13星灵突破
    "RoomEnterTrigger",                                     --14风船房间触发
    "ShowResSwitchTrigger",                                 -- 15双倍开关显示
    "MissionAutoBattleTrigger",                             --16主线自动战斗
    "ResAutoBattleTrigger",                                 --17资源本自动战斗
    "PlotEnterFinishTrigger",                               -- 18主线剧情关结束
    "LevelFinishAircraftTrigger",                           -- 19 关卡结束触发（回到关卡界面的时候触发并判断风船是否为未解锁状态）
    "LeaveAircraftTrigger",                                 -- 20 离开风船触发
    "PetGradeDoneTrigger",                                  -- 21 完成觉醒
    "OpenTeamUITrigger",                                    -- 22 打开编队界面
    "EntertainmentRoomUnlockTrigger",                       -- 23 娱乐区房间解锁
    "OpenAirRoomFacilityTrigger",                           -- 24 打开房间设施信息界面
    "OpenAirRoomSettleTrigger",                             -- 25 打开房间入驻界面
    "BuildAirRoomTrigger",                                  -- 26 建造完工作区房间
    "TaskStateTrigger",                                     -- 27 检查任务状态
    "BattleFinishTrigger",                                  -- 28 战斗结束后，结算界面前触发
    "PlaySkillRealFinishTrigger",                           -- 29释放技能完毕（播放动画之后）
    "PlaySkillRealFinishTriggerWithoutRoundLimit",          -- 30释放技能完毕（播放动画之后）-无回合限制
    "PlaySkillRealFinishTriggerWithoutRoundLimitWithTimes", -- 31释放技能完毕（播放动画之后）-无回合限制-指定技能释放次数
    "N28BounceGameArriveTarget",                            -- 32 N28小游戏，怪物达到指定目标
}
_enum("GuideTriggerClassName", GuideTriggerClassName)

---@class GuideTriggerType
local GuideTriggerType = {
    BattleStartTrigger = 1,                                    -- 战斗开始
    RoundTrigger = 2,                                          -- 回合
    OpenUITrigger = 3,                                         -- 打开UI
    PlayerHandleFinishTrigger = 4,                             --  玩家操作结束（播放动画之前）
    PlaySkillFinishTrigger = 5,                                -- 释放技能完毕（播放动画之后，已过期）
    LevelFinishTrigger = 6,                                    -- 关卡结束触发（回到关卡界面的时候触发）
    GuideDoneTrigger = 7,                                      -- 触发后续引导
    ShowGuideCancelAreaTrigger = 8,                            -- 显示取消连线按钮
    PowerReadyTrigger = 9,                                     -- 主动技可释放
    LoginTrigger = 10,                                         -- 登录触发
    BattleCompleteTrigger = 11,                                -- 结算触发
    PetGradeTrigger = 12,                                      -- 星灵觉醒
    PetAwakeTrigger = 13,                                      -- 星灵突破
    RoomEnterTrigger = 14,                                     --风船房间触发
    ShowResSwitchTrigger = 15,                                 -- 双倍开关显示
    MissionAutoBattleTrigger = 16,                             --16主线自动战斗
    ResAutoBattleTrigger = 17,                                 --17资源本自动战斗
    PlotEnterFinishTrigger = 18,                               -- 18主线剧情关结束
    LevelFinishAircraftTrigger = 19,                           -- 19 关卡结束触发（回到关卡界面的时候触发并判断风船是否为未解锁状态）
    LeaveAircraftTrigger = 20,                                 -- 20 离开风船触发
    PetGradeDoneTrigger = 21,                                  -- 21 完成觉醒
    OpenTeamUITrigger = 22,                                    -- 22 打开编队界面
    EntertainmentRoomUnlockTrigger = 23,                       -- 23 娱乐区房间解锁
    OpenAirRoomFacilityTrigger = 24,                           -- 24 打开房间设施信息界面
    OpenAirRoomSettleTrigger = 25,                             -- 25 打开房间入驻界面
    BuildAirRoomTrigger = 26,                                  -- 26 建造完工作区房间
    TaskStateTrigger = 27,                                     -- 27 任务状态
    BattleFinishTrigger = 28,                                  -- 28 战斗结束后，结算界面前触发
    PlaySkillRealFinishTrigger = 29,                           -- 释放技能完毕（播放动画之后）
    PlaySkillRealFinishTriggerWithoutRoundLimit = 30,          -- 释放技能完毕（播放动画之后）-无回合显示
    PlaySkillRealFinishTriggerWithoutRoundLimitWithTimes = 31, --释放技能完毕（播放动画之后）-无回合限制-指定技能释放次数
    N28BounceGameArriveTarget = 32,                            -- N28小游戏，怪物达到指定目标
}
_enum("GuideTriggerType", GuideTriggerType)
------------------- 零散------------------------------------
---@class GuideWeakLineConst 弱连线引导
local GuideWeakLineConst = {
    WaitTime = 1000, --玩家未进行任何操作，10秒后触发。弱连线引导
    OpenChapter = 2, -- 开启需要章节
    Duration = 0.5,
    PauseTime = 3
}
_enum("GuideWeakLineConst", GuideWeakLineConst)

---@class GuideGotoType
local GuideGotoType = {
    UIDiscovery = 1,    --  大地图关卡界面
    UIPlayer = 2,       --  角色界面
    UICard = 3,         --  抽卡界面
    UIQuest = 4,        --  任务界面
    UIMain = 5,         --  主界面
    UITeam = 6,         -- 编队界面
    UIHelp = 7,         -- 帮助说明
    UIAircraft = 8,     -- 风船
    FromAircraftTo = 9, -- 从风船跳转出去
    CloseCurUI = 10     -- 关闭当前Controller（非state）
}
_enum("GuideGotoType", GuideGotoType)

---@class GuideModelType
local GuideModelType = {
    Monster = 1,     --  怪物
    Trap = 2,        --  机关
    ChessPet = 3,    -- 战旗
    ChessMonster = 4 -- 战旗怪物
}
_enum("GuideModelType", GuideModelType)

---@class GuideCircleType
local GuideCircleType = {
    Grid = 1,             --  格子
    Monster = 2,          --  怪物
    Trap = 3,             -- 机关
    Finger = 4,           --手指
    AirPet = 5,           -- 风船星灵
    AirSmelt = 6,         -- 风船熔炼炉
    AirSandBox = 7,       -- 风船派遣室沙盘
    AirTactic = 8,        -- 风船战术室
    ClickGrid = 9,        -- 格子点击
    SeasonEventPoint = 10 --赛季事件点
}
_enum("GuideCircleType", GuideCircleType)

---@class GuideGameCommandType
local GuideGameCommandType = {
    SkillReady = 1 -- 技能cd清零
}
_enum("GuideGameCommandType", GuideGameCommandType)

GuideConst = {}
GuideConst.StartPos = function(startPos)
    if not startPos then
        if not GuideConst._startPos then
            GuideConst._startPos = Vector3(ResolutionManager.RealWidth() * 0.5, 20, 0)
        end
        return GuideConst._startPos
    else
        GuideConst._startPos = startPos
    end
end

GuideConst.guide_team_clear_guideid = Cfg.cfg_guide_const["guide_team_clear_guideid"].ArrayValue
GuideConst.EffectLayer = 18
GuideConst.AircraftGGuideId = 2003
