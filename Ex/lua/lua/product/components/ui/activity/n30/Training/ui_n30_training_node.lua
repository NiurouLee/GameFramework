---@class UIN30TrainingNode : UICustomWidget
_class("UIN30TrainingNode", UICustomWidget)
UIN30TrainingNode = UIN30TrainingNode

function UIN30TrainingNode:OnShow(uiParams)
    self:InitWidget()
end

function UIN30TrainingNode:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.bg = self:GetUIComponent("Image", "bg")
    self.lock = self:GetUIComponent("Image", "lock")
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    self.name2 = self:GetUIComponent("UILocalizationText", "name_boss")
    self.star = self:GetGameObject("star")

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

    self._atlas = self:GetAsset("UIN30.spriteatlas", LoadType.SpriteAtlas)
    self._anim = self:GetUIComponent("Animation", "Anim")
    self._bgGo = self:GetGameObject("bg")
    self._maskGo = self:GetGameObject("mask")
    self._pass = self:GetGameObject("pass")
end

function UIN30TrainingNode:GetNodeCfg()
    local NodeCfg =
    {
        SLeval = 111111, --s关枚举id
        Passed = 888, --通关后文本和阴影颜色
    }

    NodeCfg[DiscoveryStageType.FightNormal] =
    {
        [1] = {
            normal = "n30_yhjf_di02",
            press = "",
            lock = "n30_yhjf_di04",
            textColor = Color(65 / 255, 40 / 255, 17 / 255), -- 不使用
            textShadow = Color(0 / 255, 0 / 255, 0 / 255), -- 不使用
            normalStar = "",
            passStar = "n31_xxg_star01"
        }, --普通样式
        [2] = {
            normal = "",
            press = "",
            lock = "",
            textColor = Color(241 / 255, 255 / 255, 117 / 255),
            textShadow = Color(111 / 255, 52 / 255, 25 / 255),
            normalStar = "",
            passStar = ""
        } --高难样式
    }
    NodeCfg[DiscoveryStageType.FightBoss] =
    {
        [1] = {
            normal = "n30_yhjf_di03",
            press = "",
            lock = "n30_yhjf_di04",
            textColor = Color.New(212 / 255, 148 / 255, 91 / 255), -- 不使用
            textShadow = Color.New(255 / 255, 255 / 255, 255 / 255), -- 不使用
            normalStar = "",
            passStar = ""
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
            normal = "n30_yhjf_di02",
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

function UIN30TrainingNode:SetAtlas(atlas)
    self._atlas = atlas
end

---@param passInfo cam_mission_info
function UIN30TrainingNode:SetData(lineCfg, passInfo, cb, last, last2)
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
    local lock = nil 
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
            --self._stars[i].sprite = self._atlas:GetSprite(url)
            --self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        end
        --self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
        self._pass:SetActive(true)
    else
        --没有通关数据则视为当前关
        textColor = typeCfg[hardParam].textColor
        -- shadowColor = typeCfg[hardParam].textShadow
        bg = typeCfg[hardParam].normal
        lock = typeCfg[hardParam].lock
        local stars = 0
        for i = 1, 3 do
            local pass = i <= stars
            local url = pass and typeCfg[hardParam].passStar or typeCfg[hardParam].normalStar
            --self._stars[i].sprite = self._atlas:GetSprite(url)
            --self._stars[i].gameObject:SetActive(not string.isnullorempty(url))
        end
        --self.star:SetActive(missionCfg.Type ~= DiscoveryStageType.Plot)
        self._pass:SetActive(false)
    end
    self:_SetRed(false)
    self.bg.sprite = self._atlas:GetSprite(bg)
    if lock then
        self.lock.sprite =  self._atlas:GetSprite(lock)
    else
        self.lock.gameObject:SetActive(false)
    end
    
    if last2 then
        local cfg = Cfg.cfg_component_line_mission {CampaignMissionId = self._missionID}
        if cfg[1] and cfg[1].NeedMissionId then
            self.lock.gameObject:SetActive(true)
            local roleModule = GameGlobal.GetModule(RoleModule)
            local pstid = roleModule:GetPstId()
            local dbStr = "chess" .. cfg[1].NeedMissionId .. pstid
            local dbHas = LocalDB.GetInt(dbStr, 0)
            --self.star:SetActive(true)
            --self._btn:SetActive(true)
            if dbHas and dbHas == 1 then
                dbHas = dbHas + 1
                LocalDB.SetInt(dbStr, dbHas)
                --local lockName = "UIN15ChessMapNode:_anim"
                self:StartTask(
                    function(TT)
                        -- self:Lock(lockName)
                        -- YIELD(TT, 666)
                        -- self._anim:Play("uieffanim_N15_UIN15ChessMapNode_open01")
                        -- YIELD(TT, 1100)
                        self._isonClick = true
                        --self:UnLock(lockName)
                    end
                )
            else
                self._isonClick = true
                self.lock.gameObject:SetActive(false)
            end
        end
    elseif last then
        self.lock.gameObject:SetActive(true)
        --self.star:SetActive(false)
        -- self.bg.sprite = self._atlas:GetSprite(lock)
        --self._btn:SetActive(false)
        --self.mask.gameObject:SetActive(false)
        --self.name:SetText("<color=#bfbfbf>".. StringTable.Get("str_toast_manager_not_open").. "</color>")
    else
        --self.star:SetActive(true)
        --self._btn:SetActive(true)
        self.lock.gameObject:SetActive(false)
        self._isonClick = true
    end

    -- self.name.color = textColor
    --剧情路点点击后为了截屏而滚动
    self._isStoryNode = missionCfg.Type == DiscoveryStageType.Plot

    if lineCfg.MapPosY >= 0 then
        self._anim:Play("uieff_UIN30TrainingNode_up")
    else
        self._anim:Play("uieff_UIN30TrainingNode_down")
    end
end

function UIN30TrainingNode:_SetRed(isShow)
    local redObj = self:GetGameObject("red")
    redObj:SetActive(isShow)
end

function UIN30TrainingNode:BtnOnClick(go)
    if self._onClick and self._isonClick then
        self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
    else
        ToastManager.ShowToast(StringTable.Get("str_n30_train_locked_prev_popup"))
    end
    --self._onClick(self._missionID, self._isStoryNode, self._rectTransform.position)
end
