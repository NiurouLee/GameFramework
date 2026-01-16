--[[------------------------------------------------------------------------------------------
    ClientWaveResultAwardApplySystem_Render：客户端
]] --------------------------------------------------------------------------------------------

require "wave_result_award_apply_system"

---@class ClientWaveResultAwardApplySystem_Render:WaveResultAwardApplySystem
_class("ClientWaveResultAwardApplySystem_Render", WaveResultAwardApplySystem)
ClientWaveResultAwardApplySystem_Render = ClientWaveResultAwardApplySystem_Render

function ClientWaveResultAwardApplySystem_Render:_DoRenderApplyRelic(TT, applyRelicID, relicBuffs, switchState)
    Log.debug("[MiniMaze] _DoRenderApplyRelic applyRelicID: ",applyRelicID)

    local data = DataAddRelicResult:New(applyRelicID, relicBuffs, switchState)
    ---@type PlayBuffService
    local svc = self._world:GetService("PlayBuff")
    svc:PlayBuffSeqs(TT, data:GetBuffSeqList())
    -- local state = data:GetSwitchState()
    -- if state == WaveResultAwardNextStateType.WaveSwitch then
    --     self._world:EventDispatcher():Dispatch(GameEventType.WaveResultAwardFinish, 1)
    -- elseif state == WaveResultAwardNextStateType.WaitInput then
    --     self._world:EventDispatcher():Dispatch(GameEventType.WaveResultAwardFinish, 2)
    -- end
end

function ClientWaveResultAwardApplySystem_Render:_DoRenderAddPartner(TT,applyPartnerID,petInfo,matchPet,petRes,hp,maxHP )
    Log.debug("[MiniMaze] _DoRenderApplyRelic _DoRenderAddPartner: ",applyPartnerID)
    ---@type PartnerServiceRender
    local renderPartnerService = self._world:GetService("PartnerRender")
    local data = DataAddPartnerResult:New(applyPartnerID,petInfo,matchPet,petRes,hp,maxHP)
    renderPartnerService:AddPartnerRender(TT,data)
end
