---@class UIHelpPetManageController:UIController
_class("UIHelpPetManageController", UIController)
UIHelpPetManageController = UIHelpPetManageController

function UIHelpPetManageController:Constructor()
    self.module = self:GetModule(HelpPetModule)
    ---@type WeChatProxy
    self.atlas = self:GetAsset("UIHelpPet.spriteatlas", LoadType.SpriteAtlas)

    self._elements = {
        [1] = ElementType.ElementType_Blue,
        [2] = ElementType.ElementType_Red,
        [3] = ElementType.ElementType_Green,
        [4] = ElementType.ElementType_Yellow
    }
end

function UIHelpPetManageController:LoadDataOnEnter(TT, res, uiParams)
    self.params = uiParams
    local res = self.module:RequestHelpPet_SupportInfo(TT)
    if res:GetSucc() then
        ---@type DHelpPet_PetData[]
        self._info = {}

        for i = 1, #self._elements do
            local elem = self._elements[i]
            self._info[i] = self.module:UI_FindSupportPet(elem)
        end

        -- self._info[1] = DHelpPet_PetData:New()
        -- self._info[1].m_nTemplateID = 1500331
        -- self._info[1].m_nGrade = 1
        -- self._info[1].m_nEquipLevel = 1
        -- self._info[1].m_nLevel = 2
        -- self._info[1].m_nAwake = 2

        -- self._info[2] = DHelpPet_PetData:New()
        -- self._info[2].m_nTemplateID = 1600021
        -- self._info[2].m_nGrade = 1
        -- self._info[2].m_nEquipLevel = 1
        -- self._info[2].m_nLevel = 2
        -- self._info[2].m_nAwake = 2

        -- self._info[3] = DHelpPet_PetData:New()
        -- self._info[3].m_nTemplateID = 0
        -- self._info[3].m_nGrade = 1
        -- self._info[3].m_nEquipLevel = 1
        -- self._info[3].m_nLevel = 2
        -- self._info[3].m_nAwake = 2

        -- self._info[4] = DHelpPet_PetData:New()
        -- self._info[4].m_nTemplateID = 1600011
        -- self._info[4].m_nGrade = 1
        -- self._info[4].m_nEquipLevel = 1
        -- self._info[4].m_nLevel = 2
        -- self._info[4].m_nAwake = 2

        ---@type CEventHelpPet_SupportInfoAsw
        self._supportInfo = self.module:UI_GetSupportInfo()
        -- self._supportInfo = CEventHelpPet_SupportInfoAsw:New()
        -- self._supportInfo.m_nFightTotal = 201
        -- self._supportInfo.m_nFightWeek = 12

        -- ---@type DHelpPet_PetState
        -- local m_PetState = DHelpPet_PetState:New()
        -- m_PetState.m_nTemplateID = 1500331
        -- m_PetState.m_nFightCount = 5

        -- local m_PetState2 = DHelpPet_PetState:New()
        -- m_PetState2.m_nTemplateID = 1600011
        -- m_PetState2.m_nFightCount = 4

        -- local m_PetState3 = DHelpPet_PetState:New()
        -- m_PetState3.m_nTemplateID = 1600061
        -- m_PetState3.m_nFightCount = 3

        -- local m_PetState4 = DHelpPet_PetState:New()
        -- m_PetState4.m_nTemplateID = 1600021
        -- m_PetState4.m_nFightCount = 2

        -- local m_list = {}
        -- m_list[1] = m_PetState
        -- m_list[2] = m_PetState2
        -- m_list[3] = m_PetState3
        -- m_list[4] = m_PetState4

        -- self._supportInfo.m_listPetState = m_list
        res:SetSucc(true)
    else
        res:SetSucc(false)
    end
end

function UIHelpPetManageController:GetComponents()
    self._ltBtn = self:GetUIComponent("UISelectObjectPath", "ltBtn")
    self._backBtns = self._ltBtn:SpawnObject("UICommonTopButton")
    self._animComp = self:GetUIComponent("ATransitionComponent", "animComp")
    self._backBtns:SetData(
        function()
            self:GetModule(PetModule):ClearAllPetSortInfo()
            self:CloseDialog()
            if self.backCallBack then
                self.backCallBack()
            end
        end,
        function()
            self:ShowDialog("UIHelpController", "UIHelpPetManageController")
        end,
        function()
            self._animComp.enabled = false
            self:SwitchState(UIStateType.UIMain)
        end
    )

    self.leftSop = self:GetUIComponent("UISelectObjectPath", "holder")

    self.totalCount = self:GetUIComponent("UILocalizationText", "zong")
    self.sevenCount = self:GetUIComponent("UILocalizationText", "qitian")
    self.noGO = self:GetGameObject("no")
    self.haveGO = self:GetGameObject("have")
    self.sliders = {}
    for i = 1, 4 do
        self.sliders[i] = {}
        self.sliders[i].go = self:GetGameObject("slider" .. i)
        self.sliders[i].name = self:GetUIComponent("UILocalizationText", "name" .. i)
        self.sliders[i].image = self:GetUIComponent("Image", "tiaofill" .. i)
        self.sliders[i].countTxt = self:GetUIComponent("UILocalizationText", "count" .. i)
    end
end

function UIHelpPetManageController:OnValue()
    self:SetLeft()
    self:SetRight()
end

function UIHelpPetManageController:OnShow(uiParams)
    self.backCallBack = uiParams[1]
    self:GetComponents()
    --初始化固定4个cell
    self.leftSop:SpawnObjects("UIHelpPetManageCell", 4)
    ---@type UIHelpPetManageCell[]
    self.items = self.leftSop:GetAllSpawnList()
    for i, item in ipairs(self.items) do
        item:InitData(
            self._elements[i],
            function(elementType)
                -- local data = self._info[idx]
                self:ShowDialog(
                    "UITeamChangeController",
                    true, --为助战分支
                    function(petTempId, elementType, isAdd)
                        self:StartTask(
                            function(TT)
                                --协议设置助战星灵
                                local a = 1
                                if isAdd == false then
                                    a = 0
                                end
                                if a == 1 then
                                    ToastManager.ShowToast(StringTable.Get("str_help_pet_zzszcg"))
                                end
                                local res = self.module:RequestHelpPet_SupportSet(TT, petTempId, a)
                                if res and res:GetSucc() then
                                    --关掉选人界面
                                    GameGlobal.UIStateManager():CloseDialog("UITeamChangeController")
                                    --重新设置数据
                                    self._info[elementType] = self.module:UI_FindSupportPet(elementType)
                                    self:RefreshOneManageCell(
                                        elementType,
                                        self._info[elementType] and self._info[elementType].m_nTemplateID or 0
                                    )
                                end
                            end
                        )
                    end,
                    elementType
                )
            end,
            i
        )
    end
    self:OnValue()
end

-- 设置左边
function UIHelpPetManageController:SetLeft()
    --上阵的角色列表
    for i, item in ipairs(self.items) do
        item:SetData(self._info[i] and self._info[i].m_nTemplateID or 0, self._elements[i])
    end
end

--单刷一个助战cell
function UIHelpPetManageController:RefreshOneManageCell(elementType, petTempId)
    for _, item in ipairs(self.items) do
        if item:GetElementType() == elementType then
            item:SetData(petTempId, elementType)
            return
        end
    end
end

function UIHelpPetManageController:SetRight()
    --累计帮助次数
    local totalCount = self._supportInfo and self._supportInfo.m_nFightTotal or 0
    --七天最大次数
    local sevenCount = self._supportInfo and self._supportInfo.m_nFightWeek or 0

    self.totalCount:SetText(totalCount)
    self.sevenCount:SetText(sevenCount)

    ---@type DHelpPet_PetState[]
    self.tongjiList = self._supportInfo and self._supportInfo.m_listPetState
    if not self.tongjiList or table.count(self.tongjiList) <= 0 then
        self.noGO:SetActive(true)
        self.haveGO:SetActive(false)
    else
        self.noGO:SetActive(false)
        self.haveGO:SetActive(true)

        local maxCount = sevenCount

        self._tweenerTab = {}

        for i = 1, 4 do
            local data = self.tongjiList[i]
            if data then
                self.sliders[i].go:SetActive(true)
                self:UpdateOneSlider(i, data, maxCount)
            else
                self.sliders[i].go:SetActive(false)
            end
        end
    end
end

---@param data DHelpPet_PetState
function UIHelpPetManageController:UpdateOneSlider(index, data, maxCount)
    local pet = self:GetModule(PetModule):GetPet(data.m_nPetPstID)
    -- local petTempId = data.m_nTemplateID
    -- local cfg = Cfg.cfg_pet[petTempId]
    -- if cfg then
    self.sliders[index].name:SetText(StringTable.Get(pet:GetPetName()))
    local fightCount = data.m_nFightCount
    local rate = fightCount / maxCount
    local tweener = self.sliders[index].image:DOFillAmount(rate, 0.2)
    self._tweenerTab[#self._tweenerTab + 1] = tweener
    self.sliders[index].countTxt:SetText(StringTable.Get("str_help_pet_ci", fightCount))
    -- else
    -- end
end
function UIHelpPetManageController:OnHide()
    if self._tweenerTab and #self._tweenerTab > 0 then
        for i = 1, #self._tweenerTab do
            local tweener = self._tweenerTab[i]
            tweener:Kill()
        end
    end
    self._tweenerTab = nil
end

function UIHelpPetManageController:AddListener()
end
