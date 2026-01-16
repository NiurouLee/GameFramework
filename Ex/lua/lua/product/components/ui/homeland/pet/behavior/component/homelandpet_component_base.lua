---@class HomelandPetComponentBase:Object
_class("HomelandPetComponentBase", Object)
HomelandPetComponentBase = HomelandPetComponentBase

---@param componentType HomelandPetComponentType
---@param pet HomelandPet
---@param behavior HomelandPetBehaviorBase
function HomelandPetComponentBase:Constructor(componentType, pet, behavior)
    ---@type HomelandPetComponentType
    self._componentType = componentType
    ---@type HomelandPet
    self._pet = pet
    ---@type HomelandPetComponentState
    self.state = HomelandPetComponentState.Resting
    self._behavior = behavior
    --[[
    if self._updatePerFrameCallBack == nil then
        self._updatePerFrameCallBack = GameHelper:GetInstance():CreateCallback(self._OnUpdatePerFrameCallback, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnUpdatePerFrame, self._updatePerFrameCallBack)
    end
]]
end
---光灵替换皮肤后，删除了旧模型，需要重新加载一下新模型上的动画组件
function HomelandPetComponentBase:ReLoadPetComponent()
end
function HomelandPetComponentBase:Init()
end
function HomelandPetComponentBase:OnExcute()
end
function HomelandPetComponentBase:Update(deltaTime)
end
function HomelandPetComponentBase:Exit()
    self.state = HomelandPetComponentState.Resting
end
function HomelandPetComponentBase:Dispose()
    --[[
    if self._updatePerFrameCallBack then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnUpdatePerFrame, self._updatePerFrameCallBack)
        self._updatePerFrameCallBack = nil
    end
    --]]
end
function HomelandPetComponentBase:Finish()
    return self.state == HomelandPetComponentState.Success
end

function HomelandPetComponentBase:Failure()
    return self.state == HomelandPetComponentState.Failure
end

function HomelandPetComponentBase:Resting()
    self.state = HomelandPetComponentState.Resting
end

function HomelandPetComponentBase:_OnUpdatePerFrameCallback()
    self:OnUpdatePerFrame()
end

function HomelandPetComponentBase:OnUpdatePerFrame()
end
