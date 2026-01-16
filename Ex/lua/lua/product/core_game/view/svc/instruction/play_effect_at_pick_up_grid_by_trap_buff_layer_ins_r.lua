require("base_ins_r")
---根据点击位置的机关指定buff层数播不同特效 菲雅
---@class PlayEffectAtPickUpGridByTrapBuffLayerInstruction: BaseInstruction
_class("PlayEffectAtPickUpGridByTrapBuffLayerInstruction", BaseInstruction)
PlayEffectAtPickUpGridByTrapBuffLayerInstruction = PlayEffectAtPickUpGridByTrapBuffLayerInstruction

function PlayEffectAtPickUpGridByTrapBuffLayerInstruction:Constructor(paramList)
    self._pickUpIndex = tonumber(paramList["pickUpIndex"]) or 1
    self._trapIDList = {}
    local trapList = paramList["trapIDList"]
    if trapList then
        local arr = string.split(trapList, "|")
        for i,v in ipairs(arr) do
            table.insert(self._trapIDList,tonumber(v))
        end
    end
    self._effectIDDic = {}
    local effList = paramList["effectIDList"]
    if effList then
        local arr = string.split(effList, "|")
        for k,effectID in ipairs(arr) do
            self._effectIDDic[k] = tonumber(effectID)
        end
    end
    self._effectScaleDic = {}
    local effScaleList = paramList["effectScaleList"]
    if effScaleList then
        local arr = string.split(effScaleList, "|")
        for k,scale in ipairs(arr) do
            self._effectScaleDic[k] = tonumber(scale)
        end
    end
    self._checkBuffEffectType = tonumber(paramList.checkBuffEffectType)
    self._dirX = 0
    self._dirY = 1
    if paramList["dirX"] then
        self._dirX = tonumber(paramList["dirX"])
    end
    if paramList["dirY"] then
        self._dirY = tonumber(paramList["dirY"])
    end
end

---@param casterEntity Entity
function PlayEffectAtPickUpGridByTrapBuffLayerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local oriEntity = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        oriEntity = cSuperEntity:GetSuperEntity()
    end

    ---@type MainWorld
    local world = oriEntity:GetOwnerWorld()
    ---@type EffectService
    local sEffect = world:GetService("Effect")
    local dir = Vector2(self._dirX, self._dirY)

    ---@type RenderPickUpComponent
    local renderPickUpComponent = oriEntity:RenderPickUpComponent()
    if not renderPickUpComponent then
        return
    end
    local effectID = 0
    local effScale = 1
    local tarBuffLayer = 0
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer then 
        ---@type SkillEffectPickUpTrapAndBuffDamageResult[]
        local pickUpTrapAndBuffDamageResultArray =
            skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PickUpTrapAndBuffDamage)
        if pickUpTrapAndBuffDamageResultArray and #pickUpTrapAndBuffDamageResultArray > 0 then
            ---@type SkillEffectPickUpTrapAndBuffDamageResult
            local effResult = pickUpTrapAndBuffDamageResultArray[1]
            tarBuffLayer = effResult:GetTarBuffLayer()
        end
    end
    local buffLayer = tarBuffLayer
    local effCount = #self._effectIDDic
    effectID = self._effectIDDic[buffLayer]
    if not effectID then
        if effCount > 0 then
            effectID = self._effectIDDic[effCount]
        end
    end
    effScale = self._effectScaleDic[buffLayer]
    if not effScale then
        if #self._effectScaleDic > 0 then
            effScale = self._effectScaleDic[#self._effectScaleDic]
        end
    end
    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local pickUpPos = pickUpGridArray[self._pickUpIndex]

    ---逻辑上删掉的机关取不到，改为了使用技能效果结果来传递点击的机关buff层数
    -- local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    -- local pickUpPos = pickUpGridArray[self._pickUpIndex]
    -- ---@type UtilDataServiceShare
    -- local utilSvc = world:GetService("UtilData")
    -- local traps = {}
    -- local array = utilSvc:GetTrapsAtPos(pickUpPos)
    -- for _, e in ipairs(array) do
    --     local isOwner = false
    --     if e:HasSummoner() then
    --         if e:Summoner():GetSummonerEntityID() == casterEntity:GetID() then
    --             isOwner = true
    --         end
    --     else
    --         isOwner = true
    --     end
    --     if isOwner and e:TrapRender() and not e:HasDeadMark() and table.icontains( self._trapIDList,e:TrapRender():GetTrapID()) then
    --         local entityID = e:GetID()
    --         table.insert(traps, e)
    --     end
    -- end
    -- if #traps > 0 then
    --     local trap = traps[1]
    --     ---@type UtilDataServiceShare
    --     local utilDataSvc = world:GetService("UtilData")
    --     local buffLayer = utilDataSvc:GetBuffLayer(trap, self._checkBuffEffectType)
    --     local effCount = #self._effectIDDic
    --     effectID = self._effectIDDic[buffLayer]
    --     if not effectID then
    --         if effCount > 0 then
    --             effectID = self._effectIDDic[effCount]
    --         end
    --     end
    --     effScale = self._effectScaleDic[buffLayer]
    --     if not effScale then
    --         if #self._effectScaleDic > 0 then
    --             effScale = self._effectScaleDic[#self._effectScaleDic]
    --         end
    --     end
    -- end
    if effectID and (effectID > 0) then
        local effectEntity = sEffect:CreateWorldPositionDirectionEffect(effectID, pickUpPos, dir)
        if effScale and effScale ~= 1 then
            YIELD(TT)
            ---@type UnityEngine.Transform
            local effObject = effectEntity:View():GetGameObject()
            local transWork = effObject.transform
            local scaleData = Vector3.New(effScale, effScale, effScale)
            ---@type DG.Tweening.Sequence
            local sequence = transWork:DOScale(scaleData, 0)
        end
    end
end

function PlayEffectAtPickUpGridByTrapBuffLayerInstruction:GetCacheResource()
    local res = {}
    for i,effectID in pairs(self._effectIDDic) do
        local effRes = {Cfg.cfg_effect[effectID].ResPath, 1}
        table.insert(res,effRes)
    end
    return res
end
