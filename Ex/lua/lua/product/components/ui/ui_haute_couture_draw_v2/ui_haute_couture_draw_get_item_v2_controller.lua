---@class UIHauteCoutureDrawGetItemV2Controller:UIController
_class("UIHauteCoutureDrawGetItemV2Controller", UIController)
UIHauteCoutureDrawGetItemV2Controller = UIHauteCoutureDrawGetItemV2Controller

function UIHauteCoutureDrawGetItemV2Controller:Constructor()
    ---@type UIHauteCoutureDrawGetItemBase
    self.main = nil
    self.bg = nil

    self.items = {}
    self.titleTex = nil
    self.noSort = nil
    self.callback = nil
end

function UIHauteCoutureDrawGetItemV2Controller:OnShow(uiParams)
    self.items = uiParams[1]
    self.titleTex = uiParams[2]
    self.noSort = uiParams[3]
    self.callback = uiParams[4]
    ---@type UIHauteCoutureDataBase
    self._ctx = uiParams[5] --从伯利恒高级时装开始，需要传此参数

    -- local bg = self:GetUIComponent("UISelectObjectPath", "bgRoot")
    local main = self:GetUIComponent("UISelectObjectPath", "uiRoot")
    self.hcType = HauteCouture:GetInstance().HcType
    if self.hcType == HauteCoutureType.HC_GL then
        --bg.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawGetItemBgGL.prefab") --没有背景可以不用加载
        main.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawGetItemMainGL.prefab")
        --self.bg = bg:SpawnObject("UIHauteCoutureDrawGetItemBgGL")
        self.main = main:SpawnObject("UIHauteCoutureDrawGetItemMainGL")
    elseif self.hcType == HauteCoutureType.HC_KR then
        --bg.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawGetItemBgKR.prefab") --没有背景可以不用加载
        main.dynamicInfoOfEngine:SetObjectName("UIHauteCoutureDrawGetItemMainKR.prefab")
        --self.bg = bg:SpawnObject("UIHauteCoutureDrawGetItemBgKR")
        self.main = main:SpawnObject("UIHauteCoutureDrawGetItemMainKR")
    else
        local prefab, class = self._ctx:GetGetItemUIInfo()
        main.dynamicInfoOfEngine:SetObjectName(prefab)
        self.main = main:SpawnObject(class._className)
    end
end
