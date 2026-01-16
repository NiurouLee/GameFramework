--[[------------------------------------------------------------------------------------------
    玩家命令分发
]] --------------------------------------------------------------------------------------------

---@class PlayerCommandHandler
_class("PlayerCommandHandler", Object)

function PlayerCommandHandler:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._cmds = {}
    self._handledCmdStates = {}

    ---连线命令处理器
    ---@type MovePathDownCommandHandler
    self._movePathDownCmdHandler = MovePathDownCommandHandler:New(world)

    ---即时释放型主动技命令处理器
    ---@type CastActiveSkillCommandHandler
    self._castActiveSkillCmdHandler = CastActiveSkillCommandHandler:New(world)

    ---点选型主动技命令处理器
    ---@type CastPickUpSkillCommandHandler
    self._castPickUpSkillCmdHandler = CastPickUpSkillCommandHandler:New(world)

    --切换队长
    ---@type ChangeTeamLeaderCommandHandler
    self._changeTeamLeaderCmdHandler = ChangeTeamLeaderCommandHandler:New(world)

    --取消点选命令处理器
    ---@type CancelChainSkillCommandHandler
    self._cancelChainSkillCmdHandler = CancelChainSkillCommandHandler:New(world)

    --点选型连锁技命令处理器
    ---@type CastPickUpChainSkillCommandHandler
    self._castPickUpChainSkillCmdHandler = CastPickUpChainSkillCommandHandler:New(world)

    ---@type CastSelectTeamOrderPositionCommandHandler
    self._castSelectTeamOrderPositionCommandHandler = CastSelectTeamOrderPositionCommandHandler:New(world)

    ---@type CastClearSelectedTeamOrderPositionCommandHandler
    self._castClearSelectedTeamOrderPosCmdHandler = CastClearSelectedTeamOrderPositionCommandHandler:New(world)

    --------------------------------战棋------------------------------------------------
    ---结束回合
    self._chessEndTurnHandler = CastChessPetEndTurnCommandHandler:New(world)

    ---移动
    self._castChessMoveCommandHandler = CastChessMoveCommandHandler:New(world)

    ---移动攻击
    ---@type CastClearSelectedTeamOrderPositionCommandHandler
    self._castChessPetAttackCommandHandler = CastChessPetAttackCommandHandler:New(world)
    --小秘境 选波次奖励
    ---@type ChooseMiniMazeWaveAwardCommandHandler
    self._chooseMiniMazeWaveAwardCommandHandler = ChooseMiniMazeWaveAwardCommandHandler:New(world)

    ---幻境点选
    ---@type MiragePickUpCommandHandler
    self._miragePickUpCommandHandler = MiragePickUpCommandHandler:New(world)
    ---幻境强制结束
    ---@type MirageForceCloseCommandHandler
    self._mirageForceCloseCommandHandler = MirageForceCloseCommandHandler:New(world)

    --装备精炼局内UI开关
    ---@type SwitchPetEquipRefineUICommandHandler
    self._switchPetEquipRefineUICommandHandler = SwitchPetEquipRefineUICommandHandler:New(world)

    --消灭星星点选
    ---@type PopStarPickUpCommandHandler
    self._popStarPickUpCommandHandler = PopStarPickUpCommandHandler:New(world)

    -- scan feature command handler
    -- https://wiki.h3d.com.cn/pages/viewpage.action?pageId=77138576
    ---@type ScanFeatureCommandHandler
    self._scanFeatureCommandHandler = ScanFeatureCommandHandler:New(world)
end

function PlayerCommandHandler:AddCommand(cmd)
    table.insert(self._cmds, cmd)
end

--清理当前状态执行的命令状态，当前状态结束不清理，下个状态清理
--因为waitinput状态会执行本状态累积的消息，和新收到的消息
function PlayerCommandHandler:ClearHandlerState()
    self._handledCmdStates = {}
end

--[[
    命令处理有3个约束：1.回合计数 2.执行状态 3.同类互斥
]]
function PlayerCommandHandler:HandleCommand()
    local hasPreview = self._world:RunAtClient() and self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn
    --本地回合数
    local localRoundCount = self._world:BattleStat():GetGameRoundCount()
    while self._cmds[1] do
        local cmd = self._cmds[1]
        local execStateList = {}
        local st = cmd:GetExecStateID(hasPreview)
        if type(st) == "number" then
            table.insert(execStateList, st)
        elseif type(st) == "table" then
            table.appendArray(execStateList, st)
        end
        local exclude = cmd:IsExecExcluded()
        local cmdType = cmd:GetCommandType()
        local roundCount = cmd.RoundCount
        --比较本地和远程回合计数【服务器自动战斗没有计数】
        if cmd:DependRoundCount() and roundCount and roundCount ~= localRoundCount then
            Log.error(
                "[HandleCommand] ",
                cmdType,
                " command roundCnt=",
                roundCount,
                " local roundCnt=",
                localRoundCount
            )
            if roundCount < localRoundCount then
                table.remove(self._cmds, 1)
                goto _CONTINUE_
            else
                break
            end
        end

        --执行状态判断
        local curState = self._world:GameFSM():CurStateID()
        if table.icontains(execStateList, 0) or table.icontains(execStateList, curState) then
            --同类型命令如果互斥执行【防止消息堆积导致重复处理】
            if exclude == 1 then
                --Log.debug('[HandleCommand] ', cmdType, 'st=',st, " exclude=1 handled=",self._handledCmdStates[st])
                if self._handledCmdStates[st] then
                    Log.error("[HandleCommand] ", cmdType, " exec excluded!!")
                    break
                end
                self._handledCmdStates[st] = true
            end
            self:_DoHandleCommand(cmd)
            table.remove(self._cmds, 1)
        else
            break
        end
        ::_CONTINUE_::
    end
end

function PlayerCommandHandler:_DoHandleCommand(cmd)
    --Log.debug("DoHandleCommand ", cmd:GetCommandType())
    if cmd:GetCommandType() ~= "BattleSync"
        and cmd:GetCommandType() ~= "AutoFight"
        and cmd:GetCommandType() ~= "Guide"
        and cmd:GetCommandType() ~= "ClientExceptionReport"
    then
        self._world:GetSyncLogger():Trace({ key = "HandleCommand", cmd = cmd:GetCommandType() })
    end

    if (cmd:GetCommandType() == "MovePathDone") then
        self._movePathDownCmdHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "CastActiveSkill") then
        self._castActiveSkillCmdHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "CastPickUpActiveSkill") then
        self._castPickUpSkillCmdHandler:DoHandleCommand(cmd)
    end

    if cmd:GetCommandType() == "CancelChainSkill" then
        self._cancelChainSkillCmdHandler:DoHandleCommand(cmd)
    end
    if cmd:GetCommandType() == "CastPickUpChainSkill" then
        self._castPickUpChainSkillCmdHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "BattleSync") then
        self:HandleBattleSync(cmd)
    end

    if (cmd:GetCommandType() == "AutoFight") then
        self:HandleAutoFight(cmd)
    end

    if (cmd:GetCommandType() == "Guide") then
        self:HandleGuide(cmd)
    end

    if (cmd:GetCommandType() == "GM") then
        self:HandleGM(cmd)
    end

    if (cmd:GetCommandType() == "ChangeTeamLeader") then
        self._changeTeamLeaderCmdHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "ClientExceptionReport") then
        self:HandleClientExceptionReport(cmd)
    end

    if (cmd:GetCommandType() == CastSelectTeamOrderPositionCommand.CommandType) then
        self._castSelectTeamOrderPositionCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == CastClearSelectedTeamOrderPositionCommand.CommandType) then
        self._castClearSelectedTeamOrderPosCmdHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "CastChessPetEndTurn") then
        self._chessEndTurnHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "CastChessMove") then
        self._castChessMoveCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == "CastChessPetAttack") then
        self._castChessPetAttackCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == ChooseMiniMazeWaveAwardCommand.CommandType) then
        self._chooseMiniMazeWaveAwardCommandHandler:DoHandleCommand(cmd)
    end
    if (cmd:GetCommandType() == ScanFeatureCommand.CommandType) then
        self._scanFeatureCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == MiragePickUpCommand.CommandType) then
        self._miragePickUpCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == MirageForceCloseCommand.CommandType) then
        self._mirageForceCloseCommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == SwitchPetEquipRefineUICommand.CommandType) then
        self._switchPetEquipRefineUICommandHandler:DoHandleCommand(cmd)
    end

    if (cmd:GetCommandType() == PopStarPickUpCommand.CommandType) then
        self._popStarPickUpCommandHandler:DoHandleCommand(cmd)
    end

    return false
end

---@param cmd BattleSyncCommand
function PlayerCommandHandler:HandleBattleSync(cmd)
    local syncService = self._world:GetService("SyncLogic")
    syncService:OnRecvSyncCommand(cmd)
end

---@param cmd AutoFightCommand
function PlayerCommandHandler:HandleAutoFight(cmd)
    local enableAutoFight = cmd:GetCmdAutoFight()

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:SetAutoFight(enableAutoFight)
end

---@param cmd GuideCommand
function PlayerCommandHandler:HandleGuide(cmd)
    local targetPstId = cmd:GetPetPstId()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local petList = teamEntity:Team():GetTeamPetEntities()
    local skillTriggerType = SkillTriggerType.Energy
    for _, e in ipairs(petList) do
        ---@type PetPstIDComponent
        local petPstIDCmpt = e:PetPstID()
        local pstID = petPstIDCmpt:GetPstID()
        if pstID == targetPstId then
            local activeSkillID = e:SkillInfo():GetActiveSkillID()
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(activeSkillID)
            if skillConfigData then
                skillTriggerType = skillConfigData:GetSkillTriggerType()
            end
            ---@type AttributesComponent
            local attributeCmpt = e:Attributes()
            if skillTriggerType ~= SkillTriggerType.LegendEnergy then
                attributeCmpt:Modify("Power", 0)
            end
            attributeCmpt:Modify("Ready", 1)
        end
    end
    if skillTriggerType ~= SkillTriggerType.LegendEnergy then
        self._world:EventDispatcher():Dispatch(GameEventType.PetPowerChange, targetPstId, 0, true)
    end
    self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, targetPstId, true)
end

---@param cmd GMCommand
function PlayerCommandHandler:HandleGM(cmd)
    local funcName = cmd:GetFuncName()
    local funcParam = cmd:GetFuncParam()
    self._world:HandleGM(funcName, funcParam)
end

---@param cmd ClientExceptionReportCommand
function PlayerCommandHandler:HandleClientExceptionReport(cmd)
    --只是要打印出来，没啥能处理的
end
