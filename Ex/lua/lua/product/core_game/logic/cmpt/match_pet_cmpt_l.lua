--[[------------------------------------------------------------------------------------------
    MatchPetComponent : 星灵数据组件
]] --------------------------------------------------------------------------------------------

---@class MatchPetComponent: Object
_class("MatchPetComponent", Object)
MatchPetComponent=MatchPetComponent

function MatchPetComponent:Constructor(matchPet)
    self._matchPet = matchPet
end 

function MatchPetComponent:GetMatchPet()
    return self._matchPet
end

---@return MatchPetComponent
function Entity:MatchPet()
    return self:GetComponent(self.WEComponentsEnum.MatchPet)
end

function Entity:HasMatchPet()
    return self:HasComponent(self.WEComponentsEnum.MatchPet)
end

function Entity:AddMatchPet(matchPet)
    local index = self.WEComponentsEnum.MatchPet
    local component = MatchPetComponent:New(matchPet)
    self:AddComponent(index, component)
end

function Entity:ReplaceMatchPet(matchPet)
    local index = self.WEComponentsEnum.MatchPet
    local component = MatchPetComponent:New(matchPet)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveMatchPet()
    if self:HasMatchPet() then
        self:RemoveComponent(self.WEComponentsEnum.MatchPet)
    end
end
