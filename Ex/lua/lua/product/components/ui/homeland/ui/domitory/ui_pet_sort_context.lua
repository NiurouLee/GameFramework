--[[
    宿舍星灵排序上下文
]]
---@class UIPetSortContext:Object
_class("UIPetSortContext", Object)
UIPetSortContext = UIPetSortContext

function UIPetSortContext:Constructor()
    self._viceElement = false --副属性
    self._curElement = 0 --属性
end

function UIPetSortContext:CurElement()
    return self._curElement
end

function UIPetSortContext:SetElement(element)
    self._curElement = element
end

function UIPetSortContext:SetViceElement(active)
    self._viceElement = active
end
function UIPetSortContext:ShowViceElement()
    return self._viceElement
end

---@type UIPetSortContext
UIPetSortContext.Instance = nil

function UIPetSortContext.CreateInstance()
    if UIPetSortContext.Instance then
        Log.exception("不可以创建多个实例")
    end
    UIPetSortContext.Instance = UIPetSortContext:New()
end

function UIPetSortContext.ClearInstance()
    UIPetSortContext.Instance = nil
end
