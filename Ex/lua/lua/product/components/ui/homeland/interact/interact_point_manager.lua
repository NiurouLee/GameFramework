---@class InteractPointManager:Object
_class("InteractPointManager", Object)
InteractPointManager = InteractPointManager

function InteractPointManager:Constructor()
    self._interactPoints = {}
    self._interactAreas = {}
end

---@param homelandClient HomelandClient
function InteractPointManager:Init(homelandClient)
    ---@type HomelandCharacterManager
    self._homelandCharacterManager = homelandClient:CharacterManager()
    self._triggerInteractPoints = {}
    self._client = homelandClient
end

function InteractPointManager:Dispose()
    for i = 1, #self._interactPoints do
        self._interactPoints[i]:Dispose()
    end
    self._interactPoints = nil
    self._triggerInteractPoints = nil
    self._homelandCharacterManager = nil

    for i = 1, #self._interactAreas do
        self._interactAreas[i]:Dispose()
    end
    self._interactAreas = nil
end

function InteractPointManager:Update(deltaTimeMS)
    if self._last_update_time == nil then
        self._last_update_time = 0
    end
    if self._cur_time == nil then
        self._cur_time = 0
    end
    self._cur_time = self._cur_time + deltaTimeMS
    if (self._cur_time - self._last_update_time < 200) then
        return
    end
    self._last_update_time = self._cur_time

    local characterTransform = self._homelandCharacterManager:GetCharacterTransform()
    if not characterTransform then
        return
    end
    local characterPostion = characterTransform.position

    --检查触发区域
    for i = 1, #self._interactAreas do
        ---@type InteractArea
        local interactArea = self._interactAreas[i]
        if interactArea:IsActive() then
            if interactArea:IsTrigger(characterPostion) then
                interactArea:InteractArea()
            else
                interactArea:UnInteractArea()
            end
        end
    end

    --删除无效的区域
    for i = #self._interactAreas, 1, -1 do
        local interactArea = self._interactAreas[i]
        if not interactArea:IsActive() then
            table.remove(self._interactAreas, i)
        end
    end

    --检查触发点
    for i = 1, #self._interactPoints do
        ---@type InteractPoint
        local interactPoint = self._interactPoints[i]
        if self._homelandCharacterManager:CharacterInteractable(interactPoint:GetPointType()) and
            interactPoint:IsTrigger(characterPostion) and
            interactPoint:Interactable()
        then
            self:_AddTriggerPoint(interactPoint)
        else
            self:_RemoveTriggerPoint(interactPoint)
        end
    end
end

function InteractPointManager:GetPoints(typeFilter)
    local points = {}

    for i = 1, #self._interactPoints do
        if self._interactPoints[i]:GetPointType() == typeFilter then
            table.insert(points, self._interactPoints[i])
        end
    end

    return points
end

function InteractPointManager:_AddTriggerPoint(point)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.EnterBuildInteract, point)
    if self._triggerInteractPoints[point] then
        return
    end

    self._triggerInteractPoints[point] = true
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowInteractUI)
end

function InteractPointManager:_RemoveTriggerPoint(point)
    if not self._triggerInteractPoints[point] then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.LeaveBuildInteract, point)
    self._triggerInteractPoints[point] = nil

    for k, v in pairs(self._triggerInteractPoints) do
        if k and v then
            return
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideInteractUI)
end

function InteractPointManager:ShowDialog(name, ...)
    GameGlobal.UIStateManager():ShowDialog(name, ...)
end

function InteractPointManager:CloseDialog(name)
    GameGlobal.UIStateManager():CloseDialog(name)
end

function InteractPointManager:AddBuildInteractPoint(build, index, interactPointCfgId)
    if self._client:IsVisit() then
        return self:_AddVisitPoint(build, index, interactPointCfgId)
    else
        local interactPoint = InteractPoint:New(build, index, interactPointCfgId)
        self._interactPoints[#self._interactPoints + 1] = interactPoint
        return interactPoint
    end
end

---@param interactPoint InteractPoint
function InteractPointManager:RemoveBuildInteractPoint(interactPoint)
    if not self._interactPoints then
        return
    end
    for i = 1, #self._interactPoints do
        if self._interactPoints[i] == interactPoint then
            table.remove(self._interactPoints, i)
            self:_RemoveTriggerPoint(interactPoint)
            return
        end
    end
end

function InteractPointManager:GetInteractPoints()
    return self._interactPoints
end

function InteractPointManager:AddBuildInteractArea(build, distance)
    local interactArea = InteractArea:New(build, distance)
    self._interactAreas[#self._interactAreas + 1] = interactArea
    return interactArea
end

---@param interactArea InteractArea
function InteractPointManager:RemoveBuildInteractArea(interactArea)
    if not self._interactAreas then
        return
    end
    for i = 1, #self._interactAreas do
        if self._interactAreas[i] == interactArea then
            table.remove(self._interactAreas, i)
            interactArea:UnInteractArea()
            return
        end
    end
end

function InteractPointManager:GetInteractAreas()
    return self._interactAreas
end

---@param build HomeBuilding
function InteractPointManager:_AddVisitPoint(build, index, interactPointCfgId)
    local interactPoint = nil
    local cfg = Cfg.cfg_building_interact_point[interactPointCfgId]
    if cfg.FunctionType == InteractPointType.Build then
        --白塔制造，显示交互点的前提是有打造队列
        ---@type UIHomelandModule
        local uiModule = GameGlobal.GetUIModule(HomelandModule)
        interactPointCfgId = InteractPointType.Visit_Build
        interactPoint = InteractPoint:New(build, index, interactPointCfgId)
    elseif cfg.FunctionType == InteractPointType.Storehouse then
        --仓库，显示交互点的前提是有礼物可领
        ---@type UIHomelandModule
        local uiModule = GameGlobal.GetUIModule(HomelandModule)
        if uiModule:GetVisitUIInfo():HasGift() then
            interactPointCfgId = InteractPointType.Visit_GetGift
            interactPoint = InteractPoint:New(build, index, interactPointCfgId)
        end
    elseif cfg.FunctionType == InteractPointType.Breed then
        --浇水，显示交互点的前提是该地块可浇水
        ---@type UIHomelandModule
        local uiModule = GameGlobal.GetUIModule(HomelandModule)
        ---@type CultivationInfo
        local info = uiModule:GetVisitInfo().cultivation_info
        ---@type HomelandBreedLand
        local land = build
        if info.land_cultivation_infos[land:PstID()] and not land:IsMature() then
            interactPointCfgId = InteractPointType.Visit_Water
            interactPoint = InteractPoint:New(build, index, interactPointCfgId)
        end
    elseif cfg.FunctionType == InteractPointType.ShowMedalWall then
        --勋章墙查看，修复后才能查看
        if not build:IsShabby() then
            interactPoint = InteractPoint:New(build, index, interactPointCfgId)
        end
    end
    if interactPoint then
        self._interactPoints[#self._interactPoints + 1] = interactPoint
    end
    return interactPoint
end
