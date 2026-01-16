--[[------------------------------------------------------------------------------------------
    GridViewWrapper : 格子view包装类
    格子在回池的时候，不会执行deactive，而是放到了一个很远的位置
]] --------------------------------------------------------------------------------------------
require("view_wrapper")

---@class GridViewWrapper: IViewWrapper
_class("GridViewWrapper", IViewWrapper)
GridViewWrapper = GridViewWrapper

---@param resRequest ResRequest
function GridViewWrapper:Constructor(resource_service, resRequest)
    self.ViewType = "GridView"
    self.ResRequest = resRequest
    self.GameObject = resRequest.Obj
    self.Transform = resRequest.Obj.transform
    ---@type ResourcesPoolService
    self._ResService = resource_service
end

---@param pos Vector3
---@param dir Vector3
function GridViewWrapper:SyncTransform(pos, dir, scale, id, onOtherBoard)
    ---@type UnityEngine.Transform
    local tf = self.Transform

    if (dir ~= Vector3(0, 0, 0)) then
        tf.forward = dir
    end
    if onOtherBoard then
        tf.localEulerAngles = Vector3(0, 0, 0)
        tf.localPosition = pos
    else
        tf.position = pos
    end
    tf.localScale = scale
end

function GridViewWrapper:SetVisible(active)
    --self.GameObject:SetActive(active)
    --Log.debug("[active] ", self.ResRequest.m_Name, active, Log.traceback())
    local curPos = self.GameObject.transform.position
    if active then
        self.GameObject.transform.position = Vector3(curPos.x, 0, curPos.z)

        ---@type PieceServiceRender
        local pieceService = self._ResService._world:GetService("Piece")
        pieceService:PlayDefaultNormal(self.GameObject)
    else
        self.GameObject.transform.position = Vector3(curPos.x, BattleConst.CacheHeight, curPos.z)
    end
end

function GridViewWrapper:ViewDispose()
    self._ResService:DestroyView(self)
end
