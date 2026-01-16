---@class UIQuestGrowthQuestItem:UICustomWidget
_class("UIQuestGrowthQuestItem", UICustomWidget)
UIQuestGrowthQuestItem = UIQuestGrowthQuestItem

function UIQuestGrowthQuestItem:OnShow(uiParams)
    self._animation = self:GetUIComponent("Animation", "UIQuestGrowthQuestItem")
    self._finishGo = self:GetGameObject("finishGo")
    self._noFinishGo = self:GetGameObject("noFinishGo")
    self._questDesc = self:GetUIComponent("UILocalizationText", "questDesc")
    self._imgComplete = self:GetGameObject("imgComplete")
end

function UIQuestGrowthQuestItem:OnHide()
end

---@param quest Quest
function UIQuestGrowthQuestItem:SetData(index, quest, callback, anim)
    if self._animationTask then
        GameGlobal.TaskManager():KillTask(self._animationTask)
    end
    if not quest then
        Log.fatal("### quest is nil. index=", index)
        return
    end
    self._index = index
    self._quest = quest:QuestInfo()
    self._callback = callback
    self._questModule = GameGlobal.GetModule(QuestModule)
    if self._questModule == nil then
        Log.fatal("[quest] error --> questModule is nil !")
        return
    end

    self:_OnValue()

    self._animationTask =
        GameGlobal.TaskManager():StartTask(
        function(TT)
            if index <= 3 then
                if anim then
                    self._animation:Play("uieff_Quest_GrowthQuestItem_In")
                end
            elseif index <= 6 then
                YIELD(TT, 50)
                if anim then
                    self._animation:Play("uieff_Quest_GrowthQuestItem_In")
                end
            else
                YIELD(TT, 100)
                if anim then
                    self._animation:Play("uieff_Quest_GrowthQuestItem_In")
                end
            end
        end
    )
end

function UIQuestGrowthQuestItem:_OnValue()
    if self._quest == nil then
        Log.fatal("[quest] error --> quest is nil ! id --> " .. self._quest.quest_id)
        return
    end
    if self._quest.status <= QuestStatus.QUEST_Accepted then
        self._finishGo:SetActive(false)
        self._noFinishGo:SetActive(true)
    else
        self._finishGo:SetActive(true)
        self._noFinishGo:SetActive(false)
    end

    local progress = ""
    if self._quest.ShowType == 1 then
        local c, d = math.modf(self._quest.cur_progress * 100 / self._quest.total_progress)
        if c < 1 and d > 0 then
            c = 1
        end
        progress = c .. "%"
    else
        if self._quest.cur_progress >= self._quest.total_progress then
            progress = "<color=#fbf806>" .. self._quest.cur_progress .. "</color>/" .. self._quest.total_progress
        else
            progress = self._quest.cur_progress .. "/" .. self._quest.total_progress
        end
    end

    self._imgComplete:SetActive(self._quest.status > QuestStatus.QUEST_Accepted)
    local finishStateTex = "(" .. progress .. ")"
    self._questDesc:SetText(StringTable.Get(self._quest.CondDesc) .. finishStateTex)
end

function UIQuestGrowthQuestItem:bgOnClick()
    if self._callback then
        self._callback(self._index)
    end

    if self._quest.status <= QuestStatus.QUEST_Accepted then
        ---@type UIJumpModule
        local jumpModule = self._questModule.uiModule
        if jumpModule == nil then
            Log.fatal("[quest] error --> uiModule is nil ! --> jumpModule")
            return
        end

        --FromUIType.NormalUI
        local fromParam = {}
        table.insert(fromParam, QuestType.QT_Growth)
        jumpModule:SetFromUIData(FromUIType.NormalUI, "UIQuestController", UIStateType.UIMain, fromParam)
        local jumpType = self._quest.JumpID
        local jumpParams = self._quest.JumpParam
        jumpModule:SetJumpUIData(jumpType, jumpParams)
        jumpModule:Jump()
    else
        ToastManager.ShowToast(StringTable.Get("str_quest_base_growth_item_finish"))
    end
end
