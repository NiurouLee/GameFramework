---昼夜系统参数
---@class FeatureEffectParamDayNight: FeatureEffectParamBase
_class("FeatureEffectParamDayNight", FeatureEffectParamBase)
FeatureEffectParamDayNight = FeatureEffectParamDayNight
---构造
function FeatureEffectParamDayNight:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamDayNight:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.EnterState then
        self._enterState = t.EnterState--初始状态
    end
    if t.DayRound then
        self._dayRound = t.DayRound--白天持续回合
    end
    if t.NightRound then
        self._nightRound = t.NightRound--夜晚持续回合
    end
end
---模块类型
function FeatureEffectParamDayNight:GetFeatureType()
    return FeatureType.DayNight
end
---复制用
---@param param FeatureEffectParamDayNight
function FeatureEffectParamDayNight:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamDayNight
function FeatureEffectParamDayNight:CloneSelf()
    local param = FeatureEffectParamDayNight:New()
    param:CopyFrom(self)
    return param
end
---替换部分参数
function FeatureEffectParamDayNight:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end
---初始状态
function FeatureEffectParamDayNight:GetEnterState()
    return self._enterState
end
---白天持续回合
function FeatureEffectParamDayNight:GetDayRound()
    return self._dayRound
end
---夜晚持续回合
function FeatureEffectParamDayNight:GetNightRound()
    return self._nightRound
end
---根据类型取持续回合
function FeatureEffectParamDayNight:GetLastRound(state)
    if state == FeatureDayNightState.Day then
        return self:GetDayRound()
    elseif state == FeatureDayNightState.Night then
        return self:GetNightRound()
    end
end
