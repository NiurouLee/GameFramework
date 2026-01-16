---@class UIN25IdolCommonTrainPoint:UICustomWidget
_class("UIN25IdolCommonTrainPoint", UICustomWidget)
UIN25IdolCommonTrainPoint = UIN25IdolCommonTrainPoint

---@type trainType 三维属性类型
function UIN25IdolCommonTrainPoint:SetData(uiType, trainType, value, tipsCallback)
    self._trainType = trainType or 1
    self._tipsCallback = tipsCallback

    self:_SetState(trainType)
    self:_SetBgState(uiType)
    self:_SetText(uiType, value)
end

function UIN25IdolCommonTrainPoint:_SetState(state)
    self._stateObj = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            {"_icon1"},
            {"_icon2"},
            {"_icon3"}
        },
        self._stateObj
    )
    UIWidgetHelper.SetObjGroupShow(self._stateObj, state)
end

function UIN25IdolCommonTrainPoint:_SetBgState(uiType)
    local tb = {
        [0] = 2,
        [1] = 1,
        [2] = 3,
        [3] = 3
    }
    local state = tb[uiType]
    self._stateBgObj = UIWidgetHelper.GetObjGroupByWidgetName(self,
        {
            {"_bg"},
            {"_bgRed"},
            {"_bgPlus"}
        },
        self._stateBgObj
    )
    UIWidgetHelper.SetObjGroupShow(self._stateBgObj, state)
end

function UIN25IdolCommonTrainPoint:_SetText(uiType, value)
    value = value or 0

    local c0_1 = "#ff9e9e"
    local c0_2 = "#ff4c4c"
    local c1_1 = "#cccccc"
    local c1_2 = "#737373"
    local c2 = "#737373"
    local c3 = "#f1647f"
    local text
    if uiType == 0 then -- 带前置 0 的格式，红色，数量不足样式
        text = UIActivityHelper.FormatNumber_PreZero(5, value, c0_1, c0_2)
    elseif uiType == 1 then -- 带前置 0 的格式，黑色，正常样式
        text = UIActivityHelper.FormatNumber_PreZero(5, value, c1_1, c1_2)
    elseif uiType == 2 then -- 教室，增加数值
        text = UIActivityHelper.GetColorText(c2, "+" .. value)
    else -- 教室，增加数值，灵感爆发
        text = UIActivityHelper.GetColorText(c3, "+" .. value)
    end
    UIWidgetHelper.SetLocalizationText(self, "_text", text)
end

function UIN25IdolCommonTrainPoint:BtnOnClick(go)
    if self._tipsCallback then
        local pos = go.transform.position
        local type = self._trainType -- UIN25IdolCommonTips:SetData(type)
        self._tipsCallback(pos, { type })
    end
end