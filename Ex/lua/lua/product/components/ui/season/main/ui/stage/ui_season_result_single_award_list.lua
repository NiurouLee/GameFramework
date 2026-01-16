---@class UISeasonResultSingleAwardList:UICustomWidget
_class("UISeasonResultSingleAwardList", UICustomWidget)
UISeasonResultSingleAwardList = UISeasonResultSingleAwardList

function UISeasonResultSingleAwardList:OnShow(uiParams)
    self:InitWidget()
end
function UISeasonResultSingleAwardList:InitWidget()
    self._bgResMap = {}
    self._bgResMap[UISeasonLevelDiff.Normal] = "exp_s1_map_di24"
    self._bgResMap[UISeasonLevelDiff.Hard] = "exp_s1_map_di35"
    ---@type UICustomWidgetPool
    self._awardsGen = self:GetUIComponent("UISelectObjectPath", "Awards")
    self._bgImg = self:GetUIComponent("Image", "BgImg")
    self._atlas = self:GetAsset("UIS1Main.spriteatlas", LoadType.SpriteAtlas)
end
function UISeasonResultSingleAwardList:OnHide()
end
--awardsTb 不是列表
function UISeasonResultSingleAwardList:SetData(awardsTb)
    self._taskIDList = {}
    self._awardsTb = awardsTb
    local levelDiff = self._awardsTb.levelDiff
    if levelDiff then
        -- local bgName = self._bgResMap[levelDiff]
        -- if bgName then
        --     self._bgImg.sprite = self._atlas:GetSprite(bgName)
        -- end
    end
    local count = self._awardsTb.cellCount
    self._awardsGen:SpawnObjects("UIWidgetSeasonResultReward", count)
    ---@type UIWidgetSeasonResultReward[]
    local items = self._awardsGen:GetAllSpawnList()
    local itemIndex = 1
    --三星奖励
    if awardsTb.starRewards then
        local starRewards = awardsTb.starRewards
        for i = 1, #starRewards do
            local roleAsset = starRewards[i]
            local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, true)
            items[itemIndex]:SetLevelDiff(levelDiff)
            table.insert(self._taskIDList, taskID)
            itemIndex = itemIndex + 1
        end
    end
    if awardsTb.extStarRewards then
        local extStarRewards = awardsTb.extStarRewards
        --赛季 额外三星奖励
        for i = 1, #extStarRewards do
            local roleAsset = extStarRewards[i]
            local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, true)
            items[itemIndex]:SetLevelDiff(levelDiff)
            table.insert(self._taskIDList, taskID)
            itemIndex = itemIndex + 1
        end
    end
    if awardsTb.firstPassRawrds then
        local firstPassRawrds = awardsTb.firstPassRawrds
        --首通奖励
        for i = 1, #firstPassRawrds do
            local roleAsset = firstPassRawrds[i]
            local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, true)
            items[itemIndex]:SetLevelDiff(levelDiff)
            table.insert(self._taskIDList, taskID)
            itemIndex = itemIndex + 1
        end
    end
    if awardsTb.extFirstPassRewards then
        local extFirstPassRewards = awardsTb.extFirstPassRewards
        --赛季 额外首通奖励
        for i = 1, #extFirstPassRewards do
            local roleAsset = extFirstPassRewards[i]
            local taskID = items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false, false, true)
            items[itemIndex]:SetLevelDiff(levelDiff)
            table.insert(self._taskIDList, taskID)
            itemIndex = itemIndex + 1
        end
    end
    if awardsTb.normalRewards then
        local normalRewards = awardsTb.normalRewards
        --其他奖励
        for i = 1, #normalRewards do
            ---@type RoleAsset
            local roleAsset = normalRewards[i]
            if roleAsset.assetid ~= RoleAssetID.RoleAssetExp then --按照首通奖励排序规则 金币不再特殊处理 and roleAsset.assetid ~= RoleAssetID.RoleAssetGold then
                items[itemIndex]:Init(roleAsset.count, roleAsset.assetid, false)
                items[itemIndex]:SetLevelDiff(levelDiff)
                itemIndex = itemIndex + 1
            end
        end
    end
end
-- function UISeasonResultSingleAwardList:SetData(awardsTb)
--     self._taskIDList = {}
--     self._awardsTb = awardsTb
--     local levelDiff = self._awardsTb.levelDiff
--     if levelDiff then
--         local bgName = self._bgResMap[levelDiff]
--         if bgName then
--             self._bgImg.sprite = self._atlas:GetSprite(bgName)
--         end
--     end
--     local count = self._awardsTb.cellCount
--     self._awardsGen:SpawnObjects("UISeasonStageAwardItem", count)
--     ---@type UISeasonStageAwardItem[]
--     local items = self._awardsGen:GetAllSpawnList()
--     local itemIndex = 1
--     --三星奖励
--     if awardsTb.starRewards then
--         local starRewards = awardsTb.starRewards
--         for i = 1, #starRewards do
--             local ra = starRewards[i]
--             local award = Award:New()
--             award:InitWithCount(ra.assetid, ra.count, AwardType.ThreeStar)
--             award:FlushType(StageAwardType.Star)
--             items[itemIndex]:Flush(award,levelDiff)
--             itemIndex = itemIndex + 1
--         end
--     end
--     if awardsTb.extStarRewards then
--         local extStarRewards = awardsTb.extStarRewards
--         --赛季 额外三星奖励
--         for i = 1, #extStarRewards do
--             local ra = extStarRewards[i]
--             local award = Award:New()
--             award:InitWithCount(ra.assetid, ra.count, AwardType.ThreeStar)
--             award:FlushType(StageAwardType.Star)
--             items[itemIndex]:Flush(award,levelDiff)
--             itemIndex = itemIndex + 1
--         end
--     end
--     if awardsTb.firstPassRawrds then
--         local firstPassRawrds = awardsTb.firstPassRawrds
--         --首通奖励
--         for i = 1, #firstPassRawrds do
--             local ra = firstPassRawrds[i]
--             local award = Award:New()
--             award:InitWithCount(ra.assetid, ra.count, AwardType.First)
--             award:FlushType(StageAwardType.First)
--             items[itemIndex]:Flush(award,levelDiff)
--             itemIndex = itemIndex + 1
--         end
--     end
--     if awardsTb.extFirstPassRewards then
--         local extFirstPassRewards = awardsTb.extFirstPassRewards
--         --赛季 额外首通奖励
--         for i = 1, #extFirstPassRewards do
--             local ra = extFirstPassRewards[i]
--             local award = Award:New()
--             award:InitWithCount(ra.assetid, ra.count, AwardType.First)
--             award:FlushType(StageAwardType.First)
--             items[itemIndex]:Flush(award,levelDiff)
--             itemIndex = itemIndex + 1
--         end
--     end
--     if awardsTb.normalRewards then
--         local normalRewards = awardsTb.normalRewards
--         --其他奖励
--         for i = 1, #normalRewards do
--             ---@type RoleAsset
--             local roleAsset = normalRewards[i]
--             if roleAsset.assetid ~= RoleAssetID.RoleAssetExp then --按照首通奖励排序规则 金币不再特殊处理 and roleAsset.assetid ~= RoleAssetID.RoleAssetGold then
--                 local ra = normalRewards[i]
--                 local award = Award:New()
--                 award:InitWithCount(ra.assetid, ra.count, AwardType.Pass)
--                 award:FlushType(StageAwardType.Normal)
--                 items[itemIndex]:Flush(award,levelDiff)
--                 itemIndex = itemIndex + 1
--             end
--         end
--     end
-- end