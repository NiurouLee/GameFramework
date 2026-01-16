---@class UIN7LevelDetailsController : UIController
_class("UIN7LevelDetailsController", UIController)
UIN7LevelDetailsController = UIN7LevelDetailsController

--region 初始化相关
function UIN7LevelDetailsController:Constructor()
    self._cfg = Cfg.cfg_component_blackfist() -- 获取配置
    self._detailsCompInfo = nil -- 服务器数据
    self._curDayIndex = 0 -- 当前活动开启天数
    self._order_id = nil -- 当天通关的三种难度类别OrderId
    self._currentDetails = 0 -- 当前关卡难度
    self._cfg_blackfist_hard = nil -- 显示与光灵信息

    self._currentLevelMaxCont = 0 -- 关卡总个数
    self._currentLevelNum = 0 -- 当前关卡所在

    self._petComponents = {} -- 光灵
    self._currentLevelsCfgtab = {} -- 当前所在难度所有关卡数据列表
    self._teammateTab = {} -- 敌方队友
    self._currentLeveldate = nil -- 当前选中关卡信息
    self._difficultyDate = nil -- 敌方数据
    self._teamCfg = nil -- 当前难度所有光灵
end

function UIN7LevelDetailsController:LoadDataOnEnter(TT, res, uiParams)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self._campaignModule = GameGlobal.GetModule(CampaignModule)
    self.data = self._campaignModule:GetN7BlackFightData()
    -- 获取活动 以及本窗口需要的组件
    ---@type AsyncRequestRes
    local ret = self.data:RequestCampaign(TT)
    self._campaign = self.data.activityCampaign
    res:SetResult(ret:GetResult())
    if res and not res:GetSucc() then
        self._campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
        return
    end
    self._cfg_campaign = Cfg.cfg_campaign[self._campaign._id]
    self._detailsCompInfo = self._campaign:GetComponentInfo(ECampaignN7ComponentID.ECAMPAIGN_N7_BLACKFIST)
end

function UIN7LevelDetailsController:_GetComponent()
    --generated--
    ---@type UnityEngine.UI.Image
    self.firstbg = self:GetUIComponent("Image", "firstbg")
    self.firstAttribute = self:GetUIComponent("Image", "firstAttribute")
    self.secondbg = self:GetUIComponent("Image", "secondbg")
    self.secondAttribute = self:GetUIComponent("Image", "secondAttribute")

    ---@type RawImageLoader
    self.captain = self:GetUIComponent("RawImageLoader", "captain")
    self._round = self:GetUIComponent("RawImageLoader", "Round")

    ---@type UnityEngine.GameObject
    self._lock = self:GetGameObject("lock")
    self._finish = self:GetGameObject("Finish")
    self.arrowsL = self:GetGameObject("arrowsL")
    self.arrowsR = self:GetGameObject("arrowsR")

    ---@type UILocalizationText
    self._roundText = self:GetUIComponent("UILocalizationText", "roundText")
    self._titletext = self:GetUIComponent("UILocalizationText", "titletext")
    self.dialogueText = self:GetUIComponent("UILocalizationText", "dialogueText")
    self.introduceContentText = self:GetUIComponent("UILocalizationText", "introduceContentText")
    self._recommendText2 = self:GetUIComponent("UILocalizationText", "recommendText2")
    self.integralNumberText = self:GetUIComponent("UILocalizationText", "integralNumberText")
    self._txtB = self:GetUIComponent("UILocalizationText", "txtB")

    for i = 1, 5 do
        local petComponent = {}
        petComponent = {
            self:GetUIComponent("Image", "firstAttribute" .. i),
            self:GetUIComponent("Image", "secondAttribute" .. i),
            self:GetUIComponent("RawImageLoader", "icon" .. i),
            self:GetGameObject(i - 1)
        }
        table.insert(self._petComponents, petComponent)
    end
    --generated end--
end

---@param difficultyType int 黑拳赛难度类别
function UIN7LevelDetailsController:_InitUIN7Round(difficultyType)
    local day = self._curDayIndex
    if day > self:_GetMaxDay() then
        day = 1
    end
    self._currentLevelMaxCont = self:_GetDifficultyTypeLecels(difficultyType, day) -- ToDo修改 self._curDayIndex
    local flag = 1
    for index, value in ipairs(self._currentLevelsCfgtab) do
        if self:_ComparisonContent(value.OrderId) then
            flag = index
        end
    end
    self:_ShowCurrentDifficulty(flag)
    self:_ShowEnemyDetails(self._currentLevelsCfgtab[flag])
    self._currentLeveldate = self._currentLevelsCfgtab[flag]
end

function UIN7LevelDetailsController:_GetMaxDay()
    local max = 0
    for key, value in pairs(self._cfg) do
        if value.DayIndex > max then
            max = value.DayIndex
        end
    end
    return max
end

---@private
---初始化赋值
function UIN7LevelDetailsController:_InitializeValue(uiParams)
    self._currentDetails = uiParams[1]
    self._order_id = self._detailsCompInfo.order_ids[self._currentDetails]
    if self._order_id == nil then
        self._order_id = 0
    end
    self._curDayIndex = self._detailsCompInfo.cur_day_index
end

--endregion

--region 生命周期相关
function UIN7LevelDetailsController:OnShow(uiParams)
    self:_InitializeValue(uiParams)
    -- 缓存当前难度信息
    self.data.curDifficulty = self._currentDetails
    self._module = self:GetModule(MissionModule)
    self._atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)

    self:_GetComponent()
    self:_ShowTopCommonBtn()
    --self:_InitDifficultyTeammateIcon()
    self:_InitUIN7Round(self._currentDetails)
    if self._currentLevelNum == self._currentLevelMaxCont then
        self.arrowsL:SetActive(false)
    end
    if self._currentLevelNum == 1 then
        self.arrowsR:SetActive(false)
    end
    self:_Showlock()
    local difficultyList = self.data.difficultyList
    self._txtB:SetText(difficultyList[self._currentDetails].reputaion .. "/" .. self:_GetaggreGateScore()) -- ToDo修改
    for i, v in ipairs(self._petComponents) do
        UIEventTriggerListener.Get(v[4].gameObject).onClick = function(go)
            local date = self:_GetEnemyDate()
            self:ShowDialog("UIN7EnemyDetailsController", date, i)
        end
    end
end
--endregion

--region 显示相关
function UIN7LevelDetailsController:_Showlock()
    self._finish:SetActive(false)
    if self._currentLevelNum <= self._order_id + 1 then
        self._lock:SetActive(false) -- 解锁
        if self._currentLevelNum < self._order_id + 1 then
            self._finish:SetActive(true) -- 完成
        end
    else
        self._lock:SetActive(true) -- 未解锁
    end
end

---@private
---显示通用返回
function UIN7LevelDetailsController:_ShowTopCommonBtn()
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    -- 返回按钮
    self._backBtns:SetData(
        function()
            -- self:CloseDialog()
            CutsceneManager.ExcuteCutsceneIn(
                UIStateType.UIN7LevelDetailsController,
                function()
                    self._campaignModule:CampaignSwitchState(
                        true,
                        UIStateType.UIBlackFightMain,
                        UIStateType.UIMain,
                        nil,
                        self._campaign._id
                    )
                end
            )
        end
    )
end

---@private
---当前难度关卡所在
---@type currentLevelNum int
function UIN7LevelDetailsController:_ShowCurrentDifficulty(currentLevelNum)
    self._currentLevelNum = currentLevelNum
    self._titletext:SetText(self._currentLevelNum .. "/" .. self._currentLevelMaxCont)
    self._roundText:SetText("ROUND " .. self._currentLevelNum)
end
---@private
---显示队长图标
function UIN7LevelDetailsController:_ShowLeader()
    local leader = self:GetUIComponent("UISelectObjectPath", "leader")
    self._leader = leader:SpawnObject("UITeamsLeader")
    local petIndo = pet_data:New()
    petIndo.template_id = self._teamCfg[1]
    petIndo.level = self._cfg_blackfist_hard[1].Lv
    petIndo.grade = self._cfg_blackfist_hard[1].Grade
    petIndo.awakening = self._cfg_blackfist_hard[1].Awakening
    petIndo.affinity_level = 1
    petIndo.current_skin = 0 -- current_skin不在pet_data中 用于非本地星灵
    local pet = Pet:New(petIndo)
    self._leader:Flush(pet, true)
end
---@private
---显示文本信息
function UIN7LevelDetailsController:_ShowText()
    self.integralNumberText:SetText(self._cfg_blackfist_hard[1].PrestigeItemNum) -- 积分展示
    self.dialogueText:SetText(StringTable.Get(self._cfg_blackfist_hard[1].Talk)) -- 台词
    self._recommendText2:SetText(StringTable.Get(self._cfg_blackfist_hard[1].Recommend)) -- 推荐等级
    self._round:LoadImage("n7_box_round" .. self._currentLevelNum)
end

---@private
---敌方详情显示
---@type enemyDetail 敌方详情
function UIN7LevelDetailsController:_ShowEnemyDetails(enemyDetail)
    local cfg_pet_element = Cfg.cfg_pet_element {}
    local cfg_blackfist_squads = Cfg.cfg_blackfist_squads {SquadsID = enemyDetail.SquadsID} -- petsid
    self._cfg_blackfist_hard = Cfg.cfg_blackfist_hard {HardID = enemyDetail.HardID} -- 显示和光灵信息
    self._teamCfg = {
        cfg_blackfist_squads[1].CfgPetId1,
        cfg_blackfist_squads[1].CfgPetId2,
        cfg_blackfist_squads[1].CfgPetId3,
        cfg_blackfist_squads[1].CfgPetId4,
        cfg_blackfist_squads[1].CfgPetId5
    }
    self:_ShowLeader()
    -- 关卡队列展示
    -- if self._difficultyDate == nil then
    local date = {}
    for i = 1, #self._teamCfg do
        local pet = Cfg.cfg_pet {self._teamCfg[i]}
        local petskin = Cfg.cfg_pet_skin {id = pet[1].SkinId}
        local elemt1 = nil
        local elemt2 = nil
        local petskinTeamBody = nil
        local staticBody = nil
        local battleMe = nil
        petskinTeamBody = petskin[1].TeamBody
        staticBody = petskin[1].StaticBody
        battleMe = petskin[1].BattleMes
        if pet[1].FirstElement == 0 then
            elemt1 = nil
        else
            elemt1 =
                self._atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[pet[1].FirstElement].Icon)
            )
            elemt1bg =
                self._atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite("spirit_xiangqing_icon23")
            )
        end
        if pet[1].SecondElement == 0 then
            elemt2 = nil
        else
            elemt2 =
                self._atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[pet[1].SecondElement].Icon)
            )
        end
        local tab = {
            ["elemt1"] = elemt1,
            ["elemt2"] = elemt2,
            ["skin"] = petskinTeamBody,
            ["staticBody"] = staticBody,
            ["battleMe"] = battleMe,
            ["element2NeedGrade"] = pet[1].Element2NeedGrade
        }
        table.insert(date, i, tab)
    end
    self._difficultyDate = date
    for i = 1, #self._difficultyDate do
        self:_ShowTeammate(self._difficultyDate[i], self._petComponents[i])
    end
    -- 关卡其他信息展示
    self:_ShowText()
end

---@private
---显示团队信息
function UIN7LevelDetailsController:_ShowTeammate(date, components)
    if date.elemt2 == nil or self._cfg_blackfist_hard[1].Grade ~= date.element2NeedGrade then
        components[2].gameObject:SetActive(false)
    else
        components[2].gameObject:SetActive(true)
        components[2].sprite = date.elemt2
    end
    components[1].sprite = date.elemt1
    components[3]:LoadImage(date.skin)
end

---@private
---初始化团队
function UIN7LevelDetailsController:_InitDifficultyTeammateIcon()
    local teammate = self:GetUIComponent("UISelectObjectPath", "teammate")
    teammate:SpawnObjects("UIN7TeammateItem", 5)
    self._teammateTab = teammate:GetAllSpawnList()
end
--endregion

--region 数据配置相关
---@private
---@return int 当前难度总积分
function UIN7LevelDetailsController:_GetaggreGateScore()
    local num = 0
    for k, v in pairs(self._currentLevelsCfgtab) do
        local cfg = Cfg.cfg_blackfist_hard {HardID = v.HardID}
        num = num + cfg[1].PrestigeItemNum
    end
    return num
end

---@private
---获取当前难度列表
---@param difficultyType int 黑拳赛难度类别
---@return int 难度列表个数
function UIN7LevelDetailsController:_GetDifficultyTypeLecels(difficultyType, dayIndex)
    local count = 0
    for key, value in pairs(self._cfg) do
        if value.Type == difficultyType and value.DayIndex == dayIndex then
            count = count + 1
            self._currentLevelsCfgtab[count] = value
        end
    end
    return count
end

---@private
---查看 self._detailsCompInfo.mission_infos 中是否有missionId
---是否解锁
---@return boolean
function UIN7LevelDetailsController:_ComparisonContent(orderId)
    if self._order_id == 0 then
        return false
    end
    if orderId <= self._order_id + 1 then
        return true
    end
    return false
end

function UIN7LevelDetailsController:_GetEnemyDate()
    local date = nil
    local len1 = table.count(self._difficultyDate)
    local len2 = table.count(self._teamCfg)
    if len1 == len2 then
        date = {}
        for i = 1, len1 do
            local v1 = self._teamCfg[i]
            local v2 = self._difficultyDate[i]
            local dt = {}
            dt.petid = v1
            dt.elemt1 = v2.elemt1
            dt.elemt2 = v2.elemt2
            dt.battleMe = v2.battleMe
            dt.lv = self._cfg_blackfist_hard[1].Lv
            dt.awakening = self._cfg_blackfist_hard[1].Awakening
            dt.grade = self._cfg_blackfist_hard[1].Grade
            dt.equip = self._cfg_blackfist_hard[1].Equip
            table.insert(date, dt)
        end
    end
    return date
end
--endregion

function UIN7LevelDetailsController:btnInformationOnClick(go)
    -- 跳转至敌方情报
    local date = self:_GetEnemyDate()
    if date == nil then
        return
    end
    self:ShowDialog("UIN7EnemyDetailsController", date, 1)
end

function UIN7LevelDetailsController:btnFightEnterOnClick(go)
    -- 跳转至编队或弹出飘字提示
    if self._currentLevelNum <= self._order_id + 1 then
        local data = self._campaignModule:GetN7BlackFightData()
        local ctx = self._module:TeamCtx()
        local missionId = self._currentLevelsCfgtab[self._currentLevelNum].MissionID
        local lp = data:GetComponentBlackFight()
        ctx:Init(
            TeamOpenerType.BlackFist,
            {
                missionId,
                lp:GetCampaignMissionComponentId(),
                lp:GetCampaignMissionParamKeyMap()
            }
        )
        self:Lock("DoEnterTeam")
        ctx:ShowDialogUITeams(false)
    else
        ToastManager.ShowToast(StringTable.Get("str_n7_hint"))
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N7ClickChallenge)
end

function UIN7LevelDetailsController:arrowsLOnClick(go)
    if self._currentLevelNum == self._currentLevelMaxCont then
        return
    end
    self.arrowsR:SetActive(true)
    self._currentLevelNum = self._currentLevelNum + 1
    self:_ShowEnemyDetails(self._currentLevelsCfgtab[self._currentLevelNum])
    self:_ShowCurrentDifficulty(self._currentLevelNum)
    if self._currentLevelNum == self._currentLevelMaxCont then
        self.arrowsL:SetActive(false)
    end
    self:_Showlock()
end

function UIN7LevelDetailsController:arrowsROnClick(go)
    if self._currentLevelNum == 1 then
        return
    end
    self.arrowsL:SetActive(true)
    self._currentLevelNum = self._currentLevelNum - 1
    self:_ShowEnemyDetails(self._currentLevelsCfgtab[self._currentLevelNum])
    self:_ShowCurrentDifficulty(self._currentLevelNum)
    if self._currentLevelNum == 1 then
        self.arrowsR:SetActive(false)
    end
    self:_Showlock()
end
--endregion
