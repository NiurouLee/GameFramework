require("base_ins_r")
---瞬移表现的指令外包装： 2020-06-19 韩玉信
---@class PlayCasterTeleportByAnimInstruction: BaseInstruction
_class("PlayCasterTeleportByAnimInstruction", BaseInstruction)
PlayCasterTeleportByAnimInstruction = PlayCasterTeleportByAnimInstruction

function PlayCasterTeleportByAnimInstruction:Constructor(paramList)
    self._stageIndex = tonumber(paramList["stageIndex"]) or 1
    self._leftAnimName = paramList["leftAnim"]
    self._rightAnimName = paramList["rightAnim"]
    self._leftAnimLen = tonumber(paramList["leftAnimLen"]) or 1000
    self._rightAnimLen = tonumber(paramList["rightAnimLen"]) or 1000
end

---@param casterEntity Entity
function PlayCasterTeleportByAnimInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportEffectResult =
    skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)
    if not teleportEffectResult then
        return
    end
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    local oldPos = teleportEffectResult:GetPosOld()
    local newPos = teleportEffectResult:GetPosNew()
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    ---@type DirectionType
    local dirType =utilScopeCalcSvc:GetEntityRenderDirType(casterEntity)
    local playAnimName,animLen = self:GetAnimName(newPos,oldPos,dirType)
    --Log.fatal("CurDirType:",dirType,"PlayAnimName:",playAnimName)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---相当于瞬移前
    renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
    self:RefreshPieceAnim(oldPos,casterEntity,true)
    trapServiceRender:ShowHideTrapAtPos(oldPos, true)
    casterEntity:SetAnimatorControllerTriggers({playAnimName})
    YIELD(TT,animLen)    
    ---local frame2= UnityEngine.Time.frameCount
    --Log.fatal("ConfigLen:",animLen,"RealLen:",realAnimLen)
    ---Log.fatal("FrameCount:",(frame2-frame1),"CurrentFrame:",frame2)
    casterEntity:SetAnimatorControllerTriggers({"Idle"})
    ---相当于瞬移后
    casterEntity:SetPosition(newPos + casterEntity:GetGridOffset())
    --renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
    self:RefreshPieceAnim(newPos,casterEntity,false)
    trapServiceRender:ShowHideTrapAtPos(newPos, false)
end

function PlayCasterTeleportByAnimInstruction:RefreshPieceAnim(pos,casterEntity,bLight)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local utilDataService = self._world:GetService("UtilData")
    local bodyArea = casterEntity:BodyArea():GetArea()
    for i = 1, #bodyArea do
        local posWork = pos + bodyArea[i]
        if utilDataService:IsValidPiecePos(posWork) then
            if bLight then
                pieceService:SetPieceAnimUp(posWork)
            else
                pieceService:SetPieceAnimDown(posWork)
            end
        end
    end
end


function PlayCasterTeleportByAnimInstruction:GetAnimName(newPos,oldPos,dirType)
    if dirType == DirectionType.Left then
        if newPos.y >oldPos.y then
            return self._rightAnimName,self._rightAnimLen
        else
            return self._leftAnimName,self._leftAnimLen
        end
    elseif dirType == DirectionType.Right then
        if newPos.y <oldPos.y then
            return self._rightAnimName,self._rightAnimLen
        else
            return self._leftAnimName,self._leftAnimLen
        end
    elseif dirType == DirectionType.Up then
        if newPos.x >oldPos.x then
            return self._rightAnimName,self._rightAnimLen
        else
            return self._leftAnimName,self._leftAnimLen
        end
    elseif dirType == DirectionType.Down then
        if newPos.x <oldPos.x then
            return self._rightAnimName,self._rightAnimLen
        else
            return self._leftAnimName,self._leftAnimLen
        end
    end
end
