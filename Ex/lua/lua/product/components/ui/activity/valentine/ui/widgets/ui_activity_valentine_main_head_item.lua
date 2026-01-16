--
---@class UIActivityValentineMainHeadItem : UICustomWidget
_class("UIActivityValentineMainHeadItem", UICustomWidget)
UIActivityValentineMainHeadItem = UIActivityValentineMainHeadItem

function UIActivityValentineMainHeadItem:Constructor()
    self._unSelectSize = Vector2(225,135)
    self._selectSize = Vector2(250,150)
    self._isLock = true
    self._timer = 0.2
end

--初始化
function UIActivityValentineMainHeadItem:OnShow(uiParams)
    self._atlas = self:GetAsset("Valentine.spriteatlas", LoadType.SpriteAtlas)

    self:_GetComponents()
end

--获取ui组件
function UIActivityValentineMainHeadItem:_GetComponents()
    self._headImg = self:GetUIComponent("RawImageLoader","headImg")
    self._selectObj = self:GetGameObject("select")
    self._lockObj = self:GetGameObject("lock")
    self._doneObj = self:GetGameObject("done")
    self._bgImg = self:GetUIComponent("Image","bg")
    self._lockImg = self:GetUIComponent("Image","lock")
    self._layoutElement = self:GetUIComponent("LayoutElement","rect")
    self._redObj = self:GetGameObject("red")
    self._anim = self:GetUIComponent("Animation","anim")
end

--设置数据
function UIActivityValentineMainHeadItem:SetData(cfg, isLock, callback)
    self._cfg = cfg
    self._callback = callback
    self._headImg:LoadImage(self._cfg.HeadImg_b)
    self._isLock = isLock
    self._redObj:SetActive(false)
    self._doneObj:SetActive(false)

    if isLock then
        --锁定
        self._lockObj:SetActive(true)
    else
        --未锁定
        self._lockObj:SetActive(false)
        --检查送巧克力任务是否完成
        local status = self:GetSendTaskStatus()
        if status == QuestStatus.QUEST_Taken then
            self._doneObj:SetActive(true)
        elseif status == QuestStatus.QUEST_Completed then
            self._redObj:SetActive(true)
        end
    end
end

function UIActivityValentineMainHeadItem:GetIsLock()
    return self._isLock
end 

function UIActivityValentineMainHeadItem:SetSelecte(isSelected)
    self._bgImg.sprite = self._atlas:GetSprite("N27_qrj_di08")
    self._lockImg.sprite = self._atlas:GetSprite("N27_qrj_mask04")
    self._headImg:LoadImage(self._cfg.HeadImg_b)
    if isSelected then
        --选中
        self._layoutElement:DOPreferredSize(self._selectSize,self._timer,false)
    else
        --未选中
        self._layoutElement:DOPreferredSize(self._unSelectSize,self._timer,false)
    end
end

function UIActivityValentineMainHeadItem:_SetScaleAnim(TT,isSelected)
    self:Lock("UIActivityValentineMainHeadItem")
    if isSelected then
        self._anim:Play("uieff_UIActivityValentineMainHeadItem_big")
    else
        self._anim:Play("uieff_UIActivityValentineMainHeadItem_small")
    end
    YIELD(TT,50)
    self:UnLock("UIActivityValentineMainHeadItem")
end

function UIActivityValentineMainHeadItem:GetCfg()
    return self._cfg
end

--获得送巧克力任务id
function UIActivityValentineMainHeadItem:GetSendTaskId()
    local taskGroupId = self._cfg.TaskGroupID
    local taskId = Cfg.cfg_valentine_task_group[taskGroupId].TaskIDGroup[4]
    return taskId
end

--设置头像为完成状态
function UIActivityValentineMainHeadItem:SetHeadFinish()
    self._doneObj:SetActive(true)
    self._redObj:SetActive(false)
end

--设置头像为解锁
function UIActivityValentineMainHeadItem:SetHeadUnLock()
    self._lockObj:SetActive(false)
end

function UIActivityValentineMainHeadItem:HeadBtnOnClick(noAnim)
    self:SetSelecte(true,noAnim)
    self._callback(self)
end

--获得送巧克力任务状态
---@return QuestStatus
function UIActivityValentineMainHeadItem:GetSendTaskStatus()
    local taskId = self:GetSendTaskId()
    local questModule = GameGlobal.GetModule(QuestModule)
    ---@type Quest
    local task = questModule:GetQuest(taskId)
    local status = task:Status()

    return status
end