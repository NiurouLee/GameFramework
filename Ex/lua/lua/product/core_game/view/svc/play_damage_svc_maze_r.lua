require "play_damage_svc_r"
_class("PlayDamageServiceMaze", PlayDamageService)
PlayDamageServiceMaze = PlayDamageServiceMaze


--星灵头像UI上的血条
function PlayDamageServiceMaze:_RefreshTeamHP(TT, defenderEntity, damageInfo)
    local teamEntity
    if defenderEntity:HasTeam() then
        teamEntity = defenderEntity
    elseif defenderEntity:PetPstID() then
        teamEntity = defenderEntity:Pet():GetOwnerTeamEntity()
    else
        return
    end
    local petList = teamEntity:Team():GetTeamPetEntities()
    local curTeamHP, maxTeamHP = 0, 0
    local deadPetList = {}

    ---@type BattleRenderConfigComponent
    local battleRenderCmpt = self._world:BattleRenderConfig()
    for id, entity in ipairs(petList) do
        local changeValue = damageInfo:GetMazeDamageValue(entity:GetID()) or 0
        local renderCurMaxHP = entity:HP():GetMaxHP()
        maxTeamHP = maxTeamHP + renderCurMaxHP

        local renderCurHP = entity:HP():GetRedHP()
        renderCurHP = renderCurHP + changeValue
        if renderCurHP > renderCurMaxHP then
            renderCurHP = renderCurMaxHP
        end
        if renderCurHP < 0 then
            renderCurHP = 0
        end

        entity:ReplaceRedHP(renderCurHP)

        ---@type PetPstIDComponent
        local petPstIDComponent = entity:PetPstID()
        local pstID = petPstIDComponent:GetPstID()
        curTeamHP = curTeamHP + renderCurHP
        local is_dead = false
        if renderCurHP <= 0 then
            is_dead = true
            table.insert(deadPetList, pstID)
            battleRenderCmpt:AddDeadPet(entity:PetPstID():GetTemplateID())
        end
        Log.notice("_RefreshTeamHP() entityID:", entity:GetID(), "CurHP:", renderCurHP, "MaxHP:", renderCurMaxHP)
        --增加秘境星灵血量变化表现的通知
        self:_OnHpChangeNotifyBuff(TT, entity, changeValue, damageInfo)
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.OnPetHpChangedInMaze,
            {
                pet_pstid = pstID,
                cur_hp = renderCurHP,
                max_hp = renderCurMaxHP,
                is_dead = is_dead,
                change_value = changeValue
            }
        )
    end

    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetDeadChangeHeadPos, deadPetList)
    -- 表现移到了MainStateSystem:_DoRenderPetDead 走统一的表现队列

    ---@type HPComponent
    local hpCmpt = teamEntity:HP()
    local shieldPoint = hpCmpt:GetShieldValue()

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.TeamHPChange,
        {
            isLocalTeam = true,
            currentHP = curTeamHP,
            maxHP = maxTeamHP,
            hitpoint = curTeamHP,
            shield = shieldPoint,
            entityID=teamEntity:GetID(),
            showCurseHp = hpCmpt:GetShowCurseHp(),
            curseHpVal = hpCmpt:GetCurseHpValue()
        }
    )
end
