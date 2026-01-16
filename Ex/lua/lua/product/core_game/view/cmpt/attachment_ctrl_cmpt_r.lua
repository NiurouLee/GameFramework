--[[------------------------------------------------------------------------------------------
    AttachmentControllerComponent : 挂件控制组件
]] --------------------------------------------------------------------------------------------

---@class AttachmentControllerComponent: Object
_class("AttachmentControllerComponent", Object)
AttachmentControllerComponent = AttachmentControllerComponent

function AttachmentControllerComponent:Constructor()
    ---@type ResRequest
    self._resReq = nil
    ---@type string
    self._resName = ""
end

---@param resReq ResRequest
function AttachmentControllerComponent:SetResRequest(resReq)
    self._resReq = resReq
end

---@param resName string
function AttachmentControllerComponent:SetResName(resName)
    self._resName = resName
end

---@return ResRequest
function AttachmentControllerComponent:GetResRequest()
    return self._resReq
end

---@return string
function AttachmentControllerComponent:GetResName()
    return self._resName
end

function AttachmentControllerComponent:Dispose()
    if self._resReq then
        self._resReq:Dispose()
    end
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return AttachmentControllerComponent
function Entity:AttachmentController()
    return self:GetComponent(self.WEComponentsEnum.AttachmentController)
end

---@return boolean
function Entity:HasAttachmentController()
    return self:HasComponent(self.WEComponentsEnum.AttachmentController)
end

---@param resName string
function Entity:AddAttachmentController(resName)
    self:RemoveAttachmentController()

    local gameObj = self:View().ViewWrapper.GameObject
    local resReq = ResourceManager:GetInstance():SyncLoadAsset(resName .. ".prefab", LoadType.GameObject)
    local tmpRoot = resReq.Obj
    tmpRoot.transform:SetParent(gameObj.transform, false)
    tmpRoot:SetActive(false)

    local index = self.WEComponentsEnum.AttachmentController
    local component = AttachmentControllerComponent:New()
    component:SetResRequest(resReq)
    component:SetResName(resName)
    self:AddComponent(index, component)
end

function Entity:RemoveAttachmentController()
    if self:HasAttachmentController() then
        self:RemoveComponent(self.WEComponentsEnum.AttachmentController)
    end
end

---@param animName string
function Entity:SetAttachmentAnimationTrigger(animName)
    local attachComponent = nil
    if self:HasAttachmentController() then
        attachComponent = self:AttachmentController()
    else
        return
    end

    local attachResReq = attachComponent:GetResRequest()
    if attachResReq == nil then
        return
    end

    local attachGameObj = attachResReq.Obj
    local attachResName = attachComponent:GetResName()

    local attachRoot = attachGameObj.transform:Find("Root")
    if not attachRoot then
        return
    end
    ---@type UnityEngine.Animator
    local attachAnimator = attachRoot:GetComponent("Animator")
    if attachAnimator then
        attachAnimator:SetTrigger(animName)
    end
end

---@param animName string
---@param isTrue boolean
function Entity:SetAttachmentAnimationBool(animName, isTrue)
    local attachComponent = nil
    if self:HasAttachmentController() then
        attachComponent = self:AttachmentController()
    else
        return
    end

    local attachResReq = attachComponent:GetResRequest()
    if attachResReq == nil then
        return
    end

    local attachGameObj = attachResReq.Obj
    local attachResName = attachComponent:GetResName()

    local attachRoot = attachGameObj.transform:Find("Root")
    if not attachRoot then
        return
    end
    ---@type UnityEngine.Animator
    local attachAnimator = attachRoot:GetComponent("Animator")
    if attachAnimator then
        attachAnimator:SetBool(animName, isTrue)
    end
end

---@param isShow boolean
function Entity:SetAttachmentVisible(isShow)
    local attachComponent = nil
    if self:HasAttachmentController() then
        attachComponent = self:AttachmentController()
    else
        return
    end

    local attachResReq = attachComponent:GetResRequest()
    if attachResReq == nil then
        return
    end

    local attachGameObj = attachResReq.Obj
    attachGameObj:SetActive(isShow)
end
