require("base_ins_r")
_class("PlayPickUpGridTogetherEffectInstruction", BaseInstruction)
---@class PlayPickUpGridTogetherEffectInstruction: BaseInstruction
PlayPickUpGridTogetherEffectInstruction = PlayPickUpGridTogetherEffectInstruction

function PlayPickUpGridTogetherEffectInstruction:Constructor(paramList)

end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPickUpGridTogetherEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_PickUpGridTogether
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PickUpGridTogether)
    if not resultArray then
        return
    end
    local result = resultArray[1]
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local boardServiceR = world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    ---@type PickUpGridTogetherData[]
    local newGridList = result:GetNewGridDataList()
    ---@param data PickUpGridTogetherData
    for i, data in ipairs(newGridList) do
        local newPieceType =data:GetGridType()
        local pos = data:GetGridPos()
        if utilDataSvc:GetRenderPieceType(pos) ~= newPieceType then
            local newGridEntity=boardServiceR:ReCreateGridEntity(newPieceType, pos, false, false, true)
            --破坏格子后 不会创建新格子
            if newGridEntity then
                ---@type PieceServiceRender
                local pieceSvc = world:GetService("Piece")
                pieceSvc:SetPieceEntityAnimNormal(newGridEntity)
            end
        end
    end
end

function PlayPickUpGridTogetherEffectInstruction:GetCacheResource()
    local t = {}
    return t
end
