--[[
    家园宝物管理器
]]
TreasureBirthPosType = {
    Good = 0, --普通刷新点
    Bad = 1 --保底刷新点
}

_class("HomelandTreasureManager", Object)
HomelandTreasureManager = HomelandTreasureManager

function HomelandTreasureManager:Constructor()
end

function HomelandTreasureManager:Init(homeClient)
    ---@type HomelandClient
    self._homelandClient = homeClient
    ---@type InteractPointManager
    self._interactPointMng = homeClient:InteractPointManager()
    ---@type HomeBuildManager
    self._buildMng = homeClient:BuildManager()
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    ---@type homelandTreasure
    self._treasureInfo = self._homelandModule:GetTreasureInfo()
    ---@type HomelandTreasure
    self._treasures = {}

    self._enterCallback = GameHelper:GetInstance():CreateCallback(self.DisposeTreasure, self)
    self._exitCallback = GameHelper:GetInstance():CreateCallback(self.ShowTreasure, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.EnterFindTreasure, self._enterCallback)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.ExitFindTreasure, self._exitCallback)

    self._treaCallback = GameHelper:GetInstance():CreateCallback(self.TreasureHandle, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.TreasureRemove, self._treaCallback)
end

function HomelandTreasureManager:Dispose()
    
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.EnterFindTreasure, self._enterCallback)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.ExitFindTreasure, self._exitCallback)
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.TreasureRemove, self._treaCallback)

    self:DisposeTreasure()
    
    self._homelandClient = nil
    self._homelandModule = nil
end

--
function HomelandTreasureManager:DisposeTreasure()
    for k, v in pairs(self._treasures) do
        v:Dispose()
    end
    self._treasures = {}
end

function HomelandTreasureManager:HomelandClient()
    return self._homelandClient
end

function HomelandTreasureManager:HomelandModule()
    return self._homelandModule
end

--刷新一下宝物
function HomelandTreasureManager:RefreshTreasure()
    local cfg = GameGlobal.GetUIModule(HomelandModule):GetCurrentToolCfg(ToolType.TT_SHOVEL)
    if cfg == nil then
        return false
    end

    local limit = Cfg.cfg_homeland_global["TreasureCountLimit"].IntValue
    if table.count(self._treasureInfo.treasures) >= limit then
        return false
    end
    local item_id = Cfg.cfg_homeland_global["TreasureRefreshItemId"].IntValue
    local im = GameGlobal.GetModule(ItemModule)
    if im:GetItemCount(item_id) <= 0 then --没有道具不刷新
        return false
    end
    local range = Cfg.cfg_homeland_global["TreasureOccupyRange"].FloatValue
    local birthID = nil
    local cfgs = Cfg.cfg_homeland_treasure_birth {BirthType = TreasureBirthPosType.Good}
    table.shuffle(cfgs)--先随机，省效率
    for i, cfg in ipairs(cfgs) do
        if not self._treasureInfo.treasures[cfg.ID] then
            local pos = Vector3(cfg.BirthPos[1], cfg.BirthPos[2], cfg.BirthPos[3])
            if not self:IsBirthPosOccupied(pos, range) then
                birthID = cfg.ID
                break
            end
        end
    end
    if birthID == nil then
        cfgs = Cfg.cfg_homeland_treasure_birth {BirthType = TreasureBirthPosType.Bad}
        table.shuffle(cfgs)--先随机，省效率
        for i, cfg in ipairs(cfgs) do
            if not self._treasureInfo.treasures[cfg.ID] then
                birthID = cfg.ID
                break
            end
        end
    end
    if birthID == nil then --理论上不会出现这个情况
        Log.error("HomelandTreasureManager:OnEnterHomeland()  birthID == nil.")
        return false
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            local res, trea = self._homelandModule:HomelandGetNewTreasure(TT, birthID)
            if res:GetSucc() then
                self._treasureInfo = trea
            end

            self:ShowTreasure()
        end
    )
    return true
end

--OnEnterHomeland
function HomelandTreasureManager:OnEnterHomeland()
    if self:RefreshTreasure() == false then
        self:ShowTreasure()
    end
end

--检查宝物出生点是否被占用
function HomelandTreasureManager:IsBirthPosOccupied(pos, range)
    ---@type HomeBuilding[]
    --local buildings = self._buildMng:GetBuildings()

    --为了简单，以坐标为中心，半径为range的四个点做检测
    local cb = function (newPos, hitdis)
        local canStart, hits = UnityEngine.AI.NavMesh.SamplePosition(newPos, nil, hitdis, UnityEngine.AI.NavMesh.AllAreas)
        if canStart then
            return false
        end
        return true
    end

    --中心坐标，策划填写的Y值，不能和真实值相差1以上
    if cb(pos, 2) == true then
        return true
    end

    pos.x = pos.x + range
    if cb(pos, 1) == true then
        return true
    end

    pos.x = pos.x - range
    pos.z = pos.z - range
    if cb(pos, 1) == true then
        return true
    end

    pos.x = pos.x - range
    pos.z = pos.z + range
    if cb(pos, 1) == true then
        return true
    end

    pos.x = pos.x + range
    pos.z = pos.z + range
    if cb(pos, 1) == true then
        return true
    end

    return false
end

--显示宝物
function HomelandTreasureManager:ShowTreasure()
    local sceneManager = self._homelandClient:SceneManager()
    local root = sceneManager:RuntimeRootTrans()
    ---@param v treasureInfo
    for birthID, v in pairs(self._treasureInfo.treasures) do
        if v.state ~= TreasureState.TS_DESTROY then
            local treasure = HomelandTreasure:New(self, birthID, v)
            self._treasures[birthID] = treasure
            treasure:Show(root)
        end
    end
end

--获取宝物
function HomelandTreasureManager:GetTreasure(birthID)
    return self._treasures[birthID]
end

--获取宝物状态 TreasureState
function HomelandTreasureManager:GetTreasureState(birthID)
    local info = self._treasures[birthID]
    if info == nil then
        return TreasureState.TS_DESTROY
    end

    return info:GetState()
end

--通过光灵pstid，获得宝物状态
--也可以通过IsOccupied()接口直接调用GetTreasureState
function HomelandTreasureManager:GetTreasureByPet(pstID)
    for birthID, v in pairs(self._treasureInfo.treasures) do
        if v.pet_id == pstID then
            return v.state
        end
    end
    return TreasureState.TS_DESTROY
end

--删除宝物
function HomelandTreasureManager:DelTreasure(birthID)
    local t = self._treasures[birthID]
    if t then
        t:Dispose()
    end
    self._treasures[birthID] = nil
end

---@return table<number,HomelandTreasure>
function HomelandTreasureManager:GetAllTreasure()
    local vv = {}
    for k, v in pairs(self._treasures) do
        if v:GetGameObj() ~= nil then
            vv[k] = v
        end
    end    

    return vv
end

--
function HomelandTreasureManager:TreasureHandle(delmap)
    if delmap == nil then
        return
    end

    for k, v in pairs(delmap) do
        self:DelTreasure(v)
    end    
end
