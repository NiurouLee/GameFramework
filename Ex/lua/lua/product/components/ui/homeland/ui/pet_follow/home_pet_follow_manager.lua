---@class HomePetFollowManager:Object
_class("HomePetFollowManager", Object)
HomePetFollowManager = HomePetFollowManager
--- @class PetFollowShapeType
local PetFollowShapeType = {
    Freedom = 0,--自由
    Row = 1,--一字型
    Eight = 2,--人字形
    Rect = 3,--矩形
    Circle = 4,--圆形
    Ten = 5,--十字
    Triangle = 6,--三角
    TowRow = 7,--两行
    TwoClu = 8,--两列
    Semi = 9,--半圆
}
_enum("PetFollowShapeType", PetFollowShapeType)
function HomePetFollowManager:Constructor()
    --当前的阵型，存本地
    ---@type RoleModule
    self._roleModule = GameGlobal.GetModule(RoleModule)
    self._openid = self._roleModule:GetPstId()
    local key = "home_pet_follow_type"
    self._key = key .. self._openid
    ---@type PetFollowShapeType
    self._type = LocalDB.GetInt(self._key, 0)
    self._shape = nil

    self:GetShapes()
end
function HomePetFollowManager:Dispose()
end
function HomePetFollowManager:GetShapes()
    local cfgs = Cfg.cfg_home_pet_follow_shape {}
    local tab = {}
    if cfgs and next(cfgs) then
        for i = 1, #cfgs do
            local cfg = cfgs[i]
            local data = {}
            data.Sort = cfg.Sort
            data.Shape = cfg.Shape
            data.Icon = cfg.Icon
            data.Type = cfg.Type
            data.Rate = cfg.Rate
            table.insert(tab, data)
        end
        table.sort(
            tab,
            function(a, b)
                return a.Sort < b.Sort
            end
        )
        local tmpIdx = nil
        for i = 1, #tab do
            local item = tab[i]
            local type = item.Type
            if type == self._type then
                tmpIdx = i
                break
            end
        end
        if tmpIdx then
            local tmpItem = tab[tmpIdx]
            table.remove(tab, tmpIdx)
            table.insert(tab, 1, tmpItem)
        end
    end
    self._shape = tab[1]
    return tab
end
function HomePetFollowManager:CurrentShape()
    return self._type
end
function HomePetFollowManager:ChangeShape(type)
    if self._type == type then
        return
    end
    self._type = type
    self:GetShapes()
    LocalDB.SetInt(self._key, type)

    ---@type UIHomelandModule
    local uiModule = GameGlobal.GetUIModule(HomelandModule)
    local client = uiModule:GetClient()
    client:PetManager():RefreshFollowPets()
end
function HomePetFollowManager:GetPosOffset(idx)
    if self._shape and self._shape.Type ~= PetFollowShapeType.Freedom then
        local tab = self._shape.Shape
        local shape = tab[1]
        local offset = shape[idx].pos
        local rate = self._shape.Rate
        return Vector3(offset.x * rate, 0, offset.z * rate)
    end
    return nil
end
function HomePetFollowManager:GetRot(idx)
    if self._shape and self._shape.Type ~= PetFollowShapeType.Freedom then
        local tab = self._shape.Shape
        local shape = tab[1]
        local rot = shape[idx].rot
        return rot
    end
    return nil
end
