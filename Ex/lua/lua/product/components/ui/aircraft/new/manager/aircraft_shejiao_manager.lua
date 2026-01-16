--[[
    新的社交控制器
]]
---@class AircraftShejiaoManager:Object
_class("AircraftShejiaoManager", Object)
AircraftShejiaoManager = AircraftShejiaoManager

function AircraftShejiaoManager:Constructor(main)
    ---@type AircraftMain
    self._main = main
    --社交触发时间间隔
    self._triggerTime = Cfg.cfg_aircraft_const["aircraft_social_check_time"].IntValue
    self._timer = 0
    ---@type table<number,AirActionSocialBase>
    self._actions = {}
end

function AircraftShejiaoManager:Init()
end

function AircraftShejiaoManager:Dispose()
end

function AircraftShejiaoManager:Update(dtMS)
    self._timer = self._timer + dtMS
    if self._timer > self._triggerTime then
        self._timer = 0
        self:_triggerOnce()
    end

    for key, action in pairs(self._actions) do
        action:Update(dtMS)
        if action:IsOver() then
            AirLog("社交行为结束")
            self._actions[key] = nil
        end
    end
end

--触发1次社交
function AircraftShejiaoManager:_triggerOnce()
    --[[
        1.筛选可社交星灵，目前只有星灵在房间内漫游1个条件，包含拜访星灵
    ]]
    local pets =
        self._main:GetPets(
        function(p)
            ---@type AircraftPet
            local pet = p
            local state = pet:GetState()
            return state == AirPetState.Wandering
        end,
        true
    )
    if #pets == 0 then
        AirLog("没有可社交的星灵")
        return
    end
end
