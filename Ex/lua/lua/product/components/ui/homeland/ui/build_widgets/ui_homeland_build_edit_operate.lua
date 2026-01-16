--家具摆放操作
---@class UIHomelandBuildEditOperate : UICustomWidget
_class("UIHomelandBuildEditOperate", UICustomWidget)
UIHomelandBuildEditOperate = UIHomelandBuildEditOperate

function UIHomelandBuildEditOperate:Constructor()
    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
    ---@type HomelandClient
    self.homelandClient = self.mUIHomeland:GetClient()
    ---@type HomeBuildManager
    self.homeBuildManager = self.homelandClient:BuildManager()
    self.mItem = GameGlobal.GetModule(ItemModule)
end

--初始化
function UIHomelandBuildEditOperate:OnShow(uiParams)
    self:InitWidget()
    self:AttachEvent(GameEventType.HomeBuildOnAmbientChanged, self.HomeBuildOnAmbientChanged)
    self:AttachEvent(GameEventType.OnHomeBuildRotateOpen, self.OnOpenRotate)
end

function UIHomelandBuildEditOperate:OnHide()
    self:DetachEvent(GameEventType.HomeBuildOnAmbientChanged, self.HomeBuildOnAmbientChanged)
    self:DetachEvent(GameEventType.OnHomeBuildRotateOpen, self.OnOpenRotate)
end


--获取ui组件
function UIHomelandBuildEditOperate:InitWidget()
    ---@type UnityEngine.GameObject
    self.operate = self:GetGameObject("operate")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self.goTakeIn = self:GetGameObject("imgTakeIn")
    self.goRotate = self:GetGameObject("imgRotate")
    self.goConfirm = self:GetGameObject("imgConfirm")
    self._rotateImg = self:GetUIComponent("Image", "rotateimg")
end

function UIHomelandBuildEditOperate:FlushOperate()
    local homeBuilding = self.homeBuildManager:GetCurrentBuilding()
    self.txtName:SetText(UIHomelandBuildEdit.GetBuildingName(homeBuilding:GetBuildId()))
    if not homeBuilding:ShowDeleteBtn() then
        self.goTakeIn:SetActive(false)
    else
        local canDelete, reason, showBtn = UIHomelandBuildEdit.CanBuildingDelete(homeBuilding)
        self.goTakeIn:SetActive(showBtn)

        if UIHomelandBuildEdit.CanBuildingMove(homeBuilding:GetBuildId()) then
            self.goRotate:SetActive(true)
            self.goConfirm:SetActive(true)
        else
            self.goRotate:SetActive(false)
            self.goConfirm:SetActive(false)
        end
    end
end

function UIHomelandBuildEditOperate:_Exit(TT)
    self:Lock("HomeExitBuildMode")
    self:SwitchState(UIStateType.UIHomeland)
    while GameGlobal.UIStateManager():CurUIStateType() ~= UIStateType.UIHomeland do
        YIELD(TT)
    end
    self.homelandClient:FinishBuild(TT)
    self:UnLock("HomeExitBuildMode")
end

--取消按钮点击
function UIHomelandBuildEditOperate:ImgCancelOnClick(go)
    self.homeBuildManager:RevertCurrent()
end

--收纳按钮点击
function UIHomelandBuildEditOperate:ImgTakeInOnClick(go)
    local homeBuilding = self.homeBuildManager:GetCurrentBuilding()
    local canDelete, reason = UIHomelandBuildEdit.CanBuildingDelete(homeBuilding)
    if canDelete then
        self.homeBuildManager:Delete()
        --todo:liws
        --self:HomeBuildOnSelectBuilding() --TODO 收纳后应该返回到放置模式
    else
        if not string.isnullorempty(reason) then
            ToastManager.ShowHomeToast(reason)
        else
            ToastManager.ShowHomeToast(StringTable.Get("str_homeland_build_cant_delete"))
        end
    end
end

--旋转按钮点击
function UIHomelandBuildEditOperate:ImgRotateOnClick(go)
    local homeBuilding = self.homeBuildManager:GetCurrentBuilding()
    if not homeBuilding:CanRotate() then
        ToastManager.ShowToast(StringTable.Get("str_homeland_build_fixed_rotation"))
        return
    end

    self:ShowDialog("UIHomelandBuildEditRotate")
end

--确认按钮点击
function UIHomelandBuildEditOperate:ImgConfirmOnClick(go)
    self.homeBuildManager:DropDown()
end


function UIHomelandBuildEditOperate:GetSpecialTag()
    return self._specialTag:GetGameObject("imgTab")
end

function UIHomelandBuildEditOperate:GetSpecialLand()
    return self._specialLand:GetGameObject("imgTab")
end

function UIHomelandBuildEditOperate:OnOpenRotate(isOpen)
    if isOpen then
        self._rotateImg.color = Color(247 / 255, 174 / 255, 44 / 255)
    else
        self._rotateImg.color = Color.white
    end
end