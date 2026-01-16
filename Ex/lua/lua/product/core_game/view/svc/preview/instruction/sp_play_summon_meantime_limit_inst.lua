require("sp_base_inst")
_class("SkillPreviewPlaySummonMeantimeLimitInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlaySummonMeantimeLimitInstruction: SkillPreviewBaseInstruction
SkillPreviewPlaySummonMeantimeLimitInstruction = SkillPreviewPlaySummonMeantimeLimitInstruction

function SkillPreviewPlaySummonMeantimeLimitInstruction:Constructor(params)
    self._visible = tonumber(params["visible"])
    self._trapID = tonumber(params["trapID"])
    self._limitCount = tonumber(params["limitCount"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlaySummonMeantimeLimitInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type BattleFlagsComponent
    local battleFlags = world:BattleFlags()
    local entityIDList = battleFlags:GetSummonMeantimeLimitEntityID(self._trapID)
    if table.count(entityIDList) < self._limitCount then
        return
    end

    --因为可以选中1的时候切换选中2，导致1的关闭没有显示出来。所以先把所有的还原成显示状态，再选择新的关闭的
    for _, entityID in ipairs(entityIDList) do
        local entity = world:GetEntityByID(entityID)
        ---@type LocationComponent
        local location = entity:Location()
        if location then
            ---@type UnityEngine.Vector3
            local gridWorldPos = entity:GetPosition()
            local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, 0, gridWorldPos.z)
            entity:SetPosition(gridWorldNew)
        end
    end

    local targetEntityID = entityIDList[1]
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        return
    end

    local secondEntityID = entityIDList[2]
    local secondEntity = world:GetEntityByID(secondEntityID)
    if not secondEntity then
        return
    end

    if previewContext:GetPickUpPos() == secondEntity:GridLocation():GetGridPos() then
        targetEntity = secondEntity
    end

    ---@type LocationComponent
    local location = targetEntity:Location()
    if location then
        ---@type UnityEngine.Vector3
        local gridWorldPos = targetEntity:GetPosition()
        local offsetY = self._visible == 1 and 0 or 1000
        local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
        targetEntity:SetPosition(gridWorldNew)
    end
end
