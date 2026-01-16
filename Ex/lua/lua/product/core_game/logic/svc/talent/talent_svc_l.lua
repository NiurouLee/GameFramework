--[[------------------------------------------------------------------------------------------
    TalentService 天赋逻辑类
]]
require("base_service")

---@class TalentService:BaseService
_class("TalentService", BaseService)
TalentService = TalentService

function TalentService:Constructor(world)
    self._world = world
    self._parseTalentParam = {}
    self._parseTalentParam[TalentType.Buff] = TalentAddBuffParam
    self._parseTalentParam[TalentType.MasterSkill] = TalentMasterSkillParam
    self._parseTalentParam[TalentType.AddRoundCount] = TalentAddRoundCountParam
    self._parseTalentParam[TalentType.AddChangeTeamLeaderCount] = TalentAddChangeTeamLeaderCountParam
    self._parseTalentParam[TalentType.ChooseRelic] = TalentChooseRelicParam
end

----@return TalentComponent
function TalentService:GetTalentComponent()
    ----@type TalentComponent
    local talentCmpt = self._world:GetBoardEntity():Talent()
    return talentCmpt
end

---@return boolean
function TalentService:HasTalentData(talentType)
    ---@type TalentComponent
    local talentCmpt = self:GetTalentComponent()
    return talentCmpt:HasTalentData(talentType)
end

---@return TalentBaseParam[]
function TalentService:GetTalentData(talentType)
    ---@type TalentComponent
    local talentCmpt = self:GetTalentComponent()
    return talentCmpt:GetTalentDataList(talentType)
end

---@param talentTreeSkills TalentTreeSkillNode[]
---@param unlockRelicIDs number[]
function TalentService:ParseTalentData(talentTreeSkills, unlockRelicIDs)
    ---@type TalentComponent
    local talentCmpt = self:GetTalentComponent()
    talentCmpt:SetUnlockRelicIDList(unlockRelicIDs)

    if table.count(talentTreeSkills) < 1 then
        return
    end
    for _, talent in ipairs(talentTreeSkills) do
        local talentCfg = Cfg.cfg_mini_maze_talent[talent.skill_id]
        if not talentCfg or not talentCfg.Param then
            Log.exception("ParseTalentData cant find talent :", talent.skill_id)
            return
        end

        local paramClassType = self._parseTalentParam[talentCfg.Type]
        if paramClassType == nil then
            Log.exception("ParseTalentData cant find talentType :", talentCfg.Type)
            return
        end

        --过滤掉未选择的空裔技能
        if talentCfg.Type == TalentType.MasterSkill and talent.select == 0 then
            goto CONTINUE
        end
        local talentParam = paramClassType:New(talentCfg.Param, talentCfg.Type, talent.level)
        talentCmpt:AddTalentData(talentCfg.Type, talentParam)

        ::CONTINUE::
    end
end

function TalentService:GetUnlockRelicIDList()
    ---@type TalentComponent
    local talentCmpt = self:GetTalentComponent()
    return talentCmpt:GetUnlockRelicIDList()
end

function TalentService:NeedChooseOpeningRelic()
    ---@type TalentComponent
    local talentCmpt = self:GetTalentComponent()
    if talentCmpt:IsChosenOpeningRelic() then
        return false
    end

    local groupID, count = self:GetChooseRelicParam()
    if groupID == 0 and count == 0 then
        return false
    end

    return true
end

function TalentService:InitTalentBuff(GameStartBuffs)
    if not self:HasTalentData(TalentType.Buff) then
        return
    end
    ---@type BuffLogicService
    local buffLogic = self._world:GetService("BuffLogic")

    ---@type TalentAddBuffParam[]
    local paramList = self:GetTalentData(TalentType.Buff)
    for _, param in ipairs(paramList) do
        local ret = buffLogic:AddBuffByTargetType(param:GetBuffID(), param:GetBuffTargetType(),
            param:GetBuffTargetParam())
        ---@param inst BuffInstance
        for _, inst in ipairs(ret) do
            GameStartBuffs[#GameStartBuffs + 1] = { inst:Entity(), inst:BuffSeq() }
        end
    end
end

function TalentService:ChangeFeature(featureList)
    if not self:HasTalentData(TalentType.MasterSkill) then
        return
    end

    ---@type TalentMasterSkillParam[]
    local paramList = self:GetTalentData(TalentType.MasterSkill)
    for _, param in ipairs(paramList) do
        local cfgFeatureList = param:GetFeatureList() --原始配置数据
        if cfgFeatureList then
            local featureCfg = cfgFeatureList.feature
            if featureCfg then
                for type, data in pairs(featureCfg) do
                    featureList[type] = data
                end
            end
        end
    end
end

---@param levelID number
---@return number
function TalentService:GetAddRoundCount(levelID)
    local count = 0
    if self:HasTalentData(TalentType.AddRoundCount) then
        ---@type TalentAddRoundCountParam[]
        local paramList = self:GetTalentData(TalentType.AddRoundCount)
        for _, param in ipairs(paramList) do
            count = count + param:GetAddCountByLevelID(levelID)
        end
    end
    return count
end

---@return number
function TalentService:GetAddChangeTeamLeaderCount()
    local count = 0
    if self:HasTalentData(TalentType.AddChangeTeamLeaderCount) then
        ---@type TalentAddChangeTeamLeaderCountParam[]
        local paramList = self:GetTalentData(TalentType.AddChangeTeamLeaderCount)
        for _, param in ipairs(paramList) do
            count = count + param:GetAddCount()
        end
    end
    return count
end

---@return number, number
function TalentService:GetChooseRelicParam()
    local groupID = 0
    local randomCount = 0
    if self:HasTalentData(TalentType.ChooseRelic) then
        ---@type TalentChooseRelicParam[]
        local paramList = self:GetTalentData(TalentType.ChooseRelic)
        for _, param in ipairs(paramList) do
            local tempGroupID = param:GetGroupID()
            local tempRandomCount = param:GetRandomCount()
            if tempGroupID > groupID then
                groupID = tempGroupID
                randomCount = tempRandomCount
            elseif tempGroupID == groupID then
                if tempRandomCount > randomCount then
                    randomCount = tempRandomCount
                end
            end
        end
    end
    return groupID, randomCount
end
