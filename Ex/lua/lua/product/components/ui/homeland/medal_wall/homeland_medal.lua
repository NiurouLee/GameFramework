---@class HomelandMedal:Object
_class("HomelandMedal", Object)
HomelandMedal = HomelandMedal

---@param rootTran Transform
---@param boardMedal BoardMedal
---@param buildID int
function HomelandMedal:Constructor(rootTran, boardMedal)
    self._id = boardMedal.itemId
    self._req = ResourceManager:GetInstance():SyncLoadAsset(boardMedal.model, LoadType.GameObject)
    if not self._req then
        BuildError("找不到勋章模型:" .. boardMedal.model)
        return
    end

    self._go = self._req.Obj
    self._go.layer = HomeBuildLayer.MedalWall
    self._go:SetActive(true)
    self._transform = self._req.Obj.transform
    self._transform:SetParent(rootTran)
    local offsetZ = (boardMedal.index - 1) * MedalWallConfig.MedalOffset
    self._transform.localPosition = Vector3(-boardMedal.pos.x, boardMedal.pos.y, offsetZ)
    self._transform.localRotation = Quaternion(boardMedal.quat.x, boardMedal.quat.y, boardMedal.quat.z,
        -boardMedal.quat.w)

    --3D中模型是按照比例制作的，无需缩放
    ---@type UnityEngine.MeshFilter
    -- self._meshFilter = self._go:GetComponentInChildren(typeof(UnityEngine.MeshFilter))
    -- ---@type UnityEngine.Mesh
    -- local mesh = self._meshFilter.mesh
    -- ---@type UnityEngine.Bounds
    -- local bounds = mesh.bounds
    -- local xScale = boardMedal.wh.x / bounds.size.x
    -- local yScale = boardMedal.wh.y / bounds.size.y
    -- self._transform.localScale = Vector3(xScale, yScale, 1)
end

function HomelandMedal:Destroy()
    self._go = nil
    self._transform = nil
    if self._req then
        self._req:Dispose()
    end
    self._req = nil
end
