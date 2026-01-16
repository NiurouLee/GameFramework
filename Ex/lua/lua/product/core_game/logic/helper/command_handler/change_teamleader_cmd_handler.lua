require "command_base_handler"

_class("ChangeTeamLeaderCommandHandler", CommandBaseHandler)
---@class ChangeTeamLeaderCommandHandler: CommandBaseHandler
ChangeTeamLeaderCommandHandler = ChangeTeamLeaderCommandHandler

---@param cmd ChangeTeamLeaderCommand
function ChangeTeamLeaderCommandHandler:DoHandleCommand(cmd)
        ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local newTeamLeaderPetPstID = cmd:GetNewLeaderPstID()
    local oldTeamLeaderPetPstID = cmd:GetOldLeaderPstID()
    ---@type AttributesComponent
    local teamAttrConmpt = teamEntity:Attributes()
    local leftCount = teamAttrConmpt:GetAttribute("ChangeTeamLeaderCount")
    if leftCount < 1 and leftCount ~= -1 then
        Log.fatal("ChangeTeamLeader Invalid LeftCount:", leftCount)
        return
    end
    if not self:_CheckChangeTeamLeaderPstID(teamEntity, newTeamLeaderPetPstID, oldTeamLeaderPetPstID) then
        Log.fatal("CheckChangeTeamLeader failed")
        return
    end
    ---@type MatchPet
    local newPetData = self._world.BW_WorldInfo:GetPetData(newTeamLeaderPetPstID)
    if newPetData:IsHelpPet() then
        Log.fatal("NewPet Is HelpPet NewTeamLeaderPetPstID:", newTeamLeaderPetPstID)
        return
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    battleStatCmpt:AddTeamLeaderChangeNum()

    -- 保存换队长前的序列
    local cTeam = teamEntity:Team()
    local tOldTeamOrder = cTeam:CloneTeamOrder()

    local teamOrderBefore, teamOrderAfter = self:ChangeTeamLeader(newTeamLeaderPetPstID)
    if leftCount == -1 then
    else
        if leftCount < 1 then
            Log.fatal("ChangeTeamLeader Invalid LeftCount:", leftCount)
        end
        teamAttrConmpt:Modify("ChangeTeamLeaderCount", leftCount-1)
    end
    
    local leftChangeTeamLeaderCount = teamAttrConmpt:GetAttribute("ChangeTeamLeaderCount")

    local petEntity = teamEntity:Team():GetPetEntityByPetPstID(newTeamLeaderPetPstID)
    local oldLeaderPetEntity = teamEntity:Team():GetPetEntityByPetPstID(oldTeamLeaderPetPstID)

    -- 保存换队长后的序列，这个和tOldTeamOrder的内容不一样
    local tNewTeamOrder = cTeam:CloneTeamOrder()
    teamEntity:Team():SetChangeTeamLeaderCmdData(tOldTeamOrder, tNewTeamOrder)

    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTChangeTeamLeader:New(petEntity, oldLeaderPetEntity))

    local ntTeamOrderChange = NTTeamOrderChange:New(teamEntity,teamOrderBefore,teamOrderAfter)
    triggerService:Notify(ntTeamOrderChange)

    if self._world:RunAtClient() then
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 10)
    end
end

function ChangeTeamLeaderCommandHandler:_PlayNotify(TT, ntTeamOrderChange)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntTeamOrderChange)
end

function ChangeTeamLeaderCommandHandler:_CheckChangeTeamLeaderPstID(teamEntity, newPetPstID, oldPetPstID)
    ---@type Entity
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    local curTeamLeaderPstID = teamEntity:Team():GetTeamLeaderPetPstID()
    if newPetPstID == curTeamLeaderPstID then
        Log.fatal("NewTeamLeader Invalid PetPstID:", newPetPstID)
        return false
    end
    if curTeamLeaderPstID ~= oldPetPstID then
        Log.fatal("OldTeamLeader Invalid ",oldPetPstID,' curTeamLeaderPstID=',curTeamLeaderPstID)
        return false
    end
    return true
end

--手动换队长
function ChangeTeamLeaderCommandHandler:ChangeTeamLeader(petPstID)
    --[[
        执行逻辑被移到BattleService，因为有新的技能逻辑需要使用它
    ]]
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    return battleService:ChangeLocalTeamLeader(petPstID)
end
