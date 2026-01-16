local TrailLevelLayerType = {
    Normal = 0, --普通关卡
    Final = 1, --终章
}
---@class TrailLevelLayerType:TrailLevelLayerType
_enum("TrailLevelLayerType", TrailLevelLayerType)


_class("UITrailLevelLayerData", Object)
---@class UITrailLevelLayerData:Object
UITrailLevelLayerData = UITrailLevelLayerData

function UITrailLevelLayerData:Constructor(cfg)
    self._layerId = cfg.ID
    self._layerName = StringTable.Get(cfg.LayerName)
    self._layerType = cfg.LayerType
    self._layerIcon = cfg.LayerIcon
    local levelCfgs = Cfg.cfg_tale_stage{ Type = 2, Tier = self._layerId }
    self._levelDatas = {}
    if levelCfgs then
        for i = 1, #levelCfgs do
            local data = UITrailLevelData:New(levelCfgs[i])
            self._levelDatas[#self._levelDatas + 1] = data
        end
    end
end

function UITrailLevelLayerData:GetLayerId()
    return self._layerId
end

function UITrailLevelLayerData:GetLayerName()
    return self._layerName
end

function UITrailLevelLayerData:GetLayerIcon()
    return self._layerIcon
end

function UITrailLevelLayerData:GetLayerType()
    return self._layerType
end

function UITrailLevelLayerData:GetLevelDatas()
    return self._levelDatas
end

_class("UITrailLevelData", Object)
---@class UITrailLevelData:Object
UITrailLevelData = UITrailLevelData

function UITrailLevelData:Constructor(cfg)
    ---@type TalePetModule
    local talePetModule = GameGlobal.GetModule(TalePetModule)
    self._id = cfg.ID
    self._type = cfg.Type
    ---@type TrailLevelLayerType
    self._levelLayer = cfg.Tier
    self._fightLevelId = cfg.FightLevelid
    self._firstDropId = cfg.FirstDropId
    self._levelBg = cfg.LevelBg
    self._icon = cfg.Icon
    self._name = StringTable.Get(cfg.Name)
    self._elementIcon1 = cfg.ElementIcon1
    self._elementIcon2 = cfg.ElementIcon2
    self._hasComplete = talePetModule:HasCompletLevel(self._id)
end

function UITrailLevelData:GetId()
    return self._id
end

--关卡类型1为练习关卡，2为试炼关卡
function UITrailLevelData:GetType()
    return self._type
end

--关卡层级类型
function UITrailLevelData:GetLevelLayer()
    return self._levelLayer
end

--战斗关卡Id
function UITrailLevelData:GetFightLevelId()
    return self._fightLevelId
end

--首次通关奖励
function UITrailLevelData:GetFirstDropId()
    return self._firstDropId
end

--关卡背景
function UITrailLevelData:GetLevelBg()
    return self._levelBg
end

--关卡图标
function UITrailLevelData:GetIcon()
    return self._icon
end

--关卡名字
function UITrailLevelData:GetName()
    return self._name
end

--属性图标1
function UITrailLevelData:GetElementIcon1()
    return self._elementIcon1
end

--属性图标2
function UITrailLevelData:GetElementIcon2()
    return self._elementIcon2
end

--是否通关
function UITrailLevelData:IsComplete()
    return self._hasComplete
end
