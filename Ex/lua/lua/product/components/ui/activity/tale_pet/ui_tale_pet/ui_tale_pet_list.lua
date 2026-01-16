---@class UITalePetList: UIController
_class("UITalePetList", UIController)
UITalePetList = UITalePetList

function UITalePetList:LoadDataOnEnter(TT, res, uiParams)
    ---@type TalePetModule
    self.talePetModule = GameGlobal.GetModule(TalePetModule)
end

function UITalePetList:OnShow(uiParams)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UITalePetList)
    
    self.isSwitchState = uiParams[1] and true
    local topButton = self:GetUIComponent("UISelectObjectPath","TopButtons")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            if self.isSwitchState then
                self:SwitchState(UIStateType.UIMain)
            else
                GameGlobal.EventDispatcher():Dispatch(GameEventType.TalePetInfoDataChange)
                self:CloseDialog()
            end
        end
        -- function()
        --     self:ShowDialog("UIHelpController", "UITalePetList")
        -- end
    )
    self.talePetInfo = self:GetUIComponent("UISelectObjectPath","talePetInfo")

    self.txtStoryEnter = self:GetUIComponent("UILocalizationText","txtStoryEnter")
    self.txtTrail = self:GetUIComponent("UILocalizationText","txtTrail")
    self.txtStoryEnter:SetText(StringTable.Get("str_tale_pet_replay_story"))
    self.txtTrail:SetText(StringTable.Get("str_tale_pet_start_trail_level"))

    self.btnTrail = self:GetUIComponent("Button","btnTrail")
    self.imgTrail = self:GetUIComponent("Image","imgTrail")
    self.imgTrailLock = self:GetGameObject("imgTrailLock")

    ---光灵立绘
    self.pet1_1 = self:GetUIComponent("RawImageLoader","pet1_1")
    self.pet2_1 = self:GetUIComponent("RawImageLoader","pet2_1")
    self.pet3_1 = self:GetUIComponent("RawImageLoader","pet3_1")
    self.pet4_1 = self:GetUIComponent("RawImageLoader","pet4_1")

    self.pet1_2 = self:GetUIComponent("RawImageLoader","pet1_2")
    self.pet2_2 = self:GetUIComponent("RawImageLoader","pet2_2")
    self.pet3_2 = self:GetUIComponent("RawImageLoader","pet3_2")
    self.pet4_2 = self:GetUIComponent("RawImageLoader","pet4_2")

    self.pet1_3 = self:GetUIComponent("RawImageLoader","pet1_3")
    self.pet2_3 = self:GetUIComponent("RawImageLoader","pet2_3")
    self.pet3_3 = self:GetUIComponent("RawImageLoader","pet3_3")
    self.pet4_3 = self:GetUIComponent("RawImageLoader","pet4_3")

    self.clickTips = self:GetGameObject("clickTips")
    self.tipsCanvas = self:GetUIComponent("CanvasGroup","txtClickTips")

    self.anim = self:GetUIComponent("Animation","Anim")

    self:InitTalePet()
    self:RefreshUI()
    
    self:AttachEvents()
    UIBgmHelper.PlayMainBgm()
end

function UITalePetList:RefreshUI()
    --如果有已经获得的光灵，试炼入口显示
    local state = false
    local talePetList = self.talePetModule:GetTalePetList()
    for i = 1, #talePetList do
        if self.talePetModule:IsGetTalePet(talePetList[i]) == true then
            state = true
        end
    end
    if state then
        self.btnTrail.interactable = true
        --self.imgTrailLock:SetActive(false)
        --self.imgTrail.color = Color(1,1,1,1)
    else
        self.btnTrail.interactable = false
        --self.imgTrailLock:SetActive(true)
        --self.imgTrail.color = Color(1,1,1,0.15)
    end

    local isGetAll = self.talePetModule:IsDoPet()
    self.clickTips:SetActive(isGetAll)
    if isGetAll == true then
        if self.tipsTask then
            GameGlobal.TaskManager():KillTask(self.tipsTask)
            self.tipsTask = nil
        end
        self.tipsTask = self:StartTask(self.TipsTask,self)
    end
    -- if isGetAll == false then
    --     self.clickTips:SetActive(true)
    -- end
end

function UITalePetList:TipsTask(TT)
    local initValue = 1
    local speed = 0.6
    while true do
        local dt = UnityEngine.Time.deltaTime
        initValue = initValue + dt * speed
        if initValue >= 1 or initValue <= 0.2 then
            speed = speed * -1
            initValue = initValue >= 1 and 1 or 0.2
        end
        self.tipsCanvas.alpha = initValue
        YIELD(TT)
    end
    self.tipsTask = nil
end

function UITalePetList:InitTalePet()
    self.talePets = self.talePetModule:GetActivityTalePet()
    --刷新背景角色
    for i = 1, #self.talePets do
        local cfg = Cfg.cfg_tale_pet[self.talePets[i].ID]
        local str = "pet"..tostring(i)
        self[str.."_1"]:LoadImage(cfg.PetRawImg1)
        self[str.."_2"]:LoadImage(cfg.PetRawImg2)
        self[str.."_3"]:LoadImage(cfg.PetRawImg3)

        local rawMat = self:GetUIComponent("RawImage",str.."_3").material
        local info = self.talePetModule:GetPetInfo(self.talePets[i].ID)
        local state = true
        if self.talePetModule:SelectPetCfgId() == self.talePets[i].ID then
            state = false
            --进场选择的光灵播放特效
            self:SelectPetEff(self.talePets[i].ID,str,true,true)
        else
            if info ~= nil then
                if info.pet_status == TalePetCallType.TPCT_Done or info.pet_status == TalePetCallType.TPCT_Done then
                    state = false
                    local lay2 = self:GetGameObject(str.."_2")
                    lay2:SetActive(info.pet_status == TalePetCallType.TPCT_Done)
                end
            end
        end
        if self["petStatic"..str] then
            GameGlobal.TaskManager():KillTask(self["petStatic"..str])
            self["petStatic"..str] = nil
        end
        self["petStatic"..str] = self:StartTask(self.PetStaticBodyTask,self,rawMat,state,i)
    end
    

    --刷新角色信息item    
    ---@type UITalePetInfoItem
    self.talePetInfo:SpawnObjects("UITalePetInfoItem",table.count(self.talePets))
    local items = self.talePetInfo:GetAllSpawnList()
    for index, value in ipairs(items) do
        local cfg_pet = Cfg.cfg_pet{ID = self.talePets[index].ID}[1]
        value:SetData(self.talePets[index].ID,cfg_pet.Name,function(id)
            self:SelectPetEff(self.talePets[index].ID,"pet"..tostring(index),false,true)
            if self.itemClickTask then
                GameGlobal.TaskManager():KillTask(self.itemClickTask)
                self.itemClickTask = nil
            end
            self.itemClickTask = self:StartTask(self.ItemClick,self,id)
        end)
    end
end

function UITalePetList:SelectPetEff(id,str,bg,click)
    self.lay1 = self:GetGameObject(str.."_1")
    self.lay2 = self:GetGameObject(str.."_2")
    self.lay3 = self:GetGameObject(str.."_3")

    self.lay1:SetActive(true)
    --self.lay2:SetActive(false)
    self.lay3:SetActive(true)
    
    self.bgEff = self:GetGameObject("bgEff")
    self.clcikEff = self:GetGameObject("clickEff")
    self.clcikEffAni = self:GetUIComponent("Animation","clickEff")
    
    if id == self.talePetModule:SelectPetCfgId() then
        if bg then
            self.bgEff:SetActive(true)
            self.bgEff.transform:SetParent(self.lay1.transform)
            self.bgEff.transform.localRotation = Quaternion.identity
            self.bgEff.transform.localScale = Vector3.one
            self.bgEff.transform.localPosition = Vector3.zero
            self.bgEff:SetActive(true)
        end
    end
    if click then
        self.clcikEff:SetActive(false)
        self.clcikEff.transform:SetParent(self.lay3.transform)
        self.clcikEff.transform.localRotation = Quaternion.identity
        self.clcikEff.transform.localScale = Vector3.one
        self.clcikEff.transform.localPosition = Vector3.zero
        self.clcikEff:SetActive(true)
        --self.clcikEffAni:Play("uieff_TalePet_click")
    end
end

function UITalePetList:PetStaticBodyTask(TT,rawMat,state,idx)
    YIELD(TT,(idx-1)*100)
    local initValue = 0
    local speed = 0.6
    while state do
        if rawMat == nil then
            return
        end
        local dt = UnityEngine.Time.deltaTime
        initValue = initValue + dt * speed
        if initValue >= 1 or initValue <= 0 then
            speed = speed * -1
            initValue = initValue >= 1 and 1 or 0
        end
        rawMat:SetFloat("_LuminosityAmount",initValue)
        
        YIELD(TT)
    end
end

function UITalePetList:btnStoryRePlayOnClick()
    --重播剧情
    local storyId = self.talePetModule:GetEnterTalePetStoryIds()
    self:ShowDialog("UIStoryController", storyId, function()
        self:ShowDialog("UITalePetList")
    end)
end

function UITalePetList:btnTrailOnClick()
    --光灵试炼入口
    if self.btnTrail.interactable == false then
        ToastManager.ShowToast(StringTable.Get("str_tale_pet_trail_level_un_open"))
        return
    end
    self:GetUIModule(TalePetModule):OpenTrailLevel()
end

function UITalePetList:ExerciseBtnOnClick()
    local petId = self.talePets and self.talePets[1] and self.talePets[1].ID
    self:GetUIModule(TalePetModule):OpenPracticeLevel(petId)
end

function UITalePetList:ItemClick(TT,id)
    YIELD(TT)
    self:ShowDialog("UIShopPetDetailController", id, 0, 1, nil, 1)
end

function UITalePetList:AttachEvents()
    self:AttachEvent(GameEventType.TalePetDetailReturnList,self._TalePetDetailReturnList)
end

function UITalePetList:DetachEvents()
    self:DetachEvent(GameEventType.TalePetDetailReturnList)
end

function UITalePetList:_TalePetDetailReturnList()
    self:InitTalePet()
    self:RefreshUI()
end

function UITalePetList:OnHide()
    self:DetachEvents()
    for i = 1, #self.talePets do
        local str = "pet"..tostring(i)
        if self["petStatic"..str] then
            GameGlobal.TaskManager():KillTask(self["petStatic"..str])
            self["petStatic"..str] = nil
        end
    end
    if self.itemClickTask then
        GameGlobal.TaskManager():KillTask(self.itemClickTask)
        self.itemClickTask = nil
    end
    if self.tipsTask then
        GameGlobal.TaskManager():KillTask(self.tipsTask)
        self.tipsTask = nil
    end
end

function UITalePetList:Dispose() 
    
end
