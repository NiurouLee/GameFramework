---@class UITalePetMissionController : UIController
_class("UITalePetMissionController", UIController)
UITalePetMissionController = UITalePetMissionController

function UITalePetMissionController:LoadDataOnEnter(TT, res, uiParams)
    ---@type TalePetModule
    local talePetModule = GameGlobal.GetModule(TalePetModule)
    local ret = talePetModule:RequestTrailLevelData(TT)
    if ret ~= 0 then
        res.m_result = ret
        return
    end
    local rewardDatas = talePetModule:GetTrailLevelRewardList()
end

function UITalePetMissionController:OnShow(uiParams)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UITalePetMissionController)

    ---@type TalePetModule
    self.talePetModule = GameGlobal.GetModule(TalePetModule)
    ---@type SvrTimeModule
    self.timeModule = GameGlobal.GetModule(SvrTimeModule)

    self.ElementSpriteName = {
        [ElementType.ElementType_Blue] = "bing_color",
        [ElementType.ElementType_Red] = "huo_color",
        [ElementType.ElementType_Green] = "sen_color",
        [ElementType.ElementType_Yellow] = "lei_color"
    }

    self.imgGradeSprite = {
        [0] = "spirit_juexing_icon0" ,
        [1] = "spirit_juexing_icon1" ,
        [2] = "spirit_juexing_icon2" ,
        [3] = "spirit_juexing_icon3" ,
    }
    self.bgSpriteName = {
        [1] = "legend_sixiang_di28",
        [2] = "legend_sixiang_di25",
        [3] = "legend_sixiang_di27",
        [4] = "legend_sixiang_di26",
    }
    self.btnSpriteNormal = "legend_sixiang_btn1"
    self.btnSpriteLight = "legend_sixiang_btn2"
    self.atlas = self:GetAsset("UITalePet.spriteatlas", LoadType.SpriteAtlas)

    self.petId = uiParams[1]
    self.isSwitchState = uiParams[2] and true

    self.startTime, self.endTime = self.talePetModule:GetActityTime()

    self.isActive = false

    self:_AttachEvents()

    self:InitUI()
    UIBgmHelper.PlayMainBgm()
end

function UITalePetMissionController:InitUI()

    self.Anim = self:GetUIComponent("Animation","Anim")
    self.showInTask = self:StartTask(self.ShowInEff,self)

    self.firstElement = self:GetUIComponent("Image","prop1")
    self.secondElement = self:GetUIComponent("Image","prop2")
    self.elementObj2 = self:GetGameObject("prop2")
    self.petName = self:GetUIComponent("UILocalizationText","petName")
    self.stars = self:GetUIComponent("UISelectObjectPath","stars")
    self.wakingStage = self:GetUIComponent("Image","wakingStage")
    self.txtCurPro = self:GetUIComponent("UILocalizationText","txtCurPro")
    self.txtTotalPro = self:GetUIComponent("UILocalizationText","txtTotalPro")
    self.btnGetPet = self:GetUIComponent("Button","btnGetPet")
    self.btnGetPetImg = self:GetUIComponent("Image","btnGetPet")
    self.missionStage = self:GetUIComponent("UISelectObjectPath","missionStage")
    self.missionItem = self:GetUIComponent("UISelectObjectPath","missionItem")

    self.curConvene = self:GetUIComponent("UILocalizationText","curConvene")
    self.talepetTips = self:GetUIComponent("UILocalizationText","talepetTips")
    self.btnListName = self:GetUIComponent("UILocalizationText","btnListName")
    self.btnDescName = self:GetUIComponent("UILocalizationText","btnDescName")
    self.btnTrailName = self:GetUIComponent("UILocalizationText","btnTrailName")
    self.btnExerciseName = self:GetUIComponent("UILocalizationText","btnExerciseName")
    self.txtGetPetName = self:GetUIComponent("UILocalizationText","txtGetPetName")
    self.txtConvene = self:GetUIComponent("UILocalizationText","txtConvene")
    self.stageNum = self:GetUIComponent("UILocalizationText","stageNum")
    self.curMissionNum = self:GetUIComponent("UILocalizationText","curMissionNum")
    self.totalMissionNum = self:GetUIComponent("UILocalizationText","totalMissionNum")
    self.awardIcon = self:GetUIComponent("RawImageLoader","awardIcon")
    self.imgActive = self:GetGameObject("imgActive")
    self.txtActiveDesc = self:GetUIComponent("UILocalizationText","txtActiveDesc")
    self.txtActiveTime = self:GetUIComponent("UILocalizationText","txtActiveTime")
    self.txtActiveDesc:SetText(StringTable.Get("str_tale_pet_txt_active_tips"))
    self.btnTrail = self:GetUIComponent("Button","btnTrail")
    self.btnTrailImage = self:GetUIComponent("Image","btnTrail")
    self.trailLock = self:GetGameObject("trailLock")

    self.awardRed = self:GetGameObject("award_Red")
    self.effAward = self:GetGameObject("effAward")
    self.effAward:SetActive(false)
    self.getPetRed = self:GetGameObject("getPet_red")
    self.petListRed = self:GetGameObject("petList_red")
    --self.curAwardNum = self:GetUIComponent("UILocalizationText","curAwardNum")
    self.topButtons = self:GetUIComponent("UISelectObjectPath","topButtons")
    self.awardNum = self:GetUIComponent("UILocalizationText","awardNum")
    self.awardObj = self:GetGameObject("awardObj")
    self.Anim:Play("uieff_UITalePetMissionController_in")
    self.bgL = self:GetUIComponent("RawImageLoader","bgL")
    self.normalL = self:GetUIComponent("MultiplyImageLoader","normalL")
    self.normalRect = self:GetUIComponent("RectTransform","normalL")

    --local cfg = Cfg.cfg_pet{ID = self.petId}[1]
    local cg = HelperProxy:GetInstance():GetPetStaticBody(self.petId,0,0,PetSkinEffectPath.NO_EFFECT)
    UICG.SetTransform(self.normalRect,self:GetName(),cg)
    self.normalL:Load(cg)

    ---@type UICommonTopButton
    self.topButtonWidget = self.topButtons:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            -- if self.isSwitchState then
            --     self:SwitchState(UIStateType.UIMain)
            -- else
            --     self:CloseDialog()
            -- end
            self:SwitchState(UIStateType.UIMain)
        end,
        function()
            self:ShowDialog("UIHelpController", "UITalePetMissionController")
        end
    )

    
    self.itemTips = self:GetUIComponent("UISelectObjectPath","itemTips")
    ---@type UISelectInfo
    self.tips = self.itemTips:SpawnObject("UISelectInfo")
    self.btnAwardRect = self:GetUIComponent("RectTransform","btnAward")

    -----------------------------------------------------------------------------
    self.curConvene:SetText(StringTable.Get("str_tale_pet_task_txt_curconvene"))
    self.talepetTips:SetText(StringTable.Get("str_tale_pet_task_txt_petdesc"))
    self.btnListName:SetText(StringTable.Get("str_tale_pet_btn_list_name"))
    self.btnDescName:SetText(StringTable.Get("str_tale_pet_btn_detail_name"))
    self.btnTrailName:SetText(StringTable.Get("str_tale_pet_btn_trail_level_name"))
    self.btnExerciseName:SetText(StringTable.Get("str_tale_pet_btn_exercise_name"))
    self.txtGetPetName:SetText(StringTable.Get("str_tale_pet_btn_get_pet_name"))
    self.txtConvene:SetText(StringTable.Get("str_tale_pet_txt_convene_desc"))
    self.trailLevelRed = self:GetGameObject("TrailLevelRed")

    self:RefreshTrailLevelRedStatus()
    self:Refresh()
    self:RefreshMission()
    self:RefreshMissionProgress()
    self:GetPetRedController()
    self:PetListRedController()
    self:AwardRedController()
end

function UITalePetMissionController:ShowInEff(TT)
    self.Anim:Play("uieff_UITalePetMissionController_conversion")
end

function UITalePetMissionController:RefreshTrailLevelRedStatus()
    self.trailLevelRed:SetActive(false)
    ---@type TalePetModule
    local talePetModule = GameGlobal.GetModule(TalePetModule)
    if talePetModule:IsShowRewardRed() then
        self.trailLevelRed:SetActive(true)
    end
    local state = talePetModule:IsShowTrailFinalLevelRed()
    if state then
        self.trailLevelRed:SetActive(true)
    end
end

function UITalePetMissionController:OnUpdate()
    local isActive = self.talePetModule:IsOpenActity()
    if isActive then
        self.imgActive:SetActive(true)
        local nowTime = self.timeModule:GetServerTime() / 1000
        local time = self.endTime - nowTime
        --local time = self:GetUIModule(TalePetModule):FormatTime(tonumber(self.endTime - nowTime)) 
        --self.txtActiveTime:SetText(self:GetUIModule(TalePetModule):FormatTime(tonumber(time)))
        self.txtActiveTime:SetText(self:GetUIModule(TalePetModule):FormatTime(tonumber(time)))
    else
        self.imgActive:SetActive(false)
    end
end


function UITalePetMissionController:Refresh()
    local cfg_pet = Cfg.cfg_pet[self.petId]
    if not cfg_pet then
        return
    end
    self.FirstElement = cfg_pet.FirstElement
    self.SecondElement = cfg_pet.SecondElement
    self.atlas2 = self:GetAsset("Property.spriteatlas",LoadType.SpriteAtlas)
    self.bgL:LoadImage(self.bgSpriteName[self.FirstElement])
    local cfg_pet_element = Cfg.cfg_pet_element{}
    self.firstElement.sprite = self.atlas2:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[self.FirstElement].Icon))
    --self.firstElement:LoadImage(self.ElementSpriteName[self.FirstElement])
    if self.SecondElement > 0 then
        self.secondElement.sprite = self.atlas2:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(cfg_pet_element[self.SecondElement].Icon))
        --self.secondElement:LoadImage(self.ElementSpriteName[self.SecondElement])
    end
    self.elementObj2:SetActive(self.SecondElement > 0)
    self.petName:SetText(StringTable.Get(cfg_pet.Name))
    self.stars:SpawnObjects("UICommonEmptyItems",cfg_pet.Star)
    self.wakingStage.sprite = self.atlas:GetSprite(self.imgGradeSprite[cfg_pet.BornGrade])
    self.talepetTips:SetText(StringTable.Get("str_tale_pet_task_txt_petdesc",cfg_pet.BornGrade))
    self.effAward:SetActive(self.talePetModule:IsGetReward(self.petId))
end

--刷新任务进度
function UITalePetMissionController:RefreshMissionProgress()
    local info = self.talePetModule:GetPetInfo(self.petId)
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    if info == nil then
        self.txtCurPro:SetText(1)
        self.txtTotalPro:SetText(totalPro)
        self.txtConvene:SetText(StringTable.Get("str_tale_pet_txt_convene_desc") .. "  <color=#fd9e00>1</color>" .. "/" .. totalPro)
        self.btnGetPet.interactable = false
        self.stageNum:SetText(StringTable.Get("str_tale_pet_stage_reward",1))
        self.curMissionNum:SetText(1)
        self.totalMissionNum:SetText(totalPro)
        return
    end
    self.txtCurPro:SetText(info.task_phase)
    self.txtTotalPro:SetText(totalPro)
    self.txtConvene:SetText(StringTable.Get("str_tale_pet_txt_convene_desc") .. "  <color=#fd9e00>"..info.task_phase.."</color>" .. "/" .. totalPro)
    local state = info.pet_status
    if state == TalePetCallType.TPCT_Can_Do then
        --可领取
        self.txtCurPro:SetText(totalPro)
        self.txtTotalPro:SetText(totalPro)
        self.txtConvene:SetText(StringTable.Get("str_tale_pet_txt_convene_desc") .. "  <color=#fd9e00>"..totalPro.."</color>" .. "/" .. totalPro)
        self.btnGetPet.interactable = true
        self.btnGetPetImg.sprite = self.atlas:GetSprite(self.btnSpriteLight)
        self.trailLock:SetActive(true)
        self.btnTrail.interactable = false
        --self.btnTrailImage.color = Color(1,1,1,0.15)
    elseif state == TalePetCallType.TPCT_Done then
        --已领取
        self.txtCurPro:SetText(totalPro)
        self.txtTotalPro:SetText(totalPro)
        self.txtConvene:SetText(StringTable.Get("str_tale_pet_txt_convene_desc") .. "  <color=#fd9e00>"..totalPro.."</color>" .. "/" .. totalPro)
        self.txtGetPetName:SetText(StringTable.Get("str_tale_pet_btn_has_get_name"))
        self.btnGetPet.interactable = false
        self.btnGetPetImg.sprite = self.atlas:GetSprite(self.btnSpriteNormal)
        self.btnTrail.interactable = true
        self.trailLock:SetActive(false)
        --self.btnTrailImage.color = Color(1,1,1,1)
    else
        self.btnGetPet.interactable = false
        self.btnTrail.interactable = false
        self.trailLock:SetActive(true)
        --self.btnTrailImage.color = Color(1,1,1,0.15)
    end

    --试炼
    self:RefreshTrail()
    
    --award
    self:RefreshReward(info)

end


function UITalePetMissionController:RefreshReward(info)
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    local icon
    local count
    local cfg_item
    local canGetStage = self.talePetModule:CanGetTaskPhaseAward(self.petId)
    if info.pet_status == TalePetCallType.TPCT_Can_Do or info.pet_status == TalePetCallType.TPCT_Done then
        self.curMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,canGetStage))
        self.totalMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,canGetStage))
        self.stageNum:SetText(StringTable.Get("str_tale_pet_stage_reward",canGetStage))
        if canGetStage <= totalPro then
            cfg_item = self:GetRewardId(self.petId,canGetStage)
            icon = cfg_item.Icon
            local cfg_reward = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = canGetStage}
            self.awardNum:SetText(cfg_reward[1].ItemCount)
            self.awardObj:SetActive(true)
        else
            icon = Cfg.cfg_tale_pet_global{}.TalePetEmptyBoxIcon.Value
            self.stageNum:SetText(StringTable.Get("str_tale_pet_stage_reward",totalPro))
            self.curMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,totalPro))
            self.totalMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,totalPro))
            local cfg_reward = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = totalPro}
            self.awardNum:SetText(cfg_reward[1].ItemCount)
            self.awardObj:SetActive(false)
        end
        self.awardIcon:LoadImage(icon)
        return
    else
        if self.talePetModule:IsGetReward(self.petId) then
            cfg_item = self:GetRewardId(self.petId,canGetStage)
            icon = cfg_item.Icon
            self.awardIcon:LoadImage(icon)
            local cfg_reward = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = canGetStage}
            self.awardNum:SetText(cfg_reward[1].ItemCount)
            self.stageNum:SetText(StringTable.Get("str_tale_pet_stage_reward",canGetStage))
            self.curMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,canGetStage))
            self.totalMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,canGetStage))
        else
            local curStage = info.task_phase + 1
            cfg_item = self:GetRewardId(self.petId,curStage)
            icon = cfg_item.Icon
            self.awardIcon:LoadImage(icon)
            local cfg_reward = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = curStage}
            self.awardNum:SetText(cfg_reward[1].ItemCount)
            self.stageNum:SetText(StringTable.Get("str_tale_pet_stage_reward",curStage))
            local curStageComp = 0
            for key, value in pairs(info.datas) do
                if value.status then
                    curStageComp = curStageComp + 1
                end
            end
            self.curMissionNum:SetText(curStageComp)
            self.totalMissionNum:SetText(self.talePetModule:GetTaskCounts(self.petId,curStage))
        end
    end
end

function UITalePetMissionController:RefreshTrail()
    local isGet = self.talePetModule:IsGetPetAlready()
    if isGet then
        self.trailLock:SetActive(false)
        self.btnTrail.interactable = true
        --self.btnTrailImage.color = Color(1,1,1,1)
    else
        self.trailLock:SetActive(true)
        self.btnTrail.interactable = false
        --self.btnTrailImage.color = Color(1,1,1,0.15)
    end
end

function UITalePetMissionController:GetRewardId(petId,phase)
    local cfg_reward = Cfg.cfg_tale_task_phase_reward{PetID = petId,Phase = phase}
    if cfg_reward == nil then
        return nil
    end
    local cfg_item = Cfg.cfg_item{ID = cfg_reward[1].ItemId}[1]
    return cfg_item
end

--刷新任务
function UITalePetMissionController:RefreshMission()
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    self.missionStage:SpawnObjects("UIMissionStageItem", totalPro)
    local stageItems = self.missionStage:GetAllSpawnList()
    for i = 1, #stageItems do
        stageItems[i]:SetData(
            i,
            function(index)
                self:StageItemClick(index)
            end
            ,self.petId
        )
    end
end
function UITalePetMissionController:StageItemClick(index)

    local stageItems = self.missionStage:GetAllSpawnList()
    for i = 1, #stageItems do
        stageItems[i]:RefreshSelect()
    end
    local count = self.talePetModule:GetTaskCounts(self.petId,index)
    self.missionItem:SpawnObjects("UIMissionItem",count)
    local missionItems = self.missionItem:GetAllSpawnList()
    for i = 1, #missionItems do
        if i <= count then
            missionItems[i]:SetData(i,self.petId,index,true)
        else
            missionItems[i]:SetData(i,self.petId,index,false)
        end
    end
    self.missionItemTask = self:StartTask(self.MissionItemShow,self,missionItems)
end

function UITalePetMissionController:MissionItemShow(TT,missionItems)
    YIELD(TT)
    for index, value in ipairs(missionItems) do
        value:ShowInAnim()
        YIELD(TT)
        YIELD(TT)
    end
end

--光灵列表按钮
function UITalePetMissionController:btnTalePetListOnClick()
    self:ShowDialog("UITalePetList")
end

--光灵详情按钮
function UITalePetMissionController:btnDescribeInfoOnClick()
    self:ShowDialog("UIShopPetDetailController", self.petId, 0, 0)
end

--试炼
function UITalePetMissionController:btnTrailOnClick()
    if self.btnTrail.interactable == false then
        ToastManager.ShowToast(StringTable.Get("str_tale_pet_trail_level_un_open"))
        return
    end
    self:GetUIModule(TalePetModule):OpenTrailLevel()
end

--演习
function UITalePetMissionController:btnExerciseOnClick()
    self:GetUIModule(TalePetModule):OpenPracticeLevel(self.petId)
end

--领取
function UITalePetMissionController:btnGetPetOnClick()
    --跳转获得光灵界面
    --在请求数据之前先保存当前背包，是否拥有获取的光灵
    if self.btnGetPet.interactable == false then
        local info = self.talePetModule:GetPetInfo(self.petId)
        if info.pet_status == TalePetCallType.TPCT_Done then
            return
        else
            ToastManager.ShowToast(StringTable.Get("str_tale_pet_btn_getpet_tips"))
        end
        return
    end
    GameGlobal.TaskManager():StartTask(self.GetPet,self)
end

--领取阶段奖励
function UITalePetMissionController:AwardController()
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    local info = self.talePetModule:GetPetInfo(self.petId)
    local curState = false
    local stage
    if info == nil then
        return
    end
    stage = info.task_phase + 1
    if info.pet_status == TalePetCallType.TPCT_Can_Do or info.pet_status == TalePetCallType.TPCT_Done then
        stage = totalPro
        curState = true
    end

    local cfg = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = stage}
    local state = self.talePetModule:IsGetReward(self.petId)
    return state,curState,cfg
end

function UITalePetMissionController:btnAwardOnClick()
    local info = self.talePetModule:GetPetInfo(self.petId)
    local totalPro = self.talePetModule:GetTaskPhase(self.petId)
    local canGetStage = self.talePetModule:CanGetTaskPhaseAward(self.petId)
    if canGetStage > totalPro then
        return
    end
    if canGetStage == 0 then
        canGetStage = table.count(info.task_phase_reward) + 1
    end
    local cfg = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = canGetStage}
    local cfg_item = Cfg.cfg_item{ID = cfg[1].ItemId}[1]
    local boxId = cfg_item.ID
    
    self.tips:SetData(boxId, self.btnAwardRect.position)
    -- local state,curState,cfg = self:AwardController()
    -- -- if state then
    -- --     --有奖励可以领取，显示获得物品界面
    -- --     --GameGlobal.TaskManager():StartTask(self.GetPhaseAward,self)
    -- -- else
    --     --没奖励可以领取，显示宝箱物品详细信息
    --     local cfg_item = Cfg.cfg_item{ID = cfg[1].ItemId}[1]
    --     local boxId = cfg_item.ID
    --     -- if curState then
    --     --     return
    --     -- end
        
    -- --end
end

function UITalePetMissionController:btnGetAwardOnClick()
    local state,curState,cfg = self:AwardController()
    if state then
        --有奖励可以领取，显示获得物品界面
        GameGlobal.TaskManager():StartTask(self.GetPhaseAward,self)
    end
end

function UITalePetMissionController:GetPhaseAward(TT)
    self:Lock("UITalePetMissionController.GetPhaseAward")
    local canGetStage = self.talePetModule:CanGetTaskPhaseAward(self.petId)
    local cfg = Cfg.cfg_tale_task_phase_reward{PetID = self.petId,Phase = canGetStage}[1]
    local res = self.talePetModule:ReqTaleTaskReward(TT,cfg.ID)
    if res:GetSucc() then
        --成功,调取通用获取物品界面
        local itemId = cfg.ItemId
        if itemId then
            local dropDewards = Cfg.cfg_item{ID = itemId}
            local rewards = {}
            for i = 1, #dropDewards do
                if dropDewards[i].ID and dropDewards[i].ID > 0 then
                    rewards[#rewards + 1] = {assetid = dropDewards[i].ID, count = cfg.ItemCount}
                end
            end
            self:ShowRewards(rewards)
        end
    else
        ToastManager.ShowToast(res:GetResult())
    end
    self:UnLock("UITalePetMissionController.GetPhaseAward")
end

function UITalePetMissionController:ShowRewards(rewards)
    self:ShowDialog("UIGetItemController",rewards)
end

function UITalePetMissionController:GetPet(TT)
    self:Lock("UITalePetMissionController:GetPet")
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()
    ---@type AsyncRequestRes
    local res = self.talePetModule:ReqTaleCall(TT,self.petId)
    if res:GetSucc() then
        local roleAsset = RoleAsset:New()
        roleAsset.assetid = self.petId
        roleAsset.count = 1
        local tempPets = {roleAsset}
        if GameGlobal.GetModule(PetModule):IsPetID(roleAsset.assetid) then
            self:ShowDialog("UIPetObtain",
                tempPets,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")            
                end
            )
        end
        self.btnGetPet.interactable = false
    else
        ToastManager.ShowToast(res.m_result)
    end
    self:UnLock("UITalePetMissionController:GetPet")
end

---------------------------------------------------红点
function UITalePetMissionController:AwardRedController()
    --阶段任务完成后，显示红点
    --如果多个宝箱，会显示数字
    local state = self.talePetModule:IsGetReward(self.petId)
    self.awardRed:SetActive(state)

    local info = self.talePetModule:GetPetInfo(self.petId)
    if info == nil then
        return
    end


    local count = 0
    for index, value in pairs(info.task_phase_reward) do
        count = count + 1
    end

    -- if info.task_phase - count > 1 then
    --     self.curAwardNum:SetText(info.task_phase - count)
    -- else
    --     self.curAwardNum:SetText("")
    -- end
end

function UITalePetMissionController:GetPetRedController()
    --光灵可领取但未领取时显示
    local state = self.talePetModule:IsCanCallPet(self.petId)
    self.getPetRed:SetActive(state)
end

function UITalePetMissionController:PetListRedController()
    --光灵可以领取但未领取，并且不是当前召集中的光灵显示
    --当前召集的光灵已领取，且当前还有未获得的传说光灵显示
    --当有任务阶段奖励可以领取，并且不是当前光灵的时候显示
    self.petListRed:SetActive(false)
    local info = self.talePetModule:GetPetInfo(self.petId)
    if info == nil then
        return
    end
    if info.pet_status ~= TalePetCallType.TPCT_Can_Do then
        if self.talePetModule:IsCallPet() then
            self.petListRed:SetActive(true)
        end
    elseif info.pet_status == TalePetCallType.TPCT_Done then
        if self.talePetModule:IsGetAll() == false then
            self.petListRed:SetActive(true)
        end
    end
    if self.talePetModule:IsCallPet() then
        local info = self.talePetModule:GetPetInfo(self.petId)
        if info ~= nil and info.pet_status ~= TalePetCallType.TPCT_Can_Do then
            self.petListRed:SetActive(true)
        end
    end
    local cfgs = Cfg.cfg_tale_pet{}
    for key, value in pairs(cfgs) do
        if value.ID ~= self.petId then
            local state = self.talePetModule:IsGetReward(value.ID)
            if state then
                self.petListRed:SetActive(true)
                return
            end
        end
    end
end

function UITalePetMissionController:OnHide()
    self:_DetachEvents()
    if self.showInTask then
        GameGlobal.TaskManager():KillTask(self.showInTask)
        self.showInTask = nil
    end
    
    if self.missionItemTask then
        GameGlobal.TaskManager():KillTask(self.missionItemTask)
        self.missionItemTask = nil
    end
end

function UITalePetMissionController:_AttachEvents()
    self:AttachEvent(GameEventType.TalePetInfoDataChange,self.InfoDataChange)
    self:AttachEvent(GameEventType.TalePetTrailLevelRewardChange, self.RefreshTrailLevelRedStatus)
end

function UITalePetMissionController:_DetachEvents()
    self:DetachEvent(GameEventType.TalePetInfoDataChange)
    self:DetachEvent(GameEventType.TalePetTrailLevelRewardChange, self.RefreshTrailLevelRedStatus)
end

function UITalePetMissionController:InfoDataChange()
    self:RefreshTrailLevelRedStatus()
    self:Refresh()
    self:RefreshMission()
    self:RefreshMissionProgress()
    self:GetPetRedController()
    self:PetListRedController()
    self:AwardRedController()
end
