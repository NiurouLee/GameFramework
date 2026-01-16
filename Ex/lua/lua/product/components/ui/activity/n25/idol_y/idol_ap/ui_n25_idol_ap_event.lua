---@class UIN25IdolApEvent:UICustomWidget
_class("UIN25IdolApEvent", UICustomWidget)
UIN25IdolApEvent = UIN25IdolApEvent
function UIN25IdolApEvent:Constructor()
end
function UIN25IdolApEvent:OnShow(uiParams)
    self:GetComponents()
end
function UIN25IdolApEvent:SetData(component)
    ---@type IdolMiniGameComponent
    self.component = component
    self:OnValue()
end
function UIN25IdolApEvent:OnHide()
end
function UIN25IdolApEvent:GetComponents()
    self.eventPool = self:GetUIComponent("UISelectObjectPath","eventPool")
end
function UIN25IdolApEvent:OnValue()
    ---@type table{eventid,roomid,round,finish}
    self.datas = self.component:UI_GetWeekApEvent()

    local info = self.component:GetComponentInfo()
    ---@type IdolProgressInfo
    local breakInfo = info.break_info
    self.finishList = breakInfo.agree_events
    self.currentTurn = breakInfo.round_index

    self:ApEvent()
end
--约定事件板
function UIN25IdolApEvent:ApEvent()
    self.eventPool:SpawnObjects("UIN25IdolApEventItem",#self.datas)
    ---@type UIN25IdolApEventItem[]
    self.eventItems = self.eventPool:GetAllSpawnList()
    for i = 1, #self.datas do
        local data = self.datas[i]
        local item = self.eventItems[i]
        local eventid = data.eventid
        local finish = data.finish
        local round = data.round
        local weekIdx, weekDay = self.component:UI_Calc_WeekDay(round)
        local roomid = data.roomid
        local status
        if finish then
            status = UIIdolApEventStatus.Finish
        else
            if self.currentTurn <= round then
                status = UIIdolApEventStatus.Ready
            else
                status = UIIdolApEventStatus.Pass
            end
        end
        local light = self:GetLight(eventid)
        item:SetData(eventid,status,weekDay,roomid,light)
        item:PlayIn()
    end
end
function UIN25IdolApEvent:GetLight(eventid)
    local cfgs_end = Cfg.cfg_component_idol_ending{}
    if not cfgs_end then
        Log.error("###[UIN25IdolApEvent] cfgs_end is nil !")
    end
    --event表增加与结局相关的字段
    local cfg = Cfg.cfg_component_idol_event{EventId=eventid}[1]
    if cfg then
        local petid = cfg.PetId
        for key, value in pairs(cfgs_end) do
            local end_petid = value.PetId
            if end_petid and petid == end_petid then
                return true
            end
        end
    else
        Log.error("###[UIN25IdolApEvent] cfg is nil ! id --> ",eventid)
    end
    return false
end
function UIN25IdolApEvent:CloseAnim(TT)
    self.eventItems = self.eventPool:GetAllSpawnList()
    for i = 1, #self.datas do
        local item = self.eventItems[i]
        
        item:PlayOut()
    end
    YIELD(TT, 167)
end