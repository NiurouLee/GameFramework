--[[
    全局的mode配置
--]]
---@class GameModeType
---@field CommonBaseMode number
---@field NormalBattleMode number
---@field MazeBattleMode number
local GameModeType = {
    CommonBaseMode = 0, ---基础模组
    NormalBattleMode = 1, ---现有的一般玩法
    MazeBattleMode = 2, ---迷宫特殊玩法部分
    ChessBattleMode = 3,---战棋玩法
    PopStarMode = 4, ---消灭星星玩法
}
_enum("GameModeType", GameModeType)

GameModeConfig = {
    [GameModeType.CommonBaseMode] = {
        Systems = {
            [1] = {
                { Name = "Input", Type = "HandleInputSystem_Render"},
                { Name = "NetReceiver", Type = "CommandReceiveSystem"},
            },
            [2] = {
                { Name = "ChainSelectGrid", Type = "SelectGridSystem_Render"},
                { Name = "PickUpGrid", Type = "PickUpGridSystem_Render" },
                { Name = "MirageInput", Type = "MirageInputSystem_Render" },
                { Name = "LinkGrid", Type = "LinkGridSystem_Render" },
            },
            [3] = {
                ---划线
                { Name = "BeginDrag", Type = "GridBeginDragSystem_Render"},
                { Name = "Drag", Type = "GridDragSystem_Render"},
                { Name = "EndDrag", Type = "GridEndDragSystem_Render"},
                { Name = "DoubleClick", Type = "GridDoubleClickSystem_Render"},
                { Name = "WaitInputChain",Type = "WaitInputChainSystem",ClientType = "ClientWaitInputChainSystem_Render"},
                
                ---划线_主动技预览阶段
                { Name = "PreviewLinkLineBeginDrag", Type = "PreviewLinkLineBeginDragSystem_Render" },
                { Name = "PreviewLinkLineDrag",      Type = "PreviewLinkLineDragSystem_Render" },
                { Name = "PreviewLinkLineEndDrag",   Type = "PreviewLinkLineEndDragSystem_Render" },
                
                ---大招点选
                { Name = "PickUpInstruction", Type = "SkillPickUpInstructionSystem_Render"},
                { Name = "PickUpSwitchInstruction",Type = "SkillPickUpSwitchInstructionSystem_Render"},
                { Name = "PickUpChainInstruction",Type = "SkillPickUpChainInstructionSystem_Render"},
                { Name = "PickUpDirection",Type = "SkillPickUpDirectionInstructionSystem_Render"},
                { Name = "PickUpAndTeleport",Type = "SkillPickUpAndTeleportInstructionSystem_Render"},
                { Name = "PickAndDirection",Type = "SkillPickUpPickAndDirectionInstructionSystem_Render"},
                { Name = "PickAndDirection2",Type = "SkillPickUpPickAndDirection2InstructionSystem_Render"},
                { Name = "PickUpLineAndDirection",Type = "SkillPickUpLineAndDirectionInstructionSystem_Render"},
                { Name = "PickUpPosAndRotate",Type = "SkillPickUpPosAndRotateInstructionSystem_Render"},
                { Name = "PickUpDiffPower",Type = "SkillPickUpDiffPowerInstructionSystem_Render"},
                { Name = "PickUpAkexiya", Type = "SkillPickUpAkexiyaInstructionSystem_Render"},
                { Name = "PickUpYeliya", Type = "SkillPickUpYeliyaSystem_Render"},
                { Name = "PickDirOrSelf", Type = "SkillPickUpDirOrSelfSystem_Render" },
                { Name = "PickUpLinkLine", Type = "SkillPickUpLinkLineSystem_Render" },
                { Name = "PickUpHati", Type = "SkillPickUpHatiSystem_Render" },
                { Name = "PickUpGridTogether", Type = "SkillPickUpGridTogetherInstructionSystem_Render" },

                ---大招状态切换
                { Name = "PreviewActiveSkill", Type = "PreviewActiveSkillSystem_Render"},
                { Name = "PreviewActiveSkillState",Type = "PreviewActiveSkillStateSystem_Render"},
                { Name = "PickUpActiveSkillTarget", Type = "PickUpActiveSkillTargetSystem"},

                ---引导
                { Name = "GuidePath", Type = "GuidePathSystem_Render"},
                { Name = "GuidePreviewLinkLine",     Type = "GuidePreviewLinkLineSystem_Render" },

                ---主状态机
                { Name = "GameFSM", Type = "GameFSMSystem"},
                { Name = "Loading", Type = "LoadingSystem", ClientType = "ClientLoadingSystem_Render"},
                { Name = "BattleEnter",Type = "BattleEnterSystem",ClientType = "ClientBattleEnterSystem_Render"},
                { Name = "RoundEnter",Type = "RoundEnterSystem",ClientType = "RoundEnterSystem_Render"},
                { Name = "FirstWaveEnter",Type = "FirstWaveEnterSystem",ClientType = "ClientFirstWaveEnterSystem_Render",},
                { Name = "RoleTurn",Type = "RoleMovementSystem",ClientType = "ClientRoleMovementSystem_Render"},
                { Name = "RoleTurnResult",Type = "RoleTurnResultStateSystem",ClientType = "ClientRoleTurnResultSystem_Render"},
                { Name = "PieceRefresh",Type = "PieceRefreshSystem",ClientType = "ClientPieceRefreshSystem_Render"},
                { Name = "MonsterMove",Type = "MonsterMoveSystem",ClientType = "ClientMonsterMoveSystem_Render"},
                { Name = "BattleResult",Type = "BattleResultSystem",
                    ClientType = "ClientBattleResultSystem_Render",
                    ServerType = "ServerBattleResultSystem_Logic",},
                { Name = "RoundResult",Type = "RoundResultSystem",ClientType = "ClientRoundResultSystem_Render"},
                { Name = "WaveEnter",Type = "WaveEnterSystem",ClientType = "ClientWaveEnterSystem_Render",},
                { Name = "WaveResult",Type = "WaveResultSystem",ClientType = "ClientWaveResultSystem_Render",},
                { Name = "WaveResultAward",Type = "WaveResultAwardSystem",ClientType = "ClientWaveResultAwardSystem_Render",},
                { Name = "WaveResultAwardApply",Type = "WaveResultAwardApplySystem",ClientType = "ClientWaveResultAwardApplySystem_Render",},
                { Name = "WaveSwitch",Type = "WaveSwitchSystem",ClientType = "ClientWaveSwitchSystem_Render",},
                { Name = "ActiveSkill",Type = "ActiveSkillSystem",ClientType = "ClientActiveSkillSystem_Render",},
                { Name = "WaitInput",Type = "WaitInputSystem",ClientType = "ClientWaitInputSystem_Render"},
                { Name = "PersonaSkill",Type = "PersonaSkillSystem",ClientType = "ClientPersonaSkillSystem_Render",},
                { Name = "PreChainState",Type = "PreChainStateSystem",ClientType = "ClientPreChainSystem_Render"},
                { Name = "ChainAttackState",Type = "ChainAttackStateSystem",ClientType = "ClientChainAttackSystem_Render"},

                { Name = "ChangeTeamLeader",Type = "RoleChangeTeamLeaderSystem",
                    ClientType = "ClientRoleChangeTeamLeaderSystem_Render"},
                { Name = "PlayerNormalAttack",Type = "PlayerNormalAttackStateSystem_Render"},
                { Name = "PlayerFSM", Type = "PlayerActionFSMSystem_Render"},
                { Name = "PlayerChainAttackState", Type = "PlayerChainAttackStateSystem_Render"},

                { Name = "PlayerIdleState", Type = "PlayerIdleStateSystem_Render"},
                { Name = "GridMove", Type = "GridMoveSystem_Render" },

                ---幻境
                { Name = "MirageEnter", Type = "MirageEnterSystem", ClientType = "ClientMirageEnterSystem_Render" },
                { Name = "MirageWaitInput", Type = "MirageWaitInputSystem", ClientType = "ClientMirageWaitInputSystem_Render" },
                { Name = "MirageRoleTurn", Type = "MirageRoleTurnSystem", ClientType = "ClientMirageRoleTurnSystem_Render" },
                { Name = "MirageMonsterTurn", Type = "MirageMonsterTurnSystem", ClientType = "ClientMirageMonsterTurnSystem_Render" },
                { Name = "MirageEnd", Type = "MirageEndSystem", ClientType = "ClientMirageEndSystem_Render" },
            },
            [4] = {
                ---划线触发
                { Name = "PreSelect", Type = "SkillPreselectTargetSystem_Render"},
                { Name = "ConnectPieces", Type = "ConnectPiecesSystem_Render"},
                { Name = "LinkLine", Type = "LinkLineRenderSystem_Render"},
                { Name = "PreviewLinkLine", Type = "PreviewLinkLineSystem_Render" },
                { Name = "LinkageNum", Type = "LinkageNumViewAddSystem_Render"},
                { Name = "CancelConnect", Type = "CancelConnectSystem_Render"},
                { Name = "PreviewLinkLineCancelConnect", Type = "PreviewLinkLineCancelConnectSystem_Render"},
                { Name = "PreviewChainAttack",Type = "PreviewChainAttackRangeSystem_Render"},
                { Name = "PreviewMonster", Type = "PreviewMonsterActionSystem_Render"},
                { Name = "PreviewTrap", Type = "PreviewTrapActionSystem_Render"},
                { Name = "TimeSpeed", Type = "TimeSpeedSystemRender_Render" },
                { Name = "BulletTime", Type = "BulletTimeSystem"},

                ---一般效果播放
                { Name = "GridAddView", Type = "GridAddViewSystem_Render"},
                { Name = "MaterialFlash", Type = "MaterialFlashSystem_Render"},
                { Name = "HUDAddView", Type = "HUDAddViewSystem_Render"},
                { Name = "TrapRoundInfo", Type = "TrapRoundInfoSystem_Render"},
                { Name = "Hitback", Type = "HitbackSystem_Render"},
                { Name = "HPPosSystem_Render", Type = "HPPosSystem_Render" },
                { Name = "ChainMoveSystem_Render", Type = "ChainMoveSystem_Render" },
                { Name = "PreviewHitbackSystem_Render", Type = "PreviewHitbackSystem_Render" },
                { Name = "FadeControllerSystem_Render", Type = "FadeControllerSystem_Render" },
                { Name = "FadeTransprentSystem_Render", Type = "FadeTransprentSystem_Render" },
                { Name = "InnerStoryTipsSystem_Render", Type = "InnerStoryTipsSystem_Render" },
                { Name = "BoardOutlineSystem_Render", Type = "BoardOutlineSystem_Render" },
                { Name = "EffectLineRendererSystem_Render", Type = "EffectLineRendererSystem_Render" },
                --{ Name = "MonsterViewAddSystem_Render", Type = "MonsterViewAddSystem_Render" },
                { Name = "TrapViewAddSystem_Render", Type = "TrapViewAddSystem_Render" },
                { Name = "HPDisplaySystem_Render", Type = "HPDisplaySystem_Render" },
                { Name = "BuffMaterialAnimationSystem_Render", Type = "BuffMaterialAnimationSystem_Render" },
                { Name = "SkillRangeOutlineSystem_Render", Type = "SkillRangeOutlineSystem_Render" },
                
                ---引导
                { Name = "GuideWeakPath", Type = "GuideWeakPathSystem_Render"},
            },
            [5] = {
                ---划线触发
                { Name = "ConnectArea", Type = "ConnectAreaRenderSystem_Render"},
                { Name = "LinkLineGridEffect", Type = "LinkLineGridEffectSystem_Render"},
                { Name = "ChainSkllRangeFlash", Type = "ChainSkllRangeFlashSystem_Render"},
                { Name = "ChainPreviewMonsterBehavior", Type = "ChainPreviewMonsterBehaviorSystem_Render"},
                { Name = "SkillTips", Type = "SkillTipsViewSystem_Render"},

                ---一般效果播放
                { Name = "PlayAnimationSystem_Render", Type = "PlayAnimationSystem_Render" },
                { Name = "EffectAttach", Type = "EffectAttachSystem_Render"},
                { Name = "EffectPlay", Type = "EffectPlaySystem_Render"},
                { Name = "Animator", Type = "AnimatorControllerSystem_Render"},
                { Name = "DirectionAnimator", Type = "DirectionAnimatorSystem_Render"},
                { Name = "TrapAuras", Type = "TrapAurasSystem_Render" },
                ---网络输出
                { Name = "NetSend", Type = "CommandSendSystem" },

                ---自动战斗
                { Name = "AutoFight",ClientType = "AutoFightSystem_Render",ServerType = "SSys_AutoFight"},
            
            },

        },
        EditorSystems = {
            ---编辑器
            { Name = "EditorInfo", Type = "EditorInfoSystem_Render"},
            { Name = "FakeInput", Type = "FakeInputSystem"},
            { Name = "AutoTest", Type = "AutoTestSystem_Render"},
            { Name = "WorldDebug", Type = "WorldDebugSystem_Render"}
        },
        UniqueComponents = {
            PlayerComponent = {},
            GameFSMComponent = {},
            MainCameraComponent = {},
            InputComponent = {},
            GridTouchComponent = {},
            PickUpComponent = {},
            BattleStatComponent = {},
            BattleFlagsComponent = {},
            BattleRenderConfigComponent = {},
            RenderBattleStatComponent = {},
            MiragePickUpComponent = {},
        },
        Services = {
            --service begin
            { Name = "Config", Type = "ConfigService" },
            { Name = "Network", Type = "MatchNetworkService", ClientType = "DummyNetworkService" },
            { Name = "Math", Type = "MathService" },
            { Name = "Piece", Type = "PieceServiceRender" },
            { Name = "BuffLogic", Type = "BuffLogicService" },
            { Name = "Formula", Type = "FormulaService" },
            { Name = "Battle", Type = "BattleService" },
            { Name = "SkillLogic", Type = "SkillLogicService" },
            { Name = "BonusCalc", Type = "BonusCalcService" },
            { Name = "Star3Calc", Type = "Star3CalcService" },
            { Name = "CompleteCondition", Type = "CompleteConditionService" },
            { Name = "CreateMonsterPos", Type = "CreateMonsterPosService" },
            { Name = "MonsterRefresh", Type = "MonsterRefreshService" },
            { Name = "Maze", Type = "MazeService" },
            { Name = "AI", Type = "AIService" },
            { Name = "CalcDamage", Type = "CalcDamageService" },
            { Name = "SkillEffectCalc", Type = "SkillEffectCalcService" },
            { Name = "Drop", Type = "DropService" },
            { Name = "LogicEntity", Type = "LogicEntityService" },
            { Name = "LinkLine", Type = "LinkLineService" },
            { Name = "Time", Type = "TimeService", ClientType = "ClientTimeService" },
            { Name = "Guide", Type = "GuideServiceRender" },
            { Name = "Trigger", Type = "TriggerService" },
            { Name = "GuideLogic", Type = "GuideLogicService" },
            { Name = "AIScheduler", Type = "AISchedulerService" },
            { Name = "TrapLogic", Type = "TrapServiceLogic" },
            {
                Name = "SyncLogic",
                ClientType = "ClientSyncLogicService",
                ServerType = "ServerSyncLogicService"
            },
            {
                Name = "AutoFight",
                Type = "AutoFightService",
                ClientType = "AutoFightService",
                ServerType = "SSvc_AutoFight"
            },
            { Name = "MonsterMoveLogic", Type = "MonsterMoveServiceLogic" },
            { Name = "ChainAttackLogic", Type = "ChainAttackServiceLogic" },
            { Name = "ConfigDecoration", Type = "ConfigDecorationService" },
            { Name = "BoardLogic", Type = "BoardServiceLogic" },
            { Name = "RandomLogic", Type = "RandomServiceLogic" },
            { Name = "UtilData", Type = "UtilDataServiceShare" },
            { Name = "UtilCalc", Type = "UtilCalcServiceShare" },
            { Name = "UtilScopeCalc", Type = "UtilScopeCalcServiceShare" },
            { Name = "UtilData", Type = "UtilDataServiceShare" },
            { Name = "Resource", Type = "UnityResourceService" },
            { Name = "Effect", Type = "EffectService" },
            { Name = "Camera", Type = "CameraService" },
            { Name = "PlaySkill", Type = "PlaySkillService" },
            { Name = "CanMoveArrow", Type = "CanMoveArrowService" },
            { Name = "ResourcesPool", Type = "ResourcesPoolService" },
            { Name = "EventListener", Type = "EventListenerServiceRender" },
            { Name = "MonsterShowLogic", Type = "MonsterShowLogicService" },
            { Name = "MonsterShowRender", Type = "MonsterShowRenderService" },
            { Name = "RenderEntity", Type = "RenderEntityService" },
            { Name = "LinkageRender", Type = "LinkageRenderService" },
            { Name = "InnerStory", Type = "InnerStoryService" },
            { Name = "PlayBuff", Type = "PlayBuffService" },
            { Name = "PreviewCalcEffect", Type = "SkillPreviewEffectCalcService" },
            { Name = "PreviewActiveSkill", Type = "PreviewActiveSkillService" },
            { Name = "EntityPool", Type = "EntityPoolServiceRender" },
            { Name = "Loading", Type = "LoadingServiceRender" },
            { Name = "TrapRender", Type = "TrapServiceRender" },
            { Name = "PlaySkillInstruction", Type = "PlaySkillInstructionService" },
            { Name = "PlayAI", Type = "PlayAIService" },
            { Name = "TransformRenderer", Type = "TransformServiceRenderer" },
            { Name = "RenderBattle", Type = "RenderBattleService" },
            { Name = "BoardRender", Type = "BoardServiceRender" },
            { Name = "MonsterMoveRender", Type = "MonsterMoveServiceRender" },
            { Name = "ChainAttackRender", Type = "ChainAttackServiceRender" },
            { Name = "PlayDamage", Type = "PlayDamageService" },
            { Name = "RandomRender", Type = "RandomServiceRender" },
            { Name = "DataListener", Type = "DataListenerServiceRender" },
            { Name = "MonsterCreationRender", Type = "MonsterCreationServiceRender" },
            { Name = "MonsterCreationLogic", Type = "MonsterCreationServiceLogic" },
            
            {
                Name = "L2R",
                Type = "L2RService",
                ClientType = "L2RService",
                ServerType = "L2RService_Server"
            },
            { Name = "Affix", Type = "AffixService" },
            { Name = "SpawnPieceRender", Type = "SpawnPieceServiceRender" },
            { Name = "Cutscene", Type = "CutsceneServiceRender" },

            { Name = "FeatureRender", Type = "FeatureServiceRender" },
            { Name = "FeatureLogic", Type = "FeatureServiceLogic" },
            { Name = "SyncMoveRender", Type = "SyncMoveServiceRender" },
            { Name = "SyncMoveLogic", Type = "SyncMoveServiceLogic" },
            { Name = "RideLogic", Type = "RideServiceLogic" },
            { Name = "RideRender", Type = "RideServiceRender" },
            --多面棋盘
            { Name = "PieceMulti", Type = "PieceMultiServiceRender" },
            { Name = "BoardMultiLogic", Type = "BoardMultiServiceLogic" },
            { Name = "BoardMultiRender", Type = "BoardMultiServiceRender" },
            { Name = "PartnerRender", Type = "PartnerServiceRender" },
            { Name = "PartnerLogic", Type = "PartnerServiceLogic" },
            { Name = "Talent", Type = "TalentService" },
            ---怪物和机关的预览
            { Name = "PreviewMonsterTrap", Type = "PreviewMonsterTrapService" },
            { Name = "MirageLogic", Type = "MirageServiceLogic" },
            { Name = "MirageRender", Type = "MirageServiceRender" },
            { Name = "PreviewLinkLine", Type = "PreviewLinkLineService" },
            --service end
        },
        EditorServices = {
            { Name = "AutoTest", Type = "AutoTestService" },
        }
    },
    [GameModeType.NormalBattleMode] = {
        Systems = {},
        UniqueComponents = {},
        Services = {}
    },
    [GameModeType.MazeBattleMode] = {
        Systems = {},
        UniqueComponents = {},
        Services = {
            { Name = "Battle", Type = "BattleService_Maze" },
            { Name = "LogicEntity", Type = "LogicEntityServiceMaze" },
            { Name = "RenderBattle", Type = "RenderBattleService_Maze" },
            { Name = "CalcDamage", Type = "CalcDamageServiceMaze" },
            { Name = "PlayDamage", Type = "PlayDamageServiceMaze" }
        }
    },
    [GameModeType.ChessBattleMode] = {
        Systems = {
            [2] = {
                { Name = "ChessInput", Type = "ChessInputSystem_Render"},
            },
            [3] = {
                ---战棋的大招点选
                { Name = "PickUpChessGrid",Type = "PickUpChessGridSystem_Render"},
                { Name = "PickUpChessMonster",Type = "PickUpChessMonsterSystem_Render"},
                { Name = "PickUpChessPetState",Type = "PickUpChessPetStateSystem_Render"},
                { Name = "PreviewChessPetState",Type = "PreviewChessPetStateSystem_Render"},
                { Name = "PreviewChessPetState",Type = "PreviewChessPetStateSystem_Render",},
                { Name = "PickUpChessPet",Type = "PickUpChessPetSystem_Render",},
                { Name = "PickUpChessGrid",Type = "PickUpChessGridSystem_Render",},

                ---战棋状态机
                { Name = "ChessPetMove",Type = "ChessPetMoveSystem",ClientType = "ClientChessPetMoveSystem_Render"},
                { Name = "ChessPetMoveAndAttac",Type = "ChessPetMoveAndAttackSystem",
                    ClientType = "ClientChessPetMoveAndAttackSystem_Render",},
                { Name = "ChessPetResult",Type = "ChessPetResultSystem",
                    ClientType = "ClientChessPetResultSystem_Render"},
            },
        },
        UniqueComponents = {
            ChessPickUpComponent = {}
        },
        Services = {
            { Name = "ChessPetCreationLogic", Type = "ChessPetCreationServiceLogic" },
            { Name = "ChessRender", Type = "ChessServiceRender" },
            { Name = "ChessLogic", Type = "ChessServiceLogic" },
        }
    },
    [GameModeType.PopStarMode] = {
        Systems = {
            [2] = {
                { Name = "PopStarInput", Type = "PopStarInputSystem_Render" },
            },
            [3] = {
                ---状态机
                { Name = "PopStarLoading", Type = "PopStarLoadingSystem", ClientType = "PopStarLoadingSystem_Render" },
                { Name = "PopStarBattleEnter", Type = "PopStarBattleEnterSystem", ClientType = "PopStarBattleEnterSystem_Render" },
                { Name = "PopStarWaveEnter", Type = "PopStarWaveEnterSystem", ClientType = "PopStarWaveEnterSystem_Render" },
                { Name = "PopStarRoundEnter", Type = "PopStarRoundEnterSystem", ClientType = "PopStarRoundEnterSystem_Render" },
                { Name = "WaitInput", Type = "PopStarWaitInputSystem", ClientType = "PopStarWaitInputSystem_Render" },
                { Name = "PopStarPieceRefresh", Type = "PopStarPieceRefreshSystem", ClientType = "PopStarPieceRefreshSystem_Render" },
                { Name = "PopStarTrapTurn", Type = "PopStarTrapTurnSystem", ClientType = "PopStarTrapTurnSystem_Render" },
                { Name = "PopStarRoundResult", Type = "PopStarRoundResultSystem", ClientType = "PopStarRoundResultSystem_Render" },
                { Name = "PopStarWaveResult", Type = "PopStarWaveResultSystem", ClientType = "PopStarWaveResultSystem_Render" },
                { Name = "PopStarBattleResult", Type = "PopStarBattleResultSystem", ClientType = "PopStarBattleResultSystem_Render",
                    ServerType = "PopStarBattleResultSystem_Logic" },
            },
        },
        UniqueComponents = {
            PopStarPickUpComponent = {}
        },
        Services = {
            { Name = "PopStarRender", Type = "PopStarServiceRender" },
            { Name = "PopStarLogic",  Type = "PopStarServiceLogic" },
        }
    },
}
