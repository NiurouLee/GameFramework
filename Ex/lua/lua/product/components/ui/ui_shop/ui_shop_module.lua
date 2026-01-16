---@class UIShopModule:UIModule
_class("UIShopModule", UIModule)
UIShopModule = UIShopModule

---@class PayStep
PayStep = {
    LaunchPurchaseUI = 1, -- 拉起购买面板
    ClickPurchaseButton = 2, -- 点击购买
    LaunchMidasAuthentication = 3, -- 拉起Midas支付鉴权
    PayResult = 4, -- 支付结果
}
_enum("PayStep", PayStep)

function UIShopModule:Constructor()
    self._curPurchaseSerialNumber = ""
    self._lastPurchaseStartTime = ""
    self._indexNumber = 1
end

function UIShopModule:Dispose()
end

function UIShopModule:GeneratePurchaseSerialNumber()
    local sTime = os.date("!*t", math.floor(GameGlobal.GetModule(SvrTimeModule):GetServerTime() / 1000))
    local timeStr = string.format('%04d%02d%02d%02d%02d%02d',sTime.year,sTime.month,sTime.day,sTime.hour,sTime.min,sTime.sec)
    
    if timeStr == self._lastPurchaseStartTime then
        self._indexNumber = self._indexNumber + 1
        if self._indexNumber >= 100 then
            Log.fatal("generate purchase serial number error, index number exceeded 99")
            self._indexNumber = 0
        end
    else
        self._indexNumber = 1
    end
    self._lastPurchaseStartTime = timeStr
    
    self._curPurchaseSerialNumber = GameGlobal.GameLogic():GetOpenId() .. timeStr .. string.format('%02d', self._indexNumber)
    return self._curPurchaseSerialNumber
end

---@param payStep number PayStep枚举值
---@param result boolean 结果
---@param errorCode number 错误码
---@param extraParam string 额外信息
function UIShopModule:ReportPayStep(payStep, result, errorCode, extraParam)
    if not errorCode then
        errorCode = 0
    end

    if not extraParam then
        extraParam = ""
    end

    local stepName = ""
    local paramsTable = {}
    if payStep == PayStep.LaunchPurchaseUI then
        stepName = "LaunchPurchaseUI"
        paramsTable["serial_number"] = self:GeneratePurchaseSerialNumber()
        paramsTable["purchase_content"] = extraParam

    elseif payStep == PayStep.ClickPurchaseButton then
        stepName = "ClickPurchaseButton"
        paramsTable["serial_number"] = self._curPurchaseSerialNumber
        paramsTable["purchase_fail_reason"] = extraParam

    elseif payStep == PayStep.LaunchMidasAuthentication then
        stepName = "LaunchMidasAuthentication"
        paramsTable["serial_number"] = self._curPurchaseSerialNumber

    elseif payStep == PayStep.PayResult then
        stepName = "PayResult"
        paramsTable["serial_number"] = self._curPurchaseSerialNumber
        paramsTable["pay_fail_reason"] = extraParam

    else
        Log.fatal("ShopModule:ReportPayStep wrong step: ", tostring(payStep))
        return
    end

    UAReportHelper.UAReportPayStep(payStep, stepName, result, errorCode, json.encode(paramsTable))
end