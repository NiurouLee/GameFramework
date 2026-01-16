--[[------------------------------------------------------------------------------------------
    PopStarWaveResultSystem_Render：消灭星星客户端实现波次结算的表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_wave_result_system"

---@class PopStarWaveResultSystem_Render:PopStarWaveResultSystem
_class("PopStarWaveResultSystem_Render", PopStarWaveResultSystem)
PopStarWaveResultSystem_Render = PopStarWaveResultSystem_Render

function PopStarWaveResultSystem_Render:_DoRenderNotifyWaveEnd(TT, waveNum)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTWaveTurnEnd:New(waveNum))
end

function PopStarWaveResultSystem_Render:_DoRenderHandleTurnBattleResult(TT, victory)
    GameGlobal.UAReportForceGuideEvent("BattleResult", { victory and 1 or 0 }, false, true)
end
