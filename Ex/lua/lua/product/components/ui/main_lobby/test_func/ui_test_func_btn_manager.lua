---@class UITestFuncBtnManager:Object
_class("UITestFuncBtnManager", Object)
UITestFuncBtnManager = UITestFuncBtnManager

function UITestFuncBtnManager:Constructor(uiView)
    self._uiView = uiView
    self._btn_Title = {}
    self._btn_Params = {}
end

function UITestFuncBtnManager:ExitBtnOnClick()
    self._root:SetActive(false)
end

function UITestFuncBtnManager:SpawnBtns(pool)
    local count = #self._btn_Title
    pool:SpawnObjects("UIMainLobbyTestFuncBtn", count)
    local list = pool:GetAllSpawnList()

    for i = 1, count do
        ---@type UIMainLobbyTestFuncBtn
        local obj = list[i]
        obj:SetData(self._btn_Title[i], self._btn_Params[i])
    end
end

--region AddFunc
-- params[1] 固定为按钮点击回调，查看 UITestFuncBtnManagerBtn
function UITestFuncBtnManager:_AddFunc(title, params)
    table.insert(self._btn_Title, title)
    table.insert(self._btn_Params, params)
end

function UITestFuncBtnManager:_AddCallback(title, callback)
    local params = { callback }
    self:_AddFunc(title, params)
end

function UITestFuncBtnManager:_AddFunShowDialog(title, name, uiParams)
    local params = {
        function()
            if uiParams and type(uiParams) == "table" then
                GameGlobal.UIStateManager():ShowDialog(name, table.unpack(uiParams))
            else
                GameGlobal.UIStateManager():ShowDialog(name, uiParams)
            end
        end
    }
    self:_AddFunc(title, params)
end

function UITestFuncBtnManager:_AddFunSwitchState(title, state, uiParams)
    local params = {
        function()
            if uiParams and type(uiParams) == "table" then
                GameGlobal.UIStateManager():SwitchState(state, table.unpack(uiParams))
            else
                GameGlobal.UIStateManager():SwitchState(state, uiParams)
            end
        end
    }
    self:_AddFunc(title, params)
end

---@param className 继承 UITestFuncSubpageBase
function UITestFuncBtnManager:_AddSubpageFunc(title, className)
    local params = {
        function()
            local obj = UIWidgetHelper.SpawnObject(self._uiView, "SubpagePool", className)
            obj:GetGameObject():SetActive(true)
        end
    }
    self:_AddFunc(title, params)
end

function UITestFuncBtnManager:_AddToggleFunc(title, callback, getValueCb)
    local params = {}
    params[1] = callback
    params[2] = true
    params[3] = getValueCb
    self:_AddFunc(title, params)
end

--endregion
