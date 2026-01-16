_class("SkillPreviewContext", Object)
---@class SkillPreviewContext: Object
SkillPreviewContext = SkillPreviewContext

function SkillPreviewContext:Constructor(world, casterEntity)
    ---@type MainWorld
    self._world = world

    ---施法者
    self._casterEntity = casterEntity

    self._scopeResult = nil
    self._scopeGridList = nil

    self._needBreak = false

    self._effectList = {}

    self._targetEntityIDList = {}

    self._hitBackDirType = nil

    self._casterDir = casterEntity:GridLocation().Direction

    self._casterPos = casterEntity:GridLocation().Position

    self._casterBodyArea = casterEntity:BodyArea()

    self._ignorePlayerBlock = false

    self._previewIndex = 0

    ---@type Vector2
    self._pickUpPos = nil

    self._scopeType = SkillScopeType.None

    ---@type table<number,Vector2[]>
    self._effectScopeList = {}
    ---@type table<number,SkillEffectParamBase>
    self._effectParamList = {}

    self._rotateGhost = nil
    ---@type Vector2[]
    self._scopeCenterPosList= {}
end

function SkillPreviewContext:SetEffectList(effectList)
    self._effectList = effectList
end

function SkillPreviewContext:GetEffect(previewEffectType)
    local retResultList = {}
    for k, v in pairs(self._effectList) do
        if v.effectType == previewEffectType then
            return v
        end
    end
end
function SkillPreviewContext:GetEffectsByType(previewEffectType)
    local retResultList = {}
    for k, v in ipairs(self._effectList) do
        if v.effectType == previewEffectType then
            table.insert(retResultList,v)
        end
    end
    return retResultList
end

----只用于Wait指令使用
function SkillPreviewContext:IsNeedBreak()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    local nowPreviewIndex = previewActiveSkillService:GetPreviewIndex()
    ---同时判断一行指令流内部打断和外部打断
    return self._needBreak or (nowPreviewIndex ~= self:_GetPreviewIndex())
end
---只用于Break指令使用
---@param needBreak boolean
function SkillPreviewContext:SetBreakState(needBreak)
    self._needBreak = needBreak
end

---@param scopeResult Vector2[] 即attackRange
---@return boolean
function SkillPreviewContext:SetScopeResult(scopeResult)
    self._scopeResult = scopeResult
end

----@return Vector2[]
function SkillPreviewContext:GetScopeResult(effectType)
    --if effectType then
    --	if self._effectScopeList[effectType] then
    --		local retScopeResult =self._effectScopeList[effectType]
    --		return retScopeResult
    --	end
    --end
    return self._scopeResult
end

function SkillPreviewContext:SetEffectParam(effectType, effectParam)
    self._effectParamList[effectType] = effectParam
end
---TODO没调用？
function SkillPreviewContext:GetEffectParam(effectType)
    return self._effectParamList[effectType]
end

--function SkillPreviewContext:SetEffectScopeResult(effectType,scopeResult)
--	self._effectScopeList[effectType] = scopeResult
--end

function SkillPreviewContext:SetTargetEntityIDList(list)
    self._targetEntityIDList = list
end
---@return number[]
function SkillPreviewContext:GetTargetEntityIDList(effectType)
    return self._targetEntityIDList
end
---@return MainWorld
function SkillPreviewContext:GetWorld()
    return self._world
end

function SkillPreviewContext:SetCasterDir(dir)
    self._casterDir = dir
end

function SkillPreviewContext:GetCasterDir()
    return self._casterDir
end

function SkillPreviewContext:SetCasterPos(pos)
    self._casterPos = pos
end
---@return Vector2
function SkillPreviewContext:GetCasterPos()
    return self._casterPos
end
---@return boolean
function SkillPreviewContext:IsIgnorePlayerBlock()
    return self._ignorePlayerBlock
end

function SkillPreviewContext:SetIgnorePlayerBlockState(state)
    self._ignorePlayerBlock = state
end

function SkillPreviewContext:GetCasterBodyArea()
    return self._casterBodyArea
end
---@return HitBackDirectionType
function SkillPreviewContext:GetHitBackDirType()
    return self._hitBackDirType
end
---@param dirType HitBackDirectionType
function SkillPreviewContext:SetHitBackDirType(dirType)
    self._hitBackDirType = dirType
end

function SkillPreviewContext:SetPreviewIndex(index)
    self._previewIndex = index
end

function SkillPreviewContext:_GetPreviewIndex()
    return self._previewIndex
end

function SkillPreviewContext:SetPickUpPos(pos)
    self._pickUpPos = pos
end

function SkillPreviewContext:GetPickUpPos()
    return self._pickUpPos
end

--region 技能范围类型
function SkillPreviewContext:SetScopeType(scopeType)
    self._scopeType = scopeType
end
---@return SkillScopeType
function SkillPreviewContext:GetScopeType()
    return self._scopeType
end
--endregion

function SkillPreviewContext:SetConfigData(configData)
    self._configData = configData
end

function SkillPreviewContext:GetConfigData()
    return self._configData
end

function SkillPreviewContext:SetScopeCenterPos(posList)
    if posList._className then
        self._scopeCenterPosList = { posList }
    else
        self._scopeCenterPosList =  posList
    end
end

function SkillPreviewContext:GetScopeCenterPosList()
    return self._scopeCenterPosList
end