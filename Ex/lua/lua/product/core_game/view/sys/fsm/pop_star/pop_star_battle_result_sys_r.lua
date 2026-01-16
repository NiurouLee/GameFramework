--[[------------------------------------------------------------------------------------------
    PopStarBattleResultSystem_Render：消灭星星客户端实现的战斗结算表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_battle_result_system"

---@class PopStarBattleResultSystem_Render:PopStarBattleResultSystem
_class("PopStarBattleResultSystem_Render", PopStarBattleResultSystem)
PopStarBattleResultSystem_Render = PopStarBattleResultSystem_Render

function PopStarBattleResultSystem_Render:_DoRenderShowExit(TT, victory, defeatType)
    ---胜利相关的buff
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, NTGameOver:New(victory, defeatType))

    ---关闭UIBattle界面点击
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnSetGraphicRaycaster, false)

    if victory == 1 then
        ---@type GuideServiceRender
        local guideService = self._world:GetService("Guide")
        guideService:Trigger(GameEventType.GuideBattleFinish)
        guideService:YieldComplete()
    end

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if victory ~= 0 and not utilData:PlayerIsDead(teamEntity) then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowTransitionEffect)
        YIELD(TT, 1000)
    end

    --还原在battle enter调用的SpawnPieceServiceRender:_OnClipBoard 里设置的裁切棋盘参数
    UnityEngine.Shader.DisableKeyword("_CELL_CLIP")
end

function PopStarBattleResultSystem_Render:_DoRenderBattleResult()
    ---@type RenderBattleService
    local battleSvcRender = self._world:GetService("RenderBattle")
    battleSvcRender:NotifyUIBattleGameOver(self.battleMatchResult)
end
