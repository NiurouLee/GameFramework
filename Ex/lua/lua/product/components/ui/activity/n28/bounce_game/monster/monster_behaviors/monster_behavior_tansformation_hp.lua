require "monster_behavior_base"

--怪物行为组件-血量改变，修改形状
---@class MonsterBeHaviorTransformationWithHp : MonsterBeHaviorBase
_class("MonsterBeHaviorTransformationWithHp", MonsterBeHaviorBase)
MonsterBeHaviorTransformationWithHp = MonsterBeHaviorTransformationWithHp

function MonsterBeHaviorTransformationWithHp:Constructor()
    --说明sharps是数组{[1] ={HP = 1, ResId = 1111}, [2] ={HP = 1, ResId = 1111} }
    self._sharps = nil
end

function MonsterBeHaviorTransformationWithHp:Name()
    return "MonsterBeHaviorTransformationWithHp"
end

function MonsterBeHaviorTransformationWithHp:FindSharpIdByHp(hp)
    if self._sharps == nil then
        return
    end

    local sharpId = nil
    for i = 1, #self._sharps do
        local sharpHp = self._sharps[i].HP
        if sharpHp >= hp then
            sharpId = self._sharps[i].ResId
            break
        end
    end

    return sharpId
end

function MonsterBeHaviorTransformationWithHp:CheckTransformation(hp)
    local sharpId = self:FindSharpIdByHp(hp)
    if not sharpId then
        return
    end

    ---@type MonsterBeHaviorView
    local view = self:GetBehavior("MonsterBeHaviorView")
    if not view then
        return
    end

    ---@type MonsterBeHaviorAnimation
    local animation = self:GetBehavior("MonsterBeHaviorAnimation")
    if animation then
        animation:PlayAnimation(BounceConst.MonsterBeAttackedAniName)
    end
    self.monster:SetTransformation(view:GetAttackedLength(), function()
        view:ChgRes(sharpId)
    end)
end

function MonsterBeHaviorTransformationWithHp:ChgResImmediatelyBy(hp)
    local sharpId = self:FindSharpIdByHp(hp)
    if not sharpId then
        return
    end

    ---@type MonsterBeHaviorView
    local view = self:GetBehavior("MonsterBeHaviorView")
    if not view then
        return
    end
    view:ChgRes(sharpId)
end


function MonsterBeHaviorTransformationWithHp:OnInit(param)
    --说明sharps是数组{[1] ={HP = 1, ResId = 1111}, [2] ={HP = 1, ResId = 1111} }
    self._sharps = param.Sharps
end

function MonsterBeHaviorTransformationWithHp:OnShow()
end

function MonsterBeHaviorTransformationWithHp:OnReset()
end

function MonsterBeHaviorTransformationWithHp:OnRelease()
    self._sharps = nil
end
