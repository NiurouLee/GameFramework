---@class UIActivityN6Node : UICustomWidget
_class("UIActivityN6Node", UICustomWidget)
UIActivityN6Node = UIActivityN6Node
function UIActivityN6Node:OnShow(uiParams)
    self:InitWidget()
end
function UIActivityN6Node:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.title = self:GetUIComponent("UILocalizationText", "title")
    self.star = self:GetGameObject("star")
    ---@type UnityEngine.UI.Image
    self.mask = self:GetUIComponent("Image", "mask")
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

    self._atlas = self:GetAsset("NPlusSix.spriteatlas", LoadType.SpriteAtlas)
end

---@param passInfo cam_mission_info
function UIActivityN6Node:SetData(lineCfg, passInfo, cb)
    self._missionID = lineCfg.CampaignMissionId
    self._onClick = cb
    self._rectTransform.anchorMax = Vector2(0, 0.5)
    self._rectTransform.anchorMin = Vector2(0, 0.5)
    self._rectTransform.sizeDelta = Vector2.zero
    self._rectTransform.anchoredPosition = Vector2(lineCfg.MapPosX, lineCfg.MapPosY)
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if not missionCfg then
        Log.exception("cfg_campaign_mission中找不到配置:", self._missionID)
    end

    self.name:SetText(StringTable.Get(missionCfg.Name))
    --1是普通难度样式，2是高难样式 N6没有高难样式
    local hardParam = 1
    local typeCfg = nil
    if lineCfg.WayPointType == 4 then
        --S关
        typeCfg = UIActivityN6LineMissionReview.NodeCfg[UINP6Level.SLeval]
    else
        --战斗、剧情、boss
        typeCfg = UIActivityN6LineMissionReview.NodeCfg[missionCfg.Type]
    end

    local mask = typeCfg[hardParam].press
    local textColor = typeCfg[hardParam].textColor
    local bg = typeCfg[hardParam].normal
    local title = typeCfg[hardParam].title
    local starSprite = nil
    if missionCfg.Type == DiscoveryStageType.Plot then
        self.star:SetActive(false)
    elseif missionCfg.Type == DiscoveryStageType.FightNormal then
        self.star:SetActive(true)
        starSprite = typeCfg[hardParam].normalStar
    else
        self.star:SetActive(true)
        starSprite = typeCfg[hardParam].spcialStar
    end
    if starSprite then
        local stars = 0
        if passInfo then
            local module = self:GetModule(MissionModule)
            stars = module:ParseStarInfo(passInfo.star)
        end
        for i = 1, 3 do
            local pass = i <= stars
            if pass then
                self._stars[i].sprite = self._atlas:GetSprite(starSprite)
                self._stars[i].gameObject:SetActive(true)
            else
                self._stars[i].gameObject:SetActive(false)
            end
        end
    end
    self.bg.sprite = self._atlas:GetSprite(bg)
    self.mask.sprite = self._atlas:GetSprite(mask)

    self.name.color = textColor
    self.title.color = textColor
    self.title:SetText(title)

    --剧情路点点击后为了截屏而滚动
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot
end
function UIActivityN6Node:BtnOnClick(go)
    self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
end
