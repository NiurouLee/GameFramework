---@class UITrailLevelBuffDes: UIController
_class("UITrailLevelBuffDes", UIController)
UITrailLevelBuffDes = UITrailLevelBuffDes

function UITrailLevelBuffDes:LoadDataOnEnter(TT, res, uiParams)
    ---@type TalePetModule
    self._talePetModule = GameGlobal.GetModule(TalePetModule)
    self._talePetModule:ApplyBuffInfo(TT)
    self._currentLevel, self._maxLevel = self._talePetModule:GetBuffLevel()
    self._exp, self._maxExp = self._talePetModule:GetBuffExp()
    self._petDatas = {}
    self._talePetCount = 4
    local talePetList = self._talePetModule:GetTalePetList()
    for i = 1, self._talePetCount do
        local data = {}
        data.templateId = talePetList[i]
        data.lock = not self._talePetModule:IsGetTalePet(data.templateId)
        self._petDatas[#self._petDatas + 1] = data
    end
end

function UITrailLevelBuffDes:OnShow()
    ---@type UISelectObjectPath
    local btns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    self._backBtn = btns:SpawnObject("UICommonTopButton")
    self._backBtn:SetData(
        function()
            self:CloseDialog()
        end,
        nil
        -- function()
        --     self:ShowDialog("UIHelpController", "UITrailLevelBuffDes")
        -- end
    )
    self._icon = self:GetUIComponent("RawImageLoader", "Icon")
    self._name = self:GetUIComponent("UILocalizationText", "Name")
    self._levelLabel = self:GetUIComponent("UILocalizationText", "Level")
    self._talePetBuffDesLabel = self:GetUIComponent("UILocalizationText", "TalePetBuffDes")
    self._normalPetBuffDesLabel = self:GetUIComponent("UILocalizationText", "NormalPetBuffDes")
    self._expBar = self:GetUIComponent("Slider", "ExpBar")
    self._expLabel = self:GetUIComponent("UILocalizationText", "Exp")
    self._nextBtn = self:GetGameObject("NextBtn")
    self._preBtn = self:GetGameObject("PreBtn")
    self._anim = self:GetUIComponent("Animation", "Anim")
    self._pets = {}
    for i = 1, self._talePetCount do
        ---@type UISelectObjectPath
        local pet = self:GetUIComponent("UISelectObjectPath", "Pet" .. i)
        ---@type UITrailLevelBuffPetItem
        local item = pet:SpawnObject("UITrailLevelBuffPetItem")
        self._pets[#self._pets + 1] = item
        item:Refresh(self._petDatas[i], self)
    end
    self:RefreshUI()
    self:RefreshButtonStatus()
    self._currentSelectPet = nil
end

---@param petItem UITrailLevelBuffPetItem
function UITrailLevelBuffDes:OnPetClick(petItem)
    if self._currentSelectPet == petItem then
        return
    end
    if self._currentSelectPet then
        self._currentSelectPet:UnSelect()
    end
    self._currentSelectPet = petItem
    self._currentSelectPet:Select()
end

function UITrailLevelBuffDes:RefreshUI()
    local cfg = Cfg.cfg_trail_level_buff_level[self._currentLevel]
    self._name:SetText(StringTable.Get(cfg.BuffName))
    self._talePetBuffDesLabel:SetText(StringTable.Get(cfg.TalePetBuffDes))
    self._normalPetBuffDesLabel:SetText(StringTable.Get(cfg.NormalPetBuffDes1))
    self._icon:LoadImage(cfg.BuffIcon)
    local level, maxLevel = self._talePetModule:GetBuffLevel()
    if level >= maxLevel then
        self._expBar.value = 1
        self._expLabel:SetText(StringTable.Get("str_tale_pet_buff_max_level"))
    else
        self._expBar.value = self._exp / self._maxExp
        self._expLabel:SetText("(" .. self._exp .. "/" .. self._maxExp .. ")")
    end
    self._levelLabel:SetText(StringTable.Get("str_tale_pet_trail_level_buff_level1", self._currentLevel))
end

function UITrailLevelBuffDes:RefreshButtonStatus()
    if self._currentLevel >= self._maxLevel then
        self._nextBtn:SetActive(false)
    else
        self._nextBtn:SetActive(true)
    end
    self._preBtn:SetActive(false)
end

function UITrailLevelBuffDes:NextBtnOnClick()
    self:Lock("UITrailLevelBuffDes_PlayAnim")
    GameGlobal.TaskManager():StartTask(self.PlayAnim, self, false)
end

function UITrailLevelBuffDes:PreBtnOnClick()
    self:Lock("UITrailLevelBuffDes_PlayAnim")
    GameGlobal.TaskManager():StartTask(self.PlayAnim, self, true)
end

function UITrailLevelBuffDes:PlayAnim(TT, isPre)
    self._anim:Play("uieff_uiTrailLevel_title01")
    YIELD(TT, 460)
    if isPre then
        self._currentLevel = self._currentLevel - 1
        self._nextBtn:SetActive(true)
        self._preBtn:SetActive(false)
        self:RefreshUI()
    else
        self._currentLevel = self._currentLevel + 1
        self._nextBtn:SetActive(false)
        self._preBtn:SetActive(true)
        self:RefreshUI()
    end
    YIELD(TT, 730)
    self:UnLock("UITrailLevelBuffDes_PlayAnim")
end

function UITrailLevelBuffDes:InsBtnOnClick()
    self:ShowDialog("UITrailLevelBuffIntroduce", self._currentLevel)
end
