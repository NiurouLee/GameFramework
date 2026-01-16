---@class UIActivityN33DateManualItem:UICustomWidget
_class("UIActivityN33DateManualItem", UICustomWidget)
UIActivityN33DateManualItem = UIActivityN33DateManualItem

function UIActivityN33DateManualItem:Constructor()
    self._isSelect = false
    self._isInMap = false
end

function UIActivityN33DateManualItem:OnShow()
    self._atlas = self:GetAsset("UIN33Date.spriteatlas", LoadType.SpriteAtlas)
    self:_GetComponent()
end

function UIActivityN33DateManualItem:_GetComponent()
    self._petImg = self:GetUIComponent("RawImageLoader","petImg")
    self._processNum = self:GetUIComponent("UILocalizationText","processNum")
    self._processNum2 = self:GetUIComponent("UILocalizationText","processNum2")
    self._needBuilding = self:GetUIComponent("Image","needBuilding")

    self._selectObj = self:GetGameObject("select")
    self._signObj = self:GetGameObject("sign")
    self._doneObj = self:GetGameObject("done")
    self._processObj = self:GetGameObject("process")
    self._lockObj = self:GetGameObject("lock")
end

function UIActivityN33DateManualItem:SetData(cfgs,data,callback)
    self._cfgs = cfgs
    ---@type UIActivityN33DateData
    self._activityConst = data
    self._callback = callback
    self:_Init()
end

function UIActivityN33DateManualItem:_Init()
    local cfg = self._cfgs[1]
    self._petImg:LoadImage(cfg.ManualIcon)

    --初始化角标
    local hasRed = false
    local allOver = true
    local readNum = 0
    local isOneOver = false
    for i, v in pairs(self._cfgs) do
        if i > 2 then
            break
        end
        local isOver = self._activityConst:CheckStoryConditionIsOver(v.ID)
        local isRead = self._activityConst:CheckStoryIsRead(v.ID)
        isOneOver = isOneOver or isOver

        if isOver then
            if not isRead then
                hasRed = true
                allOver = false
            else
                readNum = readNum + 1
            end
        else
            allOver = false
        end
    end
    self._isInMap = isOneOver

    --全部完成 左上角勾上 右下角隐藏
    if allOver then
        self._doneObj:SetActive(true)
        self._processObj:SetActive(true)
        self._lockObj:SetActive(false)
        self._processNum:SetText("2/2")
        self._processNum2:SetText("2/2")
    else
        self._doneObj:SetActive(false)
        if not isOneOver then
            --一个都未完成 置灰 右下角显示建筑图标
            self._processObj:SetActive(false)
            self._lockObj:SetActive(true)
            --显示需要的建筑和星级
            -- local buildCondition = cfg.PreCondition[1]
            -- local needBuildCfg = Cfg.cfg_component_simulation_operation{ArchitectureId = buildCondition[1],Level = buildCondition[2]}[1]
            self._needBuilding.sprite = self._atlas:GetSprite(cfg.ConditionImg)
        else
            --完成一个以上 显示进度
            self._processObj:SetActive(true)
            self._lockObj:SetActive(false)
            self._processNum:SetText(readNum.."/"..(readNum + 1))
            self._processNum2:SetText(readNum.."/"..(readNum + 1))
        end
    end

    self._signObj:SetActive(hasRed)
end

function UIActivityN33DateManualItem:GetCfgs()
    return self._cfgs
end

function UIActivityN33DateManualItem:SetSelect(isSelect)
    self._selectObj:SetActive(isSelect)
    self._isSelect = isSelect
end

--是否在地图上
function UIActivityN33DateManualItem:IsInMap()
    return self._isInMap
end

function UIActivityN33DateManualItem:ItemBtnOnClick()
    if self._activityConst:CheckSimulationOperationIsOver() then
        ToastManager.ShowToast(StringTable.Get("str_activity_finished"))
        self:SwitchState(UIStateType.UIActivityN33MainController)
        return
    end

    if self._isSelect then
        return
    end

    self:SetSelect(true)
    if self._callback then
        self._callback(self)
    end
end