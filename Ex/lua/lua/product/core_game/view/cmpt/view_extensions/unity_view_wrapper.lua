--[[******************************************************************************************
    提供更全面的UnityViewWrapper功能
--******************************************************************************************]] --

---@class UnityViewWrapper: IViewWrapper
_class("UnityViewWrapper", IViewWrapper)
UnityViewWrapper = UnityViewWrapper

---@param resRequest ResRequest
function UnityViewWrapper:Constructor(resource_service, resRequest)
    self.ViewType = "UnitySimple"
    self.ResRequest = resRequest
    self.GameObject = resRequest.Obj
    self.Transform = resRequest.Obj.transform
    ---@type ResourcesPoolService
    self._ResService = resource_service

    --region cache
    ---@type table map key=string结点名 value=UnityEngine.Transform结点transform
    self._childTrans = {} --子结点Transform字典
    --endregion
end

---@param pos Vector3
---@param dir Vector3
function UnityViewWrapper:SyncTransform(pos, dir, scale, id, onOtherBoard)
    ---@type UnityEngine.Transform
    local tf = self.Transform
    if (dir ~= Vector3(0, 0, 0)) and not onOtherBoard then
        tf.forward = dir
    end
    if onOtherBoard then
        -- tf.localEulerAngles = Vector3(0, 0, 0)
        tf.localPosition = pos
    else
        tf.position = pos
    end

    tf.localScale = scale
end

function UnityViewWrapper:SetVisible(active)
    self.GameObject:SetActive(active)
    --Log.debug("[active] ", self.ResRequest.m_Name, active, Log.traceback())
end

function UnityViewWrapper:ViewDispose()
    self._ResService:DestroyView(self)
end

--region cache
---@param name string 结点名
---@return UnityEngine.Transform 会返回该预制的第一个名为name的子结点的Transform；缓存
function UnityViewWrapper:FindChild(name)
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
