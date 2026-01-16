--
---@class UIPetEquipRefineAttr : UICustomWidget
_class("UIPetEquipRefineAttr", UICustomWidget)
UIPetEquipRefineAttr = UIPetEquipRefineAttr
--初始化
function UIPetEquipRefineAttr:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIPetEquipRefineAttr:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.attackGo = self:GetGameObject("attackGo")
    ---@typeUnityEngine.GameObject
    self.line1Go = self:GetGameObject("line1Go")
    ---@type UnityEngine.GameObject
    self.defenseGo = self:GetGameObject("defenseGo")
    ---@type UnityEngine.GameObject
    self.line2Go = self:GetGameObject("line2Go")
    ---@type UnityEngine.GameObject
    self.lifeGo = self:GetGameObject("lifeGo")

    ---@type UILocalizationText
    self.attackBaseTxt = self:GetUIComponent("UILocalizationText", "attackBaseTxt")
    ---@type UILocalizationText
    self.attackLvTxt = self:GetUIComponent("UILocalizationText", "attackLvTxt")

    ---@type UILocalizationText
    self.defenseBaseTxt = self:GetUIComponent("UILocalizationText", "defenseBaseTxt")
    ---@type UILocalizationText
    self.defenseLvTxt = self:GetUIComponent("UILocalizationText", "defenseLvTxt")
    
    ---@type UILocalizationText
    self.lifeBaseTxt = self:GetUIComponent("UILocalizationText", "lifeBaseTxt")
    ---@type UILocalizationText
    self.lifeLvTxt = self:GetUIComponent("UILocalizationText", "lifeLvTxt")
    --generated end--
end

function UIPetEquipRefineAttr:SetData(petTemplateId, petLv)
    local cfg = UIPetEquipHelper.GetRefineCfg(petTemplateId, petLv)
    if not cfg then
        return
    end
    local preAttack = 0
    local preDefense = 0
    local preHp = 0
    if petLv > 1 then
        local preCfg = UIPetEquipHelper.GetRefineCfg(petTemplateId, petLv - 1)
        if preCfg then
            preAttack = preCfg.Attack
            preDefense = preCfg.Defence
            preHp = preCfg.Health
        end
    end

    local attack, defense, life
    if cfg.Attack > preAttack then
        attack = {}
        attack.base = preAttack
        attack.up = cfg.Attack
    end

    if cfg.Defence > preDefense then
        defense = {}
        defense.base = preDefense
        defense.up = cfg.Defence
    end

    if cfg.Health > preHp then
        life = {}
        life.base = preHp
        life.up = cfg.Health
    end

    self:_Refresh(attack, defense, life)
end

--设置数据
function UIPetEquipRefineAttr:_Refresh(attack, defense, life)
    self.attackGo:SetActive(attack ~= nil)
    self.line1Go:SetActive(attack ~= nil and (defense ~= nil or life ~= nil))
    if attack then
        self.attackBaseTxt:SetText("+" .. attack.base)
        self.attackLvTxt:SetText("+" .. attack.up - attack.base)
    end

    self.defenseGo:SetActive(defense ~= nil)
    self.line2Go:SetActive(defense ~= nil and life ~= nil)
    if defense then
        self.defenseBaseTxt:SetText("+" .. defense.base)
        self.defenseLvTxt:SetText("+" .. defense.up - defense.base)
    end

    self.lifeGo:SetActive(life ~= nil)
    if life then
        self.lifeBaseTxt:SetText("+" .. life.base)
        self.lifeLvTxt:SetText("+" .. life.up - life.base)
    end
end
