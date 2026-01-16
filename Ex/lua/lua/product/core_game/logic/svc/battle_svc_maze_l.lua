--[[------------------------------------------------------------------------------------------
    BattleService 战斗整体行为公共服务
]] --------------------------------------------------------------------------------------------
require("base_service")
require("battle_svc_l")
_class("BattleService_Maze", BattleService)
---@class BattleService_Maze:BattleService
BattleService_Maze = BattleService_Maze

---@param teamEntity Entity
function BattleService_Maze:AddPetDeadMark(teamEntity)
    local deadPet = {}
    local petEntities = teamEntity:Team():GetTeamPetEntities()
    for id, entity in ipairs(petEntities) do
        local curHP = entity:Attributes():GetCurrentHP()
        if curHP <= 0 and not entity:HasPetDeadMark() then
            entity:AddPetDeadMark()
            table.insert(deadPet, entity:GetID())
            Log.fatal("PetDead PetEntityID:", entity:GetID(), "HP:", curHP, "TID:", entity:PetPstID():GetTemplateID())

            local teamOrder = teamEntity:Team():CloneTeamOrder()
            local deadPstID = entity:PetPstID():GetPstID()
            local petOrder = 1
            for index, pstID in ipairs(teamOrder) do
                if deadPstID == pstID then
                    petOrder = index
                    break
                end
            end
            entity:PetPstID():SetTeamOrderBeforeDead(petOrder)
        end
    end
    return deadPet
end

---@return Entity
function BattleService_Maze:GetNonHelperAlivePet(teamEntity)
    local teamLeader = teamEntity:GetTeamLeaderPetEntity()
    ---@type Entity[]
    local petEntities = teamEntity:Team():GetTeamPetEntities()
    local secondaryPetEntity
    for id, entity in ipairs(petEntities) do
        if (
            (entity:GetID() ~= teamLeader:GetID()) and
            (not entity:HasPetDeadMark()) and
            (not entity:PetPstID():IsHelpPet()) -- N13新增统一规则：助战不可被替补为队长
        ) then
            if (not entity:HasBuffFlag(BuffFlags.SealedCurse)) then -- 优先找没有禁止上场诅咒的宝宝
                return entity
            else
                if not secondaryPetEntity then -- 备用人选：如果所有活着的队员都禁止上场，就把这个人推上去
                    secondaryPetEntity = entity
                end
            end
        end
    end

    -- 如果走到这里，要么是没有活着的队员，要么是队员全被诅咒，如果有备选（被诅咒但活着）的话，就把备选推出去
    -- 自动换队长的时候会发出一个通知，这个通知用来自动解诅咒
    if secondaryPetEntity then
        return secondaryPetEntity
    end

    return nil
end

function BattleService_Maze:UnLoadTeamMemberLogic(teamEntity)
    local teamLeader = teamEntity:GetTeamLeaderPetEntity()
    local petEntities = teamEntity:Team():GetTeamPetEntities()
    local unloadList = {}
    for id, entity in ipairs(petEntities) do
        if id ~= teamLeader:GetID() and entity:HasPetDeadMark() then
            --TODO 卸载被动技能
            table.insert(unloadList, entity)
        end
    end
end


--队长死了用这个函数，手动换队长用ChangeTeamLeader()
--新增注释：秘境内有光灵阵亡时，会在正常的死亡逻辑处理结束时，统一做teamOrder调整和buff触发，这里不用单独做
function BattleService_Maze:ChangeTeamLeaderLogic(teamEntity)
    ---@type Entity
    local teamLeader = teamEntity:GetTeamLeaderPetEntity()
    ---队长死了
    if teamLeader:HasPetDeadMark() then
        self._world.BW_WorldInfo.TeamLeaderPetPstID = teamLeader:PetPstID():GetPstID()
        local oldLeaderTemplateID = teamLeader:PetPstID():GetTemplateID()
        ---@type Entity
        local replaceEntity = self:GetNonHelperAlivePet(teamEntity)
        if replaceEntity then
            self._world:GetService("Trigger"):Notify(NTBeforeMazeTeamLeaderSucceed:New(replaceEntity))
            teamEntity:SetTeamLeaderPetEntity(replaceEntity)
            ---@type DataPetDeadResult
            local petDeadRes = DataPetDeadResult:New()
            local deadList = {}
            deadList[#deadList + 1] = teamEntity:GetID()
            petDeadRes:DataSetDeadPetEntityIDList(deadList)
            self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, petDeadRes)

            ----TLOG需求
            ---@type BattleStatComponent
            local battleStatCmpt = self._world:BattleStat()
            battleStatCmpt:AddPassiveTeamLeaderChangeNum()

            local newLeaderTemplateID = replaceEntity:PetPstID():GetTemplateID()
            self._world:EventDispatcher():Dispatch(
                GameEventType.MazeChangeTeamLeader,
                oldLeaderTemplateID,
                newLeaderTemplateID
            )
            ----TLOG需求 End
        end
    end
end

--队长复活
function BattleService_Maze:TeamLeaderResurgence(originalLeader,teamEntity)
    local teamLeader = teamEntity:GetTeamLeaderPetEntity()

    local oldLeaderTemplateID = teamLeader:PetPstID():GetTemplateID()

    ---@type Entity
    local replaceEntity = originalLeader

    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    if replaceEntity then
        teamEntity:SetTeamLeaderPetEntity(replaceEntity)
        ----TLOG需求
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        battleStatCmpt:AddPassiveTeamLeaderChangeNum()

        local newLeaderTemplateID = replaceEntity:PetPstID():GetTemplateID()
        self._world:EventDispatcher():Dispatch(
            GameEventType.MazeChangeTeamLeader,
            oldLeaderTemplateID,
            newLeaderTemplateID
        )
    ----TLOG需求 End
    end
end

---@param teamEntity Entity
function BattleService_Maze:UnloadPetLogic(teamEntity)
    local tOldTeamOrder = teamEntity:Team():CloneTeamOrder()

    local deadPetThisTime = self:AddPetDeadMark(teamEntity)
    self:UnLoadDeadPetBuff(teamEntity)
    self:RemoveDeadPetPassiveSkill(teamEntity)
    self:ChangeTeamLeaderLogic(teamEntity)
    self:UnLoadTeamMemberLogic(teamEntity)

    local ntChangeTeamOrder
    if #deadPetThisTime > 0 then
        ntChangeTeamOrder = self:ChangeTeamOrderOnUnloadPet(teamEntity, tOldTeamOrder, deadPetThisTime)
    end

    return ntChangeTeamOrder
end

function BattleService_Maze:UnLoadDeadPetBuff(teamEntity)
        ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local petList = teamEntity:Team():GetTeamPetEntities()
    for i, entity in ipairs(petList) do
        if entity:HasPetDeadMark() then
            buffLogicService:RemoveAllBuffInstance(entity)
        end
    end
end

function BattleService_Maze:RemoveDeadPetPassiveSkill(teamEntity)
    local petList = teamEntity:Team():GetTeamPetEntities()
    for i, entity in ipairs(petList) do
        if entity:HasPetDeadMark() then
            ---@type BuffSource
            local buffSource = BuffSource:New(BuffSourceType.PassiveSkill, entity:PetPstID():GetPstID())
            local buffEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.Buff)
            for _, buffEntity in ipairs(buffEntityList) do
                ---@type BuffComponent
                local buffComponent = buffEntity:BuffComponent()
                buffComponent:UnLoadBuff(buffSource)
            end
        end
    end
end


function BattleService_Maze:PlayerIsDead(teamEntity)
    return self:IsAllPetDead()
end

---@return boolean
function BattleService_Maze:HandlePlayerCalculation()
    return self:IsAllPetDead()
end

function BattleService_Maze:IsAllPetDead()
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local petEntities = teamEntity:Team():GetTeamPetEntities()
    for _, entity in ipairs(petEntities) do
        local curHP = entity:Attributes():GetCurrentHP()
        if curHP > 0 then
            return false
        end
    end
    return true
end

---@param casterEntity Entity
---@return number ,number
function BattleService_Maze:GetCasterHP(casterEntity)
    ---@type AttributesComponent
    local attributeCmpt = casterEntity:Attributes()
    local HP = attributeCmpt:GetCurrentHP()
    local maxHP = attributeCmpt:CalcMaxHp()
    return HP, maxHP
end

---@param teamEntity Entity
function BattleService_Maze:ChangeTeamOrderOnUnloadPet(teamEntity, oldTeamOrder, deadPets)
    local cTeam = teamEntity:Team()

    -- oldTeamOrder是队长处理前的，这里获取到的是确定了新队长的序列
    local tTeamOrderAfterLeaderCheck = teamEntity:Team():CloneTeamOrder()

    local tNewTeamOrder = {}
    local deadPetPstIDs = {}
    local helpPetPstID
    for index, pstID in ipairs(tTeamOrderAfterLeaderCheck) do
        local e = cTeam:GetPetEntityByPetPstID(pstID)
        if e:PetPstID():IsHelpPet() then
            helpPetPstID = pstID
            goto CONTINUE
        end

        if not e:HasPetDeadMark() then
            table.insert(tNewTeamOrder, pstID)
        else
            table.insert(deadPetPstIDs, pstID)
        end

        ::CONTINUE::
    end

    local isHelpPetDead = helpPetPstID and cTeam:GetPetEntityByPetPstID(helpPetPstID):HasPetDeadMark()

    -- 到这里为止tNewTeamOrder里全是活着的自己人，如果助战队员是活的，那么插入助战队员
    if helpPetPstID and (not isHelpPetDead) then
        table.insert(tNewTeamOrder, helpPetPstID)
    end

    -- 接下来插入阵亡自己人
    for _, pstID in ipairs(deadPetPstIDs) do
        table.insert(tNewTeamOrder, pstID)
    end

    -- 最后，如果助阵光灵阵亡，把助阵光灵放进最后
    if helpPetPstID and isHelpPetDead then
        table.insert(tNewTeamOrder, helpPetPstID)
    end

    -- 把新的teamOrder设置到team身上
    cTeam:SetTeamOrder(tNewTeamOrder)

    -- buff触发通知：需求上认为一次这个过程算一次队伍换序
    -- 更换队长的时候没有发出通知，这里直接用处理开始前的序列发出来
    local nt = NTTeamOrderChange:New(teamEntity, oldTeamOrder, tNewTeamOrder)
    self._world:GetService("Trigger"):Notify(nt)

    return nt
end
