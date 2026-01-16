--[[
    星灵给玩家送礼控制器
]]
---@class AircraftManager:Object
_class("AircraftPresentManager", Object)
AircraftPresentManager = AircraftPresentManager

---@param aircraftMain AircraftMain
function AircraftPresentManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain

    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GetModule(AircraftModule)
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)
end

function AircraftPresentManager:Init()
    local presentPetsPstidList = self._aircraftModule:GetHavePresentPets()
    for k, petPstid in pairs(presentPetsPstidList) do
        local pet = self._petModule:GetPet(petPstid)
        if pet then
            local petID = pet:GetTemplateID()
            self:DelieverPetWander(petID)
        else
            Log.exception("背包中没有星灵，不能送礼！")
        end
    end
end

function AircraftPresentManager:Dispose()
end

--接受礼物
function AircraftPresentManager:AcceptPresent(pet)
    GameGlobal.TaskManager():StartTask(self.reqAcceptGift, self, pet)
end

---@param pet AircraftPet
function AircraftPresentManager:reqAcceptGift(TT, pet)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "reqAcceptGift")
    local tmpID = pet:TemplateID()
    local res, assetList = self._aircraftModule:AcceptPresentByTemplateID(TT, tmpID)
    if not res:GetSucc() then
        AirLog("收取礼物失败，错误码:", res:GetResult())
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(res:GetResult()))
        self:OnAcceptPresentEnd(tmpID)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "reqAcceptGift")

    local currentPet = self._main:GetPetByTmpID(tmpID)

    if assetList and table.count(assetList) > 0 then
        local delieverPresentAction = AirActionDelieverPresent:New(currentPet, assetList, self._main)
        currentPet:StartMainAction(delieverPresentAction)
        --转身面向屏幕
        local _x, _z = self._main:GetMainCameraXZ()
        local _y = pet:WorldPosition().y
        local lookAtPoint = Vector3(_x, _y, _z)
        ---@type AirActionRotate
        local rotateAction = AirActionRotate:New(pet, lookAtPoint)
        pet:StartViceAction(rotateAction)
    end
    self:OnAcceptPresentEnd(tmpID)
end

function AircraftPresentManager:OnAcceptPresentEnd(petTemplateID)
    local pet = self._main:GetPetByTmpID(petTemplateID)
    --pet:SetState(AirPetState.Wandering)
    pet:StopMatAnim()
end

function AircraftPresentManager:DelieverPetWander(petTemplateID)
    if self._main:IsRandomStoryPet(petTemplateID) then
        AirLog("送礼星灵触发随机剧情，不触发送礼：", petTemplateID)
        --剧情星灵不再标记未送礼状态 2021.6.24 靳策
        -- local pet = self._main:GetPetByTmpID(petTemplateID)
        --标记为送礼状态
        -- pet:SetGiftFlag(true)
        return
    end

    AirLog("创建1个送礼星灵：", petTemplateID)
    local pet, sp = self._main:AddPet(petTemplateID)
    if pet then
        --先设置标记，星灵带有礼物
        pet:SetGiftFlag(true)
        --再随机行为
        self._main:RandomInitActionForPet(pet)
        local presentBubbleID = AircraftPetGiftBubble.Gift
        local faceAction = AirActionEffect:New(pet, presentBubbleID, AircraftPetSlotType.Head, Vector3(0.4, 0.5, 0), nil)
        pet:StartSpecialAction(AircraftSpecialActionType.PresentBag, faceAction)
        local obj = faceAction:GetGameObject()
        pet:SetPresentObject(obj)
    else
        if sp then
            Log.debug("###[AircraftPresentManager] 送礼星灵创建失败，有sp星灵存在,sp:", sp)
        else
            Log.debug("###[AircraftPresentManager] 送礼星灵创建失败")
        end
    end
end
