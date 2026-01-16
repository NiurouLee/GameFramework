---@class UISeasonMainOvalTip:Object
_class("UISeasonMainOvalTip", Object)
UISeasonMainOvalTip = UISeasonMainOvalTip

---@param type UISeasonOvalTipType
function UISeasonMainOvalTip:Constructor(target, req, type, onClick)
    self._req = req
    self._onClick = onClick

    ---@type UnityEngine.GameObject
    self._gameObject = req.Obj
    ---@type UnityEngine.RectTransform
    self._rectTransform = self._gameObject:GetComponent(typeof(UnityEngine.RectTransform))
    ---@type UIView
    self._uiView = self._gameObject:GetComponent(typeof(UIView))
    self._uiView:SetShow(true, self)
    self._icon = self._uiView:GetGameObject("Icon")
    self._arrowObj = self._uiView:GetGameObject("Arrow")
    ---@type UnityEngine.RectTransform
    self._arrowRect = self._uiView:GetUIComponent("RectTransform", "Arrow")
    self._arrowIcon = self._uiView:GetUIComponent("Image", "ArrowIcon")

    self._atlasReq = ResourceManager:GetInstance():SyncLoadAsset("UISeasonMain.spriteatlas", LoadType.SpriteAtlas)
    self._atlas = self._atlasReq.Obj

    self:ResetTarget(target, type)
end

function UISeasonMainOvalTip:TargetWorldPos()
    if self._type == UISeasonOvalTipType.Player then
        ---@type SeasonPlayer
        local target = self._target
        return target:Position() --主角的位置 每帧可能都在变
    elseif self._type == UISeasonOvalTipType.Mission then
        ---@type SeasonMapEventPoint
        local target = self._target
        return target:Position()
    elseif self._type == UISeasonOvalTipType.Daily then
        ---@type SeasonMapEventPoint
        local target = self._target
        return target:Position()
    elseif self._type == UISeasonOvalTipType.Box then
        ---@type SeasonMapEventPoint
        local target = self._target
        return target:Position()
    end
end

function UISeasonMainOvalTip:Show()
    self._isIn = false --不在椭圆内 显示提示
    self._gameObject:SetActive(true)
end

function UISeasonMainOvalTip:Hide()
    self._isIn = true --在椭圆内 不显示提示
    self._gameObject:SetActive(false)
end

function UISeasonMainOvalTip:Delete()
    self._req = nil
    self._gameObject = nil
    self._uiView:SetShow(false, self)
    self._uiView = nil
    self._atlasReq:Dispose()
    self._atlasReq = nil
end

function UISeasonMainOvalTip:GetReq()
    return self._req
end

function UISeasonMainOvalTip:Dispose()
    self._req:Dispose()
    self:Delete()
end

function UISeasonMainOvalTip:IsInOval()
    return self._isIn
end

function UISeasonMainOvalTip:Sync(pos, rot)
    self._rectTransform.anchoredPosition = pos
    self._arrowRect.localRotation = rot
end

function UISeasonMainOvalTip:Type()
    return self._type
end

---@return SeasonMapEventPoint|SeasonPlayer
function UISeasonMainOvalTip:Target()
    return self._target
end

function UISeasonMainOvalTip:IconOnClick()
    self._onClick(self)
end

function UISeasonMainOvalTip:ArrowIconOnClick()
    self._onClick(self)
end

function UISeasonMainOvalTip:ResetTarget(target, type)
    self._type = type
    local cameraCfg = Cfg.cfg_season_camera[GameGlobal.GetModule(SeasonModule):GetCurSeasonID()]
    if self._type == UISeasonOvalTipType.Player then
        ---@type SeasonPlayer
        self._target = target
        self._icon:SetActive(true)
        self._arrowIcon.sprite = self._atlas:GetSprite("exp_s1_map_icon05")
        local min = cameraCfg.PlayerTipHideRange[1]
        local max = cameraCfg.PlayerTipHideRange[2]
        local maxSize = cameraCfg.CameraSizeMin
        local minSize = cameraCfg.CameraSizeMax
        self._tipHideParam = (max - min) / (maxSize - minSize)
        self._tipHideMinDistance = min
        self._cameraMinSize = minSize
    elseif self._type == UISeasonOvalTipType.Mission then
        ---@type SeasonMapEventPoint
        self._target = target
        self._icon:SetActive(false)
        self._arrowIcon.sprite = self._atlas:GetSprite("exp_s1_map_icon04")
        local cfg = Cfg.cfg_season_map_eventpoint[self._target:GetID()]
        if cfg.OvalTipHideRange then
            local min = cfg.OvalTipHideRange[1]
            local max = cfg.OvalTipHideRange[2]
            local maxSize = cameraCfg.CameraSizeMin
            local minSize = cameraCfg.CameraSizeMax
            self._tipHideParam = (max - min) / (maxSize - minSize)
            self._tipHideMinDistance = min
            self._cameraMinSize = minSize
        end
    elseif self._type == UISeasonOvalTipType.Daily then
        ---@type SeasonMapEventPoint
        self._target = target
        self._icon:SetActive(false)
        self._arrowIcon.sprite = self._atlas:GetSprite("exp_s1_map_icon31")
        local cfg = Cfg.cfg_season_map_eventpoint[self._target:GetID()]
        if cfg.OvalTipHideRange then
            local min = cfg.OvalTipHideRange[1]
            local max = cfg.OvalTipHideRange[2]
            local maxSize = cameraCfg.CameraSizeMin
            local minSize = cameraCfg.CameraSizeMax
            self._tipHideParam = (max - min) / (maxSize - minSize)
            self._tipHideMinDistance = min
            self._cameraMinSize = minSize
        end
    elseif self._type == UISeasonOvalTipType.Box then
        ---@type SeasonMapEventPoint
        self._target = target
        self._icon:SetActive(false)
        self._arrowIcon.sprite = self._atlas:GetSprite("exp_s1_map_icon06")
        local cfg = Cfg.cfg_season_map_eventpoint[self._target:GetID()]
        if cfg.OvalTipHideRange then
            local min = cfg.OvalTipHideRange[1]
            local max = cfg.OvalTipHideRange[2]
            local maxSize = cameraCfg.CameraSizeMin
            local minSize = cameraCfg.CameraSizeMax
            self._tipHideParam = (max - min) / (maxSize - minSize)
            self._tipHideMinDistance = min
            self._cameraMinSize = minSize
        end
    end

    self:Hide()
end

function UISeasonMainOvalTip:GetCanShowDistance(cameraSize)
    if self._tipHideMinDistance then
        return self._tipHideMinDistance + (cameraSize - self._cameraMinSize) * self._tipHideParam
    end
    return 0
end
