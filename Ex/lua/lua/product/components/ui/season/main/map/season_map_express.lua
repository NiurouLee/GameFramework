---@class SeasonMapExpress:Object
_class("SeasonMapExpress", Object)
SeasonMapExpress = SeasonMapExpress

---@param triggerType SeasonExpressTriggerType
function SeasonMapExpress:Constructor(eventPoint, triggerType, expressArr)
    self._eventPoint = eventPoint
    ---@type SeasonExpressTriggerType
    self._triggerType = triggerType
    ---@type SeasonMapExpressBase[]
    self._expressList = {}
    self._isLevel = false
    self._curExpressIndex = 0 --当前表现列表索引
    ---@type SeasonMapExpressBase
    self._curExpress = nil
    self:_CreateExpress(expressArr)
end

function SeasonMapExpress:Update(deltaTime)
    if self._curExpress then
        self._curExpress:Update(deltaTime)
    end
end

function SeasonMapExpress:Dispose()
    for _, express in pairs(self._expressList) do
        express:Dispose()
    end
    table.clear(self._expressList)
end

function SeasonMapExpress:_CreateExpress(expressArr)
    for i = 1, #expressArr do
        local expressCfg = Cfg.cfg_season_map_express[expressArr[i]]
        if expressCfg then
            local express = SeasonMapExpressFactory:GetInstance():CreateMapExpress(self._eventPoint, expressCfg.ExpressType, expressCfg)
            if express then
                if express:ExpressType() == SeasonExpressType.Level then
                    self._isLevel = true
                end
                table.insert(self._expressList, express)
            end
        end
    end
end

---@return SeasonExpressTriggerType
function SeasonMapExpress:TriggerType()
    return self._triggerType
end

function SeasonMapExpress:IsLevel()
    return self._isLevel
end

function SeasonMapExpress:CurExpressIndex()
    return self._curExpressIndex
end

---@return boolean 如果返回true表示播放完成
function SeasonMapExpress:PlayNext(param)
    if self._curExpressIndex >= #self._expressList then
        return true
    end
    self._curExpressIndex = self._curExpressIndex + 1
    self._curExpress = self._expressList[self._curExpressIndex]
    if self._curExpress then
        self._curExpress:Play(param)
    end
end

--判断表现中是否包含指定类型的表现
---@param expressType SeasonExpressType
function SeasonMapExpress:ContainExpress(expressType)
    for index, express in pairs(self._expressList) do
        if express:ExpressType() == expressType then
            return true, express:Content(), index
        end
    end
    return false, nil, nil
end

--获取指定类型的所有表现
---@param expressType SeasonExpressType
---@return SeasonMapExpressBase[]
function SeasonMapExpress:GetExpresses(expressType)
    local t = nil
    for index, express in pairs(self._expressList) do
        if express:ExpressType() == expressType then
            if not t then
                t = {}
            end
            table.insert(t, express)
        end
    end
    return t
end

function SeasonMapExpress:Reset()
    self._curExpress = nil
    self._curExpressIndex = 0
    for _, express in pairs(self._expressList) do
        express:Reset()
    end
end

--从之前断点位置继续播放
function SeasonMapExpress:ResumePlay(expressIndex, param)
    if expressIndex > #self._expressList then
        Log.error("SeasonMapExpress ResumePlay fail. expressIndex error!", expressIndex, #self._expressList)
        return
    end
    self._curExpressIndex = expressIndex
    self._curExpress = self._expressList[self._curExpressIndex]
    if self._curExpress then
        self._curExpress:Play(param)
    end
end

function SeasonMapExpress:IsPlaying()
    for _, express in pairs(self._expressList) do
        if express:State() == SeasonExpressState.Playing then
            return true
        end
    end
    return false
end