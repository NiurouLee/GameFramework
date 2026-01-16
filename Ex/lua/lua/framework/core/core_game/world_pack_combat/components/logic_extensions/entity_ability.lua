--[[******************************************************************************************
    Ability Extensions ：

    什么是Ability？ 
    1、能力可以看做是一个业务概念的实现、以及控制开关
    2、操作Entity上一组协同完成功能的Components， 隐藏其中的特化细节、隐秘约定、各种不可爱的脏活。
    3、Entity其 Components 的设计视角可能并不是纯粹面向业务概念的, 而 Ability 是纯以业务视角来设计的。

--******************************************************************************************]] --
require "abilities_component"
--不要在这里添加 AbilityType, 搜一下有扩展AbilityType的示例
---@class EntityAbilitysLookup
_enum(
    "EntityAbilitysLookup",
    {
        Invalid = 0
    }
) ---@class EntityAbility:IEntityAbility
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    EntityAbility基类
]] _class(
    "EntityAbility",
    IEntityAbility
)

function EntityAbility:Constructor()
    self.m_abilityType = EntityAbilitysLookup.Invalid
end

---@param owner Entity
function EntityAbility:Initialize(owner)
    self.m_owner = owner
    self.m_is_enable = true
    self:OnEnable()
end

function EntityAbility:GetAbilityType()
    return self.m_abilityType
end

function EntityAbility:IsEnable()
    return self.m_is_enable
end

function EntityAbility:SetEnable()
    if self.m_is_enable == true then
        return
    end
    self.m_is_enable = true
    self:OnEnable()
end

function EntityAbility:SetDisable()
    if self.m_is_enable == false then
        return
    end
    self.m_is_enable = false
    self:OnDisable()
end

function EntityAbility:Reset()
    self.m_is_enable = true
end

function EntityAbility:OnEnable()
end

function EntityAbility:OnDisable()
end
