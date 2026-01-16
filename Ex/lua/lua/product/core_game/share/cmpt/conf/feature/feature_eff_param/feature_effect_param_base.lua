--[[------------------------------------------------------------------------------------------
    FeatureEffectParamBase : 模块效果配置基类
]] --------------------------------------------------------------------------------------------

_class("FeatureEffectParamBase", Object)
---@class FeatureEffectParamBase: Object
FeatureEffectParamBase = FeatureEffectParamBase
---构造
function FeatureEffectParamBase:Constructor(t)
    self._oriData = t
end

---模块类型
function FeatureEffectParamBase:GetFeatureType()
    return -1
end

function FeatureEffectParamBase:_RefreshData(t)

end

function FeatureEffectParamBase:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end

---@param param FeatureEffectParamCard
function FeatureEffectParamBase:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamCard
function FeatureEffectParamBase:CloneSelf()
    local param = self:New()
    param:CopyFrom(self)
    return param
end
