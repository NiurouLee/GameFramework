---@class UISailingLevelDetail:UIController
_class("UISailingLevelDetail", UIController)
UISailingLevelDetail = UISailingLevelDetail

function UISailingLevelDetail:LoadDataOnEnter(TT, res, uiParams)
    ---@type SailingMissionModule
    self._sailingMissionModule = GameGlobal.GetModule(SailingMissionModule)
    self._sailingMissionModule:HandleGetSailingMissionData(TT)
end

function UISailingLevelDetail:OnShow(uiParams)
    self._layerId = uiParams[1]
    self._missionId = uiParams[2]
    self._sailingMissionModule:CacheFilterPetsLayerAndMissionId(self._layerId, self._missionId)
    local cfg = Cfg.cfg_sailing_mission[self._missionId]
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIStage.spriteatlas", LoadType.SpriteAtlas)
    self._nameLabel = self:GetUIComponent("UILocalizationText", "Name")
    self._reLvLabel = self:GetUIComponent("UILocalizationText", "ReLv")
    self._iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
    self._element1Img = self:GetUIComponent("Image", "Element1")
    self._element2Img = self:GetUIComponent("Image", "Element2")
    self._element1Go = self:GetGameObject("Element1")
    self._element2Go = self:GetGameObject("Element2")
    self._alpha = self:GetUIComponent("CanvasGroup","word")
    self._team = self:GetUIComponent("UISelectObjectPath","team")
    local enemyInfo = self:GetUIComponent("UISelectObjectPath", "enemyInfo")
    ---@type UIStageEnemy
    self._enemyObj = enemyInfo:SpawnObject("UIStageEnemy")

    local recommendAwaken = cfg.RecommendAwaken
    local recommendLV = cfg.RecommendLV
    self._reLvLabel:SetText(StringTable.Get("str_sailing_mission_level_detail_awaken_and_level", recommendAwaken, recommendLV))
    
    local color = Color(1, 1, 1, 1)
    local enemyTitleBgSprite = nil
    local enemyTitleBg2Sprite = nil
    if cfg.type == 2 then
        color = Color(54 / 255, 54 / 255, 54 / 255, 1)
        enemyTitleBgSprite = self._atlas:GetSprite("map_guanqia_tiao3")
        enemyTitleBg2Sprite = self._atlas:GetSprite("map_guanqia_tiao4")
    else
        color = Color(54 / 255, 54 / 255, 54 / 255, 1)
        enemyTitleBgSprite = self._atlas:GetSprite("map_bantou4_frame")
        enemyTitleBg2Sprite = self._atlas:GetSprite("map_bantou15_frame")
    end

    self._enemyObj:Flush(
        recommendAwaken,
        recommendLV,
        cfg.FightLevel,
        color,
        enemyTitleBgSprite,
        enemyTitleBg2Sprite,
        true,
        true
    )

    self._tb = {}
    local buff = cfg.BaseWordBuff
    if buff then
        for _, wordId in ipairs(buff) do
            table.insert(self._tb, self:GetWordDesc(cfg.ID, wordId))
        end
    end
    self._show = (#self._tb ~= 0)
    if self._show then
        self._alpha.alpha = 1
    else
        self._alpha.alpha = 0.4
    end

    self._nameLabel:SetText(StringTable.Get(cfg.MissionName))
    local icon = cfg.BossLevelIcon
    self._iconLoader:LoadImage(icon)
    UICG.SetTransform(self._iconLoader.transform, self:GetName(), icon)
    self:RefreshPets()
end

function UISailingLevelDetail:OnHide()
    self._atlas = nil
end

function UISailingLevelDetail:GetWordDesc(levelId, wordId)
    local word = Cfg.cfg_word_buff[wordId]
    if not word then
        Log.exception("cfg_word_buff 中找不到词缀:", wordId, "levelId:", levelId)
    end

    local name = StringTable.Get(word.Word[1])
    local desc = StringTable.Get(word.Desc)
    local tex = "【" .. name .. "】 " .. desc
    return tex
end

function UISailingLevelDetail:RefreshPets()
    local scale =1
    local teamCount = 5

    -- function DiscoveryStage.IsGuideStageId(id)
    --     if Cfg.cfg_mission_guide()[id] then
    --         return true
    --     end
    --     return false
    -- end


    self._team:SpawnObjects("UISailingLevelTeamItem",teamCount)
    ---@type UISailingLevelTeamItem[]
    local pools = self._team:GetAllSpawnList()
    local pets = self._sailingMissionModule:GetMissionTeams(self._layerId, self._missionId)
    local isPstId = true
    if DiscoveryStage.IsGuideStageId(self._missionId) then
        if pets and #pets > 0 then
            isPstId = false
            local cfg = Cfg.cfg_mission_guide[self._missionId]
            pets = {}
            for i = 1, #cfg.BattlePetList do
                local pet = {}
                for j = 1, #cfg.BattlePetList[i] do
                    pet[#pet + 1] = cfg.BattlePetList[i][j] --光灵id，等级，觉醒等级，突破等级，装备
                end
                pets[#pets + 1] = pet
            end
        else
            pets = {}
        end
    end
    for i = 1, #pools do
        ---@type UISailingLevelTeamItem
        local item = pools[i]
        local pstid = pets[i]
        item:SetData(pstid,scale,isPstId)
    end
end

function UISailingLevelDetail:BtnCloseOnClick()
    self:StartTask(self.Close, self)
    
end

function UISailingLevelDetail:Close(TT)
    self:Lock("UISailingLevelDetail_Close")
    local anim = self:GetUIComponent("Animation", "Anim")
    anim:Play("uieff_UISailingLevelDetail_out")
    YIELD(TT, 400)
    self:CloseDialog()
    self:UnLock("UISailingLevelDetail_Close")
end

function UISailingLevelDetail:BtnRestrainOnClick()
    self:ShowDialog("UISailingElementTips")
end

function UISailingLevelDetail:BtnWordOnClick()
    if self._show then
        self:ShowDialog("UISailingWordTips",self._tb)
    end
end

function UISailingLevelDetail:BtnResetTeamOnClick()
    local pets = self._sailingMissionModule:GetMissionTeams(self._layerId, self._missionId)
    if pets == nil or #pets <= 0 then
        return
    end
    self:ShowDialog("UISailingLevelResetTeam", function()
        self:StartTask(self.ResetTeamRequest, self)
    end)
end

function UISailingLevelDetail:ResetTeamRequest(TT)
    self:Lock("UISailingLevelDetail_ResetTeamRequest")
    self._sailingMissionModule:HandleResetMissionRecord(TT, self._layerId, self._missionId)
    self:RefreshPets()
    self:UnLock("UISailingLevelDetail_ResetTeamRequest")
end

function UISailingLevelDetail:BtnStartBattleOnClick()
    self:StartTask(self.StartBattle, self)
end

function UISailingLevelDetail:StartBattle(TT)
    self:Lock("UISailingLevelDetail_StartBattle")
    local pets = self._sailingMissionModule:GetMissionTeams(self._layerId, self._missionId)
    if pets and #pets > 0 then
        if not DiscoveryStage.IsGuideStageId(self._missionId) then
            self._sailingMissionModule:HandleChangeFormation(TT, self._layerId, self._missionId, pets)
        end
    else
        ---@type TeamCache
        local teamCache = self._sailingMissionModule:GetTeamCache()
        if teamCache then
            if teamCache.layer_id ~= self._layerId or teamCache.mission_id ~= self._missionId then
                self._sailingMissionModule:HandleChangeFormation(TT, self._layerId, self._missionId, {})
            end
        end
    end

    self._sailingMissionModule:CacheHistoryMissionCount()
    ---@type MissionModule
    local missiontModule = GameGlobal.GetModule(MissionModule)
    ---@type TeamsContext
    local ctx = missiontModule:TeamCtx()
    ---@type TeamCache
    local teamCache = self._sailingMissionModule:GetTeamCache()
    ctx:InitSailingTeams(teamCache)
    ctx:Init(TeamOpenerType.Sailing, {self._layerId, self._missionId})
    ctx:ShowDialogUITeams(false)
    self:UnLock("UISailingLevelDetail_StartBattle")
end
