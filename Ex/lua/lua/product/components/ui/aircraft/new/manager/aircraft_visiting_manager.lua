--[[
    好友拜访管理器
]]
---@class AircraftManager:Object
_class("AircraftVisitingManager", Object)
AircraftVisitingManager = AircraftVisitingManager

---@param aircraftMain AircraftMain
function AircraftVisitingManager:Constructor(aircraftMain)
    ---@type AircraftMain
    self._main = aircraftMain

    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GetModule(AircraftModule)
    ---@type PetModule
    self._petModule = GameGlobal.GetModule(PetModule)

    --来参观的星灵
    ---@type table<number, aircraft_visit_pet>
    self._visitingPets = {}
end

function AircraftVisitingManager:Init()
    ---@type List<aircraft_visit_pet>
    local visitpets = self._aircraftModule:GetVisitPets()

    -----test-----
    -- local info = role_help_pet_info:New()
    -- info.pet_template_id = 1600891
    -- info.pet_pst_id = -1
    -- local pet = aircraft_visit_pet:New()
    -- pet.owner_pstid = -1
    -- pet.owner_nick = "你大爷"
    -- pet.pet_info = info
    -- pet.is_accpet_gift = false
    -- local visitpets = { pet }
    ----test end---

    for k, airVisitPet in pairs(visitpets) do
        self._visitingPets[airVisitPet.pet_info.pet_template_id] = airVisitPet
    end

    if table.count(self._visitingPets) > 0 then
        for petTemplateID, airVisitPet in pairs(self._visitingPets) do
            self:VisitingPetWander(airVisitPet)
        end
    end
end

function AircraftVisitingManager:Dispose()
end

--接受礼物
---@param pet AircraftPet
function AircraftVisitingManager:AcceptVisitingPresent(pet)
    local id = pet:TemplateID()
    if not self._visitingPets[id] then
        Log.exception("找不到拜访星灵：", id)
    end
    if self._visitingPets[id].is_accpet_gift then
        Log.exception("拜访星灵已没有礼物，不能送礼：", id)
    end

    GameGlobal.TaskManager():StartTask(self.recieveVisitGift, self, pet)
end

---@param pet AircraftPet
function AircraftVisitingManager:recieveVisitGift(TT, pet)
    local tmpID = pet:TemplateID()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AcceptVisitingPresent")
    local visitPetPstID = self._visitingPets[tmpID].pet_info.pet_pst_id
    local res, assetList = self._aircraftModule:AcceptVisitingPresent(TT, visitPetPstID)
    if not res:GetSucc() then
        AirLog("收取礼物消息返回错误:", res:GetResult(), "，星灵:", tmpID)
        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(res:GetResult()))
    end
    --刷新列表
    self._visitingPets = {}
    local visitpets = self._aircraftModule:GetVisitPets()
    for k, airVisitPet in pairs(visitpets) do
        self._visitingPets[airVisitPet.pet_info.pet_template_id] = airVisitPet
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AcceptVisitingPresent")

    if assetList and table.count(assetList) > 0 then
        local delieverPresentAction = AirActionDelieverPresent:New(pet, assetList, self._main)
        pet:StartMainAction(delieverPresentAction)

        --转身面向屏幕
        local _x, _z = self._main:GetMainCameraXZ()
        local _y = pet:WorldPosition().y
        local lookAtPoint = Vector3(_x, _y, _z)
        ---@type AirActionRotate
        local rotateAction = AirActionRotate:New(pet, lookAtPoint)
        pet:StartViceAction(rotateAction)
    end
    pet:StopMatAnim()
end

--是否是访客星灵
function AircraftVisitingManager:BeVisitingPet(visitPetTemplateID)
    return self._visitingPets[visitPetTemplateID] ~= nil
end

--访客星灵是否有礼物
function AircraftVisitingManager:HaveVisitingPresent(visitPetTemplateID)
    if self._visitingPets[visitPetTemplateID] then
        return self._visitingPets[visitPetTemplateID].is_accpet_gift == false
    end
    return false
end

---@param airVisitPet aircraft_visit_pet
function AircraftVisitingManager:VisitingPetWander(airVisitPet)
    --拜访星灵不用判断房间是否满了
    -- if self._main:IsRandomStoryPet(petTemplateID) then
    --     Log.debug("[AircraftVisitingManager] random story pet don't deliever present")
    --     return
    -- end
    ---@type AircraftPet
    local pet = self._main:AddVisitPet(airVisitPet)
    pet:SetVisitGift(airVisitPet.is_accpet_gift == false)
    AirLog("星灵触发送礼：", pet:TemplateID(), "，是否有礼物:", pet:HasVisitGift())
    if pet == nil then
        Log.exception("AddVisitPet fail!!!")
        return
    end
    self._main:RandomInitActionForPet(pet)

    if pet:HasVisitGift() then
        self:ShowPresentBag(pet)
    end
    self:ShowLight(pet)
    self:ShowName(pet)
end

---@param pet AircraftPet
function AircraftVisitingManager:ShowPresentBag(pet)
    local presentBubbleID = AircraftPetGiftBubble.Gift
    local faceAction = AirActionEffect:New(pet, presentBubbleID, AircraftPetSlotType.Head, Vector3(0.4, 0.8, 0), nil)
    pet:StartSpecialAction(AircraftSpecialActionType.PresentBag, faceAction)
    local obj = faceAction:GetGameObject()
    pet:SetPresentObject(obj)
end

---@param pet AircraftPet
function AircraftVisitingManager:ShowLight(pet)
    local lightBubbleID = AircraftPetGiftBubble.Light
    local faceAction = AirActionEffect:New(pet, lightBubbleID, AircraftPetSlotType.Root, Vector3(0, 0.01, 0), nil)
    pet:StartSpecialAction(AircraftSpecialActionType.Light, faceAction)
end

---@param pet AircraftPet
function AircraftVisitingManager:ShowName(pet)
    local nameBubbleID = AircraftPetGiftBubble.VisitName
    local faceAction = AirActionEffect:New(pet, nameBubbleID, AircraftPetSlotType.Head, Vector3(0, 0.5, 0), nil)
    pet:StartSpecialAction(AircraftSpecialActionType.Name, faceAction)
    local nameObj = faceAction:GetGameObject()
    if not nameObj then
        return
    end
    local view = nameObj:GetComponent("UIView")
    local petText = view:GetUIComponent("UILocalizationText", "PetText")
    local ownerText = view:GetUIComponent("UILocalizationText", "ownerText")
    petText:SetText(pet:PetName())
    local ownerNameText = self._visitingPets[pet:TemplateID()].owner_nick
    ownerText:SetText(ownerNameText)
    pet:SetOwnerName(ownerNameText)
end
