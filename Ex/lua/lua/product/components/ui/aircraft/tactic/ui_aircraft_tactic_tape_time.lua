---@class UIAircraftTacticTapeTime : UICustomWidget
_class("UIAircraftTacticTapeTime", UICustomWidget)
UIAircraftTacticTapeTime = UIAircraftTacticTapeTime
function UIAircraftTacticTapeTime:OnShow(uiParams)
    self:InitWidget()
    self._airModule = self:GetModule(AircraftModule)
    ---@type AircraftTacticRoom
    self._tacticRoom = self._airModule:GetRoomByRoomType(AirRoomType.TacticRoom)
end
function UIAircraftTacticTapeTime:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.countdown = self:GetUIComponent("UILocalizationText", "countdown")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    ---@type UnityEngine.GameObject
    self.max = self:GetGameObject("max")
    --generated end--
    self._making = self:GetGameObject("making")
    self._progress = self:GetUIComponent("Image", "progress")
end
function UIAircraftTacticTapeTime:SetData(tapeCount, activityN8)
    self._activityN8 = activityN8

    local tapeCeiling = nil
    if self._activityN8 then
        -- 获取活动 以及本窗口需要的组件
        ---@type UIActivityCampaign
        self._campaign = UIActivityCampaign:New()
        self._campaign:LoadCampaignInfo_Local(ECampaignType.CAMPAIGN_TYPE_N8)
        ---@type CombatSimulatorComponent
        local component = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_CombatSimulator, 1)

        tapeCeiling = component:GetCartridgeCeiling()
    else
        tapeCeiling = self._tacticRoom:GetCartridgeLimit()
    end

    self.count:SetText(tapeCount .. "<color=#ff3030>/</color>" .. tapeCeiling)
    if tapeCount < tapeCeiling then
        self.max:SetActive(false)
        self._making:SetActive(true)
    else
        self._making:SetActive(false)
        self.max:SetActive(true)
        self.countdown:SetText(StringTable.Get("str_aircraft_tactic_tape_stopped"))
        self._progress.fillAmount = 0
    end
end
function UIAircraftTacticTapeTime:Tick(time)
    self.countdown:SetText(HelperProxy:GetInstance():FormatTime_2(time))

    if self._activityN8 then
        ---@type CombatSimulatorComponent
        local component = self._campaign:GetComponentByType(CampaignComType.E_CAMPAIGN_COM_CombatSimulator, 1)
        local cd = component:GetCartridgeNexTickSec()
        self._progress.fillAmount = 1 - (time / cd)
    else
        local cd = self._tacticRoom:GetOneCartridgeSpeed()
        self._progress.fillAmount = 1 - (time / cd)
    end
end
