_class("UIWidgetPetInfo", UICustomWidget)
---@class UIWidgetPetInfo:UICustomWidget
UIWidgetPetInfo = UIWidgetPetInfo

function UIWidgetPetInfo:OnShow()
    ---@type UILocalizationText
    self._attackTxt = self:GetUIComponent("UILocalizationText", "AttackText")
    ---@type UILocalizationText
    self._defenseTxt = self:GetUIComponent("UILocalizationText", "DefenseText")
    ---@type UILocalizationText
    self._hpTxt = self:GetUIComponent("UILocalizationText", "HpText")

    ---@type UILocalizationText
    self._localNameTxt = self:GetUIComponent("UILocalizationText", "LocalName")
    ---@type UILocalizationText
    self._englishNameTxt = self:GetUIComponent("UILocalizationText", "EnglishName")
    ---@type UnityEngine.GameObject
    self._Stars = self:GetGameObject("Stars")
    ---@type table<int, UnityEngine.GameObject>
    self._StarList = {}
    for i = 1, self._Stars.transform.childCount do
        self._StarList[i] = self._Stars.transform:GetChild(i - 1).gameObject
    end

    ---@type UnityEngine.RectTransform
    self._cg = self:GetUIComponent("RectTransform", "cg")
    ---@type RawImageLoader
    self._roleStaticBody = self:GetUIComponent("RawImageLoader", "Role")
    ---@type UISelectObjectPath
    self._skills = self:GetUIComponent("UISelectObjectPath", "grid")

    self._attackStrID = "str_battle_pet_info_attack"
    self._defenseStrID = "str_battle_pet_info_defense"
    self._hpStrID = "str_battle_pet_info_hp"
    self._energyStrID = "str_battle_pet_info_energy"

    self._infoContainerRT = self:GetUIComponent("RectTransform", "InfoContainer")

    ---消灭星星模式隐藏攻防血
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    if matchEnterData:GetMatchType() == MatchType.MT_PopStar then
        ---@type UnityEngine.GameObject
        self._goAttributes = self:GetGameObject("Attributes")
        self._goAttributes:SetActive(false)
    end

    self:AttachEvent(GameEventType.UIShowPetInfo, self.HandleUIShowPetInfo)
    self:AttachEvent(GameEventType.ShowGuideStep, self.ShowGuideStep)
end
function UIWidgetPetInfo:CloseBtnOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,false)
end
function UIWidgetPetInfo:CloseBgOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,false)
end
---@param pet Pet
function UIWidgetPetInfo:Init(pet)
    --宝宝基础数据
    self._attackTxt:SetText(StringTable.Get(self._attackStrID) .. " " .. string.format("%.0f", pet:GetPetAttack()))
    self._defenseTxt:SetText(StringTable.Get(self._defenseStrID) .. " " .. string.format("%.0f", pet:GetPetDefence()))
    self._hpTxt:SetText(StringTable.Get(self._hpStrID) .. " " .. string.format("%.0f", pet:GetPetHealth()))

    self._localNameTxt:SetText(StringTable.Get(pet:GetPetName()))
    self._englishNameTxt:SetText(StringTable.Get(pet:GetPetEnglishName()))
    local starCount = pet:GetPetStar()
    for i = 1, #self._StarList do
        if i <= starCount then
            self._StarList[i]:SetActive(true)
        else
            self._StarList[i]:SetActive(false)
        end
    end

    local petModule = GameGlobal.GetModule(PetModule)
    ---@type UIPetModule
    local uiModule = petModule.uiModule
    local skillDetailInfos = uiModule:GetSkillDetailInfoBySkillTypeHideExtra(pet)
    local spawnSkillCount = table.count(skillDetailInfos)

    self._skills:SpawnObjects("UIPetSkillItem", spawnSkillCount)
    ---@type UIPetSkillItem[]
    self._skillsSpawns = self._skills:GetAllSpawnList()
    if self._skillsSpawns then
        for i = 1, spawnSkillCount do
            local item = self._skillsSpawns[i]
            local skill_info = skillDetailInfos[i]
            local skill_list = skill_info.skillList
            item:Flush(i, pet, skill_list, true)
        end
        -- for i, v in ipairs(self._skillsSpawns) do
        --     local skill_info = skillDetailInfos[i]
        --     local skill_list = skill_info.skillList
        --     local skill_id = skill_list[1]
        --     local skill_cfg = BattleSkillCfg(skill_id)
        --     local skill_type = skill_cfg.Type
        --     v:Flush(i, pet, skill_type, true)
        -- end
    end

    --宝宝技能数据
    local staticBody = pet:GetPetStaticBody(PetSkinEffectPath.BODY_INGAME_PREVIEW)
    UICG.SetTransform(self._cg, self:GetName(), staticBody)

    --全身静态立绘
    self._roleStaticBody:LoadImage(staticBody)

    -- LayoutGroup和ContentSizeFitter的层套得太多了，实测只有这样效果才是对的
    -- Inspector上也给了警告，但这就是设计
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._infoContainerRT)
    GameGlobal.TaskManager():StartTask(self.ForceRebuildInfoContainer, self)
end

function UIWidgetPetInfo:ForceRebuildInfoContainer(TT)
    self._infoContainerRT.gameObject:SetActive(false)
    YIELD(TT)
    self._infoContainerRT.gameObject:SetActive(true)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._infoContainerRT)
end

function UIWidgetPetInfo:OnHide()
    self._infoContainerRT.gameObject:SetActive(false)

    self:Close()
end

function UIWidgetPetInfo:Close()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Button)
end
function UIWidgetPetInfo:ShowGuideStep()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowPetInfo,self.petPstID,false)
end
function UIWidgetPetInfo:HandleUIShowPetInfo(petPstID,isShow)
    if isShow then 

        --引导过程中不打开
        if GuideHelper.IsUIGuideShow() then
            return
        end

        ---@type MatchEnterData
        local enterData = GameGlobal.GetModule(MatchModule):GetMatchEnterData()
        local matchPets = enterData:GetLocalMatchPets()
        local pet = matchPets[petPstID]
        self.petPstID = petPstID
        self:Init(pet)
        self:GetGameObject():SetActive(true)
    else
        self:Close()
        self:GetGameObject():SetActive(false)
    end
end