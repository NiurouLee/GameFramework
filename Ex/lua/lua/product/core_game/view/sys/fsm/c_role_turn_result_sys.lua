--[[------------------------------------------------------------------------------------------
    ClientRoleTurnResultSystem_Render ： 客户端实现普攻结算表现阶段
]] --------------------------------------------------------------------------------------------

require "role_turn_result_state_system"

---@class ClientRoleTurnResultSystem_Render:RoleTurnResultStateSystem
_class("ClientRoleTurnResultSystem_Render", RoleTurnResultStateSystem)
ClientRoleTurnResultSystem_Render = ClientRoleTurnResultSystem_Render
function ClientRoleTurnResultSystem_Render:_DoRenderPlayNotify(TT)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTRoleTurnResultState:New())
end
function ClientRoleTurnResultSystem_Render:_DoRenderNormalAttackMonsterDead(TT)
    ---@type MonsterShowRenderService
    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
    ---此函数将表现所有挂了deadflag标记的怪物
    sMonsterShowRender:DoAllMonsterDeadRender(TT, false)
end

function ClientRoleTurnResultSystem_Render:_DoRenderGuideSkill(TT)
    local guideService = self._world:GetService("Guide")
    local guideTaskId = guideService:Trigger(GameEventType.GuidePlayerSkillFinish, GuidePlayerHandle.LinkEnd)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId,true) do
        YIELD(TT)
    end
end

function ClientRoleTurnResultSystem_Render:_DoRenderGuideSkillReal(TT)
    local guideService = self._world:GetService("Guide")
    local guideTaskId = guideService:Trigger(GameEventType.GuidePlayerSkillRealFinish, GuidePlayerHandle.LinkEnd)
    while not TaskHelper:GetInstance():IsTaskFinished(guideTaskId,true) do
        YIELD(TT)
    end
end

function ClientRoleTurnResultSystem_Render:_DoRenderWaitDeathEnd(TT)
    while self:_CheckShowDeathNotEnd() do
        YIELD(TT)
    end
end

---检查死亡动画是否播放完
function ClientRoleTurnResultSystem_Render:_CheckShowDeathNotEnd()
    ---@type Group
    local deathGroup = self._world:GetGroup(self._world.BW_WEMatchers.ShowDeath)
    for _, v in ipairs(deathGroup:GetEntities()) do
        ---@type Entity
        local entity = v
        ---@type ShowDeathComponent
        local showDeathCmpt = entity:ShowDeath()
        if not showDeathCmpt:IsShowDeathEnd() then
            return true
        end
    end

    return false
end

function ClientRoleTurnResultSystem_Render:_WaitBeHitSkillFinish(TT)
    --普攻致死的怪物，在播放死亡动画后，过1帧才能播放到设置等待的指令。所以这里等了2帧
    YIELD(TT)
    YIELD(TT)
    local count = 0
    local previewEntity = self._world:GetPreviewEntity()
    ---@type RenderStateComponent
    local renderState = previewEntity:RenderState()
    if renderState and renderState:GetRenderStateType() == RenderStateType.WaitPlayTask then
        local taskID = renderState:GetRenderStateParam()

        if taskID then
            while not TaskHelper:GetInstance():IsTaskFinished(taskID) do
                YIELD(TT)
                count = count + 1
            end
        else
            while renderState:GetRenderStateType() == RenderStateType.WaitPlayTask do
                YIELD(TT)
                count = count + 1
            end
        end

        --previewEntity:RemoveRenderState()
    end

    if count ~= 0 then
        Log.warn("HPLock Wait Count:", count)
    end
end
