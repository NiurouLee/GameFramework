---@class UIRugueLikeDefeatedController:UIController
_class("UIRugueLikeDefeatedController", UIController)
UIRugueLikeDefeatedController = UIRugueLikeDefeatedController

function UIRugueLikeDefeatedController:OnShow(uiParam)
    local show_save = uiParam[1]
    if show_save then
        --弹框是否存档
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel,
            "",
            StringTable.Get("str_maze_sava_archieve_or_not"),
            function(param)
                self:SaveBattleArchive(true)
                GameGlobal.UIStateManager():Lock("SaveBattleArchive")
            end,
            nil,
            function(param)
                self:SaveBattleArchive(false)
            end,
            nil
        )
    else
        self:SaveBattleArchive(false)
    end

    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)

    --再次挑战按钮
    local againFightBtn = self:GetGameObject("againFightBtn")
    local againActive = HelperProxy:GetInstance():AgainFightActive(MatchType.MT_Maze, false)
    againFightBtn:SetActive(againActive)

    self:AttachEvent(
        GameEventType.MazeInfoUpdate,
        function()
            GameGlobal.UIStateManager():UnLock("SaveBattleArchive")
        end
    )
end

function UIRugueLikeDefeatedController:OnHide()
    GameGlobal.UIStateManager():UnLock("SaveBattleArchive")
end

function UIRugueLikeDefeatedController:bgOnClick()
    GameGlobal:GetInstance():ExitCoreGame()
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
end
--再次挑战
function UIRugueLikeDefeatedController:againFightBtnOnClick()
    --编队
    ---@type TeamsContext
    local ctx = self:GetModule(MissionModule):TeamCtx()
    local teamInfo = self:GetModule(MazeModule):GetFormationInfo()
    ctx:InitMazeTeam(teamInfo)

    GameGlobal:GetInstance():ExitCoreGame() --退局处理
    local ctx = self:GetModule(MissionModule):TeamCtx()
    ctx:SetFightAgain(true) --设置再次挑战
    ctx:ShowDialogUITeams(true) --直接打开编队界面（状态UI）
end

function UIRugueLikeDefeatedController:SaveBattleArchive(save)
    local md = GameGlobal.GetModule(MatchModule)
    local result = md:GetMatchResult()
    result.maze_result[1].save_archive = save
    md:GameOver(result)
end
---客户端自动测试密境局内专用关闭函数
function UIRugueLikeDefeatedController:bgOnClick_MazeTest()
    GameGlobal:GetInstance():ExitCoreGame()
    self:CloseDialog()
end
