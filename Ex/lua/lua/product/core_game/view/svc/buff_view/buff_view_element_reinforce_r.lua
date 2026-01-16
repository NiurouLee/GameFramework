--[[
     属性强化buff表现
]]
---@class BuffViewElementReinforce:BuffViewBase
_class("BuffViewElementReinforce", BuffViewBase)
BuffViewElementReinforce = BuffViewElementReinforce

function BuffViewElementReinforce:PlayView(TT)
    local e = self:Entity()
    local world = self:World()
    local hpSliderEntityId = e:HP():GetHPSliderEntityID()
    local eHPSlider = world:GetEntityByID(hpSliderEntityId)
    if not eHPSlider then
        Log.fatal("### no HPSlider.", e:Asset():GetResPath())
        return
    end
    local go = InnerGameHelperRender:GetInstance():GetGameObject(eHPSlider)
    if not go then
        return
    end
    ---@type UIView
    local uiView = go:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local imgBG = uiView:GetUIComponent("Image", "imgBG")
    ---@type UnityEngine.GameObject
    local eff_glow = uiView:GetGameObject("eff_glow")
    imgBG.gameObject:SetActive(true)
    eff_glow:SetActive(true)
    --动画
    ---@type UnityEngine.Animation
    local anim = eff_glow.transform.parent:GetComponent(typeof(UnityEngine.Animation))
    local cfg_pet_element = Cfg.cfg_pet_element {}
    
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local elementType = utilDataSvc:GetEntityElementPrimaryType(e)

    local name = "uieff_hpslider_" .. cfg_pet_element[elementType].IconWhite
    YIELD(TT) --TODO等一帧才能播
    anim:Play(name)
end

---------------------------------------------------------------------

---@class BuffViewRemoveElementReinforce:BuffViewBase
_class("BuffViewRemoveElementReinforce", BuffViewBase)
BuffViewRemoveElementReinforce = BuffViewRemoveElementReinforce

function BuffViewRemoveElementReinforce:PlayView(TT)
    local e = self:Entity()
    local world = self:World()
    local hpSliderEntityId = e:HP():GetHPSliderEntityID()
    local eHPSlider = world:GetEntityByID(hpSliderEntityId)
    if not eHPSlider then
        Log.fatal("### no HPSlider.", e:Asset():GetResPath())
        return
    end
    local go = InnerGameHelperRender:GetInstance():GetGameObject(eHPSlider)
    if not go then
        return
    end
    ---@type UIView
    local uiView = go:GetComponent("UIView")
    ---@type UnityEngine.UI.Image
    local imgBG = uiView:GetUIComponent("Image", "imgBG")
    ---@type UnityEngine.GameObject
    local eff_glow = uiView:GetGameObject("eff_glow")
    imgBG.gameObject:SetActive(false)
    eff_glow:SetActive(false)
end
