---@class UITrailLevelBuffPetItem : UICustomWidget
_class("UITrailLevelBuffPetItem", UICustomWidget)
UITrailLevelBuffPetItem = UITrailLevelBuffPetItem

function UITrailLevelBuffPetItem:OnShow()
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._headImg = self:GetUIComponent("RawImageLoader", "Head")
    ---@type UnityEngine.UI.Image
    self._firstElementImg = self:GetUIComponent("Image", "FirstElement")
    ---@type UnityEngine.UI.Image
    self._secondElementImg = self:GetUIComponent("Image", "SecondElement")
    self._secondElementGo = self:GetGameObject("SecondElement")
    self._lockGo = self:GetGameObject("Lock")
    self._selectGo = self:GetGameObject("Select")
    self._infoGo = self:GetGameObject("Info")
    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }
    self._starPanel = self:GetUIComponent("UISelectObjectPath", "StarPanel")
    self._selectGo:SetActive(false)
end

function UITrailLevelBuffPetItem:ParseConfig()
    if not self._petTemplateId then
        return
    end
    local cfg_pet = Cfg.cfg_pet[self._petTemplateId]
    if not cfg_pet then
        return
    end
    self._firstElement = cfg_pet.FirstElement
    self._secondElement = 0 --大于0表示存在第二属性
    if self._grade >= cfg_pet.Element2NeedGrade then
        self._secondElement = cfg_pet.SecondElement
    end
    local cfg = Cfg.cfg_tale_pet[self._petTemplateId]
    self._head = cfg.PetIcon
end

function UITrailLevelBuffPetItem:Refresh(data, buffDes)
    if not data then
        return
    end
    ---@type UITrailLevelBuffDes
    self._buffDesUI = buffDes
    --数据
    self._petTemplateId = data.templateId
    self._isLock = data.lock
    ---@type Pet
    local petData = nil
    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    if self._isLock then
        self._grade = self:GetMaxGrade(self._petTemplateId)
    else
        petData = petModule:GetPetByTemplateId(self._petTemplateId)
        self._grade = petData:GetPetGrade()
    end
    self:ParseConfig()
    --刷新界面
    self._headImg:LoadImage(self._head)
    if self._isLock then
        self._infoGo:SetActive(false)
    else
        self._infoGo:SetActive(true)
        --觉醒
        local cfg_pet = Cfg.cfg_pet[self._petTemplateId]
        local star = cfg_pet.Star
        local awake = petData:GetPetAwakening()
        self._starPanel:SpawnObjects("UITrailLevelBuffPetStar", star)
        ---@type UITrailLevelBuffPetStar[]
        local starItems = self._starPanel:GetAllSpawnList()
        for i = 1, awake do
            starItems[i]:Refresh(true)
        end
        for i = awake + 1, star do
            starItems[i]:Refresh(false)
        end
    end
    --元素类型
    self._firstElementImg.sprite =
        self.atlasProperty:GetSprite(
        UIPropertyHelper:GetInstance():GetColorBlindSprite(self.ElementSpriteName[self._firstElement])
    )
    if self._secondElement <= 0 then
        self._secondElementGo:SetActive(false)
    else
        self._secondElementGo:SetActive(true)
        self._secondElementImg.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(self.ElementSpriteName[self._secondElement])
        )
    end
    self._lockGo:SetActive(self._isLock)
end

function UITrailLevelBuffPetItem:GetMaxGrade(templateId)
    local cfgs = Cfg.cfg_pet_grade {PetID = templateId}
    local max = 0 --Grade最小值为0
    for _, c in pairs(cfgs) do
        if max < c.Grade then
            max = c.Grade
        end
    end
    return max
end

function UITrailLevelBuffPetItem:PetBtnOnClick()
    if self._isLock then
        ToastManager.ShowToast(StringTable.Get("str_tale_pet_trail_level_pet_unget_tips"))
        return
    end
    self._buffDesUI:OnPetClick(self)
end

function UITrailLevelBuffPetItem:Select()
    self._selectGo:SetActive(true)
end

function UITrailLevelBuffPetItem:UnSelect()
    self._selectGo:SetActive(false)
end
