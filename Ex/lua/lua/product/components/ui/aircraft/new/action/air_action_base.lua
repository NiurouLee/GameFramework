--[[
    风船星灵Action基类
]]
---@class AirActionBase:Object
_class("AirActionBase", Object)
AirActionBase = AirActionBase
function AirActionBase:Constructor()
    self._duration = 0
    self._curTime = 0
    self._running = false
    self._des = nil
end
function AirActionBase:Start()
    self._running = true
end
---@return boolean
function AirActionBase:IsOver()
    return self._curTime > self._duration
end
function AirActionBase:Update(deltaTimeMS)
    if self._running and not self:IsOver() then
        self._curTime = self._curTime + deltaTimeMS
    end
end
function AirActionBase:Stop()
    self._running = false
    self._curTime = 0
    self._duration = 0
end
---@return number 总时长
function AirActionBase:Duration()
    return self._duration
end
---@ return number 当前运行时长
function AirActionBase:CurrentTime()
    return self._curTime
end
--返回该行为控制的星灵列表
---@return table<number,AircraftPet>
function AirActionBase:GetPets()
    return nil
end
function AirActionBase:Dispose()
end
function AirActionBase:Log(...)
    Log.debug("[AircraftAction] ", ...)
end
function AirActionBase:LogStart()
    -- local id = "，Pet: "
    -- if self:GetPets() then
    --     for idx, pet in ipairs(self:GetPets()) do
    --         if idx > 1 then
    --             id = id .. "," .. pet:TemplateID()
    --         else
    --             id = id .. pet:TemplateID()
    --         end
    --     end
    -- end
    -- if self._des == nil then
    --     self._des = self._className
    -- end
    -- self:Log("--->开始行为：", self._des, id)
end
function AirActionBase:LogStop()
    -- local id = "，Pet: "
    -- if self:GetPets() then
    --     for idx, pet in ipairs(self:GetPets()) do
    --         if idx > 1 then
    --             id = id .. "," .. pet:TemplateID()
    --         else
    --             id = id .. pet:TemplateID()
    --         end
    --     end
    -- end
    -- if self._des == nil then
    --     self._des = self._className
    -- end
    -- self:Log("===>结束行为：", self._des, id)
end

function AirActionBase:GetActionType()
    return AircraftActionType.None
end
