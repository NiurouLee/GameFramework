require("base_ins_r")
---显隐HUD上的对象
---@class PlayHUDVisibleInstruction: BaseInstruction
_class("PlayHUDVisibleInstruction", BaseInstruction)
PlayHUDVisibleInstruction = PlayHUDVisibleInstruction

function PlayHUDVisibleInstruction:Constructor(paramList)
    local param = tonumber(paramList["visible"])
    if param == 1 then
        self._visible = true
    else
        self._visible = false
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayHUDVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    if self._visible then
        local targets = phaseContext:GetHUDTargets()
        if targets then
            for i, e in ipairs(targets) do
                e:SetViewVisible(true)
            end
        end
    else --隐藏
        local targets = {}
        local group = world:GetGroup(world.BW_WEMatchers.HUD)
        for _, e in ipairs(group:GetEntities()) do
            e:SetViewVisible(self._visible)
            if e:IsViewVisible() then
                table.insert(targets, e)
                e:SetViewVisible(false)
            end
        end
        phaseContext:SetHUDTargets(targets)
    end
end
