---@class UIChooseAssistantController:UIController
_class("UIChooseAssistantController", UIController)
UIChooseAssistantController = UIChooseAssistantController

---助理切换类型
---@class AssistantCutType
local AssistantCutType = {
    Star13 = 1,
    Star4 = 2,
    Star5 = 3,
    Star6 = 4,
    StarAll = 5
}
_enum("AssistantCutType", AssistantCutType)

function UIChooseAssistantController:Constructor()
    self._itemCountPerRow = 3
    ---@type PetModule
    self._petModule = self:GetModule(PetModule)

    ---@type RoleModule
    self._roleModule = self:GetModule(RoleModule)

    --高级时装调整边界不进屏幕内
    self._pivot = Vector2(0.5,0.5)
    local realWidth = ResolutionManager.RealWidth()
    local realHeight = ResolutionManager.RealHeight()
    self._safeArea = Vector2(realWidth,realHeight)

    --(all)
    self._filterType = AssistantCutType.StarAll

    self._allPets = self._petModule:GetPets()

    self._firstIn = true

    --特殊处理任务打开选助理界面就把任务关掉--MSG28596	【必现】（测试_常舟)成长第一天任务“更换助理”跳转界面不对 附视频 log	4	缺陷反复修复中	李学森, 1958	08/26/2021	
    local isShowQuestUI = GameGlobal.UIStateManager():IsShow("UIQuestController")
    if isShowQuestUI then
        GameGlobal.UIStateManager():CloseDialog("UIQuestController")
    end   
end

function UIChooseAssistantController:CreateSortParamAll()
    local sortTypeAll = {}

    --星等
    local PetSortParam1 = PetSortParam:New(PetSortType.Star, PetSortOrder.Descending)
    table.insert(sortTypeAll, PetSortParam1)

    --看板娘删掉
    -- --等级
    -- local PetSortParam2 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    -- table.insert(sortTypeAll, PetSortParam2)

    --ID
    local PetSortParam3 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(sortTypeAll, PetSortParam3)

    return sortTypeAll
end
function UIChooseAssistantController:CreateSortParamOther()
    local sortTypeOther = {}

    --看板娘删掉
    -- --等级
    -- local PetSortParam1 = PetSortParam:New(PetSortType.Level, PetSortOrder.Descending)
    -- table.insert(sortTypeOther, PetSortParam1)

    --ID
    local PetSortParam2 = PetSortParam:New(PetSortType.ID, PetSortOrder.Ascending)
    table.insert(sortTypeOther, PetSortParam2)

    return sortTypeOther
end
function UIChooseAssistantController:CreateFilterParam()
    local filterParam = {}
    return filterParam
end

--创建星灵变立绘觉醒等级table
function UIChooseAssistantController:CreatePetChangeCgTable()
    self._pet2grade = {}
    self._petExtraSkin = {}
    local pets = self._petModule:GetPets()
    local cfg_pet = Cfg.cfg_pet {}
    for key, value in pairs(pets) do
        ---@type MatchPet
        local pet = value
        local petid = pet:GetTemplateID()
        local pet_cfg = cfg_pet[petid]
        local pet_cg = HelperProxy:GetInstance():GetPetStaticBody(petid,0,0,PetSkinEffectPath.NO_EFFECT)

        local pet_cfg_grade = Cfg.cfg_pet_grade {PetID = petid}
        for j = 1, #pet_cfg_grade do
            local pet_grade_data = pet_cfg_grade[j]
            local gradeCg = HelperProxy:GetInstance():GetPetStaticBody(petid,pet_grade_data.Grade,0,PetSkinEffectPath.NO_EFFECT)
            if gradeCg ~= pet_cg then
                if pet:GetPetGrade() >= j then
                    self._pet2grade[petid] = j
                    break
                end
            end
        end
        local extraSkin = {}
        local skinData = self._petModule:GetPetSkinsData(petid)
        local tmpTab = {}

        for _, tInfo in ipairs(skinData.skin_info) do
            table.insert(tmpTab,tInfo)
        end
        table.sort(tmpTab,function(a,b)
            return a.skin_id < b.skin_id
        end)

        if skinData then
            for _, skinInfo in ipairs(tmpTab) do
                local pet_skin_cfg = Cfg.cfg_pet_skin[skinInfo.skin_id]
                if pet_skin_cfg then
                    local unlockType = pet_skin_cfg.UnlockType[1]
                    if unlockType == 1 or unlockType == 2 then
                    else
                        table.insert(extraSkin,skinInfo.skin_id)
                    end
                end
            end
        end
        
        if #extraSkin > 0 then
            self._petExtraSkin[petid] = extraSkin
        end
    end
end

function UIChooseAssistantController:OnShow()
    self:CreatePetChangeCgTable()

    self:_GetComponents()

    --当前助理
    self:ShowCurrentAssistant()

    self:_OnValue()

    self:ShowInfo()

    self:_refreshPetSkinList()
    self._posBtnGo:SetActive(self._currID ~= -1)

    self:ChangeChooseState(self._filterType)

    self:_AttachEvent()

    self:ShowBtns()
end
function UIChooseAssistantController:ShowBtns()
    local itemModule = GameGlobal.GetModule(ItemModule)
    local cfg_bg = Cfg.cfg_main_bg{Type = UIChooseAssistantBgType.Cg}
    local showBtn = false
    if cfg_bg and next(cfg_bg) then
        for i = 1, #cfg_bg do
            local cfg = cfg_bg[i]
            local itemid = cfg.ItemID
            local itemcount = itemModule:GetItemCount(itemid)
            if itemcount and itemcount > 0 then
                showBtn = true
                break
            end
        end
    end
    local cgBgBtnGo = self:GetGameObject("cgBgBtn")
    cgBgBtnGo:SetActive(showBtn)
end

function UIChooseAssistantController:ShowCurrentAssistant()
    local petid = self._roleModule.m_choose_painting.pet_template_id

    local defaultPetID
    local grade
    local skin
    local asid
    if petid and petid ~= 0 then
        Log.debug("###[UIChooseAssistantController]petid -- " .. petid)
        defaultPetID = petid
        grade = self._roleModule.m_choose_painting.pet_grade
        skin = self._roleModule.m_choose_painting.skin_id
        asid = self._roleModule.m_choose_painting.board_pet
    else
        defaultPetID = Cfg.cfg_global["main_default_spine_pet_id"].IntValue
        grade = 0
        skin = 0
        asid = 0
    end

    local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue
    local cgRect = self:GetGameObject("cg"):GetComponent("RectTransform")
    cgRect.sizeDelta = Vector2(size[1], size[2])

    Log.debug("###[UIChooseAssistantController]defaultPetID -- " .. defaultPetID)

    self._currID = defaultPetID

    self._currGrade = grade
    self._currSkinId = skin
    self._currAsId = asid

    self._selectID = self._currID
    self._selectGrade = self._currGrade
    self._selectSkinId = self._currSkinId
    self._selectAsId = self._currAsId
end

function UIChooseAssistantController:SortAndFilterPets()
    self._filterParam = self:CreateFilterParam()
    if self._filterType ~= AssistantCutType.StarAll then
        self._sortParam = self:CreateSortParamOther()
    else
        self._sortParam = self:CreateSortParamAll()
    end
    self._pets = {}
    if self._filterType == AssistantCutType.Star13 then
        self._starLeft = 1
        self._starRight = 3
    elseif self._filterType == AssistantCutType.Star4 then
        self._starLeft = 4
        self._starRight = 4
    elseif self._filterType == AssistantCutType.Star5 then
        self._starLeft = 5
        self._starRight = 5
    elseif self._filterType == AssistantCutType.Star6 then
        self._starLeft = 6
        self._starRight = 6
    elseif self._filterType == AssistantCutType.StarAll then
        self._starLeft = 1
        self._starRight = 100
    end

    ---@type ItemModule
    self._itemModule = GameGlobal.GetModule(ItemModule)
    --已经获得的看板娘
    local onlyAs = {}
    --遍历看板娘表，通过关联的物品来检查获得了哪些看板娘
    local cfg_only_assistant = Cfg.cfg_only_assistant{}
    if cfg_only_assistant and table.count(cfg_only_assistant)>0 then
        for key, value in pairs(cfg_only_assistant) do
            local petid = value.PetID
            local itemid = value.ID
            local count = self._itemModule:GetItemCount(itemid)
            if count > 0 then
                if not onlyAs[petid] then
                    onlyAs[petid] = {}
                end
                table.insert(onlyAs[petid],value)
            end
        end
    end
    --把这些看板娘分为已有该星灵和没有该星灵两个列表
    local onlyAsWithPet = {}
    local onlyAsWithoutPet = {}
    for key, value in pairs(onlyAs) do
        local cfgList = value
        local petid = key
        local pet = self._petModule:GetPetByTemplateId(petid)
        if pet then
            onlyAsWithPet[petid] = cfgList
        else
            onlyAsWithoutPet[petid] = cfgList
        end
    end
    --把没有星灵的看板娘创作临时pet类，参与排序
    ---@type Pet[]
    local sortPets = {}
    for key, value in pairs(self._allPets) do
        local pet = value
        table.insert(sortPets,pet)
    end
    for key, value in pairs(onlyAsWithoutPet) do
        local petid = key
        --作假的星灵类参与排序
        ---@type pet_data
        local tempData = pet_data:New()
        tempData.template_id = petid
        tempData.current_skin = 0
        ---@type Pet
        local pet = Pet:New(tempData)
        -- 不要改变顺序
        tempData.grade = 0
        tempData.level = 1
        tempData.awakening = 1
        tempData.equip_lv = 1
        pet:SetData(tempData)

        table.insert(sortPets,pet)
    end
    --排序
    ---@type Pet[]
    local pets = self._petModule:_SortPets(sortPets, self._filterParam, self._sortParam)
    for i = 1, #pets do
        local pet = pets[i]
        if pet:GetPetStar() >= self._starLeft and pet:GetPetStar() <= self._starRight then
            table.insert(self._pets, pet)
        end
    end
    --如果有当前星灵的话
    --筛选完要把当前的加入到第一个
    if self._selectID and self._selectID ~= -1 then
        local firstPet = self._petModule:GetPetByTemplateId(self._selectID)
        if not firstPet then
            Log.error("###[UIChooseAssistantController] firstPet is nil ! id --> ",self._selectID)
        end
        for i = 1, #self._pets do
            local petid = self._pets[i]:GetTemplateID()
            if petid == self._selectID then
                table.remove(self._pets, i)
                break
            end
        end
        table.insert(self._pets, 1, firstPet)
    end

    --最后加入觉醒数据,在这里把没有星灵的看板娘和有星灵的区分开
    ---@type choose_assistant_ui_data_pet[]
    self._showPets = {}
    --{petid=0,grade=0}
    for i = 1, #self._pets do
        local pet = self._pets[i]
        local petid = pet:GetTemplateID()

        local withPet
        --在这个列表里的是没有的星灵
        if onlyAsWithoutPet[petid] then
            withPet = false
        else
            withPet = true
        end

        ---@type choose_assistant_ui_data_pet
        local data = choose_assistant_ui_data_pet:New(petid,0,0,0,withPet)
        table.insert(self._showPets, data)

        --如果有星灵，则正常把皮肤列表加进来，否则，只加进来看板娘皮肤
        if data.withPet then
            --QA 支持时装列表，兼容之前逻辑 
            local baseSkinData = choose_assistant_ui_data_skin:New(petid,0,0,0)
            data:AppendSkinData(baseSkinData)
            --填充到光灵底下
            if self._pet2grade[petid] then
                local gradeSkinData = choose_assistant_ui_data_skin:New(petid,self._pet2grade[petid],0,0)
                data:AppendSkinData(gradeSkinData)
            end
            if self._petExtraSkin[petid] then
                for _, skinId in ipairs(self._petExtraSkin[petid]) do
                    local extraSkinData = choose_assistant_ui_data_skin:New(petid,0,skinId,0)
                    data:AppendSkinData(extraSkinData)
                end
            end
        end
        --把看板娘的加进来
        local asList = onlyAs[petid]
        if asList then
            for i = 1, #asList do
                local extraAsData = choose_assistant_ui_data_skin:New(petid,0,0,asList[i].ID)
                data:AppendAsData(extraAsData)
            end
        end
    end
    -- Log.debug("###self._showPets count-->", #self._showPets)
    --如果当前的星灵未空
    --if self._currID ~= -1 then
        local data = choose_assistant_ui_data_pet:New(-1,-1,-1,-1,true)
        table.insert(self._showPets,1,data)
    --end
end

function UIChooseAssistantController:_GetComponents()
    --self._cutTypePool = self:GetUIComponent("UISelectObjectPath", "cutTypePool")
    ---@type UIDynamicScrollView
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "scrollView")
    self._cg = self:GetUIComponent("RawImageLoader", "cg")
    self._cgGo = self:GetGameObject("cg")
    self._logo = self:GetUIComponent("RawImageLoader", "logo")
    self._logoGo = self:GetGameObject("LeftAnchor")
    self._posBtnGo = self:GetGameObject("posBtn")

    self._name = self:GetUIComponent("UILocalizationText", "name")

    --self._noPet = self:GetGameObject("noPet")

    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil
    )

    self._star13Tex = self:GetUIComponent("UILocalizationText", "star13tex")
    self._star4Tex = self:GetUIComponent("UILocalizationText", "star4tex")
    self._star5Tex = self:GetUIComponent("UILocalizationText", "star5tex")
    self._star6Tex = self:GetUIComponent("UILocalizationText", "star6tex")
    self._starAllTex = self:GetUIComponent("UILocalizationText", "staralltex")

    self._star13Img = self:GetGameObject("star13img")
    self._star4Img = self:GetGameObject("star4img")
    self._star5Img = self:GetGameObject("star5img")
    self._star6Img = self:GetGameObject("star6img")
    self._starAllImg = self:GetGameObject("starallimg")

    self._star13star = self:GetUIComponent("Image", "star13star")
    self._star4star = self:GetUIComponent("Image", "star4star")
    self._star5star = self:GetUIComponent("Image", "star5star")
    self._star6star = self:GetUIComponent("Image", "star6star")

    self._currAssistentTex = self:GetUIComponent("UILocalizationText", "currAssistentTex")
    ---@type UICustomWidgetPool
    self._selectSkinAreaGen = self:GetUIComponent("UISelectObjectPath", "SelectSkinArea")
    if self._selectSkinAreaGen then
        ---@type UIChooseAssistantPetSkinList
        self._selectSkinListWidget = self._selectSkinAreaGen:SpawnObject("UIChooseAssistantPetSkinList")
    end

    self._go = self:GetGameObject()

    ---@type UnityEngine.RectTransform
    self._viewBg = self:GetUIComponent("RectTransform","viewBg")

    self._specialCg = self:GetUIComponent("RawImageLoader","specialCg")
end

function UIChooseAssistantController:_OnValue()
    self:SortAndFilterPets()

    self:CalcCount()

    if self._listShowItemCount <= 0 then
        self._scrollView.gameObject:SetActive(false)
        return
    else
        self._scrollView.gameObject:SetActive(true)
    end

    if self._firstIn then
        self._firstIn = false
        self:_InitScrollView()
    else
        self._scrollView:SetListItemCount(self._listShowItemCount)
        self._scrollView:MovePanelToItemIndex(0, 0)
    end

    self:GetPosAndScale()
    self:SetViewBg()
end
function UIChooseAssistantController:SetViewBg()
    self:TestOnMainCgChangePos()
    self:TestOnMainCgChangeScale()
end 

function UIChooseAssistantController:_AttachEvent()
    self:AttachEvent(GameEventType.OnMainCgChangeSave,self.OnMainCgChangeSave)
    self:AttachEvent(GameEventType.OnMainCgChangePos,self.OnMainCgChangePos)
    self:AttachEvent(GameEventType.OnMainCgChangeScale,self.OnMainCgChangeScale)
end
--type 1-cg,2-bg,11-2mainlobby(cg),22-2mainlobby(bg)  state 1-save,2-cancel,3-default
function UIChooseAssistantController:OnMainCgChangeSave(type,state)
    if type == UIChooseAssistantType.Change2Cg then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeSave,UIChooseAssistantType.Cg2MainLobby,state)
        if state == UIChooseAssistantState.Save then
            -- self._go:SetActive(true)
            --通知主界面保存当前背景偏移值
            self:CloseDialog()
        elseif state == UIChooseAssistantState.Cancel then
            -- self._go:SetActive(true)
            --通知主界面还原之前偏移值
            self:CloseDialog()
        elseif state == UIChooseAssistantState.Default then
            --通知主界面还原默认偏移值
            self._startPos = Vector2(0,0)
            self._startScale = 1
            self._defaultPos = self._startPos
            self._defaultScale = self._startScale
        end
    end
end

function UIChooseAssistantController:OnMainCgChangeScale(type,scale_off)
    if type == UIChooseAssistantType.Change2Cg then
        if self._size then
            --计算是否可以缩放，可以再给主界面发消息
            local targetScale = self._defaultScale + scale_off
            if targetScale > 2 then
                targetScale = 2
            end
            local cantScale = false
            --需要调整
            local needChangePos = 0
            --region
            local up,left,right,down,newScale = self:CalcImgInnerSafeArea(targetScale,self._defaultPos,true)
            if     up and not left and not right and not down then
                --先缩小，再把他挪到上边界
                needChangePos = 2
            elseif up and left and not right and not down then
                --先缩小，再把他挪到左上边界
                needChangePos = 1
            elseif up and not left and right and not down then
                --先缩小，再把它挪到右上边界
                needChangePos = 3
            elseif not up and left and not right and not down then
                --先缩小，再把他挪到左边界
                needChangePos = 4
            elseif not up and left and not right and down then
                --先缩小，再把它挪到左下边界
                needChangePos = 7
            elseif not up and not left and right and not down then
                --先缩小，再把它挪到右边界
                needChangePos = 6
            elseif not up and not left and right and down then
                --先缩小，再把它挪到右下边界
                needChangePos = 9
            elseif not up and not left and not right and down then
                --先缩小，再把他挪到下边界
                needChangePos = 8
            elseif not up and not left and not right and not down then
                --先缩小
                needChangePos = 5
            else
                --不能缩
                cantScale = true
            end
            --endregion
            if not cantScale then
                if newScale then
                    targetScale = newScale
                end
                self._defaultScale = targetScale
                self:TestOnMainCgChangeScale()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Cg2MainLobby,self._defaultScale)
                --这里先挪自己的defaultPos，然后testPos，然后给主界面发消息改defaultPos

                if needChangePos ~= 0 or needChangePos ~= 5 then
                    local _newSize = Vector2(math.floor(self._size.x*self._defaultScale),math.floor(self._size.y*self._defaultScale))
                    local gap = Vector2(0,0)
                    if     needChangePos == 1 then
                        local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                        local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 2 then
                        local _x = 0
                        local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 3 then
                        local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                        local _y = (self._safeArea.y * 0.5) - math.floor(self._defaultPos.y + (_newSize.y * (1-self._pivot.y)))
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 4 then
                        local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                        local _y = 0
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 5 then
                    elseif needChangePos == 6 then
                        local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                        local _y = 0
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 7 then
                        local _x = (self._safeArea.x * -0.5) - math.floor(self._defaultPos.x - (_newSize.x * (self._pivot.x)))
                        local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 8 then
                        local _x = 0
                        local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                        gap = Vector2(_x,_y)
                    elseif needChangePos == 9 then
                        local _x = (self._safeArea.x * 0.5) - math.floor(self._defaultPos.x + (_newSize.x * (1-self._pivot.x)))
                        local _y = (self._safeArea.y * -0.5) - math.floor(self._defaultPos.y - (_newSize.y * (self._pivot.y)))
                        gap = Vector2(_x,_y)
                    end
                    self._defaultPos = self._defaultPos + gap
                    self:TestOnMainCgChangePos()
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Cg2MainLobby,self._defaultPos)
                end
            end
        else
            local targetScale = self._defaultScale + scale_off
            if targetScale > self._scaleMax then
                targetScale = self._scaleMax
            end
            if targetScale < self._scaleMin then
                targetScale = self._scaleMin
            end
            self._defaultScale = targetScale
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,UIChooseAssistantType.Cg2MainLobby,self._defaultScale)
        end
    end
end
function UIChooseAssistantController:OnMainCgChangePos(type,pos_off)
    if type == UIChooseAssistantType.Change2Cg then
        if self._size then
            --计算是否可以移动，可以再给主界面发消息
            --x和y分开计算，手感
            local targetPos = self._defaultPos+pos_off
            local targetPos_x = self._defaultPos+Vector2(pos_off.x,0)
            local targetPos_y = self._defaultPos+Vector2(0,pos_off.y)
            if self:CalcImgInnerSafeArea(self._defaultScale,targetPos,false) then
                self._defaultPos = self._defaultPos+pos_off
                self:TestOnMainCgChangePos()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Cg2MainLobby,self._defaultPos)
            elseif self:CalcImgInnerSafeArea(self._defaultScale,targetPos_x,false) then
                self._defaultPos = targetPos_x
                self:TestOnMainCgChangePos()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Cg2MainLobby,self._defaultPos)
            elseif self:CalcImgInnerSafeArea(self._defaultScale,targetPos_y,false) then
                self._defaultPos = targetPos_y
                self:TestOnMainCgChangePos()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Cg2MainLobby,self._defaultPos)
            end
        else
            local targetPos = self._defaultPos+pos_off
            if targetPos.x > self._moveMaxX then
                targetPos = Vector2(self._moveMaxX,targetPos.y)
            end
            if targetPos.x < self._moveMinX then
                targetPos = Vector2(self._moveMinX,targetPos.y)
            end
            if targetPos.y > self._moveMaxY then
                targetPos = Vector2(targetPos.x,self._moveMaxY)
            end
            if targetPos.y < self._moveMinY then
                targetPos = Vector2(targetPos.x,self._moveMinY)
            end
            self._defaultPos = targetPos
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,UIChooseAssistantType.Cg2MainLobby,self._defaultPos)
        end
    end
end
function UIChooseAssistantController:CalcImgInnerSafeArea(scale,pos,changeScale)
    --获得目标尺寸
    local _newSize = Vector2(math.floor(self._size.x*scale),math.floor(self._size.y*scale))
    local newScale = nil
    if _newSize.x < self._safeArea.x or _newSize.y < self._safeArea.y then
        --这个缩放值会导致宽高不对，先找到正确的缩放值，并返回回去
        local rate_x = self._safeArea.x/_newSize.x
        local rate_y = self._safeArea.y/_newSize.y
        if rate_x > rate_y then
            newScale = self._safeArea.x/self._size.x
        else
            newScale = self._safeArea.y/self._size.y
        end
        _newSize = Vector2(self._size.x*newScale,self._size.y*newScale)
    end
    --上边界不行
    local _up = math.floor(pos.y + (_newSize.y * (1-self._pivot.y))) < (self._safeArea.y * 0.5)
    local _left = math.floor(pos.x - (_newSize.x * (self._pivot.x))) > (self._safeArea.x * -0.5)
    local _right = math.floor(pos.x + (_newSize.x * (1-self._pivot.x))) < (self._safeArea.x * 0.5)
    local _down = math.floor(pos.y - (_newSize.y * (self._pivot.y))) > (self._safeArea.y * -0.5)

    if changeScale then
        return _up,_left,_right,_down,newScale
    else
        if not _up and not _left and not _right and not _down then
            return true
        end
    end
    return false
end
function UIChooseAssistantController:TestOnMainCgChangeScale()
    self._viewBg.localScale = Vector3(self._defaultScale, self._defaultScale, self._defaultScale)
end
function UIChooseAssistantController:TestOnMainCgChangePos()
    self._viewBg.anchoredPosition = self._defaultPos
end
function UIChooseAssistantController:GetPosAndScale()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local petid = roleModule:GetResId()

    local _defaultPetID = 0
    local grade
    local skin
    local asid
    if petid and petid ~= 0 then
        _defaultPetID = petid
        grade = roleModule.m_choose_painting.pet_grade
        skin = roleModule.m_choose_painting.skin_id
        asid = roleModule.m_choose_painting.board_pet
    else
        --获取spine设置
        _defaultPetID = Cfg.cfg_global["main_default_spine_pet_id"].IntValue
        grade = 0
        skin = 0
        asid = 0
    end

    local petModule = GameGlobal.GetModule(PetModule)
    local cfg_pet
    if grade > 0 then
        cfg_pet = Cfg.cfg_pet_grade {PetID = _defaultPetID, Grade = grade}[1]
    else
        cfg_pet = Cfg.cfg_pet[_defaultPetID]
    end

    ---@type MatchPet
    if cfg_pet then
        --看板娘qa
        if asid and asid ~= 0 then
            local cfg_as = Cfg.cfg_only_assistant[asid]
            if not cfg_as then
                Log.error("###[UIChooseMainCgController] cfg_as is nil ! id --> ",asid)
            end
            self._staticSpineSettings = cfg_as.CG
        else
            --时装还没应用
            self._staticSpineSettings =
            HelperProxy:GetInstance():GetMainLobbyStaticBody(_defaultPetID, grade, skin, PetSkinEffectPath.NO_EFFECT)
            if not self._staticSpineSettings then
                self._staticSpineSettings =
                HelperProxy:GetInstance():GetPetStaticBody(_defaultPetID, grade, skin, PetSkinEffectPath.NO_EFFECT)
            end
        end
    else
        self._staticSpineSettings = _defaultPetID .. "_cg"
    end

    -----------------------------------
    self._startPos = Vector2(0,0)
    self._startScale = 1

    local open_id = GameGlobal.GameLogic():GetOpenId()
    local title = "MAIN_OFFSET_"
    local key = title .. open_id .. "_" .. self._staticSpineSettings

    local pos_offset_str = LocalDB.GetString(key,"null")
    if pos_offset_str == "null" then
    else
        local strs = string.split(pos_offset_str,"|")
        local _x = tonumber(strs[1])
        local _y = tonumber(strs[2])

        self._startPos = Vector2(_x,_y)
        self._startScale = tonumber(strs[3])
    end

    --如果self._currentChooseID不等于0
    self._size = nil
    --获取基准Size
    if self._currSkinId and self._currSkinId > 0 then
        local cfg = Cfg.cfg_pet_skin[self._currSkinId]
        if not cfg then
            Log.error("###[UIChooseAssistantController] cfg is nil ! id --> ",self._currSkinId)
        end
        if cfg.MainLobbySize then
            self._size = Vector2(cfg.MainLobbySize[1],cfg.MainLobbySize[2])

            --如果size小于屏幕分辨率，则设为分辨率
            local rate_x = 1
            local rate_y = 1

            if self._size.x*self._startScale < self._safeArea.x then
                rate_x = self._size.x*self._startScale/self._safeArea.x
            end
            if self._size.y*self._startScale < self._safeArea.y then
                rate_y = self._size.y*self._startScale/self._safeArea.y
            end

            if rate_x < 1 or  rate_y < 1 then
                local changex = true
                if rate_x < rate_y then
                    changex = true
                else
                    changex = false
                end
                if changex then
                    self._startScale = self._startScale/rate_x
                else
                    self._startScale = self._startScale/rate_y
                end
            end
        end
    end

    self._defaultPos = self._startPos
    self._defaultScale = self._startScale

    if self._size then
        self._viewBg.sizeDelta = self._size
    end

    --region
    --缩放系数
    self._scaleK = 0.2
    self._touchScaleK = 0.001

    --缩放限制
    self._scaleMax = 2
    self._scaleMin = 0.5

    --移动系数
    self._moveK = 1
    --移动限制
    self._moveMaxX = 1000
    self._moveMinX = -1000
    self._moveMaxY = 500
    self._moveMinY = -500

    --计算鼠标移动位置
    self._mousePos2 = 0
    self._mousePos = 0

    --动作
    self._scaling = false
    self._draging = false

    --手指移动位置
    self._touch0Pos = 0
    self._touch0Pos2 = 0

    --手指间距
    self._touchDis = 0
    self._touchDis2 = 0

    --算移动
    local pixels = Cfg.cfg_aircraft_camera["clickAndDragPixelLength"].Value
    self._startMove = pixels * pixels
    --endregion
end

function UIChooseAssistantController:OnHide()
end
function UIChooseAssistantController:_InitScrollView()
    if self._scrollView then
        self._scrollView:InitListView(
            self._listShowItemCount,
            function(scrollView, index)
                return self:_InitListView(scrollView, index)
            end
        )
    end
end

function UIChooseAssistantController:CalcCount()
    self._petCount = table.count(self._showPets)
    self._listShowItemCount = math.ceil(self._petCount / self._itemCountPerRow)
end

function UIChooseAssistantController:_InitListView(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIChooseAssistantItem", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local heartItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._petCount then
            heartItem:GetGameObject():SetActive(false)
        else
            self:ShowHeartItem(heartItem, itemIndex)
        end
    end
    return item
end

---@param heartItem UIChooseAssistantItem
function UIChooseAssistantController:ShowHeartItem(heartItem, index)
    local pet = self._showPets[index]

    heartItem:GetGameObject():SetActive(true)
    if (pet ~= nil) then
        heartItem:SetData(
            pet,
            self._currID,
            self._currGrade,
            self._currSkinId,
            self._currAsId,
            self._selectID,
            self._selectGrade,
            self._selectSkinId,
            self._selectAsId,
            function(petid, grade,skinId,asId)
                self._selectID = petid
                self._selectGrade = grade
                self._selectSkinId = skinId
                self._selectAsId = asId
                self:_refreshPetSkinList()
            end,
            function(petid, grade,skinId,asId)
                return self:GetHeadIconByIdAndGrade(petid, grade,skinId,asId)
            end
        )
    end
end

function UIChooseAssistantController:GetHeadIconByIdAndGrade(petid, grade,skinId,asId)
    local _petid = petid
    local _grade = grade
    local _skinId = skinId
    local _asId = asId

    if _asId and _asId ~= 0 then
        _skinId = 0
    end
    local icon = HelperProxy:GetInstance():GetPetHead(_petid, _grade,_skinId,PetSkinEffectPath.HEAD_ICON_CHANGE_ASSIST)--时装 暂未应用
    return icon
end

function UIChooseAssistantController:ChangeCutType(cutType)
    self._filterType = cutType

    self:_OnValue()
end

---@param pet Pet
function UIChooseAssistantController:ShowInfo()
    if self._selectID == -1 then
        return
    end
    local petid = self._selectID
    local grade = self._selectGrade
    local skinId = self._selectSkinId
    local asId = self._selectAsId

    
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnAssistantPetItemClick, self._selectID)
    
    local isSpecialCg = false
    local cgName
    local logo
    local name
    if asId and asId ~= 0 then
        local cfg = Cfg.cfg_only_assistant[asId]
        if not cfg then
            Log.error("###[UIChooseAssistantController] cfg is nil ! id --> ",asId)
        end
        cgName = cfg.CG
        if not cgName then
            Log.error("###[UIChooseAssistantController] cgName is nil ! id --> ",asId)
        end
        
        local cfg_pet = Cfg.cfg_pet[petid]
        if not cfg_pet then
            Log.error("###[UIChooseAssistantController] cfg_pet is nil ! id --> ",petid)
        end
        name = cfg_pet.Name
        logo = cfg_pet.Logo
    else
        isSpecialCg = true
        cgName = HelperProxy:GetInstance():GetMainLobbyStaticBody(petid, grade,skinId,PetSkinEffectPath.BODY_CHANGE_ASSIST)
        if not cgName then
            isSpecialCg = false
            cgName = HelperProxy:GetInstance():GetPetStaticBody(petid, grade,skinId,PetSkinEffectPath.BODY_CHANGE_ASSIST)--时装暂未应用
        end
        local pet = self._petModule:GetPetByTemplateId(petid)
        logo = pet:GetPetLogo()
        name = pet:GetPetName()
    end

    self._cg.gameObject:SetActive(not isSpecialCg)
    self._specialCg.gameObject:SetActive(isSpecialCg)
    if isSpecialCg then
        local size = Vector2(2539,1439)
        if skinId then
            local cfg_skin = Cfg.cfg_pet_skin[skinId]
            if cfg_skin then
                local mainSize = cfg_skin.MainLobbySize
                if mainSize then
                    size = Vector2(mainSize[1],mainSize[2])
                end
            end
        end
        local _rect = self._specialCg.gameObject:GetComponent(typeof(UnityEngine.RectTransform))
        _rect.sizeDelta = size
        _rect.localScale = Vector3(1,1,1)
        self._specialCg:LoadImage(cgName)
    else
        self._cg:LoadImage(cgName)
        -- local size = Cfg.cfg_global["ui_interface_common_size"].ArrayValue
        -- self._cgGo:GetComponent("RectTransform").sizeDelta = Vector2(size[1], size[2])
        UICG.SetTransform(self._cg.transform, self:GetName(), cgName)
    end

    self._logo:LoadImage(logo)
    
    self._name:SetText(StringTable.Get(name))
    local isCurrPet 
    if asId and asId ~= 0 then
        isCurrPet = (self._currAsId == asId)
    else
        isCurrPet = (self._currID == petid and self._currGrade == grade and self._currSkinId == skinId)
    end

    if isCurrPet then
        self._currAssistentTex:SetText(StringTable.Get("str_assistant_current_assistant"))
    else
        self._currAssistentTex:SetText(StringTable.Get("str_assistant_preview_assistant"))
    end
end

function UIChooseAssistantController:ChangeChooseState(type)
    local c = Color(1, 1, 1, 1)
    self._star13Tex.color = c
    self._star4Tex.color = c
    self._star5Tex.color = c
    self._star6Tex.color = c
    self._starAllTex.color = c

    self._star13Img:SetActive(false)
    self._star4Img:SetActive(false)
    self._star5Img:SetActive(false)
    self._star6Img:SetActive(false)
    self._starAllImg:SetActive(false)

    self._star13star.color = c
    self._star4star.color = c
    self._star5star.color = c
    self._star6star.color = c

    local c_yellow = Color(1, 253 / 255, 0, 1)
    if type == AssistantCutType.Star13 then
        self._star13Tex.color = c_yellow
        self._star13Img:SetActive(true)
        self._star13star.color = c_yellow
    elseif type == AssistantCutType.Star4 then
        self._star4Tex.color = c_yellow
        self._star4Img:SetActive(true)
        self._star4star.color = c_yellow
    elseif type == AssistantCutType.Star5 then
        self._star5Tex.color = c_yellow
        self._star5Img:SetActive(true)
        self._star5star.color = c_yellow
    elseif type == AssistantCutType.Star6 then
        self._star6Tex.color = c_yellow
        self._star6Img:SetActive(true)
        self._star6star.color = c_yellow
    elseif type == AssistantCutType.StarAll then
        self._starAllTex.color = c_yellow
        self._starAllImg:SetActive(true)
    end
end

function UIChooseAssistantController:star13OnClick()
    if self._filterType ~= AssistantCutType.Star13 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self:ChangeCutType(AssistantCutType.Star13)
        self:ChangeChooseState(AssistantCutType.Star13)
    end
end
function UIChooseAssistantController:star4OnClick()
    if self._filterType ~= AssistantCutType.Star4 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self:ChangeCutType(AssistantCutType.Star4)
        self:ChangeChooseState(AssistantCutType.Star4)
    end
end
function UIChooseAssistantController:star5OnClick()
    if self._filterType ~= AssistantCutType.Star5 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self:ChangeCutType(AssistantCutType.Star5)
        self:ChangeChooseState(AssistantCutType.Star5)
    end
end
function UIChooseAssistantController:star6OnClick()
    if self._filterType ~= AssistantCutType.Star6 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self:ChangeCutType(AssistantCutType.Star6)
        self:ChangeChooseState(AssistantCutType.Star6)
    end
end
function UIChooseAssistantController:starallOnClick()
    if self._filterType ~= AssistantCutType.StarAll then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
        self:ChangeCutType(AssistantCutType.StarAll)
        self:ChangeChooseState(AssistantCutType.StarAll)
    end
end

function UIChooseAssistantController:sskinBtnOnClick()
    ToastManager.ShowToast(StringTable.Get("str_pet_config_function_no_open"))
end

function UIChooseAssistantController:posBtnOnClick()
    self._go:SetActive(false)
    local isShowQuestUI = GameGlobal.UIStateManager():IsShow("UIQuestController")
    if isShowQuestUI then
        GameGlobal.UIStateManager():CloseDialog("UIQuestController")
    end
    GameGlobal.UIStateManager():ShowDialog("UIChooseMainCgController",UIChooseAssistantType.Change2Cg)
end
function UIChooseAssistantController:bgBtnOnClick()
    self:CloseDialog()
    local isShowQuestUI = GameGlobal.UIStateManager():IsShow("UIQuestController")
    if isShowQuestUI then
        GameGlobal.UIStateManager():CloseDialog("UIQuestController")
    end
    GameGlobal.UIStateManager():ShowDialog("UIChooseMainBgController",UIChooseAssistantType.Change2Cg)
end
function UIChooseAssistantController:cgBgBtnOnClick()
    self:CloseDialog()
    local isShowQuestUI = GameGlobal.UIStateManager():IsShow("UIQuestController")
    if isShowQuestUI then
        GameGlobal.UIStateManager():CloseDialog("UIQuestController")
    end
    GameGlobal.UIStateManager():ShowDialog("UIChooseMainBgController",UIChooseAssistantType.Change2Bg)
end

function UIChooseAssistantController:changeBtnOnClick()
    self:Lock("UIChooseAssistantController:changeBtnOnClick")
    self:StartTask(self.ChangeRequest, self)
end
function UIChooseAssistantController:ChangeRequest(TT)
    local id = self._selectID
    local grade = self._selectGrade
    local skinID = self._selectSkinId
    local asID = self._selectAsId
    --看板娘设置为空
    if id == -1 then
        grade = -1
        skinID = -1
        asID = -1
    end
    local res = self._roleModule:RequestChoosePainting(TT, id, grade, skinID, asID)
    self:UnLock("UIChooseAssistantController:changeBtnOnClick")

    if res:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnAssistantChanged, id, grade, skinID, asID)
        self:CloseDialog()
    else
        Log.debug("###UIChooseAssistantController id-->", id, "|grade-->", grade, "|skin-->", skinID, "|as-->",asID)
        Log.fatal("###UIChooseAssistantController -- change assistent res error ! result --> ", res:GetResult())
    end
end

--刷新时装列表区域
function UIChooseAssistantController:_refreshPetSkinList()
    local petId = self._selectID
    --如果是没有星灵
    self._cgGo:SetActive(petId ~= -1)
    self._logoGo:SetActive(petId ~= -1)
    if petId == -1 then
        self._name:SetText(StringTable.Get("str_assistant_current_pet_null"))
        if self._currID == petId then
            self._currAssistentTex:SetText(StringTable.Get("str_assistant_current_assistant"))
        else
            self._currAssistentTex:SetText(StringTable.Get("str_assistant_preview_assistant"))
        end         
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnAssistantPetItemClick, self._selectID)
        return
    end
    --todo index
    local curPetData = nil
    for index, petData in ipairs(self._showPets) do
        if petData.petid == petId then
            curPetData = petData
            break
        end
    end
    if self._selectSkinListWidget then
        if not self._skilListSetted then
            self._selectSkinListWidget:SetRefreshUiCallBack(
                function(petid, grade,skinId,asId)
                    self._selectID = petid
                    self._selectGrade = grade
                    self._selectSkinId = skinId
                    self._selectAsId = asId
                    self:ShowInfo()
                end)
            self._selectSkinListWidget:SetCheckIsCurSkinCallBack(
                function(petid, grade,skinId,asId)
                    local isCur
                    if (self._currAsId and self._currAsId ~= 0) or (asId and asId ~= 0) then
                        if asId == self._currAsId then
                            isCur = true
                        end
                    else
                        isCur = (petid == self._currID and grade == self._currGrade and skinId == self._currSkinId)
                    end
                    return isCur
                end
                )
            self._skilListSetted = true
        end
        if curPetData then
            self._selectSkinListWidget:RefreshData(curPetData)
        end
    end

end

function UIChooseAssistantController:OnUpdate(deltaTimeMS)
    if self._selectSkinListWidget then
        self._selectSkinListWidget:OnUpdate(deltaTimeMS)
    end
end
