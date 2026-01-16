---@class UIActivityBattlePassN5QuestGroupBtn:UICustomWidget
_class("UIActivityBattlePassN5QuestGroupBtn", UICustomWidget)
UIActivityBattlePassN5QuestGroupBtn = UIActivityBattlePassN5QuestGroupBtn

-- 状态
--- @class UIActivityBattlePassN5QuestGroupBtnState
local UIActivityBattlePassN5QuestGroupBtnState = {
    EState_NotStart = 1,
    EState_Normal = 2,
    EState_Over = 3
}
_enum("UIActivityBattlePassN5QuestGroupBtnState", UIActivityBattlePassN5QuestGroupBtnState)

local BtnIdx = {
    Common = 1,
    Level1 = 2,
    Level2 = 3
}

local UIState = {
    Normal = 1,
    Selected = 2,
    Closed = 3,
    Unlock = 4
}

function UIActivityBattlePassN5QuestGroupBtn:_GetComponents()
    -- self._state_Normal = self:GetGameObject("state_Normal")

    -- self._state_NotStart = self:GetGameObject("state_NotStart")
    -- self._state_Over = self:GetGameObject("state_Over")
    -- self._selected = self:GetGameObject("selected")

    -- self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    -- self._txtTitle_Over = self:GetUIComponent("UILocalizationText", "txtTitle_Over")

    self._red = self:GetGameObject("red")
    self._title = self:GetUIComponent("UILocalizationText", "text")
    self._icon = self:GetUIComponent("Image", "icon")
    self._bg = self:GetUIComponent("Image", "bg")
end

function UIActivityBattlePassN5QuestGroupBtn:SetData(index, mode, campaign, componentId, callback)
    self._index = index
    self._mode = mode -- 只有两个按钮的情况 [2] = 2 个按钮， [3] = 3 个按钮
    self._campaign = campaign
    self._componentId = componentId
    ---@type CamQuestComponentInfo
    self._info = self._campaign:GetComponentInfo(componentId)
    self._callback = callback

    self.uiInfo = {
        [BtnIdx.Common] = {
            [UIState.Normal] = {
                icon = "pass_task_icon_daily2",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_1",
                color = Color(1, 204 / 255, 47 / 255)
            },
            [UIState.Selected] = {
                icon = "pass_task_icon_daily1",
                bg = "pass_task_bg_tab_select",
                text = "str_activity_battlepass_tab_quest_group_title_1",
                color = Color(40 / 255, 40 / 255, 40 / 255)
            },
            [UIState.Closed] = {
                icon = "pass_task_icon_daily3",
                bg = "pass_task_bg_tab_ended",
                text = "str_activity_battlepass_tab_quest_group_title_1",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            },
            [UIState.Unlock] = {
                icon = "pass_task_icon_lock",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_1",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            }
        },
        [BtnIdx.Level1] = {
            [UIState.Normal] = {
                icon = "pass_task_icon_onestage2",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_2",
                color = Color(1, 204 / 255, 47 / 255)
            },
            [UIState.Selected] = {
                icon = "pass_task_icon_onestage1",
                bg = "pass_task_bg_tab_select",
                text = "str_activity_battlepass_tab_quest_group_title_2",
                color = Color(40 / 255, 40 / 255, 40 / 255)
            },
            [UIState.Closed] = {
                icon = "pass_task_icon_onestage3",
                bg = "pass_task_bg_tab_ended",
                text = "str_activity_battlepass_tab_quest_group_title_2",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            },
            [UIState.Unlock] = {
                icon = "pass_task_icon_lock",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_2",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            }
        },
        [BtnIdx.Level2] = {
            [UIState.Normal] = {
                icon = "pass_task_icon_secondstage2",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_3",
                color = Color(1, 204 / 255, 47 / 255)
            },
            [UIState.Selected] = {
                icon = "pass_task_icon_secondstage1",
                bg = "pass_task_bg_tab_select",
                text = "str_activity_battlepass_tab_quest_group_title_3",
                color = Color(40 / 255, 40 / 255, 40 / 255)
            },
            [UIState.Closed] = {
                icon = "pass_task_icon_secondstage3",
                bg = "pass_task_bg_tab_ended",
                text = "str_activity_battlepass_tab_quest_group_title_3",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            },
            [UIState.Unlock] = {
                icon = "pass_task_icon_lock",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_3",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            }
        }
    }

    -- 只有两个按钮的情况
    self.uiInfo_2btn = {
        [BtnIdx.Common] = self.uiInfo[BtnIdx.Common],
        [BtnIdx.Level1] = {
            [UIState.Normal] = {
                icon = "pass_task_icon_onestage2",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_2_s",
                color = Color(1, 204 / 255, 47 / 255)
            },
            [UIState.Selected] = {
                icon = "pass_task_icon_onestage1",
                bg = "pass_task_bg_tab_select",
                text = "str_activity_battlepass_tab_quest_group_title_2_s",
                color = Color(40 / 255, 40 / 255, 40 / 255)
            },
            [UIState.Closed] = {
                icon = "pass_task_icon_onestage3",
                bg = "pass_task_bg_tab_ended",
                text = "str_activity_battlepass_tab_quest_group_title_2_s",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            },
            [UIState.Unlock] = {
                icon = "pass_task_icon_lock",
                bg = "",
                text = "str_activity_battlepass_tab_quest_group_title_2_s",
                color = Color(127 / 255, 127 / 255, 127 / 255)
            }
        }
    }
    self._atlas = self:GetAsset("UIBattlePassN5.spriteatlas", LoadType.SpriteAtlas)

    self:_Refresh()
end

function UIActivityBattlePassN5QuestGroupBtn:SetSelected(isSel)
    if isSel and self._state == UIState.Normal then
        self._state = UIState.Selected
        self:setUIInfo()
    elseif not isSel and self._state == UIState.Selected then
        self._state = UIState.Normal
        self:setUIInfo()
    end
end

function UIActivityBattlePassN5QuestGroupBtn:OnShow(uiParams)
    self:_GetComponents()

    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
end

function UIActivityBattlePassN5QuestGroupBtn:OnHide()
end

function UIActivityBattlePassN5QuestGroupBtn:_Refresh()
    self._state = self:_CheckState()
    self:_CheckRedPointAll()
    self:setUIInfo()
end

function UIActivityBattlePassN5QuestGroupBtn:setUIInfo()
    local tb = self._mode == 2 and self.uiInfo_2btn or self.uiInfo
    local uiInfo = tb[self._index][self._state]
    self._title:SetText(StringTable.Get(uiInfo.text))
    self._title.color = uiInfo.color
    self._icon.sprite = self._atlas:GetSprite(uiInfo.icon)
    if string.isnullorempty(uiInfo.bg) then
        self._bg.gameObject:SetActive(false)
    else
        self._bg.sprite = self._atlas:GetSprite(uiInfo.bg)
        self._bg.gameObject:SetActive(true)
    end
end

function UIActivityBattlePassN5QuestGroupBtn:_CheckState()
    --- @type SvrTimeModule
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    if curTime < self._info.m_unlock_time then
        return UIState.Unlock
    elseif curTime > self._info.m_close_time then
        return UIState.Closed
    else
        return UIState.Normal
    end
end

--region OnClick
function UIActivityBattlePassN5QuestGroupBtn:btnOnClick()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    if self._state == UIState.Normal then
        Log.info("UIActivityBattlePassN5QuestGroupBtn:NormalBtnOnClick")
        if self._callback then
            self._callback(self._index)
        end
    elseif self._state == UIState.Selected then
    elseif self._state == UIState.Closed then
        Log.info("UIActivityBattlePassN5QuestGroupBtn:OverBtnOnClick")
        ToastManager.ShowToast(StringTable.Get("str_activity_battlepass_tab_quest_group_over"))
    elseif self._state == UIState.Unlock then
        Log.info("UIActivityBattlePassN5QuestGroupBtn:NotStartBtnOnClick")
        --- @type SvrTimeModule
        local svrTimeModule = self:GetModule(SvrTimeModule)
        local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
        local endTime = self._info.m_unlock_time
        local stamp = endTime - curTime

        if stamp <= 0 then
            self:_Refresh()
            return
        end

        local timeStr = UIActivityHelper.GetFormatTimerStr(stamp)
        local str = StringTable.Get("str_activity_battlepass_tab_quest_group_notstart", timeStr)
        ToastManager.ShowToast(str)
    else
        Log.error("State error:", self._index)
    end
end

--endregion

--region AttachEvent
function UIActivityBattlePassN5QuestGroupBtn:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign and self._campaign._id == campaign_id then
        self:_CheckRedPointAll()
    end
end

function UIActivityBattlePassN5QuestGroupBtn:_CheckRedPointAll()
    self:_CheckRedPoint(self._red, self._componentId)
end

function UIActivityBattlePassN5QuestGroupBtn:_CheckRedPoint(obj, ...)
    local bShow = self._campaign and UIActivityBattlePassHelper.CheckComponentRedPoint(self._campaign, ...)
    obj:SetActive(bShow)
end

--endregion
