--[[------------------------------------------------------------------------------------------

**********************************************************************************************

    UI状态注册器

**********************************************************************************************

]] --------------------------------------------------------------------------------------------

---UI状态类�?
---@class UIStateType
---@field Invalid string
local _UIStateType = {
    Invalid = "Invalid",
    LoginEmpty = "LoginEmpty",
    Login = "Login",
    UIMain = "UIMain",
    UISideEnterCenter = "UISideEnterCenter",
    --BattleLoading = "BattleLoading",
    UIBattle = "UIBattle",
    UIDiscovery = "UIDiscovery",
    UITeams = "UITeams",
    UITeamsGuide = "UITeamsGuide",
    UITeamChangeController = "UITeamChangeController",
    UIAircraft = "UIAircraft",
    UIExtraMission = "UIExtraMissionDetailController",
    UIExtraMissionStage = "UIExtraMissionStageController",
    UIStoryController = "UIStoryController",
    UIStoryViewer = "UIStoryViewer", ---剧情查看界面
    UISKillEditor = "UISkillEditorController",
    UIMaze = "UIMazeController", --秘境探索
    UIResDetailController = "UIResDetailController", --资源本详情界�?
    UIResEntryController = "UIResEntryController", --资源本详情界�?
    UIDrawCard = "UIDrawCard", --抽卡
    UIDrawCardAnim = "UIDrawCardAnim",
    UITower = "UITower",
    UITowerLayer = "UITowerLayer",
    UIStageTest = "UIStageTest",
    UICoreGameTest = "UICoreGameTest",
    UICutsceneTest = "UICutsceneTest",
    UIShopController = "UIShopController",
    UICommonLoading = "UICommonLoading",
    UITrailLevel = "UITrailLevel",
    UITalePetList = "UITalePetList",
    UITalePetCollect = "UITalePetCollect",
    UIActivityEveSinsaMainController = "UIActivityEveSinsaMainController",
    UIActivityEveSinsaLevelAController = "UIActivityEveSinsaLevelAController",
    UIActivityEveSinsaLevelBController = "UIActivityEveSinsaLevelBController",
    UISakuraEntryController = "UISakuraEntryController",
    UISummer1 = "UISummer1",
    UIXH1SimpleLevel = "UIXH1SimpleLevel", --夏活1普通关
    UIXH1HardLevel = "UIXH1HardLevel", --夏活1高难�?
    UISummer2 = "UISummer2",
    UISummer2Level = "UISummer2Level",
    UIActivityBattlePassMainController = "UIActivityBattlePassMainController",
    UIPlot = "UIPlot",
    UICutsceneReview = "UICutsceneReview", ---3D剧情回顾
    UIActivityN5 = "UIActivityN5", ---活动N5
    UIActivityN5BattleField = "UIActivityN5BattleField", ---活动N5战场
    UIActivityN6 = "UIActivityN6", ---活动N6
    UINP6Level = "UINP6Level", --n+6关卡
    UIActivityN5SimpleLevel = "UIActivityN5SimpleLevel", --活动N5普通关
    UIN5ProgressController = "UIN5ProgressController", --活动N5军功�?
    UILostLandMain = "UILostLandMain", ---迷失之地主界�?
    UILostLandStage = "UILostLandStage", ---迷失之地关卡界面
    UIWeekTower = "UIWeekTower", ---周爬塔关卡界�?
    UIWorldBoss = "UIWorldBoss", --世界boss 
    UIGlobalBoss = "UIGlobalBoss", --世界boss N31
    UISailingMain = "UISailingMain", --大航�?
    UISailingChapter = "UISailingChapter", --大航�?
    UIActivityN7MainController = "UIActivityN7MainController",
    UIN7Level = "UIN7Level",
    UIBlackFightMain = "UIBlackFightMain",
    UIN7LevelDetailsController = "UIN7LevelDetailsController",
    UIActivityN8MainController = "UIActivityN8MainController",
    UIActivityN8LineMissionController = "UIActivityN8LineMissionController",
    UIActivityN8BattleSimulatorController = "UIActivityN8BattleSimulatorController",
    UIActivityN9MainController = "UIActivityN9MainController",
    UIActivityN9LineMissionController = "UIActivityN9LineMissionController",
    UIN9HardLevel = "UIN9HardLevel",
    UIActivityShopControllerN9 = "UIActivityShopControllerN9",
    UIN10MainController = "UIN10MainController",
    UIN11Main = "UIN11Main",
    UIN11Shop = "UIN11Shop",
    UIActivityN11LineMissionController = "UIActivityN11LineMissionController",
    UIActivtiyN11HardLevelController = "UIActivtiyN11HardLevelController",
    UIN12MainController = "UIN12MainController",
    UIN12NormalLevel = "UIN12NormalLevel",
    UIN12HardlLevel = "UIN12HardlLevel",
    UIN12HardlLevelInfo = "UIN12HardlLevelInfo",
    UIN12IntegralController = "UIN12IntegralController",
    UIN12EntrustStageController = "UIN12EntrustStageController",
    UIN12EntrustLevelController = "UIN12EntrustLevelController",
    UIActivityDoubleDropIntroduce = "UIActivityDoubleDropIntroduce",
    UIN13BuildController = "UIN13BuildController",
    UIN14Main = "UIN14Main",
    UIActivityN14LineMissionController = "UIActivityN14LineMissionController",
    UIActivityN14HardMissionController = "UIActivityN14HardMissionController",
    UIN14Shop = "UIN14Shop",
    -- N13
    UIN13BuildController = "UIN13BuildController",
    UIN13MainController = "UIN13MainController",
    UIN13LineMissionController = "UIN13LineMissionController",
    UIN14Main = "UIN14Main",
    UIN14FishingGameStageController = "UIN14FishingGameStageController",
    -- N15
    UIN15MainController = "UIN15MainController",
    UIN15LineMissionController = "UIN15LineMissionController",
    UIN15RaffleController = "UIN15RaffleController",
    UIN15ChessController = "UIN15ChessController",
    -- N16
    UIActivityN16MainController = "UIActivityN16MainController",
    UIActivityN16LineMissionController = "UIActivityN16LineMissionController",
    UIN16HardLevel = "UIN16HardLevel",
    UIActivityShopControllerN16 = "UIActivityShopControllerN16",
    -- N17
    UIN17MainController = "UIN17MainController",
    UIN17LotteryController = "UIN17LotteryController",
    -- N18
    UIN18Main = "UIN18Main",
    UIN18LineMissionController = "UIN18LineMissionController",
    UIN18HardMissionController = "UIN18HardMissionController",
    UIN18ShopController = "UIN18ShopController",
    UIN18Shop = "UIN18Shop",
    --家园
    UIHomeland = "UIHomeland",
    UIHomelandBuild = "UIHomelandBuild",
    UIHomeStoryController = "UIHomeStoryController",
    UIHomeMovieStoryController = "UIHomeMovieStoryController",
    UIHomelandFishMatchEnd = "UIHomelandFishMatchEnd",
    --homestory
    UIStoryViewer3D = "UIStoryViewer3D",
    -- N19
    UIN19MainController = "UIN19MainController",
    UIN19LineMissionController = "UIN19LineMissionController",
    UIN19HardLevelController = "UIN19HardLevelController",
    -- N19P5
    UIN19P5 = "UIN19P5Controller",
    UIN19P5DrawCard = "UIN19P5AwardController",
    -- N20
    UIActivityN20MainController = "UIActivityN20MainController",
    UIActivityN20NormalLevel = "UIActivityN20NormalLevel",
    UIActivityN20HardLevel = "UIActivityN20HardLevel",
    UIN20AVGMain = "UIN20AVGMain",
    UIN20AVGStory = "UIN20AVGStory",
    -- N21
    UIN21Controller = "UIN21Controller",
    UIN21LineMissionController = "UIN21LineMissionController",
    UIN21ShopController = "UIN21ShopController",
    --n23
    UIN23Main = "UIN23Main",
    UIN23Line = "UIN23Line",
    UIN23Shop = "UIN23Shop",
    UIHomelandMoviePrepareMainController = "UIHomelandMoviePrepareMainController", --拍电影准�?
    UIHomelandMovieClosingController = "UIHomelandMovieClosingController", --拍电影准�?
    --region 活动回顾
    UIActivityReview = "UIActivityReview",
    UIExtraSelect = "UIExtraSelect",
    UIActivityEveSinsaMainController_Review = "UIActivityEveSinsaMainController_Review",
    UIActivityEveSinsaLevelAController_Review = "UIActivityEveSinsaLevelAController_Review",
    UIActivityEveSinsaLevelBController_Review = "UIActivityEveSinsaLevelBController_Review",
    UISakuraEntryController_Review = "UISakuraEntryController_Review",
    UISummer1Review = "UISummer1Review",
    UIXH1SimpleLevelReview = "UIXH1SimpleLevelReview",
    UIXH1HardLevelReview = "UIXH1HardLevelReview",
    UISummer2MainControllerReview = "UISummer2MainControllerReview",
    UIActivityN5SimpleLevelReview = "UIActivityN5SimpleLevelReview",
    UIN5MainController_Review = "UIN5MainController_Review",
    UIN7MainReview = "UIN7MainReview",
    UIN7LevelReview = "UIN7LevelReview",
    --endregion
    UIActivityN21CCMainController = "UIActivityN21CCMainController",
    UIActivityN21CCLevelDetail = "UIActivityN21CCLevelDetail",
    UIActivityN22MainController = "UIActivityN22MainController",
    UIActivityN22LineMissionController = "UIActivityN22LineMissionController",
    UIActivtiyN22HardLevelController = "UIActivtiyN22HardLevelController",
    UIActivtiyN22ShopController = "UIActivtiyN22ShopController",
    UIN22EntrustStageController = "UIN22EntrustStageController",
    UIN22EntrustLevelController = "UIN22EntrustLevelController",
    --n24
    UIActivityN24MainController = "UIActivityN24MainController",
    UIN24Shop = "UIN24Shop",
    --n25
    UIActivityN25MainController = "UIActivityN25MainController",
    UIN25Line = "UIN25Line",
    UIN25Shop = "UIN25Shop",
    UIActivtiyN25HardLevelController = "UIActivtiyN25HardLevelController",
    UIN25IdolLogin = "UIN25IdolLogin",
    UIN25VampireMain = "UIN25VampireMain",
    UIN25VampireTalentTree = "UIN25VampireTalentTree",
    UIN6MainController_Review = "UIN6MainController_Review",
    UIActivityN6LineMissionReview = "UIActivityN6LineMissionReview",
    UIActivityN6ReviewBuildingMainController = "UIActivityN6ReviewBuildingMainController",
    UIN25VampireLevel = "UIN25VampireLevel",
    UIActivityOneAndHalfAnniversaryVideoController = "UIActivityOneAndHalfAnniversaryVideoController",
    --n26
    UIActivityN26MainController = "UIActivityN26MainController",
    UIN26Line = "UIN26Line",
    UIN26HardLevel = "UIN26HardLevel",
    UIN26CookMainController = "UIN26CookMainController",
    UIN26CookMatRequireController = "UIN26CookMatRequireController",
    UIN26CookBookController = "UIN26CookBookController",
    UIN26CookMakeController = "UIN26CookMakeController",
    --n27
    UIActivityN27HardLevelMain = "UIActivityN27HardLevelMain",
    UIN27LotteryMain = "UIN27LotteryMain",
    UIN27PostInnerGameController = "UIN27PostInnerGameController",
    UIN27MiniGameController = "UIN27MiniGameController",
    UIN27LineMissionController = "UIN27LineMissionController",
    UIN27Controller = "UIN27Controller",
    UIActivityN8LineMissionController_Review = "UIActivityN8LineMissionController_Review",
    UIActivityN8MainController_Review = "UIActivityN8MainController_Review",
    --n28
    UIActivityN28MainController = "UIActivityN28MainController",
    UIActivityN9LineMissionController_Review = "UIActivityN9LineMissionController_Review",
    UIActivityN9MainController_Review = "UIActivityN9MainController_Review",
    UIN28GronruPlatform = "UIN28GronruPlatform",
    UIActivityN28Shop = "UIActivityN28Shop",
    UIN28HardLevel = "UIN28HardLevel",
    UIN28Line = "UIN28Line",
    UIN28GronruGameSelectPlayer = "UIN28GronruGameSelectPlayer",
    UIN28GronruGameFlash = "UIN28GronruGameFlash",
    UIN28GronruGameLevel = "UIN28GronruGameLevel",
    UIN28GronruGameRewards = "UIN28GronruGameRewards",
    UIN28AVGMain = "UIN28AVGMain",
    UIN28AVGStory = "UIN28AVGStory",
    --n28盜寶�?
    UIN28Errand = "UIN28Errand",
    UIBounceMainController = "UIBounceMainController",
    --n29
    UIN29ChessController = "UIN29ChessController",
    UIActivityN29MainController = "UIActivityN29MainController",
    UIActivityN29DetectiveMapController = "UIActivityN29DetectiveMapController",
    UIN29DetectiveLogin = "UIN29DetectiveLogin",
    UIActivityN11LineMissionController_Review = "UIActivityN11LineMissionController_Review",
    UIActivityN11MainController_Review = "UIActivityN11MainController_Review",
    UIActivityN29HardLevelMain = "UIActivityN29HardLevelMain",
    UIN29DetectivePersonController = "UIN29DetectivePersonController.prefab",
    UIN29DetectiveSuspectController = "UIN29DetectiveSuspectController.prefab",
    UIN29DetectiveCluePopController = "UIN29DetectiveCluePopController.prefab",
    UIN29DetectiveReasoningPopController = "UIN29DetectiveReasoningPopController.prefab",
    UIActivityN29LineLevel = "UIActivityN29LineLevel",
    UIN29Shop = "UIN29Shop",
    UIActivityN30MainController = "UIActivityN30MainController",
    UIN30ShopController = "UIN30ShopController",
    UIN30Entrust = "UIN30Entrust",
    UIN30EntrustLine = "UIN30EntrustLine",
    --n30
    UIN12MainController_Review = "UIN12MainReviewController",
    UIN12IntegralController_Review = "UIN12IntegralReviewController",
    --n31
    UIN31HardLevel = "UIN31HardLevel",
    UIN31Line = "UIN31Line",
    UIActivityN31MainController = "UIActivityN31MainController",
    UIActivityN31Shop = "UIActivityN31Shop",
    UIN13MainControllerReview = "UIN13MainControllerReview",
    UIN13LineMissionControllerReview = "UIN13LineMissionControllerReview",
    UIN13BuildControllerReview = "UIN13BuildControllerReview",
    UIN32MultiLineMain = "UIN32MultiLineMain",
    UIN32MultiLineMapController = "UIN32MultiLineMapController",
    UIActivityN32MainController = "UIActivityN32MainController",
    UIN32ShopController = "UIN32ShopController",
    UIActivityN32HardLevelMain = "UIActivityN32HardLevelMain",
    UIActivityN32PeridalesLevelMain = "UIActivityN32PeridalesLevelMain",
    UIN14MainReview = "UIN14MainReview",
    UIActivityN14LineMissionControllerReview = "UIActivityN14LineMissionControllerReview",
    --33
    UIActivityN33MainController = "UIActivityN33MainController",
    UIActivityN33LevelController = "UIActivityN33LevelController",
    UIActivityN33DateMainController = "UIActivityN33DateMainController",
    UIActivityN33BuildingInfo = "UIActivityN33BuildingInfo",
    UIN33ShopController = "UIN33ShopController",
    UIActivityN33ArchUpgradeReward = "UIActivityN33ArchUpgradeReward",
    UIN15MainControllerReview = "UIN15MainControllerReview",
    UIN15LineMissionControllerReview = "UIN15LineMissionControllerReview",
    --s1
    UISeason = "UISeason",                                           --赛季局内玩法
    UISeasonExploreMainController = "UISeasonExploreMainController", --赛季局内玩法
    UIS1Main = "UIS1Main",                                           --s1主界面
    --n34
    UIN34DispatchMain = "UIN34DispatchMain",
    UIActivityN34TaskMainController = "UIActivityN34TaskMainController",
    UIActivityN34MainController = "UIActivityN34MainController", 
    UIActivityN16ReviewMainController = "UIActivityN16ReviewMainController",
    UIActivityN16ReviewLineMissionController = "UIActivityN16ReviewLineMissionController",
}
_enum("UIStateType", _UIStateType)
UIStateType = UIStateType

---切state不执行gc的state
NoGCStateList = {
    "UITower"
}

---Loading类型参数
---@class UILoadingType
local UILoadingType = {
    Match = 1,
    AircraftEnter = 2,
    AircraftExit = 3,
    MazeEnter = 4,
    MazeExit = 5
}
_enum("UILoadingType", UILoadingType)

--常见场景容器
local SceneContainer = {}
SceneContainer.Default = ""
SceneContainer.UIScene = "UI"

-- SceneContainer.Aircraft = "fc_ui"

---@class UIStateRegister:Singleton

_class("UIStateRegister", Singleton)

UIStateRegister = UIStateRegister

-- UI状态注册：

---@param uiStateManager UIStateManager

function UIStateRegister.Register(uiStateManager)
    --uiStateManager:RegisterUIState(UIStateType, UIState:New(场景名称, UIController名称1, UIController名称2,...))
    uiStateManager:RegisterUIState(UIStateType.LoginEmpty, UIState:New(SceneContainer.UIScene, "UILoginEmpty"))

    uiStateManager:RegisterUIState(UIStateType.UIMain, UIState:New(SceneContainer.UIScene, "UIMainLobbyController"))

    uiStateManager:RegisterUIState(UIStateType.UIBattle, UIState:New(SceneContainer.Default, "UIBattle"), true)

    uiStateManager:RegisterUIState(UIStateType.UIDiscovery, UIState:New(SceneContainer.UIScene, "UIDiscovery"))

    uiStateManager:RegisterUIState(UIStateType.UITeams, UIState:New(SceneContainer.UIScene, "UITeams"))
    uiStateManager:RegisterUIState(UIStateType.UITeamsGuide, UIState:New(SceneContainer.UIScene, "UITeamsGuide"))

    --活动中心
    uiStateManager:RegisterUIState(
        UIStateType.UISideEnterCenter,
        UIState:New(SceneContainer.UIScene, "UISideEnterCenterController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UITeamChangeController,
        UIState:New(SceneContainer.UIScene, "UITeamChangeController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIAircraft,
        UIState:New(SceneContainer.Default, "UIAircraftController"),
        true
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIHomelandBuild,
        UIState:New(SceneContainer.Default, "UIHomelandBuild"),
        true
    )

    uiStateManager:RegisterUIState(UIStateType.UIHomeland, UIState:New(SceneContainer.Default, "UIHomelandMain"), true)

    uiStateManager:RegisterUIState(
        UIStateType.UIHomeStoryController,
        UIState:New(SceneContainer.Default, "UIHomeStoryController"),
        true
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIHomelandFishMatchEnd,
        UIState:New(SceneContainer.Default, "UIHomelandFishMatchEnd"),
        true
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIExtraMission,
        UIState:New(SceneContainer.UIScene, "UIExtraMissionDetailController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIExtraMissionStage,
        UIState:New(SceneContainer.UIScene, "UIExtraMissionStageController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIStoryController,
        UIState:New(SceneContainer.Default, "UIStoryController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIStoryViewer,
        UIState:New(SceneContainer.Default, "UIStoryViewerController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UISKillEditor,
        UIState:New(SceneContainer.Default, "UISkillEditorController")
    )

    uiStateManager:RegisterUIState(UIStateType.UIMaze, UIState:New(SceneContainer.Default, "UIMazeController"))
    uiStateManager:RegisterUIState(
        UIStateType.UIResDetailController,
        UIState:New(SceneContainer.UIScene, "UIResDetailController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIResEntryController,
        UIState:New(SceneContainer.UIScene, "UIResEntryController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIDrawCard,
        UIState:New(SceneContainer.Default, "UIDrawCardController"),
        true
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIDrawCardAnim,
        UIState:New(SceneContainer.Default, "UIDrawCardAnimController")
    )
    uiStateManager:RegisterUIState(UIStateType.UITower, UIState:New(SceneContainer.Default, "UITowerController"))
    uiStateManager:RegisterUIState(
        UIStateType.UITowerLayer,
        UIState:New(SceneContainer.UIScene, "UITowerLayerController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIStageTest,
        UIState:New(SceneContainer.Default, "UIStageTestController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UICutsceneTest,
        UIState:New(SceneContainer.Default, "UICutsceneTestController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIShopController,
        UIState:New(SceneContainer.UIScene, "UIShopController")
    )
    uiStateManager:RegisterUIState(UIStateType.UICommonLoading, UIState:New(SceneContainer.Default, "UICommonLoading"))

    uiStateManager:RegisterUIState(
        UIStateType.UITrailLevel,
        UIState:New(SceneContainer.UIScene, "UITrailLevelController")
    )
    uiStateManager:RegisterUIState(UIStateType.UITalePetList, UIState:New(SceneContainer.UIScene, "UITalePetList"))
    uiStateManager:RegisterUIState(
        UIStateType.UITalePetCollect,
        UIState:New(SceneContainer.UIScene, "UITalePetMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaMainController,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaMainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaLevelAController,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaLevelAController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaLevelBController,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaLevelBController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UISakuraEntryController,
        UIState:New(SceneContainer.UIScene, "UISakuraEntryController")
    )
    uiStateManager:RegisterUIState(UIStateType.UISummer1, UIState:New(SceneContainer.UIScene, "UISummer1"))
    uiStateManager:RegisterUIState(
        UIStateType.UIXH1SimpleLevel,
        UIState:New(SceneContainer.UIScene, "UIXH1SimpleLevel")
    )
    uiStateManager:RegisterUIState(UIStateType.UIXH1HardLevel, UIState:New(SceneContainer.UIScene, "UIXH1HardLevel"))
    uiStateManager:RegisterUIState(
        UIStateType.UISummer2,
        UIState:New(SceneContainer.UIScene, "UISummerActivityTwoMainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UISummer2Level,
        UIState:New(SceneContainer.UIScene, "UISummerActivityTwoLevelController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityBattlePassMainController,
        UIState:New(SceneContainer.UIScene, "UIActivityBattlePassMainController")
    )

    uiStateManager:RegisterUIState(UIStateType.UIPlot, UIState:New(SceneContainer.UIScene, "UIPlot"))

    uiStateManager:RegisterUIState(
        UIStateType.UICutsceneReview,
        UIState:New(SceneContainer.Default, "UICutsceneReviewController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIActivityN5, UIState:New(SceneContainer.UIScene, "UIN5MainController"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN5BattleField,
        UIState:New(SceneContainer.UIScene, "UIN5BattleFieldController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN5BattleField,
        UIState:New(SceneContainer.UIScene, "UIN5BattleFieldController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN6,
        UIState:New(SceneContainer.UIScene, "UIActivityNPlusSixMainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UINP6Level, UIState:New(SceneContainer.UIScene, "UINP6Level"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN5SimpleLevel,
        UIState:New(SceneContainer.UIScene, "UIActivityN5SimpleLevel")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN5ProgressController,
        UIState:New(SceneContainer.UIScene, "UIN5ProgressController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UILostLandMain,
        UIState:New(SceneContainer.Default, "UILostLandMainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UILostLandStage,
        UIState:New(SceneContainer.Default, "UILostLandStageController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIWeekTower,
        UIState:New(SceneContainer.UIScene, "UIWeekTowerController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIWorldBoss,
        UIState:New(SceneContainer.UIScene, "UIWorldBossController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIGlobalBoss,
        UIState:New(SceneContainer.UIScene, "UIGlobalBossController")
    )

    uiStateManager:RegisterUIState(UIStateType.UISailingMain, UIState:New(SceneContainer.UIScene, "UISailing"))
    uiStateManager:RegisterUIState(
        UIStateType.UISailingChapter,
        UIState:New(SceneContainer.UIScene, "UISailingChapter")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN7MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN7MainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN7Level, UIState:New(SceneContainer.UIScene, "UIN7Level"))
    uiStateManager:RegisterUIState(
        UIStateType.UIBlackFightMain,
        UIState:New(SceneContainer.UIScene, "UIBlackFightMain")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN7LevelDetailsController,
        UIState:New(SceneContainer.UIScene, "UIN7LevelDetailsController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN8MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN8MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN8LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN8LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN8BattleSimulatorController,
        UIState:New(SceneContainer.UIScene, "UIActivityN8BattleSimulatorController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN9MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN9MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN9LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN9LineMissionController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN9HardLevel, UIState:New(SceneContainer.UIScene, "UIN9HardLevel"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityShopControllerN9,
        UIState:New(SceneContainer.UIScene, "UIActivityShopControllerN9")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN10MainController,
        UIState:New(SceneContainer.UIScene, "UIN10MainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN11Main, UIState:New(SceneContainer.UIScene, "UIN11Main"))
    uiStateManager:RegisterUIState(UIStateType.UIN11Shop, UIState:New(SceneContainer.UIScene, "UIN11Shop"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN12MainController,
        UIState:New(SceneContainer.UIScene, "UIN12MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN12NormalLevel,
        UIState:New(SceneContainer.UIScene, "UIN12NormalLevel")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN12HardlLevel, UIState:New(SceneContainer.UIScene, "UIN12HardlLevel"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN12HardlLevelInfo,
        UIState:New(SceneContainer.UIScene, "UIN12HardlLevelInfo")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN12IntegralController,
        UIState:New(SceneContainer.UIScene, "UIN12IntegralController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN12EntrustStageController,
        UIState:New(SceneContainer.UIScene, "UIN12EntrustStageController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN12EntrustLevelController,
        UIState:New(SceneContainer.UIScene, "UIN12EntrustLevelController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN11LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN11LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivtiyN11HardLevelController,
        UIState:New(SceneContainer.UIScene, "UIActivtiyN11HardLevelController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityDoubleDropIntroduce,
        UIState:New(SceneContainer.UIScene, "UIActivityDoubleDropIntroduce")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN13BuildController,
        UIState:New(SceneContainer.UIScene, "UIN13BuildController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN13MainController,
        UIState:New(SceneContainer.UIScene, "UIN13MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN13LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIN13LineMissionController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN14Main, UIState:New(SceneContainer.UIScene, "UIN14Main"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN14LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN14LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN14HardMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN14HardMissionController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN14Shop, UIState:New(SceneContainer.UIScene, "UIN14Shop"))

    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN16MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN16MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN16LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN16LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityShopControllerN16,
        UIState:New(SceneContainer.UIScene, "UIActivityShopControllerN16")
    )
    -- N15
    uiStateManager:RegisterUIState(
        UIStateType.UIN15MainController,
        UIState:New(SceneContainer.UIScene, "UIN15MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN15LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIN15LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN15RaffleController,
        UIState:New(SceneContainer.UIScene, "UIN15RaffleController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN15ChessController,
        UIState:New(SceneContainer.UIScene, "UIN15ChessController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIHomeStoryController,
        UIState:New(SceneContainer.Default, "UIHomeStoryController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIHomeMovieStoryController,
        UIState:New(SceneContainer.Default, "UIHomeMovieStoryController")
    )

    -- N16
    uiStateManager:RegisterUIState(UIStateType.UIN16HardLevel, UIState:New(SceneContainer.UIScene, "UIN16HardLevel"))

    -- N17
    uiStateManager:RegisterUIState(
        UIStateType.UIN17MainController,
        UIState:New(SceneContainer.UIScene, "UIN17MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN17LotteryController,
        UIState:New(SceneContainer.UIScene, "UIN17LotteryController")
    )

    -- N18
    uiStateManager:RegisterUIState(UIStateType.UIN18Main, UIState:New(SceneContainer.UIScene, "UIN18MainController"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN18LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIN18LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN18HardMissionController,
        UIState:New(SceneContainer.UIScene, "UIN18HardMissionController")
    )

    uiStateManager:RegisterUIState(UIStateType.UIN18Shop, UIState:New(SceneContainer.UIScene, "UIN18Shop"))

    --homestory
    uiStateManager:RegisterUIState(UIStateType.UIStoryViewer3D, UIState:New(SceneContainer.Default, "UIStoryViewer3D"))

    -- N19
    uiStateManager:RegisterUIState(
        UIStateType.UIN19MainController,
        UIState:New(SceneContainer.UIScene, "UIN19MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN19LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIN19LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN19HardLevelController,
        UIState:New(SceneContainer.UIScene, "UIN19HardLevelController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN20MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN20MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN20NormalLevel,
        UIState:New(SceneContainer.UIScene, "UIActivityN20NormalLevel")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN20HardLevel,
        UIState:New(SceneContainer.UIScene, "UIActivityN20HardLevel")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN20AVGMain, UIState:New(SceneContainer.UIScene, "UIN20AVGMain"))
    uiStateManager:RegisterUIState(UIStateType.UIN20AVGStory, UIState:New(SceneContainer.UIScene, "UIN20AVGStory"))
    --n19p5
    uiStateManager:RegisterUIState(UIStateType.UIN19P5, UIState:New(SceneContainer.UIScene, "UIN19P5Controller"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN19P5DrawCard,
        UIState:New(SceneContainer.UIScene, "UIN19P5AwardController")
    )

    --region 活动回顾
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityReview,
        UIState:New(SceneContainer.UIScene, "UIActivityReview")
    )
    uiStateManager:RegisterUIState(UIStateType.UIExtraSelect, UIState:New(SceneContainer.UIScene, "UIExtraSelect"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaMainController_Review,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaMainController_Review")
    )
    uiStateManager:RegisterUIState(UIStateType.UISummer1Review, UIState:New(SceneContainer.UIScene, "UISummer1Review"))
    uiStateManager:RegisterUIState(
        UIStateType.UIXH1SimpleLevelReview,
        UIState:New(SceneContainer.UIScene, "UIXH1SimpleLevelReview")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIXH1HardLevelReview,
        UIState:New(SceneContainer.UIScene, "UIXH1HardLevelReview")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaLevelAController_Review,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaLevelAController_Review")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityEveSinsaLevelBController_Review,
        UIState:New(SceneContainer.UIScene, "UIActivityEveSinsaLevelBController_Review")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UISummer2MainControllerReview,
        UIState:New(SceneContainer.UIScene, "UISummer2MainControllerReview")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UISakuraEntryController_Review,
        UIState:New(SceneContainer.UIScene, "UISakuraEntryController_Review")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN5SimpleLevelReview,
        UIState:New(SceneContainer.UIScene, "UIActivityN5SimpleLevelReview")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN5MainController_Review,
        UIState:New(SceneContainer.UIScene, "UIN5MainController_Review")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN7MainReview, UIState:New(SceneContainer.UIScene, "UIN7MainReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN7LevelReview, UIState:New(SceneContainer.UIScene, "UIN7LevelReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN12MainController_Review, UIState:New(SceneContainer.UIScene, "UIN12MainController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIN12IntegralController_Review, UIState:New(SceneContainer.UIScene, "UIN12IntegralController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIN13MainControllerReview, UIState:New(SceneContainer.UIScene, "UIN13MainControllerReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN13LineMissionControllerReview, UIState:New(SceneContainer.UIScene, "UIN13LineMissionControllerReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN13BuildControllerReview, UIState:New(SceneContainer.UIScene, "UIN13BuildControllerReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN14MainReview, UIState:New(SceneContainer.UIScene, "UIN14MainReview"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN14LineMissionControllerReview, UIState:New(SceneContainer.UIScene, "UIActivityN14LineMissionControllerReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN15MainControllerReview, UIState:New(SceneContainer.UIScene, "UIN15MainControllerReview"))
    uiStateManager:RegisterUIState(UIStateType.UIN15LineMissionControllerReview, UIState:New(SceneContainer.UIScene, "UIN15LineMissionControllerReview"))
    --endregion
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN21CCMainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN21CCMainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN21CCLevelDetail,
        UIState:New(SceneContainer.UIScene, "UIActivityN21CCLevelDetail")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN21Controller, UIState:New(SceneContainer.UIScene, "UIN21Controller"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN21LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIN21LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN21ShopController,
        UIState:New(SceneContainer.UIScene, "UIN21ShopController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN22MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN22MainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN22LineMissionController,
        UIState:New(SceneContainer.UIScene, "UIActivityN22LineMissionController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivtiyN22HardLevelController,
        UIState:New(SceneContainer.UIScene, "UIActivtiyN22HardLevelController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivtiyN22ShopController,
        UIState:New(SceneContainer.UIScene, "UIActivtiyN22ShopController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN22EntrustStageController,
        UIState:New(SceneContainer.UIScene, "UIN22EntrustStageController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN22EntrustLevelController,
        UIState:New(SceneContainer.UIScene, "UIN22EntrustLevelController")
    )
    --n23
    uiStateManager:RegisterUIState(UIStateType.UIN23Main, UIState:New(SceneContainer.UIScene, "UIN23Main"))
    uiStateManager:RegisterUIState(UIStateType.UIN23Line, UIState:New(SceneContainer.UIScene, "UIN23Line"))
    uiStateManager:RegisterUIState(UIStateType.UIN23Shop, UIState:New(SceneContainer.UIScene, "UIN23Shop"))

    uiStateManager:RegisterUIState(
        UIStateType.UIHomelandMoviePrepareMainController,
        UIState:New(SceneContainer.Default, "UIHomelandMoviePrepareMainController")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIHomelandMovieClosingController,
        UIState:New(SceneContainer.Default, "UIHomelandMovieClosingController")
    )
    --n24
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN24MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN24MainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN24Shop, UIState:New(SceneContainer.UIScene, "UIN24Shop"))

    --n25
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN25MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN25MainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN25Line, UIState:New(SceneContainer.UIScene, "UIN25Line"))
    uiStateManager:RegisterUIState(UIStateType.UIN25Shop, UIState:New(SceneContainer.UIScene, "UIN25Shop"))
    uiStateManager:RegisterUIState(
        UIStateType.UIActivtiyN25HardLevelController,
        UIState:New(SceneContainer.UIScene, "UIActivtiyN25HardLevelController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN25IdolLogin, UIState:New(SceneContainer.UIScene, "UIN25IdolLogin"))
    uiStateManager:RegisterUIState(
        UIStateType.UIN25VampireMain,
        UIState:New(SceneContainer.UIScene, "UIN25VampireMain")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN25VampireTalentTree,
        UIState:New(SceneContainer.UIScene, "UIN25VampireTalentTree")
    )

    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN6LineMissionReview,
        UIState:New(SceneContainer.UIScene, "UIActivityN6LineMissionReview")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN6MainController_Review,
        UIState:New(SceneContainer.UIScene, "UIN6MainController_Review")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN6ReviewBuildingMainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN6ReviewBuildingMainController")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIN25VampireLevel,
        UIState:New(SceneContainer.UIScene, "UIN25VampireLevel")
    )
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityOneAndHalfAnniversaryVideoController,
        UIState:New(SceneContainer.UIScene, "UIActivityOneAndHalfAnniversaryVideoController")
    )
    --N26
    uiStateManager:RegisterUIState(
        UIStateType.UIActivityN26MainController,
        UIState:New(SceneContainer.UIScene, "UIActivityN26MainController")
    )
    uiStateManager:RegisterUIState(UIStateType.UIN26Line, UIState:New(SceneContainer.UIScene, "UIN26Line"))
    uiStateManager:RegisterUIState(UIStateType.UIN26HardLevel, UIState:New(SceneContainer.UIScene, "UIN26HardLevel"))
    uiStateManager:RegisterUIState(UIStateType.UIN26CookMainController, UIState:New(SceneContainer.UIScene, "UIN26CookMainController"))
    uiStateManager:RegisterUIState(UIStateType.UIN26CookMatRequireController, UIState:New(SceneContainer.UIScene, "UIN26CookMatRequireController"))
    uiStateManager:RegisterUIState(UIStateType.UIN26CookBookController, UIState:New(SceneContainer.UIScene, "UIN26CookBookController"))
    uiStateManager:RegisterUIState(UIStateType.UIN26CookMakeController, UIState:New(SceneContainer.UIScene, "UIN26CookMakeController"))
    --N27
    uiStateManager:RegisterUIState(UIStateType.UIActivityN27HardLevelMain, UIState:New(SceneContainer.UIScene, "UIActivityN27HardLevelMain"))
    uiStateManager:RegisterUIState(UIStateType.UIN27LotteryMain, UIState:New(SceneContainer.UIScene, "UIN27LotteryMain"))
    uiStateManager:RegisterUIState(UIStateType.UIN27PostInnerGameController, UIState:New(SceneContainer.UIScene, "UIN27PostInnerGameController"))
    uiStateManager:RegisterUIState(UIStateType.UIN27MiniGameController, UIState:New(SceneContainer.UIScene, "UIN27MiniGameController"))
    uiStateManager:RegisterUIState(UIStateType.UIN27LineMissionController, UIState:New(SceneContainer.UIScene, "UIN27LineMissionController"))
    uiStateManager:RegisterUIState(UIStateType.UIN27Controller, UIState:New(SceneContainer.UIScene, "UIN27Controller"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN8LineMissionController_Review, UIState:New(SceneContainer.UIScene, "UIActivityN8LineMissionController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN8MainController_Review, UIState:New(SceneContainer.UIScene, "UIActivityN8MainController_Review"))
    --N28
    uiStateManager:RegisterUIState(UIStateType.UIActivityN28MainController, UIState:New(SceneContainer.UIScene, "UIActivityN28MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN9MainController_Review, UIState:New(SceneContainer.UIScene, "UIActivityN9MainController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN9LineMissionController_Review, UIState:New(SceneContainer.UIScene, "UIActivityN9LineMissionController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIN28GronruPlatform, UIState:New(SceneContainer.UIScene, "UIN28GronruPlatform"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN28Shop, UIState:New(SceneContainer.UIScene, "UIActivityN28Shop"))
    uiStateManager:RegisterUIState(UIStateType.UIN28HardLevel, UIState:New(SceneContainer.UIScene, "UIN28HardLevel"))
    uiStateManager:RegisterUIState(UIStateType.UIN28Line, UIState:New(SceneContainer.UIScene, "UIN28Line"))
    uiStateManager:RegisterUIState(UIStateType.UIN28GronruGameFlash, UIState:New(SceneContainer.UIScene, "UIN28GronruGameFlash"))
    uiStateManager:RegisterUIState(UIStateType.UIN28GronruGameSelectPlayer, UIState:New(SceneContainer.UIScene, "UIN28GronruGameSelectPlayer"))
    uiStateManager:RegisterUIState(UIStateType.UIN28GronruGameLevel, UIState:New(SceneContainer.UIScene, "UIN28GronruGameLevel"))
    uiStateManager:RegisterUIState(UIStateType.UIN28GronruGameRewards, UIState:New(SceneContainer.UIScene, "UIN28GronruGameRewards"))
    uiStateManager:RegisterUIState(UIStateType.UIN28AVGMain, UIState:New(SceneContainer.UIScene, "UIN28AVGMain"))
    uiStateManager:RegisterUIState(UIStateType.UIN28AVGStory, UIState:New(SceneContainer.UIScene, "UIN28AVGStory"))
    --n28 盗宝�?
    uiStateManager:RegisterUIState(UIStateType.UIN28Errand, UIState:New(SceneContainer.UIScene, "UIN28ErrandController"))
    uiStateManager:RegisterUIState(UIStateType.UIBounceMainController, UIState:New(SceneContainer.UIScene, "UIBounceMainController"))
    --n29
    uiStateManager:RegisterUIState(UIStateType.UIN29ChessController,UIState:New(SceneContainer.UIScene, "UIN29ChessController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN29MainController, UIState:New(SceneContainer.UIScene, "UIActivityN29MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN29DetectiveMapController, UIState:New(SceneContainer.UIScene, "UIActivityN29DetectiveMapController"))
    uiStateManager:RegisterUIState(UIStateType.UIN29DetectiveLogin, UIState:New(SceneContainer.UIScene, "UIN29DetectiveLogin"))

    uiStateManager:RegisterUIState(UIStateType.UIActivityN11LineMissionController_Review,UIState:New(SceneContainer.UIScene, "UIActivityN11LineMissionController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN11MainController_Review,UIState:New(SceneContainer.UIScene, "UIActivityN11MainController_Review"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN29HardLevelMain,UIState:New(SceneContainer.UIScene, "UIActivityN29HardLevelMain"))

    uiStateManager:RegisterUIState(UIStateType.UIN29DetectivePersonController, UIState:New(SceneContainer.UIScene, "UIN29DetectivePersonController"))
    uiStateManager:RegisterUIState(UIStateType.UIN29DetectiveSuspectController, UIState:New(SceneContainer.UIScene, "UIN29DetectiveSuspectController"))
    uiStateManager:RegisterUIState(UIStateType.UIN29DetectiveCluePopController, UIState:New(SceneContainer.UIScene, "UIN29DetectiveCluePopController"))
    uiStateManager:RegisterUIState(UIStateType.UIN29DetectiveReasoningPopController, UIState:New(SceneContainer.UIScene, "UIN29DetectiveReasoningPopController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN29LineLevel, UIState:New(SceneContainer.UIScene, "UIActivityN29LineLevel"))
    uiStateManager:RegisterUIState(UIStateType.UIN29Shop, UIState:New(SceneContainer.UIScene, "UIN29Shop"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN30MainController, UIState:New(SceneContainer.UIScene, "UIActivityN30MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIN30ShopController, UIState:New(SceneContainer.UIScene, "UIN30ShopController"))
    uiStateManager:RegisterUIState(UIStateType.UIN30Entrust, UIState:New(SceneContainer.UIScene, "UIN30Entrust"))
    uiStateManager:RegisterUIState(UIStateType.UIN30EntrustLine, UIState:New(SceneContainer.UIScene, "UIN30EntrustLine"))
    --n31
    uiStateManager:RegisterUIState(UIStateType.UIN31HardLevel, UIState:New(SceneContainer.UIScene, "UIN31HardLevel"))
    uiStateManager:RegisterUIState(UIStateType.UIN31Line, UIState:New(SceneContainer.UIScene, "UIN31Line"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN31MainController, UIState:New(SceneContainer.UIScene, "UIActivityN31MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN31Shop, UIState:New(SceneContainer.UIScene, "UIActivityN31Shop"))
    
    --n32
    uiStateManager:RegisterUIState(UIStateType.UIActivityN32MainController, UIState:New(SceneContainer.UIScene, "UIActivityN32MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIN32MultiLineMain, UIState:New(SceneContainer.UIScene, "UIN32MultiLineMain"))
    uiStateManager:RegisterUIState(UIStateType.UIN32MultiLineMapController, UIState:New(SceneContainer.UIScene, "UIN32MultiLineMapController"))
    uiStateManager:RegisterUIState(UIStateType.UIN32ShopController, UIState:New(SceneContainer.UIScene, "UIN32ShopController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN32PeridalesLevelMain, UIState:New(SceneContainer.UIScene, "UIActivityN32PeridalesLevelMain"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN32HardLevelMain, UIState:New(SceneContainer.UIScene, "UIActivityN32HardLevelMain"))
    
    --n33
    uiStateManager:RegisterUIState(UIStateType.UIActivityN33MainController, UIState:New(SceneContainer.UIScene, "UIActivityN33MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN33LevelController, UIState:New(SceneContainer.UIScene, "UIActivityN33LevelController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN33DateMainController, UIState:New(SceneContainer.UIScene, "UIActivityN33DateMainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN33BuildingInfo, UIState:New(SceneContainer.UIScene, "UIActivityN33BuildingInfo"))
    uiStateManager:RegisterUIState(UIStateType.UIN33ShopController, UIState:New(SceneContainer.UIScene, "UIN33ShopController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN33ArchUpgradeReward, UIState:New(SceneContainer.UIScene, "UIActivityN33ArchUpgradeReward"))

    --s1
    uiStateManager:RegisterUIState(UIStateType.UISeason, UIState:New(SceneContainer.Default, "UISeasonMain"))
    uiStateManager:RegisterUIState(UIStateType.UISeasonExploreMainController, UIState:New(SceneContainer.Default, "UISeasonExploreMainController"))
    uiStateManager:RegisterUIState(UIStateType.UIS1Main, UIState:New(SceneContainer.Default, "UIS1MainController"))
    --n34
    uiStateManager:RegisterUIState(UIStateType.UIN34DispatchMain, UIState:New(SceneContainer.UIScene, "UIN34DispatchMain"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN34TaskMainController, UIState:New(SceneContainer.UIScene, "UIActivityN34TaskMainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN34MainController, UIState:New(SceneContainer.UIScene, "UIActivityN34MainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN16ReviewMainController, UIState:New(SceneContainer.UIScene, "UIActivityN16ReviewMainController"))
    uiStateManager:RegisterUIState(UIStateType.UIActivityN16ReviewLineMissionController, UIState:New(SceneContainer.UIScene, "UIActivityN16ReviewLineMissionController"))
end