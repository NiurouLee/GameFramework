---@class UIN22MedalEditBoardItem:UICustomWidget
---@field vecBeginDrag Vector2 开始拖拽时拖动点和勋章坐标的偏移向量
_class("UIN22MedalEditBoardItem", UICustomWidget)
UIN22MedalEditBoardItem = UIN22MedalEditBoardItem

function UIN22MedalEditBoardItem:Constructor()
    self.mMedal = GameGlobal.GetModule(MedalModule)
    self.data = self.mMedal:GetN22MedalEditData()

    self.vecBeginDrag = Vector2.zero
end

function UIN22MedalEditBoardItem:OnShow()
    local go = self:GetGameObject()
    ---@type UnityEngine.RectTransform
    self.rt = go:GetComponent(typeof(UnityEngine.RectTransform))
    UICommonHelper:GetInstance():RectTransformAnchor2Center(self.rt)
    ---@type UnityEngine.Animation
    self.anim = go:GetComponent(typeof(UnityEngine.Animation))
    self.select = self:GetGameObject("select")
    self.select:SetActive(false)
    self.bg = self:GetGameObject("bg")
    ---@type UnityEngine.UI.Image
    self.imgMedal = self:GetUIComponent("Image", "imgMedal")
    self.goImgMedal = self:GetGameObject("imgMedal")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)

    --region UICustomUIEventListener
    local etl = UICustomUIEventListener.Get(self.bg)
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.BeginDrag,
        function(eventData)
            local camera = GameGlobal.UIStateManager():GetControllerCamera("UIN22MedalEdit")
            local posScreen = camera:WorldToScreenPoint(self.rt.position)
            self.vecBeginDrag = Vector2(posScreen.x, posScreen.y) - eventData.position
            self.ui:SetIsDraggingMedal(true)
            self.ui:SetCurBoardMedalId(self.id, self)
            self:SetIndexAsLast()
        end
    )
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.Drag,
        function(eventData)
            self.ui:SetCurDragScreenPosition(eventData.position + self.vecBeginDrag)
        end
    )
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.EndDrag,
        function(eventData)
            self.vecBeginDrag = Vector2.zero
            self.ui:SetIsDraggingMedal(false)
            self.ui:ClampBoardMedalUI(self.id)
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Click,
        function(go)
            self.ui:SetCurBoardMedalId(self.id, self)
            self:SetIndexAsLast()
        end
    )
    --endregion
end
function UIN22MedalEditBoardItem:OnHide()
    self.goModel = nil
    if self.taskId and self.taskId > 0 then
        GameGlobal.TaskManager():KillTask(self.taskId)
    end
end

---@param id number BoardMedal的id
---@param ui UIN22MedalEdit
function UIN22MedalEditBoardItem:Flush(id, ui)
    self.id = id
    self.ui = ui
    self.boardMedal = self.data:GetBoardMedalById(self.id)
    local sprite = UIN22MedalEditItem.GetSprite(self.atlas, self.boardMedal:IconMedal())
    self.imgMedal.sprite = sprite
    self:FlushWidthHeight()
    local posView = self:CalcPosViewByPos(self.boardMedal.pos)
    self:FlushPos(posView)
    self:FlushRot(self.boardMedal.quat)
    self.rt:SetSiblingIndex(self.boardMedal.index - 1)

    if IsUnityEditor() then
        self:GetGameObject().name = id .. self.boardMedal:IconMedal()
    end
end
function UIN22MedalEditBoardItem:FlushWidthHeight()
    local rect = self.imgMedal.sprite.rect
    self.boardMedal.wh = Vector2(rect.width, rect.height) * 0.36 --icon的尺寸
    local whBoard = self.ui:GetBoardWidthHeight()
    self.rt.sizeDelta = self.data:GetScaledWidthHeight(whBoard.x, self.boardMedal.wh)
end
---@param pos Vector2 实际坐标，即表现坐标
function UIN22MedalEditBoardItem:FlushPos(posView)
    self.rt.anchoredPosition = posView
    local whBoard = self.ui:GetBoardWidthHeight()
    local pos = self.data:GetScaledPosInverse(whBoard.x, posView)
    self.boardMedal.pos = pos
end
function UIN22MedalEditBoardItem:FlushRot(quat)
    self.boardMedal.quat = quat
    self.rt.localRotation = quat
end
function UIN22MedalEditBoardItem:FlushSelect(id)
    if id == self.id then
        self.select:SetActive(true)
        self.anim:Play("uieff_UIN22MedalEditBoardItem_in")
    else
        if self:IsSelect() then
            self.taskId =
                self:StartTask(
                function(TT)
                    local key = "uieff_UIN22MedalEditBoardItem_out"
                    self:Lock(key)
                    self.anim:Play("uieff_UIN22MedalEditBoardItem_out")
                    YIELD(TT, 500)
                    self.select:SetActive(false)
                    self.taskId = 0
                    self:UnLock(key)
                end,
                self
            )
        end
    end
end
---不带动画的刷新选择
function UIN22MedalEditBoardItem:FlushSelectWithoutAnim(id)
    if id == self.id then
        self.select:SetActive(true)
    else
        if self:IsSelect() then
            self.select:SetActive(false)
        end
    end
end
function UIN22MedalEditBoardItem:IsSelect()
    return self.select.activeInHierarchy
end

function UIN22MedalEditBoardItem:CalcPosViewByPos(pos)
    local whBoard = self.ui:GetBoardWidthHeight()
    local posView = self.data:GetScaledPos(whBoard.x, pos)
    return posView
end

function UIN22MedalEditBoardItem:SetIndexAsLast()
    self.data:SinkMedalById(self.id)
    self.rt:SetAsLastSibling()
end

--region data
---@return number 返回本板上勋章的勋章Id
function UIN22MedalEditBoardItem:Id()
    return self.id
end
---@return Vector2
function UIN22MedalEditBoardItem:Position()
    return self.rt.position
end
---@return Vector2
function UIN22MedalEditBoardItem:AnchoredPosition()
    return self.rt.anchoredPosition
end
---@return Vector3
function UIN22MedalEditBoardItem:LocalPosition()
    return self.rt.localPosition
end
---@return Quaternion
function UIN22MedalEditBoardItem:LocalRotation()
    return self.rt.localRotation
end
--endregion

---@return MedalAABB 返回本勋章最新的的AABB
function UIN22MedalEditBoardItem:AABB()
    local aabb = UIN22MedalEdit.GetAABBOfRectTransform(self.rt)
    return aabb
end
