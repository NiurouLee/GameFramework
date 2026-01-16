--[[
    复活表现[只有秘境里有复活]
]]
_class("BuffViewResurgence", BuffViewBase)
BuffViewResurgence = BuffViewResurgence

function BuffViewResurgence:PlayView(TT)
    ---@type BuffResultResurgence
    local result = self._buffResult
    local playerEntity = result:GetEntity()
    --复活前的队长
    local beforeResurgenceTeamLeader = result:GetLeader()
    local addHPValue = result:GetAddValue()
    local damageInfo = result:GetDamageInfo()
    --复活之后的队长
    local teamLeaderEntity = self._world:Player():GetLocalTeamEntity():GetTeamLeaderPetEntity()
    beforeResurgenceTeamLeader:SetViewVisible(false)
    playerEntity:SetViewVisible(true)


    local tOldTeamOrder = result:GetOldTeamOrder()
    local tNewTeamOrder = result:GetNewTeamOrder()
    
    local viewRequest = BattleTeamOrderViewRequest:New(
        tOldTeamOrder,
        tNewTeamOrder,
        BattleTeamOrderViewType.FillVacancies_MazePetDead
    )

    local renderBattleSvc = self._world:GetService("RenderBattle")
    renderBattleSvc:RequestUIChangeTeamOrderView(viewRequest)

    local ntTeamOrderChange = NTTeamOrderChange:New(self._world:Player():GetLocalTeamEntity(), tOldTeamOrder, tNewTeamOrder)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntTeamOrderChange)

    --死亡动画
    local deadTriggerParam = "Death"
    local deadAnimName = "death"
    ---@type ViewComponent
    local viewCmpt = playerEntity:View()
    local playerObj = viewCmpt:GetGameObject()
    local animTimeLen = GameObjectHelper.GetActorAnimationLength(playerObj, deadAnimName)
    playerEntity:SetAnimatorControllerTriggers({deadTriggerParam})
    YIELD(TT, animTimeLen * 1000)

    --设置待机动画
    ---@type UnityEngine.Animator
    local animator = playerObj.transform:Find("Root"):GetComponent(typeof(UnityEngine.Animator))
    animator:Play("idle", 0)

    --复活特效
    local targetEffectID = self:BuffViewInstance():BuffConfigData():GetExecEffectID()
    if targetEffectID then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local effectEntity = effectService:CreateEffect(targetEffectID, playerEntity)
        YIELD(TT, 1000)
    end

    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()
    battleRenderCmpt:RemoveDeadPet(playerEntity:PetPstID():GetPstID())

    --刷新UI血条
    ---@type PlayDamageService
    local playDamageSvc = self._world:GetService("PlayDamage")
    playDamageSvc:UpdateTargetHPBar(TT, playerEntity, damageInfo)

    playerEntity:SetViewVisible(false)
    teamLeaderEntity:SetViewVisible(true)
end
