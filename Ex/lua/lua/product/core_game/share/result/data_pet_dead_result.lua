--[[------------------------------------------------------------------------------------------
    DataPetDeadResult : 宝宝死亡的通知结果
]] --------------------------------------------------------------------------------------------

---@class DataPetDeadResult: Object
_class("DataPetDeadResult", Object)
DataPetDeadResult = DataPetDeadResult

function DataPetDeadResult:Constructor()
    self._petDeadEntityIDList = {}
end

function DataPetDeadResult:DataSetDeadPetEntityIDList(deadList)
    self._petDeadEntityIDList = deadList
end

function DataPetDeadResult:DataGetDeadPetEntityIDList()
    return self._petDeadEntityIDList
end