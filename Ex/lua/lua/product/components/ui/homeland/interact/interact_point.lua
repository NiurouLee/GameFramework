---@class InteractPointType:InteractPointType
local InteractPointType = {
    None = 0,
    Info = 1,
    Build = 2,
    PetCommunication = 3, --主角交互
    CutTree = 4,
    Treasure = 5, --宝物
    TreasureBoard = 6, --宝物木牌
    PetBuilding = 7, --光灵建组交互
    Wishing = 8, --许愿池
    Raise = 9, --饲养
    Shop = 10, --商店
    Breed = 11, --培育
    EnterDomitory = 12, --进入宿舍
    FindTreasure = 13, --寻宝小游戏
    Mining = 14, --挖矿
    Photo = 15, --博物馆
    Storehouse = 16, --仓库
    FixBuilding = 17, --修复破损建筑
    TreeDye = 18, --奇异树染色
    RoleInteract = 19, --主角交互
    Album = 20, --唱片集
    Aquarium = 21, --水族箱
    Clean = 22, --清理父建筑挂点
    HomelandShop = 23, --家园商店
    FlushingRoom = 24, --冲水房，主角换泳装的地方
    RoleSwimmingArea = 25, --主角游泳区域
    Invite = 26, -- 家具邀请
    EditMedalWall = 27, --勋章墙展示编辑
    ShowMedalWall = 28, --勋章墙查看
    Movie = 29,  --拍电影

    --以下是拜访用的交互点
    Visit_Build = 2001, --拜访，为好友加速
    Visit_Water = 2002, --拜访，浇水加速培育
    Visit_GetGift = 2003, --拜访，仓库领取礼物
    TaskNpc = 34, --任务Npc
    --家园任务npc
    TracePoint = 35, --追踪
}
_enum("InteractPointType", InteractPointType)

---@class InteractPoint:Object
_class("InteractPoint", Object)
InteractPoint = InteractPoint

function InteractPoint:Constructor(build, index, interactPointCfgId)
    local cfg = Cfg.cfg_building_interact_point[interactPointCfgId]
    if not cfg then
        return
    end
    ---@type BuildBase
    self._build = build
    self._index = index
    ---@type InteractPointType
    self._pointType = cfg.FunctionType
    self._pointName = StringTable.Get(cfg.Name)
    self._icon = cfg.Icon
    self.interactDistance = cfg.Distance
    self._interactObject = nil
    self._useBoxArea = cfg.UseBoxArea
    self._cfg = cfg
end

function InteractPoint:Dispose()
end

function InteractPoint:GetBuild()
    return self._build
end

function InteractPoint:GetIndex()
    return self._index
end

---@return InteractPointType
function InteractPoint:GetPointType()
    return self._pointType
end

function InteractPoint:GetPointName()
    return self._pointName
end

function InteractPoint:GetPointIcon()
    return self._icon
end

function InteractPoint:GetCfg()
    return self._cfg
end

function InteractPoint:GetRedPointStatus()
    return self._build:GetInteractRedStatus(self._pointType, self._index)
end

---@param interactBtn UIInteractPoint
function InteractPoint:Interact(interactBtn)
    if not self._build then
        return
    end

    self._build:Interact(self._pointType, self._index, self, interactBtn)
end

---@param pos Vector3
function InteractPoint:IsTrigger(pos)
    if not pos then
        return false
    end

    if self._useBoxArea then
        local boxCollider = self:_GetInteractBoxCollider()
        if not boxCollider then
            Log.fatal("矩形交互未设置BoxCollider！！！")
            return false
        end
        local closestPoint = boxCollider:ClosestPoint(pos)
        local distance = Vector3.Distance(closestPoint, pos)
        return distance <= self.interactDistance
    else
        local interactPos = self:_GetInteractPosition()
        if not interactPos then
            return false
        end
        local distance = Vector3.Distance(interactPos, pos)
        return distance <= self.interactDistance
    end
end

function InteractPoint:Equal(build, index)
    return build == self._build and index == self._index
end

function InteractPoint:_GetInteractPosition()
    if not self._build then
        return nil
    end
    return self._build:GetInteractPosition(self._index)
end

---@return UnityEngine.BoxCollider
function InteractPoint:_GetInteractBoxCollider()
    if not self._build then
        return nil
    end
    return self._build:GetInteractBoxCollider(self._index)
end

function InteractPoint:GetInteractObject()
    return self._interactObject
end

--当前交互对象
function InteractPoint:SetInteractObject(interactObject)
    self._interactObject = interactObject
end

function InteractPoint:GetDistance(pos)
    local interactPos = self:_GetInteractPosition()

    if not interactPos then
        return -1
    end

    if not pos then
        return -1
    end

    return Vector3.Distance(interactPos, pos)
end

function InteractPoint:Interactable()
    if self:GetPointType() == InteractPointType.PetBuilding or 
    self:GetPointType() == InteractPointType.RoleInteract or
    self:GetPointType() == InteractPointType.Invite or
    self:GetPointType() == InteractPointType.RoleSwimmingArea then
        return  self:GetBuild():Interactable() 
    elseif self:GetPointType() == InteractPointType.FlushingRoom then
        ---@type HomeBuilding
        local building = self:GetBuild()
        return building:Interactable()
    end
    return true
end
