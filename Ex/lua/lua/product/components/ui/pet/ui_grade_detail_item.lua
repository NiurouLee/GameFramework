---@class UIGradeDetailItem:UICustomWidget
_class("UIGradeDetailItem", UICustomWidget)
UIGradeDetailItem = UIGradeDetailItem

--[[
    用于处理突破详情，包括立绘改变、主动技提升、连锁技提升、工作技提升、获得新的工作技
]]
function UIGradeDetailItem:Constructor()
    self._skillInfo = nil
end
function UIGradeDetailItem:OnShow(uiParams)
    self:GetComponents()
end

function UIGradeDetailItem:GetComponents()
    self._lineGo = self:GetGameObject("line")

    self._beforeTips = self:GetUIComponent("UILocalizationText", "beforeTips")

    self._arrow = self:GetGameObject("GradeArrow")

    self._skillToGo = self:GetGameObject("skillTo")

    self._afterTipsGo = self:GetGameObject("GradeAfterTips")

    self._skillFrom = self:GetUIComponent("UISelectObjectPath", "skillFrom")
    self._skillTo = self:GetUIComponent("UISelectObjectPath", "skillTo")
end

function UIGradeDetailItem:OnHide()
end
---@param skillInfo UIFightSkillChangeData
function UIGradeDetailItem:SetData(petData, skillInfo, idx, allCount,lastGrade,nextGrade,lastBreak,nextBreak)
    local isLast = (idx == allCount)
    self._lineGo:SetActive(not isLast)
    self._petData = petData
    self._skillInfo = skillInfo
    self._tag = skillInfo.type
    self._lastGrade = lastGrade
    self._nextGrade = nextGrade
    self._lastBreak = lastBreak
    self._nextBreak = nextBreak

    self._isChain = false
    self._isActive = false
    if self._tag == "active" then
        self._isActive = true
    elseif self._tag == "extra" then
    elseif self._tag == "passive" then
    elseif self._tag == "chain" then
        self._isChain = true
    elseif self._tag == "work" then
    end

    self._state = self._skillInfo.changeType
    -- if self._isChain then
    --     for i = 1, #self._skillInfo.value do
    --         local item = self._skillInfo.value[i]
    --         if item.state ~= PetSkillChangeState.NoChange then
    --             self._state = item.state
    --             break
    --         end
    --     end
    -- else
    --     self._state = self._skillInfo.value.state
    -- end

    self:ShowSkill()
end

function UIGradeDetailItem:ShowSkill()
    if self._state == PetSkillChangeState.Improved then
        self._beforeTips:SetText(StringTable.Get("str_pet_config_before_grade_info"))

        self._arrow:SetActive(true)

        self._skillToGo:SetActive(true)

        self._afterTipsGo:SetActive(true)

        --old
        -- local skillInfoFrom = {skillList = {}}
        -- local skillInfoTo = {skillList = {}}
        -- if self._isChain then
        --     local chainSkill = self._skillInfo.value
        --     for i = 1, table.count(chainSkill) do
        --         skillInfoFrom.skillList[#skillInfoFrom.skillList + 1] = chainSkill[i].from
        --     end
        --     for i = 1, table.count(chainSkill) do
        --         skillInfoTo.skillList[#skillInfoTo.skillList + 1] = chainSkill[i].to
        --     end
        -- else
        --     local otherSkill = self._skillInfo.value
        --     skillInfoFrom.skillList[#skillInfoFrom.skillList + 1] = otherSkill.from
        --     skillInfoTo.skillList[#skillInfoTo.skillList + 1] = otherSkill.to

        --     if self._isActive then
        --         --主动技变体有变化的idx，不算本身
        --         skillInfoTo.var_change_idx = self._skillInfo.var_change_idx
        --     end
        -- end

        --new
        local skillInfoFrom = {skillList = self._skillInfo.from}
        local skillInfoTo = {skillList = self._skillInfo.to,param = self._skillInfo.param}

        ---@type UIFightSkillItem
        local skillLuaFrom = self._skillFrom:SpawnObject("UIFightSkillItem")
        skillLuaFrom:SetData(skillInfoFrom, self._petData,nil,nil,nil,self._lastGrade,self._lastBreak)

        ---@type UIFightSkillItem
        local skillLuaTo = self._skillTo:SpawnObject("UIFightSkillItem")
        skillLuaTo:SetData(skillInfoTo, self._petData,nil,nil,nil,self._nextGrade,self._nextBreak)
    elseif self._state == PetSkillChangeState.NewGain then
        local showTex = ""
        if self._tag == "passive" then
            showTex = "str_pet_config_unlock_equip_skill"
        elseif self._tag == "work" then
            showTex = "str_pet_config_unlock_work_skill"
        elseif self._tag == "chain" then
            showTex = "str_pet_config_unlock_chain_skill"
        elseif self._tag == "active" then
            showTex = "str_pet_config_unlock_active_skill"
        elseif self._tag == "extra" then
            showTex = "str_pet_config_unlock_active_skill"
        end

        self._beforeTips:SetText(StringTable.Get(showTex))

        self._arrow:SetActive(false)

        self._skillToGo:SetActive(false)

        self._afterTipsGo:SetActive(false)

        --old
        -- local skillInfoTo = {skillList = {}}
        -- if self._isChain then
        --     local chainSkill = self._skillInfo.value
        --     for i = 1, table.count(chainSkill) do
        --         skillInfoTo.skillList[#skillInfoTo.skillList + 1] = chainSkill[i].to
        --     end
        -- else
        --     local otherSkill = self._skillInfo.value
        --     skillInfoTo.skillList[#skillInfoTo.skillList + 1] = otherSkill.to
        -- end
        --new
        local skillInfoTo = {skillList = self._skillInfo.to,param = self._skillInfo.param}

        ---@type UIFightSkillItem
        local skillLua = self._skillFrom:SpawnObject("UIFightSkillItem")
        skillLua:SetData(skillInfoTo, self._petData)
    end
end
