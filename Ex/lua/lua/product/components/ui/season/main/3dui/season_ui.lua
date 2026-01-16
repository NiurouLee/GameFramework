---@class SeasonUI:Object
_class("SeasonUI", Object)
SeasonUI = SeasonUI

function SeasonUI:Constructor()
    ---@type SeasonUILevel[]
    self._levelWidgetPool = {} --关卡信息
    ---@type SeasonUISign[]
    self._signWidgetPool = {} --头顶信号
    self._seasonObj = GameGlobal.GetModule(SeasonModule):GetCurSeasonObj()
    ---@type SeasonMissionComponentInfo
    self._componentInfo = self._seasonObj:GetComponentInfo(ECCampaignSeasonComponentID.SEASON_MISSION)
    self:_InitUICanvas()
    self:_RefreshWidgets()
end

function SeasonUI:_InitUICanvas()
    ---@type SeasonManager
    self._mgr = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    self._uiCanvasRequest = ResourceManager:GetInstance():SyncLoadAsset("SeasonUICanvas.prefab", LoadType.GameObject)
    ---@type UnityEngine.GameObject
    self._gameObject = self._uiCanvasRequest.Obj
    self._gameObject.name = "UICanvas"
    self._gameObject.transform:SetParent(nil)
    UnityEngine.SceneManagement.SceneManager.MoveGameObjectToScene(self._gameObject, self._mgr:SeasonSceneManager():Scene())
    self._gameObject:SetActive(true)
    self._gameObject.transform.position = Vector3.zero
    ---@type UnityEngine.Canvas
    self._canvas = self._gameObject:GetComponent("Canvas")
    self._canvas.worldCamera = self._mgr:SeasonCameraManager():Camera()
    ---@type UIView
    self._view = self._gameObject:GetComponentInChildren(typeof(UIView))
    ---@type UISelectObjectPath
    self._level = self._view:GetUIComponent("UISelectObjectPath", "Level")
    ---@type UICustomWidgetPool
    self._sign = self._view:GetUIComponent("UISelectObjectPath", "Sign")
    self._atlasReq = ResourceManager:GetInstance():SyncLoadAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
    self._atlas = self._atlasReq.Obj
end

function SeasonUI:Dispose()
    if self._uiCanvasRequest then
        self._uiCanvasRequest:Dispose()
        self._uiCanvasRequest = nil
    end
    if self._atlasReq then
        self._atlasReq:Dispose()
        self._atlasReq = nil
    end
    table.clear(self._levelWidgetPool)
    table.clear(self._signWidgetPool)
    UnityEngine.Object.Destroy(self._gameObject)
end

function SeasonUI:Update(deltaTime)
end

function SeasonUI:Refresh()
    self:_RefreshWidgets()
end

---@param diff UISeasonLevelDiff
function SeasonUI:SwitchDiff(diff)
    self:_RefreshWidgets()
end

function SeasonUI:_RefreshWidgets()
    self:_CreateLevelWidgets()
    self:_CreateSignWidgets()
end

function SeasonUI:_CreateLevelWidgets()
    local mainLevels = self._mgr:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.MainLevel)
    local subLevels = self._mgr:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.SubLevel)
    local dailyLevels = self._mgr:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.DailyLevel)
    ---@type SeasonMapEventPoint[]
    local levels = {}
    if mainLevels then
        for _, value in pairs(mainLevels) do
            table.insert(levels, value)
        end
    end
    if subLevels then
        for _, value in pairs(subLevels) do
            table.insert(levels, value)
        end
    end
    if dailyLevels then
        for _, value in pairs(dailyLevels) do
            table.insert(levels, value)
        end
    end
    local count = table.count(levels)
    local poolLength = #self._levelWidgetPool
    if count > poolLength then
        for i = poolLength, count - 1 do
            ---@type UnityEngine.GameObject    
            local go = self._level:SpawnOneObject("SeasonUILevel")
            table.insert(self._levelWidgetPool, SeasonUILevel:New(go, self._atlas))
        end
    end
    for i = 1, #self._levelWidgetPool do
        local widget = self._levelWidgetPool[i]
        if i <= count then
            widget:SetData(levels[i], self._componentInfo)
        else
            widget:SetData(nil)
        end
    end
end

function SeasonUI:_CreateSignWidgets()
    self:ClearSignWidgets()
    for _, _type in pairs(SeasonEventPointType) do
        local eventPoints = self._mgr:SeasonMapManager():GetEventPointsByType(_type)
        if eventPoints then
            for _, eventPoint in pairs(eventPoints) do
                if eventPoint:IsUnLock() then
                    local curProgressExpress = eventPoint:CurProgressExpress()
                    if curProgressExpress then
                        local expresses = curProgressExpress:GetExpresses(SeasonExpressType.Sign)
                        if expresses then
                            for _, express in pairs(expresses) do
                                local content = express:Content()
                                ---@type SeasonSignType
                                local signType = content.type
                                if signType == SeasonSignType.Before then
                                    self:AddSign(eventPoint, express)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

--添加一个Sign
---@param eventPoint SeasonMapEventPoint
---@param express SeasonMapExpressBase
function SeasonUI:AddSign(eventPoint, express)
    local widget = self:_GetFreeSignWidget()
    if not widget then
        ---@type UnityEngine.GameObject    
        local go = self._sign:SpawnOneObject("SeasonUISign")
        widget = SeasonUISign:New(go, self._atlas)
        table.insert(self._signWidgetPool, widget)
    end
    widget:SetData(eventPoint, express)
end

--移除一个Sign
---@param eventPoint SeasonMapEventPoint
function SeasonUI:RemoveSign(eventPoint)
    for _, widget in pairs(self._signWidgetPool) do
        if widget:EventPoint() == eventPoint then
            widget:Clear()
            break
        end
    end
end

---@return SeasonUISign
function SeasonUI:_GetFreeSignWidget()
    for _, widget in pairs(self._signWidgetPool) do
        if widget:IsFree() then
            return widget
        end
    end
    return nil
end

function SeasonUI:ClearSignWidgets()
    for _, widget in pairs(self._signWidgetPool) do
        widget:Clear()
    end
end