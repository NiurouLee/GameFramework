require("play_grid_range_convert_ins_r")
---@class PlayIsolateConvertInstruction: BaseInstruction
_class("PlayIsolateConvertInstruction", BaseInstruction)
PlayIsolateConvertInstruction = PlayIsolateConvertInstruction

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayIsolateConvertInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local cRoutine = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_IsolateConvert[]
    local results = cRoutine:GetEffectResultsAsArray(SkillEffectType.IsolateConvert)

    -- 实际上这里只应该有一个结果的
    local result = results[1]
    if not result then
        return
    end

    local tConvertInfo = {}
    local world = casterEntity:GetOwnerWorld()
    local tAtomicData = result:GetAtomicDataArray()
    for _, atomicData in ipairs(tAtomicData) do
        local traps = {}
        local pos = atomicData:GetPosition()
        local oldPieceType = atomicData:GetOldPieceType()
        local newPieceType = atomicData:GetTargetPieceType()
        local flushTrapIds = atomicData:GetDestroyedTrapArray()
        for i, v in ipairs(flushTrapIds) do
            local e = world:GetEntityByID(v)
            table.insert(traps, e)
        end
        --self:_Convert(world, pos, newPieceType, traps)
        --洗机关，直接删除
        ---@type TrapServiceRender
        local trapServiceRender = world:GetService("TrapRender")
        trapServiceRender:PlayTrapDieSkill(TT, traps)
        for _, trap in ipairs(traps) do
            trapServiceRender:DestroyTrap(TT,trap)
        end
        --执行转色
        if newPieceType and newPieceType >= PieceType.None and newPieceType <= PieceType.Any then
            ---@type BoardServiceRender
            local boardServiceR = world:GetService("BoardRender")
            ---@type Entity
            local newGridEntity = boardServiceR:ReCreateGridEntity(newPieceType, pos)

            if newGridEntity then
                ---@type PieceServiceRender
                local pieceSvc = world:GetService("Piece")
                pieceSvc:SetPieceEntityAnimNormal(newGridEntity)
            end
        end
        local convertInfo = NTGridConvert_ConvertInfo:New(pos, oldPieceType, newPieceType)
        table.insert(tConvertInfo, convertInfo)
    end

    --通知转色
    ---@type PlaySkillService
    local svcPlaySkill = world:GetService("PlaySkill")
    
    ---@type PlayBuffService
    local svcPlayBuff = world:GetService("PlayBuff")
    if #tConvertInfo > 0 then
        local notify = NTGridConvert:New(casterEntity, tConvertInfo)
        notify:SetConvertEffectType(SkillEffectType.IsolateConvert)
        notify.__attackPosMatchRequired = true
        svcPlayBuff:PlayBuffView(TT, notify)
    end
end
