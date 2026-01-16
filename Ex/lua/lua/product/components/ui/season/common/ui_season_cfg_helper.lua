--[[
    Season cfg 辅助类
]]
---@class UISeasonCfgHelper:Object
_class("UISeasonCfgHelper", Object)
UISeasonCfgHelper = UISeasonCfgHelper

--region Quest

function UISeasonCfgHelper.CfgSeason_CampaignClient(id)
    local cfg = Cfg.cfg_season_campaign_client[id]
    UISeasonCfgHelper.CheckCfgNil(cfg, "cfg_season_campaign_client", id)
    return cfg
end

function UISeasonCfgHelper.GetCurSeasonQuestContent(id)
    if id == -1 then
        return
    end
    local cfg = UISeasonCfgHelper.CfgSeason_CampaignClient(id)
    local className = cfg and cfg.QuestContent and cfg.QuestContent[1]
    local prefabName = cfg and cfg.QuestContent and cfg.QuestContent[2]
    return className, prefabName
end

function UISeasonCfgHelper.GetCurSeasonMedalGroupCfg(id)
    if id == -1 then
        return
    end
    local cfg = UISeasonCfgHelper.CfgSeason_CampaignClient(id)
    local medalId = cfg and cfg.MedalGroupID
    if medalId then
        local medalCfg = Cfg.cfg_item_medal_group[medalId]
        UISeasonCfgHelper.CheckCfgNil(medalCfg, "cfg_item_medal_group", medalId)
        return medalCfg
    end
end

--endregion

--region Quest

function UISeasonCfgHelper.CfgSeason_QuestItemClient(id)
    local cfg = Cfg.cfg_season_quest_item_client[id]
    UISeasonCfgHelper.CheckCfgNil(cfg, "cfg_season_quest_item_client", id)
    return cfg
end

--endregion

function UISeasonCfgHelper.CheckCfgNil(cfg, cfgName, id)
    if not cfg then
        local strId = string.format("UISeasonCfgHelper %s[%s] = nil", cfgName, id)
        local str = id and strId or string.format("UISeasonCfgHelper %s = nil", cfgName)
        Log.exception(str, debug.traceback())
        return
    end
end