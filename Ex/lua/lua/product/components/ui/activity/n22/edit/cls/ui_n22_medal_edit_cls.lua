--region N22MedalEditData
---@class N22MedalEditData:Object
---@field boardMedals BoardMedal[] 板上徽章列表
---@field whBoard Vector2 勋章板宽高
_class("N22MedalEditData", Object)
N22MedalEditData = N22MedalEditData

function N22MedalEditData:Constructor()
    self.mMedal = GameGlobal.GetModule(MedalModule)

    -- self.medalItems = {}
    self.boardMedals = {}
    --1920 × 1080下编辑界面的勋章板宽 = 1672，此时高586
    --勋章板宽高比：
    --1113/ 390 = 2.853846153846154
    --1792/628 = 2.853503184713376
    self.whBoard = Vector2(1672, 586)
end

--region Init
function N22MedalEditData:Init()
    self:InitBoardMedals()
    self:FormatBoardMedalIndex()
end
function N22MedalEditData:InitBoardMedals()
    ---@type medal_placement_info
    local medal_board = self.mMedal:GetPlacementInfo()
    ---@type medal_position[]
    local medal_on_board = medal_board.medal_on_board
    if not medal_on_board then
        return
    end
    self.boardMedals = {}
    for id, bm in pairs(medal_on_board) do
        local md = BoardMedal:New(id)
        md.index = bm.z
        md.pos = Vector2(bm.x, bm.y)
        md.quat = Quaternion(bm.quatx, bm.quaty, bm.quatz, bm.quatw)
        md.wh = Vector2(bm.w, bm.h)
        table.insert(self.boardMedals, md)
    end
end
--endregion

---@param res AsyncRequestRes
function N22MedalEditData.CheckCode(res)
    local result = res:GetResult()
    if result == MedalErrorType.E_MEDAL_ERROR_TYPE_SUCCESS then
        return true
    end
    local msg = StringTable.Get("str_medal_error_" .. result)
    ToastManager.ShowToast(msg)
    return false
end

---@return BoardMedal
function N22MedalEditData:GetBoardMedalById(id)
    for index, boardMedal in ipairs(self.boardMedals) do
        if boardMedal.id == id then
            return boardMedal
        end
    end
end

function N22MedalEditData:IsDirty()
    ---@type medal_placement_info
    local medal_board = self.mMedal:GetPlacementInfo()
    ---@type medal_position[]
    local medal_on_board = medal_board.medal_on_board or {}
    if table.count(self.boardMedals) ~= table.count(medal_on_board) then --客户端服务器数量不同肯定脏
        return true
    end
    for _, boardMedal in ipairs(self.boardMedals) do
        local serData = medal_on_board[boardMedal.id]
        if not serData then --客户端有服务器无肯定脏；有这个条件，加上数量对比，就不需要判断客户端无服务器有的情况了
            return true
        end
        local posSer = Vector2(serData.x, serData.y)
        local quatSer = Quaternion(serData.quatx, serData.quaty, serData.quatz, serData.quatw)
        local index = serData.z
        if boardMedal:IsDirtyPos(posSer) or boardMedal:IsDirtyRot(quatSer) or boardMedal:IsDirtyIndex(index) then --都有的勋章数据是否一致
            return true
        end
    end
    return false
end

--region 勋章板id
---@return number 获取勋章板id
function N22MedalEditData:GetBoardId()
    local medal_board = self.mMedal:GetPlacementInfo()
    return medal_board.board_back_id
end
function N22MedalEditData:SetBoardId(id)
    local medal_board = self.mMedal:GetPlacementInfo()
    medal_board.board_back_id = id
end
--endregion

---@param boardMedals BoardMedal[]
function N22MedalEditData:SortBoardMedals(boardMedals)
    table.sort(
        boardMedals,
        function(a, b)
            return a.index < b.index
        end
    )
end
---将板上勋章的index格式化为1-n
function N22MedalEditData:FormatBoardMedalIndex()
    self:SortBoardMedals(self.boardMedals)
    for i, boardMedal in ipairs(self.boardMedals) do
        boardMedal.index = i
    end
end
---将勋章下沉到队尾
function N22MedalEditData:SinkMedalById(id)
    local curBM = self:GetBoardMedalById(id)
    local curIndex = curBM.index
    for i, boardMedal in ipairs(self.boardMedals) do
        if boardMedal.index == curIndex then
            boardMedal.index = table.count(self.boardMedals)
        elseif boardMedal.index > curIndex then
            boardMedal.index = boardMedal.index - 1
        end
    end
end

---@return number 板上勋章上限
function N22MedalEditData:GetBoardMedalLimit()
    local limit = Cfg.cfg_global["MedalLImit"].IntValue
    return limit
end

--region 对外接口
---@param width number 实际板宽
---@param placementInfo medal_placement_info 摆放信息
---@return BoardMedal[]
function N22MedalEditData:GetMappingBoardMedalList(width, placementInfo)
    local ret = {}
    ---@type medal_position[]
    local medal_on_board = placementInfo.medal_on_board
    if medal_on_board then
        for id, srt in pairs(medal_on_board) do
            local bm = BoardMedal:New(id)
            bm.index = srt.z
            bm.pos = self:GetScaledPos(width, Vector2(srt.x, srt.y))
            bm.quat = Quaternion(srt.quatx, srt.quaty, srt.quatz, srt.quatw)
            bm.wh = Vector2(srt.w, srt.h) * self:GetScaleTimes(width)
            table.insert(ret, bm)
        end
        self:SortBoardMedals(ret)
    else
        Log.fatal("### medal_on_board nil.")
    end
    return ret
end
---@param width number 实际板宽
---@return number 返回勋章板宽与标准宽（whBoard.x）缩放比率
function N22MedalEditData:GetScaleTimes(width)
    local scaleTimes = width / self.whBoard.x
    return scaleTimes
end
---@param width number 实际板宽
---@return UnityEngine.Matrix4x4 适应勋章板宽的缩放矩阵
function N22MedalEditData:GetScaledMatrix(width)
    local scaleTimes = self:GetScaleTimes(width)
    local mtx4Scale = UnityEngine.Matrix4x4.identity
    mtx4Scale.m00 = mtx4Scale.m00 * scaleTimes
    mtx4Scale.m11 = mtx4Scale.m11 * scaleTimes
    mtx4Scale.m22 = mtx4Scale.m22 * scaleTimes
    return mtx4Scale
end
---@param width number 实际板宽
---@param pos Vector2  标准位置
---@return Vector2 实际位置
function N22MedalEditData:GetScaledPos(width, pos)
    local mtx4Scale = self:GetScaledMatrix(width)
    local v4 = mtx4Scale * Vector4(pos.x, pos.y, 0, 0)
    return Vector2(v4.x, v4.y)
end
---@param width number 实际板宽
---@param wh Vector2 标准宽高
---@return Vector2 实际宽高
function N22MedalEditData:GetScaledWidthHeight(width, wh)
    local scaleTimes = self:GetScaleTimes(width)
    local wh = wh * scaleTimes
    return wh
end

---@param width number 勋章板宽
---@return UnityEngine.Matrix4x4 返回缩放矩阵的逆矩阵
function N22MedalEditData:GetScaledMatrixInverse(width)
    local mtx4Scale = self:GetScaledMatrix(width)
    return mtx4Scale.inverse
end
---@param width number 实际板宽
---@param pos Vector2 实际位置
---@return Vector2 标准位置
function N22MedalEditData:GetScaledPosInverse(width, pos)
    local mtx4Scale = self:GetScaledMatrixInverse(width)
    local v4 = mtx4Scale * Vector4(pos.x, pos.y, 0, 0)
    return Vector2(v4.x, v4.y)
end
---@param width number 实际板宽
---@param wh Vector2 实际宽高
---@return Vector2 标准宽高
function N22MedalEditData:GetScaledWidthHeightInverse(width, wh)
    local scaleTimes = self:GetScaleTimes(width)
    local wh = wh / scaleTimes
    return wh
end
--endregion
--endregion

--region BoardMedal 板上勋章
---@class BoardMedal:Object
---@field id number 唯一id
---@field itemId number 对应道具id
---@field index number 索引，大的居上
---@field pos Vector2 坐标，相对于勋章板中心
---@field quat Quaternion 旋转
---@field wh Vector2 宽高，在原始的勋章板尺寸下，宽高是icon原始尺寸；其他尺寸下需要做等比缩放
---@field model string 勋章对应模型名，XXX.prefab
_class("BoardMedal", Object)
BoardMedal = BoardMedal

function BoardMedal:Constructor(id)
    self.id = id
    self.itemId = id
    self.index = 0
    self.pos = Vector2.zero
    self.quat = Quaternion.identity
    self.wh = Vector2.zero
    local cfgv = BoardMedal.CfgItemMedal(self.itemId)
    self.model = cfgv.Model .. ".prefab"

    self.mMedal = GameGlobal.GetModule(MedalModule)
    self.data = self.mMedal:GetN22MedalEditData()
end

---@return table cfg_item_medal1行
function BoardMedal.CfgItemMedal(itemId)
    local cfgv = Cfg.cfg_item_medal[itemId]
    if not cfgv then
        Log.fatal("### no data in cfg_item_medal. itemId=", self.itemId)
    end
    return cfgv
end
---@return string 获取板上勋章icon
function BoardMedal:IconMedal()
    return BoardMedal.IconMedalById(self.itemId)
end
---@return string 获取板上勋章icon
function BoardMedal.IconMedalById(id)
    local cfgv = BoardMedal.CfgItemMedal(id)
    return cfgv.IconMedal
end

---@return Vector2 获取本勋章的表现位置
function BoardMedal:PosView(width)
    local pos = self.data:GetScaledPos(width, self.pos)
    return pos
end

---@param pos Vector2 物体位置
---是否有未保存坐标
function BoardMedal:IsDirtyPos(pos)
    local isDirty = not BoardMedal.IsEqualVector2(self.pos, pos)
    return isDirty
end
---@param quat Quaternion 物体旋转
---是否有未保存旋转
function BoardMedal:IsDirtyRot(quat)
    local isDirty = not BoardMedal.IsEqualQuaternion(self.quat, quat)
    return isDirty
end
---是否有未保存坐标
function BoardMedal:IsDirtyIndex(index)
    local isDirty = not BoardMedal.IsEqualFloat(self.index, index)
    return isDirty
end
---@param fl number
---@param fr number
---两个浮点数是否相等
function BoardMedal.IsEqualFloat(fl, fr)
    local epsilon = 0.01
    local delta = fl - fr
    if -epsilon <= delta and delta <= epsilon then
        return true
    end
    return false
end
---@param v2l Vector2
---@param v2r Vector2
---两个Vector2是否相等
function BoardMedal.IsEqualVector2(v2l, v2r)
    if BoardMedal.IsEqualFloat(v2l.x, v2r.x) and BoardMedal.IsEqualFloat(v2l.y, v2r.y) then
        return true
    end
    return false
end
---@param quatl Quaternion
---@param quatr Quaternion
---两个Quaternion是否相等
function BoardMedal.IsEqualQuaternion(quatl, quatr)
    if
        BoardMedal.IsEqualFloat(quatl.x, quatr.x) and BoardMedal.IsEqualFloat(quatl.y, quatr.y) and
            BoardMedal.IsEqualFloat(quatl.z, quatr.z) and
            BoardMedal.IsEqualFloat(quatl.w, quatr.w)
     then
        return true
    end
    return false
end
--endregion

--region MedalAABB 勋章AABB类
---@class MedalAABB:Object
_class("MedalAABB", Object)
MedalAABB = MedalAABB

function MedalAABB:Constructor()
    self.min = Vector2.zero
    self.max = Vector2.zero
    self.center = Vector2.zero
end

---@param points Vector2[]
function MedalAABB:InitByPoints(points)
    local minX = 99999
    local minY = 99999
    local maxX = -99999
    local maxY = -99999
    for index, point in ipairs(points) do
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end
    self.min.x = minX
    self.min.y = minY
    self.max.x = maxX
    self.max.y = maxY
    self.center = (self.min + self.max) * 0.5
end

---@param aabb MedalAABB
---@return boolean
function MedalAABB:IntersectsAABB(aabb)
    local xIntersects = (self.max.x > aabb.min.x) and (self.min.x < aabb.max.x)
    local yIntersects = (self.max.y > aabb.min.y) and (self.min.y < aabb.max.y)
    return xIntersects and yIntersects
end
---@param point Vector2
---@return boolean
function MedalAABB:ContainsPoint(point)
    local xIntersects = (self.min.x < point.x) and (point.x < self.max.x)
    local yIntersects = (self.min.y < point.y) and (point.y < self.max.y)
    return xIntersects and yIntersects
end
---@param aabb MedalAABB
---@return boolean 本AABB是否全包含aabb
function MedalAABB:InvolveAABB(aabb)
    local minInvolve = (aabb.min.x > self.min.x) and (aabb.min.y > self.min.y)
    local maxInvolve = (aabb.max.x < self.max.x) and (aabb.max.y < self.max.y)
    return minInvolve and maxInvolve
end

--endregion
