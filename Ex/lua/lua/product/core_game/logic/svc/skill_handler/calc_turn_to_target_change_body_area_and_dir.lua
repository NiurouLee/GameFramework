--[[
    TurnToTargetChangeBodyAreaAndDir = 199, -- 朝向目标，中心点不变，修改自己身形和朝向，(n28蜘蛛3x2)
]]
---@class SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir : SkillEffectCalc_Base
_class("SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir", SkillEffectCalc_Base)
SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir = SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir

function SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TurnToTargetChangeBodyAreaAndDir:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamTurnToTargetChangeBodyAreaAndDir
    local skillParam = skillEffectCalcParam.skillEffectParam

    local forceTurn = skillParam:GetForceTurn() --是否强行转向，默认0不转(这个不转是不转90度，如果在背后身形不变还是可以转中心点)

    local caster = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterBodyArea = caster:BodyArea():GetArea()
    local casterPos = caster:GetGridPosition()
    local casterDir = caster:GetGridDirection()
    local casterBodyAreaPosList = {}
    for _, area in ipairs(casterBodyArea) do
        local workPos = area + casterPos
        table.insert(casterBodyAreaPosList, workPos)
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local playerPos = teamEntity:GetGridPosition()
    local playerBodyArea = teamEntity:BodyArea():GetArea()

    --计算结果
    local newBodyArea = casterBodyArea
    local newPos = casterPos
    local newDir = casterDir

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    --计算施法者坐标和队伍坐标的朝向
    local vectors = {Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)}
    local minIdx, minAngle = 1, 180
    local vec = playerPos - casterPos
    for i, v in ipairs(vectors) do
        local angle = Vector2.Angle(vec, v)
        if minAngle > angle then
            minAngle = angle
            minIdx = i
        end
    end
    newDir = vectors[minIdx]

    if table.count(casterBodyArea) == 6 then
        if newDir == Vector2(0, -1) then
            newBodyArea = {
                Vector2(0, 0),
                Vector2(1, 0),
                Vector2(-1, 0),
                Vector2(0, 1),
                Vector2(1, 1),
                Vector2(-1, 1)
            }
        elseif newDir == Vector2(1, 0) then
            newBodyArea = {
                Vector2(0, 0),
                Vector2(0, 1),
                Vector2(0, -1),
                Vector2(-1, 0),
                Vector2(-1, 1),
                Vector2(-1, -1)
            }
        elseif newDir == Vector2(-1, 0) then
            newBodyArea = {
                Vector2(0, 0),
                Vector2(0, 1),
                Vector2(0, -1),
                Vector2(1, 0),
                Vector2(1, 1),
                Vector2(1, -1)
            }
        elseif newDir == Vector2(0, 1) then
            newBodyArea = {
                Vector2(0, 0),
                Vector2(-1, 0),
                Vector2(1, 0),
                Vector2(0, -1),
                Vector2(-1, -1),
                Vector2(1, -1)
            }
        end
    end

    --强制转变
    if forceTurn == 1 then
    else
        --先计算不变中心点能否变身形
        local canChangeBodyArea = true
        --每一个点计算4个方向能否放下新的身形
        for _, area in ipairs(newBodyArea) do
            local workPos = area + casterPos

            if
                utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand) and
                    not table.intable(casterBodyAreaPosList, workPos)
             then
                canChangeBodyArea = false
                break
            end
        end

        --计算后不能变换身形
        if canChangeBodyArea == false then
            --不计算原地转

            newBodyArea = casterBodyArea
            newDir = casterDir
        end
    end

    --加血结果入SkillRoutine
    local skillEffectResultContainer = caster:SkillContext():GetResultContainer()

    if newDir ~= casterDir then
        ---@type SkillRotateEffectResult
        local skillRotateEffectResult = SkillRotateEffectResult:New(caster:GetID(), casterDir, newDir)
        skillEffectResultContainer:AddEffectResult(skillRotateEffectResult)

        ---@type SkillEffectResultChangeBodyArea
        local skillEffectResultChangeBodyArea = SkillEffectResultChangeBodyArea:New(caster:GetID(), newBodyArea)
        skillEffectResultContainer:AddEffectResult(skillEffectResultChangeBodyArea)
    end

    --这里需要有一个瞬移结果来关闭模型，再次打开模型的朝向就对了
    -- --不一定会有瞬移结果
    -- if newPos ~= casterPos then
    local colorOld = utilDataSvc:FindPieceElement(casterPos)
    local stageIndex = skillEffectCalcParam.skillEffectParam:GetSkillEffectDamageStageIndex()
    ---@type SkillEffectResult_Teleport
    local skillEffectResult_Teleport =
        SkillEffectResult_Teleport:New(
        skillEffectCalcParam.casterEntityID,
        casterPos,
        colorOld,
        newPos,
        newDir,
        stageIndex
    )
    skillEffectResultContainer:AddEffectResult(skillEffectResult_Teleport)
    -- end
end
