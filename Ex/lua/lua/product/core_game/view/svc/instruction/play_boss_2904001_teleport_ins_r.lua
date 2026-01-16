require("base_ins_r")

_class("PlayBoss2904001TeleportInstruction", BaseInstruction)
---@class PlayBoss2904001TeleportInstruction : BaseInstruction
PlayBoss2904001TeleportInstruction = PlayBoss2904001TeleportInstruction

function PlayBoss2904001TeleportInstruction:Constructor(paramList)
    self._stockpileTimeMs = tonumber(paramList.stockpileTimeMs)
    self._stockpileAnimTriggerName = paramList.stockpileAnimTriggerName

    self._jumpTimeMs = tonumber(paramList.jumpTimeMs)
    self._jumpAnimTriggerName = paramList.jumpAnimTriggerName

    self._landTimeMs = tonumber(paramList.landTimeMs)
    self._landAnimTriggerName = paramList.landAnimTriggerName
end

---@param casterEntity Entity
function PlayBoss2904001TeleportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local casterPos = casterEntity:GetGridPosition()
    local targetPos = casterEntity:GetGridPosition()

    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportResult = routineComponent:GetEffectResultByArray(SkillEffectType.Teleport)
    if teleportResult then
        casterPos = teleportResult:GetPosOld()
        local posNew = teleportResult:GetPosNew()
        if posNew then
            targetPos = posNew
        else
            targetPos = casterPos
        end
    end

    if self._stockpileAnimTriggerName then
        casterEntity:SetAnimatorControllerTriggers({self._stockpileAnimTriggerName})
    end
    YIELD(TT, self._stockpileTimeMs)

    if self._jumpAnimTriggerName then
        casterEntity:SetAnimatorControllerTriggers({self._jumpAnimTriggerName})
    end
    if casterPos ~= targetPos then
        local speed = Vector2.Distance(targetPos, casterPos) / self._jumpTimeMs * 1000
        casterEntity:AddGridMove(speed, targetPos, casterPos)
    end
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
    local bodyArea = casterEntity:BodyArea():GetArea()
    for _, body in ipairs(bodyArea) do
        pieceService:SetPieceAnimUp(casterPos + body)
    end
    YIELD(TT, self._jumpTimeMs)
    while (casterEntity:HasGridMove()) do
        YIELD(TT)
    end

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:ShowHideTrapAtPos(targetPos, false)
    local trapIDList = teleportResult:GetTriggerTrapIDList()
    local trapEntityList = {}
    for _, v in ipairs(trapIDList) do
        local trapEntity = world:GetEntityByID(v)
        trapEntityList[#trapEntityList + 1] = trapEntity
    end
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")
    sPlaySkillInstruction:PlayTrapTrigger(TT, casterEntity, trapEntityList)

    renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
    if self._landAnimTriggerName then
        casterEntity:SetAnimatorControllerTriggers({self._landAnimTriggerName})
    end
    YIELD(TT, self._landTimeMs)
    for _, body in ipairs(bodyArea) do
        pieceService:SetPieceAnimDown(targetPos + body)
    end
end

function PlayBoss2904001TeleportInstruction:_PlayCasterControlGridDown(casterEntity, enable)
    if casterEntity:MonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = casterEntity:MonsterID()
        monsterIDCmpt:SetNeedGridDownEnable(enable == 1)
    elseif casterEntity:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRender = casterEntity:TrapRender()
        trapRender:SetNeedGridDownEnable(enable == 1)
    else
        return
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    local areaArray = bodyAreaCmpt:GetArea()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local monsterGridPos = casterEntity:GetRenderGridPosition()
    for i = 1, #areaArray do
        local curAreaPos = areaArray[i]
        local pos = Vector2(curAreaPos.x + monsterGridPos.x, curAreaPos.y + monsterGridPos.y)
        if enable == 1 then
            pieceSvc:SetPieceAnimDark(pos)
        else
            pieceSvc:SetPieceAnimNormal(pos)
        end
    end
end
