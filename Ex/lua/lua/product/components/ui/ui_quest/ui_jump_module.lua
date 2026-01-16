---@class UIJumpModule:UIModule
_class("UIJumpModule", UIModule)
UIJumpModule = UIJumpModule

--[[
    跳转module
    步骤：
    1-设置fromui
    2-设置jumpui
    3-调用Jump

    PS:需要跳转的状态ui在返回时来检查一下是否是跳转过去的，如果是，调用BackFromUI
]]
--- @class JumpUIType
local JumpUIType = {
    --状态ui
    StateUI = 0,
    --普通ui
    NormalUI = 1,
    --状态ui下的普通ui
    StateUIAndNormalUI = 2
}
_enum("JumpUIType", JumpUIType)

--- @class FromUIType
local FromUIType = {
    --状态ui
    StateUI = 0,
    --普通ui
    NormalUI = 1
}
_enum("FromUIType", FromUIType)

---#对应UIJumpType
--- @class Id2UIName
local Id2UIName = {
    [UIJumpType.UI_JumpMission] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIDiscovery,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 3 }
    },
    [UIJumpType.UI_JumpResDungeon] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIResEntryController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 5 }
    },
    [UIJumpType.UI_JumpExMission] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIExtraMission,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 7 }
    },
    [UIJumpType.UI_JumpExMissionStage] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIExtraMissionStage,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 7 }
    },
    [UIJumpType.UI_JumpPet] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIHeartSpiritController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpMaze] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIMaze,
        normalUI = nil,
        needLoading = true,
        loadingHander = "MazeEnterLoadingHandler",
        sceneName = "mj_01",
        unLockID = { [1] = 6 }
    },
    [UIJumpType.UI_JumpMall] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIShopController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 9 }
    },
    [UIJumpType.UI_JumpAircraft] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIAircraft,
        normalUI = nil,
        needLoading = true,
        loadingHander = "AircraftEnterLoadingHandler",
        sceneName = "fc_ui",
        unLockID = { [1] = 4 }
    },
    [UIJumpType.UI_JumpDraw] = {
        type = JumpUIType.NormalUI,
        -- stateUI = UIStateType.UIDrawCard,
        stateUI = nil,
        normalUI = "UIDrawCardController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 8 }
    },
    [UIJumpType.UI_JumpQuest] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIQuestController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 13, [2] = 14, [4] = 16, [5] = 15 }
    },
    [UIJumpType.UI_JumpChooseAssistant] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIChooseAssistantController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpPlayerInfo] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIPlayerInfoController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 11 }
    },
    [UIJumpType.UI_JumpTower] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UITower,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 24 }
    },
    [UIJumpType.UI_JumpTowerLayer] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UITowerLayer,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 24 }
    },
    [UIJumpType.UI_JumpWeChat] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIWeChatController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 25 }
    },
    [UIJumpType.UI_JumpPetDetail] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UISpiritDetailGroupController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpPetUpLevel] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIUpLevelInterfaceController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpPetBreak] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIBreakController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpPetAwaken] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIGradeInterfaceController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpPetFile] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIPetIntimacyMainController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 2 }
    },
    [UIJumpType.UI_JumpNotice] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UINoticeController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 20 }
    },
    [UIJumpType.UI_JumpActivityEveSinsa] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityEveSinsaMainController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySakuraEntry] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UISakuraEntryController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpTempSignIn] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UITempSignInController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_WebView] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UITempSignInController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer1] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UISummer1,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer1LevelSimple] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIXH1SimpleLevel,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer1LevelHard] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIXH1HardLevel,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer1Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIXH1Shop",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer1Game] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIMiniGameStageController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer2] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UISummer2,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivitySummer2Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UISummer2Level,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN5] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN5,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN5SimpleLevel] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN5SimpleLevel,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN5BattleField] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN5BattleField,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpWorldBoss] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIWorldBoss,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = { [1] = 33 }
    },
    [UIJumpType.UI_JumpActivityN6Building] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityNPlusSixBuildingMainController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN6Level] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UINP6Level",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN7Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN7Level,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityBlackFightMain] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIBlackFightMain,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN8Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN8LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN8Combat] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN8BattleSimulatorController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN9Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN9LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN9Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityShopControllerN9,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN10Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIN10ShopController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN11Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN11Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN11Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN11LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN12NormalLevel] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN12NormalLevel,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN13Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN13LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN13Build] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN13BuildController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN15Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN15LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN15Lottery] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN15RaffleController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpHauteCouture] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIHauteCoutureDrawV2Controller",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN14Normal] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN14LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN14Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN14Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN16Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN16LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN16Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityShopControllerN16,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN17Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN17LotteryController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpHome] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIHomeland,
        normalUI = nil,
        needLoading = true,
        loadingHander = "HomelandEnterLoadingHandler",
        sceneName = "konggu02func",
        unLockID = { [1] = 34 }
    },
    [UIJumpType.UI_JumpActivityN18Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN18LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN18Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN18Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN19P5Award] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN19P5DrawCard,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN19Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN19LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN20Level] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN20NormalLevel,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN20Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityN20Shop",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN21Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN21LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN21Award] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN21ShopController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN22Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN22LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN22Award] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivtiyN22ShopController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN23Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN23Line,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN23Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN23Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpHauteCoutureReview] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        -- normalUI = "UIHauteCoutureDraw_Review", --旧版本，卡莲高级时装专用
        normalUI = "UIHauteCoutureDrawV2ReviewController", --新版本，卡莲之后全部通用
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN24Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN24Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN25Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN25Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN25Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN25Line,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN26Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityN26Shop",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN26Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN26Line,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN27Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIN27LotteryMain",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN27Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN27LineMissionController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN28Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityN28Shop",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN28Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN28Line,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN29DetectiveLogin] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN29DetectiveLogin,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },

    [UIJumpType.UI_JumpActivityN29Line] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityN29LineLevel",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },

    [UIJumpType.UI_JumpActivityN29Shop] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIN29Shop",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },

    [UIJumpType.UI_JumpActivityN30Entrust] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN30Entrust,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN30Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN30ShopController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN31Line] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN31Line,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN31Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIActivityN31Shop,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityPopStar] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UISideEnterCenter",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN32Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN32ShopController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN33Shop] = {
        type = JumpUIType.StateUI,
        stateUI = UIStateType.UIN33ShopController,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN33Simulation] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = UIStateType.UIActivityN33DateMainController,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpActivityN33NormalLevel] = {
        type = JumpUIType.NormalUI,
        stateUI = nil,
        normalUI = "UIActivityN33LevelController",
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
    [UIJumpType.UI_JumpSeasonMap] = {
        type = JumpUIType.StateUI,
        stateUI = nil,
        normalUI = nil,
        needLoading = false,
        loadingHander = nil,
        sceneName = nil,
        unLockID = {}
    },
}
--_enum("Id2UIName", Id2UIName)

--家园界面枚举
--- @class HomeUIDialogEnum
local HomeUIDialogEnum = {
    --等级界面
    Level = 1
}
_enum("HomeUIDialogEnum", HomeUIDialogEnum)
--家园界面枚举对应界面名字
local HomeDialogEnum2DialogName = {
    [HomeUIDialogEnum.Level] = "UIHomelandLevel"
}

function UIJumpModule:Dispose()
    self._fromUIType = nil
    self._fromUIName = nil
    self._fromUIOfStateUI = nil
    self._fromUIParams = nil

    self._uiControllerType = nil
    self._jumpUIType = nil
    self._jumpStateUIName = nil
    self._jumpNormalUIName = nil
    self._jumpUIParams = nil
    self._jumpLoadingHander = nil
    self._jumpLoadingSceneName = nil
end

function UIJumpModule:Constructor()
    self._fromUIType = nil
    self._fromUIName = nil
    self._fromUIOfStateUI = nil
    self._fromUIParams = {}

    self._uiControllerType = nil
    self._jumpUIType = nil
    self._jumpStateUIName = nil
    self._jumpNormalUIName = nil
    self._jumpNeedLoading = nil
    self._jumpLoadingHander = nil
    self._jumpLoadingSceneName = nil
    self._jumpUIParams = {}
end

function UIJumpModule:_ResetData()
    self._fromUIType = nil
    self._fromUIName = nil
    self._fromUIOfStateUI = nil
    self._fromUIParams = {}

    self._uiControllerType = nil
    self._jumpUIType = nil
    self._jumpStateUIName = nil
    self._jumpNormalUIName = nil
    self._jumpNeedLoading = nil
    self._jumpLoadingHander = nil
    self._jumpLoadingSceneName = nil
    self._jumpUIParams = {}
end

---@param fromUIType FromUIType 来的界面类型
---@param fromUIName UIStateType 来的界面名字
---@param fromUIOfStateUI string 之前的状态ui
---@param fromUIParams table 来的界面的参数
function UIJumpModule:SetFromUIData(fromUIType, fromUIName, fromUIOfStateUI, fromUIParams)
    self._fromUIType = fromUIType
    self._fromUIName = fromUIName
    self._fromUIOfStateUI = fromUIOfStateUI
    self._fromUIParams = fromUIParams
end

---@param jumpUIType UIJumpType 去的界面的类型
---@param jumpUIParams table 去的界面的参数
--[[
---@param jumpStateUIName string 去的状态界面的名字
---@param jumpNormalUIName string 去的普通界面的名字
]]
function UIJumpModule:SetJumpUIData(jumpUIType, jumpUIParams)
    self._uiControllerType,
    self._jumpUIType,
    self._jumpStateUIName,
    self._jumpNormalUIName,
    self._jumpNeedLoading,
    self._jumpLoadingHander,
    self._jumpLoadingSceneName,
    self._jumpUnLockID = self:_SetJumpUIType(jumpUIType)
    if not jumpUIParams then
        self._jumpUIParams = {}
    else
        self._jumpUIParams = jumpUIParams
    end
end

---@param UIJumpType UIJumpType UIJumpType
function UIJumpModule:_SetJumpUIType(UIJumpType)
    local type = Id2UIName[UIJumpType].type
    local stateUI = Id2UIName[UIJumpType].stateUI
    local normalUI = Id2UIName[UIJumpType].normalUI
    local needLoading = Id2UIName[UIJumpType].needLoading
    local loadingHander = Id2UIName[UIJumpType].loadingHander
    local sceneName = Id2UIName[UIJumpType].sceneName
    local unLockID = Id2UIName[UIJumpType].unLockID
    return UIJumpType, type, stateUI, normalUI, needLoading, loadingHander, sceneName, unLockID
end

function UIJumpModule:GetUnLockId(UIJumpType)
    return Id2UIName[UIJumpType].unLockID
end

---public 对外接口
function UIJumpModule:Goto(id, fromType, uiName, uiStateType, ...)
    local cfg = Cfg.cfg_jump[id]
    if not cfg then
        return
    end
    self:SetFromUIData(fromType, uiName, uiStateType, { ... })
    local jumpType = cfg.JumpID
    local jumpParams = cfg.JumpParam
    self:SetJumpUIData(jumpType, jumpParams)
    self:Jump()
end

function UIJumpModule:GotoWithItemGetPath(id, extParam, fromType, uiName, uiStateType, ...)
    local cfg = Cfg.cfg_jump[id]
    if not cfg then
        return
    end
    local param = { ... }
    self._gotoParam = param
    self:SetFromUIData(fromType, uiName, uiStateType, { ... })
    local jumpType = cfg.JumpID
    local jumpParams = nil
    if cfg.JumpParam then
        jumpParams = {}
        for i, value in ipairs(cfg.JumpParam) do
            jumpParams[i] = value
        end
    end
    --判断需不需要添加额外参数
    --判断依据,每个跳转类型自己写
    if jumpType == UIJumpType.UI_JumpAircraft then
        if jumpParams then
            if jumpParams[1] == OpenAircraftParamType.Spaceid then
                local airModule = GameGlobal.GetModule(AircraftModule)
                local gotoSpaceId = jumpParams[2]
                if gotoSpaceId then
                    --解锁
                    local space = airModule:GetSpaceInfo(gotoSpaceId)
                    if not space then
                        if self._gotoParam and self._gotoParam[1] and self._gotoParam[1].isSmeltRoom and not (self._gotoParam[1].conform) then
                            -- 熔炼室特殊处理
                        else
                            ToastManager.ShowToast("The Jump Space Is Not Open !")
                            Log.debug("Space is nil !")
                            return
                        end
                    end
                    -- 熔炼室特殊处理
                    if space then
                        if space.space_status == SpaceState.SpaceStateFull then
                            ---@type AircraftRoomBase
                            local room = airModule:GetRoom(gotoSpaceId)
                            if room:GetRoomType() == AirRoomType.SmeltRoom then
                                local lock = airModule:IsSmeltItemLock(extParam)
                                --材料未解锁
                                if lock and not (self._gotoParam and self._gotoParam[1] and self._gotoParam[1].isSmeltRoom) then
                                    ToastManager.ShowToast("The Jump Mat Is Not UnLock !")
                                    Log.debug("mat is lock !")
                                    return
                                end
                                if extParam then
                                    jumpParams[#jumpParams + 1] = extParam
                                    if self._gotoParam and self._gotoParam[1] then
                                        jumpParams[#jumpParams + 1] = self._gotoParam[1].NeedNumRawData
                                    end
                                end
                            end
                        else
                            if self._gotoParam and self._gotoParam[1] and self._gotoParam[1].isSmeltRoom and not (self._gotoParam[1].conform) then
                                -- 熔炼室特殊处理
                            else
                                Log.debug("space.space_status ~= SpaceState.SpaceStateFull")
                                return
                            end
                        end
                    end
                end
            end
        end
    elseif jumpType == UIJumpType.UI_JumpSeasonMap then
        GameGlobal.GetUIModule(SeasonModule):EnterCurrentSeasonMainUI()
    else
    end
    self:SetJumpUIData(jumpType, jumpParams)
    self:Jump()
end

---#跳转界面后，如果跳转的是状态ui，当该界面点击返回的时候，让他去jumpmodule里检查一下是不是跳转过来的，如果是，则调用jumpmodule的BackFromUI，否则自行处理
function UIJumpModule:Jump()
    local currentStateUI = GameGlobal.UIStateManager():CurUIStateType()
    --and self._jumpUIType ~= JumpUIType.NormalUI
            
    if currentStateUI == UIStateType.UIAircraft then
        --1-跳风船类型（1=spaceid,2=petid），2-spaceid，3-需要的参数
        if self._uiControllerType == UIJumpType.UI_JumpAircraft and self._jumpUIParams[2] == AircraftLayer.Smelt then
            --风船跳熔炼室
            GameGlobal.UIStateManager():CloseDialog("UIItemGetPathController")
            local controller = GameGlobal.UIStateManager():GetController("UIAircraftItemSmeltController")
            local gotoSpaceId = self._jumpUIParams[2]
            local airModule = GameGlobal.GetModule(AircraftModule)
            local space = airModule:GetSpaceInfo(gotoSpaceId)
            if not space then
                GameGlobal.UIStateManager():ShowDialog("UIAircraftRoomUnLockTipsController", AircraftLayer.Smelt)
                return
            end
            if controller then
                controller:OpenJump(self._jumpUIParams[3], self._jumpUIParams[4], true)
            else
                GameGlobal.UIStateManager():ShowDialog("UIAircraftItemSmeltController", self._jumpUIParams[3],
                    self._jumpUIParams[4])
            end
        elseif self._uiControllerType == UIJumpType.UI_JumpAircraft then
            --如果是在风船内部，跳到某个房间
            local param = self._jumpUIParams
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOpenRoom, table.unpack(param))
        elseif self._uiControllerType == UIJumpType.UI_JumpDraw then
            self:_GotoJump()
        else
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.AircraftJumpOutTo,
                function()
                    if self._jumpUIType == JumpUIType.NormalUI then
                        if self._uiControllerType == UIJumpType.UI_JumpMall then
                            self._jumpUIType = JumpUIType.StateUI
                            self._jumpStateUIName = UIStateType.UIShopController
                            self._jumpNormalUIName = nil
                        end
                    end
                    self:_GotoJump()
                end
            )
        end
        return
    elseif currentStateUI == UIStateType.UISeason then --从赛季往外跳转必须执行赛季通用的退出逻辑
        if self._jumpNeedLoading then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SeasonLeaveToBattle)
            self:_GotoJump()
        elseif self._jumpUIType == JumpUIType.NormalUI and self._jumpStateUIName == nil and self._jumpNormalUIName == "UIRecruit" then
            --赛季跳转到抽卡dialog
            local seasonUIModule = GameGlobal.GetUIModule(SeasonModule)
            seasonUIModule:ExitSeasonTo(UIStateType.UIRecruit)
        else
            ---@type UISeasonModule
            local seasonUIModule = GameGlobal.GetUIModule(SeasonModule)
            seasonUIModule:ExitSeasonTo(
                function()
                    self:_GotoJump()
                end
            )
        end
        return
    end
    --如果是其他地方跳转到熔炼室（不加载巨像场景，直接打开熔炼室页面）
    if currentStateUI ~= UIStateType.UIAircraft and self._uiControllerType == UIJumpType.UI_JumpAircraft then
        local gotoSpaceId = self._jumpUIParams[2]
        local param = self._jumpUIParams[3]
        local param2 = self._jumpUIParams[4]
        --如果是跳转过来的，需要打开房间界面
        local airModule = GameGlobal.GetModule(AircraftModule)
        local room = airModule:GetRoom(gotoSpaceId)
        -- 熔炼室特殊处理   任务跳转
        local canJump = (self._gotoParam and self._gotoParam[1] and self._gotoParam[1].isSmeltRoom and self._gotoParam[1].conform)
            or (not self._gotoParam) or (self._gotoParam and #self._gotoParam == 0)
        if room and room:GetRoomType() == AirRoomType.SmeltRoom and canJump then
            ---@type aircraft_space_info
            local space = airModule:GetSpaceInfo(gotoSpaceId)
            if not space then
                ToastManager.ShowToast("Space is nil !")
                return
            end

            --风船外跳熔炼室
            GameGlobal.UIStateManager():CloseDialog("UIItemGetPathController")
            --param - 材料id
            local controller = GameGlobal.UIStateManager():GetController("UIAircraftItemSmeltController")
            if controller then
                controller:OpenJump(param, param2, true)
            else
                GameGlobal.UIStateManager():ShowDialog("UIAircraftItemSmeltController", param, param2)
            end
            return
        end
        if self._gotoParam  and self._gotoParam[1] and  self._gotoParam[1].isSmeltRoom  then
            self._jumpUIParams = self._gotoParam[1].conform and self._jumpUIParams or {}
        end
    end
    --and self._jumpUIType ~= JumpUIType.NormalUI
    if currentStateUI == UIStateType.UIMaze then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.AircraftJumpOutTo,
            function()
                if self._jumpUIType == JumpUIType.NormalUI then
                    GameGlobal.UIStateManager():SwitchState(UIStateType.UIMain)
                end
                self:_GotoJump()
            end
        )
        return
    end
    --if in home
    if currentStateUI == UIStateType.UIHomeland then
        if self._uiControllerType == UIJumpType.UI_JumpHome then
            if self._jumpUIParams and table.count(self._jumpUIParams) > 0 then
                local param = table.clone(self._jumpUIParams)
                if param then
                    local isShowDialog = param[1]
                    if isShowDialog and isShowDialog == 1 then
                        local dialogName = HomeDialogEnum2DialogName[param[2]]
                        table.remove(param, 2)
                        table.remove(param, 1)
                        local dialogParm = param
                        ---@type UIHomelandModule
                        local uiHomeModule = GameGlobal.GetUIModule(HomelandModule)
                        uiHomeModule:SetDialog(dialogName, dialogParm)
                        uiHomeModule:ShowDialog()
                    end
                end
            end
        end

        return
    end

    if self._jumpNormalUIName == "UISideEnterCenter" then
        local param = {campaign_id = self._jumpUIParams[1]}
        GameGlobal.UIStateManager():ShowDialog("UISideEnterCenterController", param)
        return
    end

    self:_GotoJump()
end

function UIJumpModule:_GotoJump()
    if self._jumpUIType ~= nil then
        --如果是内部跳转任务界面
        if self._uiControllerType == UIJumpType.UI_JumpQuest then
            local questType = self._jumpUnLockID[self._jumpUIParams[1]]
            if questType then
                ---@type RoleModule
                local module = GameGlobal.GetModule(RoleModule)
                if module:CheckModuleUnlock(questType) == false then
                    local cfg = Cfg.cfg_module_unlock[questType]
                    if cfg then
                        ToastManager.ShowToast(StringTable.Get(cfg.Tips))
                    end
                    return
                else
                    if GameGlobal.UIStateManager():IsShow("UIQuestController") then
                        local args = table.unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeQuestController, args)
                        return
                    end
                end
            end
        else
            --其他界面跳转解锁
            local unLockID = self._jumpUnLockID[1]
            if unLockID then
                ---@type RoleModule
                local module = GameGlobal.GetModule(RoleModule)
                if module:CheckModuleUnlock(unLockID) == false then
                    Log.debug("###jumpModule -- 没有解锁-id", unLockID)
                    local cfg = Cfg.cfg_module_unlock[unLockID]
                    if cfg then
                        ToastManager.ShowToast(StringTable.Get(cfg.Tips))
                    end
                    return
                else
                    Log.debug("###jumpModule -- 解锁了-id", unLockID)
                end
            end
        end
        if self._uiControllerType == UIJumpType.UI_JumpMission then
            --如果是跳转主线
            ---@type MissionModule
            local module = GameGlobal.GetModule(MissionModule)
            ---@type DiscoveryData
            local data = module:GetDiscoveryData()

            if self._jumpUIParams and table.count(self._jumpUIParams) > 0 then
                local newParams = {}
                if self._jumpUIParams[1] == 1 then
                    local discoveryData = module:GetDiscoveryData()
                    local node = discoveryData:GetCanPlayNode()
                    table.insert(newParams, node.stages[1].id)
                else
                    newParams = self._jumpUIParams
                end
                data:UpdatePosByEnter(6, table.unpack(newParams, 1, table.maxn(newParams)))
            else
                DiscoveryData.EnterStateUIDiscovery(1)
            end
        end
        if self._uiControllerType == UIJumpType.UI_JumpExMissionStage then
            local extId = self._jumpUIParams[1]
            local stageId = self._jumpUIParams[2]
            local extModule = GameGlobal.GetModule(ExtMissionModule)

            --先判断章节有没有解锁，没有的话提示
            local extState = extModule:UI_GetExtMissionState(extId)
            if extState == EnumExtMissionState.Disable then
                --章节没解锁
                ToastManager.ShowToast(StringTable.Get("str_extra_mission_public_chapter_is_lock"))
                return
            end
            --[[old
            local cfg_extra_mission = Cfg.cfg_extra_mission[extId]
            if cfg_extra_mission.ExtTaskList then
                local firstStage = cfg_extra_mission.ExtTaskList[1]
                local firstStageStar = extModule:UI_GetExtTaskState(extId, firstStage)
                if firstStageStar<0 then
                    return
                end
            end
            ]]
            --在判断关卡解锁，没解锁跳到最新的关卡
            local star = extModule:UI_GetExtTaskState(extId, stageId)
            if star < 0 then
                --没解锁
                local cfg_extra_mission = Cfg.cfg_extra_mission[extId]
                local stagelist = cfg_extra_mission.ExtTaskList
                for i = 1, #stagelist do
                    local star = extModule:UI_GetExtTaskState(extId, stagelist[i])
                    if star <= 0 then
                        --找最新
                        self._jumpUIParams[2] = stagelist[i]
                        break
                    end
                end
            end
        end
        --如果是星灵相关的，先检查有没有这个星灵,如果没有调到列表
        if
            self._uiControllerType == UIJumpType.UI_JumpPetDetail or
            self._uiControllerType == UIJumpType.UI_JumpPetUpLevel or
            self._uiControllerType == UIJumpType.UI_JumpPetBreak or
            self._uiControllerType == UIJumpType.UI_JumpPetAwaken or
            self._uiControllerType == UIJumpType.UI_JumpPetFile
        then
            local petid = self._jumpUIParams[1]
            ---@type PetModule
            local petModule = GameGlobal.GetModule(PetModule)
            local pet = petModule:GetPetByTemplateId(petid)
            if not pet then
                self:SetJumpUIData(UIJumpType.UI_JumpPet, self._jumpUIParams)
            end
        end
        --如果是公告
        if self._uiControllerType == UIJumpType.UI_JumpNotice then
            if SDKProxy:GetInstance():IsInternationalSDK() then
                if NoNoticeOut then
                    return
                end
            end
        end

        --region UI_WebView
        -- 测试链接：https://www.gachatest.alchemystars.com?openid=%s&role_id=%d&role_name=%s&area_id=%d&zone_id=%d&plat_id=%d&lang_type=%d
        -- 正式链接：https://www.gacha.alchemystars.com?openid=%s&role_id=%d&role_name=%s&area_id=%d&zone_id=%d&lang_type=%d
        if self._uiControllerType == UIJumpType.UI_WebView then
            local www = self._jumpUIParams[1]
            if string.isnullorempty(www) then
                Log.fatal("### jump param is empty.")
            else
                SDKProxy:GetInstance():OpenUrl(www)
                return
            end
        end
        --endregion

        --如果是风船跳抽卡 (由于加载优化处理需要切换抽卡统一使用SwitchState或showDialog,无需加载场景)
        -- local currentStateUI = GameGlobal.UIStateManager():CurUIStateType()
        -- if currentStateUI == UIStateType.UIAircraft and self._uiControllerType == UIJumpType.UI_JumpDraw then
        --     GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftLeaveAircraft)
        --     GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft2Drawcard, "Ckt_01_new")
        --     return
        -- end

        --如果从其他地方是跳转家园
        --参数放在uimodule处理，不走正常传参逻辑
        if self._uiControllerType == UIJumpType.UI_JumpHome then
            if self._jumpUIParams and table.count(self._jumpUIParams) > 0 then
                local param = table.clone(self._jumpUIParams)
                if param then
                    local isShowDialog = param[1]
                    if isShowDialog and isShowDialog == 1 then
                        local dialogName = HomeDialogEnum2DialogName[param[2]]
                        table.remove(param, 2)
                        table.remove(param, 1)
                        local dialogParm = param
                        ---@type UIHomelandModule
                        local uiHomeModule = GameGlobal.GetUIModule(HomelandModule)
                        uiHomeModule:SetDialog(dialogName, dialogParm)
                    end
                end
            end
        end

        if self._jumpUIType == JumpUIType.NormalUI then
            if self._jumpStateUIName == nil then
                GameGlobal.UIStateManager():ShowDialog(
                    self._jumpNormalUIName,
                    table.unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
                )
            end
        elseif self._jumpUIType == JumpUIType.StateUI then
            if self._jumpNeedLoading == true then
                GameGlobal.LoadingManager():StartLoading(
                    self._jumpLoadingHander,
                    self._jumpLoadingSceneName,
                    table.unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
                )
            else
                --如果番外，参数不需要unpack
                if self._uiControllerType == 3 then
                    GameGlobal.UIStateManager():SwitchState(self._jumpStateUIName, self._jumpUIParams)
                else
                    GameGlobal.UIStateManager():SwitchState(
                        self._jumpStateUIName,
                        table.unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
                    )
                end
            end
        elseif self._jumpUIType == JumpUIType.StateUIAndNormalUI then
            --B
            self._openUICallback = GameHelper:GetInstance():CreateCallback(self.UIOpenHandleJump, self)
            GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.UIOpen, self._openUICallback)

            GameGlobal.UIStateManager():SwitchState(self._jumpStateUIName)
            --[[
A
                GameGlobal.UIStateManager():SwitchState(self._jumpStateUIName)
                GameGlobal.UIStateManager():ShowDialog(
                    self._jumpNormalUIName,
                    unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
                    )
                    ]]
        end
    end
end

---#该接口由跳转的过去的界面返回时调用，用来返回之前的界面
function UIJumpModule:_BackFromUI()
    if self._fromUIType ~= nil then
        if self._fromUIType == FromUIType.StateUI then
            GameGlobal.UIStateManager():SwitchState(self._fromUIName, self._fromUIParams)
            self:_ResetData()
        elseif self._fromUIType == FromUIType.NormalUI then
            --目前框架不支持，用B计划
            --打开StateUI之前先注册uiopen事件，当这个ui打开之后再showdialogui，然后取消事件
            --直接switchstate然后showdialog，会先show，再switch，原因还在看
            self._openUICallback = GameHelper:GetInstance():CreateCallback(self.UIOpenHandleFrom, self)
            GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.UIOpen, self._openUICallback)

            GameGlobal.UIStateManager():SwitchState(self._fromUIOfStateUI)

            --[[
                --之前是switch然后show
                GameGlobal.UIStateManager():ShowDialog(
                    self._fromUIName,
                    unpack(self._fromUIParams, 1, table.maxn(self._fromUIParams))
                    )
                    ]]
        end
    end

    --self:_ResetData()
end

function UIJumpModule:UIOpenHandleFrom(uiname)
    local n = GameGlobal.UIStateManager().registeredStateDic[self._jumpStateUIName]
    if uiname == n.defaultUIList[1] then
        GameGlobal.UIStateManager():ShowDialog(
            self._jumpNormalUIName,
            table.unpack(self._jumpUIParams, 1, table.maxn(self._jumpUIParams))
        )
        self:_ResetData()
    end
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.UIOpen, self._openUICallback)
end

function UIJumpModule:UIOpenHandleJump(uiname)
    local n = GameGlobal.UIStateManager().registeredStateDic[self._fromUIOfStateUI]
    if uiname == n.defaultUIList[1] then
        GameGlobal.UIStateManager():ShowDialog(
            self._fromUIName,
            table.unpack(self._fromUIParams, 1, table.maxn(self._fromUIParams))
        )
        self:_ResetData()
    end
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.UIOpen, self._openUICallback)
end

---#该界面提供功能：检查一个界面是否是跳转过去的
function UIJumpModule:CheckUIOpenType(uiName)
    if self._jumpUIType ~= nil then
        if self._jumpStateUIName ~= nil then
            if self._jumpStateUIName == uiName then
                self:_BackFromUI()
                return true
            end
        end
        if self._jumpNormalUIName ~= nil then
            if self._jumpNormalUIName == uiName then
                self:_BackFromUI()
                return true
            end
        end
        return false
    end
    return false
end
