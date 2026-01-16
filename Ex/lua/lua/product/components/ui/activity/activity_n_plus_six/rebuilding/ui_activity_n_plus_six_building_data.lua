local UIActivityNPlusSixBuildingStatus = {
    CleanUp = 0, --待除尘状态
    CleanUpComplete = 1, --除尘完成，待修复状态
    RepairComplete = 2, --修复完成，待装饰状态
    DecorateComplete = 4 --装饰完成
}
---@class UIActivityNPlusSixBuildingStatus:UIActivityNPlusSixBuildingStatus
_enum("UIActivityNPlusSixBuildingStatus", UIActivityNPlusSixBuildingStatus)

--[[
    配置说明：
    1.NeedItemId和NeedItemStaus表示当前状态解锁的条件（控制上一个状态能否跳到该状态）
    2.BuildCost表示上一状态到当前状态需要的花费
    3.StoryType和StoryId表示当前状态结束的时候播放的剧情和剧情类型
]]
_class("UIActivityNPlusSixBuildingStatusData", Object)
---@class UIActivityNPlusSixBuildingStatusData:Object
UIActivityNPlusSixBuildingStatusData = UIActivityNPlusSixBuildingStatusData

---@param localProcess CCampaingN6
function UIActivityNPlusSixBuildingStatusData:Constructor(cfg, localProcess)
    if not cfg then
        return
    end
    ---@type CCampaingN6
    self._localProcess = localProcess
    ---@type UIActivityNPlusSixBuildingStatus
    self._status = cfg.BuildStatus --状态
    ---@type UIActivityNPlusSixBuildingCondition
    self._condition = UIActivityNPlusSixBuildingCondition:New(cfg, self._localProcess) --解锁条件
    self._cost = cfg.BuildCost --完成此状态的消耗
    self._storyId = cfg.StoryId --完成此状态后的剧情id
    self._storyType = cfg.StoryType --剧情类型, 1:纯局外立绘对话 2:通用的剧情形式 3:终端对话
    self._storyReviewId = cfg.StoryReviewId --剧情回顾Id
    self._statusName = "" --此状态的名字
    if cfg.StatusName then
        self._statusName = StringTable.Get(cfg.StatusName)
    end
    self._des = "" --此状态的描述
    if cfg.Des  then
        self._des = StringTable.Get(cfg.Des)
    end
    self._icon = "" --此状态的图标
    if cfg.Icon then
        self._icon = cfg.Icon
    end
    self._name = StringTable.Get(cfg.Name) --名字
    self._isShow = cfg.IsShow == 1
    
    local widgetPos = cfg.WidgetPos
    self._widgetPos = Vector2(widgetPos[1], widgetPos[2])
    local iconConfig = cfg.IconConfig
    self._iconPos = Vector2(iconConfig[1], iconConfig[2])
    self._iconWidth = iconConfig[3]
    self._iconHeight = iconConfig[4]
    self._iconRotate = iconConfig[5]
    local triggerArea = cfg.TriggerArea
    self._triggerPos = Vector2(triggerArea[1], triggerArea[2])
    self._triggerWidth = triggerArea[3]
    self._triggerHeight = triggerArea[4]
    self._triggerRotate = triggerArea[5]
    local widgetDesPos = cfg.WidgetDesPos
    self._widgetDesPos = Vector2(widgetDesPos[1], widgetDesPos[2])
    self._layer = cfg.Layer

    self._tipsIcon = cfg.TipsIcon
end

--物件描述位置
function UIActivityNPlusSixBuildingStatusData:GetWidgetDesPos()
    return self._widgetDesPos
end

--获取控件位置
function UIActivityNPlusSixBuildingStatusData:GetWidgetPos()
    return self._widgetPos
end

--获取图标位置
function UIActivityNPlusSixBuildingStatusData:GetIconPos()
    return self._iconPos
end

--获取图标宽度
function UIActivityNPlusSixBuildingStatusData:GetIconWidth()
    return self._iconWidth
end

--获取图标高度
function UIActivityNPlusSixBuildingStatusData:GetIconHeight()
    return self._iconHeight
end

--获取图标旋转
function UIActivityNPlusSixBuildingStatusData:GetIconRotate()
    return self._iconRotate
end

--获取触发区域位置
function UIActivityNPlusSixBuildingStatusData:GetTriggerPos()
    return self._triggerPos
end

--获取触发区域宽度
function UIActivityNPlusSixBuildingStatusData:GetTriggerWidth()
    return self._triggerWidth
end

--获取触发区域高度
function UIActivityNPlusSixBuildingStatusData:GetTriggerHeight()
    return self._triggerHeight
end

--获取触发区域旋转
function UIActivityNPlusSixBuildingStatusData:GetTriggerRotate()
    return self._triggerRotate
end

--获取层级
function UIActivityNPlusSixBuildingStatusData:GetLayer()
    return self._layer
end

--状态
function UIActivityNPlusSixBuildingStatusData:GetStatus()
    return self._status
end

--解锁条件
function UIActivityNPlusSixBuildingStatusData:GetCondition()
    return self._condition
end

--建造花费
function UIActivityNPlusSixBuildingStatusData:GetCost()
    return self._cost
end

--剧情Id
function UIActivityNPlusSixBuildingStatusData:GetStoryId()
    return self._storyId
end

--剧情类型
function UIActivityNPlusSixBuildingStatusData:GetStoryType()
    return self._storyType
end

--获取剧情回顾Id
function UIActivityNPlusSixBuildingStatusData:GetStoryReviewId()
    return self._storyReviewId
end

--状态名称
function UIActivityNPlusSixBuildingStatusData:GetStatusName()
    return self._statusName
end

--状态描述
function UIActivityNPlusSixBuildingStatusData:GetDes()
    return self._des
end
    
--状态图标
function UIActivityNPlusSixBuildingStatusData:GetIcon()
    return self._icon
end

--建筑名称
function UIActivityNPlusSixBuildingStatusData:GetName()
    return self._name
end

--是否显示
function UIActivityNPlusSixBuildingStatusData:IsShow()
    return self._isShow
end

---@param buildingDatas UIActivityNPlusSixBuildingDatas
function UIActivityNPlusSixBuildingStatusData:IsUnLock(buildingDatas)
    if not self._condition then
        return true
    end
    return self._condition:IsUnLock(buildingDatas)
end

--获取建造提示界面的图标
function UIActivityNPlusSixBuildingStatusData:GetTipsIcon()
    return self._tipsIcon
end

_class("UIActivityNPlusSixBuildingData", Object)
---@class UIActivityNPlusSixBuildingData:Object
UIActivityNPlusSixBuildingData = UIActivityNPlusSixBuildingData

function UIActivityNPlusSixBuildingData:Constructor(buildingDatas, buildingId, cfgs, localProcess)
    if cfgs == nil then
        return
    end
    ---@type CCampaingN6
    self._localProcess = localProcess
    ---@type CampaignBuildComponent
    self._buildComponent = self._localProcess:GetComponent(ECampaignN6ComponentID.ECAMPAIGN_N6_BUILD)
    ---@type BuildComponentInfo
    self._buildComponentInfo = self._localProcess:GetComponentInfo(ECampaignN6ComponentID.ECAMPAIGN_N6_BUILD)
    ---@type UIActivityNPlusSixBuildingDatas
    self._buildingDatas = buildingDatas
    self._buildingId = buildingId
    self._statusDatas = {}
    for k, v in pairs(cfgs) do
        self._statusDatas[#self._statusDatas + 1] = UIActivityNPlusSixBuildingStatusData:New(v, self._localProcess)
    end
    table.sort(self._statusDatas, function(a, b)
       return a:GetStatus() < b:GetStatus() 
    end)
    --初始化建筑状态
    local status = self._statusDatas[1]:GetStatus()
    local buildItemInfos = self._buildComponentInfo.build_item_infos
    ---@type BuildItemInfo
    local buildingInfo = buildItemInfos[buildingId]
    if buildingInfo then
        local mask = buildingInfo.mask
        if mask == 0 then
            status = UIActivityNPlusSixBuildingStatus.CleanUp
        elseif (mask & 4) > 0 then
            status = UIActivityNPlusSixBuildingStatus.DecorateComplete
        elseif (mask & 2) > 0 then
            status = UIActivityNPlusSixBuildingStatus.RepairComplete
        elseif (mask & 1) > 0 then
            status = UIActivityNPlusSixBuildingStatus.CleanUpComplete
        end
    end
    ---@type UIActivityNPlusSixBuildingStatusData
    self._currentStatus = nil
    self._currentStatusIndex = 0
    for i = 1, #self._statusDatas do
        if self._statusDatas[i]:GetStatus() == status then
            self._currentStatusIndex = i
            self._currentStatus = self._statusDatas[i]
            break
        end
    end
end

function UIActivityNPlusSixBuildingData:GetUnPlayStoryList()
    local storyList = {}
    --初始化建筑状态
    local buildItemInfos = self._buildComponentInfo.build_item_infos
    ---@type BuildItemInfo
    local buildingInfo = buildItemInfos[self._buildingId]
    if buildingInfo then
        local mask = buildingInfo.mask
        local storyMask = buildingInfo.story_mask
        if (mask & 4) > 0 then
            if (storyMask & 4) == 0 then
                ---@type UIActivityNPlusSixBuildingStatusData
                local statusData = self:GetStatusByStatusType(UIActivityNPlusSixBuildingStatus.RepairComplete)
                local storyType = statusData:GetStoryType()
                local storyId = statusData:GetStoryId()
                if storyId and storyId > 0 then
                    storyList[#storyList + 1] = {storyType, storyId, UIActivityNPlusSixBuildingStatus.RepairComplete, self._buildingId}
                end
            end
        end
        if (mask & 2) > 0 then
            if (storyMask & 2) == 0 then
                ---@type UIActivityNPlusSixBuildingStatusData
                local statusData = self:GetStatusByStatusType(UIActivityNPlusSixBuildingStatus.CleanUpComplete)
                local storyType = statusData:GetStoryType()
                local storyId = statusData:GetStoryId()
                if storyId and storyId > 0 then
                   storyList[#storyList + 1] = {storyType, storyId, UIActivityNPlusSixBuildingStatus.CleanUpComplete, self._buildingId}
                end
            end
        end
        if (mask & 1) > 0 then
            if (storyMask & 1) == 0 then
                ---@type UIActivityNPlusSixBuildingStatusData
                local statusData = self:GetStatusByStatusType(UIActivityNPlusSixBuildingStatus.CleanUp)
                local storyType = statusData:GetStoryType()
                local storyId = statusData:GetStoryId()
                if storyId and storyId > 0 then
                    storyList[#storyList + 1] = {storyType, storyId, UIActivityNPlusSixBuildingStatus.CleanUp, self._buildingId}
                end
            end
        end
    end
    return storyList
end

function UIActivityNPlusSixBuildingData:GetBuildingComponent()
    return self._buildComponent
end

function UIActivityNPlusSixBuildingData:GetBuildingComponentInfo()
    return self._buildComponentInfo
end

--建筑id
function UIActivityNPlusSixBuildingData:GetBuildingId()
    return self._buildingId
end

--是否已经解锁了状态
---@param status UIActivityNPlusSixBuildingStatus
function UIActivityNPlusSixBuildingData:IsUnLockStatus(status)
    return self:GetStatusType() >= status
end

--状态类型
function UIActivityNPlusSixBuildingData:GetStatusType()
    return self._currentStatus:GetStatus()
end

--当前状态
function UIActivityNPlusSixBuildingData:GetStatus()
    return self._currentStatus
end

--当前状态数据
function UIActivityNPlusSixBuildingData:GetStatusData()
    if #self._statusDatas <= 0 then
        return nil
    end
    return self._statusDatas[self._currentStatusIndex]
end

--是否可以建造
function UIActivityNPlusSixBuildingData:CanBuild()
    if #self._statusDatas <= 0 then
        return false
    end
    return self._currentStatusIndex < #self._statusDatas
end

function UIActivityNPlusSixBuildingData:IsComplete()
    if #self._statusDatas <= 0 then
        return true
    end
    return self._currentStatusIndex >= #self._statusDatas
end

--建筑名称
function UIActivityNPlusSixBuildingData:GetName()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetName()
end

--状态名称
function UIActivityNPlusSixBuildingData:GetStatusName()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetStatusName()
end

--状态图标
function UIActivityNPlusSixBuildingData:GetIcon()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetIcon()
end

--状态描述
function UIActivityNPlusSixBuildingData:GetDes()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetDes()
end

--建造花费
function UIActivityNPlusSixBuildingData:GetCost()
    ---@type UIActivityNPlusSixBuildingStatusData
    local nextStatusData = self:GetNextStatusData()
    if not nextStatusData then
        return nil
    end
    return nextStatusData:GetCost()
end

--剧情Id
function UIActivityNPlusSixBuildingData:GetCompleteStoryId()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetStoryId()
end

--剧情类型
function UIActivityNPlusSixBuildingData:GetCompleteStoryType()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetStoryType()
end

--是否显示
function UIActivityNPlusSixBuildingData:IsShow()
    if not self._currentStatus then
        return false
    end
    if self._currentStatus:IsUnLock(self._buildingDatas) then
        return true
    end
    return self._currentStatus:IsShow()
end

--是否解锁
function UIActivityNPlusSixBuildingData:IsUnLock()
    if not self._currentStatus then
        return true
    end
    return self._currentStatus:IsUnLock(self._buildingDatas)
end

--下一状态是否解锁
function UIActivityNPlusSixBuildingData:IsNextStatusUnLock()
    ---@type UIActivityNPlusSixBuildingStatusData
    local nextStatusData = self:GetNextStatusData()
    if not nextStatusData then
        return nil
    end
    return nextStatusData:IsUnLock(self._buildingDatas)
end

--下一状态数据
function UIActivityNPlusSixBuildingData:GetNextStatusData()
    if #self._statusDatas <= 0 then
        return nil
    end
    if self._currentStatusIndex >= #self._statusDatas then
        return nil
    end
    return self._statusDatas[self._currentStatusIndex + 1]
end

--获取下一状态
function UIActivityNPlusSixBuildingData:GetNextStatus()
    local status = self:GetNextStatusData()
    if not status then
        return nil
    end
    return status:GetStatus()
end

--升级到下一状态
function UIActivityNPlusSixBuildingData:BuildingLevelUp()
    if #self._statusDatas <= 0 then
        return
    end
    if self._currentStatusIndex >= #self._statusDatas then
        return
    end
    self._currentStatusIndex = self._currentStatusIndex + 1
    self._currentStatus = self._statusDatas[self._currentStatusIndex]
end

function UIActivityNPlusSixBuildingData:GetStatusByStatusType(status)
    for i = 1, #self._statusDatas do
        if self._statusDatas[i]:GetStatus() == status then
            return self._statusDatas[i]
        end
    end
    return nil
end

function UIActivityNPlusSixBuildingData:GetCanReviewStory()
    local ids = {}
    for i = 1, self._currentStatusIndex - 1 do
        local id = self._statusDatas[i]:GetStoryReviewId()
        if id and id > 0 then
            ids[#ids + 1] = id
        end
    end
    return ids
end

--获取控件描述位置
function UIActivityNPlusSixBuildingData:GetWidgetDesPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetWidgetDesPos()
end

--获取控件位置
function UIActivityNPlusSixBuildingData:GetWidgetPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetWidgetPos()
end

--获取图标位置
function UIActivityNPlusSixBuildingData:GetIconPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetIconPos()
end

--获取图标宽度
function UIActivityNPlusSixBuildingData:GetIconWidth()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconWidth()
end

--获取图标高度
function UIActivityNPlusSixBuildingData:GetIconHeight()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconHeight()
end

--获取图标旋转
function UIActivityNPlusSixBuildingData:GetIconRotate()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconRotate()
end

--获取触发区域位置
function UIActivityNPlusSixBuildingData:GetTriggerPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetTriggerPos()
end

--获取触发区域宽度
function UIActivityNPlusSixBuildingData:GetTriggerWidth()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerWidth()
end

--获取触发区域高度
function UIActivityNPlusSixBuildingData:GetTriggerHeight()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerHeight()
end

--获取触发区域旋转
function UIActivityNPlusSixBuildingData:GetTriggerRotate()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerRotate()
end

--获取层级
function UIActivityNPlusSixBuildingData:GetLayer()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetLayer()
end

_class("UIActivityNPlusSixBuildingDatas", Object)
---@class UIActivityNPlusSixBuildingDatas:Object
UIActivityNPlusSixBuildingDatas = UIActivityNPlusSixBuildingDatas

---@param localProcess CCampaingN6
function UIActivityNPlusSixBuildingDatas:Constructor(componentId, localProcess)
    self._localProcess = localProcess
    ---@type UIActivityNPlusSixBuildingData
    self._buildingList = {}
    local cfgs = Cfg.cfg_component_build_item {ComponentID = componentId}
    if not cfgs then
        return
    end
    if table.count(cfgs) <= 0 then
        return
    end
    local buildingCfgs = {}
    for k, v in pairs(cfgs) do
        local buildingId = v.BuildItemId
        local buildingCfg = buildingCfgs[buildingId]
        if not buildingCfg then
            buildingCfg = {}
            buildingCfgs[buildingId] = buildingCfg
        end
        buildingCfg[#buildingCfg + 1] = v
    end
    for k, v in pairs(buildingCfgs) do
        self._buildingList[k] = UIActivityNPlusSixBuildingData:New(self, k, v, self._localProcess)
    end
end

function UIActivityNPlusSixBuildingDatas:GetBuildingList()
    return self._buildingList
end

function UIActivityNPlusSixBuildingDatas:GetBuilding(buildingId)
    return self._buildingList[buildingId]
end

function UIActivityNPlusSixBuildingDatas:IsUnLock(buildingId)
    ---@type UIActivityNPlusSixBuildingData
    local buildingData = self._buildingList[buildingId]
    return buildingData:IsUnLock()
end

function UIActivityNPlusSixBuildingDatas:GetUnPlayStoryList()
    local storyList = {}
    for k, v in pairs(self._buildingList) do
        local storys = v:GetUnPlayStoryList()
        for j = 1, #storys do
            storyList[#storyList + 1] = storys[j]
        end
    end
    return storyList
end

--是否有可以建造的建筑
function UIActivityNPlusSixBuildingDatas:HaveCanBuilding(itemCount)
    for k, v in pairs(self._buildingList) do
        ---@type UIActivityNPlusSixBuildingData
        local buildingData = v
        if buildingData:CanBuild() and buildingData:IsUnLock() and buildingData:IsNextStatusUnLock() then
            local costCfg = buildingData:GetCost()
            local cost = 0
            if costCfg and costCfg[1] and costCfg[1][2] then
                cost = costCfg[1][2]
            end
            if itemCount >= cost then
                return true
            end
        end
    end
    return false
end

--是否所有建筑都建造完毕
function UIActivityNPlusSixBuildingDatas:IsAllBuildingComplete()
    for k, v in pairs(self._buildingList) do
        ---@type UIActivityNPlusSixBuildingData
        local buildingData = v
        if not buildingData:IsComplete() then
            return false
        end
    end
    return true
end

function UIActivityNPlusSixBuildingDatas:IsFirstEnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    local value = UnityEngine.PlayerPrefs.GetInt(key, 0)
    return value == 0
end

function UIActivityNPlusSixBuildingDatas:EnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIActivityNPlusSixBuildingDatas:GetFirstEnterBuildingKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "FirstEnterNPlusSixBuilding"
    return key
end

function UIActivityNPlusSixBuildingDatas:GetCanReviewStory()
    local results = {}
    for k, v in pairs(self._buildingList) do
        local ids = v:GetCanReviewStory()
        for i = 1, #ids do
            results[#results + 1] = ids[i]
        end
    end
    table.sort(results, function(a, b)
       return a < b
    end)
    return results
end
