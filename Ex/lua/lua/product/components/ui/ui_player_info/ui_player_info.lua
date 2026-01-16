---@class PlayerInfoType
---名片展示页面类型
local PlayerInfoType = {
    --玩家编辑状态
    PlayerEdit = 1,
    --查看好友
    Friend = 2,
    --查看陌生人
    Stranger = 3,
    --查看黑名单
    BlackList = 4,
    --查看玩家自身名片
    PlayerPreview = 5,
}

_enum("PlayerInfoType", PlayerInfoType)

---@class PlayerInfoType
---名片展示页面来源
local PlayerInfoFrom = {
    MainLobby = 1,      --主界面进入
    Chat = 2,           --好友界面进入
    WorldBoss = 3,      --灾典界面进入
}

_enum("PlayerInfoFrom", PlayerInfoFrom)

---@class UIPlayerInfoController:UIController
_class("UIPlayerInfoController", UIController)
UIPlayerInfoController = UIPlayerInfoController

function UIPlayerInfoController:LoadDataOnEnter(TT, res, uiParams)
    --判断页面来源
    self._from = uiParams[1]
    self._friendId = uiParams[2]
    self._chatFriendManager = uiParams[3]

    self._infoData = {}
    self._roleModule = self:GetModule(RoleModule)
    if self._from == PlayerInfoFrom.MainLobby then
        self._isFriendMode = false
        self._isPlayerEditMode = true
    elseif self._from == PlayerInfoFrom.Chat then
        self._isFriendMode = true
        self._isPlayerEditMode = false
    elseif self._from == PlayerInfoFrom.WorldBoss then
        self._isFriendMode = true
        self._isPlayerEditMode = false
    else
        --解决任务中或其他地方跳转进界面，都按照自己编辑处理逻辑
        self._isFriendMode = false
        self._isPlayerEditMode = true
    end

    self:_RequestData(TT)
    self:_RefreshData()
end

function UIPlayerInfoController:_RequestData(TT)
    self:Lock("UIPlayerInfoController_RequestData")
    --好友系统进入
    if self._isFriendMode then
        self._chatFriendManager:RequestFriendList(TT)
        local socialModule = self:GetModule(SocialModule)
        local res, tempPlayerDetailInfo = socialModule:HandleGetPlayerDetailInfo(TT, self._friendId)
        if not res:GetSucc() then
            self._chatFriendManager:HandleErrorMsgCode(res:GetResult())
            self:UnLock("UIPlayerInfoController_RequestData")
            return
        end
        ---@type social_player_detail_info
        local playerDetailInfo = tempPlayerDetailInfo
        ---@type social_player_info
        local simpleInfo = playerDetailInfo.simple_info
        ---@type ChatFriendData
        local chatFriendData =
            ChatFriendData:New(
                                    simpleInfo.pstid,
                                    simpleInfo.head,
                                    simpleInfo.head_bg,
                                    simpleInfo.frame_id,
                                    simpleInfo.level,
                                    simpleInfo.nick,
                                    false,
                                    simpleInfo.is_online,
                                    simpleInfo.create_time,
                                    0,
                                    simpleInfo.last_logout_time,
                                    simpleInfo.remark_name,
                                    simpleInfo.help_pet,
                                    simpleInfo.world_boss_info,
                                    simpleInfo.homeland_info
                                )
        ---@type ChatFriendDetailData
        self._friendDetailData = ChatFriendDetailData:New(chatFriendData, playerDetailInfo)
        ---@type ChatFriendData
        self._friendData = self._friendDetailData:GetFriendData()
    end
    --主界面进入
    if self._isPlayerEditMode then
        ---@type PlayerRoleBaseInfo
        local res = self._roleModule:Request_RoleImageInfo(TT)
        if not res:GetSucc() then
            Log.debug("###[UIPlayerInfoController] Request_RoleImageInfo Fail !")
        end
    end
    self:UnLock("UIPlayerInfoController_RequestData")
end

function UIPlayerInfoController:_RefreshData()
    if self._isPlayerEditMode then
        self._infoType = PlayerInfoType.PlayerEdit
        --刷新数据
        self._playerInfo = self._roleModule:UI_GetPlayerInfo()
        self._scheduleInfo = self._roleModule:UI_GetPlayerScheduleInfo()
        self._worldBossModule = self:GetModule(WorldBossModule)
        --head tag and icon
        local headid = self._playerInfo.m_nHeadImageID
        local cfg_head = Cfg.cfg_role_head_image[headid]
        --head bg
        local headbgid = self._playerInfo.m_nHeadColorID
        local cfg_head_bg = Cfg.cfg_player_head_bg[headbgid]
        if cfg_head_bg == nil then
            Log.debug("###playerinfo - cfg_player_head_bg is nil ! id ", headbgid)
            local bid = HelperProxy:GetInstance():GetHeadBgDefaultID()
            cfg_head_bg = Cfg.cfg_player_head_bg[bid]
        end
        --frame icon
        local frameid = self._roleModule:GetHeadFrameID()
        local cfg_head_frame = Cfg.cfg_role_head_frame[frameid]
        local frameIcon
        if cfg_head_frame then
            frameIcon = cfg_head_frame.Icon
        else
            local fid = HelperProxy:GetInstance():GetHeadFrameDefaultID()
            frameIcon = Cfg.cfg_role_head_frame[fid].Icon
        end
        self._infoData.headIconName = cfg_head.Icon
        self._infoData.headIconTag = cfg_head.Tag
        self._infoData.headBgName = cfg_head_bg.Icon
        self._infoData.headFrameIconName = frameIcon
        self._infoData.name = self._playerInfo.m_stRoleName
        --创建时间
        local unixtime = self._playerInfo.m_nCreateTime
        local dateStr = os.date("%Y/%m/%d", unixtime)
        self._infoData.createDate = dateStr
        self._infoData.level = self._playerInfo.m_player_lv
        self._infoData.showID = self._playerInfo.m_player_showid
        self._infoData.sign = self._playerInfo.m_stSignText
        self._infoData.currMissionID = self._scheduleInfo.m_player_current_missionid
        self._infoData.star = self._scheduleInfo.m_player_mission_star
        self._infoData.petCount = self._scheduleInfo.m_player_pet_count
        self._infoData.achievementPoint = self._scheduleInfo.m_player_achievement_point
        self._infoData.achievementPointAll = self._scheduleInfo.m_player_achievement_all_point
        self._infoData.towerWater = self._scheduleInfo.m_player_tower_info.tower_water
        self._infoData.towerFire = self._scheduleInfo.m_player_tower_info.tower_fire
        self._infoData.towerWood = self._scheduleInfo.m_player_tower_info.tower_wood
        self._infoData.towerThunder = self._scheduleInfo.m_player_tower_info.tower_thunder
        self._infoData.difficultyMission = self._playerInfo.m_difficulty_mission
        self._infoData.sailingMission = self._playerInfo.m_sailing_mission
        self._infoData.titleUsed = self._playerInfo.m_title_used
        self._infoData.fifureUsed = self._playerInfo.m_fifure_used
        self._infoData.dan = self._roleModule:GetWorldBossRecordDan()
        self._infoData.grading = self._roleModule:GetWorldBossRecordRank()
        --Rank
        local expID = Cfg.cfg_aircraft_values[36].IntValue
        if not expID then
            Log.debug("###[UIPlayerInfoController] expID is nil !")
        end
        local exp = GameGlobal.GetModule(RoleModule):GetAssetCount(expID)
        local rankValue = GameGlobal.GetModule(AircraftModule):GetLvByExp(exp)
        self._infoData.rankValue = rankValue
    end
    if self._isFriendMode then
        --判断界面类型
        if self._chatFriendManager:IsMyFriend(self._friendId) then
            self._infoType = PlayerInfoType.Friend
        elseif self._chatFriendManager:IsInBlackList(self._friendId) then
            self._infoType = PlayerInfoType.BlackList
        elseif self._friendId == self._roleModule:GetPstId() then
            self._infoType = PlayerInfoType.PlayerPreview
        else    
            self._infoType = PlayerInfoType.Stranger
        end

        self._infoData.headIconName, self._infoData.headIconTag = self._friendData:GetHeadIconName()
        self._infoData.headBgName = self._friendData:GetHeadBgName()
        self._infoData.headFrameIconName = self._friendData:GetHeadFrameName()
        self._infoData.name = self._friendData:GetName()
        self._infoData.createDate = self._friendData:GetCreateDateStr()
        self._infoData.level = self._friendData:GetLevel()
        self._infoData.showID = self._friendData:GetShowFriendId()
        self._infoData.sign = self._friendDetailData:GetDes()
        self._infoData.currMissionID = self._friendDetailData:GetCurrentMissionId()
        self._infoData.star = self._friendDetailData:GetStar()
        self._infoData.petCount = self._friendDetailData:GetPetCount()
        self._infoData.achievementPoint = self._friendDetailData:GetAchievementPoint()
        self._infoData.achievementPointAll = self._friendDetailData:GetAllAchievementPoint()
        self._infoData.towerWater = self._friendDetailData:GetTowerWater()
        self._infoData.towerFire = self._friendDetailData:GetTowerFire()
        self._infoData.towerWood = self._friendDetailData:GetTowerWood()
        self._infoData.towerThunder = self._friendDetailData:GetTowerThunder()
        self._infoData.difficultyMission = self._friendDetailData:GetDifficultyMission()
        self._infoData.sailingMission = self._friendDetailData:GetSailingMission()
        self._infoData.titleUsed = self._friendDetailData:GetTitleUsed()
        self._infoData.fifureUsed = self._friendDetailData:GetFifureUsed()
        self._infoData.rankValue = self._friendDetailData:GetRankValue()
        self._infoData.dan = self._friendDetailData:GetWorldBossRecordDan()
        self._infoData.grading = self._friendDetailData:GetWorldBossRecordRank()
    end
end

function UIPlayerInfoController:OnShow(uiParams)
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPlayerInfoOpen, true)

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._atlas = self:GetAsset("UIPlayerInfo.spriteatlas", LoadType.SpriteAtlas)
    
    self:_GetComponents()
    self:_OnValue()

    -- local showChangeHead = uiParams[1]
    -- --是否打开修改头像
    -- if showChangeHead then
    --     if showChangeHead == 1 then
    --         self:headOnClick()
    --     elseif showChangeHead == 2 then
    --         self:signBtnOnClick()
    --     elseif showChangeHead == 3 then
    --         self:nameBtnOnClick()
    --     elseif showChangeHead == 4 then
    --         self:btnManageHelpOnClick()
    --     end
    -- end
end

function UIPlayerInfoController:OnHide()
    self._helpPetIcon = nil

    self:DetachEvent(GameEventType.OnChapcterInfoChanged, self.OnChapcterInfoChanged)
    self:DetachEvent(GameEventType.OnPlayerHeadInfoChanged, self.OnPlayerHeadInfoChanged)
    self:DetachEvent(GameEventType.OnPlayerChangeHeadBadgeClick, self.OnPlayerHeadInfoChanged)
    self:DetachEvent(GameEventType.OnPlayerTitleInfoChanged, self.OnPlayerTitleInfoChanged)
    self:DetachEvent(GameEventType.OnPlayerEmblazonryChange, self.OnPlayerEmblazonryChange)
    self:DetachEvent(GameEventType.ChangeFriendInfoSuccess, self.ChangeFriendInfoSuccess)
    self:DetachEvent(GameEventType.HideHeadRedPoint, self.FlushRed)
    self:DetachEvent(GameEventType.HideHeadFrameRedPoint, self.FlushRed)
    self:DetachEvent(GameEventType.RefreshPlayerInfoRedPoint, self.FlushRed)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPlayerInfoOpen, false)
end

function UIPlayerInfoController:_GetComponents()
    self._cgGo = self:GetGameObject("cg")
    self._cg = self:GetUIComponent("RawImageLoader", "cg")
    self._spineGo = self:GetGameObject("spine")
    self._spine = self:GetUIComponent("SpineLoader", "spine")

    ---@type UISelectObjectPath
    local btns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    ---@type UICommonTopButton
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
            -- self:StartTask(
            --     function(TT)
            --         YIELD(TT, 300)
            --         GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPlayerInfoOpen, false)
            --     end,
            --     self
            -- )
        end,
        nil
    )

    self._nameTex = self:GetUIComponent("UILocalizationText", "name")
    self._nameRect = self:GetUIComponent("RectTransform", "nameRect")
    self._idTex = self:GetUIComponent("UILocalizationText", "id")
    self._dateTex = self:GetUIComponent("UILocalizationText", "date")
    self._lvTex = self:GetUIComponent("UILocalizationText", "lv")
    self._missionProgressTex = self:GetUIComponent("UILocalizationText", "missionProgress")
    self._missionStarTex = self:GetUIComponent("UILocalizationText", "missionStar")
    self._petCountTex = self:GetUIComponent("UILocalizationText", "petCount")
    self._achievementPointTex = self:GetUIComponent("UILocalizationText", "achievementPoint")
    self._worldBossTex = self:GetUIComponent("UILocalizationText", "worldBossTex")
    self._worldBossTexObj = self:GetGameObject("worldBossTex")
    self._worldBossLevelTex = self:GetUIComponent("UILocalizationText", "worldBossLevelTex")
    self._worldBossIcon = self:GetUIComponent("RawImageLoader", "worldBossIcon")
    self._worldBossIconObj = self:GetGameObject("worldBossIcon")
    self._worldBossNode = self:GetUIComponent("RectTransform", "worldBossNode")

    self._sailingMissionTex = self:GetUIComponent("UILocalizationText", "sailingMissionTex")
    self._difficultyMissionTex = self:GetUIComponent("UILocalizationText", "difficultyMissionTex")

    self._headIcon = self:GetUIComponent("RawImageLoader", "head")
    self._headIconRect = self:GetUIComponent("RectTransform", "head")

    self._headBgIcon = self:GetUIComponent("UICircleMaskLoader", "headbg")

    self._frameIcon = self:GetUIComponent("RawImageLoader", "frame")

    self._signTex = self:GetUIComponent("UILocalizationText", "signTex")

    self._tower_water = self:GetUIComponent("UILocalizationText", "tower_water")
    self._tower_fire = self:GetUIComponent("UILocalizationText", "tower_fire")
    self._tower_wood = self:GetUIComponent("UILocalizationText", "tower_wood")
    self._tower_thunder = self:GetUIComponent("UILocalizationText", "tower_thunder")

    self._goRedPoint = self:GetGameObject("UICommonRedPoint")
    self._titleRedPoint = self:GetGameObject("titleRed")
    self._emblazonryRedPoint = self:GetGameObject("emblazonryRed")
    --助战
    self._helpPetGO = self:GetGameObject("helpPetGO")
    self._btnManageHelp = self:GetGameObject("btnManageHelp")
    self._helppetholder = self:GetGameObject("helppetholder")
    self._friendhelppetObj = self:GetGameObject("friendhelppet")
    self._friendhelppet = self:GetUIComponent("UISelectObjectPath", "friendhelppet")

    self._helpPetIcon = {}
    for i = 1, 4 do
        self._helpPetIcon[i] = {}
        self._helpPetIcon[i].go = self:GetGameObject("helppeticon" .. i)
        self._helpPetIcon[i].icon = self:GetUIComponent("RawImageLoader", "helppeticon" .. i)
        self._helpPetIcon[i].levelObj = self:GetGameObject("helppetlevelObj" .. i)
        self._helpPetIcon[i].level = self:GetUIComponent("UILocalizationText", "helppetlevel" .. i)
        self._helpPetIcon[i].awake = self:GetUIComponent("Image", "helppetawake" .. i)
        self._helpPetIcon[i].first = self:GetUIComponent("Image", "helppet" .. i .. "f")
        self._helpPetIcon[i].second = self:GetUIComponent("Image", "helppet" .. i .. "s")
    end
    self._helppetholder = self:GetGameObject("helppetholder")
    self._noHelpTip = self:GetGameObject("noHelpTip")
    self._atlasAwake = self:GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)
    
    --头像徽章
    self._danBadgeGen = self:GetUIComponent("UISelectObjectPath", "DanBadgeSimpleGen")
    self._danBadgeGenGo = self:GetGameObject("DanBadgeSimpleGen")
    self._danBadgeGenRect = self:GetUIComponent("RectTransform", "DanBadgeSimpleGen")
    
    --rank
    self._rank = self:GetGameObject("rank")
    self._rankTex = self:GetUIComponent("UILocalizationText","rankTex")

    self._uicgGo = self:GetGameObject("uicg")
    --纹饰设置按钮
    self._emblazonrySetting = self:GetGameObject("emblazonrySetting")
    self._emblazonryBg = self:GetUIComponent("RawImageLoader", "emblazonryBg") 
    --称号设置按钮
    self._titleSetting = self:GetGameObject("titleSetting")
    self._titleIcon = self:GetUIComponent("RawImageLoader", "titleIcon") 
    self._titleIconObj = self:GetGameObject( "titleIcon") 
    self._noTitleTips = self:GetGameObject( "noTitleTips") 
    --勋章
    local medalWall = self:GetUIComponent("UISelectObjectPath", "medalWall")
    ---@type UICommonTopButton
    self._medalWall = medalWall:SpawnObject("UIMedalCard")
    if self._isPlayerEditMode then
        self._medalWall:SetData(nil)
    else
        self._medalWall:SetData(self._friendDetailData:GetMedalPlacementInfo())
    end

    --名字设置按钮
    self._nameSetting = self:GetGameObject("nameSetting")
    --好友选项
    self._friendOptions = self:GetGameObject("friendOptions")
    self._friendOptionsList = self:GetGameObject("friendOptionsList")
    self._deleteFriendItem = self:GetGameObject("deleteFriendItem")
    self._setBlackListItem = self:GetGameObject("setBlackListItem")
    self._addFriendItem = self:GetGameObject("addFriendItem")
    self._removeBlackListItem = self:GetGameObject("removeBlackListItem")
    self._changeHeadBtn = self:GetUIComponent("EmptyImage","changeHeadBtn")
    self._changeFriendNameObj = self:GetGameObject("changeFriendNameObj")

    self._friendLayout = self:GetUIComponent("RectTransform", "friendLayout")
end

function UIPlayerInfoController:_OnValue()
    --self:ShowCurrentAssistant()
    self:ShowPlayerInfo()
    self:ShowPlayerTitleAndEmblazonry()
    self:ShowScheduleInfo()
    self:FlushRed()
    self:RankValue()
    self:AttachAllEvents()
    self:SetViewFriendStatus()
    --助战特殊处理
    if self._isPlayerEditMode then
        self:SetHelpPets()
    else
        self:ShowFriendHelpPets()
    end
end

function UIPlayerInfoController:AttachAllEvents()
    self:AttachEvent(GameEventType.OnChapcterInfoChanged, self.OnChapcterInfoChanged)
    self:AttachEvent(GameEventType.OnPlayerHeadInfoChanged, self.OnPlayerHeadInfoChanged)
    self:AttachEvent(GameEventType.OnPlayerChangeHeadBadgeClick, self.OnPlayerHeadInfoChanged)
    self:AttachEvent(GameEventType.OnPlayerTitleInfoChanged, self.OnPlayerTitleInfoChanged)
    self:AttachEvent(GameEventType.OnPlayerEmblazonryChange, self.OnPlayerEmblazonryChange)
    self:AttachEvent(GameEventType.ChangeFriendInfoSuccess, self.ChangeFriendInfoSuccess)
    self:AttachEvent(GameEventType.HideHeadRedPoint, self.FlushRed)
    self:AttachEvent(GameEventType.HideHeadFrameRedPoint, self.FlushRed)
    self:AttachEvent(GameEventType.RefreshPlayerInfoRedPoint, self.FlushRed)
end
--rank积分
function UIPlayerInfoController:RankValue()
    local airModule = GameGlobal.GetModule(AircraftModule)
    local switchOpen = airModule:GetSwitchOpenState(16)
    self._rank:SetActive(switchOpen)
    if switchOpen then
        self._rankTex:SetText(self._infoData.rankValue)
    end
end
--刷新头像
function UIPlayerInfoController:OnPlayerHeadInfoChanged()
    self:_RefreshData()
    self:ShowPlayerHeadAndBg()
end

function UIPlayerInfoController:OnPlayerEmblazonryChange()
    self:_RefreshData()
    self:ShowPlayerTitleAndEmblazonry()
end

function UIPlayerInfoController:OnPlayerTitleInfoChanged()
    self:_RefreshData()
    self:ShowPlayerTitleAndEmblazonry()
end
--显示人物称号和纹饰
function UIPlayerInfoController:ShowPlayerTitleAndEmblazonry()
    --默认纹饰 
    local icon
    if self._infoData.fifureUsed == 0 then
        local _cfg = Cfg.cfg_item_fifure_extend{Order=1}
        icon = _cfg[1].PlayerInfoFifureIcon
    else
        icon = Cfg.cfg_item_fifure_extend[self._infoData.fifureUsed].PlayerInfoFifureIcon
    end
    self._emblazonryBg:LoadImage(icon)
    --默认称号
    if self._infoData.titleUsed == -1 then
        self._titleIconObj:SetActive(false)
        self._noTitleTips:SetActive(true)
    --选择后的称号
    elseif self._infoData.titleUsed == 0 then
        self._noTitleTips:SetActive(true)
        self._titleIconObj:SetActive(false)
    else
        self._noTitleTips:SetActive(false)
        self._titleIconObj:SetActive(true)
        self._titleIcon:LoadImage(Cfg.cfg_item_title_extend[self._infoData.titleUsed].ChangeTitleIcon)
    end
end

function UIPlayerInfoController:FlushRed()
    ---@type RoleModule
    --头像红点
    local roleModule = self:GetModule(RoleModule)
    local canUnLock = roleModule:HasCanUnLock()
    self._goRedPoint.gameObject:SetActive(canUnLock)
    --纹饰
    local itemModule = self:GetModule(ItemModule)
    local titleNew = itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Title, true) 
    self._titleRedPoint:SetActive(titleNew)
    local emblazonryNew = itemModule:HasNewSubTypeItem(ItemSubType.ItemSubType_Fifure, true)
    self._emblazonryRedPoint:SetActive(emblazonryNew)
end
--刷新名字
function UIPlayerInfoController:OnChapcterInfoChanged()
    self:_RefreshData()
    self:ShowPlayerSignAndName()
end
--签名
function UIPlayerInfoController:ShowPlayerSignAndName()
    --name
    self._nameTex:SetText(self._infoData.name)

    --sign
    if string.isnullorempty(self._infoData.sign) then
        self._infoData.sign = StringTable.Get("str_player_info_set_your_sign")
    end
    self._signTex:SetText(self._infoData.sign)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._nameRect)
end
--显示当前助理
function UIPlayerInfoController:ShowCurrentAssistant()
    --(pet_grade,skin_id)
    local petid = self._roleModule:GetResId()

    local asIsNil = false
    self._defaultPetID = 0
    local grade
    local skin
    local asid
    if petid and petid ~= 0 then
        self._defaultPetID = petid
        if petid == -1 then
            asIsNil = true
        end
        grade = self._roleModule.m_choose_painting.pet_grade
        skin = self._roleModule.m_choose_painting.skin_id
        asid = self._roleModule.m_choose_painting.board_pet
    else
        --获取spine设置
        self._defaultPetID = Cfg.cfg_global["main_default_spine_pet_id"].IntValue
        grade = 0
        skin = 0
        asid = 0
    end

    self._uicgGo:SetActive(not asIsNil)
    if asIsNil then
        return
    end

    local petModule = self:GetModule(PetModule)
    local cfg_pet
    if grade > 0 then
        cfg_pet = Cfg.cfg_pet_grade {PetID = self._defaultPetID, Grade = grade}[1]
    else
        cfg_pet = Cfg.cfg_pet[self._defaultPetID]
    end
    local resName = ""
    --获取设置，设置bg
    local flagValue = self._roleModule:GetExtFlag(CharExtFlag.CEFT_MAIN_UI_SHOW_SPINE)
    --默认改为静态,任务11722
    flagValue = true
    ---@type MatchPet
    if cfg_pet then
        --看板娘qa
        --如果有看板娘的话显示看板娘
        if asid and asid ~= 0 then
            local cfg_as = Cfg.cfg_only_assistant[asid]
            if not cfg_as then
                Log.error("###[UIPlayerInfoController] cfg_as is nil ! id --> ",asid)
            end
            if flagValue then
                resName = cfg_as.CG
            else
                resName = cfg_as.Spine
            end
        else
            if flagValue then
                resName = HelperProxy:GetInstance():GetPetStaticBody(self._defaultPetID,grade,skin,PetSkinEffectPath.NO_EFFECT)--时装暂未应用
            else
                resName = HelperProxy:GetInstance():GetPetSpine(self._defaultPetID,grade,skin,PetSkinEffectPath.NO_EFFECT)--时装暂未应用
            end
        end
    else
        Log.fatal("###[UIPlayerInfoController] cfg_pet is nil ! id == ", self._defaultPetID)
        if flagValue then
            resName = self._defaultPetID .. "_cg"
        else
            resName = self._defaultPetID .. "_spine_idle"
        end
    end
    --默认false
    if flagValue then
        self._spineGo:SetActive(false)
        self._cgGo:SetActive(true)

        local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue
        self._cgGo:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        self._cg:LoadImage(resName)
        UICG.SetTransform(self._cgGo.transform, "UIMainLobbyController", resName)
    else
        self._spineGo:SetActive(true)
        self._cgGo:SetActive(false)

        self._spine:LoadSpine(resName)
        UICG.SetTransform(self._spineGo.transform, "UIMainLobbyController", resName)
    end
end
--显示人物简介
function UIPlayerInfoController:ShowPlayerInfo()
    --sign,name
    self:ShowPlayerSignAndName()
    --head
    self:ShowPlayerHeadAndBg()

    --id
    local id = self._infoData.showID
    self._idTex:SetText("ID:" .. id)
    --lv,exp
    self:LevelExp()
    --date
    self:ShowDate()
end
--创建日期
function UIPlayerInfoController:ShowDate()
    self._dateTex:SetText(self._infoData.createDate)
end
--显示人物头像和背景
function UIPlayerInfoController:ShowPlayerHeadAndBg()
    self._headIcon:LoadImage(self._infoData.headIconName)
    self._headBgIcon:LoadImage(self._infoData.headBgName)
    self._frameIcon:LoadImage(self._infoData.headFrameIconName)
    --头像徽章
    if self._infoType == PlayerInfoType.PlayerEdit then
        UIWorldBossHelper.InitSelfDanBadgeSimple(self._danBadgeGen,self._danBadgeGenGo,self._danBadgeGenRect)
    else
        UIWorldBossHelper.InitOtherDanBadgeSimple(self._danBadgeGen,self._danBadgeGenGo,self._danBadgeGenRect,self._friendData:GetWorldBossInfo())
    end
end
--等级经验
function UIPlayerInfoController:LevelExp()
    local lv = self._infoData.level
    self._lvTex:SetText(lv)
    if self._isPlayerEditMode then
        local nPlayerExp = self._roleModule:GetRoleExp()
        local expPercent = 0
        if lv == HelperProxy:GetInstance():GetMaxLevel() then
            expPercent = 1
        else
            local curLvExp = HelperProxy:GetInstance():GetLevelExp(lv)
            local nextLvExp = HelperProxy:GetInstance():GetLevelExp(lv + 1)
            local deltaExp = nextLvExp - curLvExp
            if deltaExp > 0 then
                expPercent = (nPlayerExp - curLvExp) / deltaExp
            end
        end
        ---@type ArtFont
        local txtFilling = self._lvTex.gameObject:GetComponent("ArtFont")
        txtFilling.Division = expPercent
    end
end
--显示人物数据
function UIPlayerInfoController:ShowScheduleInfo()
    --主线进度
    local currMissionID = self._infoData.currMissionID
    local cfg_mission = Cfg.cfg_mission[currMissionID]
    if cfg_mission then
        local cfgName = DiscoveryStage.GetStageIndexString(currMissionID)
        -- .. StringTable.Get(cfg_mission.Name)
        --MSG24888	【TAPD_80931536】【必现】（测试_朱文科）英文环境，个人信息界面显示战斗进度里的主线进度，主线关卡名字长就会超框，附截图	4	新缺陷	李学森, 1958	06/10/2021
        self._missionProgressTex:SetText(cfgName)
    else
        Log.fatal("###uiplayerinfo - cfg_mission is nil ! id - ", currMissionID)
        self._missionProgressTex:SetText("")
    end
    --主线星数
    local star = self._infoData.star
    self._missionStarTex:SetText(star)
    --光灵数量
    local petCount = self._infoData.petCount
    self._petCountTex:SetText(petCount)
    --成就点数
    local achievementPoint = self._infoData.achievementPoint
    local achievementPointAll = self._infoData.achievementPointAll
    self._achievementPointTex:SetText(achievementPoint .. "/" .. achievementPointAll)
    --属性塔
    self._tower_water:SetText(
        string.format(
            StringTable.Get("str_tower_cur_layer"),
            self._infoData.towerWater
        )
    )
    self._tower_fire:SetText(
        string.format(
            StringTable.Get("str_tower_cur_layer"),
            self._infoData.towerFire
        )
    )
    self._tower_wood:SetText(
        string.format(
            StringTable.Get("str_tower_cur_layer"),
            self._infoData.towerWood
        )
    )
    self._tower_thunder:SetText(
        string.format(
            StringTable.Get("str_tower_cur_layer"),
            self._infoData.towerThunder
        )
    )
    --困难杯数
    local diffMiss = self._infoData.difficultyMission
    self._difficultyMissionTex:SetText(diffMiss)
    --大航海
    local sailingMission = self._infoData.sailingMission
    self._sailingMissionTex:SetText(sailingMission)
    --世界boss
    local dan = self._infoData.dan
    local grading = self._infoData.grading
    local danName = UIWorldBossHelper.GetDanName(dan, grading)
    if UIWorldBossHelper.IsNoDan(dan,grading) then--无段位
        --self._worldBossIcon:LoadImage("1601191_logo")
        self._worldBossIconObj:SetActive(false)
        self._worldBossLevelTex:SetText(StringTable.Get(danName))
        self._worldBossTexObj:SetActive(false)
    else
        local badgeBase = UIWorldBossHelper.GetDanBadgeBase(dan,grading)
        self._worldBossIconObj:SetActive(true)
        self._worldBossIcon:LoadImage(badgeBase)
        self._worldBossLevelTex:SetText(StringTable.Get(danName))
        self._worldBossTexObj:SetActive(true)
        self._worldBossTex:SetText(grading)
    end
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._worldBossNode)
end
--查看好友名片处理
function UIPlayerInfoController:SetViewFriendStatus()
    
    local isEditSelf = self._infoType == PlayerInfoType.PlayerEdit
    local isShowSelf = isEditSelf or self._infoType == PlayerInfoType.PlayerPreview

    self._emblazonrySetting:SetActive(isEditSelf)
    self._titleSetting:SetActive(isEditSelf)
    self._nameSetting:SetActive(isEditSelf)
    if not isEditSelf then
        self._goRedPoint:SetActive(false)
    end
    --助战
    self._btnManageHelp:SetActive(isEditSelf)
    self._helppetholder:SetActive(isEditSelf)
    self._friendhelppetObj:SetActive(not isEditSelf)
    self._changeHeadBtn.enabled = isEditSelf
    --处理好友选项
    self._friendOptions:SetActive(not isShowSelf)
    if self._infoType == PlayerInfoType.Friend then
        self._deleteFriendItem:SetActive(true)
        self._setBlackListItem:SetActive(true)
        self._addFriendItem:SetActive(false)
        self._removeBlackListItem:SetActive(false)
        --好友备注
        self._changeFriendNameObj:SetActive(true)
    elseif self._infoType == PlayerInfoType.Stranger then
        self._addFriendItem:SetActive(true)
        self._setBlackListItem:SetActive(true)
        self._deleteFriendItem:SetActive(false)
        self._removeBlackListItem:SetActive(false)
    elseif self._infoType == PlayerInfoType.BlackList then
        self._addFriendItem:SetActive(true)
        self._removeBlackListItem:SetActive(true)
        self._setBlackListItem:SetActive(false)
        self._deleteFriendItem:SetActive(false)
    else
        self._changeFriendNameObj:SetActive(false)
    end

    -- 灾典隐藏右上角【加好友】按钮
    if self._from == PlayerInfoFrom.WorldBoss then
        self._friendOptions:SetActive(false)
    end

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._friendLayout)
end

function UIPlayerInfoController:headOnClick()
    self:ShowDialog("UIChangeHeadController", self._playerInfo)
end

function UIPlayerInfoController:signBtnOnClick()
    if self._infoType ~= PlayerInfoType.PlayerEdit then
        return
    end
    self:ShowDialog("UIChangeSignController", self._playerInfo)
end

function UIPlayerInfoController:nameBtnOnClick()
    self:ShowDialog("UIChangeNameController", self._playerInfo)
end
--称号修改
function UIPlayerInfoController:titleBtnOnClick()
    self:ShowDialog("UIChangeTitleController", self._playerInfo)
end
--纹饰修改
function UIPlayerInfoController:emblazonryBtnOnClick()
    self:ShowDialog("UIChangeEmblazonryController", self._playerInfo)
end

--助战星灵信息
function UIPlayerInfoController:SetHelpPets()
    --判断助战是否开启
    local module = self:GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_HelpPet)
    if isLock then
        self._helpPetGO:SetActive(false)
        return
    end
    self._helpPetGO:SetActive(true)
    self:StartTask(
        function(TT)
            local helpPetModule = self:GetModule(HelpPetModule)
            local res = helpPetModule:RequestHelpPet_SupportInfo(TT)
            if res:GetSucc() then
                ---@type DHelpPet_PetData[]
                --元素顺序
                local _elements = {
                    [1] = ElementType.ElementType_Blue,
                    [2] = ElementType.ElementType_Red,
                    [3] = ElementType.ElementType_Green,
                    [4] = ElementType.ElementType_Yellow
                }
                local _infos = {}
                for i = 1, #_elements do
                    local elem = _elements[i]
                    local _info = helpPetModule:UI_FindSupportPet(elem)
                    if _info then
                        table.insert(_infos, _info)
                    end
                end

                if not self._helpPetIcon then --表示界面关闭了
                    return
                end
                local petModule = self:GetModule(PetModule)
                local showHelpPetCount = 4
                local noHelpPetCount = 0
                for i = 1, showHelpPetCount do
                    local helpPetIcon = self._helpPetIcon[i]
                    if helpPetIcon and _infos[i] then
                        helpPetIcon.go:SetActive(true)
                        local tempId = _infos[i] and _infos[i].m_nTemplateID or 0
                        local helpPetLevel = _infos[i].m_nLevel
                        local pet = petModule:GetPetByTemplateId(tempId)
                        if pet then
                            --根据觉醒等级换头像
                            local grade = pet:GetPetGrade()
                            local head = HelperProxy:GetInstance():GetPetHead(tempId, grade,pet:GetSkinId(),PetSkinEffectPath.HEAD_ICON_PLAYER_INFO_HELP)
                            helpPetIcon.icon:LoadImage(head)
                            helpPetIcon.icon.gameObject:SetActive(true)
                            --显示等级
                            helpPetIcon.level:SetText("Lv." .. helpPetLevel)
                            helpPetIcon.levelObj.gameObject:SetActive(true)
                            self:ShowElement(helpPetIcon, pet)
                            --觉醒等级
                            helpPetIcon.awake.gameObject:SetActive(true)
                            local spriteName = UIPetModule.GetAwakeSpriteName(tempId, grade)
                            helpPetIcon.awake.sprite = self._atlasAwake:GetSprite(spriteName)
                        else
                            helpPetIcon.icon.gameObject:SetActive(false)
                            helpPetIcon.go:SetActive(false)
                            helpPetIcon.awake.gameObject:SetActive(false)
                            helpPetIcon.levelObj.gameObject:SetActive(false)
                            helpPetIcon.first.gameObject:SetActive(false)
                            helpPetIcon.second.gameObject:SetActive(false)
                            noHelpPetCount = noHelpPetCount + 1
                        end
                    else
                        helpPetIcon.go:SetActive(false)
                        helpPetIcon.awake.gameObject:SetActive(false)
                        helpPetIcon.first.gameObject:SetActive(false)
                        helpPetIcon.second.gameObject:SetActive(false)
                        helpPetIcon.levelObj.gameObject:SetActive(false)
                        noHelpPetCount = noHelpPetCount + 1
                    end
                end
                --没有光灵出战
                if noHelpPetCount == showHelpPetCount then
                    self._helppetholder:SetActive(false)
                    self._noHelpTip:SetActive(true)
                else
                    self._helppetholder:SetActive(true)
                    self._noHelpTip:SetActive(false)
                end
            end
        end
    )
end

function UIPlayerInfoController:ShowFriendHelpPets()
    local maxPetCount = 4
    self._petList = {}
    self._friendhelppet:SpawnObjects("UIChatPetItem", maxPetCount, self._petList)
    local petList = self._friendData:GetPetDataList()
    for i = 1, maxPetCount do
        if petList and petList[i] then
            self._petList[i]:Refresh(petList[i])
        else
            self._petList[i]:Refresh(nil)
        end
    end
end

function UIPlayerInfoController:btnManageHelpOnClick()
    self:ShowDialog(
        "UIHelpPetManageController",
        function()
            --关闭管理界面要刷下信息界面
            self:SetHelpPets()
        end
    )
end

function UIPlayerInfoController:ShowElement(trans, pet)
    if pet == nil then
        return
    end
    local cfg_pet_element = Cfg.cfg_pet_element {}
    if cfg_pet_element then
        local _1stElement = pet:GetPetFirstElement()
        if _1stElement then
            trans.first.gameObject:SetActive(true)
            trans.first.sprite =
                self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[_1stElement].Icon .. "_battle")
            )
        else
            trans.first.gameObject:SetActive(false)
        end
        local _2ndElement = pet:GetPetSecondElement()
        if _2ndElement then
            trans.second.gameObject:SetActive(true)
            trans.second.sprite =
                self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[_2ndElement].Icon .. "_battle")
            )
        else
            trans.second.gameObject:SetActive(false)
        end
    end
end

function UIPlayerInfoController:idCopyOnClick(go)
    local copyid = self._infoData.showID
    HelperProxy:GetInstance():CopyString(copyid)
    ToastManager.ShowToast(StringTable.Get("str_player_info_id_copy_succ"))
end

function UIPlayerInfoController:FriendOptionsBtnOnClick()
    self._friendOptionsList:SetActive(true)
end

function UIPlayerInfoController:FriendOptionsBtnCloseOnClick()
    self._friendOptionsList:SetActive(false)
end
--添加好友
function UIPlayerInfoController:addFriendBtnOnClick(go)
    self:Lock("AddFriendBtnOnClick")
    GameGlobal.TaskManager():StartTask(function()
        ---@type SocialModule
        local socialModule = GameGlobal.GetModule(SocialModule)
        ---@type AsyncRequestRes
        local res, invtInfo = socialModule:InvitationFriend(TT, self._friendId)
        if not res:GetSucc() then
            local retCode = res:GetResult()
            if retCode == SocialErrorCode.SOCIAL_INVITATION_MUTUAL_SUCCESS then
                ToastManager.ShowToast(StringTable.Get("str_chat_is_your_friend"))
            else
                self._chatFriendManager:HandleErrorMsgCode(retCode)
            end
        else
            ToastManager.ShowToast(StringTable.Get("str_chat_send_request_add_friend_success"))
        end
        self:UnLock("AddFriendBtnOnClick") 
    end, self)
end
--删除好友
function UIPlayerInfoController:deleteFriendBtnOnClick(go)
    self:ShowDialog("UIChatDeleteFriendController", self._friendData, self._chatFriendManager)
    self._friendOptionsList:SetActive(false)
end
--移入黑名单
function UIPlayerInfoController:setBlackListBtnOnClick(go)
    if not self._friendData then
        return
    end
    self:ShowDialog("UIChatAddBlacklistController", self._friendData, self._chatFriendManager)
    self._friendOptionsList:SetActive(false)
end
--移除黑名单
function UIPlayerInfoController:removeBlackListBtnOnClick(go)
    if not self._friendData then
        return
    end
    self:ShowDialog("UIChatRemoveBlacklistController", self._friendData, self._chatFriendManager)
    self._friendOptionsList:SetActive(false)
end

function UIPlayerInfoController:ChangeFriendInfoSuccess(go)
    GameGlobal.TaskManager():StartTask(function(TT)
        self:_RequestData(TT)
        self:_RefreshData()
        self:ShowPlayerSignAndName()
        self:SetViewFriendStatus()
    end, self)
end

function UIPlayerInfoController:ChangeFriendNameBtnOnClick(go)
    if not self._friendData then
        return
    end
    self:ShowDialog("UIChatSetNoteNameController", self._friendData, self._chatFriendManager)
end
