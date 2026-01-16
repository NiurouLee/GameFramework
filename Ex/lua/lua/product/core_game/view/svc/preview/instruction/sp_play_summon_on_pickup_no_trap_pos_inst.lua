--点选位置没有指定机关，则显示机关虚影（特效
require("sp_base_inst")
_class("SkillPreviewPlaySummonOnPickupNoTrapPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlaySummonOnPickupNoTrapPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlaySummonOnPickupNoTrapPosInstruction = SkillPreviewPlaySummonOnPickupNoTrapPosInstruction

function SkillPreviewPlaySummonOnPickupNoTrapPosInstruction:Constructor(params)
    self._trapID = tonumber(params.trapID)
    self._effectID = tonumber(params.effectID)
end

function SkillPreviewPlaySummonOnPickupNoTrapPosInstruction:GetCacheResource()
    return {
        {Cfg.cfg_effect[self._effectID].ResPath, 1}
    }
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlaySummonOnPickupNoTrapPosInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")

    local pickUpPos = previewContext:GetPickUpPos()
    local boardCmpt = world:GetBoardEntity():Board()
    local traps =
        boardCmpt:GetPieceEntities(
        pickUpPos,
        function(e)
            local isOwner = false
            if e:HasSummoner() then
                if e:Summoner():GetSummonerEntityID() == casterEntity:GetID() then
                    isOwner = true
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrapRender() and e:TrapRender():GetTrapID() == self._trapID and not e:HasDeadMark()
        end
    )

    if #traps > 0 then
    else
        local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(self._effectID, pickUpPos)
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())
    end
end
