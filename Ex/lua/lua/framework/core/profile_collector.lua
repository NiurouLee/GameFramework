--[[
    性能收集器
]]
_class("ProfileCollector", Object)
ProfileCollector = ProfileCollector

function ProfileCollector:Constructor(title)
    self._title = title
    self._last_tick = 0
    self._begin_tick = 0
    self._collection = {}
end

--采样
function ProfileCollector:Sample(name)
    local tick = os.clock()
    if self._last_tick == 0 then
        self._last_tick = tick
        self._begin_tick = tick
    end
    local diff = (tick - self._last_tick) * 1000
    self._last_tick = tick
    table.insert(self._collection, {name = name, usetime = diff})
end

--输出
function ProfileCollector:Dump()
    self._last_tick = 0
    for i, v in ipairs(self._collection) do
        Log.prof("[", self._title, "]", ",name,", v.name, ",usetime,", v.usetime)
    end
    local total = (os.clock() - self._begin_tick) * 1000
    Log.prof("[", self._title, "]", ",name,", "total", ",usetime,", total)
    self:ResetCollector()
end

--重置
function ProfileCollector:ResetCollector()
    self._last_tick = 0
    self._collection = {}
end
