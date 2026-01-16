---@class UISeasonResultMultiAwardList:UICustomWidget
_class("UISeasonResultMultiAwardList", UICustomWidget)
UISeasonResultMultiAwardList = UISeasonResultMultiAwardList

function UISeasonResultMultiAwardList:OnShow(uiParams)
    self:InitWidget()
end
function UISeasonResultMultiAwardList:InitWidget()
    ---@type UICustomWidgetPool
    self._seasonAwardGen = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UnityEngine.UI.ScrollRect
    self._sr = self:GetUIComponent("ScrollRect", "ScrollView")
end
function UISeasonResultMultiAwardList:OnHide()
end
---@param matchRes UI_MatchResult
---@param seasonMissionInfo SeasonMissionCreateInfo
function UISeasonResultMultiAwardList:SetData(matchRes,seasonMissionInfo)
    local firstDiff = UISeasonLevelDiff.Hard
    local secondDiff = UISeasonLevelDiff.Normal
    local missionId = seasonMissionInfo.mission_id
    local secondMissionId = 0
    if missionId then
        local useMissionCfg = Cfg.cfg_season_mission[missionId]
        if useMissionCfg then
            firstDiff = useMissionCfg.OrderID
            local secondMissionCfg = nil
            local missionGroupId = useMissionCfg.GroupID
            local missionGroupCfgs = Cfg.cfg_season_mission{GroupID = missionGroupId}
            if #missionGroupCfgs > 0 then
                for index, value in ipairs(missionGroupCfgs) do
                    if value.OrderID ~= useMissionCfg.OrderID then
                        secondMissionCfg = value
                        secondMissionId = value.ID
                        secondDiff = value.OrderID
                        break
                    end
                end
            end
        end
    end
    --奖励物品(包括经验 货币 道具等)
    local normalRewards = matchRes.m_vecAwardNormal
    local starRewards = matchRes.m_vecAwardPerfect
    local firstPassRawrds = matchRes.m_vecFirstPassAward
    local extStarRewards = matchRes.m_ext_star_rewards[secondMissionId] or {}--赛季关卡
    local extFirstPassRewards = matchRes.m_ext_first_rewards[secondMissionId] or {}--赛季关卡
    local activityRewards = matchRes.m_activity_rewards
    --QA MSG26599 活动奖励单独弹窗(连续自动战斗中不单独弹)
    local extReward = matchRes.m_vecExtAward
    local doubleExtReward = matchRes.m_vecDoubleExtAward
    local backRewards = matchRes.m_back_rewards or {}
    local recommendReward = {}
    local collectionList = {}
    normalRewards = self:ProcessCollectionItem(normalRewards,collectionList)
    starRewards = self:ProcessCollectionItem(starRewards,collectionList)
    firstPassRawrds = self:ProcessCollectionItem(firstPassRawrds,collectionList)
    extStarRewards = self:ProcessCollectionItem(extStarRewards,collectionList)
    extFirstPassRewards = self:ProcessCollectionItem(extFirstPassRewards,collectionList)

    local itemModule = GameGlobal.GetModule(ItemModule)
    --推荐奖励排序
    if #recommendReward > 1 then
        itemModule:BattleResultSortAsset(recommendReward)
    end
    --给双倍券额外奖励排序
    if #doubleExtReward > 1 then
        itemModule:BattleResultSortAsset(doubleExtReward)
    end
    --给三星奖励排序
    if #starRewards > 1 then
        itemModule:BattleResultSortAsset(starRewards)
    end
    --给赛季额外三星奖励排序
    if #extStarRewards > 1 then
        itemModule:BattleResultSortAsset(extStarRewards)
    end
    --给首通奖励排序
    if #firstPassRawrds > 1 then
        itemModule:BattleResultSortAsset(firstPassRawrds)
    end
    --给赛季额外首通奖励排序
    if #extFirstPassRewards > 1 then
        itemModule:BattleResultSortAsset(extFirstPassRewards)
    end
    --给普通物品排序
    if #normalRewards > 1 then
        self:BattleNormalResultSortAsset(normalRewards)
    end
    if #extReward > 1 then
        itemModule:BattleResultSortAsset(extReward)
    end
    --回流排序
    if #backRewards > 1 then
        itemModule:BattleResultSortAsset(backRewards)
    end

    local multiAwardList = {}
    local firstList = {}
    local firstCellCount = #starRewards + #firstPassRawrds + #normalRewards
    firstList.levelDiff = firstDiff
    firstList.cellCount = firstCellCount
    firstList.starRewards = starRewards
    firstList.firstPassRawrds = firstPassRawrds
    firstList.normalRewards = normalRewards
    table.insert(multiAwardList,firstList)
    if #extStarRewards > 0 or #extFirstPassRewards > 0 then
        local secondList = {}
        local secondCellCount = #extStarRewards + #extFirstPassRewards
        secondList.levelDiff = secondDiff
        secondList.cellCount = secondCellCount
        secondList.extStarRewards = extStarRewards
        secondList.extFirstPassRewards = extFirstPassRewards
        table.insert(multiAwardList,secondList)
    end

    self._multiAwardList = multiAwardList
    local count = #self._multiAwardList
    self._seasonAwardGen:SpawnObjects("UISeasonResultSingleAwardList", count)
    ---@type UISeasonResultSingleAwardList[]
    local list = self._seasonAwardGen:GetAllSpawnList()
    for i, v in ipairs(list) do
        v:SetData(self._multiAwardList[i])
    end
    self:ResetScrollPos()

    --跟另一个功能冲突了，这里不处理返回赛季界面的收藏品弹窗了
    -- if collectionList and #collectionList > 0 then
    --     ---@type SeasonModule
    --     local seasonModule = self:GetModule(SeasonModule)
    --     if seasonModule then
    --         for index, value in ipairs(collectionList) do
    --             seasonModule:AppendWaitShowCollectionRewards(value)
    --         end
    --     end
    -- end
end
-- function UISeasonResultMultiAwardList:SetData(multiAwardList)
--     self._multiAwardList = multiAwardList
--     local count = #self._multiAwardList
--     self._seasonAwardGen:SpawnObjects("UISeasonStageSingleAwardList", count)
--     ---@type UISeasonStageSingleAwardList[]
--     local list = self._seasonAwardGen:GetAllSpawnList()
--     for i, v in ipairs(list) do
--         v:SetData(self._multiAwardList[i])
--     end
--     self:ResetScrollPos()
-- end
function UISeasonResultMultiAwardList:ProcessCollectionItem(awardList,collectionList)
    local retList = {}
    for i = 1, #awardList do
        ---@type RoleAsset
        local roleAsset = awardList[i]
        local isCollection = UISeasonHelper.IsSeasonCollectionItem(roleAsset.assetid)
        if isCollection then
            table.insert(collectionList,roleAsset)
        else
            table.insert(retList,roleAsset)
        end
    end
    return retList
end
function UISeasonResultMultiAwardList:ResetScrollPos()
    self._sr.horizontalNormalizedPosition = 0
end
---@param vecItem RoleAsset
function UISeasonResultMultiAwardList:_GetItemCount(vecItem)
    local nItemCount = 0
    if vecItem then
        for i = 1, #vecItem do
            local roleAsset = vecItem[i]
            if roleAsset.assetid ~= RoleAssetID.RoleAssetExp then
                nItemCount = nItemCount + 1
            end
        end
    end
    return nItemCount
end
--局内普通战斗结果物品排序
function UISeasonResultMultiAwardList:BattleNormalResultSortAsset(assets)
    local dataList = self:GetPassAward()
    table.sort(
        assets,
        function(a, b)
            local ta = Cfg.cfg_item[a.assetid]
            local tb = Cfg.cfg_item[b.assetid]
            if (ta == nil) then
                Log.error(" Cfg.cfg_item cant find assetid ", a.assetid)
            end
            if (tb == nil) then
                Log.error(" Cfg.cfg_item cant find assetid ", b.assetid)
            end
            local aNormal = self:HasItem(dataList, ta.ID)
            local bNormal = self:HasItem(dataList, tb.ID)
            if aNormal == bNormal then
                if ta.Color == tb.Color then
                    return ta.ID < tb.ID
                else
                    return ta.Color > tb.Color
                end
            else
                return aNormal > bNormal
            end
        end
    )
    return assets
end
function UISeasonResultMultiAwardList:GetPassAward()
    local awardHeadType, cfgId
    return UICommonHelper:GetInstance():GetPassAward(awardHeadType, cfgId)
end
function UISeasonResultMultiAwardList:HasItem(dataList, itemId)
    local isNormal = 0
    if dataList then
        for i, v in ipairs(dataList) do
            if v.ItemID == itemId then
                isNormal = 1
                break
            end
        end
    end
    return isNormal
end