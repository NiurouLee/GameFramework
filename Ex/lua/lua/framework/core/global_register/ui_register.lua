--[[------------------------------------------------------------------------------------------

**********************************************************************************************

    UI注册�?

**********************************************************************************************

]]
--------------------------------------------------------------------------------------------

---@class UIRegister:Singleton

_class("UIRegister", Singleton)

UIRegister = UIRegister

require "audio_const"

-- UI窗口注册�?

-- UI窗口名称 = {uiPrefab=UI窗口预设名称, maskType=UI窗口遮罩类型, loadDataBeforeSwitch=是否加载预设前先加载数据,

--uiComponents={注册UI组件(比如目前UITransitionComponent表示UI过渡组件)}}

UIRegister.registeredUIs = {
    -----框架-----
    UIMonitorController                             = { uiPrefab = "UIMonitor.prefab" },
    UIResLeak                                       = { uiPrefab = "UIResLeak.prefab" },
    UIGameStatus                                    = { uiPrefab = "UIGameStatus.prefab" },
    -----三消项目-----

    UILoginEmpty                                    = { uiPrefab = "UILoginEmpty.prefab" },
    ---大厅
    UIMainLobbyController                           = {
        uiPrefab = "UIMainLobbyController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    ---侧边栏入口 活动中心
    UISideEnterCenterController                     = {
        uiPrefab = "UISideEnterCenterController.prefab",
        maskType = MaskType.MT_None
    },
    UISideEnterCenterSingleController               = {
        uiPrefab = "UISideEnterCenterSingleController.prefab",
        maskType = MaskType.MT_None
    },
    UIPetForecast                                   = {
        uiPrefab = "UIPetForecast.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetForecast2                                  = {
        uiPrefab = "UIPetForecast2.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --邮件界面
    UIMailController                                = {
        uiPrefab = "UIMailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIMailContentController                         = {
        uiPrefab = "UIMailContentController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --聊天好友
    UIChatController                                = {
        uiPrefab = "UIChatController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatFriendInfoController                      = {
        uiPrefab = "UIChatFriendInfoController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatDeleteFriendController                    = {
        uiPrefab = "UIChatDeleteFriendController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatDontFriendTipsController                  = {
        uiPrefab = "UIChatDontFriendTipsController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatSetNoteNameController                     = {
        uiPrefab = "UIChatSetNoteNameController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatBlackListController                       = {
        uiPrefab = "UIChatBlackListController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatAddBlacklistController                    = {
        uiPrefab = "UIChatAddBlacklistController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIChatRemoveBlacklistController                 = {
        uiPrefab = "UIChatRemoveBlacklistController.prefab",
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    ---Loading
    UICommonLoading                                 = { uiPrefab = "UICommonLoading.prefab", maskType = MaskType.MT_None },
    ---common
    UILevelUp                                       = {
        uiPrefab = "UILevelUp.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    ---剧情
    UIStoryController                               = { uiPrefab = "UIStory.prefab", maskType = MaskType.MT_None },
    ---待删除的demo临时界面
    UIDemoPrepare                                   = { uiPrefab = "UIDemoPrepare.prefab" },
    ---背包
    UIBackPackController                            = { uiPrefab = "UIBackPackController.prefab" },
    UIGetItemController                             = {
        uiPrefab = "UIGetItemController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIBackPackBox                                   = {
        uiPrefab = "UIBackPackBox.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetBackPackBox                                = {
        uiPrefab = "UIPetBackPackBox.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetBackPackConfirm                            = {
        uiPrefab = "UIPetBackPackConfirm.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIBackPackBoxGain                               = {
        uiPrefab = "UIBackPackBoxGain.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAmbientPanel                                  = {
        uiPrefab = "UIAmbientPanel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIItemGetPathController                         = {
        uiPrefab = "UIItemGetPathController.prefab",
        maskType = MaskType.MT_None
    },
    UIItemSaleAndUseWithCountController             = {
        uiPrefab = "UIItemSaleAndUseWithCountController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    ---大地�?
    UIDiscovery                                     = {
        uiPrefab = "UIDiscovery.prefab",
        maskType = MaskType.MT_MoreBlackMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery
        }
    },
    UIChapters                                      = { uiPrefab = "UIChapters.prefab", maskType = MaskType.MT_None },
    UIChapterAward                                  = {
        uiPrefab = "UIChapterAward.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDiscoveryPart                                 = {
        uiPrefab = "UIDiscoveryPart.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDiscoveryPartUnlock                           = {
        uiPrefab = "UIDiscoveryPartUnlock.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMazeEnter                                     = { uiPrefab = "UIMazeEnter.prefab", maskType = MaskType.MT_None },
    UIPlotEnter                                     = { uiPrefab = "UIPlotEnter.prefab", maskType = MaskType.MT_BlurMask },
    UIDiscoveryUnlock                               = {
        uiPrefab = "UIDiscoveryUnlock.prefab",
        maskType = MaskType.MT_None
    },
    ---星灵
    UIHeartSpiritController                         = {
        uiPrefab = "UIHeartSpiritController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIUpLevelInterfaceController                    = {
        uiPrefab = "UIUpLevelInterfaceController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIGradeInterfaceController                      = {
        uiPrefab = "UIGradeInterfaceController.prefab"
    },
    UIBreakController                               = {
        uiPrefab = "UIBreakController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISpiritDetailGroupController                   = {
        uiPrefab = "UISpiritDetailGroupController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetSkillDetailController                      = {
        uiPrefab = "UIPetSkillDetailController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetIntimacyMainController                     = {
        uiPrefab = "UIPetIntimacyMainController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetIntimacyImageRecallController              = {
        uiPrefab = "UIPetIntimacyImageRecallController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetIntimacyStumbles                           = {
        uiPrefab = "UIPetIntimacyStumbles.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetIntimacyLevelUp                            = {
        uiPrefab = "UIPetIntimacyLevelUp.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UISpiritDetailLookCgAndSpineController          = { uiPrefab = "UISpiritDetailLookCgAndSpineController.prefab" },
    ---关卡组队
    UIStage                                         = { uiPrefab = "UIStage.prefab", maskType = MaskType.MT_BlurMask },
    UIEnemyTip                                      = { uiPrefab = "UIEnemyTip.prefab", maskType = MaskType.MT_BlurMask },
    UIEnemyBookTip                                  = {
        uiPrefab = "UIEnemyBookTip.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPlot                                          = { uiPrefab = "UIPlot.prefab", maskType = MaskType.MT_None },
    UITeams                                         = { uiPrefab = "UITeams.prefab" },
    UITeamsGuide                                    = { uiPrefab = "UITeamsGuide.prefab" },
    UITeamsNameModify                               = {
        uiPrefab = "UITeamsNameModify.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISkillScope                                    = {
        uiPrefab = "UISkillScope.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITeamChangeController                          = {
        uiPrefab = "UITeamChangeController.prefab",
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIStageRecordController                         = {
        uiPrefab = "UIStageRecord.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    ---局�?
    UIBattle                                        = {
        uiPrefab = "UIBattle.prefab"
    },
    UIBattleInfo                                    = {
        uiPrefab = "UIBattleInfo.prefab",
        maskType = MaskType
            .MT_BlurMask
    },
    UIBattleQuit                                    = {
        uiPrefab = "UIBattleQuit.prefab",
        maskType = MaskType
            .MT_BlurMask
    },
    UIFeatureSanInfo                                = {
        uiPrefab = "UIFeatureSanInfo.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIBattleTeamState                               = {
        uiPrefab = "UIBattleTeamState.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIBattleResultComplete                          = {
        uiPrefab = "UIBattleResultComplete.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIBattleResultRevive                            = {
        uiPrefab = "UIBattleResultRevive.prefab",
        maskType = MaskType.MT_None
    },
    UIBattleBossWarning                             = {
        uiPrefab = "UIBattleBossWarning.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIBattleBossSpeakDialog                         = {
        uiPrefab = "UIBattleBossSpeakDialog.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIHarvestTime                                   = { uiPrefab = "UIHarvestTime.prefab", maskType = MaskType.MT_None },
    UISuperChainSkill                               = {
        uiPrefab = "UISuperChainSkill.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIBattleWaveSwitch                              = {
        uiPrefab = "UIBattleWaveSwitch.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIBattleZeroRoundWarning                        = {
        uiPrefab = "UIBattleZeroRoundWarning.prefab",
        maskType = MaskType.MT_None
    },
    UIBattleOutOfRoundPunishWarn                    = {
        uiPrefab = "UIBattleOutOfRoundPunishWarn.prefab",
        maskType = MaskType.MT_None
    },
    UIBattleBonus                                   = {
        uiPrefab = "UIBattleStart.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIBattleCheat                                   = { uiPrefab = "UIBattleCheat.prefab" },
    UIBattleChangeTeamLeader                        = {
        uiPrefab = "UIBattleChangeTeamLeader.prefab",
        maskType = MaskType.MT_None
    },
    UIBattleUltraSkillCG                            = {
        uiPrefab = "UIBattleUltraSkillCG.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIBattlePersonaSkillEffTop                      = {
        uiPrefab = "UIBattlePersonaSkillEffTop.prefab",
        maskType = MaskType.MT_None
    },
    UIPetObtain                                     = { uiPrefab = "UIPetObtain.prefab", maskType = MaskType.MT_None },
    ---模板
    UIDragImageController                           = { uiPrefab = "UIDragImage.prefab" },
    ---测试�? 各系统入口界�? 上线前要删掉
    UITestEntry                                     = { uiPrefab = "UITestEntry.prefab", maskType = MaskType.MT_Default },
    ---番外
    UIExtraMissionDetailController                  = {
        uiPrefab = "UIExtraMissionDetailController.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery,
            ["UITransitionComponent"] = {}
        }
    },
    UIExtraMissionStageController                   = {
        uiPrefab = "UIExtraMissionStageController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery,
            ["UITransitionComponent"] = {}
        }
    },
    UIExtraMissionAwardController                   = {
        uiPrefab = "UIExtraMissionAwardController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    ---体力
    UIPowerInfoRunTimeController                    = {
        uiPrefab = "UIPowerInfoRunTimeController.prefab",
        maskType = MaskType.MT_None
    },
    UIEmptyController                               = {
        uiPrefab = "UIEmptyController.prefab",
        maskType = MaskType.MT_None
    },
    ---风船
    UIAircraftController                            = {
        uiPrefab = "UIAircraft.prefab",
        maskType = MaskType.MT_None
    },
    UIAircraftRoomLevelUpController                 = {
        uiPrefab = "UIAircraftRoomLevelUp.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftPreconditionController                = {
        uiPrefab = "UIAircraftPrecondition.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftRoomLevelDownController               = {
        uiPrefab = "UIAircraftRoomLevelDown.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftConfirmDialogController               = {
        uiPrefab = "UIAircraftConfirmDialog.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftEvilInfoController                    = {
        uiPrefab = "UIAircraftEvilInfo.prefab",
        maskType = MaskType.MT_None
    },
    UIAircraftEvilClearController                   = {
        uiPrefab = "UIAircraftEvilClear.prefab",
        maskType = MaskType.MT_None
    },
    UIPowerExchangeController                       = {
        uiPrefab = "UIPowerExchange.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftFireflySpeedupController              = {
        uiPrefab = "UIAircraftFireflySpeedup.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftSpaceCleanController                  = {
        uiPrefab = "UIAircraftSpaceClean.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftBuildRoomController                   = {
        uiPrefab = "UIAircraftBuildRoomController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftEnterBuildController                  = {
        uiPrefab = "UIAircraftEnterBuildController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftRoomInteractiveEventController        = {
        uiPrefab = "UIAircraftInteractiveEventInfo.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftUnlockFileController                  = {
        uiPrefab = "UIAircraftUnlockFile.prefab",
        maskType = MaskType.MT_None
    },
    UIAircraftItemSmeltController                   = {
        uiPrefab = "UIAircraftItemSmeltController.prefab",
        maskType = MaskType.MT_Default
    },
    UIAircraftDecorateController                    = {
        uiPrefab = "UIAircraftDecorateController.prefab",
        maskType = MaskType.MT_None
    },
    UISmeltAtomExchangeController                   = {
        uiPrefab = "UISmeltAtomExchange.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIAircraftDecorateTip                           = {
        uiPrefab = "UIAircraftDecorateTip.prefab",
        maskType = MaskType.MT_None
    },
    ---家园
    UIHomelandMain                                  = { uiPrefab = "UIHomelandMain.prefab", maskType = MaskType.MT_None },
    UIHomelandBuild                                 = { uiPrefab = "UIHomelandBuild.prefab", maskType = MaskType.MT_None },
    UIHomelandBuildEditRotate                       = {
        uiPrefab = "UIHomelandBuildEditRotate.prefab",
        maskType = MaskType.MT_None
    },
    UIHomelandShopController                        = {
        uiPrefab = "UIHomelandShopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandShopBuyConfirm                        = {
        uiPrefab = "UIHomelandShopBuyConfirm.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandShopSellConfirm                       = {
        uiPrefab = "UIHomelandShopSellConfirm.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIBuildInfo                                     = { uiPrefab = "UIBuildInfo.prefab", maskType = MaskType.MT_BlurMask },
    UIBuildSkinTips                                 = {
        uiPrefab = "UIBuildSkinTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIForge                                         = { uiPrefab = "UIForge.prefab", maskType = MaskType.MT_BlurMask }, --打�?
    UIForgeDetail                                   = {
        uiPrefab = "UIForgeDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIForgeSpeed                                    = {
        uiPrefab = "UIForgeSpeed.prefab",
        maskType = MaskType
            .MT_BlurMask
    },
    UIHomelandMessageBox                            = {
        uiPrefab = "UIHomelandMessageBox.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMessageBox_Items                      = {
        uiPrefab = "UIHomelandMessageBox_Items.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIItemTipsHomeland                              = {
        uiPrefab = "UIItemTipsHomeland.prefab",
        maskType = MaskType.MT_None
    },
    UIHomelandBackpack                              = {
        uiPrefab = "UIHomelandBackpack.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandToolLevelUp                           = {
        uiPrefab = "UIHomelandToolLevelUp.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandGetPath                               = {
        uiPrefab = "UIHomelandGetPath.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandSaleAndUseWithCount                   = {
        uiPrefab = "UIHomelandSaleAndUseWithCount.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBackpackBox                           = {
        uiPrefab = "UIHomelandBackpackBox.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBackPackBoxGain                       = {
        uiPrefab = "UIHomelandBackPackBoxGain.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UITreasureBoard                                 = {
        uiPrefab = "UITreasureBoard.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIBuildRaiseFish                                = {
        uiPrefab = "UIBuildRaiseFish.prefab",
        maskType = MaskType
            .MT_None
    },
    UIBuildCollectCoin                              = {
        uiPrefab = "UIBuildCollectCoin.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIBuildCollectCoinTask                          = {
        uiPrefab = "UIBuildCollectCoinTask.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIHomelandLevel                                 = {
        uiPrefab = "UIHomelandLevel.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandLevelSignPop                          = {
        uiPrefab = "UIHomelandLevelSignPop.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandLevelExpTips                          = {
        uiPrefab = "UIHomelandLevelExpTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeTopTips                                   = { uiPrefab = "UIHomeTopTips.prefab", maskType = MaskType.MT_None },
    UIHomelandMedalWall                             = {
        uiPrefab = "UIHomelandMedalWall.prefab",
        maskType = MaskType.MT_None
    },
    ---剧情查看界面
    UIStoryViewerController                         = {
        uiPrefab = "UIStoryViewer.prefab",
        MaskType = MaskType
            .MT_Default
    },
    UIVideo                                         = { uiPrefab = "UIVideo.prefab" },
    ---局内剧情Banner
    UIStoryBanner                                   = {
        uiPrefab = "UIStoryBanner.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UISetController                                 = {
        uiPrefab = "UISetController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICredits                                       = { uiPrefab = "UICredits.prefab", maskType = MaskType.MT_None },
    UIColorBlind                                    = {
        uiPrefab = "UIColorBlind.prefab",
        maskType = MaskType
            .MT_BlurMask
    },
    UISetAgeConfirmController                       = { uiPrefab = "UISetAgeConfirmController.prefab" },
    UISetDataCopyController                         = {
        uiPrefab = "UISetDataCopyController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetPrivacySetController                       = {
        uiPrefab = "UISetPrivacySetController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetPrivacySetTipsController                   = { uiPrefab = "UISetPrivacySetTipsController.prefab" },
    UISetChangePasswdController                     = {
        uiPrefab = "UISetChangePasswdController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISkillEditorController                         = { uiPrefab = "SkillEditor.prefab" },
    UISetBindChannelController                      = { uiPrefab = "UISetBindChannelController.prefab" },
    UISetBindChannelTipsController                  = { uiPrefab = "UISetBindChannelTipsController.prefab" },
    UISetBindMailController                         = { uiPrefab = "UISetBindMailController.prefab" },
    UISetBindMailChangePasswordController           = { uiPrefab = "UISetBindMailChangePasswordController.prefab" },
    --秘境探索
    UIMazeController                                = {
        uiPrefab = "UIMaze.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMaze
        }
    },
    UIRugueLikeRestRoomController                   = {
        uiPrefab = "UIRugueLikeRestRoomController.prefab",
        maskType = MaskType.MT_None
    },
    UIRugueLikeChooseCardController                 = {
        uiPrefab = "UIRugueLikeChooseCardController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIRugueLikeBattleResultController               = {
        uiPrefab = "UIRugueLikeBattleResultController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            },
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMBattleSuccess
        }
    },
    UIRugueLikeDefeatedController                   = {
        uiPrefab = "UIRugueLikeDefeatedController.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMBattleFail
        }
    },
    UIRugueLikeBackpackController                   = {
        uiPrefab = "UIRugueLikeBackpackController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIRugueLikeResetMsgBoxController                = {
        uiPrefab = "UIRugueLikeResetMsgBoxController.prefab",
        maskType = MaskType.MT_None
    },
    UIHelpController                                = {
        uiPrefab = "UIHelpController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIRugueLikeLastStageTipController               = { uiPrefab = "UIRugueLikeLastStageTipController.prefab" },
    --资源�?
    UIResEntryController                            = {
        uiPrefab = "UIResEntryController.prefab",
        maskType = MaskType.MT_None
    },
    UIResDetailController                           = {
        uiPrefab = "UIResDetailController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery
        }
    },
    --商城
    UIShopController                                = {
        uiPrefab = "UIShopController.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMShop
        }
    },
    UIPayLawTipsController                          = { uiPrefab = "UIPayLawTipsController.prefab" },
    UIPayLawContentController                       = { uiPrefab = "UIPayLawContentController.prefab" },
    UIShopConfirmNormalController                   = {
        uiPrefab = "UIShopConfirmNormalController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIShopConfirmDetailController                   = {
        uiPrefab = "UIShopConfirmDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIShopPetDetailController                       = { uiPrefab = "UIShopPetDetailController.prefab" },
    UIShopGiftPackDetail                            = {
        uiPrefab = "UIShopGiftPackDetail.prefab",
        maskType = MaskType.MT_None
    },
    UIShopCurrency1To2                              = {
        uiPrefab = "UIShopCurrency1To2.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    UIShopRechargeGain                              = {
        uiPrefab = "UIShopRechargeGain.prefab",
        maskType = MaskType.MT_None
    },
    UIItemTips                                      = { uiPrefab = "UIItemTips.prefab", maskType = MaskType.MT_None },
    --任务
    UIQuestAchievementPointAwardsController         = {
        uiPrefab = "UIQuestAchievementPointAwardsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIQuestAwardsInfoController                     = { uiPrefab = "UIQuestAwardsInfoController.prefab" },
    UIQuestController                               = {
        uiPrefab = "UIQuestController.prefab",
        maskType = MaskType.MT_BlurMask
        -- uiComponents = {
        --     ["UITransitionComponent"] = {}
        -- }
    },
    -- 新手引导
    UIGuidePopController                            = {
        uiPrefab = "UIGuidePopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIGuideCircleController                         = {
        uiPrefab = "UIGuideCircleController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIGuideCircleModelController                    = {
        uiPrefab = "UIGuideCircleModelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIGuideAttrController                           = {
        uiPrefab = "UIGuideAttrController.prefab",
        maskType = MaskType.MT_None
    },
    UIGuideFailedController                         = {
        uiPrefab = "UIGuideFailedController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIGuideModelController                          = { uiPrefab = "UIGuideModelController.prefab" },
    --抽卡
    UIDrawCardController                            = { uiPrefab = "UIDrawCard.prefab" },
    UIDrawCardAwardPoolDetailController             = {
        uiPrefab = "UIDrawCardAwardPoolDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDrawCardMultipleShowController                = {
        uiPrefab = "UIDrawCardMultipleShow.prefab",
        maskType = MaskType.MT_None
    },
    UIDrawCardConfirmController                     = {
        uiPrefab = "UIDrawCardConfirm.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDrawCardAnimController                        = { uiPrefab = "UIDrawCardAnim.prefab", maskType = MaskType.MT_None },
    UIUnObtainSixPetController                      = {
        uiPrefab = "UIUnObtainSixPetController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDrawCardAwardConversionForOtherController     = {
        uiPrefab = "UIDrawCardAwardConversionForOtherController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --
    UIFunctionLockTipsController                    = { uiPrefab = "UIFunctionLockTipsController.prefab" },
    --顶条信息提示
    UITopTipsController                             = {
        uiPrefab = "UITopTipsController.prefab",
        maskType = MaskType.MT_None
    },
    --物品信息空界面（用来关闭�?
    UISelectInfoEmptyController                     = {
        uiPrefab = "UISelectInfoEmptyController.prefab",
        maskType = MaskType.MT_None
    },
    --登录后公�?
    UINoticeController                              = {
        uiPrefab = "UINoticeController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UILoginNoticeController                         = {
        uiPrefab = "UILoginNoticeController.prefab",
        maskType = MaskType.MT_None
    },
    --更换助理
    UIChooseAssistantController                     = {
        uiPrefab = "UIChooseAssistantController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --克制关系
    UIRestrainTips                                  = {
        uiPrefab = "UIRestrainTips.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    --三星条件
    UIThreeStarTips                                 = {
        uiPrefab = "UIThreeStarTips.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    --圣物说明
    UIRelicInfoController                           = {
        uiPrefab = "UIRelicInfoController.prefab",
        maskType = MaskType.MT_None
    },
    UIGradeSkillPanelController                     = {
        uiPrefab = "UIGradeSkillPanelController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --图鉴
    UIBookEntryController                           = {
        uiPrefab = "UIBookEntryController.prefab",
        maskType = MaskType.MT_MoreBlackMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIBookCGPreviewController                       = {
        uiPrefab = "UIBookCGPreviewController.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    UIBookRoleEntryController                       = {
        uiPrefab = "UIBookRoleEntryController.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    UIBookRoleRelationController                    = {
        uiPrefab = "UIBookRoleRelationController.prefab",
        maskType = MaskType.MT_MoreBlackMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIBookRoleRelationShowController                = {
        uiPrefab = "UIBookRoleRelationShowController.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    --个人信息
    UIPlayerInfoController                          = {
        uiPrefab = "UIPlayerInfoController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIChangeNameController                          = {
        uiPrefab = "UIChangeNameController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIChangeSignController                          = {
        uiPrefab = "UIChangeSignController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIChangeTitleController                         = {
        uiPrefab = "UIChangeTitleController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIChangeEmblazonryController                    = {
        uiPrefab = "UIChangeEmblazonryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIChangeHeadController                          = {
        uiPrefab = "UIChangeHeadController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --尖塔
    UITowerController                               = {
        uiPrefab = "UITower.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMTower
        }
    },
    UITowerRecordController                         = {
        uiPrefab = "UITowerRecord.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITowerLayerController                          = {
        uiPrefab = "UITowerLayer.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMTower
        }
    },
    --终端�?
    UIWeChatController                              = {
        uiPrefab = "UIWeChatController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIWeChatChangeNameController                    = {
        uiPrefab = "UIWeChatChangeNameController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIWeChatJumpController                          = {
        uiPrefab = "UIWeChatJumpController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --充值demo
    UIDemoPayController                             = {
        uiPrefab = "UIDemoPayController.prefab",
        maskType = MaskType.MT_None
    },
    UIPayTokenInputTest                             = {
        uiPrefab = "UIPayTokenInputTest.prefab",
        maskType = MaskType.MT_None
    },
    UIStageTestController                           = {
        uiPrefab = "UIStageTest.prefab",
        maskType = MaskType.MT_None
    },
    UICutsceneTestController                        = {
        uiPrefab = "UICutsceneTest.prefab",
        maskType = MaskType.MT_None
    },
    --终端�?
    UIAircraftSendGiftController                    = {
        uiPrefab = "UIAircraftSendGiftController.prefab",
        maskType = MaskType.MT_None
    },
    UISkillHrefInfo                                 = { uiPrefab = "UISkillHrefInfo.prefab", maskType = MaskType.MT_None },
    --装备--
    UIPetEquipController                            = {
        uiPrefab = "UIPetEquipController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetEquipIntrController                        = {
        uiPrefab = "UIPetEquipIntrController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetEquipUpLevelController                     = {
        uiPrefab = "UIPetEquipUpLevelController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPetEquipUpLvInfoController                    = {
        uiPrefab = "UIPetEquipUpLvInfoController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --助战--
    UIHelpPetManageController                       = {
        uiPrefab = "UIHelpPetManageController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHelpPetInfoController                         = {
        uiPrefab = "UIHelpPetInfoController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHelpPetSelectController                       = {
        uiPrefab = "UIHelpPetSelectController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UILuaLeak                                       = { uiPrefab = "UIResLeak.prefab" },
    --巨像派遣
    UIDispatchMapController                         = { uiPrefab = "UIDispatchMapController.prefab" },
    UIDispatchDetailController                      = {
        uiPrefab = "UIDispatchDetailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIBookController                                = {
        uiPrefab = "UIBookController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIBookInfoController                            = {
        uiPrefab = "UIBookInfoController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDispatchSelectPetController                   = { uiPrefab = "UIDispatchSelectPetController.prefab" },
    UIDispatchGiveUpController                      = { uiPrefab = "UIDispatchGiveUpController.prefab" },
    --签到
    UISignInController                              = {
        uiPrefab = "UISignInController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIChooseMainBgController                        = {
        uiPrefab = "UIChooseMainBgController.prefab",
        maskType = MaskType.MT_None
    },
    UIAlbumController                               = { uiPrefab = "UIAlbum.prefab" },
    --活动兑换商店
    UICampaignShopController                        = {
        uiPrefab = "UICampaignShopController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsaShop
        }
    },
    UICampaignShopConfirmDetailController           = {
        uiPrefab = "UICampaignShopConfirmDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICampaignShopConfirmNormalController           = {
        uiPrefab = "UICampaignShopConfirmNormalController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- 活动礼包详情
    UIActivityGiftPackDetail                        = {
        uiPrefab = "UIActivityGiftPackDetail.prefab",
        maskType = MaskType.MT_None
    },
    -- 伊芙醒山活动
    UIActivityEveSinsaMainController                = {
        uiPrefab = "UIActivityEveSinsaMainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIActivityEveSinsaTaskController                = {
        uiPrefab = "UIActivityEveSinsaTaskController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityEveSinsaLevelAController              = {
        uiPrefab = "UIActivityEveSinsaLevelAController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIActivityEveSinsaLevelBController              = {
        uiPrefab = "UIActivityEveSinsaLevelBController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIActivityStage                                 = { uiPrefab = "UIStage.prefab", maskType = MaskType.MT_BlurMask },
    UIActivityPlotEnter                             = {
        uiPrefab = "UIPlotEnter.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    --传说光灵
    UITrailLevelBuffTips                            = {
        uiPrefab = "UITrailLevelBuffTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UITrailLevelBuffDes                             = { uiPrefab = "UITrailLevelBuffDes.prefab" },
    UITrailLevelController                          = { uiPrefab = "UITrailLevelController.prefab" },
    UITrailLevelRewardController                    = {
        uiPrefab = "UITrailLevelRewardController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UITrailLevelDetail                              = {
        uiPrefab = "UITrailLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UITalePetList                                   = { uiPrefab = "UITalePetList.prefab" },
    UITalePetMissionController                      = { uiPrefab = "UITalePetMissionController.prefab" },
    UIConveneDesc                                   = { uiPrefab = "UIConveneDesc.prefab" },
    UISwitchPetPro                                  = { uiPrefab = "UISwitchPetPro.prefab" },
    UIMissionSubmitItem                             = { uiPrefab = "UIMissionSubmitItem.prefab" },
    UITrailLevelBuffIntroduce                       = { uiPrefab = "UITrailLevelBuffIntroduce.prefab" },
    --活动 累计登录奖励
    UIActivityTotalLoginAwardController             = {
        uiPrefab = "UIActivityTotalLoginAwardController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIAircraftRoomUnLockTipsController              = {
        uiPrefab = "UIAircraftRoomUnLockTipsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIGetPhyPointController                         = {
        uiPrefab = "UIGetPhyPointController.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIGetPhyPointTipsController                     = {
        uiPrefab = "UIGetPhyPointTipsController.prefab",
        maskType = MaskType.MT_None
    },
    --通用活动介绍
    UIActivityIntroController                       = {
        uiPrefab = "UIActivityIntroController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    -- 新型 通用活动介绍 加载�?
    UIIntroLoader                                   = { uiPrefab = "UIIntroLoader.prefab" },
    --连续自动战斗
    UISerialAutoFightInfo                           = {
        uiPrefab = "UISerialAutoFightInfo.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    UISerialAutoFightOption                         = {
        uiPrefab = "UISerialAutoFightOption.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISerialAutoFightSweepResult                    = {
        uiPrefab = "UISerialAutoFightSweepResult.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetAutoFightCount                             = {
        uiPrefab = "UISetAutoFightCount.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UISetAutoFightCountNew                          = {
        uiPrefab = "UISetAutoFightCountNew.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetAutoFightCountAndTicket                    = {
        uiPrefab = "UISetAutoFightCountAndTicket.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetAutoFightCountAndTicketNew                 = {
        uiPrefab = "UISetAutoFightCountAndTicketNew.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetAutoFightIntroduce                         = {
        uiPrefab = "UISetAutoFightIntroduce.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --签到活动
    UITempSignInController                          = {
        uiPrefab = "UITempSignInController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    --樱龙使活�?
    UISakuraEntryController                         = {
        uiPrefab = "UISakuraEntryController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSakura
        }
    },
    UISakuraController                              = {
        uiPrefab = "UISakuraController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISakuraDrawShopController                      = { uiPrefab = "UISakuraDrawShopController.prefab" },
    UISakuraDrawShopTipsController                  = {
        uiPrefab = "UISakuraDrawShopTipsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISakuraTaskController                          = {
        uiPrefab = "UISakuraTaskController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISakuraTaskControllerWrapper                   = {
        uiPrefab = "UISakuraTaskController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISummer1                                       = {
        uiPrefab = "UISummer1.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1
        }
    },
    UISummer1Intro                                  = {
        uiPrefab = "UISummer1Intro.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    --传说光灵局内弹�?
    UIBattleTaleBuffDesc                            = {
        uiPrefab = "UIBattleTaleBuffDesc.prefab",
        maskType = MaskType.MT_None
    },
    UIBossCounter                                   = { uiPrefab = "UIBossCounter.prefab", maskType = MaskType.MT_None },
    UIBattleAutoTest                                = {
        uiPrefab = "UIBattleAutoTest.prefab",
        maskType = MaskType
            .MT_None
    },
    --夏活二期
    UISummerActivityTwoMainController               = {
        uiPrefab = "UISummerActivityTwoMainController.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1Hard
        }
    },
    UISummerActivityTwoScoreController              = {
        uiPrefab = "UISummerActivityTwoScoreController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISummerActivityTwoLevelController              = {
        uiPrefab = "UISummerActivityTwoLevelController.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1Hard
        }
    },
    UISummerActivityTwoLevelDetail                  = {
        uiPrefab = "UISummerActivityTwoLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISummerActivityTwoNormalLevelDetail            = {
        uiPrefab = "UISummerActivityTwoNormalLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISummerActivityTwoSelectEntryController        = { uiPrefab = "UISummerActivityTwoSelectEntryController.prefab" },
    UISummerActivityTwoEntryController              = {
        uiPrefab = "UISummerActivityTwoEntryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --光灵时装
    UIPetSkinsMainController                        = {
        uiPrefab = "UIPetSkinsMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --夏活1普通关
    UIXH1SimpleLevel                                = {
        uiPrefab = "UIXH1SimpleLevel.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1
        }
    },
    --夏活1高难�?
    UIXH1HardLevel                                  = {
        uiPrefab = "UIXH1HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1Hard
        }
    },
    --夏活1普通关关卡详情
    UIXH1Stage                                      = { uiPrefab = "UIXH1Stage.prefab", maskType = MaskType.MT_BlurMask },
    UIXH1PointDetail                                = {
        uiPrefab = "UIXH1PointDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --夏活刨冰关卡
    UIMiniGameStageController                       = {
        uiPrefab = "UIMiniGameStageController.prefab",
        maskType = MaskType.MT_None
    },
    --夏活刨冰游戏
    UIMiniGameController                            = {
        uiPrefab = "UIMiniGameController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    --获得典藏时装
    UIPetSkinsGetCgController                       = {
        uiPrefab = "UIPetSkinsGetCgController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --夏活2剧情
    UISummerActivityTwoPlotDetailController         = {
        uiPrefab = "UISummerActivityTwoPlotDetailController.prefab",
        maskType = MaskType.MT_None
    },
    UIXH1Shop                                       = {
        uiPrefab = "UIXH1Shop.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --region
    -----------------------------------------------------------------
    -- 战斗通行�?
    UIActivityBattlePassMainController              = {
        uiPrefab = "UIActivityBattlePassMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityBattlePassPreviewController           = {
        uiPrefab = "UIActivityBattlePassPreviewController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityBattlePassBuyController               = {
        uiPrefab = "UIActivityBattlePassBuyController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityBattlePassBuyLevelController          = {
        uiPrefab = "UIActivityBattlePassBuyLevelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityBattlePassAwardController             = {
        uiPrefab = "UIActivityBattlePassAwardController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    -----------------------------------------------------------------
    -- 战斗通行证N5
    UIActivityBattlePassN5MainController            = {
        uiPrefab = "UIActivityBattlePassN5MainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityBattlePassN5PreviewController         = {
        uiPrefab = "UIActivityBattlePassN5PreviewController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityBattlePassN5BuyController             = {
        uiPrefab = "UIActivityBattlePassN5BuyController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityBattlePassN5BuyLevelController        = {
        uiPrefab = "UIActivityBattlePassN5BuyLevelController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityBattlePassN5AwardController           = {
        uiPrefab = "UIActivityBattlePassN5AwardController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    -- 1.5周年PV
    UIActivityOneAndHalfAnniversaryController       = {
        uiPrefab = "UIActivityOneAndHalfAnniversaryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityOneAndHalfAnniversaryVideoController  = {
        uiPrefab = "UIActivityOneAndHalfAnniversaryVideoController.prefab",
        maskType = MaskType.MT_None
    },
    --endregion
    -- 回流系统
    UIActivityReturnSystemMainController            = {
        uiPrefab = "UIActivityReturnSystemMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --回流系统Tip
    UIActivityReturnSystemTipController             = {
        uiPrefab = "UIActivityReturnSystemTipController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICutsceneReviewController                      = {
        uiPrefab = "UICutsceneReview.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityPetTryController                      = {
        uiPrefab = "UIActivityPetTryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityReturnSystemIntro                     = {
        uiPrefab = "UIActivityReturnSystemIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityReturnSystemGetItem                   = {
        uiPrefab = "UIActivityReturnSystemGetItem.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetSkinObtainController                       = {
        uiPrefab = "UIPetSkinObtainController.prefab",
        maskType = MaskType.MT_None
    },
    -- 盗掘者迁徙记
    UIActivityGraveRobberMainController             = {
        uiPrefab = "UIActivityGraveRobberMainController.prefab",
        maskType = MaskType.MT_None
    },
    UICutsceneReviewController                      = {
        uiPrefab = "UICutsceneReview.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityPetTryController                      = {
        uiPrefab = "UIActivityPetTryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityReturnSystemIntro                     = {
        uiPrefab = "UIActivityReturnSystemIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityReturnSystemGetItem                   = {
        uiPrefab = "UIActivityReturnSystemGetItem.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIPetSkinObtainController                       = {
        uiPrefab = "UIPetSkinObtainController.prefab",
        maskType = MaskType.MT_None
    },
    -- 盗掘者迁徙记
    UIActivityGraveRobberMainController             = {
        uiPrefab = "UIActivityGraveRobberMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动N+6
    UIActivityNPlusSixBuildingMainController        = { uiPrefab = "UIActivityNPlusSixBuildingMainController.prefab" },
    UIActivityNPlusSixRewardController              = { uiPrefab = "UIActivityNPlusSixRewardController.prefab" },
    UIActivityNPlusSixBuildingTipsController        = {
        uiPrefab = "UIActivityNPlusSixBuildingTipsController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityNPlusSixMainController                = {
        uiPrefab = "UIActivityNPlusSixMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    UIActivityNPlusSixEventCompleteController       = { uiPrefab = "UIActivityNPlusSixEventCompleteController.prefab" },
    UINP6Level                                      = {
        uiPrefab = "UINP6Level.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    --活动N5
    UIN5MainController                              = {
        uiPrefab = "UIN5MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            --["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    --活动N5普通关
    UIActivityN5SimpleLevel                         = {
        uiPrefab = "UIActivityN5SimpleLevel.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            --["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    --活动N5普通关关卡详情
    UIActivityN5Stage                               = {
        uiPrefab = "UIActivityN5Stage.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN5PointDetail                         = {
        uiPrefab = "UIActivityN5PointDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --活动N5剧情
    UIN5StoryController                             = {
        uiPrefab = "UIN5StoryController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动N5战场
    UIN5BattleFieldController                       = {
        uiPrefab = "UIN5BattleFieldController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    --活动N5战场关卡信息
    UIN5BattleFieldStageInfo                        = {
        uiPrefab = "UIN5BattleFieldStageInfo.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --活动N5战场关卡敌方信息
    UIN5BattleFieldEnemyInfo                        = {
        uiPrefab = "UIN5BattleFieldEnemyInfo.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --活动N5战场结算
    UIN5BattleFieldBattleComplete                   = {
        uiPrefab = "UIN5BattleFieldBattleComplete.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动N5军功积分（个人进度）
    UIN5ProgressController                          = {
        uiPrefab = "UIN5ProgressController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN5Intro                                       = {
        uiPrefab = "UIN5Intro.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    --迷失之地入口界面
    UILostLandMainController                        = {
        uiPrefab = "UILostLandMainController.prefab",
        maskType = MaskType.MT_None
    },
    --迷失之地本关详情界面
    UILostLandMissionInfoController                 = {
        uiPrefab = "UILostLandMissionInfoController.prefab",
        maskType = MaskType.MT_None
    },
    --奖励预览
    UILostLandAwardViewController                   = {
        uiPrefab = "UILostLandAwardViewController.prefab",
        maskType = MaskType.MT_None
    },
    --关卡
    UILostLandStageController                       = {
        uiPrefab = "UILostLandStageController.prefab",
        maskType = MaskType.MT_None
    },
    --本周情报
    UILostLandWeekInfoController                    = {
        uiPrefab = "UILostLandWeekInfoController.prefab",
        maskType = MaskType.MT_None
    },
    --直升道具
    UIAwakeDirectly                                 = {
        uiPrefab = "UIAwakeDirectly.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动线性关通用的关卡详�?
    UIActivityLevelStage                            = {
        uiPrefab = "UIActivityLevelStage.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityLevelStageNew                         = {
        uiPrefab = "UIActivityStageNew.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --周爬�?
    UIWeekTowerController                           = {
        uiPrefab = "UIWeekTowerController.prefab",
        maskType = MaskType.MT_None
    },
    --N+7
    UIActivityN7MainController                      = {
        uiPrefab = "UIActivityN7MainController.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIN7Level                                       = {
        uiPrefab = "UIN7Level.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIBlackFightMain                                = {
        uiPrefab = "UIBlackFightMain.prefab",
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIBlackFightReputation                          = {
        uiPrefab = "UIBlackFightReputation.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIBlackFightPaper                               = {
        uiPrefab = "UIBlackFightPaper.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN7LevelDetailsController                      = {
        uiPrefab = "UIN7LevelDetailsController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIN7EnemyDetailsController                      = { uiPrefab = "UIN7EnemyDetailsController.prefab" },
    UIActivityN7Intro                               = {
        uiPrefab = "UIActivityN7Intro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动N8
    UIActivityN8MainController                      = {
        uiPrefab = "UIActivityN8MainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN8
        }
    },
    UIActivityN8LineMissionController               = {
        uiPrefab = "UIActivityN8LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN8
        }
    },
    UIActivityN8BattleSimulatorController           = {
        uiPrefab = "UIActivityN8BattleSimulatorController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN8
        }
    },
    UIActivityN8PersonProgressController            = {
        uiPrefab = "UIActivityN8PersonProgressController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --活动线性关通用的关卡详�?
    UIActivityLevelStage                            = {
        uiPrefab = "UIActivityLevelStage.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --直升道具
    UIAwakeDirectly                                 = {
        uiPrefab = "UIAwakeDirectly.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --伊芙行动点详�?
    UIEvePointDetail                                = {
        uiPrefab = "UIEvePointDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --伊芙醒山活动说明界面
    UIActivityEveSinsaIntrController                = {
        uiPrefab = "UIActivityEveSinsaIntrController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --世界boss
    UIWorldBossController                           = {
        uiPrefab = "UIWorldBossController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery
        }
    },
    --世界boss段位
    UIWorldBossDanDetailController                  = {
        uiPrefab = "UIWorldBossDanDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIWorldBossDanLastRecordController              = {
        uiPrefab = "UIWorldBossDanLastRecordController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIWorldBossRecordChoice                         = {
        uiPrefab = "UIWorldBossRecordChoice.prefab",
        maskType = MaskType.MT_None
    },
    UIWorldBossDanResult                            = {
        uiPrefab = "UIWorldBossDanResult.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIWorldBossDanDetailTipsController              = {
        uiPrefab = "UIWorldBossDanDetailTipsController.prefab",
        maskType = MaskType.MT_None
    },
    --GlobalBoss
    --Globalboss
    UIGlobalBossController                          = {
        uiPrefab = "UIGlobalBossController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMDiscovery
        }
    },
    UIBlobalBossRecordChoice                        = {
        uiPrefab = "UIBlobalBossRecordChoice.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIGlobalBossResultController                    = {
        uiPrefab = "UIGlobalBossResultController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIWorldBossDiffSelectController                 = {
        uiPrefab = "UIWorldBossDiffSelectController.prefab",
        maskType = MaskType.MT_None
    },

    UISailing                                       = {
        uiPrefab = "UISailing.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    UISailingChapter                                = {
        uiPrefab = "UISailingChapter.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    UIAircraftTactic                                = {
        uiPrefab = "UIAircraftTactic.prefab",
        maskType = MaskType
            .MT_None
    },
    UITacticTapeInfo                                = {
        uiPrefab = "UITacticTapeInfo.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDataBaseMapController                         = {
        uiPrefab = "UIDataBaseMapController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDataBaseController                            = {
        uiPrefab = "UIDataBaseController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITopRankController                             = {
        uiPrefab = "UITopRankController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITacticTapeProduceFree                         = {
        uiPrefab = "UITacticTapeProduceFree.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITacticTapeProduceSpeedup                      = {
        uiPrefab = "UITacticTapeProduceSpeedup.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UITacticTapeObtain                              = {
        uiPrefab = "UITacticTapeObtain.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMazeQuickFightController                      = {
        uiPrefab = "UIMazeQuickFightController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIAircraftTacticSwitch                          = {
        uiPrefab = "UIAircraftTacticSwitch.prefab",
        maskType = MaskType.MT_None
    },
    --活动N9
    UIActivityN9MainController                      = {
        uiPrefab = "UIActivityN9MainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    UIActivityN9LineMissionController               = {
        uiPrefab = "UIActivityN9LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    UIActivityN9ActionPointDetail                   = {
        uiPrefab = "UIActivityN9ActionPointDetail.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN9SubjectMainController                       = {
        uiPrefab = "UIN9SubjectMainController.prefab",
        maskType = MaskType.MT_None
    },
    UIN9Intro                                       = {
        uiPrefab = "UIN9Intro.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIN9HardLevel                                   = {
        uiPrefab = "UIN9HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    UIActivityShopControllerN9                      = {
        uiPrefab = "UIN9ShopController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    UIN9SubjectTestDetailController                 = {
        uiPrefab = "UIN9SubjectTestDetailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIN9SubjectNormalDetailController               = {
        uiPrefab = "UIN9SubjectNormalDetailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIN9SubjecIntroduce                             = {
        uiPrefab = "UIN9SubjecIntroduce.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --调整立绘
    UIChooseMainCgController                        = {
        uiPrefab = "UIChooseMainCgController.prefab",
        maskType = MaskType.MT_None
    },
    UIN9AnswerController                            = {
        uiPrefab = "UIN9AnswerController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN9ResultController                            = {
        uiPrefab = "UIN9ResultController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN9AnswerOnPauseController                     = {
        uiPrefab = "UIN9AnswerOnPauseController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN9AnswerControllerTest                        = {
        uiPrefab = "UIN9AnswerControllerTest.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN10MainController                             = {
        uiPrefab = "UIN10MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN10ShopController                             = { uiPrefab = "UIN10ShopController.prefab" },
    UIN10ShopTipsController                         = {
        uiPrefab = "UIN10ShopTipsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN10IntroController                            = {
        uiPrefab = "UIN10IntroController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    --N10活动 累计登录奖励
    UIN10TotalLoginAwardController                  = {
        uiPrefab = "UIN10TotalLoginAwardController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIAircraftTacticSwitch                          = {
        uiPrefab = "UIAircraftTacticSwitch.prefab",
        maskType = MaskType.MT_None
    },
    --获取材料觉醒
    UIOpenGiftGetMatController                      = {
        uiPrefab = "UIOpenGiftGetMatController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityPetTryPlusController                  = {
        uiPrefab = "UIActivityPetTryPlusController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN11Main                                       = {
        uiPrefab = "UIN11Main.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIN11Shop                                       = {
        uiPrefab = "UIN11Shop.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIN11Intro                                      = { uiPrefab = "UIN11Intro.prefab", maskType = MaskType.MT_None },
    UIN12MainController                             = {
        uiPrefab = "UIN12MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12NormalLevel                                = {
        uiPrefab = "UIN12NormalLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12HardlLevel                                 = {
        uiPrefab = "UIN12HardlLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12IntroController                            = {
        uiPrefab = "UIN12IntroController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIActivityN11LineMissionController              = {
        uiPrefab = "UIActivityN11LineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIActivtiyN11HardLevelController                = {
        uiPrefab = "UIActivtiyN11HardLevelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIActivityN11ActionPointDetail                  = {
        uiPrefab = "UIActivityN11ActionPointDetail.prefab",
        maskType = MaskType.MT_None
    },
    UIN12HardlLevelInfo                             = {
        uiPrefab = "UIN12HardlLevelInfo.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12EntrustStageController                     = {
        uiPrefab = "UIN12EntrustStageController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12EntrustStageDetailController               = {
        uiPrefab = "UIN12EntrustStageDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12EntrustStageIntroController                = {
        uiPrefab = "UIN12EntrustStageIntroController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12EntrustLevelController                     = {
        uiPrefab = "UIN12EntrustLevelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12MapBannerController                        = {
        uiPrefab = "UIN12MapBannerController.prefab",
        maskType = MaskType.MT_None
    },
    UIN12MapBoxController                           = {
        uiPrefab = "UIN12MapBoxController.prefab",
        maskType = MaskType.MT_None
    },
    UIN12MapExitsController                         = {
        uiPrefab = "UIN12MapExitsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12MapGetRewardsController                    = {
        uiPrefab = "UIN12MapGetRewardsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12MapCommonPopController                     = {
        uiPrefab = "UIN12MapCommonPopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12MapQuestController                         = {
        uiPrefab = "UIN12MapController_Quest.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12MapStageController                         = {
        uiPrefab = "UIN12MapController_Stage.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12MapStoryController                         = {
        uiPrefab = "UIN12MapController_Story.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12ChallengesContorl                          = {
        uiPrefab = "UIN12ChallengesContorl.prefab",
        maskType = MaskType.MT_None
    },
    UIN12SynopsisController                         = {
        uiPrefab = "UIN12SynopsisController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12IntegralController                         = {
        uiPrefab = "UIN12IntegralController.prefab",
        maskType = MaskType.MT_None
    },
    UIN12ChallengeTaskReward                        = {
        uiPrefab = "UIN12ChallengeTaskReward.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityDoubleDropIntroduce                   = { uiPrefab = "UIActivityDoubleDropIntroduce.prefab" },
    UIN12BattleAffix                                = {
        uiPrefab = "UIN12BattleAffix.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIQuestDailyExtraInfoController                 = {
        uiPrefab = "UIQuestDailyExtraInfoController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    --活动N13
    UIN13BuildController                            = {
        uiPrefab = "UIN13BuildController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIN13BuildConfirmController                     = {
        uiPrefab = "UIN13BuildConfirmController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN13BuildPlotController                        = {
        uiPrefab = "UIN13BuildPlotController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN13BuildRewardController                      = {
        uiPrefab = "UIN13BuildRewardController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN13MainController                             = {
        uiPrefab = "UIN13MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13
        }
    },
    UIN13LineMissionController                      = {
        uiPrefab = "UIN13LineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13
        }
    },
    UIN13IntroController                            = {
        uiPrefab = "UIN13IntroController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- 活动N14
    UIN14Main                                       = {
        uiPrefab = "UIN14Main.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIActivityN14LineMissionController              = {
        uiPrefab = "UIActivityN14LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIActivityN14HardMissionController              = {
        uiPrefab = "UIActivityN14HardMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIActivityN14Intro                              = {
        uiPrefab = "UIActivityN14Intro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN14Shop                                       = {
        uiPrefab = "UIN14Shop.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIQuestDailyExtraInfoController                 = {
        uiPrefab = "UIQuestDailyExtraInfoController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN14FishingGameStageController                 = {
        uiPrefab = "UIN14FishingGameStageController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIN14Intro                                      = {
        uiPrefab = "UIN14Intro.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIN14FishingGameController                      = {
        uiPrefab = "UIN14FishingGameController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIActivityN14ActionPointDetail                  = {
        uiPrefab = "UIActivityN14ActionPointDetail.prefab",
        maskType = MaskType.MT_None
    },
    -- N15
    UIN15MainController                             = {
        uiPrefab = "UIN15MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIN15LineMissionController                      = {
        uiPrefab = "UIN15LineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIN15IntroController                            = {
        uiPrefab = "UIN15IntroController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN15RaffleController                           = {
        uiPrefab = "UIN15RaffleController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIN15PoltController                             = {
        uiPrefab = "UIN15PoltController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN15RafflePopController                        = {
        uiPrefab = "UIN15RafflePopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN15DrawIntroController                        = {
        uiPrefab = "UIN15DrawIntroController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN15ChessController                            = {
        uiPrefab = "UIN15ChessController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIChessIntro                                    = {
        uiPrefab = "UIChessIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- N16
    UIActivityN16MainController                     = {
        uiPrefab = "UIActivityN16MainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIActivityN16LineMissionController              = {
        uiPrefab = "UIActivityN16LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIActivityN16ActionPointDetail                  = {
        uiPrefab = "UIActivityN16ActionPointDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN16SubjectMainController                      = {
        uiPrefab = "UIN16SubjectMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIN16Intro                                      = {
        uiPrefab = "UIN16Intro.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UIN16HardLevel                                  = {
        uiPrefab = "UIN16HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIActivityShopControllerN16                     = {
        uiPrefab = "UIN16ShopController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIN16SubjectTestDetailController                = {
        uiPrefab = "UIN16SubjectTestDetailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIN16SubjectNormalDetailController              = {
        uiPrefab = "UIN16SubjectNormalDetailController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIN16SubjecIntroduce                            = {
        uiPrefab = "UIN16SubjecIntroduce.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN16AnswerController                           = {
        uiPrefab = "UIN16AnswerController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN16ResultController                           = {
        uiPrefab = "UIN16ResultController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN16AnswerOnPauseController                    = {
        uiPrefab = "UIN16AnswerOnPauseController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN16AnswerControllerTest                       = {
        uiPrefab = "UIN16AnswerControllerTest.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN16Intro                                      = { uiPrefab = "UIN16Intro.prefab", maskType = MaskType.MT_BlurMask },
    UIActivityN16MainLobbyEntry                     = {
        uiPrefab = "UIActivityN16MainLobbyEntry.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- N17
    UIN17MainController                             = {
        uiPrefab = "UIN17MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17MainTipsController                         = {
        uiPrefab = "UIN17MainTipsController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17DailyPlanController                        = {
        uiPrefab = "UIN17DailyPlanController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17LotteryController                          = { uiPrefab = "UIN17LotteryController.prefab" },
    UIN17LotteryTipsController                      = {
        uiPrefab = "UIN17LotteryTipsController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17IntroController                            = {
        uiPrefab = "UIN17IntroController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17Intro2Controller                           = {
        uiPrefab = "UIN17Intro2Controller.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17
        }
    },
    UIN17GetItemController                          = {
        uiPrefab = "UIN17GetItemController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN17,
            ["UISetParamOnShowComponent"] = {
                [UIComponentParamType.KeepVoice] = true
            }
        }
    },
    UIN17MessageBoxController                       = {
        uiPrefab = "UIN17MessageBoxController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- 周年登录活动
    UIActivityAnniversaryLoginController            = {
        uiPrefab = "AnniversaryLoginController.prefab",
        maskType = MaskType.MT_None
    },
    UISetAutoFightEnhanceWarning                    = {
        uiPrefab = "UISetAutoFightEnhanceWarning.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteCoutureDrawController                    = {
        uiPrefab = "UIHauteCoutureDrawController.prefab",
        maskType = MaskType.MT_None
    },
    --高级时装控制
    UIHauteCoutureDrawV2Controller                  = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsaShop
        }
    },
    --高级时装复刻控制
    UIHauteCoutureDrawV2ReviewController            = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteCoutureDuplicateReward                   = {
        uiPrefab = "UIHauteCoutureDuplicateReward.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawRulesV2Controller             = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawDynamicProbablityV2Controller = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawGetItemV2Controller           = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawChargeV2Controller            = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawVideoV2Controller             = {
        uiPrefab = "UIHauteCoutureControllerTemplate.prefab",
        maskType = MaskType.MT_None
    },
    -- 召集馈赠
    UIActivitySummonGiftController                  = {
        uiPrefab = "UIActivitySummonGiftController.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    -- N18
    UIN18MainController                             = {
        uiPrefab = "UIN18MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN18
        }
    },
    UIN18LineMissionController                      = {
        uiPrefab = "UIN18LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN18
        }
    },
    UIN18HardMissionController                      = {
        uiPrefab = "UIN18HardMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN18
        }
    },
    UIN18Intro                                      = {
        uiPrefab = "UIN18Intro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN18Intro2                                     = {
        uiPrefab = "UIN18Intro2.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN18Shop                                       = {
        uiPrefab = "UIN18ShopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --region N20
    UIN20AVGMain                                    = {
        uiPrefab = "UIN20AVGMain.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN20
        }
    },
    UIN20AVGIntro                                   = {
        uiPrefab = "UIN20AVGIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN20AVGStory                                   = { uiPrefab = "UIN20AVGStory.prefab", maskType = MaskType.MT_None },
    UIN20AVGEnding                                  = {
        uiPrefab = "UIN20AVGEnding.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN20AVGGraph                                   = {
        uiPrefab = "UIN20AVGGraph.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN20AVGNodeDetails                             = {
        uiPrefab = "UIN20AVGNodeDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN20AVGCollection                              = {
        uiPrefab = "UIN20AVGCollection.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN20AVGReview                                  = {
        uiPrefab = "UIN20AVGReview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --endregion
    --region N22
    UIN22MedalEdit                                  = { uiPrefab = "UIN22MedalEdit.prefab", maskType = MaskType.MT_None },
    UIN22MedalEditRotate                            = {
        uiPrefab = "UIN22MedalEditRotate.prefab",
        maskType = MaskType.MT_None
    },
    UIN22MedalFilter                                = {
        uiPrefab = "UIN22MedalFilter.prefab",
        maskType = MaskType
            .MT_None
    },
    UIN22MedalChangeBoard                           = {
        uiPrefab = "UIN22MedalChangeBoard.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --endregion
    --region N23
    UIN23Main                                       = {
        uiPrefab = "UIN23Main.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN23
        }
    },
    UIN23Line                                       = {
        uiPrefab = "UIN23Line.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN23
        }
    },
    UIN23Shop                                       = {
        uiPrefab = "UIN23Shop.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN23
        }
    },
    UIN23Replay                                     = {
        uiPrefab = "UIN23Replay.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UIN23Movie                                      = { uiPrefab = "UIN23Movie.prefab", maskType = MaskType.MT_BlurMask },
    --endregion
    --region N24
    UIN24Shop                                       = {
        uiPrefab = "UIN24Shop.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN24
        }
    },
    UIN24ShopIntro                                  = { uiPrefab = "UIN24ShopIntro.prefab", maskType = MaskType.MT_None },
    --endregion
    --region N25
    UIActivtiyN25HardLevelController                = {
        uiPrefab = "UIN25HardLevelController.prefab",
        maskType = MaskType.MT_None
    },
    UIN25Line                                       = { uiPrefab = "UIN25Line.prefab", maskType = MaskType.MT_None },
    UIN25Shop                                       = {
        uiPrefab = "UIN25Shop.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN25MainController                     = {
        uiPrefab = "UIActivityN25MainController.prefab",
        maskType = MaskType.MT_None
    },
    UIN25VampireMain                                = {
        uiPrefab = "UIN25VampireMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN25Vampire
        }
    },
    UIN25VampireTalentTree                          = {
        uiPrefab = "UIN25VampireTalentTree.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN25Vampire
        }
    },
    UIN25VampireRoleSkill                           = {
        uiPrefab = "UIN25VampireRoleSkill.prefab",
        maskType = MaskType.MT_None
    },
    UIN25VampireTalentIntro                         = {
        uiPrefab = "UIN25VampireTalentIntro.prefab",
        maskType = MaskType.MT_None
    },
    UIN25VampireTips                                = {
        uiPrefab = "UIN25VampireTips.prefab",
        maskType = MaskType
            .MT_None
    },
    UIN25VampireTalentSkillTips                     = {
        uiPrefab = "UIN25VampireTalentSkillTips.prefab",
        maskType = MaskType.MT_None
    },
    UIN25VampireTalentItemTips                      = {
        uiPrefab = "UIN25VampireTalentItemTips.prefab",
        maskType = MaskType.MT_None
    },
    --endregion

    --卡莲高级时装
    UIHauteCoutureDrawDynamicProbablityController   = {
        uiPrefab = "UIHauteCoutureDrawDynamicProbablityController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawRulesController               = {
        uiPrefab = "UIHauteCoutureDrawRulesController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHauteCoutureDrawChargeController              = {
        uiPrefab = "UIHauteCoutureDrawChargeController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISetAutoFightEnhanceWarning                    = {
        uiPrefab = "UISetAutoFightEnhanceWarning.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteVideoController                          = {
        uiPrefab = "UIHauteVideoController.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteCoutureGetItemController                 = {
        uiPrefab = "UIHauteCoutureGetItemController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    -- 棱镜消�?
    UIActivityPowerCostController                   = {
        uiPrefab = "UIActivityPowerCostController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISignInActBoxTipsController                    = {
        uiPrefab = "UISignInActBoxTipsController.prefab",
        maskType = MaskType.MT_None
    },
    UIHomePetInteract                               = {
        uiPrefab = "UIHomePetInteract.prefab",
        maskType = MaskType.MT_None
    },
    UIHomePetFollowList                             = {
        uiPrefab = "UIHomePetFollowList.prefab",
        maskType = MaskType.MT_None
    },
    UIHomePhotoController                           = {
        uiPrefab = "UIHomePhotoController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomePhotoInfoController                       = {
        uiPrefab = "UIHomePhotoInfoController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeDomitory                                  = {
        uiPrefab = "UIHomeDomitory.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeStoryController                           = {
        uiPrefab = "UIHomeStoryController.prefab",
        maskType = MaskType.MT_None
    },
    UIHomelandBreed                                 = {
        uiPrefab = "UIHomelandBreed.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBreedItemSelect                       = {
        uiPrefab = "UIHomelandBreedItemSelect.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBreedPreview                          = {
        uiPrefab = "UIHomelandBreedPreview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBreedResult                           = {
        uiPrefab = "UIHomelandBreedResult.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBreedManualInfo                       = {
        uiPrefab = "UIHomelandBreedManualInfo.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandBreedDirective                        = {
        uiPrefab = "UIHomelandBreedDirective.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandTreeDye                               = {
        uiPrefab = "UIHomelandTreeDye.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeDomitoryChangeName                        = {
        uiPrefab = "UIHomeDomitoryChangeName.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeDomitorySettle                            = {
        uiPrefab = "UIHomeDomitorySettle.prefab",
        maskType = MaskType.MT_None
    },
    UIHomeDomitoryAffinityRule                      = {
        uiPrefab = "UIHomeDomitoryAffinityRule.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomePetStoryReview                            = {
        uiPrefab = "UIHomePetStoryReview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIStoryViewer3D                                 = {
        uiPrefab = "UIStoryViewer3D.prefab",
        maskType = MaskType.MT_None
    },
    --寻宝小游�?
    UIFindTreasureInteractMain                      = {
        uiPrefab = "UIFindTreasureInteractMain.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityBetweenTheChaptersController          = {
        uiPrefab = "UIActivityBetweenTheChaptersController.prefab",
        maskType = MaskType.MT_None
    },
    UIFindTreasureDetail                            = {
        uiPrefab = "UIFindTreasureDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIFindTreasureStartGame                         = {
        uiPrefab = "UIFindTreasureStartGame.prefab",
        maskType = MaskType.MT_None
    },
    UIFindTreasureMain                              = {
        uiPrefab = "UIFindTreasureMain.prefab",
        maskType = MaskType.MT_None
    },
    UIFindTreasureFailure                           = {
        uiPrefab = "UIFindTreasureFailure.prefab",
        maskType = MaskType.MT_None
    },
    UIFindTreasureSuccess                           = {
        uiPrefab = "UIFindTreasureSuccess.prefab",
        maskType = MaskType.MT_None
    },
    --home help
    UIHomeHelpController                            = {
        uiPrefab = "UIHomeHelpController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeShowAwards                                = {
        uiPrefab = "UIHomeShowAwards.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeLandDiaryContentsController               = {
        uiPrefab = "UIHomeLandDiaryContentsController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeLandDiaryController                       = {
        uiPrefab = "UIHomeLandDiaryController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeVisitFriends                              = {
        uiPrefab = "UIHomeVisitFriends.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeStorehouse                                = {
        uiPrefab = "UIHomeStorehouse.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeVisitGetGift                              = {
        uiPrefab = "UIHomeVisitGetGift.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomeVisitSpeedup                              = {
        uiPrefab = "UIHomeVisitSpeedup.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandTask                                  = {
        uiPrefab = "UIHomelandTask.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandTaskFinishEffect                      = {
        uiPrefab = "UIHomelandTaskFinishEffect.prefab",
        maskType = MaskType.MT_None
    },
    UIItemExChangeController                        = {
        uiPrefab = "UIItemExChangeController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomeGiftSelector                              = {
        uiPrefab = "UIHomeGiftSelector.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandDecompose                             = {
        uiPrefab = "UIHomelandDecompose.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandAccelerate                            = {
        uiPrefab = "UIHomelandAccelerate.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIForgeOneKeyUnlock                             = {
        uiPrefab = "UIForgeOneKeyUnlock.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIDiffStage                                     = {
        uiPrefab = "UIDiffStage.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandFixBuilding                           = {
        uiPrefab = "UIHomelandFixBuilding.prefab",
        maskType = MaskType.MT_None
    },
    UIHomePetFollow                                 = {
        uiPrefab = "UIHomePetFollowController.prefab",
        maskType = MaskType.MT_None
    },
    UIStageWordTips                                 = {
        uiPrefab = "UIStageWordTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIStageElemTips                                 = {
        uiPrefab = "UIStageElemTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISailingWordTips                               = {
        uiPrefab = "UISailingWordTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISailingElementTips                            = {
        uiPrefab = "UISailingElementTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISailingBattleResultTips                       = {
        uiPrefab = "UISailingBattleResultTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    -- N19
    UIN19MainController                             = {
        uiPrefab = "UIN19MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN19
        }
    },
    UIN19LineMissionController                      = {
        uiPrefab = "UIN19LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN19
        }
    },
    UIN19HardLevelController                        = {
        uiPrefab = "UIN19HardLevelController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN19
        }
    },
    UIN19P5Controller                               = {
        uiPrefab = "UIN19P5Controller.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN19P5
        }
    },
    UIN19P5Tip                                      = { uiPrefab = "UIN19P5Tip.prefab", maskType = MaskType.MT_BlurMask },
    UIN19P5SignInController                         = {
        uiPrefab = "UIN19P5SignInController.prefab",
        maskType = MaskType.MT_None
    },
    UIN19P5AwardController                          = {
        uiPrefab = "UIN19P5AwardController.prefab",
        maskType = MaskType.MT_None
    },
    UIN19P5IntrController                           = {
        uiPrefab = "UIN19P5IntrController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN19P5ShowAwards                               = {
        uiPrefab = "UIN19P5ShowAwards.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityN20MainController                     = {
        uiPrefab = "UIActivityN20MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN20
        }
    },
    UIActivityN20Intro                              = {
        uiPrefab = "UIActivityN20Intro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN20NormalLevel                        = {
        uiPrefab = "UIActivityN20NormalLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN20
        }
    },
    UIActivityN20ActionPointDetail                  = {
        uiPrefab = "UIActivityN20ActionPointDetail.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN20HardLevel                          = {
        uiPrefab = "UIActivityN20HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN20
        }
    },
    UIActivityN20Shop                               = {
        uiPrefab = "UIActivityN20Shop.prefab",
        maskType = MaskType.MT_None
    },
    UIHomeLandDiaryEnterController                  = {
        uiPrefab = "UIHomeLandDiaryEnterController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandStoryTaskController                   = {
        uiPrefab = "UIHomelandStoryTaskController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICampainEnterController                        = {
        uiPrefab = "UICampainEnterController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandStoryTaskSimpleController             = {
        uiPrefab = "UIHomelandStoryTaskSimpleController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandStoryTaskActionPointDetail            = {
        uiPrefab = "UIHomelandStoryTaskActionPointDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --通用cri播放视频
    UICriVideoController                            = {
        uiPrefab = "UICriVideoController.prefab",
        maskType = MaskType.MT_None
    },
    --region 活动回顾
    UIExtraSelect                                   = {
        uiPrefab = "UIExtraSelect.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIReviewUnlockTip                               = {
        uiPrefab = "UIReviewUnlockTip.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityReview                                = {
        uiPrefab = "UIActivityReview.prefab",
        maskType = MaskType
            .MT_None
    },
    UIReviewDownloadTip                             = {
        uiPrefab = "UIReviewDownloadTip.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityEveSinsaMainController_Review         = {
        uiPrefab = "UIActivityEveSinsaMainController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIActivityEveSinsaLevelAController_Review       = {
        uiPrefab = "UIActivityEveSinsaLevelAController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIActivityEveSinsaLevelBController_Review       = {
        uiPrefab = "UIActivityEveSinsaLevelBController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsa
        }
    },
    UIReviewProgressAwardDetail                     = {
        uiPrefab = "UIReviewProgressAwardDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISakuraController_Review                       = {
        uiPrefab = "UISakuraController_Review.prefab",
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISakuraEntryController_Review                  = {
        uiPrefab = "UISakuraEntryController_Review.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSakura
        }
    },
    UISummer1Review                                 = {
        uiPrefab = "UISummer1Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1
        }
    },
    UIXH1SimpleLevelReview                          = {
        uiPrefab = "UIXH1SimpleLevelReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1
        }
    },
    UIXH1HardLevelReview                            = {
        uiPrefab = "UIXH1HardLevelReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1Hard
        }
    },
    UISummer1RewardDetailRewivw                     = {
        uiPrefab = "UISummer1RewardDetailRewivw.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1
        }
    },
    UISummer2MainControllerReview                   = {
        uiPrefab = "UISummer2MainControllerReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMSummer1Hard
        }
    },
    UIN5MainController_Review                       = {
        uiPrefab = "UIN5MainController_Review.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    UIActivityN5SimpleLevelReview                   = {
        uiPrefab = "UIActivityN5SimpleLevel_Review.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN5
        }
    },
    UIN5ReviewProgressAwardDetail                   = {
        uiPrefab = "UIReviewProgressAwardDetail_N5.prefab",
        maskType = MaskType.MT_None
    },
    UIN7MainReview                                  = {
        uiPrefab = "UIN7MainReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIN7LevelReview                                 = {
        uiPrefab = "UIN7LevelReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIN7AwardProgressReview                         = {
        uiPrefab = "UIN7AwardProgressReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIBlackFightPaperReview                         = {
        uiPrefab = "UIBlackFightPaperReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN7
        }
    },
    UIActivityN8LineMissionController_Review        = {
        uiPrefab = "UIActivityN8LineMissionController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN8
        }
    },
    UIActivityN8MainController_Review               = {
        uiPrefab = "UIActivityN8MainController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN8
        }
    },
    UIActivityN9MainController_Review               = {
        uiPrefab = "UIActivityN9MainController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    UIActivityN9LineMissionController_Review        = {
        uiPrefab = "UIActivityN9LineMissionController_Review.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN9
        }
    },
    --endregion
    UIHomelandAlbum                                 = { uiPrefab = "UIHomelandAlbum.prefab" },
    UIN20MiniGameStageController                    = {
        uiPrefab = "UIN20MiniGameStageController.prefab",
        maskType = MaskType.MT_None
    },
    UIN20MiniGameController                         = {
        uiPrefab = "UIN20MiniGameController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN20MiniGameHelp                               = {
        uiPrefab = "UIN20MiniGameHelp.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN21CCMainController                   = {
        uiPrefab = "UIActivityN21CCMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIActivityN21CCIntro                            = {
        uiPrefab = "UIActivityN21CCIntro.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN21CCLevelDetail                      = {
        uiPrefab = "UIActivityN21CCLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIActivityN21CCShowCardController               = {
        uiPrefab = "UIActivityN21CCShowCardController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandAquarium                              = {
        uiPrefab = "UIHomelandAquarium.prefab",
        maskType = MaskType.MT_None
    },
    ---n21
    UIN21LineMissionController                      = {
        uiPrefab = "UIN21LineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIN21Controller                                 = {
        uiPrefab = "UIN21Controller.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIN21IntrController                             = {
        uiPrefab = "UIN21IntrController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN21ShopController                             = {
        uiPrefab = "UIN21ShopController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIActivityN21CCAffixDetail                      = {
        uiPrefab = "UIActivityN21CCAffixDetail.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN21CCShop                             = {
        uiPrefab = "UIActivityN21CCShop.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN21
        }
    },
    UIHomePetInvite                                 = {
        uiPrefab = "UIHomePetInvite.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomePetInviteEnable                           = {
        uiPrefab = "UIHomePetInviteEnable.prefab",
        maskType = MaskType.MT_BlurMask
    },
    ---
    UIShopHomelandSet                               = {
        uiPrefab = "UIShopHomelandSet.prefab",
        maskType = MaskType.MT_None,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIShopHomelandParts                             = {
        uiPrefab = "UIShopHomelandParts.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIShopHomelandPrecious                          = {
        uiPrefab = "UIShopHomelandPrecious.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIShopHomelandGetCoin                           = {
        uiPrefab = "UIShopHomelandGetCoin.prefab",
        maskType = MaskType.MT_MoreBlackMask
    },
    UIShopHomelandPreview                           = {
        uiPrefab = "UIShopHomelandPreview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    ---勋章
    UIMedalMainController                           = {
        uiPrefab = "UIMedalMainController.prefab",
        maskType = MaskType.MT_None
    },
    UIMedalListController                           = {
        uiPrefab = "UIMedalListController.prefab",
        maskType = MaskType.MT_None
    },
    UIMedalGroupTipsController                      = {
        uiPrefab = "UIMedalGroupTipsController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UIMedalGroupListController                      = {
        uiPrefab = "UIMedalGroupListController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIMedalTipsController                           = {
        uiPrefab = "UIMedalTipsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMedalTipsHomelandController                   = {
        uiPrefab = "UIMedalTipsHomelandController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMedalCardDetailController                     = {
        uiPrefab = "UIMedalCardDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISailingLevelDetail                            = {
        uiPrefab = "UISailingLevelDetail.prefab",
        maskType = MaskType.MT_None
    },
    UIMedalBgListController                         = {
        uiPrefab = "UIMedalBgListController.prefab",
        maskType = MaskType.MT_None
    },
    UIMedalGroupApply                               = {
        uiPrefab = "UIMedalGroupApply.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISailingLevelResetTeam                         = {
        uiPrefab = "UISailingLevelResetTeam.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UISailingRewardsController                      = {
        uiPrefab = "UISailingRewardsController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    ---N22
    UIActivityN22MainController                     = {
        uiPrefab = "UIN22MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIActivityN22LineMissionController              = {
        uiPrefab = "UIN22LineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIActivtiyN22HardLevelController                = {
        uiPrefab = "UIN22HardLevelController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIActivityN22Intro                              = {
        uiPrefab = "UIN22Intro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivtiyN22ShopController                     = {
        uiPrefab = "UIN22ShopController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN12EntrustStageController                     = {
        uiPrefab = "UIN12EntrustStageController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN22EntrustStageController                     = {
        uiPrefab = "UIN22EntrustStageController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN22EntrustStageDetailController               = {
        uiPrefab = "UIN22EntrustStageDetailController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN22EntrustLevelController                     = {
        uiPrefab = "UIN22EntrustLevelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN22EntrustMsgPopController                    = {
        uiPrefab = "UIN22Entrust_MsgPopController.prefab",
        maskType = MaskType.MT_None
    },
    UIN22EntrustRewardsController                   = {
        uiPrefab = "UIN22Entrust_RewardsController.prefab",
        maskType = MaskType.MT_None
    },
    UIN22EntrustEventController                     = {
        uiPrefab = "UIN22EntrustEventController.prefab",
        maskType = MaskType.MT_None
    },
    --拍电�?
    UIHomelandMoviePrepareMainController            = {
        uiPrefab = "UIHomelandMoviePrepareMainController.prefab",
        maskType = MaskType.MT_None
    },
    UIHomelandMovieIntroduceController              = {
        uiPrefab = "UIHomelandMovieIntroduceController.prefab", --电影简�?
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMovieTaskIntroduceController          = {
        uiPrefab = "UIHomelandMovieTaskIntroduceController.prefab", --拍电影任务简�?
        maskType = MaskType.MT_None
    },
    UIHomelandMovieMainController                   = {
        uiPrefab = "UIHomelandMovieMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMovieActorController                  = {
        uiPrefab = "UIHomelandMovieActorController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandAnonymousMovieController              = {
        uiPrefab = "UIHomelandAnonymousMovieController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandAnonymousPopController                = {
        uiPrefab = "UIHomelandAnonymousPopController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIHomelandMoviePlaybackController               = {
        uiPrefab = "UIHomelandMoviePlaybackController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMovieExplainController                = {
        uiPrefab = "UIHomelandMovieExplainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UIHomelandMovieSaveName                         = {
        uiPrefab = "UIHomelandMovieSaveName.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMovieClosingController                = {
        uiPrefab = "UIHomelandMovieClosingController.prefab",
        maskType = MaskType.MT_None
    },
    --剧情
    UIHomeMovieStoryController                      = {
        uiPrefab = "UIHomeMovieStoryController.prefab",
        maskType = MaskType.MT_None
    },
    UIHomelandMovieActionController                 = {
        uiPrefab = "UIHomelandMovieActionController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIHomelandMovieSaveReplaceController            = {
        uiPrefab = "UIHomelandMovieSaveReplaceController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMiniMazeChoosePartnerController               = {
        uiPrefab = "UIMiniMazeChoosePartnerController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIMiniMazeChooseRelicController                 = {
        uiPrefab = "UIMiniMazeChooseRelicController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN24MainController                     = {
        uiPrefab = "UIActivityN24MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN24
        }
    },
    UIHauteCoutureDraw_Review                       = {
        uiPrefab = "UIHauteCoutureDraw_Review.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteCoutureDrawDuplicateReward               = {
        uiPrefab = "UIHauteCoutureDrawDuplicateReward.prefab",
        maskType = MaskType.MT_None
    },
    UIHauteCoutureDrawChargeController_Re           = {
        uiPrefab = "UIHauteCoutureDrawChargeController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --钓鱼比赛结算
    UIHomelandFishMatchEnd                          = {
        uiPrefab = "UIHomelandFishMatchEnd.prefab",
        maskType = MaskType.MT_None
    },
    --局�?-阿克希亚-扫描模块控制UI
    UIFeatureScanController                         = {
        uiPrefab = "UIFeatureScanController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN24SpecialTask                                = {
        uiPrefab = "UIN24SpecialTask.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --n25
    UIN25IdolLogin                                  = {
        uiPrefab = "UIN25IdolLogin.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN25IdolBreakLoad                              = {
        uiPrefab = "UIN25IdolBreakLoad.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25IdolBreakTips                              = {
        uiPrefab = "UIN25IdolBreakTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25IdolLoading                                = {
        uiPrefab = "UIN25IdolLoading.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25IdolSumUp                                  = { uiPrefab = "UIN25IdolSumUp.prefab", maskType = MaskType.MT_None },
    UIN25IdolEndCG                                  = { uiPrefab = "UIN25IdolEndCG.prefab", maskType = MaskType.MT_None },
    UIN25IdolCollection                             = {
        uiPrefab = "UIN25IdolCollection.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolGetItem                                = {
        uiPrefab = "UIN25IdolGetItem.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIN25IdolGame                                   = { uiPrefab = "UIN25Idol_Game.prefab", maskType = MaskType.MT_None },
    UIN25IdolGamePuppy                              = {
        uiPrefab = "UIN25Idol_Game_Puppy.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolGameTraining                           = {
        uiPrefab = "UIN25Idol_Game_Training.prefab",
        maskType = MaskType.MT_None
    },
    UIN6MainController_Review                       = {
        uiPrefab = "UIN6MainController_Review.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    UIActivityN6LineMissionReview                   = {
        uiPrefab = "UIActivityN6LineMissionReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    UIActivityN6ReviewBuildingMainController        = {
        uiPrefab = "UIActivityN6ReviewBuildingMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    UIActivityN6ReviewRewardController              = {
        uiPrefab = "UIActivityNPlusSixRewardController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN6
        }
    },
    UIN25VampireTips                                = {
        uiPrefab = "UIN25VampireTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25VampireLevel                               = {
        uiPrefab = "UIN25VampireLevel.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN25Vampire
        }
    },
    UIN25VampireChallengeTask                       = {
        uiPrefab = "UIN25VampireChallengeTask.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25VampireChallengeTaskGain                   = {
        uiPrefab = "UIN25VampireChallengeTaskGain.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --idol concert
    UIN25IdolAct                                    = { uiPrefab = "UIN25Idol_Act.prefab", maskType = MaskType.MT_None },
    UIN25IdolActResult                              = {
        uiPrefab = "UIN25Idol_ActResult.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolApController                           = { uiPrefab = "UIN25Idol_Ap.prefab", maskType = MaskType.MT_None },
    UIN25IdolApResult                               = {
        uiPrefab = "UIN25Idol_ApResult.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolConcertEnter                           = {
        uiPrefab = "UIN25Idol_ConcertEnter.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25IdolConcert                                = {
        uiPrefab = "UIN25Idol_Concert.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolConcertResult                          = {
        uiPrefab = "UIN25Idol_ConcertResult.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN25NewYear                                    = {
        uiPrefab = "UIN25NewYear.prefab",
        maskType = MaskType
            .MT_BlurMask
    },
    UIN25NewYearAwards                              = {
        uiPrefab = "UIN25NewYearAwards.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN25IdolStoryController                        = {
        uiPrefab = "UIN25IdolStoryController.prefab",
        maskType = MaskType.MT_None
    },
    UIN25IdolNotOpenNextDay                         = {
        uiPrefab = "UIN25Idol_NotOpenNextDay.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --n26
    UIActivityN26MainController                     = {
        uiPrefab = "UIActivityN26MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN26
        }
    },
    UIN26Line                                       = {
        uiPrefab = "UIN26Line.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN26
        }
    },
    UIN26HardLevel                                  = {
        uiPrefab = "UIN26HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN26
        }
    },
    UIActivityN26Shop                               = {
        uiPrefab = "UIActivityN26Shop.prefab",
        maskType = MaskType.MT_None
    },
    UIN26Movie                                      = { uiPrefab = "UIN26Movie.prefab", maskType = MaskType.MT_BlurMask },
    UIN26CookMakeSuccController                     = {
        uiPrefab = "UIN26CookMakeSuccController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN26CookMakeFailedController                   = {
        uiPrefab = "UIN26CookMakeFailedController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN26CookMainController                         = {
        uiPrefab = "UIN26CookMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN26
        }
    },
    UIN26CookMatRequireController                   = {
        uiPrefab = "UIN26CookMatRequireController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN26CookBookController                         = {
        uiPrefab = "UIN26CookBookController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN26CookMakeController                         = {
        uiPrefab = "UIN26CookMakeController.prefab",
        maskType = MaskType.MT_None
    },
    --n27
    UIN27PostInnerGameController                    = {
        uiPrefab = "UIN27PostInnerGameController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIActivityN27HardLevelMain                      = {
        uiPrefab = "UIActivityN27HardLevelMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN27
        }
    },
    UIActivityN27DiffLevelDetail                    = {
        uiPrefab = "UIActivityN27DiffLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityDiffLevelDetail                       = {
        uiPrefab = "UIActivityDiffLevelDetail.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN27LotteryMain                                = {
        uiPrefab = "UIN27LotteryMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMEveSinsaShop
        }
    },
    UIN27LotteryTips                                = {
        uiPrefab = "UIN27LotteryTips.prefab",
        maskType = MaskType
            .MT_None
    },
    UIN27LotteryPlot                                = {
        uiPrefab = "UIN27LotteryPlot.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN27LotteryUnlockPool                          = {
        uiPrefab = "UIN27LotteryUnlockPool.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN27LotteryGetItem                             = {
        uiPrefab = "UIN27LotteryGetItem.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIN27PostGameClosingController                  = {
        uiPrefab = "UIN27PostGameClosingController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN27MiniGameController                         = {
        uiPrefab = "UIN27MiniGameController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN27MiniGame
        }
    },
    --n27情人节小游戏
    UIActivityValentineEndController                = {
        uiPrefab = "UIActivityValentineEndController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityValentineMailboxController            = {
        uiPrefab = "UIActivityValentineMailboxController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityValentineMainController               = {
        uiPrefab = "UIActivityValentineMainController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityValentineGetController                = {
        uiPrefab = "UIActivityValentineGetController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityValentineLetterController             = {
        uiPrefab = "UIActivityValentineLetterController.prefab",
        maskType = MaskType.MT_None
    },
    UIN27Controller                                 = {
        uiPrefab = "UIN27Controller.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN27
        }
    },
    UIN27LineMissionController                      = {
        uiPrefab = "UIN27LineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN27
        }
    },
    UIN27IntrController                             = {
        uiPrefab = "UIN27IntrController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = { ["UITransitionComponent"] = {} }
    },
    UIActivityValentineOpenLetterController         = {
        uiPrefab = "UIActivityValentineOpenLetterController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityValentineSendLetterController         = {
        uiPrefab = "UIActivityValentineSendLetterController.prefab",
        maskType = MaskType.MT_None
    },
    --n28
    UIActivityN28MainController                     = {
        uiPrefab = "UIActivityN28MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN28
        }
    },
    UIN28GronruPlatform                             =
    {
        uiPrefab = "UIN28GronruPlatform.prefab",
        maskType = MaskType.MT_None,
        uiComponents =
        {
            ["UISwitchBGMComponent"] = CriAudioIDConst.N28BounceBgmUI
        }
    },
    UIN28GronruGameForumDetails                     = {
        uiPrefab = "UIN28GronruGameForumDetails.prefab",
        maskType = MaskType.MT_None
    },
    UIN28ErrandController                           = {
        uiPrefab = "UIN28ErrandController.prefab",
        maskType = MaskType.MT_None
    },
    UIN28ErrandIntr                                 = {
        uiPrefab = "UIN28ErrandIntr.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UIN28GronruGameFlash                            = {
        uiPrefab = "UIN28GronruGameFlash.prefab",
        maskType = MaskType.MT_None
    },
    UIN28GronruGameSelectPlayer                     =
    {
        uiPrefab = "UIN28GronruGameSelectPlayer.prefab",
        maskType = MaskType.MT_None,
        uiComponents =
        {
            ["UISwitchBGMComponent"] = CriAudioIDConst.N28BoucneBgm
        }
    },
    UIN28GronruGameLevel                            =
    {
        uiPrefab = "UIN28GronruGameLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents =
        {
            ["UISwitchBGMComponent"] = CriAudioIDConst.N28BoucneBgm
        }
    },
    UIN28GronruGameRewards                          = {
        uiPrefab = "UIN28GronruGameRewards.prefab",
        maskType = MaskType.MT_None
    },
    UIN28AVGMain                                    = {
        uiPrefab = "UIN28AVGMain.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN20
        }
    },
    UIN28AVGIntro                                   = {
        uiPrefab = "UIN28AVGIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGStory                                   = { uiPrefab = "UIN28AVGStory.prefab", maskType = MaskType.MT_None },
    UIN28AVGEnding                                  = {
        uiPrefab = "UIN28AVGEnding.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGGraph                                   = {
        uiPrefab = "UIN28AVGGraph.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGNodeDetails                             = {
        uiPrefab = "UIN28AVGNodeDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGCollection                              = {
        uiPrefab = "UIN28AVGCollection.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGReview                                  = {
        uiPrefab = "UIN28AVGReview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28AVGStoryEvidenceBook                       = {
        uiPrefab = "UIN28AVGStoryEvidenceBook.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN28Shop                               = {
        uiPrefab = "UIActivityN28Shop.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN28HardLevel                                  = {
        uiPrefab = "UIN28HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN28
        }
    },
    UIN28Line                                       = {
        uiPrefab = "UIN28Line.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN28
        }
    },
    UIBounceMainController                          =
    {
        uiPrefab = "UIBounceMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents =
        {
            ["UISwitchBGMComponent"] = CriAudioIDConst.N28BounceFightBgm
        }
    },
    UIBounceMainController                          = {
        uiPrefab = "UIBounceMainController.prefab",
        maskType = MaskType.MT_None
    },
    --n29
    UIN29ChessController                            = {
        uiPrefab = "UIN29ChessController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIN29ChessIntro                                 = {
        uiPrefab = "UIN29ChessIntro.prefab",
        maskType = MaskType.MT_BlurMask
    },

    UIActivityN29MainController                     = {
        uiPrefab = "UIActivityN29MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN29
        }
    },
    UIActivityN29DetectiveMapController             = {
        uiPrefab = "UIActivityN29DetectiveMapController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIActivityN29DetectiveNewwayController          = {
        uiPrefab = "UIActivityN29DetectiveNewwayController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN29DetectiveWayController             = {
        uiPrefab = "UIActivityN29DetectiveWayController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN29DetectiveBagController             = {
        uiPrefab = "UIActivityN29DetectiveBagController.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveLogin                             = {
        uiPrefab = "UIN29DetectiveLogin.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN29DetectiveArchiveLoad                       = {
        uiPrefab = "UIN29DetectiveArchiveLoad.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveBreakLoad                         = {
        uiPrefab = "UIN29DetectiveBreakLoad.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveBreakTips                         = {
        uiPrefab = "UIN29DetectiveBreakTips.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveReasoning                         = {
        uiPrefab = "UIN29DetectiveReasoning.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveReasoningClueDetails              = {
        uiPrefab = "UIN29DetectiveReasoningClueDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN29DetectiveFragmentPopup                     = {
        uiPrefab = "UIN29DetectiveFragmentPopup.prefab",
        maskType = MaskType.MT_None
    },
    UIN29DetectiveCollection                        = {
        uiPrefab = "UIN29DetectiveCollection.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN29HardLevelMain                      = {
        uiPrefab = "UIActivityN29HardLevelMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIActivityN11MainController_Review              = {
        uiPrefab = "UIActivityN11ReviewMain.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIActivityN11LineMissionController_Review       = {
        uiPrefab = "UIActivityN11ReviewLineMissionController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN11
        }
    },
    UIN29DetectivePersonController                  = {
        uiPrefab = "UIN29DetectivePersonController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN29DetectiveCluePopController                 = {
        uiPrefab = "UIN29DetectiveCluePopController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN29DetectiveSuspectController                 = {
        uiPrefab = "UIN29DetectiveSuspectController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },
    UIN29DetectiveReasoningPopController            = {
        uiPrefab = "UIN29DetectiveReasoningPopController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN22
        }
    },

    --周活跃度
    UIQuestDailyWeekAwards                          = {
        uiPrefab = "UIQuestDailyWeekAwards.prefab",
        maskType = MaskType.MT_BlurMask
    },
    --主动技变体
    UIActiveVarInfo                                 = { uiPrefab = "UIActiveVarInfo.prefab", maskType = MaskType.MT_None },
    UIActivityN29LineLevel                          = {
        uiPrefab = "UIActivityN29LineLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN29
        }
    },
    UIN29Shop                                       = {
        uiPrefab = "UIN29Shop.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN29
        }
    },
    UIN29ShopIntro                                  = { uiPrefab = "UIN29ShopIntro.prefab", maskType = MaskType.MT_None },
    UIBackPackUseBox                                = {
        uiPrefab = "UIBackPackUseBox.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityPowerCostController2                  = {
        uiPrefab = "UIActivityPowerCostController2.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN30MainController                     = {
        uiPrefab = "UIActivityN30MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN30
        }
    },

    --n30
    UIN30ShopController                             = {
        uiPrefab = "UIN30ShopController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN30
        }
    },
    UIN12MainController_Review                      = {
        uiPrefab = "UIN12MainReviewController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN12
        }
    },
    UIN12IntegralController_Review                  = {
        uiPrefab = "UIN12IntegralReviewController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = { ["UITransitionComponent"] = {} }
    },

    UIN30Entrust                                    = {
        uiPrefab = "UIN30EntrustMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN30
        }
    },
    UIN30EntrustStage                               = {
        uiPrefab = "UIN30EntrustStage.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN30EntrustLine                                = {
        uiPrefab = "UIN30EntrustLine.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN30
        }
    },
    UIN30EntrustFinishPopup                         = {
        uiPrefab = "UIN30EntrustFinishPopup.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN30EntrustEvent                               = {
        uiPrefab = "UIN30EntrustEvent.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN30EntrustItemInfo                            = {
        uiPrefab = "UIN30EntrustItemInfo.prefab",
        maskType = MaskType.MT_None
    },
    UIN31SecondAnniversaryAwards                    = {
        uiPrefab = "UIN31SecondAnniversaryAwards.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },

    --n31
    UIWorldBossViewTeam                             = {
        uiPrefab = "UIWorldBossViewTeam.prefab",
        maskType = MaskType.MT_None
    },
    UIWorldBossQuest                                = {
        uiPrefab = "UIWorldBossQuest.prefab",
        maskType = MaskType
            .MT_None
    },
    UICommonItemInfo                                = {
        uiPrefab = "UICommonItemInfo.prefab",
        maskType = MaskType
            .MT_None
    },
    UIWorldBossLegendDan                            = {
        uiPrefab = "UIWorldBossLegendDan.prefab",
        maskType = MaskType.MT_None
    },

    UIN31HardLevel                                  = {
        uiPrefab = "UIN31HardLevel.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN31
        }
    },
    UIN31Line                                       = {
        uiPrefab = "UIN31Line.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN31
        }
    },
    UIActivityN31MainController                     = {
        uiPrefab = "UIActivityN31MainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN31
        }
    },
    UIActivityN31Shop                               = {
        uiPrefab = "UIActivityN31Shop.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN31
        }
    },
    UIPopStarNormalLevelDetail                      = {
        uiPrefab = "UIPopStarNormalLevelDetail.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPopStarChallengeLevelDetail                   = {
        uiPrefab = "UIPopStarChallengeLevelDetail.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPopStarTeam                                   = {
        uiPrefab = "UIPopStarTeam.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIPopStarTeamSuggest                            = {
        uiPrefab = "UIPopStarTeamSuggest.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIN13MainControllerReview                       = {
        uiPrefab = "UIN13MainControllerReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13
        }
    },
    UIN13LineMissionControllerReview                = {
        uiPrefab = "UIN13LineMissionControllerReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13
        }
    },
    UIN13BuildControllerReview                      = {
        uiPrefab = "UIN13BuildControllerReview.prefab",
        maskType = MaskType.MT_BlurMask,
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIN13BuildPlotControllerReview                  = {
        uiPrefab = "UIN13BuildPlotControllerReview.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLineMain                              = {
        uiPrefab = "UIN32MultiLineMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIN32MultiLineMapController                     = {
        uiPrefab = "UIN32MultiLineMapController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIN32MultiLinePetUnlock                         = {
        uiPrefab = "UIN32MultiLinePetUnlock.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLineOverTips                          = {
        uiPrefab = "UIN32MultiLineOverTips.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLineFightDetails                      = {
        uiPrefab = "UIN32MultiLineFightDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLinePlotDetails                       = {
        uiPrefab = "UIN32MultiLinePlotDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLineDialogueDetails                   = {
        uiPrefab = "UIN32MultiLineDialogueDetails.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN32MultiLineDialogue                          = {
        uiPrefab = "UIN32MultiLineDialogue.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN32MainController                     = {
        uiPrefab = "UIActivityN32MainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIN32ShopController                             = {
        uiPrefab = "UIN32ShopController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIActivityN32PeridalesLevelMain                 = {
        uiPrefab = "UIActivityN32PeridalesLevelMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIActivityN32HardLevelMain                      = {
        uiPrefab = "UIActivityN32HardLevelMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN32
        }
    },
    UIActiveTaskAwardShowController                 = {
        uiPrefab = "UIActiveTaskAwardShowController.prefab",
        maskType = MaskType.MT_None,
    },
    UIN14MainReview                                 = {
        uiPrefab = "UIN14MainReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIActivityN14LineMissionControllerReview        = {
        uiPrefab = "UIActivityN14LineMissionControllerReview.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN13Build
        }
    },
    UIUpLevelAddQuickBox                            = {
        uiPrefab = "UIUpLevelAddQuickBox.prefab",
        maskType = MaskType.MT_BlurMask,
    },

    UIN32MultiLineArchive                           = {
        uiPrefab = "UIN32MultiLineArchive.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    --尖塔通关奖励
    UITowerPassAward                                = {
        uiPrefab = "UITowerPassAward.prefab",
        maskType = MaskType.MT_BlurMask
    }
    ,
    UIN33EightPetsStage                             = {
        uiPrefab = "UIN33EightPetsStage.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    UIN33EightPetsTeams                             = {
        uiPrefab = "UIN33EightPetsTeams.prefab",
        maskType = MaskType.MT_None,
    },
    UIActivityN33MainController                     = {
        uiPrefab = "UIActivityN33MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN33
        }
    },
    UIActivityN33LevelController                    = {
        uiPrefab = "UIActivityN33LevelController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN33
        }
    },
    UIActivityN33LevelDetail                        = {
        uiPrefab = "UIActivityN33LevelDetail.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIActivityN33LevelList                          = {
        uiPrefab = "UIActivityN33LevelList.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN33DateMainController                 = {
        uiPrefab = "UIActivityN33DateMainController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN33
        }
    },
    UIActivityN33BuildingInfo                       = {
        uiPrefab = "UIActivityN33BuildingInfo.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN33
        }
    },
    UIActivityN33ArchUpgradeReward                  = {
        uiPrefab = "UIActivityN33ArchUpgradeReward.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN33
        }
    },
    UIActivityN33DatePetController                  = {
        uiPrefab = "UIActivityN33DatePetController.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    UIActivityN33DateManualController               = {
        uiPrefab = "UIActivityN33DateManualController.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    UIActivityN33DateInviteController               = {
        uiPrefab = "UIActivityN33DateInviteController.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    UIN33ShopController                             = {
        uiPrefab = "UIN33ShopController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMMiniGame
        }
    },
    UIN33LotteryGetItem                             = {
        uiPrefab = "UIN33LotteryGetItem.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UITransitionComponent"] = {},
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true }
        }
    },
    UIN15MainControllerReview                       = {
        uiPrefab = "UIN15MainControllerReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },
    UIN15LineMissionControllerReview                = {
        uiPrefab = "UIN15LineMissionControllerReview.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN15
        }
    },

    --赛季
    --赛季探索
    UISeasonExploreMainController                   =
    {
        uiPrefab = "UISeasonExploreMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = SeasonCriAudio.BGMMain, --赛季探索主界面bgm测试用
        },
    },
    UISeasonPreviewController                       = {
        uiPrefab = "UISeasonPreviewController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonCollectionController                    = {
        uiPrefab = "UISeasonCollectionController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonMusicCollectionController               = {
        uiPrefab = "UISeasonMusicCollectionController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonCgCollectionController                  = {
        uiPrefab = "UISeasonCgCollectionController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonCgDetailController                      = {
        uiPrefab = "UISeasonCgDetailController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonRareCollectionController                = {
        uiPrefab = "UISeasonRareCollectionController.prefab",
        maskType = MaskType.MT_None
    },

    --赛季核心玩法主界面
    UISeasonMain                                    = {
        uiPrefab = "UISeasonMain.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = SeasonCriAudio.BGMMap, --大地图bgm测试用
        },
    },
    UISeasonLevelStage                              = {
        uiPrefab = "UISeasonLevelStage.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonShowAwards                              = {
        uiPrefab = "UISeasonShowAwards.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISeasonItemTips                                = {
        uiPrefab = "UISeasonItemTips.prefab",
        maskType = MaskType
            .MT_None
    },
    UISeasonShowCollectionAward                     = {
        uiPrefab = "UISeasonShowCollectionAward.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UISeasonHelperController                        = {
        uiPrefab = "UISeasonHelperController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UISeasonStageDiffTips                           = {
        uiPrefab = "UISeasonStageDiffTips.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UISeasonBuffMainInfo                            = {
        uiPrefab = "UISeasonBuffMainInfo.prefab",
        maskType = MaskType.MT_LessBlackMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UISeasonBuffMainTips                            = {
        uiPrefab = "UISeasonBuffMainTips.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UISeasonStageDiffTips                           = {
        uiPrefab = "UISeasonStageDiffTips.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UISeasonS1Collages                              = {
        uiPrefab = "UISeasonS1Collages.prefab",
        maskType = MaskType.MT_None,
    }, --伊芙收藏盒
    UISeasonBuffLevelUp                             = {
        uiPrefab = "UISeasonBuffLevelUp.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISetParamOnShowComponent"] = { [UIComponentParamType.KeepVoice] = true },
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UISeasonBuffInnerGameInfo                       = {
        uiPrefab = "UISeasonBuffInnerGameInfo.prefab",
        maskType = MaskType.MT_None
    },
    --赛季任务
    UISeasonQuestController                         = {
        uiPrefab = "UISeasonQuestController.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonQuestDetail                             = {
        uiPrefab = "UISeasonQuestDetail.prefab",
        maskType = MaskType.MT_None
    },
    --赛季主题 S1
    UIS1MainController                              = {
        uiPrefab = "UIS1MainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = SeasonCriAudio.BGMS1, --主题主界面bgm测试用
        },
    },
    UIS1ExchangeController                          = {
        uiPrefab = "UIS1ExchangeController.prefab",
        maskType = MaskType.MT_None,
    },
    UIS1ExchangeConfirm                             = {
        uiPrefab = "UIS1ExchangeConfirm.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UISimpleTransitionComponent"] = {}
        }
    },
    UISeasonPlotEnter                               = {
        uiPrefab = "UISeasonPlotEnter.prefab",
        maskType = MaskType.MT_LessBlackMask
    },
    UISeasonBubble                                  = { uiPrefab = "UISeasonBubble.prefab", maskType = MaskType.MT_None },
    UISeasonActionPointTip                          = {
        uiPrefab = "UISeasonActionPointTip.prefab",
        maskType = MaskType.MT_None
    },
    UISeasonFinalPlotShare                          = {
        uiPrefab = "UISeasonFinalPlotShare.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIRecruitConfirm                                = {
        uiPrefab = "UIRecruitConfirm.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICriVideoController                            = {
        uiPrefab = "UICriVideoController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UICriVideoControllerNowrap                      = {
        uiPrefab = "UICriVideoController.prefab",
        maskType = MaskType.MT_BlurMask
    },
    UIN34DispatchMain                               = {
        uiPrefab = "UIN34DispatchMain.prefab",
        maskType = MaskType.MT_None,
    },
    UIN34DispatchComplete                           = {
        uiPrefab = "UIN34DispatchComplete.prefab",
        maskType = MaskType.MT_None,
    },
    UIN34DispatchDialogueOpen                       = {
        uiPrefab = "UIN34DispatchDialogueOpen.prefab",
        maskType = MaskType.MT_BlurMask,
    },
    UIActivityN34TaskMainController                 = {
        uiPrefab = "UIActivityN34TaskMainController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN34MainController                     = {
        uiPrefab = "UIActivityN34MainController.prefab",
        maskType = MaskType.MT_None
    },
    UIActivityN34TaskInfomationMainController       = {
        uiPrefab = "UIActivityN34TaskInfomationMainController.prefab",
        maskType = MaskType.MT_None
    },
    UIN34TaskDelegatePerson                         = {
        uiPrefab = "UIN34TaskDelegatePerson.prefab",
        maskType = MaskType.MT_None
    },
    UIN34DispatchTerminalMainControlller            = {
        uiPrefab = "UIN34DispatchTerminalMainControlller.prefab",
        maskType = MaskType.MT_None,
    },
    UIN34DispatchAwardShowControlller               = {
        uiPrefab = "UIN34DispatchAwardShowControlller.prefab",
        maskType = MaskType.MT_None,
    },
    UIActivityN34TaskInfomationRewardPreview        = {
        uiPrefab = "UIActivityN34TaskInfomationRewardPreview.prefab",
        maskType = MaskType.MT_None,
    },
    UIN34DelegatePersonTips                         = {
        uiPrefab = "UIN34DelegatePersonTips.prefab",
        maskType = MaskType.MT_BlurMask,
    },

    UIActivityN16ReviewMainController               = {
        uiPrefab = "UIActivityN16ReviewMainController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIActivityN16ReviewLineMissionController        = {
        uiPrefab = "UIActivityN16ReviewLineMissionController.prefab",
        maskType = MaskType.MT_None,
        uiComponents = {
            ["UISwitchBGMComponent"] = CriAudioIDConst.BGMN16
        }
    },
    UIActivityLevelRecordController = {
        uiPrefab = "UIActivityLevelRecordController.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
    UIActivityN34TaskInfomationPasteTips = {
        uiPrefab = "UIActivityN34TaskInfomationPasteTips.prefab",
        maskType = MaskType.MT_BlurMask,
        uiComponents = {
            ["UITransitionComponent"] = {}
        }
    },
}
