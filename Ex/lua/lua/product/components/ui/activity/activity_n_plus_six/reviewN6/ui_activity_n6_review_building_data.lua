--[[
    配置说明：
    1.NeedItemId和NeedItemStaus表示当前状态解锁的条件（控制上一个状态能否跳到该状态）
    2.BuildCost表示上一状态到当前状态需要的花费
    3.StoryType和StoryId表示当前状态结束的时候播放的剧情和剧情类型
]]
_class("UIActivityN6ReviewBuildingStatusData", Object)
---@class UIActivityN6ReviewBuildingStatusData:Object
UIActivityN6ReviewBuildingStatusData = UIActivityN6ReviewBuildingStatusData

---@param localProcess CCampaingN6
function UIActivityN6ReviewBuildingStatusData:Constructor(cfg, localProcess)
    if not cfg then
        return
    end
    ---@type CCampaingN6
    self._localProcess = localProcess
    ---@type UIActivityNPlusSixBuildingStatus
    self._status = cfg.BuildStatus --状态
    ---@type UIActivityN6ReviewBuildingCondition
    self._condition = UIActivityN6ReviewBuildingCondition:New(cfg, self._localProcess) --解锁条件
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
function UIActivityN6ReviewBuildingStatusData:GetWidgetDesPos()
    return self._widgetDesPos
end

--获取控件位置
function UIActivityN6ReviewBuildingStatusData:GetWidgetPos()
    return self._widgetPos
end

--获取图标位置
function UIActivityN6ReviewBuildingStatusData:GetIconPos()
    return self._iconPos
end

--获取图标宽度
function UIActivityN6ReviewBuildingStatusData:GetIconWidth()
    return self._iconWidth
end

--获取图标高度
function UIActivityN6ReviewBuildingStatusData:GetIconHeight()
    return self._iconHeight
end

--获取图标旋转
function UIActivityN6ReviewBuildingStatusData:GetIconRotate()
    return self._iconRotate
end

--获取触发区域位置
function UIActivityN6ReviewBuildingStatusData:GetTriggerPos()
    return self._triggerPos
end

--获取触发区域宽度
function UIActivityN6ReviewBuildingStatusData:GetTriggerWidth()
    return self._triggerWidth
end

--获取触发区域高度
function UIActivityN6ReviewBuildingStatusData:GetTriggerHeight()
    return self._triggerHeight
end

--获取触发区域旋转
function UIActivityN6ReviewBuildingStatusData:GetTriggerRotate()
    return self._triggerRotate
end

--获取层级
function UIActivityN6ReviewBuildingStatusData:GetLayer()
    return self._layer
end

--状态
function UIActivityN6ReviewBuildingStatusData:GetStatus()
    return self._status
end

--解锁条件
function UIActivityN6ReviewBuildingStatusData:GetCondition()
    return self._condition
end

--建造花费
function UIActivityN6ReviewBuildingStatusData:GetCost()
    return self._cost
end

--剧情Id
function UIActivityN6ReviewBuildingStatusData:GetStoryId()
    return self._storyId
end

--剧情类型
function UIActivityN6ReviewBuildingStatusData:GetStoryType()
    return self._storyType
end

--获取剧情回顾Id
function UIActivityN6ReviewBuildingStatusData:GetStoryReviewId()
    return self._storyReviewId
end

--状态名称
function UIActivityN6ReviewBuildingStatusData:GetStatusName()
    return self._statusName
end

--状态描述
function UIActivityN6ReviewBuildingStatusData:GetDes()
    return self._des
end
    
--状态图标
function UIActivityN6ReviewBuildingStatusData:GetIcon()
    return self._icon
end

--建筑名称
function UIActivityN6ReviewBuildingStatusData:GetName()
    return self._name
end

--是否显示
function UIActivityN6ReviewBuildingStatusData:IsShow()
    return self._isShow
end

---@param buildingDatas UIActivityN6ReviewBuildingDatas
function UIActivityN6ReviewBuildingStatusData:IsUnLock(buildingDatas)
    if not self._condition then
        return true
    end
    return self._condition:IsUnLock(buildingDatas)
end

--获取建造提示界面的图标
function UIActivityN6ReviewBuildingStatusData:GetTipsIcon()
    return self._tipsIcon
end

_class("UIActivityN6ReviewBuildingData", Object)
---@class UIActivityN6ReviewBuildingData:Object
UIActivityN6ReviewBuildingData = UIActivityN6ReviewBuildingData

function UIActivityN6ReviewBuildingData:Constructor(buildingDatas, buildingId, cfgs, localProcess)
    if cfgs == nil then
        return
    end
    ---@type CCampaingN6
    self._localProcess = localProcess
    ---@type CampaignBuildComponent
    self._buildComponent = self._localProcess:GetComponent(ECampaignReviewN6ComponentID.BUILD)
    ---@type BuildComponentInfo
    self._buildComponentInfo = self._localProcess:GetComponentInfo(ECampaignReviewN6ComponentID.BUILD)
    ---@type UIActivityN6ReviewBuildingDatas
    self._buildingDatas = buildingDatas
    self._buildingId = buildingId
    self._statusDatas = {}
    for k, v in pairs(cfgs) do
        self._statusDatas[#self._statusDatas + 1] = UIActivityN6ReviewBuildingStatusData:New(v, self._localProcess)
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
    ---@type UIActivityN6ReviewBuildingStatusData
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

function UIActivityN6ReviewBuildingData:GetUnPlayStoryList()
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
                ---@type UIActivityN6ReviewBuildingStatusData
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
                ---@type UIActivityN6ReviewBuildingStatusData
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
                ---@type UIActivityN6ReviewBuildingStatusData
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

function UIActivityN6ReviewBuildingData:GetBuildingComponent()
    return self._buildComponent
end

function UIActivityN6ReviewBuildingData:GetBuildingComponentInfo()
    return self._buildComponentInfo
end

--建筑id
function UIActivityN6ReviewBuildingData:GetBuildingId()
    return self._buildingId
end

--是否已经解锁了状态
---@param status UIActivityNPlusSixBuildingStatus
function UIActivityN6ReviewBuildingData:IsUnLockStatus(status)
    return self:GetStatusType() >= status
end

--状态类型
function UIActivityN6ReviewBuildingData:GetStatusType()
    return self._currentStatus:GetStatus()
end

--当前状态
function UIActivityN6ReviewBuildingData:GetStatus()
    return self._currentStatus
end

--当前状态数据
function UIActivityN6ReviewBuildingData:GetStatusData()
    if #self._statusDatas <= 0 then
        return nil
    end
    return self._statusDatas[self._currentStatusIndex]
end

--是否可以建造
function UIActivityN6ReviewBuildingData:CanBuild()
    if #self._statusDatas <= 0 then
        return false
    end
    return self._currentStatusIndex < #self._statusDatas
end

function UIActivityN6ReviewBuildingData:IsComplete()
    if #self._statusDatas <= 0 then
        return true
    end
    return self._currentStatusIndex >= #self._statusDatas
end

--建筑名称
function UIActivityN6ReviewBuildingData:GetName()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetName()
end

--状态名称
function UIActivityN6ReviewBuildingData:GetStatusName()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetStatusName()
end

--状态图标
function UIActivityN6ReviewBuildingData:GetIcon()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetIcon()
end

--状态描述
function UIActivityN6ReviewBuildingData:GetDes()
    if not self._currentStatus then
        return ""
    end
    return self._currentStatus:GetDes()
end

--建造花费
function UIActivityN6ReviewBuildingData:GetCost()
    ---@type UIActivityN6ReviewBuildingStatusData
    local nextStatusData = self:GetNextStatusData()
    if not nextStatusData then
        return nil
    end
    return nextStatusData:GetCost()
end

--剧情Id
function UIActivityN6ReviewBuildingData:GetCompleteStoryId()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetStoryId()
end

--剧情类型
function UIActivityN6ReviewBuildingData:GetCompleteStoryType()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetStoryType()
end

--是否显示
function UIActivityN6ReviewBuildingData:IsShow()
    if not self._currentStatus then
        return false
    end
    if self._currentStatus:IsUnLock(self._buildingDatas) then
        return true
    end
    return self._currentStatus:IsShow()
end

--是否解锁
function UIActivityN6ReviewBuildingData:IsUnLock()
    if not self._currentStatus then
        return true
    end
    return self._currentStatus:IsUnLock(self._buildingDatas)
end

--下一状态是否解锁
function UIActivityN6ReviewBuildingData:IsNextStatusUnLock()
    ---@type UIActivityN6ReviewBuildingStatusData
    local nextStatusData = self:GetNextStatusData()
    if not nextStatusData then
        return nil
    end
    return nextStatusData:IsUnLock(self._buildingDatas)
end

--下一状态数据
function UIActivityN6ReviewBuildingData:GetNextStatusData()
    if #self._statusDatas <= 0 then
        return nil
    end
    if self._currentStatusIndex >= #self._statusDatas then
        return nil
    end
    return self._statusDatas[self._currentStatusIndex + 1]
end

--获取下一状态
function UIActivityN6ReviewBuildingData:GetNextStatus()
    local status = self:GetNextStatusData()
    if not status then
        return nil
    end
    return status:GetStatus()
end

--升级到下一状态
function UIActivityN6ReviewBuildingData:BuildingLevelUp()
    if #self._statusDatas <= 0 then
        return
    end
    if self._currentStatusIndex >= #self._statusDatas then
        return
    end
    self._currentStatusIndex = self._currentStatusIndex + 1
    self._currentStatus = self._statusDatas[self._currentStatusIndex]
end

function UIActivityN6ReviewBuildingData:GetStatusByStatusType(status)
    for i = 1, #self._statusDatas do
        if self._statusDatas[i]:GetStatus() == status then
            return self._statusDatas[i]
        end
    end
    return nil
end

function UIActivityN6ReviewBuildingData:GetCanReviewStory()
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
function UIActivityN6ReviewBuildingData:GetWidgetDesPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetWidgetDesPos()
end

--获取控件位置
function UIActivityN6ReviewBuildingData:GetWidgetPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetWidgetPos()
end

--获取图标位置
function UIActivityN6ReviewBuildingData:GetIconPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetIconPos()
end

--获取图标宽度
function UIActivityN6ReviewBuildingData:GetIconWidth()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconWidth()
end

--获取图标高度
function UIActivityN6ReviewBuildingData:GetIconHeight()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconHeight()
end

--获取图标旋转
function UIActivityN6ReviewBuildingData:GetIconRotate()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetIconRotate()
end

--获取触发区域位置
function UIActivityN6ReviewBuildingData:GetTriggerPos()
    if not self._currentStatus then
        return Vector2(0, 0)
    end
    return self._currentStatus:GetTriggerPos()
end

--获取触发区域宽度
function UIActivityN6ReviewBuildingData:GetTriggerWidth()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerWidth()
end

--获取触发区域高度
function UIActivityN6ReviewBuildingData:GetTriggerHeight()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerHeight()
end

--获取触发区域旋转
function UIActivityN6ReviewBuildingData:GetTriggerRotate()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetTriggerRotate()
end

--获取层级
function UIActivityN6ReviewBuildingData:GetLayer()
    if not self._currentStatus then
        return 0
    end
    return self._currentStatus:GetLayer()
end

_class("UIActivityN6ReviewBuildingDatas", Object)
---@class UIActivityN6ReviewBuildingDatas:Object
UIActivityN6ReviewBuildingDatas = UIActivityN6ReviewBuildingDatas

---@param localProcess CCampaingN6
function UIActivityN6ReviewBuildingDatas:Constructor(componentId, localProcess)
    self._localProcess = localProcess
    ---@type UIActivityN6ReviewBuildingData
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
        self._buildingList[k] = UIActivityN6ReviewBuildingData:New(self, k, v, self._localProcess)
    end
end

function UIActivityN6ReviewBuildingDatas:GetBuildingList()
    return self._buildingList
end

function UIActivityN6ReviewBuildingDatas:GetBuilding(buildingId)
    return self._buildingList[buildingId]
end

function UIActivityN6ReviewBuildingDatas:IsUnLock(buildingId)
    ---@type UIActivityN6ReviewBuildingData
    local buildingData = self._buildingList[buildingId]
    return buildingData:IsUnLock()
end

function UIActivityN6ReviewBuildingDatas:GetUnPlayStoryList()
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
function UIActivityN6ReviewBuildingDatas:HaveCanBuilding(itemCount)
    for k, v in pairs(self._buildingList) do
        ---@type UIActivityN6ReviewBuildingData
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
function UIActivityN6ReviewBuildingDatas:IsAllBuildingComplete()
    for k, v in pairs(self._buildingList) do
        ---@type UIActivityN6ReviewBuildingData
        local buildingData = v
        if not buildingData:IsComplete() then
            return false
        end
    end
    return true
end

function UIActivityN6ReviewBuildingDatas:IsFirstEnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    local value = UnityEngine.PlayerPrefs.GetInt(key, 0)
    return value == 0
end

function UIActivityN6ReviewBuildingDatas:EnterBuilding()
    local key = self:GetFirstEnterBuildingKey()
    UnityEngine.PlayerPrefs.SetInt(key, 1)
end

function UIActivityN6ReviewBuildingDatas:GetFirstEnterBuildingKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. "FirstEnterN6ReviewBuilding"
    return key
end

function UIActivityN6ReviewBuildingDatas:GetCanReviewStory()
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
