--
---@class UIPetEquipRefinePanelLock : UICustomWidget
_class("UIPetEquipRefinePanelLock", UICustomWidget)
UIPetEquipRefinePanelLock = UIPetEquipRefinePanelLock
--初始化
function UIPetEquipRefinePanelLock:OnShow(uiParams)
    self:InitWidget()
    self:AttachEvent(GameEventType.ItemCountChanged, self._FlushItemsCount)
end
--获取ui组件
function UIPetEquipRefinePanelLock:InitWidget()
    ---@type UILocalizationText
    self.txtEffName = self:GetUIComponent("UILocalizationText", "txtEffName")

    ---@type UILocalizationText
    self.txtIndex = self:GetUIComponent("UILocalizationText", "txtIndex")

    self.conditionGo = self:GetGameObject("conditionList")
    self.consumeGo = self:GetGameObject("consume")

    self.needcoin = self:GetUIComponent("UILocalizationText", "needcoin")

    ---@type UICustomWidgetPool
    self.cunsumeListPool = self:GetUIComponent("UISelectObjectPath", "cunsumeList")
    self.animation = self:GetUIComponent("Animation", "animation")

end
--设置数据
function UIPetEquipRefinePanelLock:SetData(index, petData, refinePanel)
    self.petData = petData
    self.refineIndex = index
    self.txtEffName:SetText(self:GetPreEffName(index))
    self.txtIndex:SetText(self:GetPreEffName(index))
    self.refinePanel = refinePanel

    --attr
    if not self.attr then
        ---@type UICustomWidgetPool
        local attrPool = self:GetUIComponent("UISelectObjectPath", "attr")
        self.attr = attrPool:SpawnObject("UIPetEquipRefineAttr")
    end
    --refresh attr
    --test
    self.attr:SetData(petData:GetTemplateID(), index)

    --skill
    if not self.skill then
        ---@type UICustomWidgetPool
        local skillPool = self:GetUIComponent("UISelectObjectPath", "skill")
        self.skill = skillPool:SpawnObject("UIPetEquipRefineSkill")
    end
    --refresh skill
    self.skill:SetData(petData:GetTemplateID(), index)

    --condition
   self:RefreshConditions()

    -- self:RefreshConsume()
end

function UIPetEquipRefinePanelLock:GetPreEffName(index)
    local lanKey = "str_pet_equip_refine_preview_1"
    if index == 2 then
        lanKey = "str_pet_equip_refine_preview_2"
    elseif index == 3 then
        lanKey = "str_pet_equip_refine_preview_3"
    end
    return StringTable.Get(lanKey)
end

function UIPetEquipRefinePanelLock:RefreshConditions()
    self.showCondition = true
    local petData = self.petData
    self.conditionGo:SetActive(true)
    self.consumeGo:SetActive(false)
     ---@type UICustomWidgetPool
     local conditionPool = self:GetUIComponent("UISelectObjectPath", "conditionList")

     --Cfg.cfg_pet_equip_refine
    local refineCfg = UIPetEquipHelper.GetRefineCfg(petData:GetTemplateID(), 1)
    if not refineCfg then
        return
    end

    local strCondition = refineCfg.OpenCondition
    local conditions = StrToArray2:GetInstance():GetArray(strCondition, '&', ',', nil, true)
    
    local len = table.count(conditions)
    self.conditionList = conditionPool:SpawnObjects("UIPetEquipCondition", len)

    for i, v in ipairs(conditions) do
        local isOpen , str, curValue, limitValue, curLevel, limitLevel =  ConditionCheck:GetInstance():Check(v, true)
        local item = self.conditionList[i]
        if item then
            local strLimitValue
            local strCurValue 

            if limitLevel then
                --str = str .. " Lv"..limitLevel
               
                strLimitValue = 1
                if isOpen then
                    strCurValue = 1
                else
                    strCurValue = 0
                end
            else
                 strCurValue = curValue or ""
                 strLimitValue = limitValue or ""
            end

            -- strCurValue = curValue or ""
            -- strLimitValue = limitValue or ""
            
            item:SetData(isOpen, str, "(" .. strCurValue .. "/" .. strLimitValue .. ")")
        end
    end
end

function UIPetEquipRefinePanelLock:RefreshConsume()
    self.showCondition = false
    self.conditionGo:SetActive(false)
    self.consumeGo:SetActive(true)

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
            false,
            function(itemID, condition, pos)
                self:SetItemTip(itemID, condition, pos)
            end
        )
    end
end

function UIPetEquipRefinePanelLock:GetConsumDataList()
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

function UIPetEquipRefinePanelLock:SetItemTip(itemID, condition, pos)
    GameGlobal.UIStateManager():ShowDialog("UIItemGetPathController", itemID, nil, nil, condition)
end

function UIPetEquipRefinePanelLock:SwitchBtnOnClick(go)
    if self.showCondition then
        self:RefreshConsume()
    else
        self:RefreshConditions()
    end
end


function UIPetEquipRefinePanelLock:PlayAni(aniName)
    if self.animation then
        --local test = self.animation:GetEnumerator()
        self.animation:Play(aniName)
    end
end

function UIPetEquipRefinePanelLock:TipsBtnOnClick(go)
    if self.refinePanel then
        self.refinePanel:ShowTips(go)
    end
end

function UIPetEquipRefinePanelLock:_FlushItemsCount()
    if not  self.showCondition then
        self:RefreshConsume()
    end
end