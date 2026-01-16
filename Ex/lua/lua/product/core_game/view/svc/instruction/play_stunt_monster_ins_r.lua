require("base_ins_r")

---@class PlayStuntMonsterInstruction: BaseInstruction
_class("PlayStuntMonsterInstruction", BaseInstruction)
PlayStuntMonsterInstruction = PlayStuntMonsterInstruction

function PlayStuntMonsterInstruction:Constructor(paramList)
    self._stuntTag = paramList.tag or "default"
    self._remove = paramList.remove
    self._monsterClassID = tonumber(paramList.monsterClassID)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayStuntMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if not casterEntity:HasMonsterID() then
        return
    end

    if not self._remove then
        self:_CreateStunt(TT, casterEntity, phaseContext)
    else
        self:_DestroyStunt(TT, casterEntity, phaseContext)
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayStuntMonsterInstruction:_CreateStunt(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local resvc = world:GetService("RenderEntity")
    local eStuntMonster = resvc:CreateStuntMonster(casterEntity, self._stuntTag, self._monsterClassID)

    if not eStuntMonster then
        Log.error("Stunt monster create failed. ")
        return
    end

    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()

    local tv2GridPos = {}
    for x, groupX in pairs(renderBoardCmpt._gridEntityTable) do
        for y, _ in pairs(groupX) do
            table.insert(tv2GridPos, Vector2.New(x, y))
        end
    end

    local v2TargetPos
    local v2BackupTargetPos

    local bodyArea = casterEntity:BodyArea():GetArea()
    local v2CasterGridPos = casterEntity:GetGridPosition()

    local blockData = casterEntity:MonsterID():GetMonsterBlockData()

    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")

    while((not v2TargetPos) and (#tv2GridPos > 0)) do
        local v2Candidate = tv2GridPos[math.random(1, #tv2GridPos)]
        local isPosValid = true
        -- 首先看这个位置是否空闲
        for _, v2BodyArea in ipairs(bodyArea) do
            local v2AbsBody = v2BodyArea + v2Candidate
            if(not utilDataSvc:IsValidPiecePos(v2AbsBody)) or (utilDataSvc:IsPosBlock(v2AbsBody, blockData)) then
                isPosValid = false
                break
            end
        end

        if isPosValid then
            v2TargetPos = v2Candidate
            break
        end

        -- 如果不空闲，进行备选位置判断：位置上没有BOSS和玩家即可作为备选
        if not v2BackupTargetPos then
            local isPosBackup = true
            for _, v2BodyArea in ipairs(bodyArea) do
                local v2AbsBody = v2BodyArea + v2Candidate
                if not utilDataSvc:IsValidPiecePos(v2AbsBody) then
                    isPosBackup = false
                    break
                end

                ---@type PieceBlockData
                local pieceBlock = utilDataSvc:FindBlockByPos(v2AbsBody)
                -- 备选条件：没有玩家也没有自己
                if pieceBlock and (
                    pieceBlock:FindEntity(world, EnumTargetEntity.Pet) or
                    pieceBlock:GetEntityBlock(casterEntity:GetID())
                ) then
                    isPosBackup = false
                    break
                end
            end

            if isPosBackup then
                v2BackupTargetPos = v2Candidate
            end
        end
    end

    -- 保险措施
    if (not v2TargetPos) and (not v2BackupTargetPos) then
        v2TargetPos = Vector2.New(5, 5)
    end

    if not v2TargetPos then
        v2TargetPos = v2BackupTargetPos
    end

    -- y>=5时朝y-方向，y<5时朝y+方向
    local v2Dir = (v2TargetPos.y >= 5) and (Vector2.down) or (Vector2.up)

    eStuntMonster:SetLocation(v2TargetPos, v2Dir)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayStuntMonsterInstruction:_DestroyStunt(TT, casterEntity, phaseContext)
    if not casterEntity:HasStuntOwnerComponent() then
        return
    end

    ---@type StuntOwnerComponent
    local cStunt = casterEntity:StuntOwnerComponent()

    cStunt:RemoveStunt(self._stuntTag)
end
