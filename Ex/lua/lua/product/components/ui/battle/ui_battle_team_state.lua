---@class UIBattleTeamState : UIController
_class("UIBattleTeamState", UIController)
UIBattleTeamState = UIBattleTeamState

function UIBattleTeamState:OnShow(uiParams)
    ---@type Pet
    local leaderPetData = uiParams[1]

    ---@type UnityEngine.GameObject
    self.teamStateGO = uiParams[2]
    ---队伍血量
    self._curHp = uiParams[3]
    self._maxHp = uiParams[4]
    ---@type UnityEngine.Transform
    self.teamStateOriParent = self.teamStateGO.parent

    ---@type RawImageLoader
    self._imgBG = self:GetUIComponent("RawImageLoader", "imgBG")

    local battle_mes = leaderPetData:GetBattleMes(PetSkinEffectPath.BODY_INGAME_TEAM)
    self._imgBG:LoadImage(battle_mes)

    ---@type UILocalizationText
    --self._txtNameEn = self:GetUIComponent("UILocalizationText", "txtNameEn")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    --local leaderEnglishName = StringTable.Get(leaderPetData:GetPetEnglishName())
    local leaderLocalName = StringTable.Get(leaderPetData:GetPetName())
    --self._txtNameEn:SetText(leaderEnglishName)
    self._txtName:SetText(leaderLocalName)

    ---@type UILocalizationText
    self._hpTxt = self:GetUIComponent("UILocalizationText", "HpValueText")

    self._skillInfo = self:GetGameObject("SkillInfo")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self.imgElement = self:GetUIComponent("Image", "imgElement")
    ---@type UILocalizationText
    self._leaderSkillDescTxt = self:GetUIComponent("UILocalizationText", "SkillDesc")
    self._leaderSkillNameTxt = self:GetUIComponent("UILocalizationText", "SkillName")

    -- local leaderSkillId = leaderPetData:GetPetPassiveSkill()
    self.ElementNameTable = {
        [ElementType.ElementType_Blue] = "str_pet_element_name_blue",
        [ElementType.ElementType_Red] = "str_pet_element_name_red",
        [ElementType.ElementType_Green] = "str_pet_element_name_green",
        [ElementType.ElementType_Yellow] = "str_pet_element_name_yellow"
    }
    local firstElement = leaderPetData:GetPetFirstElement()
    self.imgElement.sprite =
        self.atlasProperty:GetSprite(
        UIPropertyHelper:GetInstance():GetColorBlindSprite(Cfg.cfg_pet_element[firstElement].Icon)
    )
    self._leaderSkillNameTxt:SetText(StringTable.Get(self.ElementNameTable[firstElement]))
    local function GetRestrainAndBe(ele)
        if ele == 1 then
            return ele + 1, 4
        elseif ele == 4 then
            return 1, ele - 1
        else
            return ele + 1, ele - 1
        end
    end
    -- 受到{1}属性伤害降低{2}%，受到{3}属性伤害增加{4}%
    local r, b = GetRestrainAndBe(firstElement)
    self._leaderSkillDescTxt:SetText(
        StringTable.Get(
            "str_battle_state_leader_state",
            StringTable.Get(self.ElementNameTable[r]),
            string.format("%d", BattleConst.Strong * 100),
            StringTable.Get(self.ElementNameTable[b]),
            string.format("%d", BattleConst.Counter * 100)
        )
    )

    ---右上角队伍状态UI
    ---@type UnityEngine.GameObject
    self._rightUpAnchor = self:GetGameObject("RightUpAnchor")
    self.teamStateGO:SetParent(self._rightUpAnchor.transform, false)

    self:RefreshHpTxt()

    self:AttachEvent(GameEventType.TeamHPChange, self.OnTeamHPChange)

    self._teamBuffList = uiParams[5]
    ---@type UICustomWidgetPool
    self._sop = self:GetUIComponent("UISelectObjectPath", "Content")

    self:OnChangeBuff(true, nil)
end

function UIBattleTeamState:OnHide()
    if self.imgElement then
        self.imgElement.sprite = nil
        self.imgElement = nil
    end
    self:DetachEvent(GameEventType.TeamHPChange, self.OnTeamHPChange)
    self.teamStateGO:SetParent(self.teamStateOriParent, false)
end

function UIBattleTeamState:ExitBtnOnClick(go)
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIBattleTeamState", input = "ExitBtnOnClick", args = {}}
    )
    self:CloseDialog()
end

function UIBattleTeamState:OnTeamHPChange(teamHealthBlock)
    if teamHealthBlock.isLocalTeam then
        self._curHp = teamHealthBlock.currentHP
        self._maxHp = teamHealthBlock.maxHP
        self:RefreshHpTxt()
    end
end

function UIBattleTeamState:OnChangeBuff()
    self:StartTask(
        function(TT)
            YIELD(TT) --等一帧等self._teamBuffList更新
            self._teamBuffList = self:OnSortBuffArray(self._teamBuffList)
            local teamBuffCount = #self._teamBuffList
            ---@type UITeamBuffItem[]
            self._sop:SpawnObjects("UITeamBuffItem", teamBuffCount)
            self._buffs = self._sop:GetAllSpawnList()
            for i, v in ipairs(self._buffs) do
                v:GetGameObject():SetActive(false)
                if i <= teamBuffCount then
                    v:GetGameObject():SetActive(true)
                    local buffViewInstance = self._teamBuffList[i]
                    v:SetData(buffViewInstance)
                end
            end
        end,
        self
    )
end

function UIBattleTeamState:RefreshHpTxt()
    local hpPercent = self._curHp / self._maxHp
    if hpPercent <= 0 then
        hpPercent = 0
    elseif hpPercent <= 0.01 then
        hpPercent = 1
    else
        hpPercent = math.floor(hpPercent * 100 + 0.5)
    end

    local strCurHp = "<color=#FF6900>" .. math.modf(self._curHp) .. "</color>"
    local strMaxHp = math.modf(self._maxHp)
    local strHpPercent = "<color=#00A1FF>" .. math.modf(hpPercent) .. "</color>"
    self._hpTxt:SetText(strCurHp .. "/" .. strMaxHp .. " (" .. strHpPercent .. "%)")
end

---排序 BuffViewInstance数组
function UIBattleTeamState:OnSortBuffArray(buffViewArray)
    table.sort(
        buffViewArray,
        function(a, b)
            --id相同
            if a:BuffID() == b:BuffID() then
                return a:BuffSeq() < b:BuffSeq()
            end
            --id 小在前
            return a:BuffID() < b:BuffID()
        end
    )

    return buffViewArray
end
