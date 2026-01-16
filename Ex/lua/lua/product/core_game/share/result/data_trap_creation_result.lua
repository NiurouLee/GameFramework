--[[------------------------------------------------------------------------------------------
    DataTrapCreationResult : 单个机关创建的结果，用于逻辑传递给表现使用
]] --------------------------------------------------------------------------------------------

_class("DataTrapCreationResult", Object)
---@class DataTrapCreationResult: Object
DataTrapCreationResult = DataTrapCreationResult

function DataTrapCreationResult:Constructor()
    self._trapConfigID = nil
    self._trapEntityID=nil
    self._replaceTrapID = nil
    self._trapHP = 0
    self._trapHPMax = 0
    self._transferTrapID = nil
end

function DataTrapCreationResult:SetTrapEntityID(eid)
    self._trapEntityID = eid
end

function DataTrapCreationResult:GetTrapEntityID()
    return self._trapEntityID
end

function DataTrapCreationResult:SetTrapHP(hp)
    self._trapHP = hp
end

function DataTrapCreationResult:SetTrapHPMax(hpMax)
    self._trapHPMax = hpMax
end

function DataTrapCreationResult:GetTrapHP()
    return self._trapHP
end

function DataTrapCreationResult:GetTrapHPMax()
    return self._trapHPMax
end

function DataTrapCreationResult:SetReplaceTrapID(id)
    self._replaceTrapID = id
end

function DataTrapCreationResult:GetReplaceTrapID()
    return self._replaceTrapID
end

function DataTrapCreationResult:SetTransferTrapID(id)
    self._transferTrapID = id
end

function DataTrapCreationResult:GetTransferTrapID()
    return self._transferTrapID
end

-------------------逻辑传送过来的机关的配置ID--------------------
function DataTrapCreationResult:SetTrapCreationResult_TrapID(id)
    self._trapConfigID = id
end

function DataTrapCreationResult:GetTrapCreationResult_TrapID()
    return self._trapConfigID
end
---------------------------------------------------------------