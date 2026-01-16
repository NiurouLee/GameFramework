---@class UIPetEquipController : UIController
_class("UIPetEquipController", UIController)
UIPetEquipController = UIPetEquipController
function UIPetEquipController:Constructor()
    ---@type PetModule
    self._petModule = self:GetModule(PetModule)
    self._atlas = self:GetAsset("UIPetEquip.spriteatlas", LoadType.SpriteAtlas)

    self:AttachEvent(GameEventType.OnEquipDataChanged, self.OnEquipDataChanged)
    self.tabCfg =
    {
        [1] = {name = "str_pet_equip_base"},
        [2] = {name = "str_pet_equip_refinement"}
    }
end

function UIPetEquipController:OnEquipDataChanged()
    self._currentEquipLv = self._petData:GetEquipLv()

    self:_OnValue()
    if self.lastSelect == 1 then
        self._petDetail:SetData(self._petData)
    end
end

function UIPetEquipController:OnShow(uiParams)
    self:_GetComponents()
    ---@type MatchPet
    self._petData = uiParams[1]
    self._petId = self._petData:GetTemplateID()
    self._pstId = self._petData:GetPstID()

    self._currentEquipLv = self._petData:GetEquipLv()
    self._elem = self._petData:GetPetFirstElement()

    self._equipMaxLv = 0
    local cfg_equip = Cfg.cfg_pet_equip {PetID = self._petId}
    if cfg_equip and #cfg_equip > 0 then
        self._equipMaxLv = cfg_equip[#cfg_equip].Level
    else
        Log.fatal("###[UIPetEquipController] cfg_pet_equip is nil ! id --> ", self._petId)
    end

    self:_OnValue()

    self:InitTabs()
    self:ShowRefineEffect(self._petData:GetEquipRefineLv() > 0)
end

function UIPetEquipController:InitTabs()
    if UIPetEquipHelper.HasRefine( self._petId) then
        self._tabGo:SetActive(true)
        --精炼功能开放
        self.tabs = self._tabs:SpawnObjects("UIPetEquipTab", 2)
        for i, v in ipairs(self.tabs) do
            local cfg = self.tabCfg[i]
            v:SetData(cfg.name, function()
                self:OnTabSelect(i)
            end)
            v:SetSelect(i == 1)
        end
    else
        --精炼功能未开放
        self._tabGo:SetActive(false)
    end

    self:OnTabSelect(1, true)
end

function UIPetEquipController:OnTabSelect(index, isInit)
    if isInit then
        self.lastSelect = index
    else
        if self.lastSelect == index then
            return
        end
    end
    
    if self.tabs then
        if self.lastSelect then
            self.tabs[self.lastSelect]:SetSelect(false)
        end
        self.tabs[index]:SetSelect(true)
        self.tabs[2]:SetPoint(UIPetEquipHelper.CheckRefineRed(self._petData))
    end
    self.lastSelect = index
    if isInit then
        self._petDetailGo:SetActive(index == 1)
        self._petRefineGo:SetActive(index == 2)
    end

    if index == 1 then
        self._petDetail:SetData(self._petData)
    elseif index == 2 then
        self._petRefine:SetData(self._petData, self)
        self.tabs[2]:SetPoint(UIPetEquipHelper.CheckRefineRed(self._petData))
    end
    if not isInit then
        --playAniamtion
        self:_PlayTabSwithAnimation()
    end
end

function UIPetEquipController:_PlayTabSwithAnimation()
    self:StartTask(
        function(TT)
            local lockName = "UIPetEquipController_TabSwitch"..self.lastSelect
            self:Lock(lockName)

            if self.lastSelect == 2 then
                self._petDetail:PlayAni("uieff_UIPetEquipDetailPanel_switchout")
                --由基础切换到精炼
                YIELD(TT, 130)
                self._petDetailGo:SetActive(false)
                self._petRefineGo:SetActive(true)
                YIELD(TT, 10)
                self._petRefine:PlayTabInAni(TT)
                YIELD(TT, 200)
            else
                --由精炼切换到基础
                self._petRefine:PlayTabOutAni(TT)
                YIELD(TT, 300)
                self._petRefineGo:SetActive(false)
                self._petDetailGo:SetActive(true)
                self._petDetail:PlayAni("uieff_UIPetEquipDetailPanel_Switchin")
                YIELD(TT, 130)
            end
            self:UnLock(lockName)

            if self.lastSelect == 2 then
                self._petRefine:CheckGuide()
            end
        end,
        self
    )
end

function UIPetEquipController:_GetComponents()
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._name = self:GetUIComponent("UILocalizationText", "name")
    -- self._lv = self:GetUIComponent("UILocalizationText", "lv")
    self._tabs = self:GetUIComponent("UISelectObjectPath", "tabs")
    self._tabGo = self:GetGameObject("tabs")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            --check
            self:CallUIMethod("UISpiritDetailGroupController", "RefreshEquipRed")
            self:CloseDialog()
        end,
        function()
            self:ShowDialog("UIHelpController", "UIPetEquipController")
        end
    )

    local petDetail = self:GetUIComponent("UISelectObjectPath", "petDetail")
    self._petDetailGo = self:GetGameObject("petDetail")
    self._petDetail = petDetail:SpawnObject("UIPetEquipDetailPanel")
    self._petDetailGo:SetActive(false)

    local petRefine = self:GetUIComponent("UISelectObjectPath", "petRefine")
    self._petRefineGo = self:GetGameObject("petRefine")
    self._petRefine = petRefine:SpawnObject("UIPetEquipRefinePanel")
    self._petRefineGo:SetActive(false)

    local sop = self:GetUIComponent("UISelectObjectPath", "mainmenu")
    self.currencyMenu = sop:SpawnObject("UICurrencyMenu")
    self.currencyMenu:SetData({RoleAssetID.RoleAssetGold})

    self.aniCamera = self:GetUIComponent("Animation", "aniCamera")
    self.aniPetEquipIn = self:GetUIComponent("Animation", "aniPetEquipIn")
    self.aniRefineEffect = self:GetUIComponent("Animation", "aniRefineEffect")
    self.aniRotateBgLine = self:GetUIComponent("Animation", "aniRotateBgLine")
    self.aniRotatexu = self:GetUIComponent("Animation", "aniRotatexu")
    self.aniIconSwing = self:GetUIComponent("Animation", "aniIconSwing")


    self.iconGo = self:GetGameObject("icon")

    self.icon1Go = self:GetGameObject("icon1")
    self.bg_circlemaskGo = self:GetGameObject("bg_circlemask")
    self.bg_circlewaiGo = self:GetGameObject("bg_circlewai")
    self.circleneiGo = self:GetGameObject("bg_circlenei")
    self.bglineGo = self:GetGameObject("aniRotateBgLine")
    self.aniRotatexuGo = self:GetGameObject("aniRotatexu")
    self.bg_circlecu = self:GetGameObject("bg_circlecu")
end

function UIPetEquipController:_OnValue()
    local cfg = Cfg.cfg_pet_equip_view[self._petId]
    if cfg then
        local icon = cfg.Icon
        local name = cfg.Name

        self._icon:LoadImage(icon)
        self._name:SetText(StringTable.Get(name))
        -- self._lv:SetText(StringTable.Get("str_pet_equip_Lv") .. self._currentEquipLv)
    else
        Log.error("###[UIPetEquipController]cfg is nil ! id --> ", self._petId)
    end
end


function UIPetEquipController:OnHide()
    self._icon = nil
    self._name = nil
    -- self._lv = nil
    self._petId = nil
    self._currentEquipLv = nil
end

function UIPetEquipController:ShowRefineEffect(bShow, dontSwingIcon)
    --self.icon1Go:SetActive(bShow)
    self.bg_circlemaskGo:SetActive(bShow)
    self.bg_circlewaiGo:SetActive(bShow)
    self.circleneiGo:SetActive(bShow)
    self.bglineGo:SetActive(bShow)
    self.aniRotatexuGo:SetActive(bShow)
    self.bg_circlecu:SetActive(bShow)
    if bShow and not dontSwingIcon then
        self.aniIconSwing:Play() 
    end
end

function UIPetEquipController:SetTextureForIcon1()
    local rawImgIcon = self.iconGo:GetComponent("RawImage")
    local srcMainTextrue = rawImgIcon.mainTexture

    local targetRenderer = self.icon1Go:GetComponent("MeshRenderer")
    if not targetRenderer then
        return
    end
    local targetMat = targetRenderer.sharedMaterial
    targetMat.mainTexture = srcMainTextrue
    self.aniIconSwing:Stop() 
end


function UIPetEquipController:ShowRefineSuccEffect(TT)
    self:SetTextureForIcon1()
    self:ShowRefineEffect(true, true)
    self.aniRefineEffect:Play()
    YIELD(TT,1220)
    -- self.aniCamera:Play()
    -- YIELD(TT,600)
    self.aniIconSwing:Play() 
end
