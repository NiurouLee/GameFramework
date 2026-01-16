_class("BuffViewAddHPMax", BuffViewBase)
---@class BuffViewAddHPMax:BuffViewBase
BuffViewAddHPMax = BuffViewAddHPMax
function BuffViewAddHPMax:PlayView(TT)
    if self:ViewParams() then 
        ---这个地方是为了解决重复扣血的问题
        ---比如配了个怪物出生时降低最大血量的buff，使用了NTMonsterShow的通知
        ---怪物出生表现时，会使用逻辑血量设置自己的表现血量，但这个逻辑血量已经包含了
        ---buff修改的值，然后当表现通知时，再次修改了表现血量。
        ---正确做法应该是怪物出生时有分阶段的逻辑血量结果，这样怪物可以先设置原来的血量
        ---当buff触发时，再次修改表现血量
        ---现在的做法因为要发版本，临时做个标记，不播放buff的表现，就不会多扣表现血量
        local skipView = self:ViewParams().SkipView
        if skipView == 1 then
            return
        end
    end

    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    ---@type BuffResultAddHPMax
    local result = self._buffResult
    local damageInfo = result:GetDamageInfo()
    local entityID = result:GetEntityID()
    local ret = result:GetMaxHPResult()

    for k, v in pairs(ret) do
        ---@type Entity
        local e = self._world:GetEntityByID(k)
        e:ReplaceMaxHP(v)
    end

    local entityWork = self._world:GetEntityByID(entityID)
    --圣钉不回血
    if result:GetNotAddHP() == 1 then
        playDamageSvc:_RefreshTeamHP(TT, entityWork, damageInfo)
        return
    end
    --血条刷新
    playDamageSvc:UpdateTargetHPBar(TT, entityWork, damageInfo)
    --伤害飘字
    if result:GetDisplayDamage() == 1 then
        playDamageSvc:DisplayDamage(TT, entityWork, damageInfo)
    end
end
