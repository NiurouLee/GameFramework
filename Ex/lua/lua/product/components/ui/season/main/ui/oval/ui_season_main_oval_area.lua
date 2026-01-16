--
---@class UISeasonMainOvalArea : UICustomWidget
_class("UISeasonMainOvalArea", UICustomWidget)
UISeasonMainOvalArea = UISeasonMainOvalArea
--初始化
function UISeasonMainOvalArea:OnShow(uiParams)
    self:InitWidget()
    self._rect = self:GetGameObject():GetComponent(typeof(UnityEngine.RectTransform)) --注意 这个RectTransform自身的pivot一定是(0.5,0.5)
    local width = self._rect.rect.width
    local height = self._rect.rect.height
    self._ovalCenter = Vector2(width / 2, height / 2)
    local seasonID = GameGlobal.GetModule(SeasonModule):GetCurSeasonID()
    local cfg = Cfg.cfg_season_campaign_client[seasonID]
    self._oval = OvalShape:New(width / 2 - cfg.OvalTipPadding[1], height / 2 - cfg.OvalTipPadding[2])
    self._arrowPool = {}
    ---@type table<object,UISeasonMainOvalTip>
    self._tips = {}
    ---@type UISeasonModule
    self._uiModule = GameGlobal.GetUIModule(SeasonModule)
    ---@type UnityEngine.Camera
    self._camera = self._uiModule:SeasonManager():SeasonCameraManager():Camera()
    self._uiCamera = GameGlobal.UIStateManager():GetControllerCamera("UISeasonMain")
    self._seasonManager = self._uiModule:SeasonManager()
    self:_RefreshMainLevelTarget() --主线关
    self:_RefreshDailyLevelTarget() --日常关
    self:_RefreshBoxTarget() --宝箱
    self:AddTarget(self._seasonManager:SeasonPlayerManager():GetPlayer(), UISeasonOvalTipType.Player) --主角
    self:AttachEvent(GameEventType.UISeasonOnLevelDiffChanged, self._RefreshMainLevelTarget)
    self:AttachEvent(GameEventType.OnEventPointProgressChange, self._RefreshTarget)
end

--获取ui组件
function UISeasonMainOvalArea:InitWidget()
    ---@type UnityEngine.Transform
    self._tipsParent = self:GetUIComponent("Transform", "tips")
end

--设置数据
function UISeasonMainOvalArea:SetData()
end

function UISeasonMainOvalArea:OnHide()
    for _, req in ipairs(self._arrowPool) do
        req:Dispose()
    end
    self._arrowPool = nil
    for _, tip in pairs(self._tips) do
        tip:Dispose()
    end
    self._tips = nil
end

---@param target SeasonMapEventPoint|SeasonPlayer
function UISeasonMainOvalArea:AddTarget(target, type)
    if self._tips[target] then
        Log.error("duplicate target")
        return
    end
    self._tips[target] = UISeasonMainOvalTip:New(target, self:_GetTip(), type,
        function(tip)
            self:_OnTipClick(tip)
        end
    )
end

function UISeasonMainOvalArea:RemoveTarget(obj)
    if not self._tips[obj] then
        Log.error("target not found")
        return
    end
    local tip = self._tips[obj]
    local req = tip:GetReq()
    self:_ReleaseTip(req)
    tip:Delete()
    self._tips[obj] = nil
end

---@return UISeasonMainOvalTip
function UISeasonMainOvalArea:GetTipByType(type)
    for _, tip in pairs(self._tips) do
        if tip:Type() == type then
            return tip
        end
    end
end

function UISeasonMainOvalArea:Update(dt)
    for _, tip in pairs(self._tips) do
        local screenPos = self._camera:WorldToScreenPoint(tip:TargetWorldPos())
        local res, pos = UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            self._rect,
            screenPos,
            self._uiCamera,
            nil
        )

        local canShow = true --主角为了不挡住模型额外增加一个显示条件
        local arrowPos = self._oval:CrossPoint(pos)
        local distance = tip:GetCanShowDistance(self._camera.orthographicSize)
        if Vector2.Distance(arrowPos, pos) < distance then
            canShow = false
        end

        if self._oval:IsInside(pos) or not canShow then
            if not tip:IsInOval() then
                tip:Hide()
            end
        else
            if tip:IsInOval() then
                tip:Show()
            end
            if not arrowPos then
                arrowPos = self._oval:CrossPoint(pos)
            end
            local dir = Vector3(pos.x - arrowPos.x, pos.y - arrowPos.y, 0)
            local lookRot = Quaternion.LookRotation(Vector3.forward, dir)
            if lookRot then
                local rot = lookRot
                tip:Sync(arrowPos, rot)
            end
        end
    end
end

---@return ResRequest
function UISeasonMainOvalArea:_GetTip()
    if #self._arrowPool == 0 then
        local req = ResourceManager:GetInstance():SyncLoadAsset("UISeasonMainOvalTip.prefab", LoadType.GameObject)
        ---@type UnityEngine.Transform
        local tr = req.Obj.transform
        tr:SetParent(self._tipsParent, false)
        tr.localPosition = Vector3.zero
        tr.localRotation = Quaternion.identity
        tr.localScale = Vector3.one
        return req
    else
        local req = self._arrowPool[#self._arrowPool]
        self._arrowPool[#self._arrowPool] = nil
        return req
    end
end

function UISeasonMainOvalArea:_ReleaseTip(req)
    -- self._arrowPool[#self._arrowPool + 1] = req
    req:Dispose()
end

function UISeasonMainOvalArea:_ScreenToOval(screenPos)
    return screenPos - self._ovalCenter
end

---@param tip UISeasonMainOvalTip
function UISeasonMainOvalArea:_OnTipClick(tip)
    ---@type UISeasonModule
    local uiModule = GameGlobal.GetUIModule(SeasonModule)
    if tip:Type() == UISeasonOvalTipType.Player then
        uiModule:SeasonManager():SeasonCameraManager():SwitchMode(SeasonCameraMode.Follow)
    elseif tip:Type() == UISeasonOvalTipType.Mission then
        uiModule:SeasonManager():SeasonCameraManager():SeasonCamera():Focus(tip:TargetWorldPos())
    elseif tip:Type() == UISeasonOvalTipType.Box then
        uiModule:SeasonManager():SeasonCameraManager():SeasonCamera():Focus(tip:TargetWorldPos())
    elseif tip:Type() == UISeasonOvalTipType.Daily then
        uiModule:SeasonManager():SeasonCameraManager():SeasonCamera():Focus(tip:TargetWorldPos())
    end
end

function UISeasonMainOvalArea:_RefreshMainLevelTarget()
    ---@type SeasonMapEventPoint[]
    local levelPoints = self._seasonManager:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.MainLevel)
    for _, point in ipairs(levelPoints) do
        if point:IsLastMainLevelGroup() then
            local tip = self:GetTipByType(UISeasonOvalTipType.Mission)
            if tip then
                tip:ResetTarget(point, UISeasonOvalTipType.Mission)
            else
                self:AddTarget(point, UISeasonOvalTipType.Mission)
            end
            return
        end
    end
    --走到这里说明没有主线关路点
    local tip = self:GetTipByType(UISeasonOvalTipType.Mission)
    if tip then
        self:RemoveTarget(tip:Target())
    end
end

function UISeasonMainOvalArea:_RefreshDailyLevelTarget()
    ---@type SeasonMapEventPoint[]
    local levelPoints = self._seasonManager:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.DailyLevel)
    if levelPoints then
        for _, point in ipairs(levelPoints) do
            self:AddTarget(point, UISeasonOvalTipType.Daily)
        end
    end
end

function UISeasonMainOvalArea:_RefreshBoxTarget()
    ---@type SeasonMapEventPoint[]
    local boxPoints = self._seasonManager:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.Box)
    local trapPoints = self._seasonManager:SeasonMapManager():GetEventPointsByType(SeasonEventPointType.Mechanism)
    table.appendArray(boxPoints, trapPoints)
    for _, point in ipairs(boxPoints) do
        local curProgressExpress = point:CurProgressExpress()
        if curProgressExpress then
            local result, content = curProgressExpress:ContainExpress(SeasonExpressType.Show)
            if result and content == true then
                local expresses = curProgressExpress:GetExpresses(SeasonExpressType.Sign)
                if expresses then
                    for _, express in pairs(expresses) do
                        content = express:Content()
                        ---@type SeasonSignType
                        local signType = content.type
                        if signType == SeasonSignType.Before then
                            local tip = self:GetTipByType(UISeasonOvalTipType.Box)
                            if tip then
                                tip:ResetTarget(point, UISeasonOvalTipType.Box)
                            else
                                self:AddTarget(point, UISeasonOvalTipType.Box)
                            end
                            return
                        end
                    end
                end
            end
        end
    end
    --走到这里说明没有宝箱路点
    local tip = self:GetTipByType(UISeasonOvalTipType.Box)
    if tip then
        self:RemoveTarget(tip:Target())
    end
end

function UISeasonMainOvalArea:_RefreshTarget()
    self:_RefreshMainLevelTarget()
    self:_RefreshBoxTarget()
end
