local UIBuildComponentBuildStatus = {
    Init = 0, -- 初始状态
    CleanUpComplete = 1, -- 除尘完成
    RepairComplete = 2, -- 修复完成
    DecorateComplete = 4, -- 装饰完成
    Picnic = 1024 -- 野餐状态
}
---@class UIBuildComponentBuildStatus:UIBuildComponentBuildStatus
_enum("UIBuildComponentBuildStatus", UIBuildComponentBuildStatus)

_class("UIBuildComponentBuildItemData", Object)
---@class UIBuildComponentBuildItemData:Object
UIBuildComponentBuildItemData = UIBuildComponentBuildItemData

function UIBuildComponentBuildItemData:Constructor(componentCfgID)
    self._componentCfgID = componentCfgID
    local cfgs = Cfg.cfg_component_build_item {ComponentID = componentCfgID}

    self._buildDataMap = self:_InitBuildDataMap(cfgs)
    self._buildDataStoryReviewIdMap = self:_InitBuildDataStoryReviewIdMap(cfgs)
    self._buildDataItemId = self:_InitBuildDataCostItemId(cfgs)
end

-- [建筑id 和 状态] 对应配置数据的 map
function UIBuildComponentBuildItemData:_InitBuildDataMap(tb_in)
    local tb_out = {}
    for _, v in pairs(tb_in) do
        local id, st = self:GetItemIdAndStatus(v)
        if not tb_out[id] then
            tb_out[id] = {}
        end
        local item = tb_out[id]
        if item[st] then
            Log.exception(
                "UIBuildComponentBuildItemData:GetBuildStatusMap()",
                " repeat [BuildItemId, BuildStatus] in cfg_component_build_item",
                " componentCfgID = " .. self._componentCfgID
            )
        end
        item[st] = v
    end
    return tb_out
end

-- [剧情回顾id] 对应 [建筑id 和 状态] 的 map
function UIBuildComponentBuildItemData:_InitBuildDataStoryReviewIdMap(tb_in)
    local tb_out = {}
    for _, v in pairs(tb_in) do
        local reviewId = self:GetStoryReviewId(v)
        if reviewId then
            if tb_out[reviewId] then
                Log.exception(
                    "UIBuildComponentBuildItemData:_InitBuildDataStoryReviewIdMap()",
                    " repeat [StoryReviewId] in cfg_component_build_item",
                    " componentCfgID = " .. self._componentCfgID,
                    " StoryReviewId = " .. reviewId
                )
            end
            local id, st = self:GetItemIdAndStatus(v)
            tb_out[reviewId] = {["buildItemId"] = id, ["status"] = st}
        end
    end
    return tb_out
end

function UIBuildComponentBuildItemData:_InitBuildDataCostItemId(tb_in)
    for _, v in pairs(tb_in) do
        local itemId = self:GetCostItemId(v)
        if itemId then
            return itemId
        end
    end
end

function UIBuildComponentBuildItemData:GetBuildItemDataMap()
    return self._buildDataMap
end

-- 获取建筑列表
function UIBuildComponentBuildItemData:GetBuildItemIdList()
    local tb_out = table.keys(self._buildDataMap)
    return tb_out
end

-- 获取含有野餐状态的建筑列表
function UIBuildComponentBuildItemData:GetBuildItemIdList_Picnic()
    local tb_out = {}
    for k, v in pairs(self._buildDataMap) do
        if v[UIBuildComponentBuildStatus.Picnic] then
            table.insert(tb_out, k)
        end
    end
    return tb_out
end

-- 获取一个建筑的所有状态
function UIBuildComponentBuildItemData:GetBuildItemStatusList(buildItemId)
    local tb_out = table.keys(self._buildDataMap[buildItemId])
    table.sort(tb_out)
    return tb_out
end

function UIBuildComponentBuildItemData:GetBuildItemData(buildItemId, buildStatus)
    local data = self._buildDataMap[buildItemId][buildStatus]
    if not data then
        Log.exception(
            "UIBuildComponentBuildItemData:GetBuildItemData() buildItemId = ",
            buildItemId,
            " buildStatus = ",
            buildStatus
        )
    end
    return data
end

function UIBuildComponentBuildItemData:GetNeedBuildItemIdAndStatus(buildItemId, buildStatus)
    local data = self:GetBuildItemData(buildItemId, buildStatus)
    return self:GetNeedItemIdAndStatus(data)
end

function UIBuildComponentBuildItemData:GetBuildDataStoryReviewIdMap()
    return self._buildDataStoryReviewIdMap
end

function UIBuildComponentBuildItemData:GetBuildDataItemId()
    return self._buildDataItemId
end

--region parse data
function UIBuildComponentBuildItemData:GetItemIdAndStatus(cfg)
    return cfg.BuildItemId, cfg.BuildStatus
end

function UIBuildComponentBuildItemData:GetNeedItemIdAndStatus(cfg)
    return cfg.NeedItemId, cfg.NeedItemStatus
end

--物件描述位置
function UIBuildComponentBuildItemData:GetWidgetDesPos(cfg)
    return Vector2(cfg.WidgetDesPos[1], cfg.WidgetDesPos[2])
end

--获取控件位置
function UIBuildComponentBuildItemData:GetWidgetPos(cfg)
    return Vector2(cfg.WidgetPos[1], cfg.WidgetPos[2])
end

--获取图标位置
function UIBuildComponentBuildItemData:GetIconPos(cfg)
    return Vector2(cfg.IconConfig[1], cfg.IconConfig[2])
end

--获取图标宽度
function UIBuildComponentBuildItemData:GetIconWidth(cfg)
    return cfg.IconConfig[3]
end

--获取图标高度
function UIBuildComponentBuildItemData:GetIconHeight(cfg)
    return cfg.IconConfig[4]
end

--获取图标旋转
function UIBuildComponentBuildItemData:GetIconRotate(cfg)
    return cfg.IconConfig[5]
end

--获取触发区域位置
function UIBuildComponentBuildItemData:GetTriggerPos(cfg)
    return Vector2(cfg.TriggerArea[1], cfg.TriggerArea[2])
end

--获取触发区域宽度
function UIBuildComponentBuildItemData:GetTriggerWidth(cfg)
    return cfg.TriggerArea[3]
end

--获取触发区域高度
function UIBuildComponentBuildItemData:GetTriggerHeight(cfg)
    return cfg.TriggerArea[4]
end

--获取触发区域旋转
function UIBuildComponentBuildItemData:GetTriggerRotate(cfg)
    return cfg.TriggerArea[5]
end

--获取特效区域位置
function UIBuildComponentBuildItemData:GetEffectAreaPos(cfg)
    local x = cfg.EffectArea[1] or 0
    local y = cfg.EffectArea[2] or 0
    return Vector2(x, y)
end

--获取特效区域大小
function UIBuildComponentBuildItemData:GetEffectAreaScale(cfg)
    return cfg.EffectArea[3] and (cfg.EffectArea[3] / 100) or 1
end

--获取层级
function UIBuildComponentBuildItemData:GetLayer(cfg)
    return cfg.Layer
end

--建造花费
function UIBuildComponentBuildItemData:GetCost(cfg)
    return cfg.BuildCost
end

function UIBuildComponentBuildItemData:GetCostItemId(cfg)
    return cfg.BuildCost and cfg.BuildCost[1] and cfg.BuildCost[1][1]
end

function UIBuildComponentBuildItemData:GetCostCount(cfg)
    return cfg.BuildCost and cfg.BuildCost[1][1] and cfg.BuildCost[1][2]
end

--重建奖励
function UIBuildComponentBuildItemData:GetBuildReward(cfg)
    local tb_out = {}
    if cfg.BuildReward then
        for i = 1, #cfg.BuildReward do
            ---@type RoleAsset
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = cfg.BuildReward[i][1]
            roleAsset.count = cfg.BuildReward[i][2]
            table.insert(tb_out, roleAsset)
        end
    end
    return tb_out
end

--剧情Id
function UIBuildComponentBuildItemData:GetStoryId(cfg)
    return cfg.StoryId
end

--剧情类型
function UIBuildComponentBuildItemData:GetStoryType(cfg)
    return cfg.StoryType
end

--获取剧情回顾Id
function UIBuildComponentBuildItemData:GetStoryReviewId(cfg)
    return cfg.StoryReviewId
end

--状态名称
function UIBuildComponentBuildItemData:GetStatusName(cfg)
    return cfg.StatusName and StringTable.Get(cfg.StatusName) or ""
end

--状态描述
function UIBuildComponentBuildItemData:GetDes(cfg)
    return cfg.Des and StringTable.Get(cfg.Des) or ""
end

--状态图标
function UIBuildComponentBuildItemData:GetIcon(cfg)
    return cfg.Icon or ""
end

function UIBuildComponentBuildItemData:GetSpine(cfg)
    if not cfg.SpineName then
        return
    end
    local name = cfg.SpineName[1] or ""
    local ani = cfg.SpineName[2] or ""
    return name, ani
end

--建筑名称
function UIBuildComponentBuildItemData:GetName(cfg)
    return StringTable.Get(cfg.Name)
end

--是否显示
function UIBuildComponentBuildItemData:IsShow(cfg)
    return cfg.IsShow == 1
end

--获取建造提示界面的图标
function UIBuildComponentBuildItemData:GetTipsIcon(cfg)
    return cfg.TipsIcon
end
--endregion
