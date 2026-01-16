---@class UIWidgetPetEquipRefine:UICustomWidget
_class("UIWidgetPetEquipRefine", UICustomWidget)
UIWidgetPetEquipRefine = UIWidgetPetEquipRefine

function UIWidgetPetEquipRefine:OnShow()
    --允许模拟输入
    self.enableFakeInput = true
    self:AttachEvent(GameEventType.BattleUIRefreshRefineSwitchBtnState, self._RefreshSwitchBtnState)

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattle1Atlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)

    ---@type UILocalizationText
    self._refineDesc = self:GetUIComponent("UILocalizationText", "refineDesc")
    ---@type UnityEngine.RectTransform
    self._bgRectTransform = self:GetUIComponent("RectTransform", "bg")

    ---@type UnityEngine.RectTransform
    self._refineInfoRT = self:GetUIComponent("RectTransform", "refineInfo")

    self._btnSwitch = self:GetUIComponent("Image", "btnSwitch")

    self._imgSwitch = self:GetUIComponent("Image", "imgSwitch")
    ---@type UnityEngine.RectTransform
    self._imgSwitchRT = self:GetUIComponent("RectTransform", "imgSwitch")

    self._txtSwitch = self:GetUIComponent("UILocalizationText", "txtSwitch")

    ---@type UnityEngine.GameObject
    self._objOnPos = self:GetGameObject("objOnPos")
    ---@type UnityEngine.GameObject
    self._objOffPos = self:GetGameObject("objOffPos")

    ---滑块是否移动中
    self._isMoving = false
end

function UIWidgetPetEquipRefine:HideSelf()
    self:GetGameObject():SetActive(false)
end

function UIWidgetPetEquipRefine:ShowSelf()
    self:GetGameObject():SetActive(true)
end

function UIWidgetPetEquipRefine:SetUIPos(position, isUp)
    self:GetGameObject().transform.position = position
    if isUp then
        self._refineInfoRT.anchorMax = Vector2(0.5, 0)
        self._refineInfoRT.anchorMin = Vector2(0.5, 0)
        self._refineInfoRT.pivot = Vector2(0.5, 0)
    else
        self._refineInfoRT.anchorMax = Vector2(0.5, 1)
        self._refineInfoRT.anchorMin = Vector2(0.5, 1)
        self._refineInfoRT.pivot = Vector2(0.5, 1)
    end
end

function UIWidgetPetEquipRefine:OnHide()
    self.activeSkillCheckPass = true
    self._cannotCastReason = nil
end

---@param isClick boolean
function UIWidgetPetEquipRefine:_RefreshUI(isClick)
    ---点击，则需要一个移动动画
    local moveTime = 0
    if isClick then
        moveTime = 0.2
        self._isMoving = true
    end

    local pos = self._objOnPos.transform.position
    if self._uiState == EquipRefineUIStateType.Off then
        pos = self._objOffPos.transform.position
    end

    self._imgSwitchRT:DOMove(pos, moveTime):OnComplete(
        function()
            self._isMoving = false
            ---@type BuffConfigData
            local buffCfgData = self._buffViewIns:BuffConfigData()
            local viewParam = buffCfgData:GetViewParams()
            local strDesc = viewParam.RefineOnDesc

            if self._uiState == EquipRefineUIStateType.On then
                self._txtSwitch.color = Color.white
                self._txtSwitch:SetText(StringTable.Get("str_battle_pet_refine_ui_on"))
                self._btnSwitch.sprite = self._uiBattle1Atlas:GetSprite("thread_zhudong_btn9")
                self._imgSwitch.sprite = self._uiBattle1Atlas:GetSprite("thread_zhudong_btn11")
            elseif self._uiState == EquipRefineUIStateType.Off then
                self._txtSwitch.color = Color(251 / 255, 251 / 255, 251 / 255, 1)
                self._txtSwitch:SetText(StringTable.Get("str_battle_pet_refine_ui_off"))
                self._btnSwitch.sprite = self._uiBattle1Atlas:GetSprite("thread_zhudong_btn13")
                self._imgSwitch.sprite = self._uiBattle1Atlas:GetSprite("thread_zhudong_btn12")
                strDesc = viewParam.RefineOffDesc
            end

            self._refineDesc:SetText(StringTable.Get(strDesc))
        end
    )
end

---@param petPstID number
---@param buffViewIns BuffViewInstance
function UIWidgetPetEquipRefine:Init(petPstID, buffViewIns)
    self._petPstID = petPstID
    self._buffViewIns = buffViewIns

    self._uiState = InnerGameHelperRender.GetBuffValue(petPstID, "EquipRefineUIState") or EquipRefineUIStateType.On
    self:_RefreshUI()
end

function UIWidgetPetEquipRefine:BtnSwitchOnClick()
    if self._isMoving then
        ---滑块移动中，禁止操作
        return
    end

    if self._uiState == EquipRefineUIStateType.On then
        self._uiState = EquipRefineUIStateType.Off
    elseif self._uiState == EquipRefineUIStateType.Off then
        self._uiState = EquipRefineUIStateType.On
    end

    ---发送状态变更消息
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIBattleSwitchPetEquipRefine, self._uiState, self._petPstID)
end

---@param uiState EquipRefineUIStateType
function UIWidgetPetEquipRefine:_RefreshSwitchBtnState(uiState)
    if uiState ~= self._uiState then
        self._uiState = uiState
    end

    self:_RefreshUI(true)
end
