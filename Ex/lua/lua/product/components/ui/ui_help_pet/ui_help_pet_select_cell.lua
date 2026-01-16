---@class UIHelpPetSelectCell:UICustomWidget
_class("UIHelpPetSelectCell", UICustomWidget)
UIHelpPetSelectCell = UIHelpPetSelectCell

function UIHelpPetSelectCell:OnShow()
    self._uiPetDeTailAtlas = self:GetAsset("UIPetDetail.spriteatlas", LoadType.SpriteAtlas)
    self._atlasAwake = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)

    self.petModule = self:GetModule(PetModule)
    self.helpPetModule = self:GetModule(HelpPetModule)
    self.loginModule = self:GetModule(LoginModule)
    --助战----------
    self.cg = self:GetUIComponent("RawImageLoader", "cg")
    self._secondBg = self:GetGameObject("secondBg") -- 副属性
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.UI.Image
    self._firstElement = self:GetUIComponent("Image", "firstElement")
    ---@type UnityEngine.UI.Image
    self._secondElement = self:GetUIComponent("Image", "secondElement")
    self._awakeCount = self:GetUIComponent("Image", "awakeCount")
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")

    --head
    self._head_bg = self:GetUIComponent("UICircleMaskLoader", "headbg")
    self._head_icon = self:GetUIComponent("RawImageLoader", "head")
    self._head_frame = self:GetUIComponent("RawImageLoader", "frame")
    self._head_icon_rect = self:GetUIComponent("RectTransform", "head")
    self._head_frame_rect = self:GetUIComponent("RectTransform", "frame")

    self._head_bg_rect = self:GetUIComponent("RectTransform", "headbg")
    self._head_bg_mask_rect = self:GetUIComponent("RectTransform", "headbgmask")
    self._head_root = self:GetUIComponent("RectTransform", "headroot")

    self.roleNameTxt = self:GetUIComponent("UILocalizationText", "rolename")
    self.yuanzhuLeiXingTxt = self:GetUIComponent("UILocalizationText", "yuanzhuleixing")
    self.zhuangbeiTxt = self:GetUIComponent("UILocalizationText", "zhuangbei")
    self._stars = self:GetUIComponent("UISelectObjectPath", "stars")
    self._levelText = self:GetUIComponent("UILocalizationText", "levelValue")
    self._shouGO = self:GetGameObject("shou")

    self._chooseGO = self:GetGameObject("choose")
    self._chooseGO:SetActive(false)
    self._imgBG = self:GetGameObject("btngo")
    local etl = UICustomUIEventListener.Get(self._imgBG)

    --头像徽章
    self._danBadgeGen = self:GetUIComponent("UISelectObjectPath", "DanBadgeSimpleGen")
    self._danBadgeGenGo = self:GetGameObject("DanBadgeSimpleGen")
    self._danBadgeGenRect = self:GetUIComponent("RectTransform", "DanBadgeSimpleGen")

    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(go)
            if self._chooseGO then
                self._chooseGO:SetActive(true)
            end
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Click,
        function(go)
            self:btngoOnClick()
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            if self._chooseGO then
                self._chooseGO:SetActive(false)
            end
        end
    )
end

function UIHelpPetSelectCell:OnHide()
end

---@type DHelpPet_PetData serverdata
function UIHelpPetSelectCell:SetData(data, index, playerData)
    ---@type DHelpPet_PetData
    self.data = data
    self.playerData = playerData
    self.index = index
    self:ConstructPet()
    self:SetHaveState()
    self:ShowStarLevel()
    self:RefreshLevelInfo()
    self:ShowElement()
    self:PlayerHeader()
end

--因为存在别人的助战星灵，所以构造一个pet
function UIHelpPetSelectCell:ConstructPet()
    local tempData = pet_data:New()
    tempData.template_id = self.data.m_nTemplateID
    tempData.current_skin = self.data.m_nSkinID
    -- current_skin不在pet_data中 用于非本地星灵
    local oriPet = Pet:New(tempData)
    -- 不要改变顺序
    tempData.grade = self.data.m_nGrade
    tempData.level = self.data.m_nLevel
    tempData.awakening = self.data.m_nAwake
    tempData.equip_lv = self.data.m_nEquipLevel
    tempData.equip_refine_lv = self.data.m_nEquipRefineLevel
    oriPet:SetData(tempData)
    oriPet:CalAttr()
    local pet,isEnhanced = UIPetModule.ProcessSinglePetEnhance(oriPet)
    self:RefreshEnhanceFlagArea(isEnhanced)
    self.pet = pet
end
--有人状态
function UIHelpPetSelectCell:SetHaveState()
    --大图
    if not self.pet then
        return
    end
    local petId = self.pet:GetTemplateID()
    local cfgv = Cfg.cfg_pet[petId]
    local grade = self.pet:GetPetGrade()
    local skinId = self.pet:GetSkinId()
    if not cfgv then
        Log.fatal("### [error] cfg_pet no pet. id = [", petId, "]")
    end
    -- local helpIcon = cfgv.HelpIcon
    local helpIcon = HelperProxy:GetInstance():GetPetVideo(petId, grade, skinId, PetSkinEffectPath.CARD_HELP_SELECT)
    if helpIcon then
        self.cg:LoadImage(helpIcon)
    else
        Log.fatal("### [error] pet [", petId, "] no helpIcon")
    end
end

-- 上阵助战星灵
function UIHelpPetSelectCell:btngoOnClick()
    local _module = self:GetModule(MissionModule)
    local ctx = _module:TeamCtx()
    local _teams = ctx:Teams()
    local curTeamId = ctx:GetCurrTeamId()
    if _teams then
        local team = _teams:Get(curTeamId) -- 当前队伍
        if team then
            local count = 0
            for index, pstid in ipairs(team:GetPets()) do
                if index < 5 and pstid <= 0 then
                    count = count + 1
                end
            end
            --前四名都是空则弹提示
            if count == 4 then
                ToastManager.ShowToast(StringTable.Get("str_help_pet_xyjfgl"))
                return
            end

            if self:_CheckReplaceSpPet(team) then
                --助战星灵需要替换普通编队的星灵
                return
            end
        end
    end
    --设置上阵的星灵
    local firstAttr = self.pet:GetPetFirstElement()
    self.helpPetModule:UI_SetSelectHelpPetPstId(firstAttr, self.data.m_nPstID)
    GameGlobal.UIStateManager():CloseDialog("UITeamChangeController")
    GameGlobal.UIStateManager():CloseDialog("UIHelpPetSelectController")
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, curTeamId)
end

-- 助战星灵详情
function UIHelpPetSelectCell:btndetailOnClick()
    self:ShowDialog("UIHelpPetInfoController", self.data)
end

function UIHelpPetSelectCell:RefreshLevelInfo()
    local curGrateMaxLevel = self.pet:GetMaxLevel()
    local curLevel = self.pet:GetPetLevel()
    self._levelText:SetText(curLevel)
    self.nameTxt:SetText(StringTable.Get(self.pet:GetPetName()))
    --curLevel .. "<size=45><color=#acacac>/</color><color=#f96601>" .. curGrateMaxLevel .. "</color></size>"
end

function UIHelpPetSelectCell:ShowStarLevel()
    local petStar = self.pet:GetPetStar()
    local awakenStep = self.pet:GetPetAwakening()
    self._stars:SpawnObjects("UIPetIntimacyStar", petStar)
    local stars = self._stars:GetAllSpawnList()
    for i = 1, #stars do
        stars[i]:Refresh(i <= awakenStep)
    end

    -- for i = 1, 6 do
    --     local starImg = self:GetUIComponent("Image", "star" .. i)
    --     if i <= petStar then
    --         starImg.gameObject:SetActive(true)
    --         if i <= awakenStep then
    --             starImg.sprite = self._uiPetDeTailAtlas:GetSprite("spirit_xiangqing_icon22")
    --         else
    --             starImg.sprite = self._uiPetDeTailAtlas:GetSprite("spirit_xiangqing_icon21")
    --         end
    --     else
    --         starImg.gameObject:SetActive(false)
    --     end
    -- end

    --跃迁
    local pet = self.pet
    local petId = pet:GetTemplateID()
    local awaken = pet:GetPetGrade()
    local spriteName = UIPetModule.GetAwakeSpriteName(petId, awaken)
    self._awakeCount.sprite = self._atlasAwake:GetSprite(spriteName)
end

function UIHelpPetSelectCell:ShowElement()
    local cfg_pet_element = Cfg.cfg_pet_element {}

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
        else
            self._secondElement.gameObject:SetActive(false)
            self._secondBg:SetActive(false)
        end
    end
end
---@type DHelpPet_PetData m_nPlayerID
function UIHelpPetSelectCell:PlayerHeader()
    local headIcon = HelperProxy:GetInstance():GetHeadIconDefaultID()
    local headBg = HelperProxy:GetInstance():GetHeadBgDefaultID()
    local headFrame = HelperProxy:GetInstance():GetHeadFrameDefaultID()
    local playerNick = ""
    if self.playerData then
        headIcon = self.playerData.head
        headBg = self.playerData.head_bg
        headFrame = self.playerData.frame_id
        playerNick = self.playerData.nick

        -- 系统或好友援助显示id
        if self.data.m_nSourceType == EnumHelpSourceType.E_HelpSource_System then
            local showID = self.loginModule:GetShowIdByPstId(self.playerData.pstid)
            self.yuanzhuLeiXingTxt:SetText("ID : " .. showID)
            self._shouGO:SetActive(false)
        elseif self.data.m_nSourceType == EnumHelpSourceType.E_HelpSource_Friend then
            self.yuanzhuLeiXingTxt:SetText(StringTable.Get("str_help_pet_hyyz"))
            self._shouGO:SetActive(true)
        end
    else
        -- 缺省援助不显示内容
        if UNITY_DEBUG then
            if self.data.m_nSourceType == EnumHelpSourceType.E_HelpSource_Default then
                self.yuanzhuLeiXingTxt:SetText(self.data.m_nTemplateID)
            else
                local showID = self.loginModule:GetShowIdByPstId(self.data.m_nPlayerID)
                self.yuanzhuLeiXingTxt:SetText(showID)
            end
        else
            self.yuanzhuLeiXingTxt:SetText("")
        end
        self._shouGO:SetActive(false)
        local randomUserID =
            GameGlobal.UIStateManager():CallUIMethod("UIHelpPetSelectController", "GetRandomDefaultUserID")
        local randomUserCfg = Cfg.cfg_help_pet_default_users[randomUserID]
        headIcon = randomUserCfg.HeadID
        playerNick = StringTable.Get(randomUserCfg.NameKey)
    end

    -- 角色名字
    self.roleNameTxt:SetText(playerNick)
    -- 角色头像
    self:SetHead(headIcon, headBg, headFrame)
    -- 装备等级
    local equipLevel = self.data.m_nEquipLevel
    if self.pet then
        equipLevel = self.pet:GetEquipLv()
    end
    if equipLevel > 0 then
        -- self.zhuangbeiTxt:SetText(StringTable.Get("str_help_pet_lglv", self.data.m_nEquipLevel))
        self.zhuangbeiTxt.gameObject:SetActive(false)
        self:_SetEquipLv()
    else
        self.zhuangbeiTxt:SetText(StringTable.Get("str_help_pet_wlg"))
    end

    --头像徽章
    if self.playerData then
        local roleWorldBossInfo = self.playerData.world_boss_info
        UIWorldBossHelper.InitOtherDanBadgeSimple(
            self._danBadgeGen,
            self._danBadgeGenGo,
            self._danBadgeGenRect,
            roleWorldBossInfo
        )
    else
        if self._danBadgeGenGo then
            self._danBadgeGenGo:SetActive(false)
        end
    end

    self:UnLock("HelpPet_HandleSearchFriend")
end

function UIHelpPetSelectCell:_SetEquipLv()
    local obj = UIWidgetHelper.SpawnObject(self, "_equipLv", "UIPetEquipLvIcon")
    obj:SetData(self.pet, true, "Lv.")
end

function UIHelpPetSelectCell:SetHead(head, headbg, frame)
    -- local headIcon = playerInfo.head
    local headIcon = head
    local cfg_header = Cfg.cfg_role_head_image[headIcon]
    if cfg_header then
        self._head_icon:LoadImage(cfg_header.Icon)
        HelperProxy:GetInstance():GetHeadIconSizeWithTag(self._head_icon_rect, cfg_header.Tag)
    else
        Log.fatal("###main - cfg_header is nil ! id - ", headIcon)
    end

    local headFrame = frame
    if not headFrame or headFrame == 0 then
        Log.warn("[Tower] 找不到头像框，使用默认1001。id：", frame)
        headFrame = HelperProxy:GetInstance():GetHeadFrameDefaultID()
    end
    local cfg_head_frame = Cfg.cfg_role_head_frame[headFrame]
    self._head_frame:LoadImage(cfg_head_frame.Icon)

    HelperProxy:GetInstance():GetHeadBgSizeWithTag(self._head_bg_rect)
    HelperProxy:GetInstance():GetHeadBgMaskSizeWithTag(self._head_bg_mask_rect)
    HelperProxy:GetInstance():GetHeadFrameSizeWithTag(self._head_frame_rect)
    HelperProxy:GetInstance():GetHeadRootSizeWithTag(self._head_root, RoleHeadFrameSizeType.Size1)

    -- local headBg = playerInfo.head_bg
    local headBg = headbg
    local cfg_head_bg = Cfg.cfg_player_head_bg[headBg]
    if not cfg_head_bg then
        local bid = HelperProxy:GetInstance():GetHeadBgDefaultID()

        cfg_head_bg = Cfg.cfg_player_head_bg[bid]
    end
    self._head_bg:LoadImage(cfg_head_bg.Icon)
end

---@param team Team
function UIHelpPetSelectCell:_CheckReplaceSpPet(team)
    local pets = {}
    for i, petPstID in ipairs(team:GetPets()) do
        if petPstID and petPstID > 0 then
            local pet = self.petModule:GetPet(petPstID)
            table.insert(pets,pet:GetTemplateID())
            -- pets[i] = pet:GetTemplateID()
        end
    end
    if next(pets) then
        local inner, sp = HelperProxy:GetInstance():CheckBinderID(pets, self.data.m_nTemplateID)
        if inner then
            local pet = self.petModule:GetPetByTemplateId(sp)
            self:StartTask(self._ReqReplace, self, pet:GetPstID())
            return true
        end
    end
    return false
end

function UIHelpPetSelectCell:_ReqReplace(TT, bReplacedPetPstID)
    ---@type UITeamChangeController
    local controller = GameGlobal.UIStateManager():GetController("UITeamChangeController")
    controller:HelpPetReplaceFormationPet(TT, self.data, bReplacedPetPstID)

    --设置上阵的星灵
    local firstAttr = self.pet:GetPetFirstElement()
    self.helpPetModule:UI_SetSelectHelpPetPstId(firstAttr, self.data.m_nPstID)
    GameGlobal.UIStateManager():CloseDialog("UITeamChangeController")
    GameGlobal.UIStateManager():CloseDialog("UIHelpPetSelectController")

    local _module = self:GetModule(MissionModule)
    local ctx = _module:TeamCtx()
    local _teams = ctx:Teams()
    local curTeamId = ctx:GetCurrTeamId()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryChangeTeamData, curTeamId)
end

function UIHelpPetSelectCell:RefreshEnhanceFlagArea(isEnhanced)
    local flagGo = self:GetGameObject("EnhanceFlagArea")
    local flagSop = self:GetUIComponent("UISelectObjectPath", "EnhanceFlagArea")
    if not flagGo then
        return
    end
    flagGo:SetActive(isEnhanced)
    if isEnhanced then
        local flagWidget = flagSop:SpawnObject("UIPetEnhancedFlag")
    else
    end
end