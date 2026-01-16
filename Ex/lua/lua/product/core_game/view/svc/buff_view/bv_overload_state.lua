--[[
    层数叠加
]]
_class("BuffViewSetOverloadState", BuffViewBase)
---@class BuffViewSetOverloadState:BuffViewBase
BuffViewSetOverloadState = BuffViewSetOverloadState
---
function BuffViewSetOverloadState:PlayView(TT)
    if self._entity:HasPetPstID() then
        ---@type PetPstIDComponent
        local petPstIDCmpt = self._entity:PetPstID()
        local petPstID = petPstIDCmpt:GetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.SetPetOverloadState,1,petPstID)
    end
end


--[[
    清空层数
]]
_class("BuffViewResetOverloadState", BuffViewBase)
---@class BuffViewResetOverloadState:BuffViewBase
BuffViewResetOverloadState = BuffViewResetOverloadState
---
function BuffViewResetOverloadState:PlayView(TT)
    if self._entity:HasPetPstID() then
        ---@type PetPstIDComponent
        local petPstIDCmpt = self._entity:PetPstID()
        local petPstID = petPstIDCmpt:GetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.SetPetOverloadState,0,petPstID)
    end
end