--吸血
---@class BuffViewVampire:BuffViewBase
_class("BuffViewVampire", BuffViewBase)
BuffViewVampire = BuffViewVampire

function BuffViewVampire:IsNotifyMatch(notify)
    --只有自己吸血
    if notify and notify:GetNotifyEntity() ~= self._entity then
        return false
    end
    if notify:GetNotifyType() == NotifyType.NormalEachAttackEnd then
        local result = self._buffResult
        return (result.attacker == notify:GetAttackerEntity() and result.defender == notify:GetDefenderEntity() and
            result.attackPos == notify:GetAttackPos() and
            result.targetPos == notify:GetTargetPos())
    end
    return true
end

function BuffViewVampire:PlayView(TT)
    ---@type BuffResultVampire
    local buffRes = self._buffResult
    ---@type  Entity
    local entity = self._entity
    ---@type DamageInfo
    local damageInfo = buffRes:GetDamageInfo()

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

    if buffRes:IsAddSan() then
        local old = buffRes:GetOldSanValue()
        local current = buffRes:GetNewSanValue()
        local val = buffRes:GetModifySanValue()
        local debtVal = buffRes:GetDebtValue()
        local modifyTimes = buffRes:GetModifyTimes()

        ---@type FeatureServiceRender
        local featureSvc = self._world:GetService("FeatureRender")
        featureSvc:NotifySanValueChange(current, old, val)

        local nt = NTSanValueChange:New(current, old, debtVal, modifyTimes)
        self._world:GetService("PlayBuff"):PlayBuffView(TT, nt)
    end
end
