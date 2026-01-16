--[[------------------------------------------------------------------------------------------
    WaitInputChainSystem ：等待玩家输入，连锁技前
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class WaitInputChainSystem:MainStateSystem
_class("WaitInputChainSystem", MainStateSystem)
WaitInputChainSystem = WaitInputChainSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function WaitInputChainSystem:_GetMainStateID()
    return GameStateID.WaitInputChain
end

---@param TT token 协程识别码，服务端环境下是nil
function WaitInputChainSystem:_OnMainStateEnter(TT)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    
    self:_DoRenderPieceAnimation(TT) ---重置格子动画

    self:_DoLogicEnalbeInput()

    self:_ShowUI(TT) --显示UI
    self:_PlayPreview(TT, teamEntity)
    self:_RemoveDimensionFlag(teamEntity)

    ---这个地方会打开点选标记
    self:_DoRenderBeforePickUp()

    self:_DoGotoPickupTarget()
end

function WaitInputChainSystem:_RemoveDimensionFlag(teamEntity)
    teamEntity:RemoveDimensionFlag()
end

function WaitInputChainSystem:_DoGotoPickupTarget()
    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputChainFinish, 1)
end

function WaitInputChainSystem:_DoLogicEnalbeInput()
    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    local gameFsmStateID = gameFsmCmpt:CurStateID()
    if gameFsmStateID == GameStateID.WaitInputChain then
        gameFsmCmpt:EnableHandleInput(true)
    end    
end
----------------------------------表现接口-----------------------------------

function WaitInputChainSystem:_DoRenderPieceAnimation(TT)
end

function WaitInputChainSystem:_DoEnableInput(TT)
end

function WaitInputChainSystem:_ShowUI(TT)
end

function WaitInputChainSystem:_PlayPreview(TT)
end

function WaitInputChainSystem:_DoRenderBeforePickUp()
end