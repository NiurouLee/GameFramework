--[[------------------------------------------------------------------------------------------
    PreviewChainSelectPetComponent : 表现层 存储连线过程中选出战星灵的组件
]]--------------------------------------------------------------------------------------------

---@class PreviewChainSelectPetComponent: Object
_class( "PreviewChainSelectPetComponent", Object )

function PreviewChainSelectPetComponent:Constructor()
    ---以下分成多个数据结构，是因为顺序问题

    ---根据当前回合连线颜色匹配出来的星灵有序列表，此顺序按照服务器下发的对垒
    self._petList = {}

    ---每个星灵的范围结果
    ---@type SkillScopeResult[]
    self._petScopeResultDic = {}

    ---每个星灵的技能ID
    self._petSkillDic = {}
end

function PreviewChainSelectPetComponent:AddPreviewChainSelectPet(petEntityID)
    if not table.icontains(self._petList, petEntityID) then
        self._petList[#self._petList + 1] = petEntityID
    end
end

function PreviewChainSelectPetComponent:AddPreviewChainSelectPetScopeResult(petEntityID,scopeResult)
    self._petScopeResultDic[petEntityID] = scopeResult
end

function PreviewChainSelectPetComponent:AddPreviewChainSelectPetSkillID(petEntityID,skillID)
    self._petSkillDic[petEntityID] = skillID
end

function PreviewChainSelectPetComponent:GetRenderPetList()
    return self._petList
end

function PreviewChainSelectPetComponent:GetPreviewChainSelectPetScopeResult(petEntityID)
    return self._petScopeResultDic[petEntityID]
end

function PreviewChainSelectPetComponent:GetPreviewChainSelectPetSkillID(petEntityID)
    return self._petSkillDic[petEntityID]
end

function PreviewChainSelectPetComponent:ClearPreviewChainSelectPet()
    self._petList = {}
    self._petScopeResultDic = {}
end


-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function PreviewChainSelectPetComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function PreviewChainSelectPetComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return PreviewChainSelectPetComponent
function Entity:PreviewChainSelectPet()
    return self:GetComponent(self.WEComponentsEnum.PreviewChainSelectPet)
end


function Entity:HasPreviewChainSelectPet()
    return self:HasComponent(self.WEComponentsEnum.PreviewChainSelectPet)
end


function Entity:AddPreviewChainSelectPet()
    local index = self.WEComponentsEnum.PreviewChainSelectPet;
    local component = PreviewChainSelectPetComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplacePreviewChainSelectPet()
    local index = self.WEComponentsEnum.PreviewChainSelectPet;
    local component = PreviewChainSelectPetComponent:New()
    self:ReplaceComponent(index, component)
end


function Entity:RemovePreviewChainSelectPet()
    if self:HasPreviewChainSelectPet() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewChainSelectPet)
    end
end