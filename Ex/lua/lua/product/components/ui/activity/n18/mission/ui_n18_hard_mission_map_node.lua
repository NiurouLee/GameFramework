---@class UIN18HardMissionMapNode : UICustomWidget
_class("UIN18HardMissionMapNode", UICustomWidget)
UIN18HardMissionMapNode = UIN18HardMissionMapNode

function UIN18HardMissionMapNode:Constructor() 

end
function UIN18HardMissionMapNode:OnShow(uiParams)
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

function UIN18HardMissionMapNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.name2 = self:GetUIComponent("UILocalizationText", "name_boss")
    self.star = self:GetGameObject("star")
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
     
    self._atlas = self:GetAsset("UIN18.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Shadow
    self._anim = self:GetGameObject():GetComponent("Animation")
    self._bgGo = self:GetGameObject("bg")
    self._btnGo = self:GetGameObject("btn")
    self._passGo = self:GetGameObject( "pass")
    self._icon = self:GetUIComponent("Image","icon")
end

---@param passInfo cam_mission_info
function UIN18HardMissionMapNode:SetData(lineCfg, passInfo, cb ,type, cfg,condition, missionCfgs, position, icon, index)
    self._missionID = lineCfg.CampaignMissionId
    self._onClick = cb
    self._rectTransform.anchoredPosition = Vector2(position.x, position.y)
    self.gameobject.transform.eulerAngles = Vector3(0, 0, position.angle) 

    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    local missionTypeCfg = missionCfgs[self._missionID]
    if not missionCfg then
        Log.exception("cfg_campaign_mission中找不到配置:", self._missionID)
    end

    self.name:SetText(StringTable.Get(missionCfg.Name))
    self.name2:SetText(StringTable.Get(missionCfg.Name))
    self.name2.gameObject:SetActive(false)

    --1是普通关，2是困难关
    local hardParam = type
    local typeCfg = cfg
    local bg = nil
    local mask = typeCfg[hardParam].press
    local lock = typeCfg[hardParam].lock
    local textColor
    if passInfo then
        --已通关
        textColor = typeCfg[hardParam].textColor
        local module = self:GetModule(MissionModule)
        bg = typeCfg[hardParam].normal
    else
        -- 正常显示
        textColor = typeCfg[hardParam].textColor
        bg = typeCfg[hardParam].normal 
    end

    self.cfg = lineCfg
    self.condition = condition
    self:ConditionShow(condition)
    self._btnGo:SetActive(true)
    self._passGo:SetActive(not (passInfo == nil) )
    --self:_SetRed(false))
    self.bg.sprite = self._atlas:GetSprite(bg)
    self.lock.sprite = self._atlas:GetSprite(lock)
    self._icon.sprite = self._atlas:GetSprite(icon)
    self._circleOutline.effectColor = typeCfg[hardParam].textShadow
    self.name.color = textColor
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot
    self.gameobject:SetActive(false)

    self:StartTask(
        function (TT)
            self:Lock("UIN18HardMissionMapNode" .. tostring(index))
            YIELD(TT, (index - 1) * 100)
            self.gameobject:SetActive(true)
            self._anim:Play("UIN18HardMissionMapNode")
            self:UnLock("UIN18HardMissionMapNode" .. tostring(index))
        end,
        self
    )
end

function UIN18HardMissionMapNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIN18HardMissionMapNode:ConditionShow(condition) 
    self.lock.gameObject:SetActive( not condition)
end 

function UIN18HardMissionMapNode:btnOnClick(go)
    if not self.condition then
        ToastManager.ShowToast(StringTable.Get("str_activity_common_clear_mission_to_unlock"))
        return 
    end 
    self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
end

