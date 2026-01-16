--[[
    逻辑死亡结果通知表现
]]

_class("DataDeadMarkResult",Object)
DataDeadMarkResult=DataDeadMarkResult

function DataDeadMarkResult:Constructor(list)
    self._deadEntityIDList = list or {}
end

function DataDeadMarkResult:AddDeadEntityID(eid)
    table.insert(self._deadEntityIDList,eid)
end

function DataDeadMarkResult:GetDeadEntityIDList()
    return self._deadEntityIDList
end