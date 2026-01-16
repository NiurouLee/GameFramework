_class("UIActivityN21CCAffixData", Object)
---@class UIActivityN21CCAffixData:Object
UIActivityN21CCAffixData = UIActivityN21CCAffixData

function UIActivityN21CCAffixData:Constructor(config, isSelected, affixGroupData)
    ---@type UIActivityN21CCAffixGroupsData
    self._affixGroupData = affixGroupData 
    self._missionAffixId = config.ID
    local id = config.AffixID
    local score = config.AffixScore
    self._unlockScore = config.UnLockScore
    local cfgs = Cfg.cfg_affix {ID = id}
    if cfgs == nil or #cfgs <= 0 then
        return
    end
    local cfg = cfgs[1]
    self._id = id
    self._type = cfg.Type
    self._categoryType =  config.GainType
    local paramsCfg = cfg.EntryParam
    local params = {}
    if paramsCfg and paramsCfg[1] then
        local p = paramsCfg[1]
        for k, v in ipairs(p) do
            if type(v) == "string" then
                params[#params + 1] = StringTable.Get(v)
            elseif type(v) == "number" then
                params[#params + 1] = v
            end
        end
    end
    self._des = StringTable.Get(cfg.Desc, table.unpack(params))
    self._score = score
    self._level = cfg.Level
    self._isSelected = isSelected
end

function UIActivityN21CCAffixData:GetAffixGroupData()
    return self._affixGroupData
end

--关卡词条id
function UIActivityN21CCAffixData:GetMissionAffixId()
    return self._missionAffixId
end

--词条Id
function UIActivityN21CCAffixData:GetId()
    return self._id
end

--词条等级
function UIActivityN21CCAffixData:GetLevel()
    return self._level
end

--词条类型
function UIActivityN21CCAffixData:GetType()
    return self._type
end

--词条分类类型
function UIActivityN21CCAffixData:GetCategoryType()
    return self._categoryType
end

--词条描述
function UIActivityN21CCAffixData:GetDes()
    return self._des
end

--词条积分
function UIActivityN21CCAffixData:GetScroe()
    return self._score
end

--是否选中
function UIActivityN21CCAffixData:IsSelected()
    return self._isSelected
end

--设置选中状态
function UIActivityN21CCAffixData:SetSelectStatus(status)
    self._isSelected = status
end

function UIActivityN21CCAffixData:GetUnlockScore()
    return self._unlockScore
end
