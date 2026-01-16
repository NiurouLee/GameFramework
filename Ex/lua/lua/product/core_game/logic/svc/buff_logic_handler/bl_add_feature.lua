--添加模块
require("buff_logic_base")

_class("BuffLogicAddFeature", BuffLogicBase)
---@class BuffLogicAddFeature : BuffLogicBase
BuffLogicAddFeature = BuffLogicAddFeature

function BuffLogicAddFeature:Constructor(buffinstance, logicParam)
    self._cfgFeatureList = logicParam.FeatureList--格式同cfg_pet_skill的FeatureList列 FeatureLit={feature={[6]={xxx}}}
    self._randomOne = logicParam.RandomOne--从中随机一个模块（当前没有的）
end

function BuffLogicAddFeature:DoLogic(notify)
    ---@type FeatureServiceLogic
	local lsvcFeature = self._world:GetService("FeatureLogic")
    local cfgFeatureList = {}
    if self._randomOne then
        local featureCfgDic = self._cfgFeatureList.feature
        if not featureCfgDic then
            return
        end
        local featureTypeList = {}
        for featureType, featureCfg in pairs(featureCfgDic) do
            table.insert(featureTypeList,featureType)
        end
        if #featureTypeList == 0 then
            return
        end
        local validFeatureList = {}
        --去掉已有的
        for _, featureType in ipairs(featureTypeList) do
            if not lsvcFeature:HasFeatureType(featureType) then
                table.insert(validFeatureList,featureType)
            end
        end
        if #validFeatureList == 0 then
            return
        end
        table.sort(validFeatureList, function(a, b) return a < b end )

        ---@type RandomServiceLogic
        local lsvcRandom = self._world:GetService("RandomLogic")
        local featureIndex = 1
        featureIndex = lsvcRandom:LogicRand(1,#validFeatureList)
        local useFeature = validFeatureList[featureIndex]
        cfgFeatureList = table.cloneconf(self._cfgFeatureList)
        cfgFeatureList.feature={}
        cfgFeatureList.feature[useFeature] = self._cfgFeatureList.feature[useFeature]
    else
        cfgFeatureList = self._cfgFeatureList
    end
    lsvcFeature:OnBuffAddFeature(cfgFeatureList)
    return BuffResultAddFeature:New()
end
