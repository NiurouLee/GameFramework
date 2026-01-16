_class("FeatureServiceHelper", Object)
---@class FeatureServiceHelper : Object
FeatureServiceHelper = FeatureServiceHelper

---@return FeatureServiceLogic
local function getLogicService()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()

    local lsvcFeature = mainWorld:GetService("FeatureLogic")
    return lsvcFeature
end

local function getWorld()
    ---@type GameGlobal
    local gameGlobal = GameGlobal:GetInstance()
    ---@type MainWorld
    local mainWorld = gameGlobal:GetMainWorld()
    return mainWorld
end

---@return number
function FeatureServiceHelper.GetLogicSanValue()
    local lsvcFeature = getLogicService()
    return lsvcFeature:GetSanValue()
end

---Check if player can cast one active skill based on Sanity(San) System
---=> FeatureServiceLogic:IsActiveSkillCanCast
---@param casterEntity Entity caster entity
---@param skillID number ID of an active skill which is **SkillTriggerType.San**
---@param context FeatureSanActiveSkillCanCastContext context with required arguments
---@return boolean
function FeatureServiceHelper.IsActiveSkillCanCast(casterEntity, skillID, context)
    local lsvcFeature = getLogicService()
    return lsvcFeature:IsActiveSkillCanCast(casterEntity, skillID, context)
end

---Check if player can cast one active skill based on Sanity(San) System
---=> FeatureServiceLogic:IsActiveSkillCanCast
---@param pstID number caster pet pstID
---@param skillID number ID of an active skill which is **SkillTriggerType.San**
---@param context FeatureSanActiveSkillCanCastContext context with required arguments
---@return boolean
function FeatureServiceHelper.IsActiveSkillCanCastByPstID(pstID, skillID, context)
    local lsvcFeature = getLogicService()
    ---@type Entity
    local eLocalTeam = lsvcFeature._world:Player():GetLocalTeamEntity()
    local cTeam = eLocalTeam:Team()
    local casterEntity = cTeam:GetPetEntityByPetPstID(pstID)
    return lsvcFeature:IsActiveSkillCanCast(casterEntity, skillID, context)
end

--取模块配置数据
function FeatureServiceHelper.GetFeatureData(featureType)
    local lsvcFeature = getLogicService()
    return lsvcFeature:GetFeatureData(featureType)
end

function FeatureServiceHelper.HasFeatureType(featureType)
    return getLogicService():HasFeatureType(featureType)
end
function FeatureServiceHelper.GetFeatureSkillHolderEntity(featureType)
    local lsvcFeature = getLogicService()
    if lsvcFeature then
        return lsvcFeature:GetFeatureSkillHolderEntity(featureType)
    end
    return nil
end
function FeatureServiceHelper.GetCards()
    local lsvcFeature = getLogicService()
    return lsvcFeature:GetCards()
end
function FeatureServiceHelper.CaclCardCompositionType(cardList)
    local lsvcFeature = getLogicService()
    return lsvcFeature:CaclCardCompositionType(cardList)
end
function FeatureServiceHelper.GetCurCardCount()
    local lsvcFeature = getLogicService()
    return lsvcFeature:GetCurCardCount()
end
function FeatureServiceHelper.CheckFeatureSkillCastCondition(featureType,skillID)
    local lsvcFeature = getLogicService()
    return lsvcFeature:CheckFeatureSkillCastCondition(featureType,skillID)
end
--region 阿克希亚-扫描模块-提供扫描结果
function FeatureServiceHelper.FeatureScanGetScanTrapIDList()
    ---@type FeatureServiceLogic
    local lsvcFeature = getLogicService()
    ---@type FeatureEffectParamScan
    local featureData = lsvcFeature:GetFeatureData(FeatureType.Scan)
    if not featureData then
        return {}
    end

    ---@type UtilDataServiceShare
    local utilData = getWorld():GetService("UtilData")
    if featureData:IsDiedTrapIncluded() then
        return utilData:ScanTrapInMatch()
    else
        return utilData:ScanTrapOnBoard()
    end
end

function FeatureServiceHelper.FeatureScanGetCurrentSelection()
    ---@type UtilDataServiceShare
    local utilData = getWorld():GetService("UtilData")
    return utilData:GetScanSelection()
end

function FeatureServiceHelper.FeatureScanIsPetHasFeatureScan(pstID)
    ---@type MainWorld
    local world = getWorld()
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    local eid = utilData:GetEntityIDByPstID(pstID)
    if eid <= 0 then
        return false
    end

    local e = world:GetEntityByID(eid)
    if (not e) or (not e:HasMatchPet()) then
        return false
    end

    ---@type MatchPet
    local matchPet = e:MatchPet():GetMatchPet()
    local featureList = matchPet:GetFeatureList() or {feature = {}}
    return (featureList.feature[FeatureType.Scan] ~= nil) -- 只需要bool结果，不返回原始配置内容，防修改
end
--endregion
