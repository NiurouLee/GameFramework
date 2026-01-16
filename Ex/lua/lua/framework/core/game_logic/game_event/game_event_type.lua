---@field ConnectReset number
---@field HomelandCloseBreedUI number

---@class GameEventType
GameEventType = {
    --网络层消息
    "GameLogin",
    "GameLogout",
    "VersionStatus",
    "ModuleInit",
    "RoleLogin",
    "AppHome",
    "AppReturn",
    "AppResume",
    "ApplicationQuit",  --编辑器里停止游戏
    "ApplicationFocus", --10应用失去/获得焦点
    "AskPopupReset",
    "PopupReset",
    "LoginReset",
    "AuthReset",
    "BackToAuth",
    "CallBegin",
    "CallEnd",
    "RequestTaskFinish",
    "ReceiveMessage", --收到消息
    "CallTimelong",   --20
    "CallTimeout",
    "ConnectDone",
    "ConnectFail",
    "ConnectClose",
    "TaskError",
    "None",
    "SwitchUIStateFinish",
    "UpdateLayerTopDepth",
    "AfterUILayerChanged",
    "UIBlackChange",
    "UIBangWidthChange",
    --30
    "LoadingProgressChanged",
    "LoadLevelEnd",
    "MatchStart",
    "MatchEnd",
    "AchieveUpdate",
    "QuestUpdate",
    "MSDKAutoAuthority", --MSDK自动鉴权
    "LoginIdipActive",
    "DemoTestEvent",
    "PushNotification",
    --40
    "CardRoleListPanelShowAvatar",
    "ItemCountChanged",      --道具数量变化
    "DiamondCountChanged",   --耀晶数量变化
    "OpenGiftReward",        -- 打开礼包后回调
    "MissionInfoChange",     --关卡信息变化
    "MissionFightResult",    --主线关卡战斗结果
    "IncidentInfoChange",    --收到事件信息变化
    "IncidentFiahtResult",   --通过关卡后战斗结果
    "ExtMissionFightResult", --番外战斗结果
    "TalePetFightResult",    --传说试炼关卡战斗结果
    "LostAreaFightResult",   --传说试炼关卡战斗结果
    "MazeFightResult",       --50秘境探索结果
    "CampaignFightResult",   --活动关卡战斗结果
    "BeforeRelogin",         --断线重连，点击按钮后切换到登录界面之前抛出消息
    "WatchPetSkinStory",     --观看光灵皮肤剧情
    --60

    "PinchIn",
    "PinchOut",
    ---UI--------
    "DiscoveryCameraMove",
    "DiscoveryPlayerMove",
    "DiscoveryNodeStateChange",
    "DiscoveryNodeNextTargetChange",
    "DiscoveryChangeTeamData",
    "DiscoveryShowHideChapter",
    "DiscoveryInitUIStage",
    "DiscoveryFlushChapter",
    "DiscoveryFlushLines",
    "CheckPartUnlock",
    "FlushChapterPreview",
    "DiscoveryShowHideUICanvas",
    "DiscoveryShowHideUIStage",
    "UpdateChapterAwardData",
    "TeamSelectItem",
    "TeamItemShowSlot",
    "TeamToggleIsOnChanged",
    "TeamItemLongPress",
    "TeamUpdateReplaceCardPos",
    "ShowItemTips",
    "FlushSkillScope",
    "OnUISkillScopeClose",
    "UIPlotClickItem",
    "UIQuestStoryDetailClosed",
    "ChangeBindBtnStatus",
    --HeadBar
    "RolePropertyChanged",
    --UIpet
    "PetSortLaterEvent",
    "PetUpLevelEvent",
    "PetUpGradeEvent",
    "PetAwakenEvent",
    "PetDetailChangeCgState",
    "PetDataChangeEvent",
    "AutoTestClose",
    --番外
    "ExtraMissionPetHeaderClick",
    "ExtraMissionPetHeaderClick2",
    "ExtraMissionNodeClick",
    "CancelRedPoint",
    "HideNew",
    "ExtMissionInitUIStage",
    "ExtraMissionChangeItemState",
    --风船
    "AircraftEnterClearPetList",
    "AircraftRefreshMainUI",
    "AircraftRequestDataAndRefreshMainUI",
    "AircraftRefreshRoomUI",
    "AircraftRefreshTopbar",
    "AircraftBackToMain",
    "AircraftSettledPetChanged",
    "SwitchToInteractiveView",
    "AircraftSelectPetEvent",
    "AircraftShowInteractiveUI",
    "AircraftAddPetFavorable",
    "AircraftLeaveAircraft",
    "AircraftInteractiveEventRewardShowItemTips",
    "AircraftEnterBuildChangeSort",
    "AircraftEnterBuildChangeFilter",
    "AircraftPlayOpenDoor",
    "AircraftPlayCloseDoor",
    "AircraftPlayDoorAnim",
    "AircraftGuideFinger",
    "AircraftJumpOutTo",
    "AircraftOnFireFlyChanged",
    "AircraftOnAmbientChanged",
    "AircraftAmbientSetActive",
    "AircraftOnAtomChanged",
    "AircraftCleanSpace",
    "AircraftBuildRoom",
    "AircraftSpeedUp",
    "AircraftShowRoomUI",
    "AircraftTryRefreshRoomUI",
    "AircraftTryStopClickAction",
    "AircraftAreaFurnitureUpdate",
    "SetAircraftMainUI",
    "AircraftEnterDecorateMode",   --进入装扮模式
    "AircraftRefreshDecorateArea", --刷新装修区域
    "AircraftSelectDecorateArea",  --选择某个装修区域
    "AircraftLeaveToBattle",       --离开风船到局内
    --技能预览
    "CloseSkillScope",
    "OnCreateMe",
    "PropertyUpdate",       --角色属性
    "RoleLevelUp",          --升级
    "FuncOpen",             --开启功能
    "GuideDone",            --完成引导
    "GuidePosChanged",      --引导位置变化
    "UIOpen",               --打开界面
    "UIClose",              --关闭界面
    "NewItem",              --获得新道具
    "ChangePetActiveSkill", --修改星灵主动技能
    "SetCurPickExtraParam",
    --通知当前预览点选额外参数（罗伊，是否点选机关时的能量消耗不同）
    "AddNewBattlePet",
    --引导
    "ShowGuideMask",
    "GuideActiveSkill",
    "GuideGradeUpDone",
    "GuideOpenTeamUI",
    "ShowPetInfo",
    --隐藏对局宝宝头像
    "CloseResInstance", --
    --秘境探索
    "MazeInfoUpdate",
    "OnLeaveMaze",
    "TeamMemberChanged",
    "OnPassRestRoom",
    "MazeJumpOutTo",
    "MazeReset",
    --
    "ResDungeonFightResult",
    -- 尖塔结算
    "TowerFightResult",
    "TowerLayerOnSelect",
    -- 商城
    "ChangeShopBg",
    "ShopTabChange",
    "ShopBuySuccess",
    "ShopNew",
    "MatchError",
    --新手引导
    "ShowGuideWarn",
    "ShowGuideCondition",
    "GuideBattleStart",             -- 战斗开始触发（刷怪前）
    "GuideRound",                   -- 某回合触发
    "GuideOpenUI",                  -- 首次开启界面触发
    "GuidePlayerHandleFinish",      -- 玩家操作结束（播放动画之前）
    "GuidePlayerSkillFinish",       --  释放技能完毕（播放动画之后已过期）
    "GuidePlayerSkillRealFinish",   --  释放技能完毕（播放动画之后新版本）
    "GuideLevelFinish",             --关卡结束触发（回到关卡界面的时候触发）
    "ShowGuideCancelArea",          -- 显示取消连线区域
    "ShowGuidePowerReady",          -- 能量满
    "GuideLogin",                   --登录
    "GuideBattleComplete",          -- 结算触发
    "ShowGuideStep",                -- 显示引导step
    "FinishGuideStep",              -- 结束引导step
    "ForceFinishGuideStep",         -- 强制结束引导step(慎用!!)
    "PauseGuideWeakLine",           -- 暂停弱引导连线
    "FinishGuideWeakLine",          -- 结束弱引导连线
    "ShowGuideInnerAttr",           -- 局内宠物属性按钮
    "GuideYield",                   -- 引导阻塞
    "GuideUnLock",                  -- 新手引导功能解锁
    "GuideGrade",                   -- 引导星灵突破
    "GuideAwake",                   -- 引导星灵觉醒
    "ShowGuideFailed",              -- 引导失败
    "GuideRoomEnter",               -- 触发风船房间进入
    "GuideShowResDouble",           --显示双倍卷货币栏通知
    "GuideChangeGhostLayer",        --引导删除幽灵
    "GuideMissionAutoBattle",       --主线自动战斗
    "GuideResAutoBattle",           --主线自动战斗
    "GuidePlayerShow",
    "GuidePlotEnterFinish",         --主线剧情关结束
    "GuideLevelFinishAircraft",
    "GuideLeaveAircraft",           -- 触发离开风船
    "GuideEntertainmentRoomUnlock", -- 娱乐区房间解锁
    "GuideOpenAirRoomFacilityUI",   -- 打开风船设施信息界面
    "GuideOpenAirRoomSettleUI",     -- 打开风船入驻界面
    "GuideBuildAirRoom",            -- 建造完房间
    "GuideTaskState",               -- 任务状态变化
    "GuideBattleFinish",            -- 战斗结束后，结算界面前触发
    "N28BounceGameArriveTarget",
    --新手引导
    "ModuleUnlocked", --功能解锁
    "FunctionUnLock", --功能解锁UI消息
    --任务
    "UIQuestControllerChangeCanvasGroup",
    "UIQuestSideRefrenshIndex",
    "UIQuestOnBigTypeBtnClick",
    "UIAchievementFinish",
    "AchieveOnGot",
    "RefreshSideQuestList",
    "RefreshDailyQuestList",
    "CheckQuestRedPoint",
    "CheckCardNew",
    "CheckCardAwakeRedPoint",
    "ChangeQuestController",
    "UIQuestDailyReset",
    "UIQuestWorldBossRest",
    "UIQuestDailyVigorous", -- 日常任务界面活跃度重置消息
    "QuestAchiUpdate",
    "QuestMedalUpdate",     --勋章成就
    "OnUIGetItemCloseInQuest",
    "OnUIPetObtainCloseInQuest",
    "OnUIPetObtainCloseInMain",
    "ComplateListQuest",
    --防沉迷
    "IndulgeDataEvent",
    "IdipBanDataEvent",
    "ClosePetAudio",               --关闭pet语音
    --邮件
    "ModuleMailNotifyNewMail",     -- 有未读邮件
    "ModuleMailNotifyExpiredMail", -- 有过期邮件
    "RefreshMailStatus",           --刷新是否有新邮件状态
    --公告
    "UINoticeItemClick",
    --助理
    "OnAssistantPetItemClick",
    "OnAssistantChanged",
    -- 风船红点检测通知 CEventPushAircraftInfo
    "AircraftRedPoint",
    --改变攻防血
    "ChangePetAtkDefHp",
    --资源本双倍通知
    "ChangeResDouble",
    "NetWorkRetryStart",
    "NetWorkRetryEnd",
    --空界面
    "OnUIEmptyClose",
    --星灵升级
    "OnPetLevelUpFirst",
    "OnPetLevelUpSecond",
    --公告
    "OnNoticeDataCheckNew",
    --星灵详情
    "CheckIsCurrent",
    --埋点
    "SetDataPoint",
    --游戏行为记录
    "RecordAction",
    --模拟输入事件
    "FakeInput",
    --通知UI打开
    "UIShowEnd",
    --个人信息
    "OnChangeHeadTagBtnClick",
    "OnPlayerChangeHeadItemClick",
    "OnPlayerChangeHeadBgItemClick",
    "OnPlayerChangeHeadFrameItemClick",
    "OnPlayerChangeHeadBadgeClick",
    "OnPlayerHeadInfoChanged",
    "OnChapcterInfoChanged",
    --纹饰修改
    "OnEmblazonryItemSelect",
    "OnPlayerEmblazonryChange",
    --称号修改
    "OnTitleItemSelect",
    "OnPlayerTitleInfoChanged",
    "RefreshPlayerInfoRedPoint",
    "HideHeadRedPoint",
    "HideHeadFrameRedPoint",
    "NoticeBackPackRed",  --背包红点
    "CloseUIBackPackBox", --关闭UIBackPackBox
    --任务奖励tips
    "QuestAwardItemClick",
    --uibattlehp
    "OnPetHpChangedInMaze",
    "OnPetDeadChangeHeadPos",
    --uplevelscrollview
    "UpLevelCheckIsCurrent",
    "BreakCheckIsCurrent",
    "GradeCheckIsCurrent",
    --打开个人信息，主界面立绘隐藏
    "OnPlayerInfoOpen",
    --成长任务关闭
    "OnCloseGrowthPanel",
    --终端占--
    "WeChatNormalState",
    "WeChatReplyState",
    "WeChatAddAnswerState",
    "WeChatWaitState",
    "WeChatWaitEndState",
    "WeChatVoiceState",
    "WeChatReaded",
    "WeChatChangeName",
    "WeChatUpdateRole",
    "WeChatPlayVoice",
    "UpdateWeChatRed",
    "UpdateWeChatMainTalk",
    "WeChatUpdateLastTime",
    --终端占---
    --PetScrollViewList
    "OnPetListIndexChanged",
    "ResetBattleTeam",
    --突破
    "OnAwakenSelectPointChange",
    "SelectRecentFriend",
    "ReceiveChatMessage",
    "DeleteFriendUI",
    "TalePetBuffChange",
    --社交
    "UpdateFriendInfo",           -- 好友数据变更
    "UpdateInvitationList",       -- 好友申请列表数据变更
    "UpdateFriendInvitation",     -- 有新的好友申请
    "ModuleFriendNotifyNewMsg",   -- 通知主界面有新消息
    "InModuleFriendNotifyNewMsg", -- 模块内有收到其他好友发来的消息提醒
    "TargetFriendNewMsg",         -- 选中好友有新消息 直接推送   参数:1. list<chat_message_info> 2. sender_pstid
    "ChatFriendNotYourFriend",
    "ChangeFriendInfoSuccess",
    "UpdateChatBlackList",
    --更新未读消息
    "UpdateUnReadMessageStatus",
    --风船点击星灵
    "AircraftOnPetClick",
    --送礼中
    "AircraftChangeGiftSending",
    --送礼成功
    "AircraftOnSendGiftSuccess",
    --风船星灵触发随机事件
    "AirStartOneRandomEvent",
    --强行触发社交
    "AirForceTriggerSocialAction",
    "OnGameOver",
    "AircraftUILock",
    "ShowResDetailBuffInfo",
    --风船送礼
    "OpenSendGiftDiaLog",
    --觉醒
    "PetUpGradeChangeCgEvent",
    "OnPetUpGradeThird",
    --详情动画
    "PlayInOutAnimation",
    "DumpSyncLog",
    "RefreshMVPText",
    --秘境换队长
    "MazeChangeTeamLeader",
    "ForceRemoveInteractivePets",
    "SendGiftRandomStory",
    "CloseSendGiftBtn",
    --air
    "RandomStoryStartOrEnd",
    "OnLevelUpAttValueChanged",
    --公告
    "OnNoticeDataCheckNew",
    --装备
    "OnEquipDataChanged",
    --风船打开房间
    "AircraftOpenRoom",
    --风船装扮
    "UIAircraftDecorateBigTabClick",       --点击一级标签
    "UIAircraftDecorateSmallTabClick",     --点击二级标签
    "UIAircraftDecorateRefreshAtmosphere", --刷新氛围
    "UIAircraftDecorateSelectItem",        --家居选中
    "UIAircraftDecoratePutFurniture",      --家居摆放
    "UIAircraftDecorateSwitchModel",       --家居摆放切换模式 true是打开装备列表 false是关闭家居列表,进入摆放
    "UIAircraftDecorateRefreshRoomTitle",  --刷新摆放界面的房间名字
    "UIAircraftShowRotater",               --显示家具旋转控制器
    "AircraftMainMoveCameraToNavMenu",
    "UpdateDispatchTaskSiteInfo",
    "UpdateDispatchTaskItemInfo",
    --风船挪相机
    "AircraftMainMoveCameraToNavMenu",
    "SetCameraToNavMenuPos",
    "RefreshNavMenuData",
    "AircraftDeletePet",
    "AircraftPushPetQueue",
    "UpdateDispatchPetList",
    "UIAirNavMenuActive",
    "GuideYieldBreak", -- 强制取消引导阻塞
    --刷新飘字
    "RefreshToast",
    --剧情任务解锁通知
    "OnNewStoryQuestUnLock",
    "StoryQuestLock",
    --书籍事件
    "UpdateBookRedPointStatus",
    --觉醒动画
    "PlayAnimation_UIGradePetDetailItem",
    --签到
    "OnTotalAwardGot",
    "ChangeMainBg",
    "OnPlayerChangeHeadFrameItemClick",
    --region Pay
    "ShowHideTSFBtn",                 --显隐特商法按钮
    "ShowHideLimitedTimeRechargeBtn", --显隐限时充值按钮
    "OpenShop",                       --打开某种商店
    "PayGetLocalPriceFinished",       --拉取价格完成
    "UpdateRechargeShop",             --刷新充值商店条目
    "UpdateGiftPackShop",             --刷新礼包商店条目
    "UpdateRechargeItemPrice",        --刷新耀晶价格
    "UpdateGiftPackItemPrice",        --刷新礼包价格
    "UpdateRechargeItemPresent",      --刷新耀晶赠送数
    "UpdateSkinsShop",                --刷新时装商店条目
    "UpdateSkinsItemPrice",           --刷新时装价格
    "ForceShowMainTabBtn",            --强制显示某主页签按钮（时装按钮随广告页刷新出现）
    "UpdateHomelandShop",             --刷新家园商店条目
    --endregion
    "CancelSerialAutoFight",          --取消连续自动战斗
    "SerialAutoFightWaitTime",
    --连续战斗跳转时间
    "MainLobbyShown",
    "MainLobbyOpenListFinish",        ---主界面自动弹出列表弹出完毕
    "SideEnterRefresh",               ---活动中心，刷新
    "ActivityCloseEvent",             --活动已关闭事件
    "ActivityComponentCloseEvent",    --活动 组件已关闭事件
    "ActivityDialogRefresh",          ---活动 同时打开多个窗口之间通知刷新事件
    "ActivityShopBuySuccess",         ---活动 兑换商店购买成功
    "OnActivityTotalAwardGot",        ---活动 累计登录领取成功
    "OnActivityTotalAwardCellSelect", ---活动 累计登录奖励条目选中
    "ActivityShopNeedRefresh",        ---活动 兑换商城 刷新
    "CampaignComponentStepChange",    ---活动 组件step更新
    "CampaignShopEnter",              ---活动 打开了兑换商店
    "ActivityQuestAwardItemClick",    ---活动 任务界面点击奖励物品
    "ActivityCurrencyBuySuccess",     ---活动 直购 返回成功
    "ActivityNormalBuyResult",        ---活动 普通购买 返回结果
    "ColorBlindSelect",               ---色盲模式选择
    "ColorBlindUpdate",               ---色盲模式更新
    ---------------传说光灵--------------------
    "TalePetInfoDataChange",          ---光灵数据变化
    "TalePetTrailLevelRewardChange",  --关卡奖励变化
    "TalePetRedStatusChange",         --主界面红点状态改变
    "TalePetDetailReturnList",        --界面返回跳转
    ---------------传说光灵end-----------------
    "OnTempSignInAwardGot",
    "SetEditorInfoShowType", --设置编辑器辅助信息
    --cg
    "OnCgBookListItemClick",
    "SummerTwoRewardRefresh",
    --summer2
    "OnSummerActivityPlotSelect",
    "OnSummerActivityTwoLevelUIClose",
    --skin
    "OnCurrencyBySkinSuccess", --直购皮肤返回成功
    "OnPetSkinChange",         --光灵更换皮肤
    "UIAircraftResolveItemOnclick",
    --夏活2主界面登录剧情红点
    "SummerTwoLoginRed",
    "SummerTwoPlotRed",
    "CheckMonthCardRedpoint",
    "CutsceneFinish",
    "PredictionStateChanged", --预告状态更新
    "PredictionDataChanged",  --预告数据更新
    "GrassClose",             --长草活动关闭
    --夏活2星灵试用
    "OnSummerTwoPetTryItemClick",
    --送礼升级
    "OnSendGiftAndLevelUp",
    --N+6
    "NPlusSixBuildingMainRefresh",
    "NPlusSixBuildingBuildingComplete",
    "NPlusSixBuildingAllBuildingComplete",
    "NPlusSixBuildingRewardGet",
    "NPlusSixMainRefresh", --N+6主界面刷新
    "NPlusSixShowEventRewardTips",
    "NPlusSixShowEventCompleteRewardTips",
    "NPlusSixEventRefresh",
    "NPlusSixEventComplete",
    "NPlusSixEventInfoItemClick",
    "ConnectReset",
    --迷失之地关卡选中事件
    "OnUILostLandStageItemClick",
    --迷失之地重置
    "OnLostLandTimeReset",
    --选中某一张星灵卡牌
    "OnSelectUIHeartItem",
    --无双结算
    "ConquestFightResult",
    --N5
    "N5ProgressScrollDragBegin",
    --主界面自动弹出相关
    "MainLobbyAutoOpenTryFail",
    --打开界面时失败
    "OnUIWeekTowerNodeItemClick",
    "WorldBossDanResult", --世界Boss段位结算
    --N7刷新活动主界面
    "ActivityN7MainRefresh",
    "BlackFistResult",
    "EnemyPetCastActiveSkill",
    "BlackFistUpdatePaperRed",
    "OnUIGMCheatCommand",
    --风船战术室
    "AircraftTacticOnSelectItemChanged",
    "AircraftTacticRefreshTapeList",
    "AircraftTacticOnTapeChanged",
    "AircraftTacticTapeCancelNew",
    --巅峰rank
    "OnTopRankGetAward",
    --资料库
    "OnDataBaseInfoUnLock",
    "OnDataBaseInfoGetAward",
    "OnDataBaseInfoItemClick",
    --秘境扫荡
    "OnQuickFightClose",
    "OnChooseCardClose",
    --N9事件
    "OnN9SubjectRewardItemClicked",
    "OnN9SubjectRefresh",
    --修改主界面立绘偏移
    "OnMainCgChangeSave",
    "OnMainCgChangeScale",
    "OnMainCgChangePos",
    "OnShowChangeMainCg",
    "OnN9SelectClick",
    "OnN9PauseClick",
    --多开礼包
    "OnOpenGiftsSucc",
    --看板娘new
    "OnRemoveAsCardNew",
    --n12地图窗口关闭
    "OnN12CloseMapWindow",
    "OnN12CloseMap",
    "OnAffixScoreChange",
    --N14小游戏事件
    "OnN14FishingGameRewardItemReceived",
    "OnN14FishingGameRewardItemClicked",
    "OnUIWeekTowerDiffItemClick",
    "BattleUIShowHideSelectTeamPositionButton",
    "BattleUISelectTargetTeamPosition",
    "ClearSelectedTeamOrderPosition",
    "OnN16SubjectRefresh",
    "OnN16SubjectRewardItemClicked",
    "OnN16PauseClick",
    "OnN16SelectClick",
    --主界面隐藏助理
    "OnMainLobbyHideAssistant",
    "OnCloseMinigame", --小游戏关闭
    -- "SeniorSkinHideTip"

    --沉默buff
    --家园事件
    "ShowHideHomelandMainUI",
    "EnterBuildInteract",
    "LeaveBuildInteract",
    "RefreshInteractUI",
    "ShowInteractUI",
    "HideInteractUI",
    "HomelandShopUpdate",           --家园商店刷新
    "ShowHideListSequence",         --家园打造显隐列表或打造列表
    "HomelandForgeUpdateSequence",  --刷新打造列表
    "HomelandForgeUpdateList",      --刷新建筑列表
    "HomelandForgeFoldFilter",      --打造界面开关一级页签
    "HomelandForgeFoldFilterChild", --打造界面开关二级页签
    "HomelandBackpackFoldFilter",
    "HomelandBackpackSelectItem",
    "OnHomePetInner",                --星灵进入交互范围
    "OnHomeInteractClose",           --交互界面关闭
    "OnHomeInteractFollow",          --星灵跟随
    "HomeBuildOnSelectBuilding",     --选中一个建筑
    "HomeBuildOnAmbientChanged",     --建筑宜居值改变
    "HomelandBuildFilterTab1",       --点击放置界面一级页签
    "HomelandBuildFilterTab2",       --点击放置界面二级页签
    "HomelandShowHideDragItem",      --通知显示隐藏拖动模块
    "DragBuildingIntoScene",         --通知拖拽到场景中
    "HomelandRefreshBuildFilterNew", --刷新摆放模式页签new标记
    "HomelandBuildChangeSkin",       --摆放模式换肤
    "HomelandBuildOnSaveBuilding",   --保存建筑
    "HomelandBuildOnSave",           --保存建筑
    "OnUIHomePhotoItemClick",
    "OnItemUpgrade",
    "HomelandLevelClickLevelItem",    --家园等级：点击等级item刷新界面
    "HomelandLevelOnLevelInfoChange", --家园等级：家园等级信息推送
    "HomeBuildingSwimmingUnlock",
    --家园图鉴
    --家园主角开始移动
    "OnMainCharacterStartMove",
    "HomelandSetMainCharReceiveMoveInput",
    --钓鱼相关
    "ChangeFishingStatus",             --钓鱼状态改变
    "FishingStartThrow",               --开始抛鱼竿
    "FishingThrowPower",               --丢出鱼竿
    "FishingCollect",                  --收杆
    "FishingSuccess",                  --钓鱼成功
    "FishingFailure",                  --钓鱼失败
    "FishingFloatPositionChange",      --鱼漂位置更新
    "FishingPowerChange",              --钓鱼力量变化
    "FishingAddFishingPosition",       --增加钓鱼点
    "FishingRemoveFishingPosition",    --删除钓鱼点
    "FishingRefreshFishingPosition",   --刷新鱼点
    "FishingCancelFish",               --取消钓鱼
    "FishThrowResult",                 --抛竿失败成功事件
    --钓鱼比赛相关
    "FishMatchReady",                  --钓鱼比赛准备
    "FishMatchStart",                  --钓鱼比赛开始
    "FishMatchEnd",                    --钓鱼比赛结束
    "FishMatchScore",                  --钓鱼比赛 得分
    "FishMatchPetScore",               --钓鱼比赛 光灵得分
    "FishMatchPetChangeFishingStatus", --钓鱼比赛 光灵钓鱼状态改变
    "FishMatchHideDash",               --钓鱼比赛隐藏Dash按钮
    --家园事件
    "HomeLandEventChange",             -- 事件变更（星灵移除宿舍）
    --家园功能解锁
    "HomeLandFunctionUnlock",          -- 某个功能解锁 参数为功能type HomelandUnlockType
    --家园探宝发现宝物
    "OnHomeEventTips",
    --探宝木牌弹窗
    "ShowTreasureBoardUI",
    "WishingAddCollectCoin",    --增加金币
    "WishingAddFish",           --增加鱼
    "WishingRemoveFish",        --删除鱼
    "WishingRefreshFish",       --刷新鱼
    "AquariumAddFish",          --水族箱增加鱼
    "AquariumRemoveFish",       --水族箱删除鱼
    "AquariumRefreshFish",      --水族箱刷新鱼
    "SetInteractPointUIStatus", --设置交互点状态
    "UIPetFilterCardsOnSelect", --星灵筛选界面，选择1张卡牌
    "HomeDomitoryRefreshRoom",  --刷新当前宿舍界面
    "ResetOneBuilding",         --刷新1个建筑
    "OnHomeMainShowUIRoot",     --星灵交互隐藏主界面UI
    "RoleChangeTeamLeaderFinish",
    "EnterFindTreasure",        --进入寻宝小游戏
    "ExitFindTreasure",         --离开寻宝小游戏
    "FindTreasureFailure",      --寻宝失败
    "FindTreasureSuccess",      --寻宝成功
    "TreasureRemove",           --挖宝事件更新
    "OnUIHomeEventTips",
    --家园跑马灯事件
    "HomelandOreRefresh",
    --矿石刷新事件
    "HomelandRefreshOreInfo",
    "HomeStorehouseGiftItemOnSelect", --家园仓库选择礼物
    "MinimapAddIcon",                 --增加小地图中的图标
    "MinimapRemoveIcon",              --删除小地图中的图标
    "MinimapClickIcon",               --点击小地图中的图标事件
    "MinimapCloseDetailUI",           --关闭小地图建筑点详情界面事件
    "MinimapUpdate",                  --更新小地图
    "MinimapSwitch",                  ---切换地图
    "UIHomeVisitAddGift",             --添加礼物到仓库
    "OnHomeLandDiaryGotoPage",        -- 跳转日记簿
    "HomeShowUIBubble",               --家园ui气泡
    "OnHomePetFollow",
    --跟随变化消息
    "OnHomeLandTaskFinished",
    --家园任务完成
    "PlayerControllerUIStatus", --设置控制角色按钮现因
    "SetMinimapStatus",         --设置小地图状态
    "OnHomeStoryFinish",
    "OnUpdatePerFrame",
    "OnHomeLandTaskSubmit",
    "OnHomeLandTaskGroupSubmit",
    "OnHomeLandTaskGroupSubmitAfterReward",
    "HomeAfterCollectLevelReward",
    "OnGetTracePoint",
    "OnLeaveTracePoint",
    "TracePointInOutMiniMap", --空庭小地图任务追踪点动画
    --家园navmesh
    "OnHomelandNavmeshUpdated",
    "OnHomeBuildRotateOpen",
    "HomelandCloseBreedUI",
    --子界面通知关闭培育界面
    "OnHomeLandSpecialCheck",
    --任务检查特殊处理
    "OnAddMinimapIconMark",               --增加小地图提示
    "OnInitMinimapIconMark",              --初始化小地图提示
    "OnRemoveMinimapIconMark",            --删除小地图提示
    "HomelandBreedPhasesChange",          --培育阶段变化
    "OnUIHomePetInteract",                --打开剧情
    "HomelandFriendSpeed",                --培育好友加速
    "FlushDiffNodes",
    "HomelandInteractPointUIRefresh",     --交互按钮UI变化
    "CloseHomeStory",                     --关闭专用剧情
    "ExitHomeland",                       --退出家园
    "OnChangeUIHomelandButtonSprintShow", --显示关闭家园主角冲刺按钮
    --n19p5
    "OnUIN19P5SignInGet",
    --签到
    "N19P5SignInRed", --
    --跳过处决动画
    "OnN19P5SkipBigView",
    --n20事件
    "N20RefreshRedAndNew",          --刷新红点和NEW
    "N20RefreshShopBtnStatus",      --刷新商店按钮状态
    --region AVG
    "AVGOnDialogEnd",               --AVG剧情一句对话结束
    "AVGShowOption",                --AVG剧情显示选项
    "AVGShowHideOptionInfluence",   --AVG剧情，显隐选项影响
    "AVGFlushNewRed",               --AVG刷新New和Red
    --endregion
    "OnTalkCheck",                  -- 任务 光灵对话
    "OnUIHomePetInteractTaskClose", -- 任务 光灵对话关闭
    "UIHomelandStoryTaskBtnSelect",
    "UIHomelandStoryTaskGroupSelect",
    --region 活动回顾
    "UIReviewOnUnlock",               --解锁
    "UIReviewRefreshRedpoint",        --刷新单个活动红点
    "UIReviewOnDownloadStateChanged", --刷新单个活动红点
    "UIReviewOnDownloadStart",        --开始下载
    --endregion
    "HandleStoryTaskUpdate",          -- 剧情任务 更新
    "StoryTaskChangeState",           -- 剧情任务
    "StoryTaskTraceSuccess",          -- 剧情任务 追蹤成功
    "OnHomePetFollowClick",
    "StoryChooseOption",              -- 剧情选项事件
    --家园跟随阵型
    --无
    "N21CCRefreshRedAndNew",
    "N21CCRefreshItemList",
    "N21CCShopRewardItemClick",
    "N21CCClearAllSelectAffix",
    "N21CCRefreshLevelStatus",
    "OnPetInvitePreview",                -- 家具邀请
    "OnPetBehaviorInteractingFurniture", -- 当光灵进入家具交互状态
    "N21CCGetScoreReward",               --N21危机合约领取奖励
    "N21CCPlayMainFocusAnim",            --N21危机合约返回主界面动画播放
    "OnHomePetInteractCloseForInivte",
    -- 家具邀请相关

    "MedalUpdate",                         --勋章更新
    "BoardMedalUpdate",                    --保存板上勋章信息，换勋章板
    "SailingMissionLayerInfoChanged",      -- 大航海层数据更新事件
    "SailingGetProgressReward",            -- 大航海 领取奖励通知
    "SailingOnProgressRewardCellSelect",   -- 大航海 探索奖励 选中条目
    "SailingOnProgressRewardBannerClick",  -- 大航海 探索奖励 点击banner
    "ShowHideHomelandAllUI",               --显示隐藏家园主界面所有UI
    --n25吸血鬼
    "N25VampireSelectTalentSkill",         --选中天赋技能消息
    --n25偶像养成
    "N25IdolStartPlayGame",                --成为偶像开始游戏
    "N25UpdateTalentData",                 --天赋数据更新
    "N25IdolGameNextDay",                  --偶像养成界面进入新的一天
    "OnN25FansChange",                     --完成偶像活动
    "OnN25IdolCheckState",                 --界面关闭回调
    --拍电影
    "MovieMakerPrepareFinish",             --拍电影准备完成
    "MovieRepalyPrepareFinish",            --回放电影准备完成
    "MovieRepalyPrepareFinish",            --回放电影准备完成
    "UIHomelandMoviePrepareItemSelect",    --回放电影
    "UIHomelandMoviePrepareTitleBtnClick", --回放
    "UIHomelandMoviePrepareItemBtnClick",  --回放
    "UIHomelandMovieSelectBtnClick",       --回放电影准备完成
    "UIHomelandMovieSaved",                --电影保存完成
    "UIHomelandMovieReplaceRecordSelect",
    "UIHomelandMoviePrepareActorSelected",
    "UIHomelandMoviePrepareItemsSelected",
    "OnHomelandTaskItemChanged",
    "OnOneAndHalfAnniversaryFinish",
    "OnVampireChallengeTaskItemRewarded",
    "OnVampireChallengeTaskItemClick",
    "OnVampireTalentSkillTipsClose",
    "OnN26ActivityMainRedStatusRefresh",
    "OnN26CookMakeSucc", --年夜饭美食制作成功
    --LI
    "ActiveUILoginLIRoot",
    --N27
    "OnN27PostGameItemTypeChange",
    "OnN27PostGameItemPress",
    "OnN27PostGameItemRelease",
    "OnN27PostGameBlockHovered",
    "OnN27PostGameBlockPress",
    "OnN27PostGameBlockRelease",
    -- N27
    "OnN27MinigameRewardItemReceived",
    "OnN27MinigameRewardItemClicked",
    "OnCampDiffTeamReset", --活动高难关编队清空
    "OnCampDiffTeamResetInternal",
    -- N28
    "OnN28ActivityMainRedStatusRefresh", --刷新主页面红点
    "AVGGainEvidence",
    "AVGShowEvdience",
    "AVGStopAutoState",
    "AVGHideEvdienceBook",
    "AVGSelectEvidenceItem",
    "AVGSelectBookEvidenceItem",
    "AVGSelectCollectionEvidenceItem",
    "OnN28ActivityMinigameGetReward",
    "ActivityMainStatusRefreshEvent",
    --周活跃度重置
    "OnWeekRewardChanged",

    "SwitchUseBoxItem",
    "WaitForRecuitSceneLoadFinish", --等待抽卡场景加载完成
    "RefreshRecuitUIView",          --刷新卡池
    "OnPetFilterTypeChange",
    "ShopForceRefresh",
    "OnOpenWorldBossMultiUI",
    "PopStarRefreshTeam",
    --n32
    "OnFlipMask",           --活跃任务翻牌子
    "RefreshActiveTaskRed", --刷新活跃任务活动红点
    "CloseUIUpLevelAddQuickBox",
    "ClosePetEnhanceTips",  --关闭光灵修正tips
    "UIActivityN33LevelRefresh",
    --n33
    "OnDateFilterClick",              --模拟约会筛选
    "OnN33PickUpCoin",                -- 领取乐园币
    "OnN33UpgradeArch",               -- 升级建筑
    "OnN33UpgradeRewardOver",         -- 领取完升级建筑奖励
    "OnN33RefArchUI",                 -- 刷新建筑UI信息
    "OnN33FocusTag",                  -- 聚焦目标
    "OnInviteEventEnd",               -- 完成邀约事件
    "OnN33RefArchUI",                 -- 刷新建筑UI信息
    "OnN33ForceRefMapArch",           -- 强制刷新大地图中的建筑信息
    "OnN33FindPet",                   -- 查找光灵
    "OnN33RefreshBuildStatus",
    "UIHauteCoutureDrawBgPLMAnimOut", --高级皮肤抽奖普律玛背景界面的动画
    "UIHauteCoutureDrawBgPLMAnimIn",  --高级皮肤抽奖普律玛背景界面的动画

    --国服n2 game
    "UIN2GameQuestSelectDay",
    "SeasonLeaveToBattle",          --离开探索场景到局内
    "UISeasonS1OnSelectCollageItem",
    "OnMedalGroupApply",            --勋章套组应用
    "UISeasonOnLevelDiffChanged",   --赛季玩法切换关卡难度
    "OnBattleHelpRedRefresh",
    "UpdateDrawCardRed",            --刷新主界面抽卡按钮红点
    "OnSeasonQuestRedUpdate", --赛季数据相关
    --局内连线事件
    "MatchLineDragStart",           --局内连线开始
    "MatchLineDragEnd",             --局内连线结束
    "SeasonLeaveToMain",            --赛季玩法切换主界面
    "UpdateMonthCardShop",          --刷新月卡商店条目
    "SwitchSkinStaticOrDynamic",
    "OnEventPointProgressChange",   --赛季事件点状态发送改变
    "OnSeasonShareCgFinished",      --赛季分享cg完成
    "OnSeasonCollectionObtained",   --获得赛季收藏品
    "OnSeasonActionPointChanged",   --赛季行动点数量变化
    "OnSeasonQuestAwardCollected",  --赛季任务奖励领取完
    "OnSeasonSceneAwardCollected",  --赛季场景内领取完奖励
    "SeasonTryShowEventBubble",     --赛季场景弹文本callback
    "OnSeasonDailyReset",           --赛季日常关重置
    "OnSeasonDailyResetSucc",       --赛季日常关重置完成
    "OnSerialAutoFightSweepFinish", --扫荡界面关闭
    "OnSeasonMainBottomEftPlay",    --赛季主界面播底部特效
    "OnFocusAfterShareBack",        --模拟分享成功
    "OnN34TaskRefreshEvent",        --N34调查玩法主界面刷新
    "End",
}
table.appendArray(GameEventType, CoreGameEventType)
_autoEnum("GameEventType", GameEventType)
GameEventType = GameEventType
