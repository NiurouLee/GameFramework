---@class UIItemTips:UIController
_class("UIItemTips", UIController)
UIItemTips = UIItemTips

function UIItemTips:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)
end

function UIItemTips:OnShow(uiParams)
    self.ra = uiParams[1]
    ---@type UnityEngine.GameObject
    self.go = uiParams[2]
    self.uiName = uiParams[3]
    self.offset = uiParams[4] --偏移
    self.uiCamera = GameGlobal.UIStateManager():GetControllerCamera(self.uiName) --弹该界面的界面的相机

    self.bg = self:GetGameObject("bg")
    ---@type PassEventComponent
    local passEvent = self.bg:GetComponent("PassEventComponent")
    passEvent:SetClickCallback(
        function()
            self:closeOnClick()
        end
    )
    self._black_mask =
        self:GetGameObject().transform.parent.parent:Find("BGMaskCanvas/black_mask"):GetComponent(
        typeof(UnityEngine.UI.Image)
    )
    self._black_mask.raycastTarget = false
    ---@type UnityEngine.RectTransform
    self.rect = self:GetUIComponent("RectTransform", "rect")
    ---@type UICustomWidgetPool
    self.itemPool = self:GetUIComponent("UISelectObjectPath", "itemPool")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")

    self:Flush()
    self:FlushPos()
end
function UIItemTips:OnHide()
    self._black_mask.raycastTarget = true
end

function UIItemTips:Flush()
    local tpl = Cfg.cfg_item[self.ra.assetid]
    ---@type UIItem
    local ui = self.itemPool:SpawnObject("UIItem")
    ui:SetForm(UIItemForm.Base)
    ui:SetData(
        {
            text1 = self.ra.count,
            icon = tpl.Icon,
            itemId = tpl.ID,
            quality = tpl.Color
        }
    )
    self.txtName:SetText(StringTable.Get(tpl.Name))
    self.txtDesc:SetText(StringTable.Get(tpl.Intro))
end
function UIItemTips:FlushPos()
    if self.go then
        local posScreen = self.uiCamera:WorldToScreenPoint(self.go.transform.position)
        local camera = GameGlobal.UIStateManager():GetControllerCamera(self:GetName())
        local res, pos =
            UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            self.rect.parent,
            posScreen,
            camera,
            nil
        )
        if self.offset then
            self.rect.anchoredPosition = pos + self.offset
        else
            self.rect.anchoredPosition = pos
        end
    end
end

function UIItemTips:closeOnClick()
    self:CloseDialog()
end
