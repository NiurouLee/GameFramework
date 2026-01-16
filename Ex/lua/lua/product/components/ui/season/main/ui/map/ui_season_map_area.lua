--
---@class UISeasonMapArea : UICustomWidget
_class("UISeasonMapArea", UICustomWidget)
UISeasonMapArea = UISeasonMapArea
--初始化
function UISeasonMapArea:OnShow(uiParams)
    local seasonID = 8001
    self._seasonMapCfg = Cfg.cfg_season_map[seasonID]
    self:InitWidget()

    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetUIModule(SeasonModule)
    ---@type SeasonManager
    self._seasonManager =self._seasonModule:SeasonManager()
    ---@type SeasonPlayerManager
    self._seasonPlayerManager = self._seasonManager:SeasonPlayerManager()
    ---@type SeasonPlayer
    self._seasonPlayer = self._seasonPlayerManager:GetPlayer()

    ---@type SeasonMapManager
    self._seasonMapManager = self._seasonManager:SeasonMapManager()

    self._cameraTransform = self._seasonManager:SeasonCameraManager():SeasonCamera():Transform()


    ---@type UnityEngine.Transform
    --self._leftUpAnchorTf = UnityEngine.GameObject.Find("LeftUpAnchor").transform
    self._leftUpAnchorPos = Vector3(self._seasonMapCfg.LeftUpAnchorPos[1],self._seasonMapCfg.LeftUpAnchorPos[2],self._seasonMapCfg.LeftUpAnchorPos[3])
    --self._leftUpAnchorTf.position = self._leftUpAnchorPos--Vector3(4.15,0,-8.99)
    ---@type UnityEngine.Transform
    --self._rightDownAnchorTf = UnityEngine.GameObject.Find("RightDownAnchor").transform
    self._rightDownAnchorpos = Vector3(self._seasonMapCfg.RightDownAnchorPos[1],self._seasonMapCfg.RightDownAnchorPos[2],self._seasonMapCfg.RightDownAnchorPos[3])
    --self._rightDownAnchorTf.position = self._rightDownAnchorpos--Vector3(-31.737,0,26.911)

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
    self:InitMapEvent()
    self:AttachEvent(GameEventType.UISeasonOnLevelDiffChanged, self.InitMapEvent) --界面内切换难度也走这里

end

--获取ui组件
function UISeasonMapArea:InitWidget()
    ---@type UnityEngine.Transform
    self._roleAnchorTf = self:GetUIComponent("Transform", "RoleAnchor")

    ---@type UnityEngine.RectTransform
    self._mapCenterRectTf = self:GetUIComponent("RectTransform", "MapCenter")
    
    local x = 2048
    local y = 1536
    local scale = self._seasonMapCfg.MapScale
    self._mapCenterRectTf.sizeDelta = Vector2(x * scale, y * scale)

    ---@type UICustomWidgetPool
    self.mapEventPool = self:GetUIComponent("UISelectObjectPath", "EventLayer")

    ---@type UnityEngine.RectTransform
    self._mapMask = self:GetUIComponent("RectTransform", "MapMask")
    self._originOffset = self._mapMask.anchoredPosition

    ---@type UnityEngine.RectTransform
    self._roleOutAnchor = self:GetUIComponent("RectTransform", "RoleOutAnchor")

    ---@type UnityEngine.Transform
    self._roleOutTf = self:GetUIComponent("Transform", "RoleOutAnchor")
    
    self._mapRadius = 240/2

    self._roleOutAnchorOffset = -1
end

function UISeasonMapArea:InitMapEvent()
    if self._seasonMapManager == nil then
        return
    end
    local dt = 0
    self:RefreshRoleAnchor(dt)
    local eventMains = self._seasonMapManager:GetEventPointsByType(SeasonEventPointType.MainLevel)
    local eventStorys = self._seasonMapManager:GetEventPointsByType(SeasonEventPointType.MainStory)
    local count = #eventMains + #eventStorys
    self.mapEventPool:SpawnObjects("UISingleSeasonMapEvent",count)

    ---@type UISingleSeasonMapEvent[]
    local list = self.mapEventPool:GetAllSpawnList()
    for i, v in ipairs(list) do
        if i<= #eventMains then
            local single = eventMains[i]
            v:SetData(single,self._mapCenterRectTf)
        else
            local single = eventStorys[i-#eventMains]
            v:SetData(single,self._mapCenterRectTf)
        end
    end
 
end

--设置数据
function UISeasonMapArea:SetData()
end

function UISeasonMapArea:OnHide()
    
end

function UISeasonMapArea:Update(dt)
    if self._cameraTransform == nil then
        return
    end
    self:RefreshRoleAnchor(dt)
    if self.mapEventPool then
        ---@type UISingleSeasonMapEvent[]
        local list = self.mapEventPool:GetAllSpawnList()
        for i, v in ipairs(list) do
            v:Update(dt)
        end
    end
end

function UISeasonMapArea:RefreshRoleAnchor(dt)
    ---@type UnityEngine.Transform
    local ctf = self._cameraTransform
    local ptf = self._seasonPlayer:Transform()

    --local angle = tf.eulerAngles
    --local roleAngle = self._roleAnchorTf.eulerAngles
    --roleAngle.z = angle.y+180
    --self._roleAnchorTf.eulerAngles =roleAngle

    local leftUpPos =self._leftUpAnchorPos
    local rightDownPos =  self._rightDownAnchorpos

    local cameraPos = ctf.position
    local mapPosDelta = rightDownPos - leftUpPos
    local curPosDelta = rightDownPos - cameraPos
    local percentX = (curPosDelta.x/mapPosDelta.x)
    local percentY = (curPosDelta.z/mapPosDelta.z)
    local anchoredPos = Vector2(percentX * self._mapCenterRectTf.sizeDelta.x, -percentY * self._mapCenterRectTf.sizeDelta.y)
    self._mapCenterRectTf.anchoredPosition = anchoredPos

    local playerPos = ptf.position
    curPosDelta = rightDownPos - playerPos
    percentX = (curPosDelta.x / mapPosDelta.x)
    percentY = (curPosDelta.z / mapPosDelta.z)

    local anchoredPos2 = Vector2(-percentX * self._mapCenterRectTf.sizeDelta.x, percentY * self._mapCenterRectTf.sizeDelta.y)
    local rolePOS = anchoredPos + anchoredPos2

    local offset = self._originOffset
    local halfUIRadius = self._mapRadius 
    local delta = (rolePOS - self._mapMask.anchoredPosition+ offset).magnitude 
    local dir = (rolePOS - self._mapMask.anchoredPosition+ offset).normalized

    if delta > halfUIRadius + self._roleOutAnchorOffset then
        local newPos = self._mapMask.anchoredPosition - offset + halfUIRadius * dir
        --self._roleAnchorTf.anchoredPosition = newPos
        --self._roleOutAnchor.anchoredPosition = newPos  
        self._roleAnchorTf.anchoredPosition = newPos
        --self._roleOutAnchor.gameObject:SetActive(true)
        --self._roleOutTf.up = dir

    else
        self._roleOutAnchor.gameObject:SetActive(false)
        self._roleAnchorTf.anchoredPosition = anchoredPos + anchoredPos2
    end
    
end