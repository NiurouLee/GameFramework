---@class UIN32MultiLineMapNormalNode : UICustomWidget
_class("UIN32MultiLineMapNormalNode", UICustomWidget)
UIN32MultiLineMapNormalNode = UIN32MultiLineMapNormalNode

function UIN32MultiLineMapNormalNode:OnShow(uiParams)
    self:InitWidget()
end

function UIN32MultiLineMapNormalNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizedTMP", "name")
    self.name2 = self:GetUIComponent("UILocalizationText", "name_boss")
    self.star = self:GetGameObject("star")
    self.bg_normal_plotGo = self:GetGameObject("bg_normal_plot")
    self.bg_bossGo = self:GetGameObject("bg_boss")

    --generated end--
    ---@type UnityEngine.UI.Image
    self.star1 = self:GetUIComponent("Image", "Star1")
    ---@type UnityEngine.UI.Image
    self.star2 = self:GetUIComponent("Image", "Star2")
    ---@type UnityEngine.UI.Image
    self.star3 = self:GetUIComponent("Image", "Star3")

    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self._stars =
    {
        self.star1,
        self.star2,
        self.star3
    }

    self._atlas = self:GetAsset("UIN32Multiline.spriteatlas", LoadType.SpriteAtlas)
    self._anim = self:GetUIComponent("Animation", "Anim")
    self._bgGo = self:GetGameObject("bg")
    -- self._maskGo = self:GetGameObject("mask")
end

function UIN32MultiLineMapNormalNode:GetNodeCfg()
    local NodeCfg =
    {
        SLeval = 111111, --s关枚举id
        Passed = 888, --通关后文本和阴影颜色
    }

    NodeCfg[DiscoveryStageType.FightNormal] =
    {
        [1] = {
            normal = "n32_dzm_dt_di02",
            press = "",
            lock = "",
            textColor = Color(65 / 255, 40 / 255, 17 / 255), -- 不使用
            textShadow = Color(0 / 255, 0 / 255, 0 / 255), -- 不使用
            normalStar = "n32_dzm_dt_di07",
            passStar = "n32_dzm_dt_di06"
        }, --普通样式
        [2] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color(241 / 255, 255 / 255, 117 / 255),
            textShadow = Color(111 / 255, 52 / 255, 25 / 255),
            normalStar = "n32_dzm_dt_di07",
            passStar = "n32_dzm_dt_di06"
        } --高难样式
    }
    NodeCfg[DiscoveryStageType.FightBoss] =
    {
        [1] = {
            normal = "n32_dzm_dt_di03",
            press = "",
            lock = "",
            textColor = Color.New(212 / 255, 148 / 255, 91 / 255), -- 不使用
            textShadow = Color.New(255 / 255, 255 / 255, 255 / 255), -- 不使用
            normalStar = "n32_dzm_dt_di07",
            passStar = "n32_dzm_dt_di06"
        }, --普通样式
        [2] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
            textShadow = Color.New(238 / 255, 0 / 255, 34 / 255),
            normalStar = "",
            passStar = ""
        } --高难样式
    }
    NodeCfg[DiscoveryStageType.Plot] =
    {
        [1] = {
            normal = "n32_dzm_dt_di04",
            press = "",
            lock = "",
            textColor = Color.New(65 / 255, 40 / 255, 17 / 255), -- 不使用
            textShadow = Color.New(0 / 255, 0 / 255, 0 / 255) -- 不使用
        }, --普通样式
        [2] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color.New(241 / 255, 255 / 255, 117 / 255),
            textShadow = Color.New(111 / 255, 52 / 255, 25 / 255)
        } --高难样式
    }
    NodeCfg[NodeCfg.SLeval] =
    {
        [1] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
            textShadow = Color.New(22 / 255, 42 / 255, 61 / 255),
            normalStar = "",
            passStar = ""
        }, --普通样式
        [2] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color.New(255 / 255, 255 / 255, 255 / 255),
            textShadow = Color.New(22 / 255, 42 / 255, 61 / 255),
            normalStar = "",
            passStar = ""
        } --高难样式
    }

    return NodeCfg
end

-- function UIN32MultiLineMapNormalNode:SetAtlas(atlas)
--     self._atlas = atlas
-- end

---@param passInfo cam_mission_info
function UIN32MultiLineMapNormalNode:SetData(levelId, multilineData, cb)
    self._levelId =levelId
    local lineCfg = Cfg.cfg_component_multiline_mission[levelId]
    local passInfo = multilineData:GetPassMissionInfo(lineCfg.MissionID)
    self._missionID = lineCfg.MissionID
    self._onClick = cb

    local missionCfg = Cfg.cfg_campaign_mission[self._missionID]
    if not missionCfg then
        Log.exception("cfg_campaign_mission中找不到配置:", self._missionID)
    end

    self.name:SetText(StringTable.Get(missionCfg.Name))
    self.name2:SetText(StringTable.Get(missionCfg.Name))
    self.name.gameObject:SetActive(missionCfg.Type ~= DiscoveryStageType.FightBoss)
    self.name2.gameObject:SetActive(missionCfg.Type == DiscoveryStageType.FightBoss)
    self.bg_normal_plotGo:SetActive(missionCfg.Type ~= DiscoveryStageType.FightBoss)
    self.bg_bossGo:SetActive(missionCfg.Type == DiscoveryStageType.FightBoss)

    local NodeCfg = self:GetNodeCfg()

    --1是普通关，2是困难关
    local hardParam = 1
    local typeCfg = nil
    if lineCfg.WayPointType == 4 then
        --S关
        typeCfg = NodeCfg[NodeCfg.SLeval]
    else
        --战斗、剧情、boss
        --普通战斗关卡=1
        --Boss战斗关卡=2
        --剧情关=3
        typeCfg = NodeCfg[missionCfg.Type]
    end
    local bg = nil
    -- local mask = typeCfg[hardParam].press
    local textColor, shadowColor
    if passInfo then
        --已通关
        textColor = typeCfg[hardParam].textColor
        --shadowColor = typeCfg[hardParam].textShadow
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
    else
        --没有通关数据则视为当前关
        textColor = typeCfg[hardParam].textColor
        -- shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal
        local stars = 0
        for i = 1, 3 do
            local pass = i <= stars
            local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
            self._stars[i].sprite = self._atlas:GetSprite(url)
            self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        end
        self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
    end
    self:_SetRed(false)
    self.bg.sprite = self._atlas:GetSprite(bg)

    -- self.name.color = textColor
    --剧情路点点击后为了截屏而滚动
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot

    -- if lineCfg.MapPosY >= 0 then
    --     self._anim:Play("uieff_UIN32MultiLineMapNormalNode_up")
    -- else
    --     self._anim:Play("uieff_UIN32MultiLineMapNormalNode_down")
    -- end
end

function UIN32MultiLineMapNormalNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIN32MultiLineMapNormalNode:BtnOnClick(go)
    self:StartTask(function (TT)
        local lockName = "UIN32MultiLineMapNormalNode_click_ani"
        self:Lock(lockName)
        self._anim:Play("uieff_UIN32MultiLineMapNormalNode_click")
        YIELD(TT, 367)
        self:UnLock(lockName)
        self._onClick(self._levelId, self._missionID, self._isStoryNode, self._rectTransform.position)
    end)
end

function UIN32MultiLineMapNormalNode:SetVisible(bVisible)
    self:GetGameObject():SetActive(bVisible)
end

function UIN32MultiLineMapNormalNode:GetPosition()
    return  self:GetGameObject().transform.position
end

function UIN32MultiLineMapNormalNode:PlayEnterAni()
    self._anim:Play("uieff_UIN32MultiLineMapNormalNode_in")
end

function UIN32MultiLineMapNormalNode:GetMissionID()
    return self._missionID
end