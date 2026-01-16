---San值系统参数
---@class FeatureEffectParamSan: FeatureEffectParamBase
_class("FeatureEffectParamSan", FeatureEffectParamBase)
FeatureEffectParamSan = FeatureEffectParamSan
---构造
function FeatureEffectParamSan:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamSan:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.EnterSanValue then
        self._enterSanValue = t.EnterSanValue--初始San值
    end
    if t.MaxSanValue then
        self._maxSanValue = t.MaxSanValue--最大值
    end
    if t.MinSanValue then
        self._minSanValue = t.MinSanValue--最小值
    end
    if t.RoundDelValue then
        self._roundDelValue = t.RoundDelValue--每回合降低值
    end
    if t.SanSysCfgId then
        Log.notice("SanSysCfgId:",t.SanSysCfgId," curId:",self._sanSysCfgId)
        self._sanSysCfgId = t.SanSysCfgId--San系统id 指向cfg_sanity表
    end
end
---模块类型
function FeatureEffectParamSan:GetFeatureType()
    return FeatureType.Sanity
end
---复制用
---@param param FeatureEffectParamSan
function FeatureEffectParamSan:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamSan
function FeatureEffectParamSan:CloneSelf()
    local param = FeatureEffectParamSan:New()
    param:CopyFrom(self)
    return param
end
---替换部分参数
function FeatureEffectParamSan:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end
---取sanity表中的Param配置
function FeatureEffectParamSan:GetSanityParam()
    if self._sanSysCfgId then
        local sanityCfg = Cfg.cfg_sanity[self._sanSysCfgId]
        if sanityCfg then
            return sanityCfg.Param
        end
    end
end
---初始值
function FeatureEffectParamSan:GetEnterSanValue()
    return self._enterSanValue
end
---最大值
function FeatureEffectParamSan:GetMaxSanValue()
    return self._maxSanValue
end
---最小值
function FeatureEffectParamSan:GetMinSanValue()
    return self._minSanValue or 0
end
---每回合降低值
function FeatureEffectParamSan:GetRoundDelValue()
    return self._roundDelValue
end