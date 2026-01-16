--[[------------------------------------------------------------------------------------------
    AIRecorderComponent : 
    记录AI行为全局信息的组件。
    AI个体的行为存储在各个Entity自己身上。
    AI的普攻技能，是同时执行，所以没有顺序要求。技能的施法都是顺序执行，所以需要记录计算时的顺序
]] --------------------------------------------------------------------------------------------


_class("AIRecorderComponent", Object)
---@class AIRecorderComponent: Object
AIRecorderComponent = AIRecorderComponent

function AIRecorderComponent:Constructor()
    --entityID:AIResultCollection
    self._aiResultCollectionDict = nil
    self._aiCastSkillSequece = nil
    self._aiWalkSequence = nil
    self._orderResultList = {}
    self._orderCastSkillSequence = {}
    self._orderWalkSequence={}

    ---一些需求里面要求ai在播放技能结果时要并行播放。
    ---key是并行播放的组号，每一组都并行播放。
    ---都播放完毕再播放下一个
    self._parallelPlayResultCollectionDict =nil
end

function AIRecorderComponent:ClearAIRecorder()
    self._aiResultCollectionDict = nil
    self._aiCastSkillSequece = nil
    self._aiWalkSequence = nil
    self._orderResultList = {}
    self._orderCastSkillSequence = {}
    self._orderWalkSequence={}

end

--添加一个order则新增数据放在新的order中
function AIRecorderComponent:AddOrderResult(order)
    local res = self._orderResultList[order]
    if res then
        --Log.error("AddOrderResult() error! order exist! order=", order)
        return
    end
    self._orderResultList[order] = {}
    self._orderCastSkillSequence[order] = {}
    self._orderWalkSequence[order] = {}
    self._aiResultCollectionDict = self._orderResultList[order]
    self._aiCastSkillSequece = self._orderCastSkillSequence[order]
    self._aiWalkSequence = self._orderWalkSequence[order]
end

function AIRecorderComponent:AddWalkResult(casterEntityID, aiResult)
    if not table.icontains(self._aiWalkSequence, casterEntityID) then
        table.insert(self._aiWalkSequence, casterEntityID)
    end
    ---@type AIResultCollection
    local collection = self._aiResultCollectionDict[casterEntityID]
    if not collection then
        collection = AIResultCollection:New()
        self._aiResultCollectionDict[casterEntityID] = collection
    end
    collection:AddWalkResult(aiResult)
end

function AIRecorderComponent:AddNormalAttackResult(casterEntityID, aiResult)
    if not table.icontains(self._aiWalkSequence, casterEntityID) then
        table.insert(self._aiWalkSequence, casterEntityID)
    end
    ---@type AIResultCollection
    local collection = self._aiResultCollectionDict[casterEntityID]
    if not collection then
        collection = AIResultCollection:New()
        self._aiResultCollectionDict[casterEntityID] = collection
    end
    collection:AddNormalAttackResult(aiResult)
end

function AIRecorderComponent:GetAISpellResultByCasterEntityID(casterEntityID)
    ---@type AISkillResult[]
    local ret = {}
    for order, aiCastSkillQueue in pairs(self._orderResultList) do
        local collection = aiCastSkillQueue[casterEntityID]
        if collection then
            ---@type AISkillResult[]
            local aiResultList = collection:GetSpellResultList()
            table.appendArray(ret,aiResultList)
        end
    end
    return ret
end

---@return table<number,AISkillResult[]>
function AIRecorderComponent:GetAllParallelSpellResultList()
    ----@type table<number,table<number,AISkillResult[]>>
    local ret = {}
    for order, aiCastSkillQueue in pairs(self._orderResultList) do
        for k, collection in pairs(aiCastSkillQueue) do
            ---@type AISkillResult[]
            local aiResultList = collection:GetSpellResultList()
            for _, aiResult in ipairs(aiResultList) do
                local parallelID = aiResult:GetParallelID()
                if parallelID then
                    if not ret[parallelID] then
                        ret[parallelID] = {}
                    end
                    local casterID = aiResult:GetCasterEntityID()
                    if not ret[parallelID][casterID] then
                        ret[parallelID][casterID] = {}
                    end

                    table.insert(ret[parallelID][casterID],aiResult)
                end
            end
        end
    end
    return ret
end

function AIRecorderComponent:AddSpellResult(casterEntityID, aiResult)
    if not table.icontains(self._aiCastSkillSequece, casterEntityID) then
        table.insert(self._aiCastSkillSequece, casterEntityID)
    end
    ---@type AIResultCollection
    local collection = self._aiResultCollectionDict[casterEntityID]
    if not collection then
        collection = AIResultCollection:New()
        self._aiResultCollectionDict[casterEntityID] = collection
    end
    collection:AddSpellResult(aiResult)
end

--获取数据需要先拿到order列表
function AIRecorderComponent:GetOrderList()
    local list = {}
    for order, res in pairs(self._orderResultList) do
        list[#list + 1] = order
    end
    table.sort(list)
    return list
end

--获取数据前先设置order
function AIRecorderComponent:SetCurrentOrder(order)
    self._aiResultCollectionDict = self._orderResultList[order]
    self._aiCastSkillSequece = self._orderCastSkillSequence[order]
    self._aiWalkSequence=self._orderWalkSequence[order]
end

--获取一次order结果包含的entityID列表
function AIRecorderComponent:GetAICasterIDList()
    return self._aiCastSkillSequece or {}
end

function AIRecorderComponent:GetAIWalkerIDList()
    return self._aiWalkSequence or {}
end


--获取一个entity的ai结果
function AIRecorderComponent:GetAIResultCollection(casterEntityID)
    return self._aiResultCollectionDict[casterEntityID]
end

---@return AIRecorderComponent
function Entity:AIRecorder()
    return self:GetComponent(self.WEComponentsEnum.AIRecorder)
end

function Entity:HasAIRecorder()
    return self:HasComponent(self.WEComponentsEnum.AIRecorder)
end

function Entity:AddAIRecorder()
    local index = self.WEComponentsEnum.AIRecorder
    local component = AIRecorderComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceAIRecorder(component)
    local index = self.WEComponentsEnum.AIRecorder
    if not component then
        component = AIRecorderComponent:New()
    end
    self:ReplaceComponent(index, component)
end

function Entity:RemoveAIRecorder()
    if self:HasAIRecorder() then
        self:RemoveComponent(self.WEComponentsEnum.AIRecorder)
    end
end
