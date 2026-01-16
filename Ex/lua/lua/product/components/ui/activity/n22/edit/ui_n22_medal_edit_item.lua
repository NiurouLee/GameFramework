---@class UIN22MedalEditItem:UICustomWidget
---@field yDragging number 开始拖拽的y值
---@field curDragMedalId number 当前拖拽的勋章id
_class("UIN22MedalEditItem", UICustomWidget)
UIN22MedalEditItem = UIN22MedalEditItem

function UIN22MedalEditItem:Constructor()
    self.mMedal = GameGlobal.GetModule(MedalModule)
    self.data = self.mMedal:GetN22MedalEditData()

    self.curDragMedalId = 0
    self.yDragging = 300
end

function UIN22MedalEditItem:OnShow()
    ---@type UnityEngine.Animation
    self.anim = self:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
    self.bg = self:GetGameObject("bg")
    ---@type UnityEngine.UI.Image
    self.imgIcon = self:GetUIComponent("Image", "imgIcon")
    ---@type UnityEngine.RectTransform
    self.rtIcon = self:GetUIComponent("RectTransform", "imgIcon")
    self.new = self:GetGameObject("new")

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)
    self.camera = GameGlobal.UIStateManager():GetControllerCamera("UIN22MedalEdit")

    local etl = UICustomUIEventListener.Get(self.bg)
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.BeginDrag,
        function(eventData)
            self.ui:SetIsDraggingMedal(false)
            self:ClearNew()
        end
    )
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.Drag,
        function(eventData)
            if self.ui:GetIsDraggingMedal() then
                self.ui:SetCurDragScreenPosition(eventData.position)
            else
                if eventData.position.y >= self.yDragging then
                    self.ui:SetIsDraggingMedal(true)
                    self.anim:Play("uieff_UIN22MedalEditItem_in")
                    self.curDragMedalId = self.item:GetID()
                    self.ui:InsertMedal(self.curDragMedalId)
                    self.ui:SetCurDragScreenPosition(eventData.position)
                    self.ui:FlushSelectBoarMedalWithoutAnim(0) --MSG49218	4	【必现】（测试_李钰琦）勋章移动与效果基准图不一致 （附截图）
                end
            end
        end
    )
    ---@param eventData UnityEngine.EventSystems.PointerEventData
    self:AddUICustomEventListener(
        etl,
        UIEvent.EndDrag,
        function(eventData)
            self.ui:SetIsDraggingMedal(false)
            if self.curDragMedalId and self.curDragMedalId > 0 then
                self.ui:ClampBoardMedalUI(self.curDragMedalId)
                self.ui:FlushSelectBoarMedal(self.curDragMedalId) --MSG49218	4	【必现】（测试_李钰琦）勋章移动与效果基准图不一致 （附截图）
                self.curDragMedalId = 0
                self.ui:FlushList()
            end
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Click,
        function(go)
            self:ClearNew(
                function()
                    self.ui:InsertMedal(self.item:GetID())
                    self.ui:FlushList()
                end
            )
        end
    )
end
function UIN22MedalEditItem:OnHide()
    self.new = nil
end

---@param ui UIN22MedalEdit
function UIN22MedalEditItem:Init(rtBoard, ui)
    self.rtBoard = rtBoard
    self.ui = ui
end
---@param item UIMedalItemData 勋章
function UIN22MedalEditItem:Flush(item)
    self.item = item
    local iconMedal = BoardMedal.IconMedalById(item:GetID())
    local sprite = UIN22MedalEditItem.GetSprite(self.atlas, iconMedal)
    self.imgIcon.sprite = sprite
    self.rtIcon.sizeDelta = Vector2(sprite.rect.width, sprite.rect.height) * 0.3
    self:FlushNew()
end

function UIN22MedalEditItem:FlushNew()
    if self.new then
        self.new:SetActive(self.item:IsNew())
    end
end

function UIN22MedalEditItem:ClearNew(callback)
    if not self.item:IsNew() then
        if callback then
            callback()
        end
        return
    end
    local pstId = self.item:GetPstId()
    if not pstId then
        if callback then
            callback()
        end
        return
    end
    self:StartTask(
        function(TT)
            local key = "UIN22MedalEditItemClearNew"
            self:Lock(key)
            self:GetModule(ItemModule):SetItemUnnew(TT, pstId)
            self:FlushNew()
            if callback then
                callback()
            end
            self:UnLock(key)
        end,
        self
    )
end

---@param spriteAtlas UnityEngine.U2D.SpriteAtlas
---@param spriteName string
---@return UnityEngine.Sprite
function UIN22MedalEditItem.GetSprite(spriteAtlas, spriteName)
    local sprite = spriteAtlas:GetSprite(spriteName)
    if not sprite then
        sprite = spriteAtlas:GetSprite("item_modle_icon_6000001") --保证有资源
    end
    return sprite
end
