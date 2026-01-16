--[[---------------------
    飘字管理器
--]] ---------------------

_class("ToastManager", Singleton)
---@class ToastManager:Singleton
ToastManager = ToastManager

---显示一条飘字
---@param textContent string 要显示的飘字内容
function ToastManager.ShowToast(textContent)
    ToastManager:GetInstance():_ShowToastText(textContent)
end
---家园显示一条飘字
---@param textContent string 要显示的飘字内容
function ToastManager.ShowHomeToast(textContent)
    ToastManager:GetInstance():_ShowToastTextHome(textContent)
end

--显示功能暂未开启
function ToastManager.ShowLockTip()
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUnlockModule)
    ToastManager:GetInstance():_showLockTips()
end

---@param uiRootGameObject UnityEngine.GameObject
function ToastManager:Init(uiRootGameObject)
    ---@type UnityEngine.GameObject
    self._toastRoot = uiRootGameObject.transform:Find("UICameras/depth_high/UI/ToastCanvas/ToastRoot").gameObject
    ---@type UnityEngine.UI.Text
    self._toastText =
        uiRootGameObject.transform:Find("UICameras/depth_high/UI/ToastCanvas/ToastRoot/Info/ToastText").gameObject:GetComponent(
        "UILocalizationText"
    )

    --home
    ---@type UnityEngine.GameObject
    self._toastRootHome = uiRootGameObject.transform:Find("UICameras/depth_high/UI/ToastCanvas/ToastRoot_home").gameObject
    ---@type UnityEngine.UI.Text
    self._toastTextHome =
        uiRootGameObject.transform:Find("UICameras/depth_high/UI/ToastCanvas/ToastRoot_home/Info/ToastText").gameObject:GetComponent(
        "UILocalizationText"
    )

    ---spine节点
    ---@type UnityEngine.GameObject
    self._lockTips = uiRootGameObject.transform:Find("UICameras/depth_high/UI/UILockTips").gameObject
    ---@type Vector3
    self._original = Vector3(0, 100, 0)
    ---@type number 总动画时长(ms)
    self._animInteval = 1500

    self._toastEvent = nil
    self._lockEvent = nil
end

function ToastManager:Dispose()
    self._toastRoot = nil
    self._toastText = nil
    self._lockTips = nil

    ToastManager.super.Dispose(self)
end

---@private
function ToastManager:_ShowToastText(textContent)
    if self._toastRoot and self._toastText then
        self:_UpdateToast(textContent)
    end
end
--家园
function ToastManager:_ShowToastTextHome(textContent)
    if self._toastRootHome and self._toastTextHome then
        self:_UpdateToastHome(textContent)
    end
end

---@private
function ToastManager:_UpdateToast(textContent)
    if self._toastEvent then
        GameGlobal.Timer():CancelEvent(self._toastEvent)
        self._toastEvent = nil
        self._toastRoot:SetActive(false)
    end

    self._toastRoot:SetActive(true)
    self._toastText:SetText(textContent)

    self._toastEvent = GameGlobal.Timer():AddEvent(
        self._animInteval,
        function ()
            self._toastText:SetText("")
            self._toastRoot:SetActive(false)
            self._toastEvent = nil
        end
    )
end
---@private
-----
function ToastManager:_UpdateToastHome(textContent)
    if self._toastEventHome then
        GameGlobal.Timer():CancelEvent(self._toastEventHome)
        self._toastEventHome = nil
        self._toastRootHome:SetActive(false)
    end

    self._toastRootHome:SetActive(true)
    self._toastTextHome:SetText(textContent)

    self._toastEventHome = GameGlobal.Timer():AddEvent(
        self._animInteval,
        function ()
            self._toastTextHome:SetText("")
            self._toastRootHome:SetActive(false)
            self._toastEventHome = nil
        end
    )
end

function ToastManager:_showLockTips()
    if self._lockEvent ~= nil then
        return
    end
    self._lockTips:SetActive(true)
    self._lockEvent =
        GameGlobal.Timer():AddEvent(
        2000,
        function()
            self._lockTips:SetActive(false)
            self._lockEvent = nil
        end
    )
end
