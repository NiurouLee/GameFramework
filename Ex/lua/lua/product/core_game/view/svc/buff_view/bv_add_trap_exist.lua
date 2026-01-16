--[[
    播放增加機關存在時長
]]
_class("BuffViewAddTrapExist", BuffViewBase)
BuffViewAddTrapExist = BuffViewAddTrapExist



function BuffViewAddTrapExist:PlayView(TT, notify)
    ---@type BuffResultAddTrapExist
    local result = self._buffResult
    ---@type TrapServiceRender
    local trapRenderSvc = self._world:GetService("TrapRender")
    ---@type  Entity
    local entity = self._entity
    local isForceFull = result:IsForceFull()
    trapRenderSvc:UpdateTrapExistShow(entity,isForceFull)
    local ignoreNextEffectUpdate = result:IgnoreNextEffectUpdate()
    if ignoreNextEffectUpdate then
        --重置数字特效后 进入怪物行动阶段会再次刷新，此时curRound是0，数字显示不对，屏蔽掉这次修改
        local roundRenderCmpt = entity:TrapRoundInfoRender()
        if roundRenderCmpt then
            roundRenderCmpt:SetEffectID(nil)
        end
    end

    if result:IsDestroy() then
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        trapServiceRender:PlayTrapDieSkill(TT, {entity})
    end
end