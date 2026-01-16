---@class UIActivityN5MissionNode : UICustomWidget
_class("UIActivityN5MissionNode", UICustomWidget)
UIActivityN5MissionNode = UIActivityN5MissionNode
function UIActivityN5MissionNode:OnShow(uiParams)
    self:InitWidget()
end
function UIActivityN5MissionNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.star = self:GetGameObject("star")
    ---@type UnityEngine.UI.Image
    self.mask = self:GetUIComponent("Image", "mask")
    ---@type UnityEngine.UI.Image
    self.lock = self:GetUIComponent("Image", "lock")
    --generated end--
    ---@type UnityEngine.UI.Image
    self.star1 = self:GetUIComponent("Image", "Star1")
    ---@type UnityEngine.UI.Image
    self.star2 = self:GetUIComponent("Image", "Star2")
    ---@type UnityEngine.UI.Image
    self.star3 = self:GetUIComponent("Image", "Star3")

    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self._stars = {
        self.star1,
        self.star2,
        self.star3
    }

    self._atlas = self:GetAsset("UIN5.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Shadow
    self.shadow = self:GetUIComponent("Shadow", "name")

    self.root = self:GetGameObject()

    self._anim = self:GetUIComponent("Animation", "UIActivityN5MissionNode")
end
function UIActivityN5MissionNode:SetData(node, cb,fromMissionResult)
    ---@type UIActivityMissionNodeInfo
    self._nodeInfo = node
    self._onClick = cb

    self._canEnter = false

    self._rectTransform.anchoredPosition = self._nodeInfo.pos

    self.name:SetText(StringTable.Get(self._nodeInfo.name))

    local viewCfg = nil
    local lineCfg = Cfg.cfg_component_line_mission {CampaignMissionId = self._nodeInfo.campaignMissionId}[1]
    if not lineCfg.CustomParams then
        AirError("N5普通关找不到自定义参数：", lineCfg.ID)
    end

    --1是普通关，2是困难关
    local hardParam = lineCfg.CustomParams[1][1]

    local typeCfg = nil
    if self._nodeInfo.isSLevel then
        --S关
        typeCfg = UIActivityN5SimpleLevel.NodeCfg[UIActivityN5SimpleLevel.SLeval]
    else
        --战斗、剧情、boss
        typeCfg = UIActivityN5SimpleLevel.NodeCfg[self._nodeInfo.type]
    end

    local needPlayStarsAnim = false --tmp
    local bg = nil
    local mask = typeCfg[hardParam].press
    local lock = typeCfg[hardParam].lock
    local textColor, shadowColor
    if self._nodeInfo.state == DiscoveryStageState.Nomal then
        --已通关
        textColor = typeCfg[hardParam].textColor
        shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal
        for i = 1, 3 do
            local pass = i <= self._nodeInfo.starCount
            if pass then
                self._stars[i].sprite = self._atlas:GetSprite(typeCfg[hardParam].passStar)
            else
                self._stars[i].sprite = self._atlas:GetSprite(typeCfg[hardParam].normalStar)
            end
        end
        local bShowStar = (self._nodeInfo.type ~= DiscoveryStageType.Plot)
        self.star:SetActive(bShowStar)
        if bShowStar and (self._nodeInfo.starCount > 0) then
            needPlayStarsAnim = true
        end
        self.lock.gameObject:SetActive(false)
        self._canEnter = true
    elseif self._nodeInfo.state == DiscoveryStageState.CanPlay then
        --当前关
        textColor = typeCfg[hardParam].textColor
        shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal
        for i = 1, 3 do
            local pass = i <= self._nodeInfo.starCount
            if pass then
                self._stars[i].sprite = self._atlas:GetSprite(typeCfg[hardParam].passStar)
            else
                self._stars[i].sprite = self._atlas:GetSprite(typeCfg[hardParam].normalStar)
            end
        end
        local bShowStar = (self._nodeInfo.type ~= DiscoveryStageType.Plot)
        self.star:SetActive(bShowStar)
        if bShowStar and (self._nodeInfo.starCount > 0) then
            needPlayStarsAnim = true
        end
        self.lock.gameObject:SetActive(false)
        self._canEnter = true
    elseif self._nodeInfo.state == nil then
        --未解锁
        textColor = typeCfg[hardParam].textColor
        shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal
        self.lock.gameObject:SetActive(true)
        self.star:SetActive(false)

        self.root:SetActive(false)
    end
    self.bg.sprite = self._atlas:GetSprite(bg)
    self.mask.sprite = self._atlas:GetSprite(mask)
    self.lock.sprite = self._atlas:GetSprite(lock)

    self.name.color = textColor
    self.shadow.effectColor = shadowColor

    --剧情路点点击后为了截屏而滚动
    self._needScrollOnClick = self._nodeInfo.type ~= DiscoveryStageType.Plot
    if fromMissionResult and self._nodeInfo.campaignMissionId == fromMissionResult then
        if needPlayStarsAnim then
            self.animTimer = GameGlobal.Timer():AddEvent(
               700,
            function()
                self._anim:Play("uieff_N5_Node_GetStars")
            end 
            )
        end
    end
    
    -- if self._nodeInfo.pos.y >= 0 then
    --     self._anim:Play("uieff_UIXH1MissionNode_belowin")
    -- else
    --     self._anim:Play("uieff_UIXH1MissionNode_topin")
    -- end
end
function UIActivityN5MissionNode:btnOnClick(go)
    if self._canEnter then
        self._onClick(self._nodeInfo.campaignMissionId, self._needScrollOnClick, self._rectTransform)
    end
end
function UIActivityN5MissionNode:OnHide()
    if self.animTimer then
        GameGlobal.Timer():CancelEvent(self.animTimer)
        self.animTimer = nil
    end
end