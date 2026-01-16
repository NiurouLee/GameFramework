---@class UIActivityN16ReviewLineMissionMapNode : UICustomWidget
_class("UIActivityN16ReviewLineMissionMapNode", UICustomWidget)
UIActivityN16ReviewLineMissionMapNode = UIActivityN16ReviewLineMissionMapNode

function UIActivityN16ReviewLineMissionMapNode:OnShow(uiParams)
    self:InitWidget()
end

function UIActivityN16ReviewLineMissionMapNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("RawImageLoader", "bg")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.name2 = self:GetUIComponent("UILocalizationText", "name_boss")
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

    self.jinji =  self:GetGameObject("jinji")
    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self._stars = {
        self.star1,
        self.star2,
        self.star3
    }

    self._atlas = self:GetAsset("UIN16.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Shadow
    -- self.shadow = self:GetUIComponent("Shadow", "name")
    self._anim = self:GetGameObject():GetComponent("Animation")
    self._redImgObj = self:GetGameObject("redImg")
end

---@param passInfo cam_mission_info
function UIActivityN16ReviewLineMissionMapNode:SetData(lineCfg, passInfo, cb)
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
    self.name2:SetText(StringTable.Get(missionCfg.Name))
    self.name.gameObject:SetActive(missionCfg.Type ~= DiscoveryStageType.FightBoss)
    self.name2.gameObject:SetActive(missionCfg.Type == DiscoveryStageType.FightBoss)
    self.jinji.gameObject:SetActive(missionCfg.Type == DiscoveryStageType.FightBoss)
    --1是普通关，2是困难关
    local hardParam = 1
    local typeCfg = nil
    if lineCfg.WayPointType == 4 then
        --S关
        typeCfg = UIActivityN16ReviewLineMissionController.NodeCfg[UIActivityN16ReviewLineMissionController.SLeval]
    else
        --战斗、剧情、boss
        typeCfg = UIActivityN16ReviewLineMissionController.NodeCfg[missionCfg.Type]
    end
    local bg = nil
    local mask = typeCfg[hardParam].press
    local lock = typeCfg[hardParam].lock
    local textColor, shadowColor
   
    if passInfo then
        --已通关
        textColor = typeCfg[hardParam].textColor
        shadowColor = typeCfg[hardParam].textShadow
        local module = self:GetModule(MissionModule)
        local stars = module:ParseStarInfo(passInfo.star)
        bg = typeCfg[hardParam].normal 
        for i = 1, 3 do
            local pass = i <= stars
            local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
            self._stars[i].sprite = self._atlas:GetSprite(url)
            self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        end
        self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
        self.lock.gameObject:SetActive(false)
    else
        --没有通关数据则视为当前关
        textColor = typeCfg[hardParam].textColor
        shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal 
        local stars = 0
        for i = 1, 3 do
            local pass = i <= stars
            local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
            self._stars[i].sprite = self._atlas:GetSprite(url)
            self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        end
        self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
        self.lock.gameObject:SetActive(false)
    end
    self:_SetRed(false)
    -- local info = Cfg.cfg_component_line_mission{CampaignMissionId = self._missionID}[1]
    -- if info.CustomParams then
    --     bg = (info.CustomParams[1][1] == 2 and missionCfg.Type == DiscoveryStageType.FightNormal)  and "n16_xxg_btn03"  or  typeCfg[hardParam].normal
    -- end
    if missionCfg.Type == DiscoveryStageType.Plot then
        self._redImgObj:SetActive(false)
    end
    
    -- bg = (missionCfg.Type == DiscoveryStageType.FightNormal) and "n16_xxg_btn03"  or  typeCfg[hardParam].normal
    self.bg:LoadImage(bg)  -- = self._atlas:GetSprite(bg)
    self.mask.sprite = self._atlas:GetSprite(mask)
    self.lock.sprite = self._atlas:GetSprite(lock)

    -- self.name.color = textColor
    -- self.shadow.effectColor = shadowColor

    --剧情路点点击后为了截屏而滚动
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot

    if lineCfg.MapPosY >= 0 then
        self._anim:Play("uieffanim_N16_lineMissMap_top")
    else
        self._anim:Play("uieffanim_N16_lineMissMap_down")
    end
end

function UIActivityN16ReviewLineMissionMapNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIActivityN16ReviewLineMissionMapNode:BtnOnClick(go)
    self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
end
