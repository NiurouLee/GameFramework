--[[
    阵营组件
    阵营1，玩家：我方队伍、星灵、守护机关、我方机关，和阵营2互为敌方
    阵营2，怪物：pvp队伍、pvp星灵、怪、敌方机关，和阵营1互为敌方
    阵营3，善良：不可以被攻击，不可以攻击别人的单位，和所有阵营的单位互为友方
    阵营4，邪恶：不可以被攻击，可以攻击别人的单位，和所有阵营(不含3)互为敌方
    阵营5，天谴：不可以被攻击，可以攻击别人的单位，作为攻击者和所有阵营(不含3)互为敌方，作为被击者和所有阵营互为友方
]]

_class("AlignmentComponent",Object)
AlignmentComponent=AlignmentComponent

function AlignmentComponent:Constructor(type)
    self._alignmentType = type
end

function AlignmentComponent:GetAlignmentType()
    return self._alignmentType
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return AlignmentComponent
function Entity:Alignment()
    return self:GetComponent(self.WEComponentsEnum.Alignment)
end


function Entity:HasAlignment()
    return self:HasComponent(self.WEComponentsEnum.Alignment)
end


function Entity:AddAlignment(alignmentType)
    local index = self.WEComponentsEnum.Alignment;
    local component = AlignmentComponent:New(alignmentType)
    self:AddComponent(index, component)
end


function Entity:ReplaceAlignment(alignmentType)
    local index = self.WEComponentsEnum.Alignment;
    local component = AlignmentComponent:New(alignmentType)
    self:ReplaceComponent(index, component)
end


function Entity:RemoveAlignment()
    if self:HasAlignment() then
        self:RemoveComponent(self.WEComponentsEnum.Alignment)
    end
end