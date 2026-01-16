--
---@class UIN31HardLevelBtn : UICustomWidget
_class("UIN31HardLevelBtn", UICustomWidget)
UIN31HardLevelBtn = UIN31HardLevelBtn

--初始化
function UIN31HardLevelBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UIN31HardLevelBtn:InitWidget()
    self._bg = self:GetUIComponent("Image", "bg")
    self.select = self:GetUIComponent("Image", "select")
    self.unSelect = self:GetUIComponent("Image", "unSelect")
    self._HideGroup = self:GetUIComponent("CanvasGroup", "unSelect")
    self.locker = self:GetUIComponent("Image", "locker")
    --self.logName = self:GetUIComponent("UILocalizationText", "logName")
    self.logName = self:GetUIComponent("RawImageLoader", "logName")
    ---@type UnityEngine.RectTransform
    self.rootRt = self:GetUIComponent("RectTransform","rootRt")

    ---@type UnityEngine.UI.Button
    self.levelBtn = self:GetUIComponent("Button", "rootRt")
    self._rootAni = self:GetUIComponent("Animation", "rootRt")
    local roleModule = GameGlobal.GetModule(RoleModule)
    local playerId = roleModule:GetPstId()
    self.key = playerId.."UIN31HardLevelBtnTips"
    
end

--设置数据
function UIN31HardLevelBtn:SetData(atlas, logName, clickCallback)
    self.atlas = atlas
    self.clickCallback = clickCallback

    local bgSpriteName = nil
    local btnSpriteName = nil
    local maskSpriteName = nil
    local lockSpriteName = nil
    local multiLangaugeName = nil
    if logName == 1 then
        bgSpriteName = "n31_kng_btn01"
        maskSpriteName = "n31_kng_mask01"
        lockSpriteName = "n31_kng_lock01"
        multiLangaugeName = "n31_kng_zi01"
    else
        bgSpriteName = "n31_kng_btn02"
        maskSpriteName = "n31_kng_mask02"
        lockSpriteName = "n31_kng_lock01"
        multiLangaugeName = "n31_kng_zi02"
    end

    self._bg.sprite = atlas:GetSprite(bgSpriteName)
    self.unSelect.sprite = atlas:GetSprite(maskSpriteName)
    self.locker.sprite = atlas:GetSprite(lockSpriteName)
    self.logName:LoadImage(multiLangaugeName)

    self:SetLockVisible(false)
end

function UIN31HardLevelBtn:SetLockVisible(bVisible,first)
    local value = LocalDB.GetInt(self.key,2)
    if self.locker then
        if not bVisible and first and value == 2 then
            self.locker.gameObject:SetActive(true)
            LocalDB.SetInt(self.key,1)
            self._rootAni:Play("uieff_UIN31HardLevelBtn_lock")
        else
            self.locker.gameObject:SetActive(bVisible)
        end
    end

    self.isLock = bVisible
end

function UIN31HardLevelBtn:SetSelect(bSelect, le2,isLevel2Lock)
    --self.unSelect.gameObject:SetActive(not bSelect)
    if le2 and isLevel2Lock then
        return
    end

    if bSelect then
        self._HideGroup.alpha = 1
        self._HideGroup:DOFade(0,0.3)
        -- local lockName = "UIN31HardLevelBtnShow"
        -- self:StartTask(function(TT)
        --     self:Lock(lockName)
        --     self._rootAni:Play("uieff_UIN31HardLevelBtn_show")
        --     YIELD(TT, 600)
        --     self:UnLock(lockName)
        -- end)
        
    else
        self._HideGroup.alpha = 0
        self._HideGroup:DOFade(1,0.3)
        -- local lockName = "UIN31HardLevelBtnHide"
        -- self:StartTask(function(TT)
        --     self:Lock(lockName)
        --     self._rootAni:Play("uieff_UIN31HardLevelBtn_hide")
        --     YIELD(TT, 600)
        --     self:UnLock(lockName)
        -- end)

    end


    --self.levelBtn.interactable = not bSelect
end


function UIN31HardLevelBtn:LevelBtnOnClick(go)
    if self.clickCallback then
        self.clickCallback()
    end
end