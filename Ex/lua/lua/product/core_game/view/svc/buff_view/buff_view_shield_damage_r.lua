--[[
    伤害导致的血条盾
]]
_class("BuffViewAddDamageShield", BuffViewBase)
BuffViewAddDamageShield = BuffViewAddDamageShield

function BuffViewAddDamageShield:PlayView(TT)
    ---@type Entity
    local player = self._world:Player():GetCurrentTeamEntity()

    ---取出对应星灵身上的护盾血量值
    local curShield = self:GetBuffResult():GetShield()
    ---@type HPComponent
    local hpCmpt = player:HP()
    if not hpCmpt then
        Log.error("add damge shield no hpCmpt!!")
        return
    end
    hpCmpt:SetShieldValue(curShield)

    player:TriggerHPUpdate()

    local hpBarID = hpCmpt:GetHPSliderEntityID()
    local hpBarEntity = self._world:GetEntityByID(hpBarID)
    local go = hpBarEntity:View().ViewWrapper.GameObject
    local uiview = go:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local shieldImg = uiview:GetUIComponent("Image", "shield")
    if shieldImg ~= nil then
        shieldImg.gameObject:SetActive(true)
    end

    -- MSG58099 但凡这个功能之前真的生效过，也不至于到了2023年才发现……
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamHPChange, {
        isLocalTeam = self._world:Player():IsLocalTeamEntity(player),
        currentHP = hpCmpt:GetRedHP(),
        maxHP = hpCmpt:GetMaxHP(),
        hitpoint = hpCmpt:GetWhiteHP(),
        shield = hpCmpt:GetShieldValue(),
        entityID = player:GetID(),
        showCurseHp = hpCmpt:GetShowCurseHp(),
        curseHpVal = hpCmpt:GetCurseHpValue()
    })
end

_class("BuffViewRemoveDamageShield", BuffViewBase)
BuffViewRemoveDamageShield = BuffViewRemoveDamageShield

function BuffViewRemoveDamageShield:PlayView(TT)
    ---@type Entity
    local player = self._world:Player():GetCurrentTeamEntity()

    ---@type HPComponent
    local hpCmpt = player:HP()
    if not hpCmpt then
        Log.error("add damge shield no hpCmpt!!")
        return
    end
    hpCmpt:SetShieldValue(0)

    player:TriggerHPUpdate()

    local hpBarID = hpCmpt:GetHPSliderEntityID()
    local hpBarEntity = self._world:GetEntityByID(hpBarID)
    local go = hpBarEntity:View().ViewWrapper.GameObject
    local uiview = go:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local shieldImg = uiview:GetUIComponent("Image", "shield")
    if shieldImg ~= nil then
        shieldImg.gameObject:SetActive(false)
    end

    -- MSG58099 但凡这个功能之前真的生效过，也不至于到了2023年才发现……
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamHPChange, {
        isLocalTeam = self._world:Player():IsLocalTeamEntity(player),
        currentHP = hpCmpt:GetRedHP(),
        maxHP = hpCmpt:GetMaxHP(),
        hitpoint = hpCmpt:GetWhiteHP(),
        shield = hpCmpt:GetShieldValue(),
        entityID = player:GetID(),
        showCurseHp = hpCmpt:GetShowCurseHp(),
        curseHpVal = hpCmpt:GetCurseHpValue()
    })
end
