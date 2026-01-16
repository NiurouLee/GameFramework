
--检查UI头像层数（亮暗十字图标视为1层0层）
_class("CheckUIPetLayerCount_Test", AutoTestCheckPointBase)
CheckUIPetLayerCount_Test = CheckUIPetLayerCount_Test

function CheckUIPetLayerCount_Test:BeforeCheck()
end

function CheckUIPetLayerCount_Test:Check(notify)
    local expect = self._args.expect
    local pstid = self._entity:PetPstID():GetPstID()
    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    local num = svc:ReadBlackBoard_Test("UIPetAccNum_" .. pstid) or 0
    self._message = " UIPetLayerCount:" .. num .. " expect:" .. expect
    return num == expect
end

--CheckUIPetLayerCount_Test的扩展，用于主动技能量点和被动技Buff层数均显示时的UI头像层数检查
--检查UI头像层数（亮暗十字图标视为1层0层）
_class("CheckUIPetPassiveSkillBuffLayerCount_Test", AutoTestCheckPointBase)
CheckUIPetPassiveSkillBuffLayerCount_Test = CheckUIPetPassiveSkillBuffLayerCount_Test

function CheckUIPetPassiveSkillBuffLayerCount_Test:BeforeCheck()
end

function CheckUIPetPassiveSkillBuffLayerCount_Test:Check(notify)
    local expect = self._args.expect
    local pstid = self._entity:PetPstID():GetPstID()
    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    local num = svc:ReadBlackBoard_Test("UIPetBuffLayerNum_" .. pstid) or 0
    self._message = " UIPetBuffLayerCount:" .. num .. " expect:" .. expect
    return num == expect
end

--检查血条buff图标层数（不显示的视为0层）
_class("CheckUIBuffIcon_Test", AutoTestCheckPointBase)
CheckUIBuffIcon_Test = CheckUIBuffIcon_Test

function CheckUIBuffIcon_Test:BeforeCheck()
end

function CheckUIBuffIcon_Test:Check(notify)
    local buffID = self._args.buffID
    local expect = self._args.expect
    local entityID = self._entity:GetID()
    local layer = 0
    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    local t = svc:ReadBlackBoard_Test("UIHPBuff_" .. entityID)
    if t then
        layer = t[buffID] or 0
    end
    self._message = " UI Buff Icon LayerCount:" .. layer .. " expect:" .. expect
    return layer == expect
end

--检查血条盾是否存在
_class("CheckUIHPShieldExist_Test", AutoTestCheckPointBase)
CheckUIHPShieldExist_Test = CheckUIHPShieldExist_Test

function CheckUIHPShieldExist_Test:BeforeCheck()
end

function CheckUIHPShieldExist_Test:Check(notify)
    local val = self._entity:HP():GetShieldValue()
    if self._args.exist then
        return val > 0
    else
        return val == 0
    end
end

--检查次数盾数量
_class("CheckUILayerShieldCount_Test", AutoTestCheckPointBase)
CheckUILayerShieldCount_Test = CheckUILayerShieldCount_Test

function CheckUILayerShieldCount_Test:BeforeCheck()
end

function CheckUILayerShieldCount_Test:Check(notify)
    local expect = self._args.expect
    local entityID = self._entity:GetID()

    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    local cnt = svc:ReadBlackBoard_Test("UIHPLayerShieldCount_" .. entityID, 0)

    self._message = " UI LayerShieldCount:" .. cnt .. " expect:" .. expect
    return expect == cnt
end

--检查格子表现颜色
_class("CheckRenderPieceType_Test", AutoTestCheckPointBase)
CheckRenderPieceType_Test = CheckRenderPieceType_Test

function CheckRenderPieceType_Test:BeforeCheck()
end

function CheckRenderPieceType_Test:Check(notify)
    local pos = Vector2.Index2Pos(self._args.pos)
    ---@type PieceServiceRender
    local svc = self._world:GetService("Piece")
    local entity = svc:FindPieceEntity(pos)
    local pieceType = entity:Piece():GetPieceType()
    self._message = "pos=" .. self._args.pos .. " pieceType=" .. pieceType .. " expect=" .. self._args.pieceType
    if pieceType == self._args.pieceType then
        return true
    end
    return false
end
