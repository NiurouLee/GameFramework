--
---@class UIPetEquipDetailPanel : UICustomWidget
_class("UIPetEquipDetailPanel", UICustomWidget)
UIPetEquipDetailPanel = UIPetEquipDetailPanel
--初始化
function UIPetEquipDetailPanel:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIPetEquipDetailPanel:InitWidget()
    --generated--
    ---@type UILocalizationText
    self._atk = self:GetUIComponent("UILocalizationText", "atkV")
    ---@type UILocalizationText
    self._def = self:GetUIComponent("UILocalizationText", "defV")
    ---@type UILocalizationText
    self._hp = self:GetUIComponent("UILocalizationText", "hpV")
    ---@type UICustomWidgetPool
    self._attPool = self:GetUIComponent("UISelectObjectPath", "attPool")
    ---@type UnityEngine.GameObject
    self._atts = self:GetGameObject("atts")
    self._maxLv = self:GetGameObject("maxLv")
    ---@type UnityEngine.UI.RectTransform
    self._skill = self:GetUIComponent("RectTransform","skill")
    -- ---@type UICustomWidgetPool
    -- self._skillPath = self:GetUIComponent("UISelectObjectPath", "skillPath")
    ---@type UILocalizedTMP
    self._skillDesc = self:GetUIComponent("UILocalizedTMP", "skillDesc")
    self._skillDesc.onHrefClick = function(hrefName)
        GameGlobal.UIStateManager():ShowDialog("UISkillHrefInfo", hrefName)
    end
    self._skillIcon = self:GetUIComponent("RawImageLoader", "skillIcon")

    self._skillInfoBtnGo = self:GetGameObject("skillUpInfoBtn")
    self._attInfoBtnGo = self:GetGameObject("attUpInfoBtn")

    ---@type UILocalizationText
    -- self._txtLv = self:GetUIComponent("UILocalizationText", "txtLv")
    self._refineItemPool = self:GetUIComponent("UISelectObjectPath", "refineItem")
    self.onlyIntroGo = self:GetGameObject("onlyIntroGo")
    self.introlAndUpGo = self:GetGameObject("introlAndUpGo")

    self._lv = self:GetUIComponent("UILocalizationText", "lv")
    self.animation = self:GetUIComponent("Animation", "animation")
    --generated end--
end
--设置数据
function UIPetEquipDetailPanel:SetData(petData)
    ---@type MatchPet
    self._petData = petData
    self._petId = self._petData:GetTemplateID()
    self._pstId = self._petData:GetPstID()

    self._currentEquipLv = self._petData:GetEquipLv()
    self._elem = self._petData:GetPetFirstElement()

    self._equipMaxLv = 0
    local cfg_equip = Cfg.cfg_pet_equip {PetID = self._petId}
    if cfg_equip and #cfg_equip > 0 then
        self._equipMaxLv = cfg_equip[#cfg_equip].Level
    else
        Log.fatal("###[UIPetEquipDetailPanel] cfg_pet_equip is nil ! id --> ", self._petId)
    end

    self:_CheckInfoBtnActive()
    self:_ShowEquipInfo()
    self:_ShowPetRefineInfo()
end

--检查info按钮的显示
function UIPetEquipDetailPanel:_CheckInfoBtnActive()
    local cfg_equip = Cfg.cfg_pet_equip {PetID = self._petId}
    if not cfg_equip then
        Log.fatal("###[UIPetEquipController] cfg_equip is nil ! id --> ", self._petId)
    end

    local dataCount = 0
    local skillCount = 0

    local attInfoBtnActive = false
    local skillInfoBtnActive = false

    for i = 1, #cfg_equip do
        local cfgData = cfg_equip[i]

        --att
        --取当前等级以上的技能信息（如果取全部的则把>后面改成最低等级,>改为>=）
        --从2级开始显示
        if cfgData.Level > 1 then
            --和前一级作比较，做差值
            local cfgDataLast = cfg_equip[i - 1]
            local addPro = cfgData.PropertyRestraint - cfgDataLast.PropertyRestraint
            local addAtk = cfgData.Attack - cfgDataLast.Attack
            local addDef = cfgData.Defence - cfgDataLast.Defence
            local addHp = cfgData.Health - cfgDataLast.Health
            if addPro ~= 0 or addAtk ~= 0 or addDef ~= 0 or addHp ~= 0 then
                dataCount = dataCount + 1
            end
        end

        --skill
        --取当前等级以上的技能信息（如果取全部的则把>后面改成最低等级,>改为>=,但是需要把等于当前等级的那条删掉）
        --if cfgData.Level > self._equipLv then
        --有字段是否提升了技能
        if cfgData.IsParamImprove and cfgData.IsParamImprove == 1 then
            skillCount = skillCount + 1
        end
    end
    if dataCount > 0 then
        attInfoBtnActive = true
    end
    self._attInfoBtnGo:SetActive(attInfoBtnActive)

    if skillCount > 0 then
        skillInfoBtnActive = true
    end
    self._skillInfoBtnGo:SetActive(skillInfoBtnActive)
end

function UIPetEquipDetailPanel:_ShowEquipInfo()
    self:_CheckMaxLv()
    self._lv:SetText(StringTable.Get("str_pet_equip_Lv") .. self._currentEquipLv)
    local isShowAtt = self:_IsShowAtt()
    if isShowAtt then
        self._atts:SetActive(true)
        self:_ShowAttInfo()
       -- self._skill.anchoredPosition = Vector2(self._skill.anchoredPosition.x, -167.6)
    else
        self._atts:SetActive(false)
       -- self._skill.anchoredPosition = Vector2(self._skill.anchoredPosition.x, 8)
    end
    self:_ShowSkillInfo()
end

--检查最大级
function UIPetEquipDetailPanel:_CheckMaxLv()
    if self._currentEquipLv >= self._equipMaxLv then
        self.onlyIntroGo:SetActive(true)
        self.introlAndUpGo:SetActive(false)
        --self._maxLv:SetActive(true)
    else
       -- self._maxLv:SetActive(false)
        self.onlyIntroGo:SetActive(false)
        self.introlAndUpGo:SetActive(true)
    end
end

--是否显示属性，和策划对的，一直有-2020/12/25/17.01
function UIPetEquipDetailPanel:_IsShowAtt()
    return true
end

--显示装备信息adh
function UIPetEquipDetailPanel:_ShowAttInfo()
    local cfg_pet_equip = Cfg.cfg_pet_equip {PetID = self._petId, Level = self._currentEquipLv}
    if not cfg_pet_equip then
        Log.fatal(
            "###[UIPetEquipController]cfg_pet_equip is nil ! id --> ",
            self._petId,
            "|level --> ",
            self._currentEquipLv
        )
        return
    end

    local atk = cfg_pet_equip[1].Attack
    local def = cfg_pet_equip[1].Defence
    local hp = cfg_pet_equip[1].Health

    self._atk:SetText("+" .. atk)
    self._def:SetText("+" .. def)
    self._hp:SetText("+" .. hp)

    local elemValue = cfg_pet_equip[1].PropertyRestraint

    ---@type UIPetEquipElemItem
    local attItem = self._attPool:SpawnObject("UIPetEquipElemItem")
    attItem:SetData(self._elem, elemValue)
end

--显示装备信息skill
function UIPetEquipDetailPanel:_ShowSkillInfo()
    local skillID = self._petData:GetPetPassiveSkill()
    local cfg = BattleSkillCfg(skillID)
    if cfg then
        self._skillIcon:LoadImage(cfg.Icon)
        self._skillDesc:SetText(HelperProxy:GetInstance():GetPetSkillDescFull(self._petData, skillID, true))
    end
end


function UIPetEquipDetailPanel:_ShowPetRefineInfo()
    if not UIPetEquipHelper.HasRefine( self._petId) then
        return
    end
    if not self._refineItem then
        self._refineItem = self._refineItemPool:SpawnObject("UIPetEquipLvIcon")
    end

    self._refineItem:SetData(self._petData)
end

--升级按钮
function UIPetEquipDetailPanel:UpBtnOnClick()
    local aps = GameGlobal.GetModule(SerialAutoFightModule):GetApsData()
    aps:SetTrack(true)

    self:ShowDialog("UIPetEquipUpLevelController", self._petData)
end

--按钮点击
function UIPetEquipDetailPanel:IntrBtnOnClick(go)
    self:ShowDialog("UIPetEquipIntrController", self._petId)
end

--按钮点击
function UIPetEquipDetailPanel:IntrBtn2OnClick(go)
    self:ShowDialog("UIPetEquipIntrController", self._petId)
end

--按钮点击
function UIPetEquipDetailPanel:SkillUpInfoBtnOnClick(go)
    local skillID = self._petData:GetPetPassiveSkill()
    self:ShowDialog("UIPetEquipUpLvInfoController", self._petData, self._currentEquipLv, skillID)
end
--按钮点击
function UIPetEquipDetailPanel:AttUpInfoBtnOnClick(go)
    self:ShowDialog("UIPetEquipUpLvInfoController", self._petData, self._currentEquipLv)
end

function UIPetEquipDetailPanel:PlayAni(aniName)
    if self.animation then
        self.animation:Play(aniName)
    end
end