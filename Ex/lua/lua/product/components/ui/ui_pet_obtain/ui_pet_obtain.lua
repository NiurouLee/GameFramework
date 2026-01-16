---@class UIPetObtain:UIController
_class("UIPetObtain", UIController)
UIPetObtain = UIPetObtain

function UIPetObtain:OnShow(uiParams)
    --使用新的抽卡表现
    self._useNewEft = true
    ---@type PetModule
    self._petModule = self:GetModule(PetModule)

    ---@type RoleAsset[]
    local pets = uiParams[1]
    if not pets then
        self:Close()
        return
    end
    self._isSkin = uiParams[4] or false

    local gotTimes = {}
    for idx, pet in ipairs(pets) do
        local id = pets[idx].assetid
        if gotTimes[id] then
            gotTimes[id] = gotTimes[id] + 1
        else
            gotTimes[id] = 1
        end
    end
    ---@type table<number,ObtainPet>
    self._dropPets = {}
    for idx, pet in ipairs(pets) do
        local id = pet.assetid
        local petId = 0
        local skinId = 0
        local isNew = true
        if self._isSkin then
            skinId = id
            local curSkinCfg = Cfg.cfg_pet_skin[skinId]
            if curSkinCfg then
                petId = curSkinCfg.PetId
                local skinData = self._petModule:GetPetSkinsData(petId)
                if skinData and skinData.skin_info then
                    for index, value in ipairs(skinData.skin_info) do
                        if value.skin_id == skinId then
                            isNew = false
                        end
                    end
                end
            end
        else
            petId = id
            isNew = not self._petModule:BeInSnapshoot(id)
        end
        --BeInSnapshoot接口只能调用一次
        self._dropPets[idx] = ObtainPet:New(petId, isNew, skinId, gotTimes[petId])
        gotTimes[petId] = gotTimes[petId] - 1
    end

    -- self._dropPets[1] = ObtainPet:New(1600061, false)
    --测试代码，修改抽卡结果
    -- if #self._dropPets > 0 then
    --     self._dropPets[1] = ObtainPet:New(1400951, false)
    --     self._dropPets[2] = ObtainPet:New(1400671, false)
    --     self._dropPets[3] = ObtainPet:New(1400071, false)
    --     self._dropPets[4] = ObtainPet:New(1300941, false)
    --     self._dropPets[5] = ObtainPet:New(1400681, false)
    --     self._dropPets[6] = ObtainPet:New(1400831, false)
    --     self._dropPets[7] = ObtainPet:New(1300741, false)
    --     self._dropPets[8] = ObtainPet:New(1500871, false)
    --     self._dropPets[9] = ObtainPet:New(1500131, false)
    --     self._dropPets[10] = ObtainPet:New(1600061, true)
    -- end

    self._callback = uiParams[2] --关闭回调
    local skipAnim = uiParams[3] --是否跳过动画直接展示，单张卡牌的时候才有效
    ------------------------------------------------------

    self._atlas = self:GetAsset("UIPetObtain.spriteatlas", LoadType.SpriteAtlas)
    self._element2Img = {
        [1] = "obtain_donghua_bing",
        [2] = "obtain_donghua_huo",
        [3] = "obtain_donghua_sen",
        [4] = "obtain_donghua_lei"
    }

    self._animName = "uieff_uipetobtain_eff"

    --UI
    self._cgRoot = self:GetGameObject("cgRoot")
    ---@type RawImageLoader
    self._cg_mid = self:GetUIComponent("RawImageLoader", "cgMid")

    self._cgRect = self:GetUIComponent("RectTransform", "cgNormal")
    ---@type MultiplyImageLoader
    self._cgNormal = self:GetUIComponent("MultiplyImageLoader", "cgNormal")
    ---@type SpineLoader
    self._spine = self:GetUIComponent("SpineLoader", "spine")

    ---@type UnityEngine.UI.RawImage
    self._img = self:GetUIComponent("RawImage", "cgNormal")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self._imgElement = self:GetUIComponent("Image", "imgElement")
    ---@type UILocalizationText
    self._txtNameEn = self:GetUIComponent("UILocalizationText", "txtNameEn")
    self._txtNameEn2 = self:GetUIComponent("UILocalizationText", "txtNameEn2")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UISelectObjectPath
    self._sop = self:GetUIComponent("UISelectObjectPath", "stars")
    self._uiStars = self:GetUIComponent("Transform", "stars")
    ---@type UILocalizationText
    self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    ---@type UnityEngine.Animation
    self._anim = self:GetGameObject():GetComponent("Animation")

    self._bgEffRoot = self:GetUIComponent("Transform", "Center")

    self._nickName = self:GetUIComponent("UILocalizationText", "nickName")
    self._nickName2 = self:GetUIComponent("UILocalizationText", "nickName2")
    self._tagTex = self:GetUIComponent("UILocalizationText", "tagTex")
    self.matTip = self:GetUIComponent("UISelectObjectPath", "matTip")

    self._smallLogo = self:GetUIComponent("RawImageLoader", "smallLogo")
    self._logo = self:GetUIComponent("RawImageLoader", "logo")

    self._elementBg = self:GetUIComponent("Image", "elementBg")
    self._elementAreaGo = self:GetGameObject("elementBg")

    self._matBgRect = self:GetUIComponent("RectTransform", "matBgImage")
    self._btnSkip = self:GetGameObject("btnSkip")

    self._endBtn = self:GetGameObject("btnEnd")

    self._simpleEff = self:GetGameObject("Eff")

    self._bgCanvas = self:GetGameObject("BGCanvas")
    self._left = self:GetGameObject("Left")
    self._leftUp = self:GetGameObject("LeftUp")
    self._down = self:GetGameObject("Down")
    self._rightDown = self:GetGameObject("RightDown")
    self._rightDownCanvas = self:GetUIComponent("CanvasGroup", "RightDown")
    self._downCanvas = self:GetUIComponent("CanvasGroup", "Down")

    self._matAnim = self:GetGameObject("matBg")
    --前动画
    self._effLogo = self:GetUIComponent("RawImageLoader", "effLogo")
    self._effStars = self:GetUIComponent("Transform", "effStars")
    self._effStars.gameObject:SetActive(false)

    self._curIdx = 1
    self._skipped = false

    self:InitData()

    --随机动画音效
    -- AudioHelperController.RequestUISoundSync(CriAudioIDConst.DrawCard_suiji)
    -- for key, value in pairs(CriAudioIDConst.DrawStarCardArr) do
    --     AudioHelperController.RequestUISoundSync(value)
    -- end

    ---@type PetAudioModule
    self._petAudioModule = self:GetModule(PetAudioModule)

    -- self._tlPlayer = EZTL_Player:New()

    ---@type PetObtainAnimBase
    self._curAnim = nil

    self._spine.gameObject:SetActive(false)
    self._cgRoot:SetActive(true)
    ---@type table<number,PetObtainAnimBase>
    self._anims = {}
    if #self._dropPets == 1 and skipAnim then
        --单抽且点跳过之后会进这个分支，跳过动画
        self:GetGameObject("Eff"):SetActive(false)
        --延迟一帧播语音，否则会被打断
        self:StartTask(
            function(TT)
                YIELD(TT)
                self._petAudioModule:PlayPetAudio("Obtain", self._dropPets[1]:PetID())
            end
        )

        --5、6星显示spine
        if self._dropPets[1]:SkinID() <= 0 and self._dropPets[1]:Star() > 4 then
            self._cgRoot:SetActive(false)
            local spineName = self:_GetFirstSpineName()
            --local spineName = Cfg.cfg_pet[self._dropPets[1]:PetID()].Spine
            self._spine:LoadSpine(spineName)
            local spineRect = self:GetUIComponent("RectTransform", "spine")
            UICG.SetTransform(spineRect, "UIPetObtain", spineName)
            self._spine.gameObject:SetActive(true)
        end
    else
        for i, pet in ipairs(self._dropPets) do
            self._anims[i] = self:getAnim(pet)
        end
        self._anims[1]:SetAsFirst()
        self._anims[1]:Prepare()
        self:PlayAnimation()
    end

    self._depth = self:GetDepth()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnUIDepthChanged)
end
function UIPetObtain:_GetFirstSpineName()
    local info = self._dropPets[1]
    if info then
        if info:SkinID() > 0 then
            local cfgv = Cfg.cfg_pet_skin[info:SkinID()]
            if cfgv then
                return cfgv.Spine
            end
        else
            local spine = HelperProxy:GetInstance():GetPetSpine(info:PetID(), 0, 0, PetSkinEffectPath.NO_EFFECT)
            if spine then
                return spine
            end
        end
    end
    return ""
end
---@param pet ObtainPet
function UIPetObtain:getAnim(pet)
    local star = Cfg.cfg_pet[pet:PetID()].Star

    if star >= 6 then
        return PetObtainAnim6Star:New(pet, self._anim, self._atlas, self._uiStars, self:GetDepth(), self._matAnim)
    elseif star >= 5 then
        return PetObtainAnim5Star:New(pet, self._anim, self._atlas, self._uiStars, self:GetDepth(), self._matAnim)
    elseif star >= 3 then
        return PetObtainAnimSimple:New(pet, self._anim, self._effStars, self._uiStars, self._matAnim)
    else
        return PetObtainAnimSimple:New(pet, self._anim, self._effStars, self._uiStars, self._matAnim)
    end
end

function UIPetObtain:OnHide()
    -- AudioHelperController.ReleaseUISoundById(CriAudioIDConst.DrawCard_suiji)
    -- for key, value in pairs(CriAudioIDConst.DrawStarCardArr) do
    --     AudioHelperController.ReleaseUISoundById(value)
    -- end
    --最后一张卡牌表现在OnHide中析构，避免黑屏
    if self._curAnim then
        self._curAnim:Dispose()
        self._curAnim = nil
    end
    self._petAudioModule:StopAll()
end

function UIPetObtain:OnUpdate(dtMS)
    if self._curAnim and self._isPlaying then
        self._curAnim:Update(dtMS)
        if self._curAnim:IsOver() then
            -- self._curAnim = nil
            if not self._skipped then
                self._btnSkip:SetActive(true)
            end
            self._endBtn:SetActive(true)
            self._isPlaying = false
        end
    end
end
function UIPetObtain:_GetStaticBody(obtainPet)
    if obtainPet then
        if obtainPet:SkinID() > 0 then
            local cfgv = Cfg.cfg_pet_skin[obtainPet:SkinID()]
            if cfgv then
                return cfgv.StaticBody
            end
        else
            local cg = HelperProxy:GetInstance():GetPetStaticBody(obtainPet:PetID(), 0, 0, PetSkinEffectPath.NO_EFFECT)
            if cg then
                return cg
            else
                Log.fatal("### [error] pet obtain get cf fail . id = [", obtainPet:PetID(), "]")
            end
        end
    end
    return ""
end
function UIPetObtain:_GetNickName(obtainPet)
    if obtainPet then
        if obtainPet:SkinID() > 0 then
            local cfgv = Cfg.cfg_pet_skin[obtainPet:SkinID()]
            if cfgv then
                return cfgv.SkinName
            end
        else
            local cfgv = Cfg.cfg_pet[obtainPet:PetID()]
            if cfgv then
                return cfgv.ChinaTag
            else
                Log.fatal("### [error] cfg_pet no pet. id = [", petId, "]")
            end
        end
    end
    return ""
end
function UIPetObtain:_GetSpine(obtainPet)
    if obtainPet then
        if obtainPet:SkinID() > 0 then
            local cfgv = Cfg.cfg_pet_skin[obtainPet:SkinID()]
            if cfgv then
                return cfgv.Spine
            end
        else
            local spine = HelperProxy:GetInstance():GetPetSpine(obtainPet:PetID(), 0, 0, PetSkinEffectPath.NO_EFFECT)
            if spine then
                return spine
            end
        end
    end
    return ""
end
---region data
---@return boolean 是否可跳过
function UIPetObtain:InitData()
    local petAsset = self._dropPets[self._curIdx]
    if not petAsset then
        return false
    end
    local petId = petAsset:PetID()

    local cfgv = Cfg.cfg_pet[petId]
    if not cfgv then
        Log.fatal("### [error] cfg_pet no pet. id = [", petId, "]")
    end
    local staticBody = self:_GetStaticBody(petAsset)
    if staticBody then
        ---@type MatchPet
        -- local pet = self._petModule:GetPetByTemplateId(petId)
        -- local maxAwaken = pet:GetMaxGrade()
        -- local cfg_grade = Cfg.cfg_pet_grade {PetID = petId, Grade = maxAwaken}
        -- if cfg_grade then
        -- else
        --     Log.fatal("###cfg_pet_grade is nil ! id -- > ", petId)
        -- end
        UICG.SetTransform(self._cgRect, self:GetName(), staticBody)
        self._cgNormal:Load(staticBody)

        self._cg_mid:LoadImage(staticBody)
        UICG.SetTransform(self._cg_mid.transform, self:GetName() .. "_mid", staticBody)
    else
        Log.fatal("### [error] pet [", petId, "] no StaticBody")
    end

    self:LoadElement(cfgv.FirstElement)
    self._logo:DestoryLastImage()
    self._logo:LoadImage(cfgv.Logo)

    self._effLogo:LoadImage(cfgv.Logo)

    self._txtNameEn:SetText(StringTable.Get(cfgv.EnglishName))
    self._txtNameEn2:SetText(StringTable.Get(cfgv.EnglishName))
    self._txtName:SetText(StringTable.Get(cfgv.Name))

    local txtDesc = nil
    local cfg_pet_voice
    ---@type ObtainPet
    local cfgs = Cfg.cfg_pet_voice {PetID = petId, SkinID = petAsset:SkinID()}
    if cfgs and next(cfgs) then
        cfg_pet_voice = cfgs[1]
    else
        cfg_pet_voice = Cfg.cfg_pet_voice {PetID = petId, SkinID = nil}[1]
    end
    if cfg_pet_voice then
        if cfg_pet_voice.Obtain then
            local voiceID = cfg_pet_voice.Obtain[1][1]
            local cfg_audio = AudioHelperController.GetCfgAudio(voiceID)
            if cfg_audio then
                txtDesc = cfg_audio.Content
            else
                Log.fatal("###cfg_audio is nil ! id --> ", voiceID)
            end
        end
    else
        Log.fatal("###cfg_pet_voice is nil ! id --> ", petId)
    end

    if txtDesc then
        self._txtDesc:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(txtDesc)))
    else
        self._txtDesc:SetText("")
    end

    --local nickName = '"' .. StringTable.Get(cfgv.ChinaTag) .. '"'
    local nickName = '"' .. StringTable.Get(self:_GetNickName(petAsset)) .. '"'
    self._nickName:SetText(nickName)
    self._nickName2:SetText(nickName)
    local cfg_tag = Cfg.cfg_pet_tags[cfgv.Tags[1]]
    self._tagTex:SetText(StringTable.Get(cfg_tag.Name))

    if cfg_tag.Icon then
        self._smallLogo.gameObject:SetActive(true)
        self._smallLogo:LoadImage(cfg_tag.Icon)
    else
        self._smallLogo.gameObject:SetActive(false)
    end

    self._star = cfgv.Star or 0

    ---@type GambleModule
    self.gambleModule = self:GetModule(GambleModule)
    if self.gambleModule and self.gambleModule:Context() then
        self.gambleModule:Context():SetMaxStarPetId(self._star, petId)
    end

    --星
    self._sop:SpawnObjects("UIEmptyWidget", self._star)

    --获取当前星灵是否已经获得过，保证在展示前先保存快照
    local isDuplicate = not petAsset:IsNew()
    self.newGo = self:GetGameObject("new")
    if isDuplicate then
        self.newGo:SetActive(false)
        ---@type RoleAsset[]
        local awards = petAsset:ConvertItems()
        if #awards > 1 then
            self._matBgRect.anchoredPosition = Vector2(0, 0)
        else
            self._matBgRect.anchoredPosition = Vector2(130, 0)
        end

        local mats = self:GetUIComponent("UISelectObjectPath", "mats")
        mats:SpawnObjects("UIItemsWidgetSingle", #awards)
        local items = mats:GetAllSpawnList()
        for i = 1, #awards do
            local val = awards[i]
            items[i]:SetData(
                val.assetid,
                val.count,
                function(_id, pos)
                    self:OnMatClick(_id, pos)
                end,
                UIItemScale.Level4
            )
        end
    else
        self.newGo:SetActive(true)
        self._matAnim:SetActive(false)
    end
    if self._isSkin then
        self._matAnim:SetActive(false)
        self._down:SetActive(false)
        self._rightDown:SetActive(false)
        self._elementAreaGo:SetActive(false)
        --动画会修改显示
        self._rightDownCanvas.alpha = 0
        self._downCanvas.alpha = 0
    end
end
---加载属性图片
function UIPetObtain:LoadElement(fstElement)
    local cfg_pet_element = Cfg.cfg_pet_element {}
    if not cfg_pet_element then
        return
    end
    if fstElement then
        self._imgElement.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[fstElement].IconWhite)
        )

        self._elementBg.sprite = self._atlas:GetSprite(self._element2Img[fstElement])
    end
end
---endregion

function UIPetObtain:PlayAnimation()
    if self._curAnim then
        self._curAnim:Dispose()
        self._curAnim = nil
    end

    self._endBtn:SetActive(false)
    self._curAnim = self._anims[self._curIdx]
    self._curAnim:Start()

    --开始准备下一段
    if self._curIdx + 1 <= #self._anims then
        self._anims[self._curIdx + 1]:Prepare()
    end

    local pet = self._dropPets[self._curIdx]
    self._btnSkip:SetActive(pet:CanSkip())
    self._isPlaying = true
end

function UIPetObtain:btnSkipOnClick(go)
    self._skipped = true

    --点跳过时，剩余要显示的卡牌数量
    -- local lastCardCount = #self._dropPets - self._curIdx
    -- local pets = {}
    -- if lastCardCount > 0 then
    --     for i = 1, lastCardCount do
    --         local pet = self._dropPets[self._curIdx + i]
    --         if not pet:CanSkip() then
    --             pets[#pets + 1] = pet
    --         end
    --     end
    -- end

    local pets = {}
    local anims = {}
    for i = self._curIdx + 1, #self._dropPets do
        local pet = self._dropPets[i]

        if pet:CanSkip() then
            self._anims[i]:Dispose()
        else
            pets[#pets + 1] = pet
            anims[#anims + 1] = self._anims[i]
        end
    end

    if #pets == 0 then
        self:Close()
    else
        self._dropPets = pets
        self._anims = anims
        self._anims[1]:SetAsFirst()
        self._anims[1]:Prepare()
        self._curIdx = 1
        self:InitData()
        self:PlayAnimation()
    end
end

---点击背景
function UIPetObtain:btnEndOnClick(go)
    --当前动画已播完
    self._curIdx = self._curIdx + 1
    if self._curIdx > #self._dropPets then
        self:Close()
    else
        self:InitData()
        self:PlayAnimation()
    end
end

function UIPetObtain:Close()
    if self._callback then
        self._callback()
    --self._star
    end
    -- self:CloseDialog() --不关闭界面，以免打开结算界面时会闪一帧局内画面
end

function UIPetObtain:OnMatClick(matId, pos)
    if self.matTipWidget == nil then
        self.matTipWidget = self.matTip:SpawnObject("UISelectInfo")
    end
    self.matTipWidget:SetData(matId, pos)
end

--跳过单张卡牌的动画，直接展示
function UIPetObtain:SkipAndShow()
    -- local state = self._anim:get_Item(self._animName)
    -- if state.normalizedTime < 0.98 then
    --正在播当前动画
    -- state.normalizedTime = 1
    -- end
end

function UIPetObtain:OnUIDepthChanged()
    local depth = self:GetDepth()
    if depth ~= self._depth then
        self._depth = depth
        for i = self._curIdx, #self._anims do
            self._anims[i]:OnUIDepthChanged(depth)
        end
    end
end

----------------------------------------------------------------
---@class ObtainPet:Object
_class("ObtainPet", Object)
ObtainPet = ObtainPet
function ObtainPet:Constructor(id, isNew, skinId, times)
    self._petID = id
    self._skinID = skinId
    self._isNew = isNew
    if Cfg.cfg_pet[id] == nil then
        Log.exception("找不到星灵：", id)
    end
    self._star = Cfg.cfg_pet[id].Star
    self._viewData = UIDrawCardViewDataItem:New(id)
    self._viewData:SetDuplicate(not isNew, times)
end
function ObtainPet:PetID()
    return self._petID
end
function ObtainPet:SkinID()
    return self._skinID
end
function ObtainPet:IsNew()
    return self._isNew
end

function ObtainPet:Star()
    return self._star
end

function ObtainPet:CanSkip()
    ---@type MatchPet
    -- local pet = self._petModule:GetPetByTemplateId(self._petID)
    -- local is6Star = pet:GetPetStar() == 6 --6星
    --MSG20413	（QA_李鑫）抽卡系统QA_获得卡牌表现修改以及6星重复获得可跳过_2021.03.29	5	QA-待制作	靳策, 1951	04/08/2021
    -- if is6Star then
    --     return false
    -- end
    --MSG68159	（QA_程烨飞）抽卡QA_抽卡操作简化_20230713（客户端）	5	QA-开发制作中	靳策, jince	07/18/2023	
    local pet = GameGlobal.GetModule(PetModule):GetPetByTemplateId(self._petID)
    if pet:GetPetStar() == 3 or pet:GetPetStar() == 4 then
        return true --3、4星不管是不是新获得都可跳过
    end

    return not self._isNew
end

function ObtainPet:ConvertItems()
    return self._viewData:ConvertItems()
end
