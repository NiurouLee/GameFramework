require("base_ins_r")
---@class PlayFlyEffectCasterToTargetInstruction: BaseInstruction
_class("PlayFlyEffectCasterToTargetInstruction", BaseInstruction)
PlayFlyEffectCasterToTargetInstruction = PlayFlyEffectCasterToTargetInstruction

--飞行轨迹类型
FlyEffectTraceType = {
    LineTrace = 1, --直线
    JumpTrace = 2, --抛物线
    ScaleTrace = 3, --固定延伸
    TimeScaleTrace = 4 --随时间延伸
}

function PlayFlyEffectCasterToTargetInstruction:Constructor(paramList)
    self._flyEffectID = tonumber(paramList["flyEffectID"])
    self._flySpeed = tonumber(paramList["flySpeed"])
    if paramList["flyTime"] then
        self._flyTime = tonumber(paramList["flyTime"])
    end

    if paramList["ignoreYield"] then
        self._ignoreYield = tonumber(paramList["ignoreYield"])
    end

    if paramList["finalWaitTime"] then
        self._finalWaitTime = tonumber(paramList["finalWaitTime"])
    end
    self._flyTrace = tonumber(paramList["flyTrace"])

    self._offsetX = tonumber(paramList["offsetx"]) or 0
    self._offsetY = tonumber(paramList["offsety"]) or 0
    self._offsetZ = tonumber(paramList["offsetz"]) or 0
    self._targetOffset = Vector3(tonumber(paramList["targetoffsetx"]) or 0, tonumber(paramList["targetoffsety"]) or 0, tonumber(paramList["targetoffsetz"]) or 0)
    self._flyEaseType = paramList["flyEaseType"]
    self._pickUpPosAsTarget = tonumber(paramList.pickUpPosAsTarget) == 1
    self._teleportPosAsTarget = tonumber(paramList.teleportPosAsTarget) == 1
    self._targetPos = ""
    if paramList["targetPos"] then
        self._targetPos = paramList["targetPos"]
    end
    self._targetPickUpPos = nil
    if paramList["targetPickUpPos"] then
        self._targetPickUpPos =  tonumber(paramList["targetPickUpPos"])
    end
    self._boardCenterPos = nil
    if paramList["boardCenterPos"] then
        self._boardCenterPos = tonumber(paramList["boardCenterPos"])
    end
    self._originalBoneName = ""
    if paramList["originalBoneName"] then
        self._originalBoneName = paramList["originalBoneName"]
    end

    --是否是阻塞技能
    self._isBlock = tonumber(paramList["isBlock"]) or 1

    --如果有需求是从target飞向caster改这里
    --目前只支持“Caster”/“Target”，分别表示施法者，技能目标
    self.caster = paramList["caster"]
    self.target = paramList["target"]

    --抛物线高度
    self._jumpPower = tonumber(paramList.jumpPower)
    self._changeScaleRoot = paramList["changeScaleRoot"]
    self._overtakeDis = tonumber(paramList["overtakeDis"]) or 0--到目标点后继续走一段 适配部分特效
end

function PlayFlyEffectCasterToTargetInstruction:GetCacheResource()
    local resList = {}
    if self._flyEffectID and self._flyEffectID ~= 0 then
        table.insert(resList, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    return resList
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayFlyEffectCasterToTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local world = casterEntity:GetOwnerWorld()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local casterEntityReal = casterEntity
    if self.caster == "Target" then
        casterEntityReal = world:GetEntityByID(targetEntityID)
    end
    if self.target == "Caster" then
        targetEntity = casterEntity
    end
    if casterEntityReal and casterEntityReal:View() then
    else
        return
    end
    --创建点位置
    local tran
    if casterEntityReal:HasSuperEntity() and casterEntityReal:SuperEntityComponent():IsUseSuperEntityView() then
        tran = casterEntityReal:GetSuperEntity():View():GetGameObject().transform
    else
        tran = casterEntityReal:View():GetGameObject().transform
    end

    local castPos = tran:TransformPoint(Vector3(self._offsetX, self._offsetY, self._offsetZ))
    if self._originalBoneName and self._originalBoneName ~= "" then
        local boneTrans = GameObjectHelper.FindChild(tran, self._originalBoneName)
        if boneTrans ~= nil then
            castPos = boneTrans.position
        end
    end
    --目标点位置

    local targetPos = Vector3.zero
    if targetEntity then
        if targetEntity:TrapRender() then
            local gridPos = targetEntity:GetGridPosition()
            local gridDir = targetEntity:GetGridDirection()
            local gridOffset = targetEntity:GetGridOffset()
            if gridOffset then 
                gridPos = gridPos + gridOffset
            end

            targetEntity:SetLocation(gridPos, gridDir)
        end
        if targetEntity:Location() then
            targetPos = targetEntity:Location().Position
        else
            ---@type GridLocationComponent
            local cGridLocation = targetEntity:GridLocation()
            local v2 = cGridLocation:Center()
            ---@type BoardServiceRender
            local boardServiceRender = casterEntityReal:GetOwnerWorld():GetService("BoardRender")
            targetPos = boardServiceRender:GridPos2RenderPos(v2)
        end
        if self._targetPos and self._targetPos ~= "" then
            local tran = targetEntity:View():GetGameObject().transform
            local targetTrans = GameObjectHelper.FindChild(tran, self._targetPos)
            if targetTrans ~= nil then
                targetPos = targetTrans.position
            end
        end
        if self._targetPickUpPos then
            ---@type RenderPickUpComponent
            local renderPickUpComponent = casterEntity:RenderPickUpComponent()
            local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
            if pickUpGridArray[self._targetPickUpPos] then
                targetPos = pickUpGridArray[self._targetPickUpPos]
            end
        end
        if self._boardCenterPos == 1 then
            ---@type UtilDataServiceShare
            local utilDataSvc = world:GetService("UtilData")
            targetPos = utilDataSvc:GetBoardCenterPos()
        end
    else
        targetPos = self:GetNoTargetRenderPos(world, casterEntityReal)
    end

    if self._pickUpPosAsTarget then
        local targetPosV2 = phaseContext:GetCurGridPos()
        ---@type BoardServiceRender
        local boardServiceRender = casterEntityReal:GetOwnerWorld():GetService("BoardRender")
        targetPos = boardServiceRender:GridPos2RenderPos(targetPosV2)
    end
    if self._teleportPosAsTarget then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        ---@type SkillEffectResult_Teleport
        local teleportEffectResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport, 1)
        if not teleportEffectResult then
            return
        end
        local oldPos = teleportEffectResult:GetPosOld()
        local newPos = teleportEffectResult:GetPosNew()

        ---@type BoardServiceRender
        local boardServiceRender = casterEntityReal:GetOwnerWorld():GetService("BoardRender")
        targetPos = boardServiceRender:GridPos2RenderPos(newPos)
    end
    targetPos = targetPos + self._targetOffset
    --发射方向
    local dir = targetPos - castPos
    if self._overtakeDis and self._overtakeDis ~= 0 then
        local dirNormalized = dir.normalized
        targetPos = targetPos + (dirNormalized * self._overtakeDis)
    end
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
    if not self._ignoreYield then
        YIELD(TT)
    end

    if effectEntity==nil or effectEntity:View()==nil then
        return
    end


    local go = effectEntity:View():GetGameObject()
    --go.transform.forward = dir
    local dotween = nil
    if self._flyTrace == FlyEffectTraceType.LineTrace then
        if flyTime == 0 and self._flyTime then
            flyTime = self._flyTime
        end

        dotween = go.transform:DOMove(targetPos, flyTime / 1000.0, false)
        if self._flyEaseType then
            local easyType = DG.Tweening.Ease[self._flyEaseType]
            dotween:SetEase(easyType)
        end
    elseif self._flyTrace == FlyEffectTraceType.JumpTrace then
        local jumpPower = self._jumpPower or math.sqrt(distance)
        flyTime = self._flyTime or flyTime
        dotween = go.transform:DOJump(targetPos, jumpPower, 1, flyTime * 0.001, false)
    elseif self._flyTrace == FlyEffectTraceType.ScaleTrace then
        go.transform.localScale = Vector3(1, 1, distance)
    elseif self._flyTrace == FlyEffectTraceType.TimeScaleTrace then
        if self._flyTime then
            flyTime = self._flyTime
        end

        --修改的不是特效全部的scale，而是某一个节点的scale
        local changeScaleRoot = go
        if self._changeScaleRoot then
            changeScaleRoot = GameObjectHelper.FindChild(go.transform, self._changeScaleRoot)
        end
        dotween = changeScaleRoot.transform:DOScaleZ(distance, flyTime / 1000.0)
    end

    if dotween then
        dotween:SetEase(DG.Tweening.Ease.InOutSine):OnComplete(
            function()
                if self._finalWaitTime and self._finalWaitTime > 0 then
                    GameGlobal.TaskManager():CoreGameStartTask(
                        function(TT)
                            YIELD(TT, self._finalWaitTime)
                            if go then
                                go:SetActive(false)
                            end
                            world:DestroyEntity(effectEntity)
                        end
                    )
                else
                    go:SetActive(false)
                    world:DestroyEntity(effectEntity)
                end
            end
        )
    end
    local totalWaitTime = flyTime
    if self._finalWaitTime and self._finalWaitTime > 0 then
        totalWaitTime = totalWaitTime + self._finalWaitTime 
    end
    if self._isBlock == 1 then
        YIELD(TT, totalWaitTime)

        if not dotween then
            world:DestroyEntity(effectEntity)
        end
    else
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                YIELD(TT, totalWaitTime)

                if not dotween then
                    world:DestroyEntity(effectEntity)
                end
            end
        )
    end
end

function PlayFlyEffectCasterToTargetInstruction:GetCacheResource()
    local t = {}
    if self._flyEffectID and self._flyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    return t
end

---@param world MainWorld
---@param casterEntity Entity
function PlayFlyEffectCasterToTargetInstruction:GetNoTargetRenderPos(world, casterEntity)
    local renderPos = Vector3.zero
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if self._flyTrace == FlyEffectTraceType.LineTrace then --如果没有攻击目标，就取技能范围中最远的位置作为终点
        local scope = skillEffectResultContainer:GetScopeResult()
        local wholeRange = scope:GetWholeGridRange()
        local isBlock = false
        for _, pos in pairs(wholeRange) do
            if utilDataSvc:IsPosBlock(pos, BlockFlag.Skill) then
                isBlock = true
                break
            end
        end
        local attRange = scope:GetAttackRange()
        local posCaster = casterEntity:GridLocation().Position
        local farestPos, farestMagnitude = Vector2.zero, 0
        local range = {}
        if isBlock then
            range = attRange
        else
            range = wholeRange
        end
        for _, pos in pairs(range) do
            local m = Vector2.Magnitude(pos - posCaster)
            if m > farestMagnitude then
                farestPos = pos
                farestMagnitude = m
            end
        end
        renderPos = boardServiceRender:GridPos2RenderPos(farestPos)
    elseif self._flyTrace == FlyEffectTraceType.JumpTrace then
        Log.fatal("### expand by yourself")
    elseif self._flyTrace == FlyEffectTraceType.ScaleTrace then
        Log.fatal("### expand by yourself")
    elseif self._flyTrace == FlyEffectTraceType.TimeScaleTrace then
        Log.fatal("### expand by yourself")
    end
    return renderPos
end
