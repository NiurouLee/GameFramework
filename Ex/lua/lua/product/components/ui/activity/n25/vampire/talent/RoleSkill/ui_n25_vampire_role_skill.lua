---@class UIN25VampireRoleSkill : UIController
---@field curRoleSkillId number 当前选中的空裔技能的id
_class("UIN25VampireRoleSkill", UIController)
UIN25VampireRoleSkill = UIN25VampireRoleSkill

function UIN25VampireRoleSkill:Constructor()
    self.mCampaign = self:GetModule(CampaignModule)
    self.data = self.mCampaign:GetN25Data()
end

function UIN25VampireRoleSkill:OnShow(uiParams)
    ---@type ATransitionComponent
    self.atc = self:GetGameObject():GetComponent(typeof(ATransitionComponent))
    self.atc.enabled = true
    self.atc:PlayEnterAnimation(true)
    ---@type UICustomWidgetPool
    self.poolContent = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    self.goBtnReplace = self:GetGameObject("BtnReplace")
    ---@type UnityEngine.UI.Image
    self.imgReplace = self:GetUIComponent("Image", "BtnReplace")
    ---@type UILocalizationText
    self.txtReplace = self:GetUIComponent("UILocalizationText", "txtReplace")

    local roleSkill = self.data:GetCurRoleSkill()
    self.curRoleSkillId = 0
    if roleSkill then
        self.curRoleSkillId = roleSkill.skillId --默认显示当前装备的空裔技能
    end

    self:Flush()
    self:SelectSkillItem()
end
function UIN25VampireRoleSkill:OnHide()
end

function UIN25VampireRoleSkill:Flush()
    self:FlushSkillInfo()
    self:FlushList()
end
function UIN25VampireRoleSkill:FlushSkillInfo()
    local curRoleSkill = self.data:GetSkillBySkillId(self.curRoleSkillId)
    if not curRoleSkill then
        curRoleSkill = self.data:GetFstRoleSkill() --如果没装备空裔技能，则默认显示第1个空裔技能
        self.curRoleSkillId = curRoleSkill.skillId
    end
    local icon, name, desc = curRoleSkill:IconNameDesc()
    self.txtName:SetText(name)
    self.txtDesc:SetText(desc)
    if self:IsRoleSkillLock(curRoleSkill.skillId) then
        self.goBtnReplace:SetActive(false)
    else
        self.goBtnReplace:SetActive(true)
        local roleSkill = self.data:GetCurRoleSkill()
        if roleSkill and roleSkill.skillId == self.curRoleSkillId then
            self.imgReplace.color = Color.gray
            self.imgReplace.raycastTarget = false
            self.txtReplace:SetText(StringTable.Get("str_n25_vampire_equiped"))
        else
            self.imgReplace.color = Color.white
            self.imgReplace.raycastTarget = true
            self.txtReplace:SetText(StringTable.Get("str_n25_vampire_replace"))
        end
    end
    self:SelectSkillItem()
end
function UIN25VampireRoleSkill:FlushList()
    local roleSkills = self.data:GetRoleSkills()
    local len = table.count(roleSkills)
    self.poolContent:SpawnObjects("UIN25VampireRoleSkillItem", len)
    ---@type UIN25VampireRoleSkillItem[]
    local uis = self.poolContent:GetAllSpawnList()
    for i, roleSkill in pairs(roleSkills) do
        local ui = uis[i]
        ui:Flush(
            roleSkill,
            self,
            function()
                if self.curRoleSkillId == roleSkill.skillId then
                    return
                end
                self.curRoleSkillId = roleSkill.skillId
                self:FlushSkillInfo()
            end
        )
    end
end
---@return boolean 空裔技能是否未解锁
function UIN25VampireRoleSkill:IsRoleSkillLock(roleSkillId)
    local tier = self.data:GetTierBySkillId(roleSkillId)
    if tier then
        if tier:IsLock() then --层未解锁，则技能未解锁
            return true
        else
            local roleSkill = self.data:GetSkillBySkillId(roleSkillId)
            if roleSkill then
                local level, maxLevel = roleSkill:CurMaxLevel()
                if level <= 0 then --技能未激活，则技能未解锁
                    return true
                end
            end
        end
    end
    return false
end

function UIN25VampireRoleSkill:SelectSkillItem()
    ---@type UIN25VampireRoleSkillItem[]
    local uis = self.poolContent:GetAllSpawnList()
    for index, uiv in ipairs(uis) do
        if self.curRoleSkillId == uiv:SkillId() then
            uiv:Select(true)
        else
            uiv:Select(false)
        end
    end
end

--region OnClick
function UIN25VampireRoleSkill:BgOnClick(go)
    self:PlayAnimClose()
end
function UIN25VampireRoleSkill:BtnReplaceOnClick(go)
    self:StartTask(
        function(TT)
            local key = "HandleBloodsuckerResetTalentTree"
            self:Lock(key)
            local row, index = self.data:GetSkillRowIndexBySkillId(self.curRoleSkillId)
            local c = self.data:GetComponentVampire()
            local res = AsyncRequestRes:New()
            c:HandleBloodsuckerSelectSkill(TT, res, row, index) --【消息】替换
            if N25Data.CheckCode(res) then
                self:PlayAnimClose()
            end
            self:UnLock(key)
        end,
        self
    )
end
--endregion

function UIN25VampireRoleSkill:PlayAnimClose()
    self:StartTask(
        function(TT)
            local key = "UIN25VampireRoleSkillPlayAnimClose"
            self:Lock(key)
            self.atc:PlayLeaveAnimation(true)
            YIELD(TT, 140)
            self:CloseDialog()
            self:UnLock(key)
        end,
        self
    )
end
