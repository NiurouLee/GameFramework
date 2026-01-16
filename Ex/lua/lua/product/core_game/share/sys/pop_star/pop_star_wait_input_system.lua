--[[------------------------------------------------------------------------------------------
    WaitInputSystem：等待玩家输入
]]
--------------------------------------------------------------------------------------------

require "main_state_sys"

---@class PopStarWaitInputSystem:MainStateSystem
_class("PopStarWaitInputSystem", MainStateSystem)
PopStarWaitInputSystem = PopStarWaitInputSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarWaitInputSystem:_GetMainStateID()
    return GameStateID.WaitInput
end

---@param TT token 协程识别码，服务端环境下是nil
function PopStarWaitInputSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---消灭星星隐藏光灵
    self:_DoRenderHidePetEntity(TT, teamEntity)

    ---计算三星进度
    self:_DoLogicCalc3StarProgress()

    ---计算三星奖励
    self:_DoLogicCalcBonusObjective()

    ---重置一些战斗状态
    self:_DoLogicRestBattleState()

    ---重置格子动画
    self:_DoRenderPieceAnimation(TT)

    --触发buff
    self:_DoLogicWaitInputBuff()
    self:_DoRenderPlayWaitInputBuff(TT)

    ---直接显示玩家头像列表
    self:_DoRenderShowPetHeadUI(TT)

    ---先等待所有动画结束
    self:_DoRenderWaitDeathEnd(TT)

    ---处理进入玩家回合后的表现
    self:_DoRenderShowPlayerTurnInfo(TT, teamEntity)

    --逻辑表现棋盘数据同步
    self:_DoL2RBoardLogicData()

    --比对逻辑血量和表现血量
    self:_DoRenderCompareHPLog(TT)

    --对比格子类型数据
    self:_DoRenderComparePieceType(TT)

    --设置预览队伍
    self:_DoRenderSetPreviewTeam(teamEntity)

    self:_DoLogicUpdateMatchData(teamEntity)

    self:_DoLogicEnableHandleInput()
end

function PopStarWaitInputSystem:_DoLogicCalc3StarProgress()
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    popStarSvc:Calculate3StarProgress()
end

function PopStarWaitInputSystem:_DoLogicCalcBonusObjective()
    ---@type BonusCalcService
    local bonusService = self._world:GetService("BonusCalc")
    bonusService:CalcBonusObjective()
end

function PopStarWaitInputSystem:_DoLogicRestBattleState()
    --计数（用于调试，客户端和服务器不一样）
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:IncWaitInputCount()
end

function PopStarWaitInputSystem:_DoLogicWaitInputBuff()
    self._world:GetService("Trigger"):Notify(NTWaitInput:New())
end

function PopStarWaitInputSystem:_DoL2RBoardLogicData()
    --更新逻辑数据
    local t = self._world:GetService("BoardLogic"):CalcPieceEntities()
    self._world:GetBoardEntity():Board():SetPieceEntities(t)

    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

function PopStarWaitInputSystem:_DoLogicUpdateMatchData(teamEntity)
    if self._world:RunAtServer() then
        ---@type CoreGameLogic
        local logic = self._world:GetCoreGameLogic()
        if logic:IsRunningAI() then
            local actorID = logic:GetActorID()
            local data = logic:GetAIData()
            update_match_state(actorID, data)

            --测试一下，原地双击
            ---@type BattleStatComponent
            local battleStatCmpt = self._world:BattleStat()
            local cmd = MovePathDoneCommand:New()
            cmd:SetChainPath({ teamEntity:GetGridPosition() })
            cmd:SetElementType(0)
            cmd.EntityID = 2
            cmd.RoundCount = battleStatCmpt:GetGameRoundCount()
            cmd.IsAutoFight = battleStatCmpt:GetAutoFight()
            cmd.ClientWaitInput = battleStatCmpt:GetWaitInputCount()
            logic:DoAICommand(cmd)
        end
    end
end

--允许输入
function PopStarWaitInputSystem:_DoLogicEnableHandleInput()
    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    gameFsmCmpt:EnableHandleInput(true)
    self._world:GetDataLogger():AddDataLog("OnShowEnd")
end

----------------------------------表现接口-----------------------------------

function PopStarWaitInputSystem:_DoRenderHidePetEntity(TT, teamEntity)
end

function PopStarWaitInputSystem:_DoRenderPieceAnimation(TT)
end

function PopStarWaitInputSystem:_DoRenderPlayWaitInputBuff(TT)
end

function PopStarWaitInputSystem:_DoRenderShowPetHeadUI(TT)
end

function PopStarWaitInputSystem:_DoRenderShowPlayerTurnInfo(TT, teamEntity)
end

function PopStarWaitInputSystem:_DoRenderCompareHPLog(TT)
end

function PopStarWaitInputSystem:_DoRenderComparePieceType(TT)
end

function PopStarWaitInputSystem:_DoRenderSetPreviewTeam(teamEntity)
end
