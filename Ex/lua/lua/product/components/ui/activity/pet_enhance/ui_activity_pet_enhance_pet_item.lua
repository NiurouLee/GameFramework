---@class UIActivityPetEnhancePetItem:UICustomWidget
_class("UIActivityPetEnhancePetItem", UICustomWidget)
UIActivityPetEnhancePetItem = UIActivityPetEnhancePetItem

function UIActivityPetEnhancePetItem:Constructor()
    self._pet_pstid = 0
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
end

function UIActivityPetEnhancePetItem:OnShow()
    self._headImage = self:GetUIComponent("RawImageLoader", "headImage")
    self._attribute1 = self:GetUIComponent("Image", "attribute1")
    self._attribute2 = self:GetUIComponent("Image", "attribute2")
    self._petAreaGo = self:GetGameObject("PetArea")
    self._emptyAreaGo = self:GetGameObject("EmptyArea")
    self._petAreaGo:SetActive(false)
    self._emptyAreaGo:SetActive(true)
end

function UIActivityPetEnhancePetItem:OnHide()

end
function UIActivityPetEnhancePetItem:HeadBgOnClick()
    --打开光灵预览
    if not self._cfgCorrect then
        return
    end
    local petId = self._cfgCorrect.PetId
    local petInfo = MatchPetInfo:New()
    petInfo.pet_pstid = 0
    petInfo.pet_power = -1 --初始能量
    petInfo.template_id = self._cfgCorrect.PetId --配置id
    petInfo.level = self._cfgCorrect.Level
    petInfo.grade = self._cfgCorrect.GradeLv
    petInfo.awakening = self._cfgCorrect.AwakeningLv
    --petInfo.attack = self._cfgCorrect.Attack
    --petInfo.defense = self._cfgCorrect.Def
    --petInfo.max_hp = self._cfgCorrect.Hp
    --petInfo.cur_hp = self._cfgCorrect.Hp
    petInfo.equip_lv = self._cfgCorrect.EquipLv
    petInfo.equip_refine_lv = self._cfgCorrect.EquipRefineLv
    petInfo.affinity_level = 1
    --petInfo.after_damage = 0 --伤害后处理系数
    --petInfo.team_slot = 6 --宝宝在星灵队伍中的位置

    -- petInfo.level = partnerCfg.Level or 1 --等级
    -- petInfo.grade = partnerCfg.GradeLevel or 0 --觉醒
    -- petInfo.awakening = partnerCfg.AwakenLevel or 0--突破
    -- petInfo.affinity_level = partnerCfg.AffinityLevel or 1 --亲密度等级
    -- petInfo.attack = partnerCfg.Attack or 0 --攻击力
    -- petInfo.defense = partnerCfg.Defence or 0 --防御力
    -- petInfo.max_hp = partnerCfg.Health or 0 --血量上限
    -- petInfo.cur_hp = partnerCfg.Health or 0 -- 当前血量
    -- petInfo.equip_lv = partnerCfg.EquipLevel or 0 --装备等级
    -- petInfo.after_damage = 0 --伤害后处理系数
    -- petInfo.team_slot = 6 --宝宝在星灵队伍中的位置

    petInfo.m_nHelpPetKey = 0 --助战标识
    ------------------
    ---@type MatchPet
    self._matchPet = MatchPet:New(petInfo)
    self._matchPet:CalAttr()
    --self:ShowDialog("UISpiritDetailGroupController", petId, false)
    local customPetData = UICustomPetData:New()
    customPetData:SetPetId(petId)
    customPetData:SetAttack(self._matchPet:GetPetAttack())
    customPetData:SetHP(self._matchPet:GetPetHealth())
    customPetData:SetDef(self._matchPet:GetPetDefence())
    customPetData:SetAwakeing(self._matchPet:GetPetAwakening())
    customPetData:SetGrade(self._matchPet:GetPetGrade())
    customPetData:SetEquip(self._matchPet:GetEquipLv())

    customPetData:SetDetailTitleText("str_activity_pet_enhance_detail_titile")
    customPetData:SetShowLevelArea(true)
    customPetData:SetCustomLevel(self._cfgCorrect.Level)--默认是显示满级，这里设置需要显示的等级
    customPetData:SetAffinityLevel(1)--默认是显示满级，这里设置需要显示的等级
    customPetData:SetEquipRefineLevel(self._matchPet:GetEquipRefineLv())--默认是显示满级，这里设置需要显示的等级
    --customPetData:SetShowBtnStatus(false)
    -- customPetData:SetBtnInfoCallback(
    --     function()
    --         GameGlobal.UIStateManager():ShowDialog("UIN25VampireTips")
    --     end
    -- )
    --customPetData:SetBtnInfoName("N25_mcwf_btn6")
    --customPetData:SetHideHomeBtn(true)
    GameGlobal.UIStateManager():ShowDialog("UIShopPetDetailController", customPetData:GetPetId(), 1, 0, customPetData,0,1)
end

function UIActivityPetEnhancePetItem:InitByCfg(cfgCorrect)
    local petData = nil
    self._cfgCorrect = cfgCorrect
    if cfgCorrect ~= nil then
        local pet_data = _G.pet_data
        local petIndo = pet_data:New()
        petIndo.template_id = cfgCorrect.PetId
        petIndo.level = cfgCorrect.Level
        petIndo.grade = cfgCorrect.GradeLv
        petIndo.awakening = cfgCorrect.AwakeningLv
        petIndo.affinity_level = 1
        petIndo.equip_lv = cfgCorrect.EquipLv
        petIndo.equip_refine_lv = cfgCorrect.EquipRefineLv
        petIndo.current_skin = 0 -- current_skin不在pet_data中 用于非本地星灵

        petData = Pet:New(petIndo)
    end

    self:UpdatePetItem(petData)
end

function UIActivityPetEnhancePetItem:UpdatePetItem(petData)
    self._petAreaGo:SetActive(petData ~= nil)
    self._emptyAreaGo:SetActive(petData == nil)
    self._headImage.gameObject:SetActive(petData ~= nil)
    self._attribute1.gameObject:SetActive(petData ~= nil)
    self._attribute2.gameObject:SetActive(petData ~= nil)

    if petData ~= nil then
        self._headImage:LoadImage(petData:GetPetTeamBody(PetSkinEffectPath.CARD_TEAM))
        self:SetAtlasProperty(self._attribute1, petData:GetPetFirstElement())
        self:SetAtlasProperty(self._attribute2, petData:GetPetSecondElement())
    end
end
function UIActivityPetEnhancePetItem:SetAtlasProperty(img, idProperty)
    local cfgSingle = nil
    local cfg_pet_element = Cfg.cfg_pet_element {}
    if cfg_pet_element then
        cfgSingle = cfg_pet_element[idProperty]
    end

    if cfgSingle then
        img.gameObject:SetActive(true)
        img.sprite = self._atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfgSingle.Icon))
    else
        img.gameObject:SetActive(false)
    end
end