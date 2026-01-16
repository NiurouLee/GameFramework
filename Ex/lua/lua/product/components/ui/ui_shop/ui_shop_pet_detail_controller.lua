--[[
    @商城星灵预览界面
]]
---@class UIShopPetDetailController:UIController
_class("UIShopPetDetailController", UIController)
UIShopPetDetailController = UIShopPetDetailController
function UIShopPetDetailController:Constructor()
    self._element2Str = {
        [ElementType.ElementType_Blue] = "str_pet_filter_water_element",
        [ElementType.ElementType_Red] = "str_pet_filter_fire_element",
        [ElementType.ElementType_Green] = "str_pet_filter_sen_element",
        [ElementType.ElementType_Yellow] = "str_pet_filter_electricity_element"
    }
    self._prof2Img = {
        [2001] = "spirit_prof_5",
        [2002] = "spirit_prof_1",
        [2003] = "spirit_prof_3",
        [2004] = "spirit_prof_7"
    }
    self._prof2Tex = {
        [2001] = "str_pet_tag_job_name_color_change",
        [2002] = "str_pet_tag_job_name_return_blood",
        [2003] = "str_pet_tag_job_name_attack",
        [2004] = "str_pet_tag_job_name_function"
    }
    self._maxStarLevel = 6
end

function UIShopPetDetailController:OnShow(uiParams)
    self.petId = uiParams[1]
    local param2 = uiParams[2] or 0
    self._showMaxAwake = param2 == 0
    local param3 = uiParams[3] or 0
    self._isActivityShow = param3 == 0
    ---@type UICustomPetData
    self._custonCfg = uiParams[4]
    local param5 = uiParams[5] or 0
    self._showBreadInfo = param5 == 0
    local param6 = uiParams[6] or 0
    self._enableScroll = param6 == 1
    self:_AttachEvents()
    
    local bHideHome = false

    self._btnInfo = self:GetGameObject("BtnInfo")
    self._btnInfo:SetActive(false)
    if self._custonCfg then
        bHideHome = self._custonCfg:GetHideHomeBtn()
        self._btnInfo:SetActive(self._custonCfg:IsShowBtnInfo())
        local btnInfoImageLoader = self:GetUIComponent("RawImageLoader", "BtnInfo")
        btnInfoImageLoader:LoadImage(self._custonCfg:GetBtnInfoName())
        ---@type UnityEngine.RectTransform
        local rect = self:GetUIComponent("RectTransform", "BtnInfo")
        if bHideHome then
            rect.anchoredPosition = Vector2(276.9,-56.07)
        end
    end
    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButton = topButton:SpawnObject("UICommonTopButton")
    self.topButton:SetData(self.OnClickBack,nil,nil,bHideHome,nil)
    local a = self:GetUIComponent("UISelectObjectPath", "cg")
    a:SpawnObjects("UISpineContainer", 1)
    self.spineContainer = a:GetAllSpawnList()[1]
    self.skillsPools = self:GetUIComponent("UISelectObjectPath", "skills")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self._firstElement = self:GetUIComponent("Image", "first")
    ---@type UnityEngine.UI.Image
    self._secondElement = self:GetUIComponent("Image", "second")
    self._secondBg = self:GetGameObject("secondBg")
    self._elementTex = self:GetUIComponent("UILocalizationText", "elementText")
    self._content = self:GetUIComponent("RectTransform", "Content")

    --名字
    self._nameText = self:GetUIComponent("UILocalizationText", "name")
    self._englishNameText = self:GetUIComponent("UILocalizationText", "EnglishName")
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    --攻击防御生命
    self._attackText = self:GetUIComponent("UILocalizationText", "attackText")
    self._defenceText = self:GetUIComponent("UILocalizationText", "defenceText")
    self._healthText = self:GetUIComponent("UILocalizationText", "healthText")
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlasAwake = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)
    self._goGradeMax = self:GetGameObject("gradeMax")
    self._maxGrade = self:GetUIComponent("Image", "maxGrade")
    self._gradeTex = self:GetUIComponent("UILocalizationText", "GradeTex")

    self._scrollViewRect = self:GetUIComponent("RectTransform", "scrollView")

    --传说光灵召集
    self._convene = self:GetGameObject("convene")
    self._conveneRect = self:GetUIComponent("RectTransform", "convene")
    self._btnState = self:GetUIComponent("Button", "btnState")
    self.btnStateObj = self:GetGameObject("btnState")
    self.convening = self:GetGameObject("convening")
    self._txtState = self:GetUIComponent("UILocalizationText", "txtState")
    self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    self._txtTotalPro = self:GetUIComponent("UILocalizationText", "txtTotalPro")
    self._txtCurPro = self:GetUIComponent("UILocalizationText", "txtCurPro")
    self._selectRed = self:GetGameObject("selectRed")
    self.txtInfo = self:GetUIComponent("UILocalizationText", "txtInfo")
    self.infoObj = self:GetGameObject("infoObj")
    self.effShadow = self:GetGameObject("effShadow")
    self.shadow = self:GetUIComponent("RawImageLoader", "shadow")

    self.anim = self:GetUIComponent("Animation", "Anim")
    self.effc = self:GetGameObject("effC")

    self._centerView = self:GetUIComponent("UIView", "rectCenter")
    self.rightAnchor = self:GetGameObject("rightAnchor")
    self.rightAnchorBreak = self:GetGameObject("rightAnchorBreak")
    self.leftDown = self:GetGameObject("leftDown")
    self.promotionDes = self:GetUIComponent("UILocalizedTMP", "promotionDes")
    self.promotionDes.onHrefClick = function(hrefName)
        GameGlobal.UIStateManager():ShowDialog("UISkillHrefInfo", hrefName)
    end
    self.showAllBtn = self:GetGameObject("showAllBtn")
    self.breakInfoBtn = self:GetGameObject("breakInfoBtn")
    self.showAllText = self:GetUIComponent("UILocalizationText", "showAllText")
    self.breakInfoText = self:GetUIComponent("UILocalizationText", "breakInfoText")
    self.tabbtn = self:GetGameObject("tabbtn")
    self.tabbtn:SetActive(self._showBreadInfo)
    self.refineInfoGo = self:GetGameObject("refineInfo")

    self._uiHeartItemAtlas = self:GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    self.levelAreaGo = self:GetGameObject("Level")
    --等级,经验
    self._leveExpSlider = self:GetUIComponent("Slider", "LeveExpSlider")
    self._levelText = self:GetUIComponent("UILocalizationText", "levelValue")
    self._awakeCount2 = self:GetUIComponent("Image", "awakenImgLeft")
    --职业
    self._profTex = self:GetUIComponent("UILocalizationText", "profTex")
    self._profImg = self:GetUIComponent("Image", "profImg")

    self._txtDesc:SetText(StringTable.Get("str_tale_pet_txt_convene_desc"))
    if self._showMaxAwake or self._enableScroll then
        self._scrollViewRect.anchoredPosition = Vector2(self._scrollViewRect.anchoredPosition.x, 0)
    else
        self._scrollViewRect.anchoredPosition = Vector2(self._scrollViewRect.anchoredPosition.x, -23)
    end

    self:RefreshInfo()
    self:RefreshStar()

    --改变背景
    local imageLoader = self:GetUIComponent("RawImageLoader", "BgLoader")
    UICommonHelper:GetInstance():ChangePetTagBackground(self.petId, imageLoader, true)

    if self._showMaxAwake then
        self:InitWorkSkill()
    end

    self:ReBuildScrollView()

    if not self._isActivityShow then
        self:RefreshTalePetPro()
    else
        self._convene:SetActive(false)
        self.infoObj:SetActive(false)
    end
end
function UIShopPetDetailController:ReBuildScrollView()
    local scrollView = self:GetUIComponent("ScrollRect", "scrollView")
    if self._showMaxAwake or self._enableScroll then
        scrollView.enabled = true
    else
        scrollView.enabled = false
    end
end

function UIShopPetDetailController:RefreshInfo()
    if self._custonCfg then
        local tempData = pet_data:New()
        tempData.template_id = self.petId
        tempData.current_skin = 0-- current_skin不在pet_data中 用于非本地星灵
        local pet = Pet:New(tempData)
        -- 不要改变顺序
        tempData.grade = self._custonCfg:GetGrade()
        tempData.level = pet:GetMaxLevel()
        if self._custonCfg:GetCustomLevel() then
            tempData.level = self._custonCfg:GetCustomLevel()
        end
        tempData.awakening = self._custonCfg:GetAwakening() --觉醒
        tempData.equip_lv = self._custonCfg:GetEquip()
        tempData.affinity_level = pet:GetPetAffinityMaxLevel()
        if self._custonCfg:GetAffinityLevel() then
            tempData.affinity_level = self._custonCfg:GetAffinityLevel()
        end
        tempData.equip_refine_lv = pet:GetEquipRefineMaxLv()
        if self._custonCfg:GetEquipRefineLevel() then
            tempData.equip_refine_lv = self._custonCfg:GetEquipRefineLevel()
        end

        pet:SetData(tempData)
        --pet:CalAttr()
        -- pet.affinity_level = 0 --亲密度等级
        -- pet.affinity_exp = 0 --亲密度经验
        -- pet.mood = 0 --心情值
        ---@type MatchPet
        self.pet = pet
        self._goGradeMax:SetActive(true)
        local awakeSpriteName = UIPetModule.GetAwakeSpriteName(self.petId, self._custonCfg:GetGrade())
        if not string.isnullorempty(awakeSpriteName) then
            self._maxGrade.sprite = self._atlasAwake:GetSprite(awakeSpriteName)
        end
        local titleStr = self._custonCfg:GetDetailTitleText()
        if titleStr then
            self._gradeTex:SetText(StringTable.Get(titleStr))
        end
        local showLevelArea = self._custonCfg:GetShowLevelArea()
        if showLevelArea then
            self.levelAreaGo:SetActive(true)
            self:RefreshLevelInfo()
        end
    else
        if self._showMaxAwake then
            local tempData = pet_data:New()
            tempData.template_id = self.petId
            tempData.current_skin = 0-- current_skin不在pet_data中 用于非本地星灵
            local pet = Pet:New(tempData)
            -- 不要改变顺序
            local maxGrade = pet:GetMaxGrade()
            tempData.grade = maxGrade
            tempData.level = pet:GetMaxLevel()
            tempData.awakening = pet:GetMaxAwakening() --觉醒
            tempData.equip_lv = ResourceHelper:GetInstance():GetPetEquip():GetMaxLv(pet:GetTemplateID())
            tempData.affinity_level = pet:GetPetAffinityMaxLevel()
            tempData.equip_refine_lv = pet:GetEquipRefineMaxLv()

            pet:SetData(tempData)
            --pet:CalAttr()
            -- pet.affinity_level = 0 --亲密度等级
            -- pet.affinity_exp = 0 --亲密度经验
            -- pet.mood = 0 --心情值
            ---@type MatchPet
            self.pet = pet
            self._goGradeMax:SetActive(true)
            local awakeSpriteName = UIPetModule.GetAwakeSpriteName(self.petId, maxGrade)
            if not string.isnullorempty(awakeSpriteName) then
                self._maxGrade.sprite = self._atlasAwake:GetSprite(awakeSpriteName)
            end
        else
            local petModule = self:GetModule(PetModule)
            self.pet = petModule:GetPetByTemplateId(self.petId)
            self._goGradeMax:SetActive(false)
        end
    end

    -- local str = StringTable.Get("str_shop_grade_max_title")
    -- local gradeMaxValue = self.pet:GetMaxGrade()
    -- --str = string.gsub(str, "x", tostring(gradeMaxValue), 1)
    -- self._gradeTex:SetText(str)

    if self.pet then
        self.spineContainer:SetData(self.pet)
        -- local staticBody = pet:GetPetStaticBody()
        -- self._img:LoadImage(staticBody)
        -- UICG.SetTransform(self._img.transform, self:GetName(), staticBody)

        local petModule = GameGlobal.GetModule(PetModule)
        ---@type UIPetModule
        local uiModule = petModule.uiModule
        local skillDetailInfos = uiModule:GetSkillDetailInfoBySkillTypeHideExtra(self.pet)
        local skillCount = table.count(skillDetailInfos)
    
        self.skillsPools:SpawnObjects("UIShopPetSkillItem", skillCount)
        ---@type UIShopPetSkillItem[]
        self._skillsSpawns = self.skillsPools:GetAllSpawnList()

        if self._skillsSpawns then
            for i = 1, skillCount do
                local item = self._skillsSpawns[i]
                local skill_info = skillDetailInfos[i]
                local skill_list = skill_info.skillList
                item:Flush(i, self.pet, skill_list)
            end
            -- for i, v in ipairs(self._skillsSpawns) do
            --     local skill_info = self._skillDetailInfos[i]
            --     local skill_list = skill_info.skillList
            --     local skill_id = skill_list[1]
            --     local skill_cfg = BattleSkillCfg(skill_id)
            --     local skill_type = skill_cfg.Type
            --     local have = v:Flush(i, self.pet, skill_type)
            -- end
            self.skillItemTask = self:StartTask(self.SkillItemAni, self)
        end
    end

    local itemIcon = self.pet:GetPetItemIcon(PetSkinEffectPath.NO_EFFECT)
    self.uiItem:SetData({icon = itemIcon, itemId = self.pet:GetTemplateID()})
    self:ShowElement()
    self:ShowName()
    self:RefreshAtt()
    self:RefreshBreakInfo()
    self:CheckAndShowRefineInfo()
end

function UIShopPetDetailController:CheckAndShowRefineInfo()
    if not self.pet   then
        self.refineInfoGo:SetActive(false)
        return
    end
    local templateId = self.pet:GetTemplateID()
    if not UIPetEquipHelper.HasRefine(templateId) then
        self.refineInfoGo:SetActive(false)
        return
    end

    self.refineInfoGo:SetActive(true)
    if not self.refineIcon then
        local refineItemPool = self:GetUIComponent("UISelectObjectPath", "refineItem")
        self.refineIcon = refineItemPool:SpawnObject("UIPetEquipLvIcon")
    end
    self.refineIcon:SetData(self.pet)
end

------------------------------------------------------------主元素和副元素
function UIShopPetDetailController:ShowElement()
    local cfg_pet_element = Cfg.cfg_pet_element {}

    local elementTex = ""

    if cfg_pet_element then
        local f = self.pet:GetPetFirstElement()
        local s = self.pet:GetPetSecondElement()
        self._firstElement.sprite =
            self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[f].Icon))
        if s and s > 0 then
            self._secondBg:SetActive(true)
            self._secondElement.gameObject:SetActive(true)
            self._secondElement.sprite =
                self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[s].Icon)
            )
            elementTex =
                StringTable.Get("str_pet_detail_element_" .. f) ..
                "  " .. StringTable.Get("str_pet_detail_element_" .. s)
        else
            elementTex = StringTable.Get(self._element2Str[f])
            self._secondElement.gameObject:SetActive(false)
            self._secondBg:SetActive(false)
        end
    end
    self._elementTex:SetText(elementTex)
end
--------------------------------------------------------------攻击防御生命
function UIShopPetDetailController:RefreshAtt()
    local _attackValue = 0
    local _defenceValue = 0
    local _healthValue = 0
    if self._custonCfg then
        _attackValue = self._custonCfg:GetAttacke()
        _defenceValue = self._custonCfg:GetDef()
        _healthValue = self._custonCfg:GetHP()
    else
        _attackValue = self.pet:GetPetAttack()
        _defenceValue = self.pet:GetPetDefence()
        _healthValue = self.pet:GetPetHealth()
    end

    -- -- --MSG15661	【需测试】招募和商城内光灵详情页面攻防血数值调整		小开发任务-待开发	靳策, 1951	12/31/2020
    -- local _attackValue = self.pet:NoBreak_Attack()
    -- local _defenceValue = self.pet:NoBreak_Defence()
    -- local _healthValue = self.pet:NoBreak_Health()

    self._attackText:SetText(_attackValue)
    self._defenceText:SetText(_defenceValue)
    self._healthText:SetText(_healthValue)
end
----------------------------------------------获得英文长度来判断是否缩放text
function UIShopPetDetailController:CheckStringLen(nameEn)
    self._englishNameText:SetText(nameEn)
    local scale = GameObjectHelper.GetTextScale(self._englishNameText, nameEn, 437)
    self._englishNameText:GetComponent("Transform").localScale = Vector3(scale, 1, 1)
end
----------------------------------------------------------------------名字
function UIShopPetDetailController:ShowName()
    local name = self.pet:GetPetName()
    self._nameText:SetText(StringTable.Get(name))
    local nameEn = StringTable.Get(self.pet:GetPetEnglishName())
    self:CheckStringLen(nameEn)
end

function UIShopPetDetailController:RefreshStar()
    local petStar = self.pet:GetPetStar()
    -- local awakenStep = self.pet:GetPetAwakening()
    for starLevel = 1, self._maxStarLevel do
        local _itemIcon = self:GetUIComponent("Image", "star" .. starLevel)
        local starGo = self:GetGameObject("star" .. starLevel)
        if starLevel <= petStar then
            starGo:SetActive(true)
        else
            starGo:SetActive(false)
        end
    end
end
function UIShopPetDetailController:InitWorkSkill()
    self._skillState = {}
    self._grade = self.pet:GetPetGrade()
    local tab = self.pet:PetGradeNewSkill()
    for i = 1, table.count(tab) do
        self._skillState[i] = {}
        self._skillState[i].ID = tab[i].NewSkill
        self._skillState[i].grade = tab[i].Grade
        -- if tab[i].Grade > self._grade then
        --     self._skillState[i].isLock = true
        -- else
        self._skillState[i].isLock = false
        -- end
    end
    self._workSkillPool = self:GetUIComponent("UISelectObjectPath", "workskills")

    local _skillState = self._skillState
    local skillCount = table.count(_skillState)
    ---@type UISelectObjectPath
    self._workSkillPool:SpawnObjects("UIShopPetWorkSkill", skillCount)
    local pools = self._workSkillPool:GetAllSpawnList()
    for i = 1, skillCount do
        local cfg_work_skill = Cfg.cfg_work_skill[_skillState[i].ID]
        pools[i]:SetData(i, _skillState[i], cfg_work_skill and cfg_work_skill.RoomType or 1)
    end
end
function UIShopPetDetailController:OnHide()
    self:_DetachEvents()
    if self.skillItemTask then
        GameGlobal.TaskManager():KillTask(self.skillItemTask)
        self.skillItemTask = nil
    end
    if self.SelectPetEffTask then
        GameGlobal.TaskManager():KillTask(self.SelectPetEffTask)
        self.SelectPetEffTask = nil
    end
    if self.breakInfoLua then
        self.breakInfoLua:Dispose()
    end
end

function UIShopPetDetailController.OnClickBack()
    GameGlobal.UIStateManager():CloseDialog("UIShopPetDetailController")
    GameGlobal.EventDispatcher():Dispatch(GameEventType.TalePetDetailReturnList)
end

---------------------------------------------------------传说光灵-----------------------------------------------------
---------------------------------------------------刷新召集进度
function UIShopPetDetailController:RefreshTalePetPro()
    --self:RectChange()

    self.talePetModule = GameGlobal.GetModule(TalePetModule)
    local info = self.talePetModule:GetPetInfo(self.petId)
    self:RectChange()
    self:RefreshByInfo(info)
    self:SelectRedController()
    local cfg = Cfg.cfg_pet {ID = self.petId}[1]
    self.infoObj:SetActive(true)
    self.txtInfo:SetText(StringTable.Get(cfg.Desc))
    local cg = HelperProxy:GetInstance():GetPetStaticBody(self.petId,0,0,PetSkinEffectPath.NO_EFFECT)
    self.shadow:LoadImage(cg)
end

function UIShopPetDetailController:RectChange()
    local height = self._conveneRect.sizeDelta.y
    self._scrollViewRect.sizeDelta =
        Vector2(self._scrollViewRect.sizeDelta.x, self._scrollViewRect.sizeDelta.y - height)
    self._scrollViewRect.anchoredPosition =
        Vector2(self._scrollViewRect.anchoredPosition.x, self._scrollViewRect.anchoredPosition.y + (height / 2))
    self._convene:SetActive(true)
end

function UIShopPetDetailController:RefreshByInfo(info)
    self.btnStateObj:SetActive(true)
    self.convening:SetActive(false)
    if info == nil then
        self._txtState:SetText(StringTable.Get("str_tale_pet__btn_select"))
        self._btnState.interactable = true
        self._txtCurPro:SetText(0)
        local totalPro = self.talePetModule:GetTaskPhase(self.petId)
        self._txtTotalPro:SetText(totalPro)
        self._txtDesc:SetText(
            StringTable.Get("str_tale_pet_txt_convene_desc") .. "<color=#ffffff>" .. "0/" .. totalPro .. "</color>"
        )
        return
    end
    local state = info.pet_status
    local id = self.talePetModule:SelectPetCfgId()
    if state == TalePetCallType.TPCT_Doing then
        --召集中
        self._txtState:SetText(StringTable.Get("str_tale_pet_btn_convening"))
        self._btnState.interactable = false
        self.btnStateObj:SetActive(false)
        self.convening:SetActive(true)
    elseif state == TalePetCallType.TPCT_Done then
        self._txtState:SetText(StringTable.Get("str_tale_pet_btn_view"))
        self._btnState.interactable = true
    else
        --已获取、可获取、无状态、暂停中等可选择状态
        self._txtState:SetText(StringTable.Get("str_tale_pet__btn_select"))
        self._btnState.interactable = true
    end
    self._txtCurPro:SetText(info.task_phase)
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    self._txtDesc:SetText(
        StringTable.Get("str_tale_pet_txt_convene_desc") ..
            "<color=#ffffff>" .. info.task_phase .. "/" .. totalPro .. "</color>"
    )
    self._txtTotalPro:SetText(totalPro)
    if state == TalePetCallType.TPCT_Can_Do or state == TalePetCallType.TPCT_Done then
        self._txtCurPro:SetText(totalPro)
        self._txtTotalPro:SetText(totalPro)
        self._txtDesc:SetText(
            StringTable.Get("str_tale_pet_txt_convene_desc") ..
                "<color=#ffffff>" .. totalPro .. "/" .. totalPro .. "</color>"
        )
    end
end

---------------------------------------------------选择/切换光灵
function UIShopPetDetailController:btnStateOnClick()
    local info = self.talePetModule:GetPetInfo(self.petId)
    local state = self.talePetModule:SelectPetCfgId()

    -- if info ~= nil then
    --     if info.pet_status == TalePetCallType.TPCT_Can_Do or info.pet_status == TalePetCallType.TPCT_Done then
    --         self:ShowSwitchTips(state, function()
    --             if self.petId ~= self.talePetModule:SelectPetCfgId() then
    --                 GameGlobal.TaskManager():StartTask(self.SwitchPetCall, self)
    --             end
    --             self.anim:Play("uieff_UIShopPetDetailController_conversion")
    --             self.effc:SetActive(true)
    --             self.effShadow:SetActive(true)
    --             self.SelectPetEffTask = self:StartTask(self.SelectPetEff, self)
    --         end)
    --         return
    --     end
    -- end
    
    if state == 0 then
        --没有正在召集的光灵
        self.anim:Play("uieff_UIShopPetDetailController_conversion")
        self.effc:SetActive(true)
        self.effShadow:SetActive(true)
        GameGlobal.TaskManager():StartTask(self.SwitchPetCall, self)
    else
        --拥有正在召集的光灵
        --self:ShowDialog("UISwitchPetPro", self.petId)
        if self.petId == state then
            --self:ShowDialog("UITalePetMissionController", self.petId)
            ToastManager.ShowToast(StringTable.Get("str_tale_pet_is_convene"))
            return
        else
            local lastInfo = self.talePetModule:GetPetInfo(state)
            local isSwi = false
            for key, value in pairs(lastInfo.datas) do
                if value.cur ~= 0 then
                    isSwi = true
                end
            end

            if isSwi then
                self:ShowSwitchTips(state, function()
                    self.anim:Play("uieff_UIShopPetDetailController_conversion")
                    self.effc:SetActive(true)
                    self.effShadow:SetActive(true)
                    GameGlobal.TaskManager():StartTask(self.SwitchPetCall, self)
                end)
            else
                self.anim:Play("uieff_UIShopPetDetailController_conversion")
                self.effc:SetActive(true)
                self.effShadow:SetActive(true)
                GameGlobal.TaskManager():StartTask(self.SwitchPetCall, self)
            end
        end
    end
end

function UIShopPetDetailController:ShowSwitchTips(state, callback)
    local curCfg = Cfg.cfg_pet[state]
    local curName = curCfg.Name
    local curTask = self.talePetModule:GetPetInfo(state).task_phase + 1
    local str =
        (StringTable.Get(
        "str_tale_pet_txt_switch_pet_tips",
        StringTable.Get(curName),
        curTask,
        StringTable.Get(curName),
        curTask
    ))
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        str,
        function()
            if callback then
                callback()
            end
        end,
        nil,
        function()
            --取消
        end,
        nil
    )
end

function UIShopPetDetailController:SelectPetEff(TT)
    local delayTime = (20 / 30) * 1000
    YIELD(TT, delayTime)
    self:SwitchState(UIStateType.UITalePetCollect, self.petId)
    -- self:ShowDialog("UITalePetMissionController", self.petId)
end

function UIShopPetDetailController:SwitchPetCall(TT)
    self:Lock("UIShopPetDetailController:SwitchPetCall")
    ---@type AsyncRequestRes
    local res = self.talePetModule:ReqTaleChoose(TT, self.petId)
    if res:GetSucc() then
        local name = Cfg.cfg_pet[self.petId].Name
        ToastManager.ShowToast(StringTable.Get("str_tale_pet_txt_start_convene_pet", StringTable.Get(name)))
        self.SelectPetEffTask = self:StartTask(self.SelectPetEff, self)
    else
        ToastManager.ShowToast(res.m_result)
    end
    self:UnLock("UIShopPetDetailController:SwitchPetCall")
end

function UIShopPetDetailController:_AttachEvents()
    self:AttachEvent(GameEventType.TalePetInfoDataChange, self._SelectTalePetCall)
    self:AttachEvent(GameEventType.OnAwakenSelectPointChange, self.OnAwakenSelectPointChange)
end

function UIShopPetDetailController:_DetachEvents()
    self:DetachEvent(GameEventType.TalePetInfoDataChange)
    self:DetachEvent(GameEventType.OnAwakenSelectPointChange)
end

function UIShopPetDetailController:_SelectTalePetCall()
    local info = self.talePetModule:GetPetInfo()
    self:RefreshByInfo(info)
end

---------------------------------------------------介绍说明
function UIShopPetDetailController:btnHelperOnClick()
    --self:ShowDialog("UIConveneDesc")
    self:ShowDialog("UIHelpController", "UIShopPetDetailController")
end

function UIShopPetDetailController:SelectRedController()
    --光灵可领取但未领取时显示
    if self.ID == self.talePetModule:SelectPetCfgId() then
        return
    end
    local state1 = self.talePetModule:IsCanCallPet(self.petId)
    local state2 = self.talePetModule:IsGetReward(self.petId)
    if state1 or state2 then
        self._selectRed:SetActive(true)
    else
        self._selectRed:SetActive(false)
    end
end

function UIShopPetDetailController:SkillItemAni(TT)
    if self._skillsSpawns then
        for index, value in ipairs(self._skillsSpawns) do
            value:ShowInAnim()
            YIELD(TT)
            YIELD(TT)
        end
    end
end

-----------------------------------------------------------------------------end----------------------------------------

-----------------------------------------------------------------------------光灵突破------------------------------------

function UIShopPetDetailController:RefreshBreakInfo()
    self.attributeCfg = self.pet:GetAwakeningConfig()
    self.levelCfg = self.pet:GetCurrentLevelConfig()
    self.promoteDes = {} --提升描述
    for i = 1, #self.attributeCfg do
        local des = self:GetBreakData(i)
        self.promoteDes[i] = des
    end
    self.breakInfoLua = UIBreakInfoItem:New()
    self.breakInfoLua:SetView(self._centerView)
    self.breakInfoLua:SetShowBreifDes()
    self.breakInfoLua:OnShowItem()
    self.breakInfoLua:SetData(0, self.pet)
end

function UIShopPetDetailController:GetBreakData(idx)
    local select = self.attributeCfg[idx]
    local attack, attackValue, attackPercent = self:_GetPromoteAttack(idx)
    local defence, defenceValue, defencePercent = self:_GetPromoteDefence(idx)
    local hp, hpValue, hpPercent = self:_GetPromoteHP(idx)
    --任意属性改变，则不再判断技能
    if attack > 0 or defence > 0 or hp > 0 then
        return self:_GetPromoteDes(idx)
    end
    return StringTable.Get(select.PromoteDes)
end

function UIShopPetDetailController:_GetPromoteDes(idx)
    local attack, attackValue, attackPercent = self:_GetPromoteAttack(idx)
    local defence, defenceValue, defencePercent = self:_GetPromoteDefence(idx)
    local hp, hpValue, hpPercent = self:_GetPromoteHP(idx)

    local temp = {
        {
            value = attackValue,
            percent = attackPercent,
            name = StringTable.Get("str_pet_config_break_att_attack"),
            suffix = StringTable.Get("str_pet_config_break_att_base_attack")
        },
        {
            value = defenceValue,
            percent = defencePercent,
            name = StringTable.Get("str_pet_config_break_att_defense"),
            suffix = StringTable.Get("str_pet_config_break_att_base_defence")
        },
        {
            value = hpValue,
            percent = hpPercent,
            name = StringTable.Get("str_pet_config_break_att_hp"),
            suffix = StringTable.Get("str_pet_config_break_att_base_hp")
        }
    }
    local des = ""
    for _, attribute in ipairs(temp) do
        local text = ""
        local valid = false
        if attribute.value > 0 then
            if attribute.percent > 0 then
                text =
                    StringTable.Get("str_pet_config_break_att_promote_both", attribute.value, attribute.percent, attribute.suffix)
            else
                text = StringTable.Get("str_pet_config_break_att_promote_value", attribute.name, attribute.value)
            end
            valid = true
        else
            if attribute.percent > 0 then
                text = StringTable.Get("str_pet_config_break_att_promote_percent", attribute.percent, attribute.suffix)
                valid = true
            end
        end
        if valid then
            des = des .. text .. "\n"
        end
    end
    return des
end

function UIShopPetDetailController:_GetPromoteAttack(level)
    --总、绝对值、基础攻击力百分比
    local total, value, percent = 0
    local cfg = self.attributeCfg[level]
    if level > 1 then
        value = cfg.Attack - self.attributeCfg[level - 1].Attack
        percent = cfg.AttackPercent - self.attributeCfg[level - 1].AttackPercent
    else
        value = cfg.Attack
        percent = cfg.AttackPercent
    end
    value = math.floor(value)
    local percentValue = 0
    if percent > 0 then
        percentValue = math.floor(self.levelCfg.Attack * percent / 100)
    end
    total = value + percentValue
    return total, value, percent
end

function UIShopPetDetailController:_GetPromoteDefence(level)
    --总、绝对值、基础攻击力百分比
    local total, value, percent = 0
    local cfg = self.attributeCfg[level]
    if level > 1 then
        value = cfg.Defence - self.attributeCfg[level - 1].Defence
        percent = cfg.DefencePercent - self.attributeCfg[level - 1].DefencePercent
    else
        value = cfg.Defence
        percent = cfg.DefencePercent
    end
    value = math.floor(value)
    local percentValue = 0
    if percent > 0 then
        percentValue = math.floor(self.levelCfg.Defence * percent / 100)
    end
    total = value + percentValue
    return total, value, percent
end

function UIShopPetDetailController:_GetPromoteHP(level)
    --总、绝对值、基础攻击力百分比
    local total, value, percent = 0
    local cfg = self.attributeCfg[level]
    if level > 1 then
        value = cfg.Health - self.attributeCfg[level - 1].Health
        percent = cfg.HealthPercent - self.attributeCfg[level - 1].HealthPercent
    else
        value = cfg.Health
        percent = cfg.HealthPercent
    end
    value = math.floor(value)
    local percentValue = 0
    if percent > 0 then
        percentValue = math.floor(self.levelCfg.Health * percent / 100)
    end
    total = value + percentValue
    return total, value, percent
end

function UIShopPetDetailController:ShowAllBtnOnClick()
    UIWidgetHelper.PlayAnimation(self, "Anim", "uieff_UIShopPetDetailController_switch_02", 533)
    -- self.rightAnchor:SetActive(true)
    -- self.leftDown:SetActive(true)
    -- self.rightAnchorBreak:SetActive(false)

    self.showAllBtn:SetActive(false)
    self.breakInfoBtn:SetActive(true)
    self.showAllText.color = Color(0, 0, 0, 1)
    self.breakInfoText.color = Color(132 / 255, 132 / 255, 132 / 255, 1)
end

function UIShopPetDetailController:OnAwakenSelectPointChange(idx, selectIdx)
    self.promotionDes:SetText(self.promoteDes[selectIdx])
end


function UIShopPetDetailController:BreakInfoBtnOnClick()
    UIWidgetHelper.PlayAnimation(self, "Anim", "uieff_UIShopPetDetailController_switch_01", 533)
    -- self.rightAnchor:SetActive(false)
    -- self.leftDown:SetActive(false)
    -- self.rightAnchorBreak:SetActive(true)

    self.showAllBtn:SetActive(true)
    self.breakInfoBtn:SetActive(false)
    self.showAllText.color = Color(132 / 255, 132 / 255, 132 / 255, 1)
    self.breakInfoText.color = Color(0, 0, 0, 1)
end

-----------------------------------------------------------------------------end----------------------------------------
function UIShopPetDetailController:BtnInfoOnClick()
    if self._custonCfg then
        local callback = self._custonCfg:GetBtnInfoCallback()
        if callback then
            callback()
        end
    end
end
function UIShopPetDetailController:RefreshLevelInfo()
    local curGrateMaxLevel = self.pet:GetMaxLevel()
    local curLevel = self.pet:GetPetLevel()

    self._levelText:SetText(
        curLevel .. "<size=45><color=#acacac>/</color><color=#f96601>" .. curGrateMaxLevel .. "</color></size>"
    )

    --self._infoTexContent.anchoredPosition = Vector2(self._infoTexContent.anchoredPosition.x, 0)

    -- local cfg_pet = Cfg.cfg_pet[self._petInfos[self._currIndex]:GetTemplateID()]
    -- if cfg_pet then
    --     self._infoTex:SetText(StringTable.Get(cfg_pet.Desc))
    -- else
    --     Log.fatal("###pet_detail -- cfg_pet is nil ! id -- " .. self._petInfos[self._currIndex]:GetTemplateID())
    -- end

    --local itemIcon = self._petInfos[self._currIndex]:GetPetItemIcon(PetSkinEffectPath.ITEM_ICON_PET_DETAIL)
    --self.uiItem:SetData({icon = itemIcon, itemId = self._petInfos[self._currIndex]:GetTemplateID()})

    self._leveExpSlider.value = 0
    local prof = self.pet:GetProf()
    self._profTex:SetText(StringTable.Get(self._prof2Tex[prof]))
    self._profImg.sprite = self._uiHeartItemAtlas:GetSprite(self._prof2Img[prof])
    ---@type UIPetEquipLvIcon
    local obj = UIWidgetHelper.SpawnObject(self, "_equipLv", "UIPetEquipLvIcon")
    obj:SetData(self.pet, true)
    --local btnIcon = UIWidgetHelper.SpawnObject(self, "_equipLvBtnIcon", "UIPetEquipLvIcon")
    --btnIcon:SetData(self._petInfos[self._currIndex], false)

    local petId = self.pet:GetTemplateID()
    local awaken = self.pet:GetPetGrade()
    local spriteName = UIPetModule.GetAwakeSpriteName(petId, awaken)
    self._awakeCount2.sprite = self._atlasAwake:GetSprite(spriteName)
end
---@param customPetData UICustomPetData
function UIShopPetDetailController.ShowCustomPetDetail(customPetData)
    GameGlobal.UIStateManager():ShowDialog("UIShopPetDetailController", customPetData:GetPetId(), 1, 0, customPetData)
end
