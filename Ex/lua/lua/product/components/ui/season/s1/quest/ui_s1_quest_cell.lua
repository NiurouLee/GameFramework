---@class UIS1QuestCell : UICustomWidget
_class("UIS1QuestCell", UICustomWidget)
UIS1QuestCell = UIS1QuestCell

function UIS1QuestCell:_GetPosCfg(index)
    local cfgs = Cfg.cfg_season_quest_item_pos{}
    local idx = (index - 1) % #cfgs + 1
    local cfg = cfgs[idx]
    return cfg
end

function UIS1QuestCell:OnShow(uiParams)
end

function UIS1QuestCell:OnHide()
end

function UIS1QuestCell:SetData(type, index, component, quest, questState, claimCallback, tipsCallback)
    --- @type CampaignQuestComponent
    self._component = component
    ---@type MobileQuestInfo
    self._quest = quest:QuestInfo()
    self._questState = questState
    self._claimCallback = claimCallback
    self._tipsCallback = tipsCallback

    self._roleAsset = self._quest.rewards[1]

    self:_SetPos(type, index)
    self:_SetState(questState)

    self:_SetDesc()
    self:_SetItem()
end

function UIS1QuestCell:PlayAnimationInSequence(index)
    local cfg = self:_GetPosCfg(index)
    local animName, duration = cfg.AnimName, cfg.Duration
    local delay = (index - 1) * 30
    UIWidgetHelper.PlayAnimationInSequence(self, "_anim", "_anim", animName, delay, duration, nil, true)
end

function UIS1QuestCell:_SetState(state)
    local tb = { 
        [CampaignQuestStatus.CQS_NotStart] = { "_state_NotStart" },
        [CampaignQuestStatus.CQS_Accepted] = { "_state_Accepted", "_bg_1", "_item" },
        [CampaignQuestStatus.CQS_Completed] = { "_state_Completed", "_bg_1", "_bg_2", "_bg_3", "_item" },
        [CampaignQuestStatus.CQS_Taken] = { "_state_Taken", "_bg_1", "_bg_2" },
        [CampaignQuestStatus.CQS_Over] = { "_state_Over" }
    }
    local objs = UIWidgetHelper.GetObjGroupByWidgetName(self, tb)
    UIWidgetHelper.SetObjGroupShow(objs, state)
end

function UIS1QuestCell:_SetPos(type, index)
    local cfg = self:_GetPosCfg(index)
    local pos = cfg.Pos
    local r = (type == 1) and 1 or 0.7
    local x, y = pos[1] * r, pos[2]

    UIWidgetHelper.SetAnchoredPosition(self, "_pos", x, y)
end

function UIS1QuestCell:_SetDesc()
    local title = StringTable.Get(self._quest.CondDesc)
    local cur, total, str = self._component:GetQuestProgressString(self._quest)
    str = string.format("(%s/%s)", UIActivityHelper.GetColorText("#F7C65E", cur), total)
    UIWidgetHelper.SetLocalizationText(self, "_desc_Accepted", title)
    UIWidgetHelper.SetLocalizationText(self, "_prog_Accepted", str)
    UIWidgetHelper.SetLocalizationText(self, "_desc_Completed", title)

    local cfg = UISeasonCfgHelper.CfgSeason_QuestItemClient(self._quest.quest_id)
    local descTaken, descId = cfg.DescTaken, cfg.DescId
    descId = UIActivityHelper.FormatNumber_PreZero(2, tonumber(descId))
    UIWidgetHelper.SetLocalizationText(self, "_desc_stateTaken", StringTable.Get(descTaken))
    UIWidgetHelper.SetLocalizationText(self, "_desc_id", descId)
end

function UIS1QuestCell:_SetItem()
    UIWidgetHelper.SetItemIcon(self, self._roleAsset.assetid , "_icon")
    UIWidgetHelper.SetLocalizationText(self, "_count", self._roleAsset.count)
end

--region Event

function UIS1QuestCell:IconOnClick(go)
    if self._tipsCallback then
        self._tipsCallback(self._roleAsset.assetid, go.transform.position)
    end
end

function UIS1QuestCell:StateCompletedBtnOnClick(go)
    if self._claimCallback then
        self._claimCallback(self, self._quest)
    end
end

function UIS1QuestCell:StateTakenBtnOnClick(go)
    self:ShowDialog("UISeasonQuestDetail", { self._quest.quest_id })
end

--endregion
