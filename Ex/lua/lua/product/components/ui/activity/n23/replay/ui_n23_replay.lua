---@class UIN23Replay:UIController
_class("UIN23Replay", UIController)
UIN23Replay = UIN23Replay

function UIN23Replay:Constructor(ui_root_transform)
    self.mCampaign = self:GetModule(CampaignModule)
    self.data = self.mCampaign:GetN23Data()

    self.curReplayIdx = 0
end

function UIN23Replay:OnShow(uiParams)
    ---@type UIN23Shop
    self.uiShop = uiParams[1]
    ---@type UILocalizationText
    self.txtIndex = self:GetUIComponent("UILocalizationText", "txtIndex")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UICustomWidgetPool
    self.poolContent = self:GetUIComponent("UISelectObjectPath", "Content")
    self.goBtnPrev = self:GetGameObject("BtnPrev")
    self.goBtnNext = self:GetGameObject("BtnNext")

    self:Init()
end

function UIN23Replay:OnHide()
end

function UIN23Replay:Init()
    local len = table.count(self.data.replays)
    self.poolContent:SpawnObjects("UIN23ReplayItem", len)
    ---@type UIN23ReplayItem[]
    local uis = self.poolContent:GetAllSpawnList()
    for i, replay in pairs(self.data.replays) do
        local ui = uis[i]
        ui:Flush(i, replay.id, self)
    end

    self.curReplayIdx = 1
    self:Flush()
end
function UIN23Replay:Flush()
    local len = table.count(self.data.replays)
    self.sv.horizontalNormalizedPosition = (self.curReplayIdx - 1) / (len - 1)
    local preZeroIndex = UIActivityHelper.GetZeroStrFrontNum(2, self.curReplayIdx) .. self.curReplayIdx
    local preZeroLen = UIActivityHelper.GetZeroStrFrontNum(2, len) .. len
    self.txtIndex:SetText("<size=132>" .. preZeroIndex .. "</size>/" .. preZeroLen)
    if self.curReplayIdx <= 1 then
        self.goBtnPrev:SetActive(false)
    else
        self.goBtnPrev:SetActive(true)
    end
    if self.curReplayIdx >= len then
        self.goBtnNext:SetActive(false)
    else
        self.goBtnNext:SetActive(true)
    end
end

function UIN23Replay:Replay(id)
    self.uiShop:Replay(id)
end

--region OnClick
function UIN23Replay:BgOnClick(go)
    self:CloseDialog()
end
function UIN23Replay:BtnReplayOnClick(go)
    -- ---@type UIN23ReplayItem[]
    -- local uis = self.poolContent:GetAllSpawnList()
    -- for i, ui in pairs(uis) do
    --     if ui.index == self.curReplayIdx then
    --         GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityShopBuySuccess, self.replay.exchangeId)
    --         break
    --     end
    -- end
    -- self:CloseDialog()
end
function UIN23Replay:BtnPrevOnClick(go)
    if self.curReplayIdx <= 1 then
        self.curReplayIdx = 1
        return
    end
    self.curReplayIdx = self.curReplayIdx - 1
    self:Flush()
end
function UIN23Replay:BtnNextOnClick(go)
    local len = table.count(self.data.replays)
    if self.curReplayIdx >= len then
        self.curReplayIdx = len
        return
    end
    self.curReplayIdx = self.curReplayIdx + 1
    self:Flush()
end
--endregion
