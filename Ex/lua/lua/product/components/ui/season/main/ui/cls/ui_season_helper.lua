--[[
    UI辅助类
]]
---@class UISeasonHelper:Object
_class("UISeasonHelper", Object)
UISeasonHelper = UISeasonHelper

--region ShowUIGetRewards
-- 通用奖励弹窗
-- 根据奖励类型分来，先显示 pet ，再显示 pet skin ，然后显示收藏品， 最后显示 item
---@param rewards RoleAsset[]
function UISeasonHelper.ShowUIGetRewards(rewards, doNotSort)
    if not rewards then
        return
    end

    -- 分类
    local tmpItemList = {}
    local petList = {}
    local petSkinList = {}
    local collectionList = {}

    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    for _, v in pairs(rewards) do
        if petModule:IsPetID(v.assetid) then
            table.insert(petList, v)
        elseif petModule:IsPetSkinID(v.assetid) then
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = petModule:GetSkinIDFromItemID(v.assetid)
            roleAsset.count = v.count
            table.insert(petSkinList, roleAsset)
        elseif UISeasonHelper.IsSeasonCollectionItem(v.assetid) then
            table.insert(collectionList, v)
        else
            table.insert(tmpItemList, v)
        end
    end
    local itemList = {}
    for index, value in ipairs(tmpItemList) do
        local itemCfg = Cfg.cfg_item[value.assetid]
        if itemCfg then
            table.insert(itemList, value)
        end
    end


    UISeasonHelper.ShowUIGetRewards_Pet(petList, petSkinList, collectionList, itemList, doNotSort)
end

function UISeasonHelper.ShowUIGetRewards_Pet(petList, petSkinList, collectionList, itemList, doNotSort)
    if table.count(petList) <= 0 then
        UISeasonHelper.ShowUIGetRewards_PetSkin(petSkinList, collectionList, itemList, doNotSort)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIPetObtain",
        petList,
        function()
            GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
            UISeasonHelper.ShowUIGetRewards_PetSkin(petSkinList, collectionList, itemList, doNotSort)
        end
    )
    return
end

function UISeasonHelper.ShowUIGetRewards_PetSkin(petSkinList, collectionList, itemList, doNotSort)
    if table.count(petSkinList) <= 0 then
        UISeasonHelper.ShowUIGetRewards_Collection(collectionList, itemList, doNotSort)
        return
    end

    local index = 0
    local showNextFunc = function()
        index = index + 1
        if index <= #petSkinList then
            return petSkinList[index]
        end
        return nil
    end
    local callBackFunc
    callBackFunc = function()
        GameGlobal.UIStateManager():CloseDialog("UIPetSkinObtainController")
        local nextAsset = showNextFunc()
        if nextAsset then
            UISeasonHelper.ShowUIGetRewards_PetSkin_Single(nextAsset, callBackFunc)
        else
            UISeasonHelper.ShowUIGetRewards_Collection(collectionList, itemList, doNotSort)
        end
    end

    UISeasonHelper.ShowUIGetRewards_PetSkin_Single(showNextFunc(), callBackFunc)
end

function UISeasonHelper.ShowUIGetRewards_PetSkin_Single(roleAsset, callBackFunc)
    if not roleAsset then
        if callBackFunc then
            callBackFunc()
        end
        return
    end
    GameGlobal.UIStateManager():ShowDialog("UIPetSkinObtainController", roleAsset, callBackFunc)
end

function UISeasonHelper.ShowUIGetRewards_Collection(collectionList, itemList, doNotSort)
    if table.count(collectionList) <= 0 then
        UISeasonHelper.ShowUIGetRewards_Item(itemList, doNotSort)
        return
    end

    local index = 0
    local showNextFunc = function()
        index = index + 1
        if index <= #collectionList then
            return collectionList[index]
        end
        return nil
    end
    local callBackFunc
    callBackFunc = function()
        GameGlobal.UIStateManager():CloseDialog("UISeasonShowCollectionAward")
        local nextAsset = showNextFunc()
        if nextAsset then
            UISeasonHelper.ShowUIGetRewards_Collection_Single(nextAsset, callBackFunc)
        else
            UISeasonHelper.ShowUIGetRewards_Item(itemList, doNotSort)
        end
    end

    UISeasonHelper.ShowUIGetRewards_Collection_Single(showNextFunc(), callBackFunc)
end

function UISeasonHelper.ShowUIGetRewards_Collection_Single(roleAsset, callBackFunc)
    if not roleAsset then
        if callBackFunc then
            callBackFunc()
        end
        return
    end
    GameGlobal.UIStateManager():ShowDialog("UISeasonShowCollectionAward", roleAsset, callBackFunc)
end

function UISeasonHelper.ShowUIGetRewards_Item(itemList, doNotSort)
    if table.count(itemList) <= 0 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        return
    end
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonShowAwards",
        itemList,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end,
        doNotSort
    )
end

--是否是收藏品
function UISeasonHelper.IsSeasonCollectionItem(id)
    if id and id > 0 then
        local cfg = Cfg.cfg_item[id]
        if cfg then
            local isCollection = (cfg.ItemSubType == ItemSubType.ItemSubType_Season_Collection)
            return isCollection
        end
    end
    return false
end

--endregion

--region 手册
---@param tabIndex UISeasonHelperTabIndex
function UISeasonHelper.ShowSeasonHelperBook(tabIndex)
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonHelperController", tabIndex
    )
end

--endregion

function UISeasonHelper.TestShowUIStage(missionId)
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonLevelStage",
        missionId
    )
end

function UISeasonHelper.TriggerStoryNode(stageId, seasonObj)
    --剧情关
    local missionCfg = Cfg.cfg_season_mission[stageId]
    if not missionCfg then
        return
    end
    local titleId = nil --StringTable.Get(missionCfg.Title)
    local titleName = StringTable.Get(missionCfg.Name)
    local missionModule = GameGlobal.GetModule(MissionModule)
    local storyId = missionModule:GetStoryByStageIdStoryType(stageId, StoryTriggerType.Node)
    if not storyId then
        Log.exception("配置错误,找不到剧情,关卡id:", stageId)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonPlotEnter",
        titleId,
        titleName,
        storyId,
        function()
            UISeasonHelper.PlotEndCallback(stageId, seasonObj)
        end
    )
    return
end

function UISeasonHelper.PlotEndCallback(stageId, seasonObj)
    -- component:Start_HandleCompleteStoryMission(stageId, function(res, award)
    --     if not res:GetSucc() then
    --         campaign._campaign_module:CheckErrorCode(res.m_result, campaign._id, nil, nil)
    --     else
    --         if table.count(award) ~= 0 then
    --             -- GameGlobal.UIStateManager():ShowDialog("UIGetItemController", award, callback)
    --             UISeasonHelper.ShowUIGetRewards(award)
    --         end
    --     end
    -- end)
end

function UISeasonHelper.TriggerMissionNode(stageId, seasonObj)
    local missionCfg = Cfg.cfg_season_mission[stageId]
    if not missionCfg then
        return
    end
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonLevelStage",
        stageId --,
    --seasonObj
    )
end

function UISeasonHelper.CalcBuffLevel(componentID)
    local cfgGroup = Cfg.cfg_component_season_wordbuff { ComponentID = componentID }
    if cfgGroup then
        if #cfgGroup > 0 then
            local needItemID = cfgGroup[1].NeedItemID
            local needItemLevelMap = {}
            for index, cfg in ipairs(cfgGroup) do
                needItemLevelMap[cfg.Lv] = cfg.NeedItemNum
            end
            ---@type ItemModule
            local itemModule = GameGlobal.GetModule(ItemModule)
            local itemCount = itemModule:GetItemCount(needItemID)
            local curLevel = 1
            local restProgress = 0
            local isMaxLevel = false
            local maxLevel = #needItemLevelMap
            for level, needItemNum in ipairs(needItemLevelMap) do
                if itemCount >= needItemNum then
                    curLevel = level
                    restProgress = itemCount - needItemNum
                end
            end
            if curLevel == #needItemLevelMap then
                isMaxLevel = true
            end
            local curLevelMaxProgress = 3
            if not isMaxLevel then
                curLevelMaxProgress = needItemLevelMap[curLevel + 1] - needItemLevelMap[curLevel]
            else
                curLevelMaxProgress = 3
            end
            return curLevel, restProgress, maxLevel, isMaxLevel, curLevelMaxProgress
        end
    end
    return 1, 0, 1, false, 3
end

---------------------------------------------------
function UISeasonHelper._ShowDialog_CurSeason(tb)
    local module = GameGlobal.GetModule(SeasonModule)
    local id = module:GetCurSeasonID()
    if id == nil or id == -1 then
        module:CheckErrorCode(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED)
        return
    end
    local dialogName = tb[id]
    if not string.isnullorempty(dialogName) then
        GameGlobal.UIStateManager():ShowDialog(dialogName)
    end
end

--打开当前开放的活动的收藏品界面
function UISeasonHelper.ShowCurSeasonCollage()
    local tb = {
        [UISeasonID.S1] = "UISeasonS1Collages"
    }

    UISeasonHelper._ShowDialog_CurSeason(tb)
end

--打开当前开放的活动的兑换界面
function UISeasonHelper.ShowCurSeasonExchange()
    local tb = {
        [UISeasonID.S1] = "UIS1ExchangeController"
    }

    UISeasonHelper._ShowDialog_CurSeason(tb)
end

function UISeasonHelper.ShowCurSeasonQuest()
    local tb = {
        [UISeasonID.S1] = "UISeasonQuestController"
    }
    UISeasonHelper._ShowDialog_CurSeason(tb)
end

--检查是否看过赛季入场视频
---@return boolean 返回true说明看过了
function UISeasonHelper.CheckEnterVideo(seasonID)
    local cfg = Cfg.cfg_season_campaign_client[seasonID]
    if not cfg then
        Log.exception("cfg_season_campaign_client中缺少配置:", seasonID)
    end
    if not cfg.EnterVideo then
        return true --没配就当看过了
    end
    local key = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterVideo"
    return LocalDB.GetInt(key, 0) == 1
end

function UISeasonHelper.AfterShowEnterVideo(seasonID)
    local key = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterVideo"
    LocalDB.SetInt(key, 1)
end

--是不是看过赛季入场剧情
---@return boolean 返回true说明看过了
function UISeasonHelper.CheckEnterStory(seasonID)
    local cfg = Cfg.cfg_season_campaign_client[seasonID]
    if not cfg then
        Log.exception("cfg_season_campaign_client中缺少配置:", seasonID)
    end
    if not cfg.EnterStory then
        return true --没配就当看过了
    end
    local key = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterStory"
    return LocalDB.GetInt(key, 0) == 1
end

function UISeasonHelper.AfterPlayEnterStory(seasonID)
    local key = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterStory"
    LocalDB.SetInt(key, 1)
end

--测试功能 删除本地入场剧情和视频存档
function UISeasonHelper.TEST_DeleteEnterStoryAndVideo(seasonID)
    local key1 = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterStory"
    LocalDB.Delete(key1)
    local key2 = GameGlobal.GetModule(RoleModule):GetPstId() .. "_" .. seasonID .. "_EnterStory"
    LocalDB.Delete(key2)
end

--赛季场景内播剧情统一接口 需要处理场景内音效
function UISeasonHelper.PlayStoryInSeasonScence(storyID, onFinish)
    ---@type SeasonAudio
    local seasonAudio
    ---@type UISeasonModule
    local uiModule = GameGlobal.GetUIModule(SeasonModule)
    if uiModule and uiModule:InSeasaonRunning() then
        seasonAudio = uiModule:SeasonManager():SeasonAudioManager():GetSeasonAudio()
    end
    if seasonAudio then
        seasonAudio:StopSeasonSounds() --停止场景音效
    end
    GameGlobal.UIStateManager():ShowDialog("UIStoryController",
        storyID,
        function()
            if seasonAudio then
                seasonAudio:ResumeSeasonSounds() --恢复场景音效
            end
            if onFinish then
                onFinish()
            end
        end
    )
end
