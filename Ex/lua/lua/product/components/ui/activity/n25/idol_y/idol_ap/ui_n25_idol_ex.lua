---@class UIN25IdolEx:UICustomWidget
_class("UIN25IdolEx", UICustomWidget)
UIN25IdolEx = UIN25IdolEx
function UIN25IdolEx:Constructor()
end
function UIN25IdolEx:OnShow(uiParams)
    --self:GetComponents()
end
---@param info IdolProgressInfo
function UIN25IdolEx:SetData(callback)
    --self.info = info
    --self:OnValue()
end
function UIN25IdolEx:OnHide()
end
function UIN25IdolEx:GetComponents()
    self.pool = self:GetUIComponent("UISelectObjectPath","pool")
end
function UIN25IdolEx:OnValue()
    ---@type table<type,id>
    self.datas = self:GetApDataWeek()

    self:ApEvent()
end
--获取本周未完成的约定事件
function UIN25IdolEx:GetApDataWeek()
    local finishAps = self.info.agree_events
    local currentTurn = self.info.round_index

    local currentWeek = currentTurn//7

    local rets = {}

    local cfgs = Cfg.cfg_component_idol_round{}
    for i = 1, #cfgs do
        local cfg = cfgs[i]
        local round = cfg.Round
        local cfgWeek = round//7
        if currentWeek == cfgWeek then
            local events = cfg.AgreedEventId
            if events then
                for j = 1, #events do
                    local data = events[j]
                    local type = data[1]
                    local id = data[2]
                    if not table.icontains(finishAps,id) then
                        local roomType = type
                        local eventID = id
                        local e = {type=roomType,id=eventID}
                        table.insert(rets,e)
                    end
                end
            end
        end
    end

    return rets
end
--约定事件板
function UIN25IdolEx:ApEvent()
    self.eventPool:SpwanObjects("UIN25IdolExItem",#self.datas)
    ---@type UIN25IdolExItem[]
    self.eventItems = self.eventPool:GetAllSpawnList()
    for i = 1, #self.datas do
        local data = self.datas[i]
        local item = self.items[i]
        item:SetData(data)
    end
end
function UIN25IdolEx:BtnOnClick(go)
    
end