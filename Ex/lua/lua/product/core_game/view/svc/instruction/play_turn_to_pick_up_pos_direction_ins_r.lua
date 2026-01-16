require("base_ins_r")

---@class PlayTurnToPickUpPosDirectionInstruction: BaseInstruction
_class("PlayTurnToPickUpPosDirectionInstruction", BaseInstruction)
PlayTurnToPickUpPosDirectionInstruction = PlayTurnToPickUpPosDirectionInstruction

function PlayTurnToPickUpPosDirectionInstruction:Constructor(paramList)
    self._pickUpIndex = tonumber(paramList.pickUpIndex)
    self._waitTime = tonumber(paramList.waitTime) or 0
    self._directDir = tonumber(paramList.directDir) or 1
    self._useResultPosCalcDir = tonumber(paramList.useResultPosCalcDir) or 0

    assert(self._pickUpIndex, "PlayTurnToPickUpDirection需要pickUpIndex参数")
end

---@param casterEntity Entity
function PlayTurnToPickUpPosDirectionInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type RenderPickUpComponent
    local selectComponent = casterEntity:RenderPickUpComponent()
    local selectedPosArray = selectComponent:GetAllValidPickUpGridPos()

    if #selectedPosArray == 0 or (not selectedPosArray[self._pickUpIndex]) then
        Log.warn(self._className, "没有找到索引的拾取点: ", self._pickUpIndex)
        return
    end

    local targetPickupPos = selectedPosArray[self._pickUpIndex]

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local targetPickupRenderPos = boardServiceRender:GridPos2RenderPos(targetPickupPos)

    local startDirection = casterEntity:Location():GetDirection()
    self:_CompressV3(startDirection)
    local casterRenderPos = casterEntity:Location():GetPosition()
    local newDirection = targetPickupRenderPos - casterRenderPos
    if self._useResultPosCalcDir == 1 then
        ---@type SkillEffectResultContainer
        local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
        ---@type SkillEffectResult_Teleport
        local teleportResult = routineComponent:GetEffectResultByArray(SkillEffectType.Teleport)
        if teleportResult then
            local posOld = teleportResult:GetPosOld()
            local posNew = teleportResult:GetPosNew()
            local posOldRender = boardServiceRender:GridPos2RenderPos(posOld)
            local posNewRender = boardServiceRender:GridPos2RenderPos(posNew)
            newDirection = posNewRender - posOldRender
        end
    end
    if self._directDir == 1 then
        newDirection = Vector3.Normalize(newDirection)
    else
        self:_CompressV3(newDirection)
    end

    local viewComponent = casterEntity:View()
    local go = viewComponent:GetGameObject()
    local transform = go.transform

    local quaternionBegin = transform.rotation
    if Vector3.Distance(newDirection, Vector3.zero) > 0 then
        local quaternionFinal = Quaternion.LookRotation(newDirection, Vector3.up)
        if self._waitTime <= 0 then
            casterEntity:SetDirection(newDirection)
            return
        end

        local startTime = GameGlobal:GetInstance():GetCurrentTime()
        local finalTime = GameGlobal:GetInstance():GetCurrentTime() + self._waitTime

        local t = 0
        while (t <= self._waitTime) do
            local deltaTime = GameGlobal:GetInstance():GetCurrentTime() - startTime

            t = t + deltaTime

            transform.rotation = Quaternion.Lerp(quaternionBegin, quaternionFinal, t / self._waitTime)

            YIELD(TT)
        end

        casterEntity:SetDirection(newDirection)
    end
end

function PlayTurnToPickUpPosDirectionInstruction:_CompressV3(v3)
    if v3.x > 1 then
        v3.x = 1
    elseif v3.x < -1 then
        v3.x = -1
    end

    if v3.y > 1 then
        v3.y = 1
    elseif v3.y < -1 then
        v3.y = -1
    end

    if v3.z > 1 then
        v3.z = 1
    elseif v3.z < -1 then
        v3.z = -1
    end
end
