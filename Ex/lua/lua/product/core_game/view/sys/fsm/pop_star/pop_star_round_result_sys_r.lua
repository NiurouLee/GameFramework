--[[------------------------------------------------------------------------------------------
    PopStarRoundResultSystem_Render：消灭星星客户端实现的回合结算表现
]]
--------------------------------------------------------------------------------------------

require "pop_star_round_result_system"

---@class PopStarRoundResultSystem_Render:PopStarRoundResultSystem
_class("PopStarRoundResultSystem_Render", PopStarRoundResultSystem)
PopStarRoundResultSystem_Render = PopStarRoundResultSystem_Render

function PopStarRoundResultSystem_Render:_DoRenderTrapAction(TT)
    ---@type PlayAIService
    local playAISvc = self._world:GetService("PlayAI")
    if playAISvc == nil then
        return
    end

    playAISvc:DoCommonRountine(TT)
end

function PopStarRoundResultSystem_Render:_DoRenderTrapState(TT, traps)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    trapServiceRender:RenderTrapState(TT, TrapDestroyType.DestroyAtRoundResult, traps)
end

function PopStarRoundResultSystem_Render:_DoRenderNotifyRoundTurnEnd(TT, teamEntity)
    local svc = self._world:GetService("PlayBuff")
    svc:PlayBuffView(TT, NTRoundTurnEnd:New(teamEntity))
end

function PopStarRoundResultSystem_Render:_DoRenderShowRoundEnd(TT, isBattleEnd)
    ---@type UtilDataServiceShare
    local utilStatSvc = self._world:GetService("UtilData")
    local l_role_module = GameGlobal.GetModule(RoleModule)
    -- 已过了UA打点上报强引导关卡 就不要上报了
    -- 由于以下判断存在较多的字符串操作会影响局内性能 同时 局内不能使用CheckModuleUnlock判断是否进行如下操作 故 写在这里
    if not l_role_module:CheckModuleUnlock(GameModuleID.MD_ForceGuideEnd) then
        local attrGroup = self._world:GetGroup(self._world.BW_WEMatchers.Attributes)
        local l_strTemp = ""
        for i, e in ipairs(attrGroup:GetEntities()) do
            local l_ePetMonster = nil
            local l_templateId = 0
            if e:HasMonsterID() then
                l_ePetMonster = "monster"
                l_templateId = e:MonsterID():GetMonsterID()
            elseif e:HasTeam() then
                l_ePetMonster = "team"
                l_templateId = 0
            end

            if l_ePetMonster ~= nil then
                local val = utilStatSvc:GetCurrentLogicHP(e)
                if val then
                    l_strTemp = l_strTemp .. "{" .. l_ePetMonster .. ": " .. l_templateId .. " , hp: " .. val .. "},"
                end
            end
        end
        local curRound = utilStatSvc:GetStatCurWaveRoundNum()
        
        GameGlobal.UAReportForceGuideEvent(
            "FightRoundInfo",
            {
                curRound,
                l_strTemp
            },
            false,
            true
        )
    end
end
