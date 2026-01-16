---@class UITeamsSelectItem:UICustomWidget
_class("UITeamsSelectItem", UICustomWidget)
UITeamsSelectItem = UITeamsSelectItem

function UITeamsSelectItem:OnShow()
    self._module = self:GetModule(MissionModule)
    self.ctx = self._module:TeamCtx()
    ---@type UnityEngine.UI.Toggle
    self._tgl = self:GetUIComponent("Toggle", "tgl")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._btnModify = self:GetGameObject("btnModify")
    --
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:RootUIOwner():GetAsset("UITeams.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.TeamToggleIsOnChanged, self.FlushSth)

    self._line = self:GetUIComponent("Image", "line")
    self._etl = UICustomUIEventListener.Get(self._tgl.gameObject)
    self._modEtl = UICustomUIEventListener.Get(self._btnModify)
    
end

function UITeamsSelectItem:OnHide()
    self:DetachEvent(GameEventType.TeamToggleIsOnChanged, self.FlushSth)
end

---@param id number 队伍id
function UITeamsSelectItem:Init(id, uiCtl, tglGroup, scrollRect)
    self._id = id
    ---@type UITeams
    self._uiCtrl = uiCtl
    self._tgl.group = tglGroup
    self._scrollRect = scrollRect --父物体滑动列表
    local teamid = self.ctx:GetCurrTeamId()
    self:FlushTglIsOn(self._id == teamid)
    self:FlushSth()
    self:FlushName(self._id)
    self:RegUIEventTriggerListener()
end

function UITeamsSelectItem:FlushName(teamId)
    if not self._txtName then
        return
    end
    local teams = self.ctx:Teams() --名字信息只用主线队伍的就行
    local team = teams:Get(teamId)
    if team then
        local name = team.name
        if not name or string.len(name) == 0 then
            name = StringTable.Get("str_discovery_formation_" .. teamId)
        end
        self._txtName:SetText(name)
    else
        Log.error("### team is nil. teamId = ", teamId)
    end
end


function UITeamsSelectItem:OnValueChange()
    --清理助战信息
    local hpm = self:GetModule(HelpPetModule)
    hpm:UI_ClearHelpPet()
    if self._id ~= self.ctx:GetCurrTeamId() then
        GameGlobal.GetModule(PetModule):ClearAllPetSortInfo()
    end
    self._uiCtrl:FlushTeam(self._id)

    GameGlobal.EventDispatcher():Dispatch(GameEventType.TeamToggleIsOnChanged)
end

function UITeamsSelectItem:FlushTglIsOn(isOn)
    self._tgl.isOn = isOn
end

function UITeamsSelectItem:FlushSth()
    if self._tgl.isOn then
        self._line.sprite = self._atlas:GetSprite("map_xian1_frame")
    else
        self._line.sprite = self._atlas:GetSprite("map_xian2_frame")
    end
end

function UITeamsSelectItem:btnModifyOnClick(go)
    self:ShowDialog("UITeamsNameModify", self._id)
end

function UITeamsSelectItem:GetId()
    return self._id
end

function UITeamsSelectItem:RegUIEventTriggerListener()
    if self._scrollRect then
        self:AddUICustomEventListener(
                self._etl,
            UIEvent.BeginDrag,
            function(eventData)
                self._tgl.enabled = false
                if self._scrollRect then
                    self._scrollRect:OnBeginDrag(eventData)
                end
            end
        )
        self:AddUICustomEventListener(
            self._etl,
            UIEvent.Drag,
            function(eventData)
                if self._scrollRect then
                    self._scrollRect:OnDrag(eventData)
                end
            end
        )
        self:AddUICustomEventListener(
            self._etl,
            UIEvent.EndDrag,
            function(eventData)
                self._tgl.enabled = true
                if self._scrollRect then
                    self._scrollRect:OnEndDrag(eventData)
                end
            end
        )
        self:AddUICustomEventListener(
                self._modEtl,
            UIEvent.BeginDrag,
            function(eventData)
                if self._scrollRect then
                    self._scrollRect:OnBeginDrag(eventData)
                end
            end
        )
        self:AddUICustomEventListener(
            self._modEtl,
            UIEvent.Drag,
            function(eventData)
                if self._scrollRect then
                    self._scrollRect:OnDrag(eventData)
                end
            end
        )
        self:AddUICustomEventListener(
            self._modEtl,
            UIEvent.EndDrag,
            function(eventData)
                if self._scrollRect then
                    self._scrollRect:OnEndDrag(eventData)
                end
            end
        )
        self._tgl.onValueChanged:AddListener(
        function(value)
            if value then
                AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
                self:OnValueChange()
            end
        end
    )
    end 
end
