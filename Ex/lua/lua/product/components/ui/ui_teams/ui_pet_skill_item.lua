---@class UIPetSkillItem:UICustomWidget
_class("UIPetSkillItem", UICustomWidget)
UIPetSkillItem = UIPetSkillItem
function UIPetSkillItem:Constructor()
    self._index = 1
    ---@type SkillConfigHelper
    self._skillConfigHelper = SkillConfigHelper:New()
end
function UIPetSkillItem:OnShow()
    self._go = self:GetGameObject()
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
    self._leader = self:GetGameObject("leader")
    ---@type UISelectObjectPath
    self._chainSkill = self:GetUIComponent("UISelectObjectPath", "chainSkill")

    ---@type UnityEngine.UI.ScrollRect
    self._sv = self:GetUIComponent("ScrollRect", "ScrollView")
    self:AttachEvent(GameEventType.OnUISkillScopeClose, self.OnUISkillScopeClose)
    self._module = self:GetModule(PetModule)
    --self._skillConf = Cfg.cfg_battle_skill
    self._chainSkillSpawns = nil

    self._btnGo = self:GetGameObject("showTipBtn")
    self._showTipBtnImg = self:GetUIComponent("Image","showTipBtn")
    self._btnTex = self:GetUIComponent("UILocalizationText", "btnTex")

    -- 先制攻击
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
function UIPetSkillItem:OnHide()
    if self._imgIcon then
        self._imgIcon:DestoryLastImage()
    end
    self:DetachEvent(GameEventType.OnUISkillScopeClose, self.OnUISkillScopeClose)
end

function UIPetSkillItem:ShowPreAttack()
    if self.preAttackCell then
        self.preAttackCell:SetData(self._pet:GetPstID(), self._skillID, false)
    end
end
--技能预览
function UIPetSkillItem:ShowTipBtnOnClick(go)
    if self._isOpenShow == false then
        self._isOpenShow = true

        if self._canViewSkillScope then
            self._showTipBtnImg.sprite = self._atlas:GetSprite(self._state2sprite[1])
            self._btnTex.color = self._state2texColor[2]
        end
        
        self:ShowDialog("UISkillScope", self._skillID, self._pet:GetPstID(), false, self._pet)
    end
end
function UIPetSkillItem:Flush(nIndex, pet, skill_id_list, uiBattle)
    if not uiBattle then
        self._btnScope = self:GetGameObject("btnScope")
        self._imgScope = self:GetGameObject("imgScope")
        if self._imgScope then
            self._imgScope:SetActive(false)
        end
    end

    self._isOpenShow = false

    self._index = 1
    ---@type MatchPet
    self._pet = pet
    self._petId = self._pet:GetTemplateID()
    self.skill_id_list = skill_id_list
    self._skillID = self.skill_id_list[1]

    self:SetActiveVar()

    self:RefreshData()

    self:ShowPreAttack()
end

function UIPetSkillItem:SetActiveVar()
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
            local equipRefineLv = self._pet:GetEquipRefineLv()
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
                end,UIFightSkillActiveVarFromType.Battle)
            end
        elseif skillType == PetSkillType.SkillType_ChainSkill then
            local count = table.count(self.skill_id_list)
            if count > 1 then
                self._activeVarGo:SetActive(true)
                
                ---@type UIFightSkillActiveVar
                self._activeVarPool = self._activeVar:SpawnObject("UIFightSkillActiveVar")
                
                self._activeVarPool:SetData(count,self._index,function(idx)
                    self:ChangeVarIdx(idx)
                end,UIFightSkillActiveVarFromType.Battle)
            end
        end
    end
end
--刷新信息
function UIPetSkillItem:ChangeVarIdx(idx)
    local cfg = BattleSkillCfg(self._skillID)
    if cfg.Type == PetSkillType.SkillType_ChainSkill then
        self._index = idx
        self._skillID = self.skill_id_list[self._index]

        local skills = {}
        local len = table.count(self.skill_id_list)
        for i, v in ipairs(self.skill_id_list) do
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
function UIPetSkillItem:RefreshData()
    if self._sv then
        self._sv.verticalNormalizedPosition = 1
    end

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
        id = self.skill_id_list
    elseif skillType == PetSkillType.SkillType_Passive then
        skillTypeStr = "str_pet_config_skill_equip"
        id = self._skillID
    end
    
    self._txtSkill:SetText(StringTable.Get(skillTypeStr))
    
    self._chainSkillSpawns = nil
    
    if skillType == PetSkillType.SkillType_ChainSkill then
        self._energy:SetActive(false)
        self._chain:SetActive(true)
        self._leader:SetActive(false)
        local skills = {}
        local len = table.count(id)
        self._chainSkill:SpawnObjects("UIPetChainSkillItem", len)
        ---@type UIPetChainSkillItem[]
        self._chainSkillSpawns = self._chainSkill:GetAllSpawnList()
        for i, v in ipairs(id) do
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
            self._chainSkillSpawns[i]:Flush(skill)
        end

        self._index = 1
        if len == 1 then
            self:FlushSkill(skills[1], len)
        else
            self:ImgIconDOFadeCallback(len, skills)
        end
    elseif skillType == PetSkillType.SkillType_Active then
        --增加了附加主动技，这里就不能通过类型去获取id了，不然区分不出来主动技和附加主动技
        --需要外部直接吧id传进来，换一种方式获取技能信息
        self._chain:SetActive(false)
        self._leader:SetActive(false)
        ---@type SkillConfigData
        local skillData = self._skillConfigHelper:GetSkillData(id)
        if skillData then
            self._go:SetActive(true)
            --杰诺 san消耗递增
            local descForceParam = {}
            local extraParam = skillData:GetSkillTriggerExtraParam()
            if extraParam and extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes] then
                local baseCost = extraParam[SkillTriggerTypeExtraParam.SanValue]
                local modCost = extraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes]
                local curTimes = BattleStatHelper.GetCurRoundDoActiveSkillTimes(self._pet:GetPstID())
                local curCost = baseCost + (modCost * curTimes)
                table.insert(descForceParam,tostring(curCost))
            end
            local skill = {
                id = skillData:GetID(),
                name = skillData:GetSkillName(),
                desc = skillData:GetPetSkillDes(descForceParam),
                icon = skillData:GetSkillIcon(),
                chainCount = skillData:GetSkillTriggerParam()
            }
            self:FlushSkill(skill)
            self._energy:SetActive(UILogicPetHelper.ShowSkillEnergy(skillData:GetSkillTriggerType()))

            local skillID = self.skill_id_list[1]
            local cfg = BattleSkillCfg(skillID)
            if cfg then
                if UILogicPetHelper.ShowSkillEnergy(cfg.TriggerType) then
                    self._txtEnergy:SetText(string.format(StringTable.Get("str_common_cooldown_round"), cfg.TriggerParam))
                end
            end    
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
        self._leader:SetActive(false)
        local confV = Cfg.cfg_passive_skill[id]
        if confV then
            self._go:SetActive(true)

            local descStr =
                HelperProxy:GetInstance():GetEquipSkillDesc(
                confV.Desc,
                self._pet:GetTemplateID(),
                self._pet:GetEquipLv(),
                id
            )

            local skill = {
                id = confV.ID,
                name = confV.Name,
                desc = descStr,
                icon = confV.Icon,
                chainCount = 0
            }
            self:FlushSkill(skill)
        else
            self._go:SetActive(false)
        end
    end
end
function UIPetSkillItem:ImgIconDOFadeCallback(len, skills)
    local skill = skills[self._index]
    if skill then
        self:FlushSkill(skill, len)
    end
end

function UIPetSkillItem:FlushSkill(skill, len)
    self._imgIcon:DestoryLastImage()
    self._imgIcon:LoadImage(skill.icon)

    self._txtName:RefreshText(StringTable.Get(skill.name))

    if not self:CheckRefineSkillReplace(skill.id) then
        self._txtDesc:SetText(skill.desc)
    end
    
    local canViewSkillScope = self._module:CanSkillPreview(skill.id)
    if self._btnScope then
        self._btnScope:SetActive(canViewSkillScope or false)
    end
    self._curSkillId = skill.id
    if self._chainSkillSpawns then
        for i, v in ipairs(self._chainSkillSpawns) do
            v:FlushSelect(skill.id, len)
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FlushSkillScope, skill.id)
    
    self:CanViewSkillScope()
end
function UIPetSkillItem:CanViewSkillScope()
    local petModule = GameGlobal.GetModule(PetModule)
    self._canViewSkillScope = petModule:CanSkillPreview(self._skillID)
    self._btnGo:SetActive(self._canViewSkillScope or false)
    if self._canViewSkillScope then
        if not self._atlas then
            self._atlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
        end
        self._state2sprite = {[1] = "spirit_xiangqing_btn4", [2] = "spirit_xiangqing_btn3"}
        self._state2texColor = {[1] = Color(1, 1, 1, 1), [2] = Color(145 / 255, 145 / 255, 145 / 255, 1)}
    end
end
function UIPetSkillItem:imgIconOnClick(go)
    Log.warn("### imgIconOnClick ")
end

function UIPetSkillItem:btnScopeOnClick(go)
    if self._imgScope then
        self._imgScope:SetActive(true)
    end
    local cfg = BattleSkillCfg(self._skillID)
    local skillID
    if cfg.Type ~= PetSkillType.SkillType_ChainSkill then
        skillID = self._skillID
    else
        skillID = self.skill_id_list[self._index]
    end
    self:ShowDialog("UISkillScope", self._skillID, self._pet:GetPstID(), self._btnScope.transform)
end

function UIPetSkillItem:OnUISkillScopeClose()
    if self._imgScope then
        self._imgScope:SetActive(false)
    end

    if self._isOpenShow then
        if self._canViewSkillScope then
            self._showTipBtnImg.sprite = self._atlas:GetSprite(self._state2sprite[2])
            self._btnTex.color = self._state2texColor[1]
        end
        self._isOpenShow = false
    end
end

function UIPetSkillItem:CheckRefineSkillReplace(skillId)
    if not self._pet or not skillId then
        return false
    end
    
    local refineLv = self._pet:GetEquipRefineLv()
    if refineLv < 1 then
        return false
    end
    
    local refineConfig = UIPetEquipHelper.GetRefineCfg(self._pet:GetTemplateID(), refineLv)
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
