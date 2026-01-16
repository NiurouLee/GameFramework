--
---@class UISingleSeasonMapEvent : UICustomWidget
_class("UISingleSeasonMapEvent", UICustomWidget)
UISingleSeasonMapEvent = UISingleSeasonMapEvent
--初始化
function UISingleSeasonMapEvent:OnShow(uiParams)
    self:InitWidget()

    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetUIModule(SeasonModule)
    ---@type SeasonManager
    self._seasonManager =self._seasonModule:SeasonManager()
    ---@type SeasonPlayerManager
    self._seasonPlayerManager = self._seasonManager:SeasonPlayerManager()
    ---@type SeasonPlayer
    self._seasonPlayer = self._seasonPlayerManager:GetPlayer()

    ---@type seasonMapManager
    self._seasonMapManager = self._seasonManager:SeasonMapManager()
    ---@type SeasonMapEventPoint
    self._bindEventData = nil
end

--获取ui组件
function UISingleSeasonMapEvent:InitWidget()
    local seasonID = 8001
    self._seasonMapCfg = Cfg.cfg_season_map[seasonID]
    ---@type UnityEngine.RectTransform
    self._rootRectTf = self:GetUIComponent("RectTransform", "Icon")

    ---@type UnityEngine.UI.Image
    self._iconImage = self:GetUIComponent("Image", "Icon")
    
    --[[---@type UnityEngine.Transform
    self._leftUpAnchorTf = UnityEngine.GameObject.Find("LeftUpAnchor").transform
    ---@type UnityEngine.Transform
    self._rightDownAnchorTf = UnityEngine.GameObject.Find("RightDownAnchor").transform]]--

    self._leftUpAnchorPos = Vector3(self._seasonMapCfg.LeftUpAnchorPos[1],self._seasonMapCfg.LeftUpAnchorPos[2],self._seasonMapCfg.LeftUpAnchorPos[3])
    self._rightDownAnchorpos = Vector3(self._seasonMapCfg.RightDownAnchorPos[1],self._seasonMapCfg.RightDownAnchorPos[2],self._seasonMapCfg.RightDownAnchorPos[3])

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
end

--设置数据
---@param point SeasonMapEventPoint
---@param mapRect RectTransform
function UISingleSeasonMapEvent:SetData(point,mapRect)
    if point then
        local pos = point:Position()
        self._bindEventData = point

        local icon = self._bindEventData:EventMapIcon()
        if icon then
            local sprite =self._atlas:GetSprite(icon)
            if sprite then
                self._iconImage.sprite = sprite
            end
            
        else
            self._iconImage.sprite = nil
        end

        self.mapRect = mapRect
        self:RefreshMapIcon(pos)
    end
end

function UISingleSeasonMapEvent:OnHide()
    
end

function UISingleSeasonMapEvent:Update(dt)
    if self._seasonPlayer ==nil or self._bindEventData ==nil then
        return
    end
    if not self._bindEventData:IsShow() then
        self._rootRectTf.gameObject:SetActive(false)
        return
    else
        self._rootRectTf.gameObject:SetActive(true)
    end

    self:RefreshMapIcon(self._bindEventData:Position())
end

function UISingleSeasonMapEvent:RefreshMapIcon(pos)
    ---@type UnityEngine.Transform
    local tf = self._seasonPlayer:Transform()
    local singlePos = pos
    local leftUpPos =self._leftUpAnchorPos
    local rightDownPos =  self._rightDownAnchorpos
    local rolePos = tf.position

    local mapPosDelta = rightDownPos - leftUpPos
    local curPosDelta = rightDownPos - singlePos
    local percentX = (curPosDelta.x/mapPosDelta.x)
    local percentY = (curPosDelta.z/mapPosDelta.z)
    local leftUpUIPos = Vector2(self.mapRect.anchoredPosition.x - self.mapRect.sizeDelta.x,self.mapRect.anchoredPosition.y -self.mapRect.sizeDelta.y)
    local rightDownUIPos = self.mapRect.anchoredPosition
    local anchoredPos = rightDownUIPos - leftUpUIPos
    anchoredPos = rightDownUIPos - Vector2(anchoredPos.x*percentX,-anchoredPos.y*percentY )

    self._rootRectTf.anchoredPosition =anchoredPos

end