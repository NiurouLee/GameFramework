---@class UIXH1MissionNodeReview : UICustomWidget
_class("UIXH1MissionNodeReview", UICustomWidget)
UIXH1MissionNodeReview = UIXH1MissionNodeReview
function UIXH1MissionNodeReview:OnShow(uiParams)
    self:InitWidget()
end
function UIXH1MissionNodeReview:InitWidget()
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

    self._atlas = self:GetAsset("UIXH1SimpleLevel.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Shadow
    self.shadow = self:GetUIComponent("Shadow", "name")

    self.root = self:GetGameObject()

    self._anim = self:GetUIComponent("Animation", "UIXH1MissionNode")
end
function UIXH1MissionNodeReview:SetData(node, cb)
    ---@type UIActivityMissionNodeInfo
    self._nodeInfo = node
    self._onClick = cb

    self._canEnter = false

    self._rectTransform.anchoredPosition = self._nodeInfo.pos

    self.name:SetText(StringTable.Get(self._nodeInfo.name))

    local viewCfg = nil
    local lineCfg = Cfg.cfg_component_line_mission {CampaignMissionId = self._nodeInfo.campaignMissionId}[1]
    if not lineCfg.CustomParams then
        AirError("夏活1普通关找不到自定义参数：", lineCfg.ID)
    end

    --1是普通关，2是困难关
    local hardParam = lineCfg.CustomParams[1][1]

    local typeCfg = nil
    if self._nodeInfo.isSLevel then
        --S关
        typeCfg = UIXH1SimpleLevelReview.NodeCfg[UIXH1SimpleLevelReview.SLeval]
    else
        --战斗、剧情、boss
        typeCfg = UIXH1SimpleLevelReview.NodeCfg[self._nodeInfo.type]
    end

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
        self.star:SetActive(self._nodeInfo.type ~= DiscoveryStageType.Plot)
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

        self.star:SetActive(self._nodeInfo.type ~= DiscoveryStageType.Plot)
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

    if self._nodeInfo.pos.y >= 0 then
        self._anim:Play("uieff_UIXH1MissionNode_belowin")
    else
        self._anim:Play("uieff_UIXH1MissionNode_topin")
    end
end
function UIXH1MissionNodeReview:btnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.Summer1ClickNormal)
    if self._canEnter then
        self._onClick(self._nodeInfo.campaignMissionId, self._needScrollOnClick, self._rectTransform)
    end
end
