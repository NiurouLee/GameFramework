--
---@class UIActivityValentineMainTaskItem : UICustomWidget
_class("UIActivityValentineMainTaskItem", UICustomWidget)
UIActivityValentineMainTaskItem = UIActivityValentineMainTaskItem

function UIActivityValentineMainTaskItem:Constructor()

end

--初始化
function UIActivityValentineMainTaskItem:OnShow(uiParams)
    self:_GetComponents()
    self._specialTaskID = {3570038,3570042}  --需要特殊处理的任务ID
    self._atlas = self:GetAsset("Valentine.spriteatlas", LoadType.SpriteAtlas)
end

--获取ui组件
function UIActivityValentineMainTaskItem:_GetComponents()
    self._taskNo = self:GetUIComponent("UILocalizationText","taskNo")
    self._taskTxt = self:GetUIComponent("UILocalizationText","taskTxt")
    self._progressTxt = self:GetUIComponent("UILocalizationText","progress")
    self._doneBtnObj = self:GetGameObject("doneBtn")
    self._taskBtnObj = self:GetGameObject("taskBtn")
end

--设置数据
function UIActivityValentineMainTaskItem:SetData(cfg,index,data)
    self._cfg = cfg
    self._index = index
    self._data = data

    self:InitData()

end

function UIActivityValentineMainTaskItem:InitData()
    self._taskNo:SetText(self._index)

    local taskId = self._cfg.ID
    local questModule = GameGlobal.GetModule(QuestModule)
    ---@type Quest
    self._task = questModule:GetQuest(taskId)
    local info = self._task:QuestInfo()
    self._taskTxt:SetText(StringTable.Get(self._cfg.QuestDesc))
    local curProcess = info.cur_progress
    local totalPorcess = info.total_progress
    local isSpecial = self:_CheckTaskIsSpecial(taskId)
    totalPorcess = isSpecial and 1 or totalPorcess

    if self._task:Status() >= QuestStatus.QUEST_Completed then
        --完成
        curProcess = isSpecial and 1 or curProcess
        self._taskTxt.color = Color(162/255,162/255,162/255)
        self._progressTxt:SetText("(<color=#c8a145>"..curProcess.."</color>/"..totalPorcess..")")

        self._doneBtnObj:SetActive(true)
        self._taskBtnObj:SetActive(false)
    else
        --未完成
        curProcess = isSpecial and 0 or curProcess
        self._taskTxt.color = Color(128/255,100/255,23/255)
        self._progressTxt:SetText("(<color=#41b9fa>"..curProcess.."</color>/"..totalPorcess..")")

        self._doneBtnObj:SetActive(false)
        self._taskBtnObj:SetActive(true)
    end
end

function UIActivityValentineMainTaskItem:TaskBtnOnClick()
    if self._task and self._task:Status() >= QuestStatus.QUEST_Completed then
        return
    end

    local isOver = self._data:CheckTaskIsOver()
    if isOver then
        ToastManager.ShowToast(StringTable.Get("str_n27_valentine_y_offline"))
        return
    end
    local questInfo = self._task:QuestInfo()
    local questModule = GameGlobal.GetModule(QuestModule)
    ---@type UIJumpModule
    local jumpModule = questModule.uiModule
    local jumpType = questInfo.JumpID
    local jumpParam = questInfo.JumpParam

    jumpModule:SetJumpUIData(jumpType, jumpParam)
    jumpModule:Jump()
end

--检查taskID是不是需要特殊处理
function UIActivityValentineMainTaskItem:_CheckTaskIsSpecial(taskID)
    for _, v in ipairs(self._specialTaskID) do
        if v == taskID then
            return true
        end
    end
    return false
end
