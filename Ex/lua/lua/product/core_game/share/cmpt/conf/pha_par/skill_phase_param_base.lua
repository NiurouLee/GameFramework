--解析技能表现参数的基类
---@class SkillPhaseParamBase: Object
_class("SkillPhaseParamBase", Object)
SkillPhaseParamBase = SkillPhaseParamBase

--用table构造参数
function SkillPhaseParamBase:Constructor(t)
    if t then
        self._hitTurnToTarget = t.hitTurnToTarget
    end
end

--获取需要缓存的prefab
---@param skillConfig SkillConfigData
function SkillPhaseParamBase:GetCacheTable(skillConfig,skinId)
    Log.fatal(self._className .. " not implicate GetCacheTable() !!!")
end

function SkillPhaseParamBase:GetSoundCacheTable()
    return nil
end

function SkillPhaseParamBase:GetVoiceCacheTable()
    return nil
end

function SkillPhaseParamBase:HitTurnToTarget()
    return self._hitTurnToTarget
end

---2019-12-30 韩玉信添加
---@param listID number[]	特效ID数组
---把nEffectID添加如listID数组
function SkillPhaseParamBase:AddEffectIDToListID(listID, nEffectID)
    if nEffectID and nEffectID > 0 then
        listID[#listID + 1] = nEffectID
    end
end

---@param listID number[]	特效ID数组
function SkillPhaseParamBase:GetCacheTableFromListID(listID)
    local t = {}
    local nMaxCount = table.count(listID)
    for i = 1, nMaxCount do
        local nEffectID = listID[i]
        if nEffectID and nEffectID > 0 then
            t[#t + 1] = {Cfg.cfg_effect[nEffectID].ResPath, 1}
        end
    end
    return t
end

function SkillPhaseParamBase:GenerateCacheTableElementByID(effectID, cacheCount)
    cacheCount = cacheCount or 1
    -- 资源ID可能不是必须的，所以没有参数可以不报错
    if "number" ~= type(effectID) then
        return nil
    end

    local cfg = Cfg.cfg_effect[effectID]
    if not cfg then
        -- 但是配了又找不到，这就应该明确报错了
        Log.exception(self._className, "找不到特效：", tostring(effectID), "\n", Log.traceback())
        return
    end

    return {cfg.ResPath, cacheCount}
end
----------------------------------------------------------------
function SkillPhaseParamBase:_TransID(nID)
    local listID = {}
    if type(nID) == "table" then
        listID = nID
    else
        if nID then
            table.insert(listID, nID )
        end
    end
    return listID
end

---计算范围内的格子数量，目前是给cache资源统计数量使用
---@param scopeType SkillScopeType
function SkillPhaseParamBase:_CalcScopeRangeGridNum(scopeType,scopeParam)
    ---默认返回的是1个
    local gridNum = 1
    if scopeType == SkillScopeType.NRowsMColumns then 
        ---@type SkillNRowsMColumnsScopeParam
        local skillNRowsMColumnsScopeParam = scopeParam
        local columns = skillNRowsMColumnsScopeParam:GetSkillScopeColumns()
        local rows = skillNRowsMColumnsScopeParam:GetSkillScopeRows()
        local yMoveCount = math.floor((rows - 1) / 2 + 0.5)
        local xMoveCount = math.floor((columns - 1) / 2 + 0.5)
        
        ---临时写死，只能最大是9
        local yNum = yMoveCount * 2 + 1
        if yNum > 9 then 
            yNum = 9
        end

        local xNum = xMoveCount * 2 + 1
        if xNum > 9 then 
            xNum = 9
        end 

        gridNum = xNum * yNum 
    else
    end

    return gridNum
end

function SkillPhaseParamBase:GetEffectResCacheInfo(effectID, count)
    count = count or 1

    if not effectID then
        return nil
    end

    if not Cfg.cfg_effect[effectID] then
        Log.exception(self._className, "effectID not found: ", tostring(effectID))
        return nil
    end

    local resPath = Cfg.cfg_effect[effectID].ResPath
    if not ResourceManager:GetInstance():HasResource(resPath) then
        Log.exception(self._className, "res not found: ", tostring(resPath))
        return nil
    end

    return {resPath, count}
end
