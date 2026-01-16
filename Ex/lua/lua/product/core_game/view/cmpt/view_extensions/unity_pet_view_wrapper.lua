--[[
    宝宝局内局外状态机拆分之后，需要特殊的Wrapper管理
]]
require("view_wrapper")
---@class UnityPetViewWrapper:IViewWrapper
_class("UnityPetViewWrapper", IViewWrapper)
UnityPetViewWrapper = UnityPetViewWrapper

function UnityPetViewWrapper:Constructor(resource_service, petRes, ancRes)
    self.ViewType = "UnityPet"
    self.ResRequests = {petRes, ancRes}
    self.GameObject = petRes.Obj
    self.Transform = petRes.Obj.transform

    --拼装
    local animatorController = ancRes.Obj:GetComponent(typeof(UnityEngine.Animator)).runtimeAnimatorController
    if (animatorController == nil) then
        Log.error("[ani] getAnimatorController Error", petRes.m_Name, ancRes.m_Name)
    end

    ---@type UnityEngine.Animator
    local u3dAnimatorCmpt = self.GameObject:GetComponentInChildren(typeof(UnityEngine.Animator))
    if u3dAnimatorCmpt == nil then 
        Log.error("[ani] Root has no animator ", petRes.m_Name, ancRes.m_Name)
    end

    u3dAnimatorCmpt.runtimeAnimatorController = animatorController
    ancRes.Obj:SetActive(false)
    ---@type ResourcesPoolService
    self._ResService = resource_service

    --region cache
    ---@type table map key=string结点名 value=UnityEngine.Transform结点transform
    self._childTrans = {} --子结点Transform字典
    --endregion
end

---@param pos Vector3
---@param dir Vector3
function UnityPetViewWrapper:SyncTransform(pos, dir, scale)
    ---@type UnityEngine.Transform
    local tf = self.Transform
    tf.position = pos

    if (dir ~= Vector3(0, 0, 0)) then
        tf.forward = dir
    end
    tf.localScale = scale
end

function UnityPetViewWrapper:SetVisible(active)
    self.GameObject:SetActive(active)
end

function UnityPetViewWrapper:ViewDispose()
    self._ResService:DestroyView(self)
end

--region cache
---@param name string 结点名
---@return UnityEngine.Transform 会返回该预制的第一个名为name的子结点的Transform；缓存
function UnityPetViewWrapper:FindChild(name)
    local tran = self.Transform
    if not tran then
        Log.fatal("### no Transform in UnityViewWrapper")
        return nil
    end
    if not self._childTrans[name] then
        local tranChild = GameObjectHelper.FindChild(tran, name)
        self._childTrans[name] = tranChild
    end
    return self._childTrans[name]
end
--endregion