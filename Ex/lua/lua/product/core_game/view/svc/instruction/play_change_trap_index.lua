require("base_ins_r")

---@class PlayChangeTrapIndexInstruction: BaseInstruction
_class("PlayChangeTrapIndexInstruction", BaseInstruction)
PlayChangeTrapIndexInstruction = PlayChangeTrapIndexInstruction

function PlayChangeTrapIndexInstruction:Constructor(paramList)
    local str  =paramList.trapIDList
    local sp = string.split(str,"|")
    self._trapID = {}
    for i, trapID in ipairs(sp) do
        table.insert(self._trapID, tonumber(trapID))
    end
    str = paramList.indexPrefabList
    self._indexPrefabList = string.split(str,"|")
end
function PlayChangeTrapIndexInstruction:GetCacheResource()
    local t = {}
    for i, resPath in ipairs(self._indexPrefabList) do
        table.insert(t, {resPath, 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayChangeTrapIndexInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()
    ---@type Entity[]
    local allTrapEntity =  self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    ---@type Entity[]
    local choseEntity = {}
    for i, trapEntity in ipairs(allTrapEntity) do
        if not trapEntity:HasDeadMark() then
            ---@type TrapRenderComponent
            local trapRenderCmpt = trapEntity:TrapRender()
            local trapID = trapRenderCmpt:GetTrapID()
            if table.icontains(self._trapID,trapID) then
                table.insert(choseEntity,trapEntity)
            end

        end
    end
    local sortFunc =function(trapA,trapB)
        ---@type TrapRenderComponent
        local trapARenderCmpt = trapA:TrapRender()
        ---@type TrapRenderComponent
        local trapBRenderCmpt = trapB:TrapRender()
        local roundA = trapARenderCmpt:GetTrapBornRound()
        local roundB = trapBRenderCmpt:GetTrapBornRound()
        return trapA:GetID()>trapB:GetID()
    end
    table.sort(choseEntity,sortFunc)
    for i, entity in ipairs(choseEntity) do
        local prefab =self._indexPrefabList[i]
        if not self._indexPrefabList[i] then
            prefab = self._indexPrefabList[#self._indexPrefabList]
        end
        entity:ReplaceAsset(NativeUnityPrefabAsset:New(prefab, true))
    end
end