---@class CoreGameEventType:GameEventType
---@field ModeStateEnter number
---@field LoadingFinish number
---@field LoadingUpdate number
---@field BattleEnterFinish number
---@field WaitInputFinish number
---@field RoleTurnFinish number
---@field RoleTurnResultFinish number
---@field PieceRefreshFinish number
---@field MonsterTurnFinish number
---@field RoundResultFinish number
---@field BattleResultFinish number
---@field ActiveSkillFinish number
---@field PersonaSkillFinish number
---@field ChainAttackFinish number
---@field PreviewActiveSkillFinish number
---@field PlayerShowFinish number
---@field WaveEnterFinish number
---@field WaveResultFinish number
---@field WaveSwitchFinish number
---@field PickUpActiveSkillTargetFinish number
---@field WaitInputChainFinish number
---@field PickUpChainSkillTargetFinish number
---@field PreChainFinish number
---@field CancelChainSkillCast number
---@field CastPickUpChainSkill number
---@field DataLogicResult number
---@field BattlePetIconSealedCurse number
---@field ToggleTeamLeaderChangeUI number
---@field BuffRoundCountChanged number
---@field ClientExceptionReport number
---@field RequestUIChangeTeamOrderView number
---@field CallUIChangeTeamOrderView number
---@field BattleUIShowHideSelectTeamPositionButton number
---@field BattleUISelectTargetTeamPosition number
---@field ChessUIStateTransit number
---@field ChessUIInputMoveAction number
---@field ChessUIInputAttackAction number
---@field ChessUIInputFinishTurnAction number
---@field ChessUIInputSkipAction number
---@field ChessUIStateBlockRaycast number
---@field UpdateBossGreyHP number
---@field FeatureListInit number
---@field FeatureSanValueChange number
---@field FeatureDayNightRefresh number
---@field BattleUIRefreshActiveSkillCastButtonState number
---@field RoleChangeTeamLeaderFinish number
---@field BattlePetIconSetSilence number
---@field SetActiveSkillCanNotReady number
---@field ShowHideOutOfRoundPunishWarn number
---@field UpdateOutOfRoundPunish number
---@field DataTrapAppearSkill number
---@field DataTrapTriggerSkill number
---@field ShowHideOutOfRoundDamageWarning number
---@field UpdateCoffinMusumeUIDef number
---@field ScanFeatureSaveInfo number
---@field ScanFeatureReplaceUIActiveSkillID number
---@field UpdateHPEnergy number
---@field DataRenderNTSelectRoundTeamNormalBefore number
---@field UpdateBuffLayerActiveSkillEnergyChange number
---@field UpdateBuffLayerActiveSkillEnergyPreview number
CoreGameEventType = {
    ---主状态机
    "ModeStateEnter",
    "LoadingFinish",
    "LoadingUpdate",
    "BattleEnterFinish",
    "RoundEnterFinish",
    "FirstWaveEnterFinish",
    "WaitInputFinish",
    "RoleTurnFinish",
    "RoleTurnResultFinish",
    "PieceRefreshFinish",
    "MonsterTurnStart",
    "MonsterTurnFinish",
    "RoundResultFinish",
    "BattleResultFinish",
    "ActiveSkillFinish",
    "PersonaSkillFinish",
    "ChainAttackFinish",
    "PreviewActiveSkillFinish",
    "WaveEnterFinish",
    "WaveResultFinish",
    "WaveResultAwardFinish",
    "WaveResultAwardApplyFinish",
    "WaveSwitchFinish",
    "PickUpActiveSkillTargetFinish",
    "WaitInputChainFinish",
    "PickUpChainSkillTargetFinish",
    "PreChainFinish",
    "PreviewActiveSkill",

    ---玩家状态机
    "PlayerActionEnter",
    "IdleEnd",
    "MoveFinish",
    "NormalAttackFinish",
    "ChainSkillAttackFinish",
    "PlayerHitBackFinish",

    ---UI事件
    "OnSetGraphicRaycaster",
    "StopPreviewActiveSkill",
    "StopPreviewFeatureSkill",
    "CastActiveSkill",
    "CastActiveSkillNoPet",
    "CastPersonaSkill",
    "AutoFight",
    "DoubleSpeed",
    "PetPowerChange",
    "PetExtraPowerChange",
    "PetLegendPowerChange",
    "TrapPowerChange",
    "TrapPowerVisible",
    "PersonaPowerChange",
    "ShowActiveSkillChooseUI",
    "UICancelChooseTarget",
    "UIChooseTargetConfirm",
    "UIChooseTargetGray",
    "UIShowPetInfo",
    "UIShowActiveSkillUI",
    "UIShowMultiActiveSkillUI",
    "UIMultiActiveSkillCastClick",
    "UIResetLastPreviewPetId",
    "UISetLastPreviewPetId",
    "UICancelActiveSkillSwitchTimer",
    "UISwitchActiveSkillUI",
    "UICancelActiveSkillCast",
    "UIShowChangeTeamLeaderData",
    "UIPetClickToSwitch",
    "UIExclusivePetHeadMaskAlpha",
    "UIShowHideCancelActiveSkillBtn",
    "UISetTeamStateTeamLeader",
    "SelectSubActiveSkill", --选择光灵主动技的子技能ID
    "PetActiveSkillGetReady",
    "PetExtraActiveSkillGetReady",
    "PetActiveSkillCancelReady", --取消准备(在准备状态中被添加CD)
    "PetExtraActiveSkillCancelReady",
    "PetPowerAndWatchChange",
    "TeamHPChange",

    "ShowUltraSkillSpine",
    "StopUltraSkillSpine",

    "ShowChainPathCancelArea",
    "HideChainPathCancelArea",

    "DisplayCombo",
    "ShowCanMoveArrow",
    "HideCanMoveArrow",

    "CancelChainPath",
    "SetHeadMaskAlpha",

    "PetShowPreviewArrow",
    "PetHidePreviewArrow",

    "ClickPetHead",
    "ClickTrapHead",
    "ClickPersonaSkill",
    "PreClickPetHead",
    "RefreshWaveInfo",
    "CancelActiveSkillCast",
    "ActiveSkillPickUp",
    "CastPickUpSkill",
    "EnablePickUpSkillCast",
    "RefreshPickUpNum",
    "ChangePickUpText", ---库斯库塔使用
    "RemainRoundCount2Power",
    "RemainRoundCount2PowerPet",
    "ChangeTeamBuff",
    "ChangeBuff",
    "ChangeBuffValue",
    "HPSliderBroken",
    "HPBombLayer",
    "AddBuffValue",
    "ShowTransitionEffect",

    "ShowHideUIBattle",

    "ChangeBossHPLock",
    "ShowHideBenumbTips",
    "ShowHideBesiegedTips",
    "PlayBattleUIEffect",

    "ChangeBossHPBuffButtonRayCast",
    "WorldBossSwitchStage",

    "PreviewMonsterReplaceHPBar", ---预览时替换大血条
    "RevokePreviewMonsterReplaceHPBar", ---关闭预览时恢复大血条
    "ClickUI2ClosePreviewMonster", ---通过点击其余UI按钮关闭怪物预览
    "UIPersonaSkillInfoShow",
    "UIFeatureSkillInfoShow",
    "UIMiniMazeChooseWaveAward",

    --region 连锁点选
    "CancelChainSkillCast",
    "CastPickUpChainSkill",
    --endregion
    ---转场黑屏效果
    "CancelReborn",
    "ExitCoreGame",

    --局内UI
    "ShowHideSuperChain",
    "ShowHideBossComing",
    "ShowHideWaveWarning",
    "WaveSwitch",
    "InitRoundCount",
    "UpdateRoundCount",
    "UpdateRoundCountByDiff",
    "ShowZeroRoundWarning",
    "ShowHideOutOfRoundPunishWarn",
    "ShowWaveSwitch",
    "ShowUIResult",
    "ShowCollectDropInfo",
    "ShowStoryBanner",
    "InOutQueue",
    "ActivatePassive",
    "ForceInitPassiveIcon",
    "SetAccumulateNum",
    "ForceInitPassiveAccumulate",
    "ShowOverloadPassiveAccumulate",
    "FlushPetChainSkillItem",
    "ShowHideChainSkillCG",
    "ShowTurnTips",
    "RefreshMainState",
    "ShowHideLowHpWarning",
    "ShowHideOutOfRoundDamageWarning",
    "ShowHideAuroraTime",
    "ActiveBattlePet", --使局内宠物头像可交互
    "ShowDropCoinInfo", --资源本掉落金币的展示
    "ShowDropMazeCoinInfo",
    "ShowDropCoinInfoActive",
    "UIBattleChangeHeadPos",
    "ChangeTeamLeader", ---UI通知替换队长
    "UIChangeTeamLeader", ---逻辑通知UI替换队长
    "UIChangeTeamLeaderLeftCount", ---逻辑通知UI替换队长剩余次数
    "UIMonsterDeadCountUpdate", ---更新UI上的怪物死亡数量变化
    "UIInternalRefreshMonster", ---更新UI上剩余怪物波次的变化
    "UIInitMonsterDeadCount", ---初始化击破数
    "UIInitN5Score", ---无双模式初始化分数
    "UIN5UpdateScore",
    "UIUpdateChessEscape",
    ---无双模式每波次通过后更新军工分数
    --设置资源本金币掉落窗体显示
    "MatchClosed", --同步失败导致的对局异常结束
    "UiHudVisible",
    "UiBattleVisible", --关闭UIbattle SafeArea节点上的 canvas
    "OnClickWhenPickUp", --拾取格子过程中发生了点击操作
    "UITrapSkillVisible", --打开机关的技能选择界面
    "PickUPValidGridShowChooseTarget", --刚进入预览时点选有效格子后,显示ui文字
    "PickUPInvalidGridCancelActiveSkill", --刚进入预览时点选无效格子后,取消预览状态
    --主动技取消和确认调换位置
    "TranspositionCancel",
    "TranspositionConfirm",
    "BattleTimeSpeed", --倍速按钮
    "ShowHideUIPreviewChain", --显隐连锁预览UI
    "ActiveUIPreviewChainBtnOK", --激活连锁预览UI的确认按钮
    "FeatureListInit", --模块 列表初始化
    "FeatureSanValueChange", --模块 通知san值变化
    "FeatureDayNightRefresh", --模块 通知昼夜回合数、状态变化
    "FeatureUIPlayDrawCard", --模块 抽牌 ui通知
    "FeatureUIRefreshCardNum", --模块 ui通知 刷新卡牌数
    "FeaturePetUIAddCardBuff", --模块 ui通知 头像显示卡牌buff
    "FeaturePetUIPreviewAddCardBuff", --模块 ui通知 预览头像显示卡牌buff
    "FeaturePetUIPreviewRecoverCardBuff", --模块 ui通知 预览头像恢复卡牌buff
    "ShowPowerfullRoundCountUI", --光灵米洛斯 头像显示技能已就绪回合数
    "ShowHideUiMultiPowerInfoByIndex", --复数cd技能时，控制某个cd区域显隐（凯雅，二技能中途解锁）
    "UIUpdateEscapeMonsterCount", --通知ui 怪物逃脱数 +1
    "UIMultiSkillClickIndex", --多主动技（包括变体）点击技能图标后 头像ui记录点选index
    "TrapRenderShow", --机关（表现）创建 通知机关计数模块
    "TrapRenderDestroy", ---机关（表现）销毁 通知机关计数模块
    "FeatureDayNightChangeUIStyle", --模块 通知昼夜 样式修改

    --Boss血条
    "ShowBossHp",
    "HideBossHp",
    "UpdateBossRedHp",
    "UpdateBossWhiteHp",
    "UpdateBossShield",
    "ShowBonusInfo",
    "OnClickUIBonusInfo",
    "UpdateBossHarmReduction",
    "UpdateBossNameAndElement",
    "UpdateWorldBossHP",
    "UpdateBossElement",
    "UpdateAntiActiveSkill",

    --自动战斗模拟UI操作
    "AutoFightCastSkill",
    "AutoFightCastPersonaSkill",
    "AutoFightCheckSwitchPetColumn", --小秘境（多列头像），点头像前先切换列（如果需要）

    "BanAutoFightBtn", --禁用自动战斗按钮

    -- START 诅咒：无法上场 战斗UI事件
    "BattlePetIconSealedCurse",
    "ToggleTeamLeaderChangeUI",
    -- END   诅咒：无法上场 战斗UI事件
    "BuffRoundCountChanged",

    --无双和世界Boss主动退局
    "SpecialMissionQuitGame",

    "ClientExceptionReport",
    --局内出战队伍换序UI表现
    "RequestUIChangeTeamOrderView",
    "CallUIChangeTeamOrderView",
    "SetPetOverloadState",
    "ResetPetOverloadState",
    "SetActiveSkillCanNotReady",

    ---战棋相关
    "PreviewChessPetFinish",
    "PickUpChessPetFinish",
    "ChessPetMoveFinish",
    "ChessPetAttackFinish",
    "ChessPetMoveAndAttackFinish",
    "ChessPetResultFinish",
    "ChessUIStateTransit",
    "ChessUIStateBlockRaycast",
    "ChessUIInputMoveAction",
    "ChessUIInputAttackAction",
    "ChessUIInputSkipAction",
    "ChessUIInputFinishTurnAction",
    "ChessUITargetIDsCanAttack",
    "GuideChessClick", --战旗引导

    "UpdateBossGreyHP",
    "BattleUIRefreshActiveSkillCastButtonState",
    "BattlePetIconSetSilence",

    "BattleUIRefreshCombinedWaveInfoOnRoundResult",

    "UpdateOutOfRoundPunish", --回合数耗尽扣血提示刷新

    --逻辑更新表现数据层事件
    "DataLogicResult",
    "DataBuffRoundCount",
    "DataBuffMaxRoundCount",
    "DataBuffValue",
    --逻辑更新表现数据层事件End

    "DataTrapAppearSkill",
    "DataTrapTriggerSkill",

    "UpdateCoffinMusumeUIDef",
    "UpdateCoffinMusumeUIAtkDef", --MSG51389
    "SkillEndForEditor",
    "GuideMonsterClick", --引导怪物点选
    "ScanFeatureSaveInfo",
    "ScanFeatureReplaceUIActiveSkillID",
    "ShowChoosePartnerUI",

    "UpdateHPEnergy", ---黑化菲莱克斯-重生能量点
    "DataRenderNTSelectRoundTeamNormalBefore",
    "UpdateBuffLayerActiveSkillEnergyChange",
    "UpdateBuffLayerActiveSkillEnergyPreview",
    "ChangePetExtraActiveSkill", --修改星灵附加主动技能
    "UIBattleSwitchPetEquipRefine", --切换装备精炼开关
    "BattleUIRefreshRefineSwitchBtnState", --消息处理后刷新切换装备精炼UI

    ---幻境_Begin
    "MirageEnterFinish",
    "MirageWaitInputFinish",
    "MirageRoleTurnFinish",
    "MirageMonsterTurnFinish",
    "MirageEndFinish",
    "ShowMirageChooseGrid",
    "UIMirageCancelChoose",
    "UIMirageChooseGridConfirm",
    "UIMirageChooseGridGray",
    "RefreshMiragePickUpGrid",
    "MirageUIClearPickUp",
    "MirageUIConfirmPickUp",
    "ShowMirageEnterUI",
    "RefreshMirageStep",
    "MirageUICountDownOver",
    "MirageUIRefreshStep",
    ---幻境状态_End

    --技能切换：退出技能预览时需要取消
    "CasterPreviewAnimatorExitPreview",
    
    "UIInitBossCastSkillTipInfo",
    "UIUpdateBossCastSkillTipInfo",
    "UIInitGlobalLayerTipInfo",
    "UIUpdateGlobalLayerTipInfo",
    "UIHideGlobalLayerTipInfo",
    "UIShowBossSpeak",
    "UICheatHideArea",--局内作弊工具 隐藏ui
    "UICheatHideObj",--局内作弊工具 隐藏物体
    "UpdateBossCurseHP",
    --region 消灭星星
    "PopStarLoadingFinish",
    "PopStarBattleEnterFinish",
    "PopStarWaveEnterFinish",
    "PopStarRoundEnterFinish",
    "PopStarPieceRefreshFinish",
    "PopStarTrapTurnFinish", 
    "PopStarRoundResultFinish",
    "PopStarWaveResultFinish",
    "PopStarPickUp",
    "PopStarShowPopNum",
    "PopStarRefreshProgressInfo",
    "PopStarRefreshStageInfo",
    --endregion 消灭星星
    ---引导----
    --局内连线事件
    "MatchLineDragStart", --局内连线开始
    "MatchLineDragEnd", --局内连线结束
}
