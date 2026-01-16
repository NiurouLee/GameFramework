require("ui_side_enter_center_content_base")

---@class UIPetForecast2Content : UISideEnterCenterContentBase
_class("UIPetForecast2Content", UISideEnterCenterContentBase)
UIPetForecast2Content = UIPetForecast2Content

function UIPetForecast2Content:DoInit(params)
    self:GetGameObject("CloseBtn"):SetActive(self._type == ESideEnterContentType.Single)
end

function UIPetForecast2Content:DoShow()
    ---@type UIPetForecastDataLoader
    self._dataLoader = UIPetForecastDataLoader:New()
    -- self.data = self.mSignIn:GetPredictionData()
    self.data = self._data  -- UISideEnterCenterContentBase:OnInit() 中传入

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIPetForecast.spriteatlas", LoadType.SpriteAtlas)
    ---@type RawImageLoader
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    ---@type UICustomWidgetPool
    self.pieces = self:GetUIComponent("UISelectObjectPath", "pieces")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UnityEngine.UI.Image
    self.imgLeftTime = self:GetUIComponent("Image", "imgLeftTime")
    ---@type UnityEngine.UI.Image
    self.imgClock = self:GetUIComponent("Image", "imgClock")
    ---@type UILocalizationText
    self.txtLeftTimeHint = self:GetUIComponent("UILocalizationText", "txtLeftTimeHint")
    ---@type UILocalizationText
    self.txtLeftTime = self:GetUIComponent("UILocalizationText", "txtLeftTime")
    ---@type UICustomWidgetPool
    local s = self:GetUIComponent("UISelectObjectPath", "tips")
    ---@type UISelectInfo
    self._tips = s:SpawnObject("UISelectInfo")
    ---@type RawImageLoader
    self.imgTitle = self:GetUIComponent("RawImageLoader", "imgTitle")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    self.goSentence = self:GetGameObject("imgSentence")
    ---@type RawImageLoader
    self.imgSentence = self:GetUIComponent("RawImageLoader", "imgSentence")

    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self:AttachEvent(GameEventType.RolePropertyChanged, self.ItemCountChanged)
    self.pieces:SpawnObjects("UIPetForecastItem2", table.count(self.data.pieces))
    ---@type UIPetForecastItem2[]
    self.pieceList = self.pieces:GetAllSpawnList()
    self.te =
        UIActivityHelper.StartTimerEvent(
        self.te,
        function()
            self:FlushLeftTime()
        end
    )

    self.curSelectDay = 0
    self:Flush()
end

function UIPetForecast2Content:DoHide()
    self.te = UIActivityHelper.CancelTimerEvent(self.te)
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self:DetachEvent(GameEventType.RolePropertyChanged, self.ItemCountChanged)
    self.imgTitle:DestoryLastImage()
    self._bg:DestoryLastImage()
end

function UIPetForecast2Content:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIPetForecast2Content:RequestPrediction(TT)
    local lockName = "UIPetForecast2Content_RequestPrediction"
    self:Lock(lockName)
    self._data = self._dataLoader:LoadData(TT)
    self:Flush()
    self:UnLock(lockName)
end

function UIPetForecast2Content:Flush()
    if not self.data then
        Log.warn("### self.data nil.")
        return
    end

    self:FlushLeftTimeColor()
    self:FlushLeftTime()
    self.txtDesc:SetText(StringTable.Get("str_prediction_info_" .. self.data.id))
    self:FlushDesc()

    self.imgTitle:LoadImage(self.data.imgTitle)
    self._bg:LoadImage(self.data:GetBG())

    self:FlushPieces()
end

function UIPetForecast2Content:FlushPieces()
    local len = table.count(self.data.pieces)
    for i, v in ipairs(self.pieceList) do
        v:Flush(
            i,
            function(day)
                local piece = self.data.pieces[day]
                if not piece or piece.state ~= PredictionStatus.PRES_Accepted then
                    return
                end
                if day < 1 or day > len then
                    Log.fatal("### invalid param. day = ", day)
                    return
                end
                if self.pieceList[self.curSelectDay] then
                    self.pieceList[self.curSelectDay]:Select(false)
                end
                if self.curSelectDay == day then
                    self.curSelectDay = 0
                    self:FlushDesc()
                else
                    self.pieceList[day]:Select(true)
                    self.curSelectDay = day
                    self:FlushDesc()
                end
            end
        )
    end
end

function UIPetForecast2Content:FlushLeftTimeColor()
    local colorBG, colorHint, color = self.data:GetLeftTimeColor()
    self.imgLeftTime.color = colorBG
    self.imgClock.color = colorHint
    self.txtLeftTimeHint.color = colorHint
    self.txtLeftTime.color = color
end

function UIPetForecast2Content:FlushLeftTime()
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < self.data.endTime then
        local leftSeconds = UICommonHelper.CalcLeftSeconds(self.data.endTime)
        local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
        if d >= 1 then
            self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_d_h", math.floor(d), math.floor(h)))
        else
            if h >= 1 then
                self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_h_m", math.floor(h), math.floor(m)))
            else
                if m >= 1 then
                    self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_m", math.floor(m)))
                else
                    self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_m", "<" .. 1))
                end
            end
        end
    else
        self.txtLeftTime:SetText(StringTable.Get("str_prediction_error_code_1"))
        UIActivityHelper.CancelTimerEvent(self.te)
    end
end

---@param curSelectDay number 当前选中的第N天拼图，0表示未选中
function UIPetForecast2Content:FlushDesc()
    if self.curSelectDay == 0 then
        self.goSentence:SetActive(false)
    else
        self.goSentence:SetActive(true)
        local piece = self.data.pieces[self.curSelectDay]
        self.imgSentence:LoadImage(piece.imgSentence)
    end
end

function UIPetForecast2Content:ShowTips(itemId, pos)
    self._tips:SetData(itemId, pos)
end

function UIPetForecast2Content:CloseBtnOnClick(go)
    self:CloseDialog(true)
end
function UIPetForecast2Content:ItemCountChanged()
    self:StartTask(self.RequestPrediction, self)
end