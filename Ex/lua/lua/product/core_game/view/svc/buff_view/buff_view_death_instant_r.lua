_class("BuffViewDeathInstant", BuffViewBase)
BuffViewDeathInstant = BuffViewDeathInstant

function BuffViewDeathInstant:PlayView(TT)
    ---@type Entity
    local entity = self._entity
    ---@type BuffResultDeathInstant
    local result = self._buffResult
    local hasDead = result:GetIsDead()
    if hasDead then
        entity:AddDeadFlag()
        --如果是BOSS 刷新BOSS大血条
        local hasBoss = entity:HasBoss()
        ---@type BuffViewComponent
        local buffCmpt = entity:BuffView()
        --身上有buff标志 自己显示在BOSS血条（映镜的墙壁）
        local curShowBossHP = buffCmpt and buffCmpt:HasBuffEffect(BuffEffectType.CurShowBossHP)
        if hasBoss or curShowBossHP then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, entity:GetID(), 0, 0, 1)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, entity:GetID(), 0, 0, 1)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossShield, entity:GetID(), 0)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossGreyHP, entity:GetID(), 0, 1)
        end

        --特效
        local targetEffectID = self:BuffViewInstance():BuffConfigData():GetExecEffectID()
        if targetEffectID then
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            local effectEntity = effectService:CreateEffect(targetEffectID, entity)
            YIELD(TT, 1000)
        end
	    --执行一次通用死亡逻辑
	    ---@type MonsterShowRenderService
	    local sMonsterShowRender = self._world:GetService("MonsterShowRender")
	    sMonsterShowRender:_DoOneMonsterDead(TT, entity)
    end
end

function BuffViewDeathInstant:IsNotifyMatch(notify)
    if self._buffResult:GetCasterID() == notify:GetNotifyEntity():GetID() then
        return true
    end

    return false
end
