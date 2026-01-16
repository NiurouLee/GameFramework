--[[---------------------
    UI状态切换时屏幕快照
--]] ---------------------

_class("UISwitchImgManager", Singleton)
---@class UISwitchImgManager:Singleton
UISwitchImgManager = UISwitchImgManager

function UISwitchImgManager.Show()
    Log.debug("[ui] UISwitchImgManager.Show")
    UISwitchImgManager:GetInstance():_Show(true)
end
function UISwitchImgManager.Hide()
    Log.debug("[ui] UISwitchImgManager.Hide")
    UISwitchImgManager:GetInstance():_Show(false)
end

---@param uiRootGameObject UnityEngine.GameObject
function UISwitchImgManager:Init(uiRootGameObject)
    ---@type UnityEngine.GameObject
    self._imageRoot = uiRootGameObject.transform:Find("UICameras/depth_high/UI/SwitchImgCanvas/RawImage").gameObject

    ---@type UnityEngine.UI.Text
    self._blurhelper = self._imageRoot:GetComponent("H3DUIBlurHelper")
end

---@private
function UISwitchImgManager:_Show(bshow)
    if (bshow) then
        self._imageRoot:SetActive(true)
        self._blurhelper:BlurTexture(UnityEngine.Screen.width, UnityEngine.Screen.height, 0)
    else
        if (self._imageRoot.activeSelf) then
            self._imageRoot:SetActive(false)
        end
    end
end
