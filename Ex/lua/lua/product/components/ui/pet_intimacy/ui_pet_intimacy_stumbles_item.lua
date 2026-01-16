---@class UIPetIntimacyStumblesItem:UICustomWidget
_class("UIPetIntimacyStumblesItem", UICustomWidget)
UIPetIntimacyStumblesItem = UIPetIntimacyStumblesItem

function UIPetIntimacyStumblesItem:OnShow(uiParams)
    ---@type UnityEngine.UI.Image
    self._imgUnlock = self:GetUIComponent("Image", "imgUnlock")
    ---@type UnityEngine.UI.Image
    self._imgLock = self:GetUIComponent("Image", "imgLock")
    ---@type UILocalizationText
    self._txtLv = self:GetUIComponent("UILocalizationText", "txtLv")
    ---@type UnityEngine.GameObject
    self._unlock = self:GetGameObject("unlock")
    ---@type UILocalizationText
    self._txtUnlock = self:GetUIComponent("UILocalizationText", "txtUnlock")
    ---@type UILocalizationText
    self._txtAttack = self:GetUIComponent("UILocalizationText", "txtAttack")
    ---@type UILocalizationText
    self._txtDefend = self:GetUIComponent("UILocalizationText", "txtDefend")
    ---@type UILocalizationText
    self._txtHp = self:GetUIComponent("UILocalizationText", "txtHp")
end

---@param lv number 亲密度等级
---@param pet Pet
function UIPetIntimacyStumblesItem:Flush(lv, pet)
    local petTemplateId = pet:GetTemplateID()
    local cfg = Cfg.cfg_pet_affinity {PetID = petTemplateId, AffinityLevel = lv}
    if not cfg then
        return
    end
    local c = cfg[1]
    if not c then
        return
    end
    local level = pet:GetPetAffinityLevel()
    local unlock = level >= lv
    self._imgUnlock.gameObject:SetActive(unlock)
    self._imgLock.gameObject:SetActive(not unlock)
    self._txtLv:SetText(StringTable.Get("str_affinity_stumbles_lv", lv))
    self._unlock:SetActive(not unlock)

    local tUnlockProfile = UIPetIntimacyLevelUp.GetUnlockProfile(petTemplateId, lv - 1, lv)
    local isUnlockProfile = tUnlockProfile and table.count(tUnlockProfile) > 0
    local tUnlockVoice = UIPetIntimacyLevelUp.GetUnlockVoice(petTemplateId,nil, lv - 1, lv)
    local isUnlockVoice = tUnlockVoice and table.count(tUnlockVoice) > 0
    local key = ""
    if isUnlockProfile and isUnlockVoice then
        key = "str_affinity_stumbles_unlock_new_profile_voice"
    else
        if isUnlockProfile and not isUnlockVoice then
            key = "str_affinity_stumbles_unlock_new_profile"
        end
        if not isUnlockProfile and isUnlockVoice then
            key = "str_affinity_stumbles_unlock_new_voice"
        end
    end
    if string.isnullorempty(key) then
        self._txtUnlock:SetText("")
    else
        self._txtUnlock:SetText(StringTable.Get(key))
    end

    self._txtAttack:SetText("+" .. c.Attack)
    self._txtDefend:SetText("+" .. c.Defence)
    self._txtHp:SetText("+" .. c.Health)
    local f208 = 208 / 255
    local colorText = Color(f208, f208, f208, 1)
    if unlock then
        colorText = Color(1 / 255, 242 / 255, 1, 1)
    end
    self._txtAttack.color = colorText
    self._txtDefend.color = colorText
    self._txtHp.color = colorText
end
