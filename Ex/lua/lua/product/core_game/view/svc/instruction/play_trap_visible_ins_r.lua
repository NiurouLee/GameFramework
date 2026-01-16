require("base_ins_r")
---@class PlayTrapVisibleInstruction: BaseInstruction
_class("PlayTrapVisibleInstruction", BaseInstruction)
PlayTrapVisibleInstruction = PlayTrapVisibleInstruction

function PlayTrapVisibleInstruction:Constructor(paramList)
    local param = tonumber(paramList["visible"])
    if param == 1 then
        self._visible = true
    else
        self._visible = false
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTrapVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local group = world:GetGroup(world.BW_WEMatchers.Trap)
    for _, e in ipairs(group:GetEntities()) do
        ---@type TrapRenderComponent
        local trapRenderCmpt = e:TrapRender()
        if trapRenderCmpt and not trapRenderCmpt:GetHadPlayDestroy() then
            -- e:SetViewVisible(self._visible)
            --关闭view会影响一些animation的状态机，所以改成了移动坐标
            ---@type LocationComponent
            local location = e:Location()
            if location then
                ---@type UnityEngine.Vector3
                local gridWorldPos = e:GetPosition()
                local offsetY = self._visible and 0 or 1000
                local gridWorldNew = Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
                e:SetPosition(gridWorldNew)
            end

            ---@type TrapRoundInfoRenderComponent
            local cTrapRoundInfo = e:TrapRoundInfoRender()
            if cTrapRoundInfo then
                cTrapRoundInfo:SetIsShow(self._visible)
            end
        end
    end
end
