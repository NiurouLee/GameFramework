--[[------------------------------------------------------------------------------------------
    AnimationViewWrapper : 老式动画的view包装类
    unity的animation组件在setactive时会执行rebuildinternalstate操作
    会产生比较明显的cpu波峰，因此这种类型gameobject的显隐是通过调整Y轴
    高度实现的
]] --------------------------------------------------------------------------------------------
require("view_wrapper")
---@class AnimationViewWrapper: IViewWrapper
_class("AnimationViewWrapper", IViewWrapper)
AnimationViewWrapper = AnimationViewWrapper

---@param resRequest ResRequest
function AnimationViewWrapper:Constructor(resource_service, resRequest)
    self.ViewType = "AnimationView"
    self.ResRequest = resRequest
    self.GameObject = resRequest.Obj
    self.Transform = resRequest.Obj.transform
    ---@type ResourcesPoolService
    self._ResService = resource_service
end

---@param pos Vector3
---@param dir Vector3
function AnimationViewWrapper:SyncTransform(pos, dir, scale, id)
    ---@type UnityEngine.Transform
    local tf = self.Transform
    tf.position = pos

    if (dir ~= Vector3(0, 0, 0)) then
        tf.forward = dir
    --Log.fatal("ID:",id,"ForWard: x=",tf.forward.x, " y=",tf.forward.y,"Dir:x=",dir.x, " y=",dir.y)
    end
    tf.localScale = scale
end

function AnimationViewWrapper:SetVisible(active)
    --self.GameObject:SetActive(active)
    --Log.debug("[active] ", self.ResRequest.m_Name, active, Log.traceback())
    local curPos = self.GameObject.transform.position
    if active then
        self.GameObject.transform.position = Vector3(curPos.x, 0, curPos.z)

        ---@type PieceServiceRender
        local pieceService = self._ResService._world:GetService("Piece")
        pieceService:PlayDefaultNormal(self.GameObject)
    else
        self.GameObject.transform.position = Vector3(curPos.x, 1000, curPos.z)
    end
end

function AnimationViewWrapper:ViewDispose()
    self._ResService:DestroyView(self)
end
