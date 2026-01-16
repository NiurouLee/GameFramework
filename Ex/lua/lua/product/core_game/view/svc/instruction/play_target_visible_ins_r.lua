require("base_ins_r")
---@class PlayTargetVisibleInstruction: BaseInstruction
_class("PlayTargetVisibleInstruction", BaseInstruction)
PlayTargetVisibleInstruction = PlayTargetVisibleInstruction

function PlayTargetVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
    local str = paramList["SupportBodySizeList"] or ""
    if str ~= "" then
        self._SupportBodySizeList = string.split(str, "&")
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetID = phaseContext:GetCurTargetEntityID()

    local targetEntity = phaseContext._world:GetEntityByID(targetID)
    if not targetEntity then
        return
    end
    if not self:CheckTargetBody(targetEntity) then
        return
    end
    -- 模型显示时血条显示，这是需求
    local isShow = self._visible == 1
    -- targetEntity:SetViewVisible(isShow)
    --关闭view会影响一些animation的状态机，所以改成了移动坐标
    ---@type LocationComponent
    local location = targetEntity:Location()
    if location then
        ---@type UnityEngine.Vector3
        local gridWorldPos = targetEntity:GetPosition()
        local offsetY = isShow and 0 or 1000
        local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
        targetEntity:SetPosition(gridWorldNew)
    end

    ---@type HPComponent
    local cHP = targetEntity:HP()

    if not cHP then
        return
    end

    local world = targetEntity:GetOwnerWorld()

    local eidHPBar = cHP:GetHPSliderEntityID()
    local hpBarEntity = world:GetEntityByID(eidHPBar)

    if not hpBarEntity then
        return
    end
    hpBarEntity:SetViewVisible(isShow)
    --local monsrsvc = world:GetService("MonsterShowRender")
    --monsrsvc:ShowMonsterHPBar(TT, targetEntity, hpBarEntity, isShow)
end

---@param targetEntity Entity
function PlayTargetVisibleInstruction:CheckTargetBody(targetEntity)
    if not self._SupportBodySizeList then
        return true
    end
    ---@type BodyAreaComponent
    local bodyCmpt = targetEntity:BodyArea()
    for i, bodySize in ipairs(self._SupportBodySizeList) do
        if bodyCmpt:GetAreaCount() == tonumber(bodySize) then
            return true
        end
    end
    return false
end
