--[[------------------------------------------------------------------------------------------
    DataPopStarResult : 消灭星星的消除格子结果数据
]]
--------------------------------------------------------------------------------------------

---@class DataPopStarResult: Object
_class("DataPopStarResult", Object)
DataPopStarResult = DataPopStarResult

function DataPopStarResult:Constructor()
    ---消除数量
    self._popNum = 0
    ---挑战关阶段发生变化
    self._indexChange = false

    ---格子数据：
    ---删除的
    self._delSet = nil
    ---下落的
    self._moveSet = nil
    ---新生成的
    self._newSet = nil

    ---特殊格子和道具
    ---删除的
    self._delTrapList = nil
    ---下落的
    self._moveTrapList = nil
    ---新生成的
    self._newTrapList = nil
end

function DataPopStarResult:GetPopNum()
    return self._popNum
end

function DataPopStarResult:SetPopNum(num)
    self._popNum = num
end

function DataPopStarResult:IsIndexChange()
    return self._indexChange
end

function DataPopStarResult:SetIndexChange()
    self._indexChange = true
end

function DataPopStarResult:GetDelSet()
    return self._delSet
end

function DataPopStarResult:SetDelSet(del)
    self._delSet = del
end

function DataPopStarResult:GetMoveSet()
    return self._moveSet
end

function DataPopStarResult:SetMoveSet(move)
    self._moveSet = move
end

function DataPopStarResult:GetNewSet()
    return self._newSet
end

function DataPopStarResult:SetNewSet(new)
    self._newSet = new
end

function DataPopStarResult:GetDelTrapList()
    return self._delTrapList
end

function DataPopStarResult:SetDelTrapList(del)
    self._delTrapList = del
end

function DataPopStarResult:GetMoveTrapList()
    return self._moveTrapList
end

function DataPopStarResult:SetMoveTrapList(move)
    self._moveTrapList = move
end

function DataPopStarResult:GetNewTrapList()
    return self._newTrapList
end

function DataPopStarResult:SetNewTrapList(new)
    self._newTrapList = new
end
