---@class UICreditsEffItem:UICustomWidget
_class("UICreditsEffItem", UICustomWidget)
UICreditsEffItem = UICreditsEffItem

function UICreditsEffItem:OnShow()
    ---@type UnityEngine.Transform
    self.tran = self:GetGameObject():GetComponent(typeof(UnityEngine.Transform))
    ---@type EffectLoader
    self._effectLoader = self:GetUIComponent("EffectLoader", "eff")
    ---@type UnityEngine.Transform
    self.tranEff = self._effectLoader.transform
end

function UICreditsEffItem:OnHide()
    if self._effectLoader then
        self._effectLoader:DestroyCurrentEffect()
    end
end

---@param txt UILocalizationText
function UICreditsEffItem:Flush(txt)
    if string.isnullorempty(txt.text) then
    else
        if self._effectLoader then
            ---@type UnityEngine.Transform
            self.txtTran = txt.transform
            self._effectLoader:LoadEffect("uieff_UICredits_RTMask")
            if self.tranEff.childCount > 0 then
                ---@type UnityEngine.RectTransform
                local rect = self.tranEff:GetChild(0):GetComponent(typeof(UnityEngine.RectTransform))
                if rect then
                    rect.sizeDelta = Vector2(txt.preferredWidth * 2 + 250, rect.sizeDelta.y)
                end
            end
        end
    end
end

function UICreditsEffItem:OnUpdate()
    if self.txtTran then
        self.tran.position = self.txtTran.position
    end
end
