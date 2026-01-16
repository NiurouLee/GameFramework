--region PetForecastData
---@class PetForecastData:Object
---@field id number
---@field endTime number
---@field cfg table
---@field prefab string
---@field enterIcon string
---@field pieces PetForecastPiece[]
---@field pets table
---@field imgLeftTime string
---@field posTitle Vector2
---@field sizeTitle Vector2
---@field colorLeftTimeBG Color
---@field colorLeftTimeHint Color
---@field colorLeftTime Color
---@field colorUnlock Color
---
---@field last PetForecastView 有新图时，最后一个图解锁表现
---@field normal PetForecastView 有新图时，常态表现
---@field close PetForecastView 有新图时，关闭表现
_class("PetForecastData", Object)
PetForecastData = PetForecastData

function PetForecastData:Constructor()
    self.mRole = GameGlobal.GetModule(RoleModule)
    self.cacheVigorous = 0 --缓存的活跃度

    self.last = nil
    self.normal = nil
    self.close = nil
end

---@param serData PredictionMsgInfo
function PetForecastData:Init(serData)
    self.id = serData.id --预告活动id
    self.endTime = serData.end_time or 0 --活动结束时间
    self.curDay = serData.day + 1 --当前第几天
    self.cfg = Cfg.cfg_prediction[self.id]
    if self.cfg then
        local cg = self.cfg.cg
        if cg then
            self.prefab = cg.prefab or "UIPetForecast"
            self.enterIcon = cg.enter
            self.mainBg = cg.mainBg
            self.bg = cg.bg
            self.imgLeftTime = cg.imgLeftTime or "main_prec_timebg"
            if cg.titleRect then
                self.posTitle = Vector2(cg.titleRect.x, cg.titleRect.y)
                self.sizeTitle = Vector2(cg.titleRect.w, cg.titleRect.h)
            else
                self.posTitle = Vector2(0, -440)
                self.sizeTitle = Vector2(1800, 195)
            end
            self:SetLeftTimeColor(cg.colorLeftTimeBG, cg.colorLeftTimeHint, cg.colorLeftTime, cg.colorUnlock)
            self.bgTitle = cg.bgTitle
            self.imgTitle = cg.imgTitle
            if self.cfg.rects then
                local mSignIn = GameGlobal.GetModule(SignInModule)
                self.pieces = {}
                for i, rect in ipairs(self.cfg.rects) do
                    ---@type PetForecastPiece
                    local piece = PetForecastPiece:New()
                    piece.day = i
                    piece.pos.x = rect.x
                    piece.pos.y = rect.y
                    piece.wh.x = rect.w
                    piece.wh.y = rect.h

                    piece.apos.x = rect.ax
                    piece.apos.y = rect.ay
                    piece.awh.x = rect.aw
                    piece.awh.y = rect.ah

                    piece.ppos.x = rect.px
                    piece.ppos.y = rect.py
                    local index = i - 1
                    piece.state = serData.status[index] or PredictionStatus.PRES_UnReach
                    piece.awards = self.cfg["award" .. i] or {}
                    if piece.state == PredictionStatus.PRES_UnReach then
                        if piece:IsCurDay() then
                            piece.curValue = self.mRole:GetAssetCount(RoleAssetID.RoleAssetVigorous) --只有首次PRES_UnReach才有当前进度
                            piece.maxValue = self.cfg["Vigorous" .. i] or 0
                        end
                    end
                    local cfgImgs = self.cfg.imgs
                    if cfgImgs and cfgImgs[i] then
                        local cfgvImgs = cfgImgs[i]
                        piece.imgSelect = cfgvImgs.s
                        piece.imgFull = cfgvImgs.f
                        piece.imgBG = cfgvImgs.bg
                        piece.imgComic = cfgvImgs.comic
                        piece.imgSentence = cfgvImgs.sentence
                    end
                    piece:Init(i, self.cfg)
                    table.insert(self.pieces, piece)
                end
            else
                Log.fatal("### cfg_prediction.rects nil. id=", self.id)
            end
            if self.cfg.pets then
                self.pets = {}
                for i, pet in ipairs(self.cfg.pets) do
                    table.insert(self.pets, {petId = pet.petId, pos = Vector2(pet.x, pet.y)})
                end
            else
                Log.fatal("### cfg_prediction.rects nil. id=", self.id)
            end
            if self.cfg.effect then
                self:InitPetForecastView(self.cfg.effect)
            end
        else
            Log.fatal("### cfg_prediction.cg nil. id=", self.id)
        end
    else
        Log.fatal("### no data in cfg_prediction. id=", self.id)
    end
end

---@param code Prediction_Result_Code 错误码
---@param isToast boolean 是否提示
---@return boolean
---处理错误码
function PetForecastData.CheckCode(code, isToast)
    if code == Prediction_Result_Code.PREDICTION_SUCCEED then
        return true
    end
    if isToast then
        ToastManager.ShowToast(StringTable.Get("str_prediction_error_code_" .. code))
    end
    return false
end
function PetForecastData:GetEnterIcon()
    return self.enterIcon
end

function PetForecastData:GetMainBG()
    return self.mainBg
end

function PetForecastData:GetBG()
    return self.bg
end

function PetForecastData:GetLeftTimeColor()
    return self.colorLeftTimeBG, self.colorLeftTimeHint, self.colorLeftTime
end
function PetForecastData:SetLeftTimeColor(colorLeftTimeBG, colorLeftTimeHint, colorLeftTime, colorUnlock)
    local GetColor = function(colorCfg)
        if colorCfg then
            local r, g, b = colorCfg[1] / 255, colorCfg[2] / 255, colorCfg[3] / 255
            local a = colorCfg[4] and colorCfg[4] / 255 or 1
            return Color(r, g, b, a)
        end
        return Color.white
    end
    self.colorLeftTimeBG = GetColor(colorLeftTimeBG)
    self.colorLeftTimeHint = GetColor(colorLeftTimeHint)
    self.colorLeftTime = GetColor(colorLeftTime)
    self.colorUnlock = GetColor(colorUnlock)
end

---更新第day天的状态
function PetForecastData:UpdateState(day, state)
    for i, piece in ipairs(self.pieces) do
        if piece.day == day then
            piece.state = state
            break
        end
    end
end
---所有都领取
function PetForecastData:IsAllAccepted()
    for i, piece in ipairs(self.pieces) do
        if piece.state == PredictionStatus.PRES_UnAccept or piece.state == PredictionStatus.PRES_UnReach then
            return false
        end
    end
    return true
end
---活跃度是否更新
function PetForecastData:IsVigorousChanged()
    local curVigorous = self.mRole:GetAssetCount(RoleAssetID.RoleAssetVigorous)
    if self.cacheVigorous ~= curVigorous then
        self.cacheVigorous = curVigorous
        return true
    end
    return false
end
---@return PetForecastPiece
function PetForecastData:GetPiece(day)
    for i, piece in ipairs(self.pieces) do
        if piece.day == day then
            return piece
        end
    end
end
function PetForecastData:InitPetForecastView(cfgv)
    if cfgv.last then
        self.last = PetForecastView:New()
        self.last:Init(cfgv.last)
    end
    if cfgv.normal then
        self.normal = PetForecastView:New()
        self.normal:Init(cfgv.normal)
    end
    if cfgv.close then
        self.close = PetForecastView:New()
        self.close:Init(cfgv.close)
    end
end

---是否有可替换图
function PetForecastData:HasNewPieceImage()
    local b = self.last and true or false
    return b
end
--endregion

--region PetForecastPiece 拼图类
---@class PetForecastPiece:Object
---@field state PredictionStatus
---@field curValue number
---@field maxValue number
---
---@field imgSelect string 选中图
---@field imgFull string 可领取图
---@field imgBG string 半透遮罩
---@field imgComic string 漫画
---@field imgSentence string 文案图（只用于UIPetForecast2）
---
---@field imgSelectUnlock string 新选中图
---@field imgFullUnlock string 新可领取图
---@field imgBGUnlock string 新半透遮罩
---@field imgComicUnlock string 新漫画
---@field imgSentenceUnlock string 新文案图（只用于UIPetForecast2）
_class("PetForecastPiece", Object)
PetForecastPiece = PetForecastPiece

function PetForecastPiece:Constructor()
    self.day = 0
    self.pos = Vector2.zero --位置
    self.wh = Vector2.zero --尺寸
    self.apos = Vector2.zero --奖励位置
    self.awh = Vector2.zero --奖励尺寸
    self.ppos = Vector2.zero --进度位置
    self.state = PredictionStatus.PRES_UnReach
    self.curValue = 0
    self.maxValue = 0
    self.awards = {}

    self.imgSelect = ""
    self.imgFull = ""
    self.imgBG = ""
    self.imgComic = ""
    self.imgSentence = ""

    self.imgSelectUnlock = ""
    self.imgFullUnlock = ""
    self.imgBGUnlock = ""
    self.imgComicUnlock = ""
    self.imgSentenceUnlock = ""
end
---该碎片是否是当前天
function PetForecastPiece:IsCurDay()
    local data = GameGlobal.GetModule(SignInModule):GetPredictionData()
    if data then
        return data.curDay == self.day
    end
    return false
end

function PetForecastPiece:Init(i, cfgv)
    self:InitImgUnlock(cfgv.unlockImgs[i])
end
function PetForecastPiece:InitImgUnlock(cfgvImgs)
    if cfgvImgs then
        self.imgSelectUnlock = cfgvImgs.s
        self.imgFullUnlock = cfgvImgs.f
        self.imgBGUnlock = cfgvImgs.bg
        self.imgComicUnlock = cfgvImgs.comic
        self.imgSentenceUnlock = cfgvImgs.sentence
    end
end
--endregion

--region PetForecastView 表现
---@class PetForecastView:Object
---@field parallel PetForecastViewParallel[]
_class("PetForecastView", Object)
PetForecastView = PetForecastView

function PetForecastView:Constructor()
    self.parallel = {}
end
function PetForecastView:Init(t)
    if not t then
        return
    end
    for _, pi in pairs(t) do
        local p = PetForecastViewParallel:New()
        for _, ci in ipairs(pi) do
            local c = PetForecastViewCommand:New()
            local strs = string.split(ci, ",")
            for i, str in ipairs(strs) do
                str = string.trim(str)
                if i == 1 then
                    c.name = str
                else
                    table.insert(c.params, str)
                end
            end
            table.insert(p.commands, c)
        end
        table.insert(self.parallel, p)
    end
end
--endregion

--region PetForecastView 并行表现，每个并行表现下有一串串行表现
---@class PetForecastViewParallel:Object
---@field commands PetForecastViewCommand[]
_class("PetForecastViewParallel", Object)
PetForecastViewParallel = PetForecastViewParallel

function PetForecastViewParallel:Constructor()
    self.commands = {}
end
--endregion

-- --region PetForecastView 串行表现
-- ---@class PetForecastViewSerial:Object
-- ---@field commands PetForecastViewCommand
-- _class("PetForecastViewSerial", Object)
-- PetForecastViewSerial = PetForecastViewSerial

-- function PetForecastViewSerial:Constructor()
--     self.commands = nil
-- end
-- --endregion

--region PetForecastView 具体表现
-- [1]="Wait,等待时长ms",
-- [2]="PlayEffect,特效名,挂特效的结点名",
-- [3]="PlayAudio,音效id",
-- [4]="ReplaceImage", //替图
---@class PetForecastViewCommand:Object
---@field name string 命令名
---@field params string[] 命令参数列表
_class("PetForecastViewCommand", Object)
PetForecastViewCommand = PetForecastViewCommand

function PetForecastViewCommand:Constructor()
    self.name = ""
    self.params = {}
end
--endregion
