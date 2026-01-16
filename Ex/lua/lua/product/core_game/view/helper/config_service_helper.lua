--[[------------------------------------------------------------------------------------------
    ConfigServiceHelper : 用来给UI访问局内状态、数据等的静态类。
    禁止在局内逻辑层使用！！服务端会崩！
    UI需要知道一些具体的数据对象，但Service是个局内的概念，所以还是隔开比较合适
]] --------------------------------------------------------------------------------------------

---@class ConfigServiceHelper: Object
_class("ConfigServiceHelper", Object)
ConfigServiceHelper = ConfigServiceHelper

function ConfigServiceHelper._GetConfigService()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()

    local configService = mainWorld:GetService("Config")
    return configService
end

---@return LevelConfigData
function ConfigServiceHelper.GetLevelConfigData()
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetLevelConfigData()
end

function ConfigServiceHelper.ClearSkillConfigData()
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    configService:ClearSkillConfigData()
end

---@return MonsterConfigData
function ConfigServiceHelper.GetMonsterConfigData()
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetMonsterConfigData()
end

function ConfigServiceHelper.GetBuffConfigData(buffID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetBuffConfigData(buffID)
end

function ConfigServiceHelper.GetSkillConfigData(skillID, pstID)
    local entity
    if pstID then
        ---@type GameGlobal
        local gameGlobal = GameGlobal:GetInstance()
        ---@type MainWorld
        local mainWorld = gameGlobal:GetMainWorld()
        ---@type Entity
        local eTeam = mainWorld:Player():GetLocalTeamEntity()
        local cTeam = eTeam:Team()
        entity = cTeam:GetPetEntityByPetPstID(pstID)
        if not entity then
            Log.error()
        end
    end
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetSkillConfigData(skillID, entity)
end

function ConfigServiceHelper.GetMission3StarCondition(missionID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetMission3StarCondition(missionID)
end

function ConfigServiceHelper.GetCampaignMission3StarCondition(missionID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetCampaignMission3StarCondition(missionID)
end

function ConfigServiceHelper.GetChessMission3StarCondition(missionID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetChessMission3StarCondition(missionID)
end

function ConfigServiceHelper.GetPopStar3StarCondition(missionID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetPopStar3StarCondition(missionID)
end
function ConfigServiceHelper.GetSeasonMission3StarCondition(missionID)
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    return configService:GetSeasonMission3StarCondition(missionID)
end

--换队长次数挪到team的attribute中，这个方法仅在UI初始化时使用 20220124
function ConfigServiceHelper.GetChangeTeamLeaderCount()
    ---@type ConfigService
    local configService = ConfigServiceHelper._GetConfigService()
    local leftCount = configService:GetChangeTeamLeaderCount()
    return leftCount
end

function ConfigServiceHelper.GetConfigMessageByAttr(tab, attr,comp)
    if not  tab then return  end 
    local  tabNew = {}
    for index, value in ipairs(tab) do
        if value[attr] and value[attr] == comp then 
            table.insert(tabNew,value)
        end 
    end
    return tabNew
end 
