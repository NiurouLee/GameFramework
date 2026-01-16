--
---@class UIMedalMainController : UIController
_class("UIMedalMainController", UIController)
UIMedalMainController = UIMedalMainController

function UIMedalMainController:Constructor()
    self.medalModule = GameGlobal.GetModule(MedalModule)
    ---@type UIMedalModule
    self.uiMedalModuel = self.medalModule:GetUIModule()
    self._canShare = self:GetModule(ShareModule):CanShare()
end

--初始化
function UIMedalMainController:OnShow(uiParams)
    self:InitWidget()
    self:Refresh()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self.AfterUILayerChanged)
end

function UIMedalMainController:OnHide()
    self:DetachEvent(GameEventType.AfterUILayerChanged,self.AfterUILayerChanged)
end

--获取ui组件
function UIMedalMainController:InitWidget()
    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            self:StartTask(
                function(TT)
                    local lockName = "UIMedalMainController_PlayAnimOut()"
                    self:Lock(lockName)
                    self._ani:Play("uieff_UIMedalMainController_out")
                    YIELD(TT, 450)
                    self:UnLock(lockName)
                    self:CloseDialog()
                 end,
                self
                )
            end,
            nil,
            nil,
            nil,
            nil)

    ---@type UnityEngine.GameObject
    self.medalBtn = self:GetGameObject("medalBtn")
    ---@type UnityEngine.GameObject
    self.medalRed = self:GetGameObject("medalRed")
    ---@type UnityEngine.GameObject
    self.medalBgBtn = self:GetGameObject("medalBgBtn")
    ---@type UnityEngine.GameObject
    self.medalBgRed = self:GetGameObject("medalBgRed")
     ---@type UnityEngine.Animation
     self._ani = self:GetUIComponent("Animation", "_ani")


    ---@type UICustomWidgetPool
    local boardMedalPool = self:GetUIComponent("UISelectObjectPath", "boardMedal")
    ---@type UIMedalCardSimple
    self.boardMedal = boardMedalPool:SpawnObject("UIMedalCardSimple")

    self._backgroundGo = self:GetGameObject("Background")
    self._editBtnGo = self:GetGameObject("EditButton")
    self._bottomGo = self:GetGameObject("Bottom")
    ---@type UnityEngine.RectTransform
    self._boardMedalRect = self:GetUIComponent("RectTransform", "boardMedal")

    self._shareBtnGO = self:GetGameObject("ShareBtn")
    self._shareBtnGO:SetActive(self._canShare)
end

function UIMedalMainController:Refresh()
    --boardMedal
    local placeData = self.medalModule:GetPlacementInfo()
    self.boardMedal:SetData(1820, placeData)
end

function UIMedalMainController:AfterUILayerChanged()
    self:_CheckRed()
end

function UIMedalMainController:_CheckRed()
    self.medalRed:SetActive(self.uiMedalModuel:IsMedalNew())
    self.medalBgRed:SetActive(self.uiMedalModuel:IsMedalBoardNew())
end
--按钮点击
function UIMedalMainController:MedalBtnOnClick(go)
    GameGlobal.UIStateManager():ShowDialog("UIMedalListController")
end

--按钮点击
function UIMedalMainController:MedalBgBtnOnClick(go)
    self:ShowDialog("UIMedalBgListController")
end

--套组按钮
function UIMedalMainController:MedalGroupBtnOnClick(go)
    self:ShowDialog("UIMedalGroupListController")
end

--按钮点击
function UIMedalMainController:EditButtonOnClick(go)
    self:ShowDialog("UIN22MedalEdit")
end

function UIMedalMainController:ShareBtnOnClick(go)
    self:Lock("UIMedalMainControllerShare")
    self:StartTask(
        function(TT)
            self:_SetShareUI(false)
            YIELD(TT)
            self:ShowDialog("UIShare", 
            self:GetName(),
            nil,
            function ()
                self:_SetShareUI(true)
            end,
        nil,
        nil,
        nil,
        ShareSceneType.Medal)
            self:UnLock("UIMedalMainControllerShare")
        end,
        self
    )
end

function UIMedalMainController:_SetShareUI(show)
    self.topButtonWidget.view.gameObject:SetActive(show)
    self._backgroundGo:SetActive(show)
    self._editBtnGo:SetActive(show)
    self._bottomGo:SetActive(show)
    self._shareBtnGO:SetActive(show)
    if show then
        self._boardMedalRect.anchoredPosition = Vector2(self._boardMedalRect.anchoredPosition.x , 72)
    else
        self._boardMedalRect.anchoredPosition = Vector2(self._boardMedalRect.anchoredPosition.x , 0)
    end
end