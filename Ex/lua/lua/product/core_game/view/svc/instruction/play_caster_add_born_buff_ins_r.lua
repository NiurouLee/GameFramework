require("base_ins_r")
---@class PlayCasterAddBornBuffInstruction: BaseInstruction
_class("PlayCasterAddBornBuffInstruction", BaseInstruction)
PlayCasterAddBornBuffInstruction = PlayCasterAddBornBuffInstruction

function PlayCasterAddBornBuffInstruction:Constructor(paramList)
end

---@param casterEntity Entity
function PlayCasterAddBornBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if casterEntity:MonsterID() then
        --怪物初始buff
        ---@type PlayBuffService
        local sPlayBuff = casterEntity:GetOwnerWorld():GetService("PlayBuff")
        ---@type BuffViewComponent
        local buffViewComponent = casterEntity:BuffView()
        if buffViewComponent then
            local viewIns = buffViewComponent:GetBuffViewInstanceArray()
            for _, inst in ipairs(viewIns) do
                local context = inst:GetBuffViewContext()
                if context and context.isMonsterBornBuff then
                    sPlayBuff:PlayAddBuff(TT, inst)
                end
            end
        end
    end
end
