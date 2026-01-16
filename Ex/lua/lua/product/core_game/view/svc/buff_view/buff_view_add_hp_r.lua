--[[
    加血效果
]]
_class("BuffViewAddHP", BuffViewBase)
---@class BuffViewAddHP:BuffViewBase
BuffViewAddHP = BuffViewAddHP

function BuffViewAddHP:Constructor()
end

---@param notify INotifyBase
function BuffViewAddHP:IsNotifyMatch(notify)
    if notify then
        if notify:GetNotifyType() == NotifyType.MonsterBeHit then
            ---@type NotifyAttackBase
            local n = notify

            if self._buffResult:GetMatchPass() then
                return true
            end

            return ((self._buffResult:GetNotifyAttackerPos() == n:GetAttackPos()) and
                (self._buffResult:GetNotifyDefenderPos() == n:GetTargetPos()) and
                (self._buffResult:GetNotifyAttackerID() == n:GetAttackerEntity():GetID()) and
                (self._buffResult:GetNotifyDefenderID() == n:GetDefenderEntity():GetID()))
        end
        if notify:GetNotifyType() == NotifyType.TeamEachMoveEnd then
            local notifyPos = notify:GetPos()
            local notifyEntityID = notify:GetEntityID()
            return self._buffResult:GetNotifyPos() == notifyPos and notifyEntityID == self._buffResult:GetNotifyEntityID()
        end
        if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd or notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart then
            local notifyPos = notify:GetPos()
            local notifyEntityID = notify:GetEntityID()
            return self._buffResult:GetNotifyPos() == notifyPos and notifyEntityID == self._buffResult:GetNotifyEntityID()
        end
        if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
            local notifyPos = notify:GetWalkPos()
            local notifyEntityID = notify:GetNotifyEntity():GetID()
            return self._buffResult:GetNotifyPos() == notifyPos and notifyEntityID == self._buffResult:GetNotifyEntityID()
        end
        if notify:GetNotifyType() == NotifyType.MonsterDead then
            local monsterEntity = notify:GetNotifyEntity()
            if monsterEntity then
                local monsterEntityID = monsterEntity:GetID()
                local resultEntityID = self._buffResult:GetNotifyEntityID() or 0
                return monsterEntityID == resultEntityID
            end
        end
    end

    return true
end

function BuffViewAddHP:PlayView(TT)
    ---@type  Entity
    local entity = self._entity
    ---@type DamageInfo
    local damageInfo = self._buffResult:GetDamageInfo()

    YIELD(TT)
    local materialEntity = entity
    --维多利亚吸血通过buff放技能给skillholder回血
    if entity:HasSuperEntity() and entity:EntityType():IsSkillHolder() then
        materialEntity = entity:GetSuperEntity()
    end
    if entity:HasTeam() then
        materialEntity = entity:GetTeamLeaderPetEntity()
    end

    if materialEntity:MaterialAnimationComponent() then
        --材质动画
        if damageInfo:GetDamageType() == DamageType.Recover then
            materialEntity:MaterialAnimationComponent():PlayCure()
        end
    end

    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")

    --伤害飘字
    playDamageService:AsyncUpdateHPAndDisplayDamage(materialEntity, damageInfo)
end
