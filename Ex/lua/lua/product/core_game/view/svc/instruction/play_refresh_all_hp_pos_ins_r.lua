require("base_ins_r")
---刷新血条位置 （火车特效带震屏，导致血条位置出错）
---@class PlayRefreshAllHPPosInstruction: BaseInstruction
_class("PlayRefreshAllHPPosInstruction", BaseInstruction)
PlayRefreshAllHPPosInstruction = PlayRefreshAllHPPosInstruction

function PlayRefreshAllHPPosInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayRefreshAllHPPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local hpGroup = world:GetGroup(world.BW_WEMatchers.HP)
    if hpGroup then
        local targetEntitys = hpGroup:GetEntities()
        if targetEntitys then
            for i, e in ipairs(targetEntitys) do
                ---@type HPComponent
                local hpCmpt = e:HP()
                if hpCmpt then
                    hpCmpt:SetHPPosDirty(true)
                end
            end
        end
    end
end
