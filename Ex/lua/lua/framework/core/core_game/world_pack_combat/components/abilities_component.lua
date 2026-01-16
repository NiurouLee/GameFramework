
--[[******************************************************************************************
    AbilitiesComponent ：

    什么是Ability？ 
    1、能力可以看做是一个业务概念的实现、以及控制开关。 
    2、操作Entity上一组协同完成功能的Components， 隐藏其中的特化细节、隐秘约定、各种不可爱的脏活。
    3、Entity其 Components 的设计视角可能并不是纯粹面向业务概念的, 而 Ability 是纯以业务视角来设计的。

    一些问答：
    Q：什么业务适合以Ability的方式组织？ 它和 Component+System 有啥区别？
    A：首先一般我们不会通过Ability来分组entity， 比如一般不会有 "找到所有拥有加速跑能力的entity" 这种需要。
       其次Ability一般是一个策划向的上层业务概念，加速跑能力（FPS游戏中的shift、主机动作游戏中的R2键）
       Ability 可能依赖一系列Animat、FSM、Movement 组件系统的支持实现功能。也可能生写一堆特别神的代码。
       但有Ability之后，我们写上层业务代码的时候不再关心底层支持的组件系统，只用放心的开关Ability就行。

--******************************************************************************************]]--


---@class IEntityAbility:Object
_class( "IEntityAbility", Object )
IEntityAbility = IEntityAbility

function IEntityAbility:Initialize(owner) end

function IEntityAbility:GetAbilityType() end

function IEntityAbility:IsEnable() end

function IEntityAbility:SetEnable() end

function IEntityAbility:SetDisable() end


--[[------------------------------------------------------------------------------------------
    AbilitiesComponent
]]--------------------------------------------------------------------------------------------

---@class AbilitiesComponent:Object
_class( "AbilitiesComponent", Object )
AbilitiesComponent = AbilitiesComponent


function AbilitiesComponent:Constructor()
    ---@type SortedDictionary
    self.abilities = SortedDictionary:New()
end


-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////
---@param owner Entity
function AbilitiesComponent:WEC_PostInitialize(owner)
    self.WEC_OwnerEntity = owner
end


function AbilitiesComponent:WEC_PostRemoved()
    local abilities = self.abilities
    for i = 1, abilities:Size() do
        abilities:GetAt(i):OnDisable()
    end
    abilities:Clear()
    self.abilities = nil
    self.WEC_OwnerEntity = nil
end

-- This:
--//////////////////////////////////////////////////////////
---@param ability IEntityAbility
function AbilitiesComponent:AddAbility(ability)
    ability:Initialize(self.WEC_OwnerEntity)
    local abilityType = ability:GetAbilityType()
    self.abilities:Insert(abilityType, ability)
end

function AbilitiesComponent:RemoveAbility(abilityType)
    self.abilities:Remove(abilityType)
end

---@return IEntityAbility
function AbilitiesComponent:GetAbility(abilityType)
    return self.abilities:Find(abilityType)
end

function AbilitiesComponent:HandleCommand(cmd) 
    local abilities = self.abilities
    for i = 1, abilities:Size() do
        local ability = abilities:GetAt(i)
        if ability:IsEnable() and ability.HandleCommand then
            ability:HandleCommand(cmd) 
        end
    end
end


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return AbilitiesComponent
function Entity:Abilities()
    return self:GetComponent(self.WEComponentsEnum.Abilities)
end

function Entity:HasAbilities()
    return self:HasComponent(self.WEComponentsEnum.Abilities)
end


function Entity:AddAbility(ability)
    if not self:HasAbilities() then
        local index = self.WEComponentsEnum.Abilities;
        local component = AbilitiesComponent:New()
        self:AddComponent(index, component);
    end
    self:Abilities():AddAbility(ability)
end

function Entity:RemoveAbility(abilityType)
    local abilities = self:Abilities()
    if abilities then
        abilities:RemoveAbility(abilityType)
    end
end

function Entity:GetAbility(abilityType)
    local abilities = self:Abilities()
    if abilities then
        return abilities:GetAbility(abilityType)
    end
end

function Entity:EnableAbility(abilityType)
    local ability = self:GetAbility(abilityType)
    if ability then
        return ability:SetEnable()
    end
end

function Entity:DisableAbility(abilityType)
    local ability = self:GetAbility(abilityType)
    if ability then
        return ability:SetDisable()
    end
end

function Entity:RemoveAbilities()
    if self:HasAbilities() then
        self:RemoveComponent(self.WEComponentsEnum.Abilities)
    end
end