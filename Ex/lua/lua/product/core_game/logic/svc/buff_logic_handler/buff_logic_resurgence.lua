--[[
    复活
]]
_class("BuffLogicResurgence", BuffLogicBase)
---@class BuffLogicResurgence:BuffLogicBase
BuffLogicResurgence = BuffLogicResurgence

function BuffLogicResurgence:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._addValue = logicParam.addValue or 0
    self._hadResurgence = false
end

function BuffLogicResurgence:DoLogic()
    --因为现在 没有数量限制
    if self._hadResurgence then
        return
    end

    self._hadResurgence = true

    ---@type Entity
    local e = self._world:BattleStat():GetFirstDeadPetEntity()
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()

    -- local cur_hp = e:Attributes():GetAttribute("HP")
    local add_value = max_hp * self._mulValue + self._addValue

    if add_value > max_hp then
        add_value = max_hp
    end
    add_value = math.floor(add_value)

    e:RemovePetDeadMark()

    self._world:BattleStat():SetFirstDeadPetEntity(nil)
    local damageInfo =  DamageInfo:New(add_value, DamageType.Recover)
    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")
    calcDamageSvc:AddTargetHP(e:GetID(), damageInfo)

    local tOldTeamOrder = teamEntity:Team():CloneTeamOrder()
    local tNewTeamOrderTmp

    -- 恢复这个光灵原先的席位，视作触发一次换序
    local formerOrder = e:PetPstID():GetTeamOrderBeforeDead()
    local pstID = e:PetPstID():GetPstID()
    if formerOrder == 1 then
        local originalLeader = teamEntity:Team():GetPetEntityByPetPstID(tOldTeamOrder[1])
        self._world:GetService("Battle"):TeamLeaderResurgence(originalLeader, teamEntity)
         -- teamEntity:SetTeamLeaderPetEntity里动过这个数据，这里重新取一遍就是最新了
        tNewTeamOrderTmp = teamEntity:Team():CloneTeamOrder()
    else
        tNewTeamOrderTmp = teamEntity:Team():CloneTeamOrder()
        table.removev(tNewTeamOrderTmp, e:PetPstID():GetPstID())
        if formerOrder > #tNewTeamOrderTmp then
            
        end
        table.insert(tNewTeamOrderTmp, formerOrder, pstID)
        teamEntity:Team():SetTeamOrder(tNewTeamOrderTmp)
    end

    -- 到这里还要重新整理一遍teamOrder的顺序：活人>活助战>死人>死助战
    local tNewTeamOrder = {}
    local deadPets = {}
    local helpPet
    for _, pstID in ipairs(tNewTeamOrderTmp) do
        local e = teamEntity:Team():GetPetEntityByPetPstID(pstID)
        if e:PetPstID():IsHelpPet() then
            helpPet = pstID
            goto CONTINUE
        end

        if not e:HasPetDeadMark() then
            table.insert(tNewTeamOrder, pstID)
        else
            table.insert(deadPets, pstID)
        end
        ::CONTINUE::
    end

    if helpPet then
        local e = teamEntity:Team():GetPetEntityByPetPstID(helpPet)
        if e:HasPetDeadMark() then
            -- 有助战且助战阵亡：先放自己的阵亡光灵
            table.appendArray(tNewTeamOrder, deadPets)
            table.insert(tNewTeamOrder, helpPet)
        else
            -- 有助战且助战存活：先放助战
            table.insert(tNewTeamOrder, helpPet)
            table.appendArray(tNewTeamOrder, deadPets)
        end
    else
        table.appendArray(tNewTeamOrder, deadPets)
    end

    local ntTeamOrderChange = NTTeamOrderChange:New(teamEntity, tOldTeamOrder, tNewTeamOrderTmp)
    self._world:GetService("Trigger"):Notify(ntTeamOrderChange)

    -- 移除这个光灵记录的阵亡前TeamOrder（是不是不清好像也没事？）
    e:PetPstID():SetTeamOrderBeforeDead(0)

    local curTeamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
    local curTeamLeaderEntity = self._world:GetEntityByID(curTeamLeaderEntityID)

    local res = BuffResultResurgence:New(e,curTeamLeaderEntity, add_value, damageInfo, tOldTeamOrder, tNewTeamOrderTmp)
    return res
end
