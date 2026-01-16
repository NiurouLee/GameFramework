require("base_ins_r")
---@class PlayMultiJumpEffectToTargetInstruction: BaseInstruction
_class("PlayMultiJumpEffectToTargetInstruction", BaseInstruction)
PlayMultiJumpEffectToTargetInstruction = PlayMultiJumpEffectToTargetInstruction

function PlayMultiJumpEffectToTargetInstruction:Constructor(paramList)
    self._flyEffectID = tonumber(paramList["flyEffectID"])
    self._flySpeed = tonumber(paramList["flySpeed"])
    if paramList["flyTime"] then
        self._flyTime = tonumber(paramList["flyTime"])
    end

    self._startOffsetX = tonumber(paramList["startOffsetX"]) or 0
    self._startOffsetY = tonumber(paramList["startOffsetY"]) or 0
    self._startOffsetZ = tonumber(paramList["startOffsetZ"]) or 0

    self._targetOffsetX = tonumber(paramList["targetOffsetX"]) or 0
    self._targetOffsetY = tonumber(paramList["targetOffsetY"]) or 0
    self._targetOffsetZ = tonumber(paramList["targetOffsetZ"]) or 0

    --抛物线高度
    self._jumpPower = tonumber(paramList.jumpPower)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMultiJumpEffectToTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local casterEntityReal = casterEntity

    if not targetEntity then
        return
    end

    --创建点位置
    local tran = casterEntityReal:View():GetGameObject().transform
    local castPos = tran:TransformPoint(Vector3(self._startOffsetX, self._startOffsetY, self._startOffsetZ))

    --目标点位置
    ---@type GridLocationComponent
    local cGridLocation = targetEntity:GridLocation()
    local v2 = cGridLocation:Center()
    ---@type BoardServiceRender
    local boardServiceRender = casterEntityReal:GetOwnerWorld():GetService("BoardRender")
    local targetPos = boardServiceRender:GridPos2RenderPos(v2)

    targetPos = targetPos + Vector3(self._targetOffsetX, self._targetOffsetY, self._targetOffsetZ)

    --发射方向
    local dir = targetPos - castPos
    --创建特效
    local effectEntity = world:GetService("Effect"):CreatePositionEffect(self._flyEffectID, castPos)
    effectEntity:SetDirection(dir)

    --计算距离
    local distance = Vector3.Distance(castPos, targetPos)
    --计算飞行时间
    local flyTime = 0
    if self._flySpeed then
        flyTime = distance * self._flySpeed
    end

    -- YIELD(TT)

    local go = effectEntity:View():GetGameObject()
    --go.transform.forward = dir
    local dotween = nil

    local jumpPower = self._jumpPower or math.sqrt(distance)
    flyTime = self._flyTime or flyTime

    local path = {}
    table.insert(path, castPos)
    -- local middlePos = castPos + (dir.normalized * 0.6) + Vector3(0, jumpPower, 0)
    local middlePos = Vector3.Lerp(castPos, targetPos, 0.4) + Vector3(0, jumpPower, 0)
    table.insert(path, middlePos)
    table.insert(path, targetPos)

    local pathBezier = {}
    for i = 0, 1, 0.1 do
        table.insert(pathBezier, self:_BezierMethod(i, path))
    end
    table.insert(pathBezier, targetPos)

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            local tweenTime = flyTime / table.count(pathBezier)
            for i = 1, table.count(pathBezier) - 1 do
                local nextPos = pathBezier[i + 1]
                go.transform:LookAt(nextPos)
                go.transform:DOMove(nextPos, tweenTime * 0.001)
                -- go.transform:DOLookAt(nextPos, tweenTime * 0.0005)

                YIELD(TT, tweenTime)
            end

            go:SetActive(false)
            world:DestroyEntity(effectEntity)
        end
    )

    -- dotween =
    --     go.transform:DOPath(
    --     path,
    --     flyTime * 0.001,
    --     DG.Tweening.PathType.CatmullRom,
    --     DG.Tweening.PathMode.Full3D,
    --     10,
    --     Color.red
    -- )

    -- :SetLookAt(0)
    -- :SetSpecialStartupMode(DG.Tweening.Core.Enums.SpecialStartupMode.SetLookAt)

    -- if dotween then
    --     dotween:SetEase(DG.Tweening.Ease.InOutSine):OnComplete(
    --         function()
    -- go:SetActive(false)
    -- world:DestroyEntity(effectEntity)
    --         end
    --     )
    -- end

    -- if self._isBlock == 1 then
    --     YIELD(TT, flyTime)

    --     go:SetActive(false)
    --     world:DestroyEntity(effectEntity)
    -- else
    --     GameGlobal.TaskManager():CoreGameStartTask(
    --         function(TT)
    --             YIELD(TT, flyTime)

    --             go:SetActive(false)
    --             world:DestroyEntity(effectEntity)
    --         end
    --     )
    -- end
end

function PlayMultiJumpEffectToTargetInstruction:GetCacheResource()
    local t = {}
    if self._flyEffectID and self._flyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    return t
end

function PlayMultiJumpEffectToTargetInstruction:_BezierMethod(t, foceList)
    if table.count(foceList) < 2 then
        return foceList[1]
    end

    local temp = {}

    for i = 1, table.count(foceList) - 1 do
        local proportion =
            Vector3(
            (1 - t) * foceList[i].x + t * foceList[i + 1].x,
            (1 - t) * foceList[i].y + t * foceList[i + 1].y,
            (1 - t) * foceList[i].z + t * foceList[i + 1].z
        )

        table.insert(temp, proportion)
    end

    return self:_BezierMethod(t, temp)
end
