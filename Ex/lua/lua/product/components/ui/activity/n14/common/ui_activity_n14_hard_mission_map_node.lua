---@class UIActivityN14HardMissionMapNode : UICustomWidget
_class("UIActivityN14HardMissionMapNode", UICustomWidget)
UIActivityN14HardMissionMapNode = UIActivityN14HardMissionMapNode

function UIActivityN14HardMissionMapNode:Constructor() 

end
function UIActivityN14HardMissionMapNode:OnShow(uiParams)
    self:InitWidget()

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnGo),
        UIEvent.Press,
        function(go)
          --  self._bgGo:SetActive(false)
          --  self._maskGo:SetActive(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._btnGo),
        UIEvent.Release,
        function(go)
           -- self._bgGo:SetActive(true)
           -- self._maskGo:SetActive(false)
        end
    )
end

function UIActivityN14HardMissionMapNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
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
    ---@type CircleOutline
    self._circleOutline = self:GetUIComponent("H3D.UGUI.CircleOutline", "name")
    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self._stars = {
        self.star1,
        self.star2,
        self.star3
    }

    self._buttonBg = 
    {
        type1 = {"bg1","bg2","bg3"},
    }
     
    self._atlas = self:GetAsset("UIN14.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Shadow
    self._anim = self:GetGameObject():GetComponent("Animation")
    self._bgGo = self:GetGameObject("bg")
    self._btnGo = self:GetGameObject("btn")
    self._maskGo = self:GetGameObject( "mask")
    self._passGo = self:GetGameObject( "pass")
end

---@param passInfo cam_mission_info
function UIActivityN14HardMissionMapNode:SetData(lineCfg, passInfo, cb ,type, cfg,condition,missionCfgs)
    self._missionID = lineCfg.CampaignMissionId
    self._onClick = cb
    self._rectTransform.anchorMax = Vector2(0, 0.5)
    self._rectTransform.anchorMin = Vector2(0, 0.5)
    self._rectTransform.sizeDelta = Vector2.zero
    self._rectTransform.anchoredPosition = Vector2(lineCfg.MapPosX, lineCfg.MapPosY)
    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    local missionTypeCfg = missionCfgs[self._missionID]
    if not missionCfg then
        Log.exception("cfg_campaign_mission中找不到配置:", self._missionID)
    end

    self.name:SetText(StringTable.Get(missionCfg.Name))
    self.name2:SetText(StringTable.Get(missionCfg.Name))
    --self.name.gameObject:SetActive(missionCfg.Type ~= DiscoveryStageType.FightBoss)
    self.name2.gameObject:SetActive(false)

    --1是普通关，2是困难关
    local hardParam = type
    local  typeCfg = cfg[missionTypeCfg.WayPointType]
    local bg = nil
    local mask = typeCfg[hardParam].press
    local lock = typeCfg[hardParam].lock
    local textColor
    if passInfo then
        --已通关
        textColor = typeCfg[hardParam].textColor
        local module = self:GetModule(MissionModule)
        -- local stars = module:ParseStarInfo(passInfo.star or typeCfg[hardParam].normalStar )
        bg = typeCfg[hardParam].normal
        -- for i = 1, 3 do
          --  local pass = i <= stars
          --  local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
          --  self._stars[i].sprite = self._atlas:GetSprite(url)
          --  self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        -- end
        --self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
    else
        --没有通关数据则视为当前关
        textColor = typeCfg[hardParam].textColor
        bg = typeCfg[hardParam].normal
        -- local stars = 0
        -- for i = 1, 3 do
        --     local pass = i <= stars
        --     local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
        --     self._stars[i].sprite = self._atlas:GetSprite(url)
        --     self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        -- end
        --self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
    end
    self.cfg = lineCfg
    self.condition = condition
    self:ConditionShow(condition)
    self._btnGo:SetActive(true)
    self._maskGo:SetActive(passInfo ~= nil or not condition)
    self._passGo:SetActive(not (passInfo == nil) )
    --self:_SetRed(false))
    self.bg.sprite = self._atlas:GetSprite(bg)
    self.mask.sprite = self._atlas:GetSprite(mask)
    self.lock.sprite = self._atlas:GetSprite(lock)
    self._circleOutline.effectColor =   typeCfg[hardParam].textShadow
    textColor.a =  (passInfo ~= nil or not condition)  and textColor.a * 0.2 or textColor.a
    self.name.color = textColor
    textColor.a = 1 
    --剧情路点点击后为了截屏而滚动

    if lineCfg.MapPosY >= 0 then
        self._anim:Play("uieff_UIXH1MissionNode_belowin")
    else
        self._anim:Play("uieff_UIXH1MissionNode_topin")
    end
end

function UIActivityN14HardMissionMapNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIActivityN14HardMissionMapNode:ConditionShow(condition) 
    self.lock.gameObject:SetActive( not condition)
end 

function UIActivityN14HardMissionMapNode:btnOnClick(go)
    if not self.condition then 
        local lvName = ""
        for i,v in pairs(self.cfg.NeedMissionList) do
            local cfgv = Cfg.cfg_campaign_mission[v]
            lvName = lvName ..StringTable.Get(cfgv.Name)
            if i == #self.cfg.NeedMissionList then 
               break
            end 
            lvName = lvName .. " "
        end
        ToastManager.ShowToast(StringTable.Get("str_activity_common_will_open_after_clearance",lvName))
        return 
    end 
    self._onClick(self._missionID,false , self._rectTransform.position)
end
