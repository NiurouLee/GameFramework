--[[------------------------------------------------------------------------------------------
    ClientLoadingSystem_Render：客户端实现主状态的进度条阶段
]] --------------------------------------------------------------------------------------------

require("loading_system")

_class("ClientLoadingSystem_Render", LoadingSystem)
---@class ClientLoadingSystem_Render : LoadingSystem
ClientLoadingSystem_Render = ClientLoadingSystem_Render

---此处卡住流程，每帧检查本地是否收到服务端下发的开始对局状态
---该消息的通知流程是 Server---->MatchModule----->EventListenerRender---->Component
function ClientLoadingSystem_Render:_DoRenderMatchStart(TT)
    ---@type BattleRenderConfigComponent
    local battleRenderConfigCmpt = self.world:BattleRenderConfig()
    while not battleRenderConfigCmpt:IsMatchStart() do
        YIELD(TT)
    end
end

function ClientLoadingSystem_Render:_DoRenderLoading(TT)
    local loadingService = self._world:GetService("Loading")
    return GameGlobal.TaskManager():CoreGameStartTask(loadingService.MockLoading, loadingService)
end

function ClientLoadingSystem_Render:_DoRenderCreateRenderBoard()
    ---@type RenderEntityService
    local resvc = self._world:GetService("RenderEntity")
    resvc:CreateRenderBoardEntity()
end

function ClientLoadingSystem_Render:_DoRenderPreloadCfg()
    local bEnable = true
    if EDITOR and bEnable then
        ---@type TestRobotModule
        local testRobot = GameGlobal.GetModule(TestRobotModule)
        local isRunAutoTest = testRobot:GetIsEnableRobot()
        if not isRunAutoTest then
            return
        end

        -- 单机环境对局过程中，可能会出现IO问题，所以提前加载这个文件
        local board_guide = Cfg.cfg_board_guide()
        local trap = Cfg.cfg_trap()
        local ai = Cfg.cfg_ai()
        local passive_skill = Cfg.cfg_passive_skill()
    end
end
