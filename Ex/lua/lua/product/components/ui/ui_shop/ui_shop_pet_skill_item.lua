---@class UIShopPetSkillItem:UICustomWidget
_class("UIShopPetSkillItem", UICustomWidget)
UIShopPetSkillItem = UIShopPetSkillItem
function UIShopPetSkillItem:Constructor()
    self._index = 1
    ---@type SkillConfigHelper
    self._skillConfigHelper = SkillConfigHelper:New()
end
function UIShopPetSkillItem:OnShow()
    self._go = self:GetGameObject()

    self._Anim = self:GetUIComponent("Animation", "Anim")

    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self._txtSkill = self:GetUIComponent("UILocalizationText", "txtSkill")
    self._txtName = self:GetUIComponent("RollingText", "txtName")
    ---@type UILocalizedTMP
    self._txtDesc = self:GetUIComponent("UILocalizedTMP", "txtDesc")
    self._txtDesc.onHrefClick = function(hrefName)
        GameGlobal.UIStateManager():ShowDialog("UISkillHrefInfo", hrefName)
    end
    self._txtEnergy = self:GetUIComponent("UILocalizationText", "txtEnergy")
    self._energy = self:GetGameObject("energy")
    self._chain = self:GetGameObject("chain")
    ---@type UISelectObjectPath
    self._chainSkill = self:GetUIComponent("UISelectObjectPath", "chainSkill")
    self._btnScope = self:GetGameObject("btnScope")
    self._btnScopeImg = self:GetUIComponent("Image", "btnScope")
    self._btnTex = self:GetUIComponent("UILocalizationText", "btnTex")

    ---@type UnityEngine.RectTransform
    self._skillIconRect = self:GetUIComponent("RectTransform", "imgIcon")
    ---@type UnityEngine.UI.ScrollRect
    self._sv = self:GetUIComponent("ScrollRect", "ScrollView")
    self:AttachEvent(GameEventType.OnUISkillScopeClose, self.OnUISkillScopeClose)
    self._module = self:GetModule(PetModule)
    --self._skillConf = Cfg.cfg_battle_skill
    self._chainSkillSpawns = nil
    local sop = self:GetUIComponent("UISelectObjectPath", "preattack")
    sop:SpawnObject("UIPreAttackItem")
    self.preAttackCell = sop:GetAllSpawnList()[1]
    self.preAttackCell:Enable(false)

    self._activeVar = self:GetUIComponent("UISelectObjectPath","activeVar")
    self._activeVarGo = self:GetGameObject("activeVar")

    local activeVarTip = self:GetUIComponent("UISelectObjectPath","activeVarTip")
    ---@type UIActiveVarTip
    self._activeVarTip = activeVarTip:SpawnObject("UIActiveVarTip")
    self._activeVarTipGo = self:GetGameObject("activeVarTip")

    self._flagIconBaseGo = self:GetGameObject("flagIconBaseGo") 
    self._flagIconBaseGo:SetActive(false)
    self._flagIcon = self:GetUIComponent("RawImageLoader","flagIcon") 
end

function UIShopPetSkillItem:ShowInAnim()
    self._Anim:Play("uieff_UIShopPetSkillItem_in")
end

function UIShopPetSkillItem:ShowPreAttack()
    if self.preAttackCell then
        self.preAttackCell:SetData(nil, self._skillID, true, self.pet)
    end
end
function UIShopPetSkillItem:OnHide()
    if self._imgIcon then
        self._imgIcon:DestoryLastImage()
    end
    self:DetachEvent(GameEventType.OnUISkillScopeClose, self.OnUISkillScopeClose)
end

function UIShopPetSkillItem:SetActiveVar()
    self._activeVarGo:SetActive(false)
    self._activeVarTipGo:SetActive(false)
    local cfg = nil
    cfg = BattleSkillCfg(self._skillID)
    if cfg then
        local skillType = cfg.Type
        if skillType == PetSkillType.SkillType_Active then
            local activeVar = nil
            --local activeVar = cfg.ActiveVar
            local activeSkillID = self._skillID
            local equipRefineLv = self.pet:GetEquipRefineLv()
            local equipRefineCfg = Cfg.cfg_pet_equip_refine{PetID=self._petId,Level=equipRefineLv}
            if equipRefineCfg and table.count(equipRefineCfg)>0 then
                local activeVarTab = equipRefineCfg[1].VariantActiveSkillInfo
                if activeVarTab and table.count(activeVarTab)>0 then
                    activeVar =  activeVarTab[activeSkillID]
                end
            end
            if activeVar and table.count(activeVar)>0 then
                --构建主动技变体数据s
                self._activeVarIdx = 1

                self._activeVarTab = {}
                table.insert(self._activeVarTab,self._skillID)
                for index, value in ipairs(activeVar) do
                    table.insert(self._activeVarTab,value)
                end

                self._activeVarTipGo:SetActive(true)
                self._activeVarGo:SetActive(true)

                ---@type UIFightSkillActiveVar
                self._activeVarPool = self._activeVar:SpawnObject("UIFightSkillActiveVar")

                local count = #self._activeVarTab
                self._activeVarPool:SetData(count,self._activeVarIdx,function(idx)
                    self:ChangeVarIdx(idx)
                end,UIFightSkillActiveVarFromType.Shop)
            end
        elseif skillType == PetSkillType.SkillType_ChainSkill then
            --检查连锁数量
            local count = table.count(self._skillList)
            if count > 1 then
                self._activeVarGo:SetActive(true)

                ---@type UIFightSkillActiveVar
                self._activeVarPool = self._activeVar:SpawnObject("UIFightSkillActiveVar")

                self._activeVarPool:SetData(count,self._index,function(idx)
                    self:ChangeVarIdx(idx)
                end,UIFightSkillActiveVarFromType.Shop)
            end
        end
    end
end
function UIShopPetSkillItem:ChangeVarIdx(idx)
    local cfg = BattleSkillCfg(self._skillID)
    if cfg.Type == PetSkillType.SkillType_ChainSkill then
        self._index = idx

        local skills = {}
        local len = table.count(self._skillList)
        for i, v in ipairs(self._skillList) do
            ---@type SkillConfigData
            local skillData = self._skillConfigHelper:GetSkillData(v)
            local skill = {
                id = skillData:GetID(),
                name = skillData:GetSkillName(),
                desc = skillData:GetPetSkillDes(),
                icon = skillData:GetSkillIcon(),
                chainCount = skillData:GetSkillTriggerParam()
            }
            table.insert(skills, skill)
        end

        self:ImgIconDOFadeCallback(len,skills)
    else
        local skillid = self._activeVarTab[idx]
        self._skillID = skillid
        self:RefreshData()
    end
end
function UIShopPetSkillItem:RefreshData()
    local skill_cfg = BattleSkillCfg(self._skillID)
    ---@type PetSkillType
    local skillType = skill_cfg.Type
    local skillTypeStr = ""
    local id
    if skillType == PetSkillType.SkillType_Active then
        skillTypeStr = "str_pet_config_common_major_des"
        id = self._skillID
    elseif skillType == PetSkillType.SkillType_ChainSkill then
        skillTypeStr = "str_pet_config_common_chain_des"
        id = self._skillList
    elseif skillType == PetSkillType.SkillType_Passive then
        skillTypeStr = "str_pet_config_skill_equip"
        id = self._skillID
    end
    
    self._txtSkill:SetText(StringTable.Get(skillTypeStr))

    self._chainSkillSpawns = nil

    self._chainSkillSpawns = nil
    if skillType == PetSkillType.SkillType_ChainSkill then
        self._energy:SetActive(false)
        self._chain:SetActive(true)
        local skills = {}
        local len = table.count(id)
        self._chainSkill:SpawnObjects("UIPetChainSkillItem", len)
        ---@type UIPetChainSkillItem[]
        self._chainSkillSpawns = self._chainSkill:GetAllSpawnList()
        for i, v in ipairs(id) do
            ---@type SkillConfigData
            local skillConfigData = self._skillConfigHelper:GetSkillData(v)
            local skill = {
                id = skillConfigData:GetID(),
                name = skillConfigData:GetSkillName(),
                desc = skillConfigData:GetPetSkillDes(),
                icon = skillConfigData:GetSkillIcon(),
                chainCount = skillConfigData:GetSkillTriggerParam()
            }
            table.insert(skills, skill)
            self._chainSkillSpawns[i]:Flush(skill)
        end
        
        self._index = 1
        if len == 1 then
            self:FlushOtherSkill(skills[1], len, PetSkillType.SkillType_ChainSkill)
        else
            self:ImgIconDOFadeCallback(len, skills)
        end
    elseif skillType == PetSkillType.SkillType_Active then
        self._chain:SetActive(false)
        ---@type SkillConfigData
        local skillConfigData = self._skillConfigHelper:GetSkillData(id)
        if skillConfigData then
            self._go:SetActive(true)
            self._energy:SetActive(UILogicPetHelper.ShowSkillEnergy(skillConfigData:GetSkillTriggerType()))
            --杰诺 san消耗递增
            local descForceParam = {}
            local extraParam = skillConfigData:GetSkillTriggerExtraParam()
            if extraParam and extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes] then
                local baseCost = extraParam[SkillTriggerTypeExtraParam.SanValue]
                local modCost = extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes]
                local curTimes = 0 --局外
                local curCost = baseCost + (modCost * curTimes)
                table.insert(descForceParam,tostring(curCost))
            end
            local skill = {
                id = skillConfigData:GetID(),
                name = skillConfigData:GetSkillName(),
                desc = skillConfigData:GetPetSkillDes(descForceParam),
                icon = skillConfigData:GetSkillIcon(),
                chainCount = skillConfigData:GetSkillTriggerParam()
            }
            self:FlushOtherSkill(skill, PetSkillType.SkillType_Active)
            self._txtEnergy:SetText(StringTable.Get("str_discovery_cool_down", skillConfigData:GetSkillTriggerParam()))
        else
            self._go:SetActive(false)
        end

        --角标
        if self._flagIconBaseGo then
            local variantSkillFlagCfg = Cfg.cfg_variant_skill_flag_icon[self._skillID]
            if variantSkillFlagCfg then
                local flagIconID = variantSkillFlagCfg.FlagIcon
                self._flagIconBaseGo:SetActive(true)
                self._flagIcon:LoadImage(flagIconID)
            else
                self._flagIconBaseGo:SetActive(false)
            end
        end
    elseif skillType == PetSkillType.SkillType_Passive then
        self._energy:SetActive(false)
        self._chain:SetActive(false)
        local confV = BattleSkillCfg(id)
        if confV then
            self._go:SetActive(true)
            local skill = {
                id = confV.ID,
                name = confV.Name,
                desc = confV.Desc,
                icon = confV.Icon,
                chainCount = confV.TriggerParam
            }
            self:FlushEquipSkill(skill)
        else
            self._go:SetActive(false)
        end
    end
    if self._sv then
        self._sv.verticalNormalizedPosition = 1
    end
end
function UIShopPetSkillItem:Flush(nIndex, clientPet, skill_id_list)
    ---@type Pet
    self.pet = clientPet
    self._petId = clientPet:GetTemplateID()
    self._skillList = skill_id_list
    self._skillID = skill_id_list[1]

    self:SetActiveVar()
    self:RefreshData()
    self:ShowPreAttack()
end

function UIShopPetSkillItem:ImgIconDOFadeCallback(len, skills)
    local skill = skills[self._index]
    if skill then
        self:FlushOtherSkill(skill, len)
    end
end

function UIShopPetSkillItem:FlushEquipSkill(skill, len)
    if not self:CheckRefineSkillReplace(skill.id) then
            local descStr =
            HelperProxy:GetInstance():GetEquipSkillDesc(
            skill.desc,
            self.pet:GetTemplateID(),
            self.pet:GetEquipLv(),
            skill.id
        )
        self._txtDesc:SetText(descStr)
    end
    self:FlushSkill(skill, len)
end
function UIShopPetSkillItem:FlushOtherSkill(skill, len)
    -- local descStr = StringTable.Get(skill.desc)
    if not self:CheckRefineSkillReplace(skill.id) then
        self._txtDesc:SetText(skill.desc)
    end
    self:FlushSkill(skill, len)
end

function UIShopPetSkillItem:FlushSkill(skill, len)
    self._imgIcon:DestoryLastImage()
    self._imgIcon:LoadImage(skill.icon)
    self._txtName:RefreshText(StringTable.Get(skill.name))

    --self._txtChainIdx:SetText(skill.chainCount)
    self._canViewSkillScope = self._module:CanSkillPreview(skill.id)
    if self._btnScope then
        self._btnScope:SetActive(self._canViewSkillScope or false)
    end
    if self._canViewSkillScope then
        self._atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
        self._state2sprite = {[1] = "spirit_xiangqing_btn4", [2] = "spirit_xiangqing_btn3"}
        self._state2texColor = {[1] = Color(1, 1, 1, 1), [2] = Color(145 / 255, 145 / 255, 145 / 255, 1)}
    end
    if self._chainSkillSpawns then
        for i, v in ipairs(self._chainSkillSpawns) do
            v:FlushSelect(skill.id, len)
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushSkillScope, skill.id)
end

function UIShopPetSkillItem:imgIconOnClick(go)
    Log.warn("### imgIconOnClick ")
end

function UIShopPetSkillItem:btnScopeOnClick(go)
    if self._canViewSkillScope then
        self._btnScopeImg.sprite = self._atlas:GetSprite(self._state2sprite[2])
        self._btnTex.color = self._state2texColor[2]
    end
    self._skillIconRect.sizeDelta = Vector2(162, 157)

    local cfg = BattleSkillCfg(self._skillID)
    local skillID
    if cfg.Type ~= PetSkillType.SkillType_ChainSkill then
        skillID = self._skillID
    else
        skillID = self._skillList[self._index]
    end
    self:ShowDialog("UISkillScope", skillID, nil, self._btnScope.transform, self.pet)
end

function UIShopPetSkillItem:OnUISkillScopeClose()
    if self._canViewSkillScope then
        self._btnScopeImg.sprite = self._atlas:GetSprite(self._state2sprite[1])
        self._btnTex.color = self._state2texColor[1]
    end
    self._skillIconRect.sizeDelta = Vector2(146, 141)
end

function UIShopPetSkillItem:CheckRefineSkillReplace(skillId)
    if not self.pet or not skillId then
        return false
    end
    
    local refineLv = self.pet:GetEquipRefineLv()
    if refineLv < 1 then
        return false
    end
    
    local refineConfig = UIPetEquipHelper.GetRefineCfg(self.pet:GetTemplateID(), refineLv)
    if not refineConfig then
        return false
    end

    local replaceData = refineConfig.SubstituteSkillDesc
    if not  replaceData then
        return false
    end

    local newDesc
    for k, v in pairs(replaceData) do
        newDesc = v[skillId]
        if newDesc and newDesc ~= "" then
            break
        end
    end

    if newDesc then
        self._txtDesc:SetText(StringTable.Get(newDesc))
        return true
    end

    return false
end
