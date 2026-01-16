-- local UIActivityNPlusSixBuildingStatus = {
--     CleanUp = 0, --待除尘状态
--     CleanUpComplete = 1, --除尘完成，待修复状态
--     RepairComplete = 2, --修复完成，待装饰状态
--     DecorateComplete = 4 --装饰完成
-- }
-- ---@class UIActivityNPlusSixBuildingStatus:UIActivityNPlusSixBuildingStatus
-- _enum("UIActivityNPlusSixBuildingStatus", UIActivityNPlusSixBuildingStatus)

_class("UIActivityNPlusSixEventData", Object)
---@class UIActivityNPlusSixEventData:Object
UIActivityNPlusSixEventData = UIActivityNPlusSixEventData

function UIActivityNPlusSixEventData:Constructor(eventId)
    local cfg = Cfg.cfg_component_build_event[eventId]
    if not cfg then
        return
    end
    self._eventId = eventId
    --事件类型
    self._type = cfg.Type --1：清扫2：收集3：驱赶
    --事件奖励
    self._rewards = {}
    if cfg.Reward then
        for i = 1, #cfg.Reward do
            local reward = RoleAsset:New()
            reward.assetid = cfg.Reward[i][1]
            reward.count = cfg.Reward[i][2]
            self._rewards[#self._rewards + 1] = reward
        end
    end
    self._name = ""
    if cfg.Name then
        self._name= StringTable.Get(cfg.Name)
    end
    self._title = ""
    if cfg.Title then
        self._title = StringTable.Get(cfg.Title)
    end
    self._des = ""
    if cfg.Des then
        self._des = StringTable.Get(cfg.Des)
    end
    local posConfig = cfg.MapPos
    self._posX = posConfig[1]
    self._posY = posConfig[2]
    self._spineName = cfg.SpineName
    self._idleAnimName = cfg.IdleAnimName
    self._completeAnimName = cfg.CompleteAnimName
    self._completAnimLength = cfg.CompleteAnimLength
    local triggerArea = cfg.TriggerArea
    self._triggerPosX = triggerArea[1]
    self._triggerPosY = triggerArea[2]
    self._triggerWidth = triggerArea[3]
    self._triggerHeight = triggerArea[4]
    self._height = cfg.Height
end

--事件Id
function UIActivityNPlusSixEventData:GetEventId()
    return self._eventId
end

 --事件类型 1：清扫2：收集3：驱赶
function UIActivityNPlusSixEventData:GetType()
    return self._type
end

--事件奖励
function UIActivityNPlusSixEventData:GetRewards()
    return self._rewards
end

--任务名称
function UIActivityNPlusSixEventData:GetName()
    return self._name
end

--事件标题
function UIActivityNPlusSixEventData:GetTitle()
    return self._title
end

--事件标题
function UIActivityNPlusSixEventData:GetDes()
    return self._des
end

--事件X方向位置
function UIActivityNPlusSixEventData:GetPosX()
    return self._posX
end

--事件Y方向位置
function UIActivityNPlusSixEventData:GetPosY()
    return self._posY
end

--事件Spine资源名称
function UIActivityNPlusSixEventData:GetSpineName()
    return self._spineName
end

--待机动画
function UIActivityNPlusSixEventData:GetIdleAnimName()
    return self._idleAnimName
end

--事件完成动画
function UIActivityNPlusSixEventData:GetCompleteAnimName()
    return self._completeAnimName
end

--事件完成动画时长
function UIActivityNPlusSixEventData:GetCompleteAnimLength()
    return self._completAnimLength
end

--事件触发区域X方向位置
function UIActivityNPlusSixEventData:GetTriggerAreaPosX()
    return self._triggerPosX
end

--事件触发区域Y方向位置
function UIActivityNPlusSixEventData:GetTriggerAreaPosY()
    return self._triggerPosY
end

--事件点击区域宽度
function UIActivityNPlusSixEventData:GetTriggerAreaWidth()
    return self._triggerWidth
end

--事件点击区域高度
function UIActivityNPlusSixEventData:GetTriggerAreaHeight()
    return self._triggerHeight
end
