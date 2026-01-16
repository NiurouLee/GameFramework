--
---@class UIN26CookMatRequireController : UIController
_class("UIN26CookMatRequireController", UIController)
UIN26CookMatRequireController = UIN26CookMatRequireController

---@param res AsyncRequestRes
function UIN26CookMatRequireController:LoadDataOnEnter(TT, res)
    self._cookData = UIN26CookData.New()
    self._cookData:LoadData(TT,res)
    local state = self._cookData:GetCookState()
    if state == UISummerOneEnterBtnState.NotOpen then
        return
    elseif state == UISummerOneEnterBtnState.Closed then
        return
    end
    local com, comInfo = self._cookData:GetComponnet()
    ---@type NewYearDinnerMiniGameComponent
    self._component = com
    ---@type NewYearDinnerComponentInfo
    self._foodData = comInfo
end
--初始化
function UIN26CookMatRequireController:OnShow(uiParams)
    self._taskTb = {} --任务表
    self._widgets = {}
    self:InitWidget()
    self:GetInfo()
    self:RefreshTaskList()
end
--获取ui组件
function UIN26CookMatRequireController:InitWidget()
    self._spineLoader = self:GetGameObject("spineLoader")
    self._content = self:GetUIComponent("UISelectObjectPath","content")
    self._contentRect = self:GetUIComponent("RectTransform","content")
    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")
    self._anim = self:GetUIComponent("Animation","anim")

    local btns = self:GetUIComponent("UISelectObjectPath", "topBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            GameGlobal.TaskManager():StartTask(self._CloseFunc,self)
        end,
        nil,
        nil
    )
end

function UIN26CookMatRequireController:_CloseFunc(TT)
    self:Lock("UIN26CookMatRequireController_Close")
    self._anim:Play("uieff_N26_CookMatRequireController_out")
    local time = self._anim:GetClip("uieff_N26_CookMatRequireController_out").length
    YIELD(TT, time * 1000)
    self:UnLock("UIN26CookMatRequireController_Close")

    self:CloseDialog()
    self:CallUIMethod("UIN26CookMainController", "RefreshRequireRed")
end

--获取页面需要的信息
function UIN26CookMatRequireController:GetInfo()
    
end

--刷新任务列表
function UIN26CookMatRequireController:RefreshTaskList()
    self:_Sort()
    self._content:SpawnObjects("UIN26CookMatRequireItem",#self._taskTb)
    self._widgets = self._content:GetAllSpawnList()
    for i,v in pairs(self._widgets) do
        local task = self._taskTb[i]
        v:SetData(task,self._component,i,
        function()
            self:_ReceiveCallback()
        end,
        function (tplId, pos)
            self:OnItemClicked(tplId, pos)
        end)
    end
end

function UIN26CookMatRequireController:_ReceiveCallback()

end

--任务排序
function UIN26CookMatRequireController:_Sort()
    self._taskTb = {}
    local tb = self._foodData.task_list
    local unFinish = {}
    local received = {}
    for _,task in pairs(tb) do
        if task.status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH then
            table.insert(unFinish,task)
        elseif task.status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV then
            table.insert(self._taskTb,task)
        elseif task.status == NewYearDinner_Status.E_NewYearDinner_Status_RECVED then
            table.insert(received,task)
        end
    end

    for _,task in pairs(unFinish) do
        table.insert(self._taskTb,task)
    end
    for _,task in pairs(received) do
        table.insert(self._taskTb,task)
    end
end

function UIN26CookMatRequireController:OnItemClicked(matid, pos)
    self._selectInfo:SetData(matid, pos)
end