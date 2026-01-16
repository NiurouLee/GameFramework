--
---@class UIActivityValentineMainFlavorItem : UICustomWidget
_class("UIActivityValentineMainFlavorItem", UICustomWidget)
UIActivityValentineMainFlavorItem = UIActivityValentineMainFlavorItem

function UIActivityValentineMainFlavorItem:Constructor()

end

--初始化
function UIActivityValentineMainFlavorItem:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIActivityValentineMainFlavorItem:_GetComponents()
    self._hookImg = self:GetUIComponent("Image","hookImg")
    self._foodName = self:GetUIComponent("UILocalizationText","foodName")
    self._hookImgObj = self:GetGameObject("hookImg")
end

--设置数据
function UIActivityValentineMainFlavorItem:SetData(cfg,isDone)
    self._cfg = cfg
    self:InitData(isDone)
end

function UIActivityValentineMainFlavorItem:InitData(isDone)
    local questModule = GameGlobal.GetModule(QuestModule)
    local taskId = self._cfg.TaskID
    ---@type Quest
    local task = questModule:GetQuest(taskId)
    self._foodName:SetText(StringTable.Get(self._cfg.Info))

    if isDone or (task and task:Status() >= QuestStatus.QUEST_Completed) then
        --self._hookImg.sprite
        self._hookImgObj:SetActive(true)
    else
        self._hookImgObj:SetActive(false)
        --self._hookImg.sprite
    end
end