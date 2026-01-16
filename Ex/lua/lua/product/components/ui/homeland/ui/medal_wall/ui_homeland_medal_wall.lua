---@class UIHomelandMedalWall:UIController
_class("UIHomelandMedalWall", UIController)
UIHomelandMedalWall = UIHomelandMedalWall

function UIHomelandMedalWall:OnShow(uiParams)
    ---@type HomelandModule
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self._uiHomelandModule = self._homelandModule:GetUIModule()
    ---@type HomelandClient
    self._homelandClient = self._uiHomelandModule:GetClient()
    self._isVisit = self._homelandClient:IsVisit()
    self._btnEdit = self:GetGameObject("BtnEdit")
    self._btnEdit:SetActive(not self._isVisit)

    ---@type UnityEngine.GameObject
    self._mobileMedalWallControlGO = self:GetGameObject("MobileMedalWallControl")
    ---@type UICustomWidgetPool
    self._mobileMedalWallConWidgetPool = self:GetUIComponent("UISelectObjectPath", "MobileMedalWallControl")
    self:Init()

    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, false)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.EnterFindTreasure)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandAllUI, false)

    --隐藏主角
    ---@type HomelandMainCharacterController
    local characterController = self._homelandClient:CharacterManager():MainCharacterController()
    characterController:ShowHideCharacter(false)
    --隐藏Pet
    ---@type HomelandPetManager
    local petMng = self._homelandClient:PetManager()
    petMng:SetPetsVisible(false)
    --隐藏小地图
    local homelandMainController = GameGlobal.UIStateManager():GetController("UIHomelandMain")
    if homelandMainController then
        homelandMainController:SetMinimapStatus(false)
    end

    local cameraTransform = uiParams[1]
    --切换相机及输入模式
    self._homelandClient:InputManager():ChangeMedalWallController(true, cameraTransform)
    self._homelandClient:CameraManager():SetMedalWallCameraActive(true)
end

function UIHomelandMedalWall:Init()
    self._mobileMedalWallControlGO:SetActive(true)
    ---@type UIWidgetHomelandMedalWallController
    self._uiWidgetMedalWallCtrl = self._mobileMedalWallConWidgetPool:SpawnObject("UIWidgetHomelandMedalWallController")

    self._blackMask = self:GetGameObject().transform.parent.parent:Find("BGMaskCanvas/black_mask"):GetComponent(
        typeof(UnityEngine.UI.Image))
    self._blackMask.raycastTarget = false
end

function UIHomelandMedalWall:OnHide()
    ---@type UIHomelandModule
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    local homelandClient = homeLandModule:GetClient()
    if not homelandClient then
        return
    end
    local cameraMgr = homelandClient:CameraManager()
    ---@type HomelandMedalWallCameraController
    local medalWallCameraController = cameraMgr:MedalWallCameraController()
    medalWallCameraController:ResetInitPos(
        function()
            self._blackMask.raycastTarget = true
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandAllUI, true)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshInteractUI)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, true)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ExitFindTreasure)

            homelandClient:InputManager():ChangeMedalWallController(false)
            cameraMgr:SetMedalWallCameraActive(false)

            ---@type HomelandFollowCameraController
            local followCameraController = cameraMgr:FollowCameraController()
            followCameraController:LeaveFocusUseAngles()

            ---@type HomelandMainCharacterController
            local characterController = homelandClient:CharacterManager():MainCharacterController()
            characterController:ShowHideCharacter(true)
            characterController:SetForbiddenMove(false)

            --恢复Pet显示
            ---@type HomelandPetManager
            local petMng = homelandClient:PetManager()
            petMng:SetPetsVisible(true)

            --恢复小地图显示
            local homelandMainController = GameGlobal.UIStateManager():GetController("UIHomelandMain")
            if homelandMainController then
                homelandMainController:SetMinimapStatus(true)
            end
        end
    )
end

function UIHomelandMedalWall:BtnCloseOnClick(go)
    self:CloseDialog()
end

function UIHomelandMedalWall:BtnEditOnClick(go)
    self:ShowDialog("UIN22MedalEdit", true)
end
