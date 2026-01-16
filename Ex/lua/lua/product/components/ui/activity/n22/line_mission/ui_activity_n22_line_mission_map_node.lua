---@class UIActivityN22LineMissionMapNode : UICustomWidget
_class("UIActivityN22LineMissionMapNode", UICustomWidget)
UIActivityN22LineMissionMapNode = UIActivityN22LineMissionMapNode

function UIActivityN22LineMissionMapNode:OnShow(uiParams)
    self:InitWidget()

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnGo),
        UIEvent.Press,
        function(go)
       --     self._bgGo:SetActive(false)
        --    self._maskGo:SetActive(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnGo),
        UIEvent.Release,
        function(go)
        --    self._bgGo:SetActive(true)
        --    self._maskGo:SetActive(false)
        end
    )
end

function UIActivityN22LineMissionMapNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg_normal")
    ---@type UILocalizationText
    self.name_normal = self:GetUIComponent("UILocalizationText", "name_normal")
    self.name_boss = self:GetUIComponent("UILocalizationText", "name_boss")
    self.name_plot = self:GetUIComponent("UILocalizationText", "name_plot")
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

    self._atlas = self:GetAsset("UIN22.spriteatlas", LoadType.SpriteAtlas)
    self._anim = self:GetGameObject():GetComponent("Animation")
   -- self._bgGo = self:GetGameObject("bg")
    self._btnGo = self:GetGameObject("btn")
    self._maskGo = self:GetGameObject( "mask")
end

---@param passInfo cam_mission_info
function UIActivityN22LineMissionMapNode:SetData(lineCfg, passInfo, cb)
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

    self.name_normal:SetText(StringTable.Get(missionCfg.Name))
    self.name_boss:SetText(StringTable.Get(missionCfg.Name))
    self.name_plot:SetText(StringTable.Get(missionCfg.Name))
    self.name_normal.gameObject:SetActive(missionCfg.Type ~= DiscoveryStageType.FightBoss)
    self.name_boss.gameObject:SetActive(missionCfg.Type == DiscoveryStageType.FightBoss)

    --1是普通关，2是困难关
    local hardParam = 1
    local typeCfg = nil
    if lineCfg.WayPointType == 4 then
        --S关
        typeCfg = UIActivityN22LineMissionController.NodeCfg[UIActivityN22LineMissionController.SLeval]
    else
        --战斗、剧情、boss
        typeCfg = UIActivityN22LineMissionController.NodeCfg[missionCfg.Type]
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
    --self:_SetRed(false)
    self.bg.sprite = self._atlas:GetSprite(bg)
    self.mask.sprite = self._atlas:GetSprite(mask)
    self.lock.sprite = self._atlas:GetSprite(lock)


    local nametext = missionCfg.Type == DiscoveryStageType.FightBoss and  self.name_boss or  self.name_normal
    nametext.color = textColor
  
    -- self.shadow.effectColor = shadowColor

    --剧情路点点击后为了截屏而滚动
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot

    if lineCfg.MapPosY >= 0 then
        self._anim:Play("uieff_UIXH1MissionNode_belowin")
    else
        self._anim:Play("uieff_UIXH1MissionNode_topin")
    end
end

function UIActivityN22LineMissionMapNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIActivityN22LineMissionMapNode:BtnOnClick(go)
    self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
end
