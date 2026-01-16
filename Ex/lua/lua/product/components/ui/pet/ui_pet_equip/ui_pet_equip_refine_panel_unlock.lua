-- 界面布局
-- 由于布局逻辑修改，使用两种布局
-- canRefine节点：未完成精炼（可以精炼，不可以精炼）
-- canotRefine 节点： 已完成精炼 
---@class UIPetEquipRefinePanelUnLock : UICustomWidget
_class("UIPetEquipRefinePanelUnLock", UICustomWidget)
UIPetEquipRefinePanelUnLock = UIPetEquipRefinePanelUnLock
--初始化
function UIPetEquipRefinePanelUnLock:OnShow(uiParams)
    ---@type PetModule
    self._petModule = GameGlobal.GameLogic():GetModule(PetModule)
    ---@type RoleModule
    self._roleModule = GameGlobal.GetModule(RoleModule)

    self:InitWidget()

    self._waitTime = Cfg.cfg_global["shakeWaitTime"].IntValue or 2000
    self._shakeX = Cfg.cfg_global["shakeOffsetX"].IntValue or 10
    self._shakeY = Cfg.cfg_global["shakeOffsetY"].IntValue or 10
    self:AttachEvent(GameEventType.ItemCountChanged, self._FlushItemsCount)
end

function UIPetEquipRefinePanelUnLock:OnHide()
    if self._goldTweer then
        self._goldTweer:Kill()
        self._goldTweer = nil
    end
    -- if self._event then
    --     GameGlobal.Timer():CancelEvent(self._event)
    --     self._event = nil
    -- end
    if self.goldEvent then
        GameGlobal.Timer():CancelEvent(self.goldEvent)
        self.goldEvent = nil
    end

    self:StopTween()
end
--获取ui组件
function UIPetEquipRefinePanelUnLock:InitWidget()
    ---@type UICustomWidgetPool
    self.attrPool = self:GetUIComponent("UISelectObjectPath", "attr")
    ---@type UICustomWidgetPool
    self.skillPool = self:GetUIComponent("UISelectObjectPath", "skill")
    ---@type UICustomWidgetPool
    self.attr2Pool = self:GetUIComponent("UISelectObjectPath", "attr2")
    ---@type UICustomWidgetPool
    self.skill2Pool = self:GetUIComponent("UISelectObjectPath", "skill2")

    ---@type UICustomWidgetPool
    self.cunsumeListPool = self:GetUIComponent("UISelectObjectPath", "cunsumeList")

    ---@type UnityEngine.GameObject
    self.consumeGo = self:GetGameObject("consumeGo")
    ---@type UILocalizationText
    self.needcoin = self:GetUIComponent("UILocalizationText", "needcoin")
    ---@type UnityEngine.GameObject
    self.canRefineGo = self:GetGameObject("canRefineGo")
    ---@type UnityEngine.GameObject
    self.refineFinishGo = self:GetGameObject("refineFinishGo")
    ---@type UnityEngine.GameObject
    self.cannotRefineGo = self:GetGameObject("cannotRefine")
    ---@type UnityEngine.GameObject
    self.refineBtnGo = self:GetGameObject("refineBtnGo")
    ---@type UnityEngine.GameObject
    self.refineFinishGo = self:GetGameObject("refineFinishGo")

    self._consumeRect = self:GetUIComponent("RectTransform", "xiaohaobi")
    self._leftLine = self:GetUIComponent("Graphic", "leftLine")
    self._consumeName = self:GetUIComponent("Graphic", "consumeName")
    self._coinBg = self:GetUIComponent("Graphic", "coin")
    self._needcoin = self:GetUIComponent("Graphic", "needcoin")
    self._rightLine = self:GetUIComponent("Graphic", "rightLine")
    ---@type UILocalizationText
    self._refineBtnTex = self:GetUIComponent("UILocalizationText","refineBtnTex")
    self.animation = self:GetUIComponent("Animation", "animation")

    ---@type UILocalizationText
    self.txtEffName = self:GetUIComponent("UILocalizationText", "txtEffName")
    self.txtEffName2 = self:GetUIComponent("UILocalizationText", "txtEffName2")

    self.cannotrefineTipsGo = self:GetGameObject("cannotrefineTipsGo")
end
--设置数据
function UIPetEquipRefinePanelUnLock:SetData(index, petData, refineSuccCall, petEquipController, refinePanel)
    self.refineIndex = index
    ---@type MatchPet
    self.petData = petData
    self.refineSuccCall = refineSuccCall
    self.petEquipController = petEquipController
    self.refinePanel = refinePanel

    self.txtEffName:SetText(self:GetPreEffName(index))
    self.txtEffName2:SetText(self:GetPreEffName(index))
    self:RefreshAll()
end

function UIPetEquipRefinePanelUnLock:RefreshAll()
    local refineLv = self.petData:GetEquipRefineLv()
    local canRefine = false
    local refineFinish = false
    if self.refineIndex == 1 then
        canRefine = true
        refineFinish = self.refineIndex <= refineLv
    else
        canRefine = self.refineIndex - refineLv <= 1
        refineFinish = refineLv >= self.refineIndex
    end
    self.canRefine = canRefine
    self.refineFinish = refineFinish
    
    -- if canRefine and not refineFinish then
    --     self.canRefineGo:SetActive(true)
    --     self.cannotRefineGo:SetActive(false)
    --     self.refineBtnGo:SetActive(not refineFinish)
    --     self:RefreshConsume(refineFinish)
    --     self:RefreshAttrAndSkill()
    --     -- if self.refineIndex == 1 then
    --     --     self._refineBtnTex:SetText(StringTable.Get("str_pet_equip_refine_unlock"))
    --     -- else
    --     --     self._refineBtnTex:SetText(StringTable.Get("str_pet_equip_refine"))
    --     -- end
    --     self._refineBtnTex:SetText(StringTable.Get("str_pet_equip_refine"))
    -- else
    --     self.canRefineGo:SetActive(false)
    --     self.cannotRefineGo:SetActive(true)
    --     self:RefreshAttrAndSkill2(refineFinish)
    -- end

    if refineFinish then
        self.canRefineGo:SetActive(false)
        self.cannotRefineGo:SetActive(true)
        self:RefreshAttrAndSkill2(refineFinish)
    else
        self.canRefineGo:SetActive(true)
        self.cannotRefineGo:SetActive(false)
        self.refineBtnGo:SetActive(self.canRefine)
        self.cannotrefineTipsGo:SetActive(not self.canRefine)
        self:RefreshConsume(refineFinish)
        self:RefreshAttrAndSkill()
        self._refineBtnTex:SetText(StringTable.Get("str_pet_equip_refine"))
    end
end

function UIPetEquipRefinePanelUnLock:RefreshConsume(refineFinish)
    if self._consumItem then
        self._consumItem:StopTween()
        self._consumItem = nil
    end
    self.refineFinish = refineFinish
    local dataList , cost = self:GetConsumDataList()
    self._materialItemInfos  = dataList
    self._needGoldCount = cost
    self.needcoin:SetText(cost)
    local len = #dataList
    self.cunsumeListPool:ClearWidgets()
    local itemList = self.cunsumeListPool:SpawnObjects("UIConsumaItem", len)
    self._materialItemList = itemList
    for i = 1, len, 1 do
        local subItem = itemList[i]
        subItem:SetData(
            self.petData,
            dataList[i],
            i,
            refineFinish,
            function(itemID, condition, pos)
                self:SetItemTip(itemID, condition, pos)
            end
        )
    end
end

function UIPetEquipRefinePanelUnLock:GetConsumDataList()
    local dataList = {}
    local costGold = 0
    local refineCfg = UIPetEquipHelper.GetRefineCfg(self.petData:GetTemplateID(), self.refineIndex)
    if not refineCfg then
        return dataList, costGold
    end

    if self.refineIndex == 1 then
        local strCondition = refineCfg.UnLockCondition
        local conditions = StrToArray2:GetInstance():GetArray(strCondition, '&', ',', nil, true)
        if conditions then
            for _, subCondition in pairs(conditions) do
                local conditionId = subCondition[1]
                if ConditionType.CT_PetGradeLevel == conditionId then
                    if subCondition[4] then
                        local levelCondition = {}
                        levelCondition.ConditionType = "Level"
                        levelCondition.condition = tonumber(subCondition[4])
                        table.insert(dataList, levelCondition)
                    end
                elseif ConditionType.CT_PeAffinityLevel == conditionId then
                    if subCondition[3] then
                        local affinityCondition = {}
                        affinityCondition.ConditionType = "Affinity"
                        affinityCondition.condition = tonumber(subCondition[3])
                        table.insert(dataList, affinityCondition)
                    end
                end
            end
        end
    end

    --
    local cunsumeItems = refineCfg.NeedItem
    for _, item in pairs(cunsumeItems) do
        local itemCondition = {}
            local itemId  = tonumber(item[1])
            local itemNum =  tonumber(item[2])
            if itemId == RoleAssetID.RoleAssetGold then
                costGold = itemNum
            else
                itemCondition.ConditionType = "Consum"
                itemCondition.ID = itemId
                itemCondition.condition = itemNum
                table.insert(dataList, itemCondition)
            end
    end
    return dataList, costGold
end

function UIPetEquipRefinePanelUnLock:RefreshAttrAndSkill()
     --attr
    if not self.attr then
        self.attr = self.attrPool:SpawnObject("UIPetEquipRefineAttr")
    end
    self.attr:SetData(self.petData:GetTemplateID(), self.refineIndex)
 
    --skill
    if not self.skill then
        self.skill = self.skillPool:SpawnObject("UIPetEquipRefineSkill")
    end
    self.skill:SetData(self.petData:GetTemplateID(), self.refineIndex)
end

function UIPetEquipRefinePanelUnLock:RefreshAttrAndSkill2(refineFinish)
    --attr
    if not self.attr2 then
       self.attr2 = self.attr2Pool:SpawnObject("UIPetEquipRefineAttr")
   end
   self.attr2:SetData(self.petData:GetTemplateID(), self.refineIndex)
  
   --skill
   if not self.skill2 then
       self.skill2 = self.skill2Pool:SpawnObject("UIPetEquipRefineSkill")
   end
   self.skill2:SetData(self.petData:GetTemplateID(), self.refineIndex)

    self.refineFinishGo:SetActive(refineFinish)
    self.cannotrefineTipsGo:SetActive(not refineFinish)
end

--按钮点击
function UIPetEquipRefinePanelUnLock:RefineBtnOnClick(go)
    if self:CheckMaterialItems() then

         --金币
        local bagNum = self._roleModule:GetGold()
        if bagNum < self._needGoldCount then
            self:GoldDOShakePosition()
            return
        end

         local pstID = self.petData:GetPstID()
        --  ---@type UIPetModule
        --  local uiModule = self._petModule.uiModule
        --  --觉醒的提升
        --  self._skillVaryInfosParams = uiModule:GetDiffWithGrade(self.petData, false)

         self:StartRefine(pstID)
    end
    
end

function UIPetEquipRefinePanelUnLock:StartRefine(pstID)
    self:Lock("UIPetEquipRefinePanelUnLock:StartRefine")
    GameGlobal.TaskManager():StartTask(self.RefineCallback, self, pstID)
end

function UIPetEquipRefinePanelUnLock:RefineCallback(TT, pstID)
    local res = self._petModule:ReqUpEquipRefineLvUp(TT, pstID)
    if res:GetSucc() then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N29RefineSuccess)
        if self.petEquipController then
            self.petEquipController:ShowRefineSuccEffect(TT)
            YIELD(TT, 2000)
        end
        if self.refineIndex == 3 then
            self:RefreshAll()
        end

        if self.refineSuccCall then
            self.refineSuccCall()
        end
        YIELD(TT, 350)
    else
        Log.fatal( pstID .. "  refine  failed !!! result --> ", res:GetResult())
    end
    self:UnLock("UIPetEquipRefinePanelUnLock:StartRefine")
end

function UIPetEquipRefinePanelUnLock:CheckMaterialItems()
    local isOk, index = self:CheckIndexMaterialItems()
    if isOk == false then
        local item = self._materialItemList[index]
        self._consumItem = item
        item:DOShakePosition()

        --材料不足音效
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIMaterialNotEnough)

        return false
    end

    return true
end

function UIPetEquipRefinePanelUnLock:CheckIndexMaterialItems()
    if self._materialItemInfos == nil then
        return true, 1
    end
    for index, itemInfo in pairs(self._materialItemInfos) do
        if itemInfo.ConditionType == "Level" then
            local petLevel = self.petData:GetPetLevel()
            if petLevel < itemInfo.condition then
                return false, index
            end
        elseif itemInfo.ConditionType == "Affinity" then
            local petAffinity = self.petData:GetPetAffinityLevel()
            if petAffinity < itemInfo.condition then
                return false, index
            end
        elseif itemInfo.ConditionType == "Coin" then
            local bagNum = self._roleModule:GetGold()
            if bagNum < itemInfo.condition then
                return false, -1
            end
        else
            local bagNum = self._roleModule:GetAssetCount(itemInfo.ID)
            if bagNum < itemInfo.condition then
                return false, index
            end
        end
    end
    return true, 1
end

function UIPetEquipRefinePanelUnLock:GoldDOShakePosition()
    if self._goldTweer then
        if self._goldTweer:IsPlaying() then
            return
        end
    end
    if self._goldTweer then
        self._goldTweer:Kill()
        self._consumeRect.anchoredPosition = Vector2(0, 0)
    end
    self:SetColor(false)
    self._goldTweer =
        self._consumeRect:DOShakePosition(1, Vector3(self._shakeX, self._shakeY, 0)):OnComplete(
        function()
            self:StartTimer()
        end
    )
end

function UIPetEquipRefinePanelUnLock:StopTween()
    if self._consumItem then
        self._consumItem:StopTween()
        self._consumItem = nil
    end
end


function UIPetEquipRefinePanelUnLock:SetItemTip(itemID, condition, pos)
    GameGlobal.UIStateManager():ShowDialog("UIItemGetPathController", itemID, nil, nil, condition)
end

function UIPetEquipRefinePanelUnLock:StartTimer()
    if self.goldEvent then
        GameGlobal.Timer():CancelEvent(self.goldEvent)
        self.goldEvent = nil
    end
    self.goldEvent =
        GameGlobal.Timer():AddEvent(
        self._waitTime,
        function()
            self:SetColor(true)
        end
    )
end

function UIPetEquipRefinePanelUnLock:SetColor(isDefaultColor)
    local color = nil
    if isDefaultColor then
        color = Color(0.96, 0.81, 0.14)
    else
        color = Color(1, 0.4, 0.32)
    end
    if color ~= nil then
        self._leftLine.color = color
        self._consumeName.color = color
        self._coinBg.color = color
        self._needcoin.color = color
        self._rightLine.color = color
    end
end

function UIPetEquipRefinePanelUnLock:PlayAni(aniName)
    if self.animation then
        self.animation:Play(aniName)
    end
end


function UIPetEquipRefinePanelUnLock:PLayInAni()
    if not self.refineFinish then
        self:PlayAni("uieff_UIPetEquipRefinePanelUnLock_in")
    else
        self:PlayAni("uieff_UIPetEquipRefinePanelUnLock_cannotRefine_in")
    end
end

function UIPetEquipRefinePanelUnLock:PLayOutAni()
    if not self.refineFinish then
        self:PlayAni("uieff_UIPetEquipRefinePanelUnLock_out")
    else
        self:PlayAni("uieff_UIPetEquipRefinePanelUnLock_cannotRefine_out")
    end
end

--刷新物品数量
function UIPetEquipRefinePanelUnLock:_FlushItemsCount()
    if self.canRefine then
        self:RefreshConsume(self.refineFinish)
    end
end

function UIPetEquipRefinePanelUnLock:GetPreEffName(index)
    local lanKey = "str_pet_equip_refine_preview_1"
    if index == 2 then
        lanKey = "str_pet_equip_refine_preview_2"
    elseif index == 3 then
        lanKey = "str_pet_equip_refine_preview_3"
    end
    return StringTable.Get(lanKey)
end

function UIPetEquipRefinePanelUnLock:TipsBtnOnClick(go)
    if self.refinePanel then
        self.refinePanel:ShowTips(go)
    end
end

function UIPetEquipRefinePanelUnLock:TipsBtn2OnClick(go)
    if self.refinePanel then
        self.refinePanel:ShowTips(go)
    end
end