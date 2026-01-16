---@class UIPetSkinsMainController : UIController
_class("UIPetSkinsMainController", UIController)
UIPetSkinsMainController = UIPetSkinsMainController

function UIPetSkinsMainController:Constructor()
    self._rawImageLoaderHelper = RawImageLoaderHelper:New()
    self._rawImageLoaderHelper:Init(1)
    --时装列表 格子宽高
    self._cardWidth = 70
    self._cardHeight = 488
    self._havePet = true -- 购买用
    self._aniReqs = {}

    self._curSelSkinIndex = 1 -- ui上切换到的皮肤格子index
    self._curSelSkinId = 0 -- ui上切换到的皮肤id
    self._3DModelShow = false
    self._DesignInfoShow = false
    self._skinsCellCount = 0
    self._count = 0
    self._isScrollReady = false
    self._petModule = self:GetModule(PetModule)
    self._skinsStateData = nil
    self._campBg = {
        [PetFilterType.BaiYeCheng] = "sbc_byc",
        [PetFilterType.BaiYeXiaCheng] = "sbc_xc",
        [PetFilterType.QiGuang] = "sbc_qg",
        [PetFilterType.BeiJing] = "sbc_bj",
        [PetFilterType.HongYouBanShou] = "sbc_hybs",
        [PetFilterType.TaiYangJiaoTuan] = "sbc_zljs",
        [PetFilterType.YouMin] = "sbc_wzy"
    }
    self._campSubTitleAreaColor = {
        [PetFilterType.BaiYeCheng] = Color(224 / 255, 135 / 255, 0),
        [PetFilterType.BaiYeXiaCheng] = Color(122 / 255, 50 / 255, 194 / 255),
        [PetFilterType.QiGuang] = Color(184 / 255, 159 / 255, 7 / 255),
        [PetFilterType.BeiJing] = Color(0, 153 / 255, 188 / 255),
        [PetFilterType.HongYouBanShou] = Color(199 / 255, 51 / 255, 0),
        [PetFilterType.TaiYangJiaoTuan] = Color(148 / 255, 0, 0),
        [PetFilterType.YouMin] = Color(58 / 255, 146 / 255, 140 / 255)
    }

    self._sortTb = {}
    self._lastContentPosX = 0

    self._modelShowMng = PetSkinShowModelManager:New()
end
function UIPetSkinsMainController:OnShow(uiParams)
    self:Lock("UIPetSkinsMainController_Anim")
    if self._animEvent then
        GameGlobal.Timer():CancelEvent(self._animEvent)
        self._animEvent = nil
    end
    self._animEvent =
        GameGlobal.Timer():AddEvent(
        633,
        function()
            self:UnLock("UIPetSkinsMainController_Anim")
            self._animEvent = nil
        end
    )

    self.atlas = self:GetAsset("UIPetSkin.spriteatlas", LoadType.SpriteAtlas)

    self._showJinYao = true
    self._openType = uiParams[1] -- PetSkinUiOpenType
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
        self._petId = uiParams[2]
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        ---@type SkinsShopItem
        self._shopGoodData = uiParams[2]
        if self._shopGoodData then
            self._curSelSkinId = self._shopGoodData._skinId
        end
        local skinCfg = Cfg.cfg_pet_skin[self._curSelSkinId]
        if skinCfg then
            self._petId = skinCfg.PetId
        end
        self._shopModule = self:GetModule(ShopModule)
        self._clientShop = self._shopModule:GetClientShop()
    elseif self._openType == PetSkinUiOpenType.PSUOT_TIPS then
        self._curSelSkinId = uiParams[2]
        local skinCfg = Cfg.cfg_pet_skin[self._curSelSkinId]
        if skinCfg then
            self._petId = skinCfg.PetId
        end
        --N30QA 礼包购买界面优化 2023.3.23 曾祥生 移除时装页面详情home按钮
        self._hideHomeBtn = true
        --移除右上角晶耀显示
        self._showJinYao = false
    end

    self._cfgPet = Cfg.cfg_pet[self._petId]
    self._isScrollReady = false

    self:InitWidget()
    self:_InitSkinListData()
    self:_RefreshPetInfo()
    --UICommonHelper:GetInstance():ChangePetTagBackground(self._petId), self._bgLoader, true)
    self:_initSkinsListScroll()
    self:_selDefaultIndex()
    self._isScrollReady = true

    self:AttachEvent(GameEventType.OnCurrencyBySkinSuccess, self._OnCurrencyBuySkinSuccess)
    self:AttachEvent(GameEventType.OnPetSkinChange, self._ForceRefreshUi)
    self:AttachEvent(GameEventType.OpenShop, self.OpenShop)
end
function UIPetSkinsMainController:OnHide()
    self:DetachEvent(GameEventType.OnCurrencyBySkinSuccess, self._OnCurrencyBuySkinSuccess)
    self:DetachEvent(GameEventType.OnPetSkinChange, self._ForceRefreshUi)
    self:DetachEvent(GameEventType.OpenShop, self.OpenShop)
    
    if self._unlockCgTaskID then
        GameGlobal.TaskManager():KillTask(self._unlockCgTaskID)
        self._unlockCgTaskID = nil
    end
    if self._tryUseSkinTaskId then
        GameGlobal.TaskManager():KillTask(self._tryUseSkinTaskId)
        self._tryUseSkinTaskId = nil
    end
    if self._modelShowMng then
        self._modelShowMng:Dispose()
        self._modelShowMng = nil
    end
    for key, value in pairs(self._timeEvents) do
        GameGlobal.Timer():CancelEvent(value)
    end
end

function UIPetSkinsMainController:InitWidget()
    --generated--
    ---@type RawImageLoader
    self._campBgLoader = self:GetUIComponent("RawImageLoader", "CampBg")
    --获取组件
    local backBtns = self:GetUIComponent("UISelectObjectPath", "BackBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    ---@type UIHomelandModule
    self._homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    local hideHomeBtn = self._hideHomeBtn or nil and self._homeLandModule:IsRunning()
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        nil,
        hideHomeBtn
    )
    self._petLogoIconLoader = self:GetUIComponent("RawImageLoader", "PetIcon")
    self._petSkinNameText = self:GetUIComponent("UILocalizationText", "PetSkinName")

    self._petNameCHLabel = self:GetUIComponent("UILocalizationText", "PetNameCH")
    self._petNameENLabel = self:GetUIComponent("UILocalizationText", "PetNameEN")

    self._petNameENBgGo = self:GetGameObject("PetNameENBg")
    self._skinsNumText = self:GetUIComponent("UILocalizationText", "SkinsNumText")
    self._skinsNumAreaGo = self:GetGameObject("SkinsNumArea")
    self._skinsNumTextGo = self:GetGameObject("SkinsNumText")

    self._subPanelTitleAreaImg = self:GetUIComponent("Image", "SubPanelTitleArea")
    self._subPanelTitleText = self:GetUIComponent("UILocalizationText", "SubPanelTitleText")

    self._subPanelAreaGo = self:GetGameObject("SubPanelShowArea")
    self._closeSubPanelAreaGo = self:GetGameObject("CloseSubPanelArea")
    self._3DPanelGo = self:GetGameObject("3DPanel")
    self._designPanelGo = self:GetGameObject("DesignPanel")
    --self._3DModelTex = self:GetUIComponent("EmptyImage", "3DModel")
    --self._3DModelTrans = self:GetUIComponent("Transform", "3DModel")
    self._designText = self:GetUIComponent("UILocalizationText", "DesignText")
    self._designTextTrans = self:GetUIComponent("RectTransform", "DesignText")

    self._cgBtnAreaGo = self:GetGameObject("CgBtnArea")
    self._cgMiniImgLoader = self:GetUIComponent("RawImageLoader", "CgPreview")
    --self._cgTipsRollText = self:GetUIComponent("RollingText", "CgTipsText")

    self._content = self:GetUIComponent("RectTransform", "Content")

    self._swithArrowAreaGo = self:GetGameObject("SwithArrowArea")

    ---@type UnityEngine.UI.ScrollRect
    self._scrollRect = self:GetUIComponent("ScrollRect", "SkinsList")
    self._curSkinAreaGo = self:GetGameObject("CurSkinArea")
    self._useBtnGo = self:GetGameObject("UseBtn")
    self._buyBtnGo = self:GetGameObject("BuyBtn")
    self._getPathAreaGo = self:GetGameObject("GetPathArea")
    self._gotSkinAreaGo = self:GetGameObject("GotSkinArea")
    self._stateAreas = {
        [PetSkinStateType.PSST_CUR_SKIN] = self._curSkinAreaGo,
        [PetSkinStateType.PSST_CAN_USE] = self._useBtnGo,
        [PetSkinStateType.PSST_SHOP_BUY] = self._buyBtnGo,
        [PetSkinStateType.PSST_NOT_OBTAIN] = self._getPathAreaGo,
        [PetSkinStateType.PSST_SHOP_OBTAINED] = self._gotSkinAreaGo
    }
    self._getPathText = self:GetUIComponent("RollingText", "GetPathText")
    self._priceText = self:GetUIComponent("UILocalizationText", "PriceText")
    self._imgPrice = self:GetUIComponent("Image", "ImgPrice")

    self._modelBtnGo = self:GetGameObject("ModelBtn")
    if self._modelBtnGo then
        self._modelBtnGo:SetActive(false)
    --qa 去掉模型显示
    end
    self._designInfoBtnGo = self:GetGameObject("DesignInfoBtn")
    self._modelBtnImg = self:GetUIComponent("Image", "ModelBtn")
    self._designInfoBtnImg = self:GetUIComponent("Image", "DesignInfoBtn")
    self._modelBtnText = self:GetUIComponent("UILocalizationText", "ModelBtnText")
    self._designInfoBtnText = self:GetUIComponent("UILocalizationText", "DesignInfoBtnText")
    self._designScroll = self:GetUIComponent("ScrollRect", "DesignInfoScroll")
    self._designScrollRect = self:GetUIComponent("RectTransform", "DesignInfoScroll")

    --qa 增加专属cg和专属剧情
    self._storyInfoBtnObj = self:GetGameObject("StoryInfoBtn")
    self._StoryInfoBtnText = self:GetUIComponent("UILocalizationText","StoryInfoBtnText")
    self._storyRedPointObj = self:GetGameObject("storyRedPoint")
    self._storyLockObj = self:GetGameObject("story_lock")
    ---------3d---------
    self._ui3DRawImg = self:GetUIComponent("RawImage", "TmpUi3d")
    if self._modelShowMng then
        self._modelShowMng:SetRenderTexture(self._ui3DRawImg.mainTexture)
    end
    self._ui3DGo = self:GetGameObject("TmpUi3d")
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._ui3DGo),
        UIEvent.Drag,
        function(eventData)
            self:_3dDrag(eventData)
        end
    )
    ------------------------------------------------------
    --UI
    self._cgRoot = self:GetGameObject("cgRoot")
    ---@type RawImageLoader
    self._cg_mid = self:GetUIComponent("RawImageLoader", "cgMid")
    self._cg_mid_rect = self:GetUIComponent("RectTransform", "cgMid")

    self._cgRect = self:GetUIComponent("RectTransform", "cgNormal")
    ---@type MultiplyImageLoader
    self._cgNormal = self:GetUIComponent("MultiplyImageLoader", "cgNormal")

    ---@type UnityEngine.UI.RawImage
    self._img = self:GetUIComponent("RawImage", "cgNormal")
    --generated end--
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    --anim
    self._bgAnim = self:GetUIComponent("Animation", "BgAnim")
    self._uiAnim = self:GetUIComponent("Animation", "UiAnim")
    self._animNames = {
        show_3d = {
            name = "UIPetSkinsMainController_u_in_3D",
            time_len = 500
        },
        show_design = {
            name = "UIPetSkinsMainController_u_in_Design",
            time_len = 500
        },
        left_out = {
            name_bg = "UIPetSkinsMainController_b_out_l",
            name_ui = "UIPetSkinsMainController_u_out_l",
            time_len = 233
        },
        left_in = {
            name_bg = "UIPetSkinsMainController_b_in_l",
            name_ui = "UIPetSkinsMainController_u_in_l",
            time_len = 500
        },
        right_out = {
            name_bg = "UIPetSkinsMainController_b_out_r",
            name_ui = "UIPetSkinsMainController_u_out_r",
            time_len = 233
        },
        right_in = {
            name_bg = "UIPetSkinsMainController_b_in_r",
            name_ui = "UIPetSkinsMainController_u_in_r",
            time_len = 500
        }
    }
    self._timeEvents = {}

    --直购买皮肤
    self._binderCurrency = self:GetGameObject("binderCurrency")
    self._binderCurrencyPrice = self:GetUIComponent("UILocalizationText", "binderCurrencyPrice")
    self._binderNormalPrice = self:GetUIComponent("UILocalizationText", "binderNormalPrice")
    self._binderNormalImg = self:GetUIComponent("Image", "binderNormalImg")

    self._cgSpecial = self:GetUIComponent("RawImageLoader","cgSpecial")

    if self._showJinYao then
        local sop = self:GetUIComponent("UISelectObjectPath", "topMenu")
        ---@type UICurrencyMenu
        self.shopCurrencyMenu = sop:SpawnObject("UICurrencyMenu")
        self.shopCurrencyMenu:SetData({RoleAssetID.RoleAssetDiamond})
    end
end
function UIPetSkinsMainController:_selDefaultIndex()
    local defaultIndex = 1
    if self._uiSkinsData then
        for index, uiData in ipairs(self._uiSkinsData) do
            if uiData:IsCurrentSkin() then
                defaultIndex = index
                break
            end
        end
    end
    self:_SelectSkinCellIdx(defaultIndex, true)
    self:_SetMoveToCurSelIdx()
end

function UIPetSkinsMainController:_initSkinsListScroll()
    if not self._petSkinCfg then
        return
    end
    self._skinsCellCount = #self._petSkinCfg
    self._count = self._skinsCellCount
    self._curSelSkinIndex = 1
    self:_CreateScrollItem()
    self:_RefreshScrollItemStateData()
    self:_RefreshScrollItemUiState()
    --默认选中

    if self._count <= 1 then
        self._scrollRect.horizontal = false
    else
        self._scrollRect.horizontal = true
    end
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
        self._swithArrowAreaGo:SetActive(true)
        self._skinsNumAreaGo:SetActive(true)
        self._skinsNumTextGo:SetActive(true)
        self._skinsNumText:SetText(StringTable.Get("str_pet_skin_list_num", self._skinsCellCount))
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        self._swithArrowAreaGo:SetActive(false)
        self._skinsNumAreaGo:SetActive(false)
        self._skinsNumTextGo:SetActive(false)
    elseif self._openType == PetSkinUiOpenType.PSUOT_TIPS then
        self._swithArrowAreaGo:SetActive(false)
        self._skinsNumAreaGo:SetActive(false)
        self._skinsNumTextGo:SetActive(false)
    end
end
function UIPetSkinsMainController:_ForceRefreshUi()
    self:_RefreshScrollItemStateData()
    self:_RefreshScrollItemUiState()
    self:_RefreshUiByCurSkinIndex()
end
function UIPetSkinsMainController:_SelectSkinCellIdx(idx, bNoAnim)
    local useAnim = true
    if bNoAnim then
        useAnim = false
    end
    if idx == self._curSelSkinIndex then
        useAnim = false
    end
    local bLeft = idx >= self._curSelSkinIndex
    self._curSelSkinIndex = idx
    if useAnim then
        if bLeft then
            self:PlayLeftOut()
            -- 开启倒计时
            self._timeEvents._swithLeftTimeEvent =
                GameGlobal.Timer():AddEvent(
                self._animNames.left_out.time_len,
                function()
                    self:_RefreshUiByCurSkinIndex()
                    self:PlayLeftIn()
                end
            )
        else
            self:PlayRightOut()
            -- 开启倒计时
            self._timeEvents._swithLeftTimeEvent =
                GameGlobal.Timer():AddEvent(
                self._animNames.right_out.time_len,
                function()
                    self:_RefreshUiByCurSkinIndex()
                    self:PlayRightIn()
                end
            )
        end
    else
        self:_RefreshUiByCurSkinIndex()
    end
end
function UIPetSkinsMainController:_SetMoveToCurSelIdx()
    self._targetPosX = self:_CalcPosX(self._curSelSkinIndex)
    --self._curSelSkinIndex * self._cardWidth * -1
    self:_RefreshClothListSibling()
end
function UIPetSkinsMainController:_CreateScrollItem()
    self._contentWidth = self._cardWidth * self._skinsCellCount
    --self:_SetMoveToCurSelIdx()
    self._contentCenterPosX = self._contentWidth / 2
    self._sortTb = {}
    ---------------------------------------------------
    local itemPool = self:GetUIComponent("UISelectObjectPath", "Content")
    local y = self._content.sizeDelta.y
    self._content.sizeDelta = Vector2(self._contentWidth, y)
    itemPool:SpawnObjects("UIPetSkinsSelectCell", self._skinsCellCount)
    ---@type UIPetSkinsSelectCell[]
    local items = itemPool:GetAllSpawnList()
    self._items = items
    for i = 1, self._skinsCellCount do
        local cellSortTb = {}
        cellSortTb.idx = 0
        cellSortTb.posX = 0
        cellSortTb.absDis = 0
        self._sortTb[i] = cellSortTb
        local itemGo = items[i]:GetGameObject()
        itemGo.transform.anchorMin = Vector2(0, 0.5)
        itemGo.transform.anchorMax = Vector2(0, 0.5)
        itemGo.transform.sizeDelta = Vector2(self._cardWidth, self._cardHeight)
        local posY = items[i]:GetGameObject().transform.anchoredPosition.y
        itemGo.transform.anchoredPosition = Vector2(self._cardWidth * (i - 1) + self._cardWidth / 2, posY)
        items[i]:SetData(
            self._petSkinCfg[i],
            i,
            --idx
            function(idx) --onclick
                if self._count <= 1 then
                    return
                end
                --把cg预览隐藏
                self._cgBtnAreaGo:SetActive(false)
                --self._curSelSkinIndex = idx
                self:_SelectSkinCellIdx(idx)
                self:_SetMoveToCurSelIdx()
                self._isDarging = false
            end,
            function(eventData) --dragBegin
                if self._count <= 1 then
                    return
                end
                self._bDragPosX = eventData.position.x
                self._isDarging = true
                self._tmpContentPosX = self._content.anchoredPosition.x

                --把cg预览隐藏
                self._cgBtnAreaGo:SetActive(false)
            end,
            function(eventData) --draging
            end,
            function(eventData) --dragEnd
                if self._count <= 1 then
                    return
                end
                local lPosX = self._content.anchoredPosition.x - self._contentWidth / 2
                if lPosX >= 0 then
                    lPosX = -self._cardWidth / 2
                elseif lPosX <= -self._contentWidth then
                    lPosX = -self._contentWidth + self._cardWidth / 2
                end
                local absLPosX = math.abs(lPosX)

                --local posx = math.abs(self._content.anchoredPosition.x)
                --local c, d = math.modf(posx / self._cardWidth)
                local c = math.ceil(absLPosX / self._cardWidth)
                local _, d = math.modf(absLPosX / self._cardWidth)

                local tmpIdx = self._curSelSkinIndex
                self._eDragPosX = eventData.position.x
                tmpIdx = c
                if tmpIdx == self._curSelSkinIndex then
                    if self._eDragPosX < self._bDragPosX then
                        if d > 0.7 then
                            tmpIdx = tmpIdx + 1
                        end
                    else
                        if d < 0.3 then
                            tmpIdx = tmpIdx - 1
                        end
                    end
                end

                local finalIdx = 1
                if tmpIdx > self._count then
                    --tmpIdx % self._count
                    finalIdx = self._count
                elseif tmpIdx <= 0 then
                    --self._count
                    finalIdx = 1
                else
                    finalIdx = tmpIdx
                end
                self:_SelectSkinCellIdx(finalIdx)
                self:_SetMoveToCurSelIdx()
                self._isDarging = false
            end
        )
    end
end
function UIPetSkinsMainController:_RefreshScrollItemStateData()
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
        self:_Detail_RefreshScrollItemStateData()
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        self:_Shop_RefreshScrollItemStateData()
    elseif self._openType == PetSkinUiOpenType.PSUOT_TIPS then
        self:_Tips_RefreshScrollItemStateData()
    end
end
function UIPetSkinsMainController:_Detail_RefreshScrollItemStateData()
    if not self._petModule then
        return
    end
    self._uiSkinsData = {}

    local petModuleInfo = self._petModule:GetPetByTemplateId(self._petId)
    if not petModuleInfo then
        return
    end
    self._cfg_grade = Cfg.cfg_pet_grade {PetID = self._petId, Grade = petModuleInfo:GetPetGrade()}
    ---@type pet_skin_data
    self._skinsStateData = self._petModule:GetPetSkinsData(self._petId)
    if self._skinsStateData then
    end
    if self._petSkinCfg then
        for idx, skinCfg in ipairs(self._petSkinCfg) do
            ---@type DPetSkinDetailCard
            local uiSkinData = DPetSkinDetailCard:New(skinCfg)
            uiSkinData:SetIsShopDetail(false)
            local is_obtain = false
            if self._skinsStateData then
                local curSkin = self._skinsStateData.current_skin
                local isCurSkin = (curSkin == skinCfg.id)
                if curSkin == 0 then
                    isCurSkin = (idx == 1)
                end
                uiSkinData:SetIsCurrentSkin(isCurSkin)
                local obtainedSkinInfo = self._skinsStateData.skin_info
                if obtainedSkinInfo then
                    for _, skinInfo in pairs(obtainedSkinInfo) do
                        if skinInfo and (skinInfo.skin_id == skinCfg.id) then
                            is_obtain = true
                            uiSkinData:SetUnlockCg(skinInfo.unlock_CG)
                            break
                        end
                    end
                end
            else
                --tmp
                local isCurSkin = (idx == 1)
                uiSkinData:SetIsCurrentSkin(isCurSkin)
            end
            uiSkinData:SetObtained(is_obtain)
            table.insert(self._uiSkinsData, uiSkinData)
        end
    end
end
function UIPetSkinsMainController:_Shop_RefreshScrollItemStateData()
    if not self._petModule then
        return
    end
    self._havePet = true
    self._uiSkinsData = {}
    local petModuleInfo = self._petModule:GetPetByTemplateId(self._petId)
    if not petModuleInfo then --没有光灵
        self._havePet = false
    end
    ---@type pet_skin_data
    self._skinsStateData = self._petModule:GetPetSkinsData(self._petId)
    if self._skinsStateData then
    end
    if self._petSkinCfg then
        for idx, skinCfg in ipairs(self._petSkinCfg) do
            ---@type DPetSkinDetailCard
            local uiSkinData = DPetSkinDetailCard:New(skinCfg)
            uiSkinData:SetIsShopDetail(true)
            local is_obtain = false
            uiSkinData:SetIsCurrentSkin(false)
            if self._skinsStateData then
                local obtainedSkinInfo = self._skinsStateData.skin_info
                if obtainedSkinInfo then
                    for _, skinInfo in pairs(obtainedSkinInfo) do
                        if skinInfo and (skinInfo.skin_id == skinCfg.id) then
                            is_obtain = true
                            uiSkinData:SetUnlockCg(skinInfo.unlock_CG)
                            break
                        end
                    end
                end
            else
            end
            uiSkinData:SetObtained(is_obtain)
            table.insert(self._uiSkinsData, uiSkinData)
        end
    end
end

function UIPetSkinsMainController:_Tips_RefreshScrollItemStateData()
    if not self._petModule then
        return
    end
    self._havePet = true
    self._uiSkinsData = {}
    local petModuleInfo = self._petModule:GetPetByTemplateId(self._petId)
    if not petModuleInfo then --没有光灵
        self._havePet = false
    end
    ---@type pet_skin_data
    self._skinsStateData = self._petModule:GetPetSkinsData(self._petId)
    if self._skinsStateData then
    end
    if self._petSkinCfg then
        for idx, skinCfg in ipairs(self._petSkinCfg) do
            ---@type DPetSkinDetailCard
            local uiSkinData = DPetSkinDetailCard:New(skinCfg)
            uiSkinData:SetIsTipsDetail(true)
            local is_obtain = false
            uiSkinData:SetIsCurrentSkin(false)
            if self._skinsStateData then
                local obtainedSkinInfo = self._skinsStateData.skin_info
                if obtainedSkinInfo then
                    for _, skinInfo in pairs(obtainedSkinInfo) do
                        if skinInfo and (skinInfo.skin_id == skinCfg.id) then
                            is_obtain = true
                            uiSkinData:SetUnlockCg(skinInfo.unlock_CG)
                            break
                        end
                    end
                end
            else
            end
            uiSkinData:SetObtained(is_obtain)
            table.insert(self._uiSkinsData, uiSkinData)
        end
    end
end

function UIPetSkinsMainController:_RefreshScrollItemUiState()
    if not self._uiSkinsData then
        return
    end
    for idx, item in ipairs(self._items) do
        local data = self._uiSkinsData[idx]
        item:RefreshData(data)
    end
end
function UIPetSkinsMainController:_CalcPosX(idx)
    local posx = 0
    if not idx or self._count <= 1 then
        return posx
    end
    local startPos = self._contentWidth / 2 + self._cardWidth / 2
    posx = startPos - idx * self._cardWidth
    return posx
end

function UIPetSkinsMainController:_RefreshPetInfo()
    if not self._cfgPet then
        return
    end
    self._petNameCHLabel:SetText(StringTable.Get(self._cfgPet.Name))
    local enName = self._cfgPet.EnglishName
    local strEnName = StringTable.Get(enName)
    self._petNameENLabel:SetText(strEnName)

    self._petLogoIconLoader:LoadImage(self._cfgPet.Logo)
    self:_SetSubTitleColor()
end

function UIPetSkinsMainController:_Refresh3DModel()
    if self._modelShowMng then
        self._modelShowMng:ShowPetSkinModel(self._curSelSkinId)
    end
end
function UIPetSkinsMainController:_Release3d()
    if self._modelShowMng then
        self._modelShowMng:Reset()
    end
end

function UIPetSkinsMainController:_RefreshDesignInfo()
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    if cfgSkin then
        self._designText:SetText(StringTable.Get(cfgSkin.DesignStr))
        local timerEvent =
            GameGlobal.Timer():AddEventTimes(
            100,
            1,
            function()
                if self._designTextTrans.sizeDelta.y < self._designScrollRect.sizeDelta.y then
                    self._designScroll.vertical = false
                else
                    self._designScroll.vertical = true
                end
            end
        )
    end
end
function UIPetSkinsMainController:CloseSubPanelAreaOnClick(go)
    if self._3DModelShow then
        self:ModelBtnOnClick(nil)
    elseif self._DesignInfoShow then
        self:DesignInfoBtnOnClick(nil)
    end
end
function UIPetSkinsMainController:ModelBtnOnClick(go)
    do
        return --qa 去掉模型显示
    end
    self._3DModelShow = not self._3DModelShow
    self._DesignInfoShow = false
    self._designInfoBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame9")
    self._designInfoBtnText:SetText(StringTable.Get("str_pet_skin_show_design_info"))

    self._subPanelAreaGo:SetActive(self._3DModelShow)
    self._closeSubPanelAreaGo:SetActive(self._3DModelShow)
    self._3DPanelGo:SetActive(self._3DModelShow)
    self._designPanelGo:SetActive(false)
    if self._3DModelShow then
        self:_Set3DModelTitle()
        self:_Refresh3DModel()
        self._modelBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame10")
        self._modelBtnText:SetText(StringTable.Get("str_pet_skin_hide_model"))
    else
        self:_Release3d()
        self._modelBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame9")
        self._modelBtnText:SetText(StringTable.Get("str_pet_skin_show_model"))
    end
    if self._3DModelShow then
        self:Lock("UIPetSkinsMainController:ModelBtnOnClick")
        if self._uiAnim then
            self._uiAnim:Play(self._animNames.show_3d.name)
        end
        self._timeEvents._show3dTimeEvent =
            GameGlobal.Timer():AddEvent(
            self._animNames.show_3d.time_len,
            function()
                self:UnLock("UIPetSkinsMainController:ModelBtnOnClick")
            end
        )
    end
end

function UIPetSkinsMainController:DesignInfoBtnOnClick(go)
    self._DesignInfoShow = not self._DesignInfoShow
    self._3DModelShow = false
    self._modelBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame9")
    self._modelBtnText:SetText(StringTable.Get("str_pet_skin_show_model"))
    self:_Release3d()
    self._subPanelAreaGo:SetActive(self._DesignInfoShow)
    self._closeSubPanelAreaGo:SetActive(self._DesignInfoShow)

    self._designPanelGo:SetActive(self._DesignInfoShow)
    self._3DPanelGo:SetActive(false)
    if self._DesignInfoShow then
        self:_SetDesignTitle()
        self:_RefreshDesignInfo()
        self._designInfoBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame10")
        self._designInfoBtnText:SetText(StringTable.Get("str_pet_skin_hide_design_info"))
    else
        self._designInfoBtnImg.sprite = self.atlas:GetSprite("fashion_main_frame9")
        self._designInfoBtnText:SetText(StringTable.Get("str_pet_skin_show_design_info"))
    end
    if self._DesignInfoShow then
        self:Lock("UIPetSkinsMainController:DesignInfoBtnOnClick")
        if self._uiAnim then
            self._uiAnim:Play(self._animNames.show_design.name)
        end
        self._timeEvents._showDesignTimeEvent =
            GameGlobal.Timer():AddEvent(
            self._animNames.show_design.time_len,
            function()
                self:UnLock("UIPetSkinsMainController:DesignInfoBtnOnClick")
            end
        )
    end
end

function UIPetSkinsMainController:CgBtnOnClick(go)
    local curUiData = self._uiSkinsData[self._curSelSkinIndex]
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]
    if curUiData and skinCfg then
        if curUiData:IsObtained() then
            if skinCfg.CgId then
                if curUiData:IsUnlockCg() then
                    --打开cg
                    self:_PlayCurSelSkinCg(false)
                else
                    ToastManager.ShowToast(StringTable.Get("str_pet_skin_cg_lock_story"))
                end
            end
        else
            ToastManager.ShowToast(StringTable.Get("str_pet_skin_cg_lock_story"))
        end
    end
end
function UIPetSkinsMainController:_ConfirmToPlayCurSelSkinStory(bFirst)
    local strTitle = ""
    local strText = ""
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    if cfgSkin then
        local storyId = cfgSkin.StoryId
        local storyCfg = Cfg.cfg_pet_story[storyId]
        if storyCfg then
            local tipsStr = "str_pet_skin_collect_fashion_story_tips_2"
            local titleStr = "str_quest_base_type_stroy" -- 剧情
            if cfgSkin.CgId then
                tipsStr = "str_pet_skin_collect_fashion_story_tips_1"
                titleStr = "str_pet_skin_collect_fashion_story"
            -- 典藏剧情
            end
            strText = StringTable.Get(tipsStr, StringTable.Get(storyCfg.Title))
            strTitle = StringTable.Get(titleStr)
        end
    end
    local okCb = function()
        self:_PlayCurSelSkinStory(bFirst)
    end
    local okBtnText = StringTable.Get("str_pet_skin_enter")
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        strTitle,
        strText,
        okCb,
        nil,
        nil,
        nil,
        nil,
        okBtnText
    )
end
function UIPetSkinsMainController:_PlayCurSelSkinStory(bFirst)
    local isFirst = bFirst or false
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]
    if skinCfg and skinCfg.StoryId then
        local storyCfg = Cfg.cfg_pet_story[skinCfg.StoryId]
        if storyCfg then
            GameGlobal.GetModule(StoryModule):StartStory(
                storyCfg.StoryID,
                function()
                    self:_StoryPlayEnd(skinCfg.StoryId, isFirst, skinCfg.CgId)
                end,
                true
            )
        end
    end
end
function UIPetSkinsMainController:_PlayCurSelSkinCg(bFirst)
    local isFirst = bFirst or false
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]
    if skinCfg and skinCfg.CgId then
        --skinCfg.CgId
        local cgCfg = Cfg.cfg_cg_book[skinCfg.CgId]
        if cgCfg then
            self:ShowDialog("UIPetSkinsGetCgController", cgCfg.StaticPic, isFirst)
        end
    end
end
function UIPetSkinsMainController:_StoryPlayEnd(storyid, isFirst, cgId)
    if isFirst then
        self._unlockCgTaskID =
            self:StartTask(
            function(TT)
                self:Lock("UIPetSkinsMainController:_StoryPlayEnd")
                local res = self._petModule:UnlockSkinCG(TT, self._curSelSkinId)
                if res:GetSucc() then
                    if cgId then
                        self:_PlayCurSelSkinCg(true)
                    else
                        self:_ShowStoryTips()
                    end
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.WatchPetSkinStory)
                end
                self:_ForceRefreshUi()
                self:UnLock("UIPetSkinsMainController:_StoryPlayEnd")
            end
        )
    end
end
function UIPetSkinsMainController:_ShowStoryTips()
    self:Lock("UIPetSkinsMainController:_ShowStoryTips")
    self:ShowDialog(
        "UIAircraftUnlockFileController",
        StringTable.Get("str_aircraft_review_story"),
        StringTable.Get("str_aircraft_review_story_en")
    )
    GameGlobal.Timer():AddEvent(
        3000,
        function()
            GameGlobal.UIStateManager():CloseDialog("UIAircraftUnlockFileController")
            self:UnLock("UIPetSkinsMainController:_ShowStoryTips")
        end
    )
end

function UIPetSkinsMainController:_ConfirmToUseNewSkin()
    local strTitle = StringTable.Get("str_pet_skin_get_new_skin") -- 获得新时装

    local petName = StringTable.Get(self._cfgPet.Name)
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    local skinName = ""
    local skinType = ""
    if cfgSkin then
        skinName = StringTable.Get(cfgSkin.SkinName)
        if cfgSkin.SkinType == PetSkinFlag.PSF_NORMAL then
            skinType = StringTable.Get("str_pet_skin_fashion")
        elseif cfgSkin.SkinType == PetSkinFlag.PSF_COLLECTION then
            skinType = StringTable.Get("str_pet_skin_collect_fashion")
        end
    end
    local strText = StringTable.Get("str_pet_skin_net_skin_tips", petName, skinType, skinName)
    local okCb = function()
        self:_TryUseSkin(self._curSelSkinId, true)
    end
    local okBtnText = StringTable.Get("str_pet_skin_change")
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        strTitle,
        strText,
        okCb,
        nil,
        nil,
        nil,
        nil,
        okBtnText
    )
end
function UIPetSkinsMainController:_TryUseSkin(skinId, inShop)
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    if not cfgSkin then
        return
    end
    if not self._petModule:HasPet(cfgSkin.PetId) then
        ToastManager.ShowToast(StringTable.Get("str_pet_skin_change_fail_tips")) -- 尚未获得该光灵，无法更换！
        return
    end
    self._tryUseSkinTaskId = self:StartTask(self._TaskTryUseSkin, self, skinId, inShop)
end
function UIPetSkinsMainController:_TaskTryUseSkin(TT, skinId, inShop)
    self:Lock("UIPetSkinsMainController_UseSkin")
    local res = self._petModule:PetSkinChange(TT, skinId)
    if res:GetSucc() then
        if inShop then
            ToastManager.ShowToast(StringTable.Get("str_pet_skin_change_success_tips")) -- 时装更换成功，可前往光灵详情界面查看!
        end
        self:_ForceRefreshUi()
        self:UnLock("UIPetSkinsMainController_UseSkin")
    else
        self:UnLock("UIPetSkinsMainController_UseSkin")
    end
end

function UIPetSkinsMainController:UseBtnOnClick(go)
    self:_TryUseSkin(self._curSelSkinId, false)
end
function UIPetSkinsMainController:_Set3DModelTitle()
    if not self._cfgPet then
        return
    end
    local petName = StringTable.Get(self._cfgPet.Name)
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    local skinName = ""
    if cfgSkin then
        skinName = StringTable.Get(cfgSkin.SkinName)
    end
    --local title = string.format("%s-%s-%s",petName,skinName,StringTable.Get("str_pet_skin_show_model"))
    local title = StringTable.Get("str_pet_skin_show_model_title")
    self._subPanelTitleText:SetText(title)
end
function UIPetSkinsMainController:_SetDesignTitle()
    if not self._cfgPet then
        return
    end
    local petName = StringTable.Get(self._cfgPet.Name)
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    local skinName = ""
    if cfgSkin then
        skinName = StringTable.Get(cfgSkin.SkinName)
    end
    local title = StringTable.Get("str_pet_skin_show_design_info")
    self._subPanelTitleText:SetText(title)
end
function UIPetSkinsMainController:_SetSubTitleColor()
    local petCfg = self._cfgPet
    local tags = petCfg.Tags
    if not tags or tags[1] == nil then
        return
    end
    local tag = tags[1]
    local color = self._campSubTitleAreaColor[tag]
    if color then
        self._subPanelTitleAreaImg.color = color
    end
end
function UIPetSkinsMainController:_SetCampBg(templateId, skinId, imageLoader)
    local skinCfg = Cfg.cfg_pet_skin[skinId]
    if skinCfg then
        if skinCfg.CampBg then
            imageLoader:LoadImage(skinCfg.CampBg)
            return
        end
    end
    local petCfg = self._cfgPet
    local tags = petCfg.Tags
    if not tags or tags[1] == nil then
        return
    end
    local tag = tags[1]
    local campBg = self._campBg[tag]
    if campBg then
        imageLoader:LoadImage(campBg)
    end
end
function UIPetSkinsMainController:LeftArrowOnClick(go)
    if self._count <= 1 then
        return
    end
    if self._curSelSkinIndex <= 1 then
        return
    end
    local idx = self._curSelSkinIndex - 1
    self:_SelectSkinCellIdx(idx)
    self:_SetMoveToCurSelIdx()
    self._isDarging = false
end
function UIPetSkinsMainController:RightArrowOnClick(go)
    if self._count <= 1 then
        return
    end
    if self._curSelSkinIndex >= self._count then
        return
    end
    local idx = self._curSelSkinIndex + 1
    self:_SelectSkinCellIdx(idx)
    self:_SetMoveToCurSelIdx()
    self._isDarging = false
end
function UIPetSkinsMainController:_InitSkinListData()
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
        self._petSkinCfg = Cfg.cfg_pet_skin {PetId = self._petId}
        table.sort(
            self._petSkinCfg,
            function(a, b)
                return a.id < b.id
            end
        )
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        self._petSkinCfg = {}
        self._petSkinCfg[1] = Cfg.cfg_pet_skin[self._curSelSkinId]
    elseif self._openType == PetSkinUiOpenType.PSUOT_TIPS then
        self._petSkinCfg = {}
        self._petSkinCfg[1] = Cfg.cfg_pet_skin[self._curSelSkinId]
    else
    end
end
function UIPetSkinsMainController:_RefreshUiByCurSkinIndex()
    local curCfg = self._petSkinCfg[self._curSelSkinIndex]
    if not curCfg then
        return
    end
    self._curSelSkinId = curCfg.id
    self:_SetCgBySkin(self._curSelSkinId)
    self:_SetSkinNameBySkin(self._curSelSkinId)
    self:_SetCampBg(self._petId, self._curSelSkinId, self._campBgLoader)
    self:_CheckInfoBtnShow()
    if self._3DModelShow then
        self:_Refresh3DModel()
    elseif self._DesignInfoShow then
        self:_RefreshDesignInfo()
    end

    self:_RefreshStateAreaByCurSkinIndex()
    self:_RefreshCgMiniBtnAreaByCurSkinIndex()
end
function UIPetSkinsMainController:_CheckInfoBtnShow()
    local curUiData = self._uiSkinsData[self._curSelSkinIndex]
    local skinCfg = Cfg.cfg_pet_skin[self._curSelSkinId]
    if not skinCfg then
        return
    end
    if not skinCfg.DesignStr or skinCfg.DesignStr == "" then
        self._designInfoBtnGo:SetActive(false)
        if self._DesignInfoShow then
            self:DesignInfoBtnOnClick(nil)
        end
    else
        self._designInfoBtnGo:SetActive(true)
    end

    --有附带剧情
    if skinCfg.StoryId then
        self._storyInfoBtnObj:SetActive(true)
        --判断是否已经购买过
        if curUiData:IsObtained() then
            self._StoryInfoBtnText:SetText(StringTable.Get("str_pet_skin_story_obtained"))
            self._storyLockObj:SetActive(false)
            --判断是否看过
            if curUiData:IsUnlockCg() then
                self._storyRedPointObj:SetActive(false)
            else
                self._storyRedPointObj:SetActive(true)
            end
        else
            self._storyRedPointObj:SetActive(false)
            self._storyLockObj:SetActive(true)
            self._StoryInfoBtnText:SetText(StringTable.Get("str_pet_skin_story_unobtained"))
        end
    else
        self._storyInfoBtnObj:SetActive(false)
    end
end
function UIPetSkinsMainController:_SetSkinNameBySkin(skinId)
    local skinCfg = Cfg.cfg_pet_skin[skinId]
    if not skinCfg then
        return
    end
    local skinTitleFmt = '"%s"'
    local title = string.format(skinTitleFmt, StringTable.Get(skinCfg.SkinName))
    self._petSkinNameText:SetText(title)
end
function UIPetSkinsMainController:_RefreshStateAreaByCurSkinIndex()
    if not self._uiSkinsData then
        return
    end
    ---@type DPetSkinDetailCard
    local curUiData = self._uiSkinsData[self._curSelSkinIndex]
    if curUiData then
        if curUiData:IsShopDetail() then
            if curUiData:IsObtained() then
                self:_ShowStateArea(PetSkinStateType.PSST_SHOP_OBTAINED)
            else
                self:_ShowStateArea(PetSkinStateType.PSST_SHOP_BUY)
                self:_RefreshPriceBtn()
            end
        elseif curUiData:IsTipsDetail() then
            if curUiData:IsObtained() then
                self:_ShowStateArea(PetSkinStateType.PSST_SHOP_OBTAINED)
            else
                self:_ShowStateArea(PetSkinStateType.PSST_NOT_OBTAIN)
                self:_RefreshSkinGetPathText()
            end
        else
            if curUiData:IsCurrentSkin() then
                self:_ShowStateArea(PetSkinStateType.PSST_CUR_SKIN)
            else
                if curUiData:IsObtained() then
                    self:_ShowStateArea(PetSkinStateType.PSST_CAN_USE)
                else
                    self:_ShowStateArea(PetSkinStateType.PSST_NOT_OBTAIN)
                    self:_RefreshSkinGetPathText()
                end
            end
        end
    end
end
function UIPetSkinsMainController:_RefreshCgMiniBtnAreaByCurSkinIndex()
    local curUiData = self._uiSkinsData[self._curSelSkinIndex]
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]
    local showArea = false
    if curUiData and skinCfg then
        if skinCfg.CgId then
            showArea = true
            local cgCfg = Cfg.cfg_cg_book[skinCfg.CgId]
            if cgCfg then
                if cgCfg.SkinCgPreview then
                    self._cgMiniImgLoader:LoadImage(cgCfg.SkinCgPreview)
                end
            end
        else
            showArea = false
        end
        -- if skinCfg.StoryId then
        --     -- 只有剧情 但看过了 隐藏
        --     if curUiData:IsObtained() then
        --         if curUiData:IsUnlockCg() then
        --             showArea = false
        --         end
        --     end
        --     if showArea then
        --         --剧情默认图
        --         local defaultCgMiniImg = "Ty_Scg_small"
        --         self._cgMiniImgLoader:LoadImage(defaultCgMiniImg)
        --     end
        -- end
    end
    self._cgBtnAreaGo:SetActive(showArea)
end
function UIPetSkinsMainController:_ShowStateArea(state)
    for key, value in pairs(self._stateAreas) do
        value:SetActive(key == state)
    end

    --MSG36449	【必现】（测试_李鑫）皮肤直购后购买完成界面没有隐藏购买按钮，附截图/附log	4	新缺陷	王怀冬, 252	01/24/2022
    --已获得皮肤关闭直购按钮 靳策添加
    if state == PetSkinStateType.PSST_SHOP_OBTAINED then
        self._binderCurrency:SetActive(false)
    end
end
function UIPetSkinsMainController:_RefreshSkinGetPathText()
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]
    if skinCfg then
        local getPathStr = ""
        if skinCfg.ObtainPathStr then
            getPathStr = skinCfg.ObtainPathStr
        else
            if skinCfg.UnlockType then
                local unlockType = skinCfg.UnlockType[1]
                if unlockType == PetSkinUnlockType.PSUT_BASE then
                elseif unlockType == PetSkinUnlockType.PSUT_GRADE then
                    getPathStr = "str_pet_skin_get_path_1"
                elseif unlockType == PetSkinUnlockType.PSUT_SHOP then
                    getPathStr = "str_pet_skin_get_path_2"
                elseif unlockType == PetSkinUnlockType.PSUT_Dream then
                    getPathStr = "str_pet_skin_get_path_6"
                end
            end
        end
        self._getPathText:RefreshText(StringTable.Get(getPathStr))
    end
end
function UIPetSkinsMainController:_RefreshPriceBtn()
    if self._shopGoodData then
        --如果有binderItem的话
        local binderItem = self._shopGoodData:GetBinderSkin()
        if binderItem then
            self._buyBtnGo:SetActive(false)
            self._binderCurrency:SetActive(true)

            local img = self._shopGoodData:GetPriceIcon()
            self._binderNormalImg.sprite = self._atlas:GetSprite(self._shopGoodData:GetPriceIcon())
            self._binderNormalPrice:SetText(self._shopGoodData:GetPrice())

            self._binderCurrencyPrice:SetText(binderItem:GetPriceWithCurrencySymbol())
        else
            self._buyBtnGo:SetActive(true)
            self._binderCurrency:SetActive(false)

            local itemtType = self._shopGoodData:GetType()
            if itemtType == SkinsPayType.Currency then
                self._imgPrice.gameObject:SetActive(false)
                self._priceText:SetText(self._shopGoodData:GetPriceWithCurrencySymbol())
            elseif itemtType == SkinsPayType.Free then
                self._imgPrice.gameObject:SetActive(false)
                self._priceText:SetText(StringTable.Get("str_pay_free"))
            else
                self._imgPrice.gameObject:SetActive(true)
                self._imgPrice.sprite = self._atlas:GetSprite(self._shopGoodData:GetPriceIcon())
                self._priceText:SetText(self._shopGoodData:GetPrice())
            end
        end
    end
end
function UIPetSkinsMainController:_SetCgBySkin(skinId)
    local skinCfg = Cfg.cfg_pet_skin[skinId]
    if not skinCfg then
        return
    end
    local staticBody
    if skinCfg.MainLobbyCg then
        staticBody = skinCfg.MainLobbyCg
    else
        staticBody = skinCfg.StaticBody
    end
    if staticBody then
        ---@type MatchPet
        local uiName = self:GetName()
        --tmp
        --uiName = "UIPetObtain"

        local isSpecial = false
        if skinCfg.MainLobbySize then
            isSpecial = true
            self._cgSpecial:LoadImage(staticBody)
        else
            isSpecial = false
            UICG.SetTransform(self._cg_mid.transform, uiName .. "_mid", staticBody)
            UICG.SetTransform(self._cgRect, uiName, staticBody)
            self._cgNormal:Load(staticBody)
        end
        self._cgNormal.gameObject:SetActive(not isSpecial)
        self._cgSpecial.gameObject:SetActive(isSpecial)

        self._cg_mid:LoadImage(staticBody)
    else
        Log.fatal("### [error] pet [", skinId, "] no StaticBody")
    end
end

function UIPetSkinsMainController:OnUpdate(deltaTimeMS)
    if self._isScrollReady then
        if self._count <= 1 then
            return
        end
        if not self._isDarging then
            local absDis = math.abs(self._content.anchoredPosition.x - self._targetPosX)
            if absDis > 1 then
                local moveTime = 0.5
                self._content.anchoredPosition =
                    Vector2(
                    Mathf.Lerp(self._content.anchoredPosition.x, self._targetPosX, moveTime),
                    self._content.anchoredPosition.y
                )
            else
                self._content.anchoredPosition = Vector2(self._targetPosX, self._content.anchoredPosition.y)
            end
        end
        if self._content.anchoredPosition.x ~= self._lastContentPosX then
            self._lastContentPosX = self._content.anchoredPosition.x

            self:_RefreshClothListSibling()
        end
    end
end
function UIPetSkinsMainController:_CalSkinListOrderLayer(absDis)
    local param = self._cardWidth
    if param <= 0 then
        return 1
    end
    local a, b = math.modf(absDis / param)
    return a
end
function UIPetSkinsMainController:_RefreshClothListSibling()
    if not self._items then
        return
    end
    local curCenterPosX = self._contentCenterPosX - self._content.anchoredPosition.x
    --self._contentCenterPosX
    local minAbs = -1
    local topCellPos = -1
    for index, item in ipairs(self._items) do
        local posX = item:GetGameObject().transform.anchoredPosition.x
        local absDis = math.abs(curCenterPosX - posX)
        local tmpCell = self._sortTb[index]
        if minAbs < 0 or minAbs > absDis then
            minAbs = absDis
            topCellPos = posX
        end
        if tmpCell then
            tmpCell.idx = index
            tmpCell.posX = posX
            tmpCell.absDis = absDis
        end
    end
    table.sort(
        self._sortTb,
        function(a, b)
            return a.absDis > b.absDis
        end
    )
    for index, value in ipairs(self._sortTb) do
        local item = self._items[value.idx]
        local itemGo = item:GetGameObject()
        itemGo.transform:SetSiblingIndex(index - 1)
        if index == self._skinsCellCount then
            item:SetIsOnTop(true)
        else
            item:SetIsOnTop(false)
        end
        local absToTop = math.abs(value.posX - topCellPos)
        local orderLayer = self:_CalSkinListOrderLayer(absToTop + 1)
        item:SetOrderLayer(orderLayer)
    end
end
-----------region buy---------------
function UIPetSkinsMainController:BuyBtnOnClick(go)
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        if self._shopGoodData then
            local itemtType = self._shopGoodData:GetType()
            if itemtType == SkinsPayType.Yaojing then ---耀晶购买 要弹确认窗
                self:_buyConfirmForYaojing()
            else
                self:_goBuyFunc()
            end
        end
    end
end
function UIPetSkinsMainController:binderNormalBuyBtnOnClick(go)
    self:BuyBtnOnClick(go)
end
function UIPetSkinsMainController:binderCurrencyBuyBtnOnClick(go)
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        if self._shopGoodData then
            self:OnCurrencyBtnOnClick()
        end
    end
end
function UIPetSkinsMainController:OnCurrencyBtnOnClick()
    local binderItem = self._shopGoodData:GetBinderSkin()
    local midasId = binderItem:GetMidasId()
    if string.isnullorempty(midasId) then
        GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "midasId_is_empty")
        Log.fatal("###[UIPetSkinsMainController] [Pay] midasId can't be empty")
        return
    end
    self:StartTask(
        function(TT)
            local ret = self._shopModule:CEventBuyPetSkin(TT, binderItem:GetId())
            if ClientShop.CheckShopCode(ret:GetResult()) then
                self:CanCharge(midasId, binderItem)
            end
        end,
        self
    )
end
function UIPetSkinsMainController:_buyConfirmForYaojing()
    --"是否消耗<color=#ff6b08>{1}</color>耀晶为{2}购买时装"{3}"？"
    --"是否消耗<color=#ff6b08>{1}</color>耀晶为{2}购买典藏时装"{3}"？"
    local price = self._shopGoodData:GetPrice()
    local petName = StringTable.Get(self._cfgPet.Name)
    local cfgSkin = Cfg.cfg_pet_skin[self._curSelSkinId]
    local skinName = ""
    local msgStrKey = ""
    if cfgSkin then
        skinName = StringTable.Get(cfgSkin.SkinName)
        if cfgSkin.SkinType == PetSkinFlag.PSF_NORMAL then
            msgStrKey = "str_shop_skin_confirm_to_buy_1"
        elseif cfgSkin.SkinType == PetSkinFlag.PSF_COLLECTION then
            msgStrKey = "str_shop_skin_confirm_to_buy_2"
        end
    end
    local strText = StringTable.Get(msgStrKey, price, petName, skinName)

    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        strText,
        function(param)
            self:_goBuyFunc()
        end,
        nil,
        nil,
        nil
    )
end
function UIPetSkinsMainController:_goBuyFunc()
    -- do
    --     self:_ShowSkinObtain(self._curSelSkinId)
    --     return
    -- end
    if self._openType == PetSkinUiOpenType.PSUOT_SHOW_LIST then
    elseif self._openType == PetSkinUiOpenType.PSUT_SHOP_DETAIL then
        if self._shopGoodData then
            local itemtType = self._shopGoodData:GetType()
            if itemtType == SkinsPayType.Currency then ---礼包直购
                local midasId = self._shopGoodData:GetMidasId()
                if string.isnullorempty(midasId) then
                    GameGlobal.GetUIModule(ShopModule):ReportPayStep(
                        PayStep.ClickPurchaseButton,
                        false,
                        -1,
                        "midasId_is_empty"
                    )
                    Log.fatal("### [Pay]midasId can't be empty")
                    --self:CloseDialog()
                    return
                end
                self:StartTask(
                    function(TT)
                        local ret = self._shopModule:CEventBuyPetSkin(TT, self._shopGoodData:GetId())
                        if ClientShop.CheckShopCode(ret:GetResult()) then
                            self:CanCharge(midasId, self._shopGoodData)
                        end
                    end,
                    self
                )
            elseif itemtType == SkinsPayType.Yaojing then ---消耗耀晶购买礼包
                local price = self._shopGoodData:GetPrice()
                if
                    self._clientShop:CheckEnoughYJ(
                        price,
                        true,
                        function()
                            self:CloseDialog()
                        end
                    )
                 then
                    self:RequestBuySkin()
                else
                    --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "Yaojing_not_enough")
                    --self:CloseDialog()
                end
            elseif itemtType == SkinsPayType.Guangpo then ---消耗光珀购买礼包
                local price = self._shopGoodData:GetPrice()
                if self._clientShop:CheckEnoughGP(price) then
                    self:RequestBuySkin()
                else
                    --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "Guangpo_not_enough")
                    self:CloseDialog()
                end
            elseif itemtType == SkinsPayType.Item then
                local mRole = self:GetModule(RoleModule)
                local price = self._shopGoodData:GetPrice()
                local assetId = self._shopGoodData:GetPriceItemId()
                local count = mRole:GetAssetCount(assetId)
                if count and price and (count >= price) then
                    self:RequestBuySkin()
                else
                    --GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "item_not_enough")
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        "",
                        StringTable.Get("str_pay_item_not_enough")
                    )
                end
            elseif itemtType == SkinsPayType.Free then --免费礼包，直接发消息
                self:RequestBuySkin()
            else
                Log.fatal("### invalid SkinsPayType. itemtType=", itemtType)
            end
        end
    end
end
function UIPetSkinsMainController:RequestBuySkin()
    self:StartTask(
        function(TT)
            self:Lock("UIPetSkinsMainControllerRequestBuySkin")
            local id = self._shopGoodData:GetId()
            local ret = self._shopModule:CEventBuyPetSkin(TT, id)
            if ClientShop.CheckShopCode(ret:GetResult()) then
                self._clientShop:SendProtocal(TT, ShopMainTabType.Skins)
                self:_ShowSkinObtain(self._curSelSkinId)
                self:_ForceRefreshUi()
            end
            self:UnLock("UIPetSkinsMainControllerRequestBuySkin")
            --self:CloseDialog()
        end,
        self
    )
end
function UIPetSkinsMainController:_OnCurrencyBuySkinSuccess()
    self:_ShowSkinObtain(self._curSelSkinId)
end
function UIPetSkinsMainController:_ShowSkinObtain(skinId)
    local roleAsset = RoleAsset:New()
    roleAsset.assetid = skinId
    roleAsset.count = 1
    local tempPets = {roleAsset}
    self:ShowDialog(
        "UIPetSkinObtainController",
        roleAsset,
        function()
            GameGlobal.UIStateManager():CloseDialog("UIPetSkinObtainController")
            self:_ConfirmToUseNewSkin()
        end
    )
end

function UIPetSkinsMainController:testbtnOnClick()
    local id = 90303
    local roleAsset = RoleAsset:New()
    roleAsset.assetid = id
    roleAsset.count = 1
    local tempPets = {roleAsset}
    self:ShowDialog(
        "UIPetSkinObtainController",
        roleAsset,
        function()
            
        end
    )
end

function UIPetSkinsMainController:CanCharge(midasId, buyItem)
    self:Lock("UIPetSkinsMainController_CanCharge")
    GameGlobal.TaskManager():StartTask(self.CanChargeCoro, self, midasId, buyItem)
end
function UIPetSkinsMainController:CanChargeCoro(TT, midasId, buyItem)
    local roleModule = GameGlobal.GetModule(RoleModule)
    if not roleModule:IsJapanZone() then
        self:StartTask(self.BuyGoodsTask, self, midasId, 1, buyItem)
        self:UnLock("UIPetSkinsMainController_CanCharge")
        return
    end
    ---@type PayModule
    local payModule = GameGlobal.GetModule(PayModule)
    --判断是否选择了年龄
    if payModule:NeedSelectAge(TT) then
        self:ShowDialog("UISetAgeConfirmController")
        self:UnLock("UIPetSkinsMainController_CanCharge")
        return
    end
    self:StartTask(self.BuyGoodsTask, self, midasId, 1, buyItem)
    self:UnLock("UIPetSkinsMainController_CanCharge")
end
function UIPetSkinsMainController:BuyGoodsTask(TT, itemId, itemCount, buyItem)
    local mPay = self:GetModule(PayModule)
    if IsAndroid() or IsUnityEditor() or IsPc() then --安卓环境下
        if H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_Inland then
            local res, replyEvent = mPay:SendBuyGoodsRequest(TT, itemId, itemCount)
            Log.debug("UIDemoPayController:BuyGoodsTask IsAndroid start res ", res.m_result)
            if not res:GetSucc() then --购买物品请求失败
                if res.m_result == PayErrorCode.PAY_ERROR_NOT_USE_MIDAS then
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        "",
                        StringTable.Get("str_pay_direct_buy_need_open_switch")
                    )
                else
                    PopupManager.Alert(
                        "UICommonMessageBox",
                        PopupPriority.Normal,
                        PopupMsgBoxType.Ok,
                        "",
                        StringTable.Get("str_pay_direct_buy_fail_try_later")
                    )
                end
            elseif not replyEvent then
                Log.debug("UIDemoPayController:BuyGoodsTask failed no replyEvent")
            elseif res.m_result == PayErrorCode.PAY_SUCC then
                local token = replyEvent.token
                local url = replyEvent.url_params
                Log.debug("UIDemoPayController:BuyGoodsTask success token ", token, " url ", url)
                mPay:BuySkinGoodsByUrl(url, buyItem)
            end
        elseif H3DGCloudLuaHelper.MsdkStatus == MSDKStatus.MS_International then
            mPay:BuyGoodsBySkinShopItem(buyItem, itemCount)
        end
    elseif IsIos() then
        mPay:BuyGoodsBySkinShopItem(buyItem, itemCount)
    end
end
-----------region buy end---------------
-------region drag 3d------
function UIPetSkinsMainController:_3dDrag(eventData)
    if self._modelShowMng then
        self._modelShowMng:OnDrag(eventData)
    end
end
-------region drag 3d end------

-------region anim--------
function UIPetSkinsMainController:PlayLeftOut()
    self:Lock("UIPetSkinsMainController:PlayLeftOut")
    if self._uiAnim and self._bgAnim then
        self._uiAnim:Play(self._animNames.left_out.name_ui)
        self._bgAnim:Play(self._animNames.left_out.name_bg)
    end
    self._timeEvents._leftOutTimeEvent =
        GameGlobal.Timer():AddEvent(
        self._animNames.left_out.time_len,
        function()
            self:UnLock("UIPetSkinsMainController:PlayLeftOut")
        end
    )
end
function UIPetSkinsMainController:PlayLeftIn()
    self:Lock("UIPetSkinsMainController:PlayLeftIn")
    if self._uiAnim and self._bgAnim then
        self._uiAnim:Play(self._animNames.left_in.name_ui)
        self._bgAnim:Play(self._animNames.left_in.name_bg)
    end
    self._timeEvents._leftInTimeEvent =
        GameGlobal.Timer():AddEvent(
        self._animNames.left_in.time_len,
        function()
            self:UnLock("UIPetSkinsMainController:PlayLeftIn")
        end
    )
end
function UIPetSkinsMainController:PlayRightOut()
    self:Lock("UIPetSkinsMainController:PlayRightOut")
    if self._uiAnim and self._bgAnim then
        self._uiAnim:Play(self._animNames.right_out.name_ui)
        self._bgAnim:Play(self._animNames.right_out.name_bg)
    end
    self._timeEvents._rightOutTimeEvent =
        GameGlobal.Timer():AddEvent(
        self._animNames.right_out.time_len,
        function()
            self:UnLock("UIPetSkinsMainController:PlayRightOut")
        end
    )
end
function UIPetSkinsMainController:PlayRightIn()
    self:Lock("UIPetSkinsMainController:PlayRightIn")
    if self._uiAnim and self._bgAnim then
        self._uiAnim:Play(self._animNames.right_in.name_ui)
        self._bgAnim:Play(self._animNames.right_in.name_bg)
    end
    self._timeEvents._rightInTimeEvent =
        GameGlobal.Timer():AddEvent(
        self._animNames.right_in.time_len,
        function()
            self:UnLock("UIPetSkinsMainController:PlayRightIn")
        end
    )
end

function UIPetSkinsMainController:OpenShop()
    self:CloseDialog()
end
-------region anim end

-------region story qa--------
function UIPetSkinsMainController:StoryInfoBtnOnClick()
    local curUiData = self._uiSkinsData[self._curSelSkinIndex]
    local skinCfg = self._petSkinCfg[self._curSelSkinIndex]

    if curUiData and skinCfg then
        if curUiData:IsObtained() then
            --判断是否是第一次观看
            local isFirst = not curUiData:IsUnlockCg()
            self:_ConfirmToPlayCurSelSkinStory(isFirst)
        else
            ToastManager.ShowToast(StringTable.Get("str_pet_skin_story_lock_buy"))
        end
    end
end
-------region story end--------