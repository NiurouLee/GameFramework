require("base_ins_r")
---@class PlayCasterToPickupDirTrajectoryInstruction: BaseInstruction
_class("PlayCasterToPickupDirTrajectoryInstruction", BaseInstruction)
PlayCasterToPickupDirTrajectoryInstruction = PlayCasterToPickupDirTrajectoryInstruction

function PlayCasterToPickupDirTrajectoryInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList.effectID)
    self._flySpeed = tonumber(paramList.flySpeed)
    self._flyTime = tonumber(paramList.flyTime)

    if (not self._effectID) or (not Cfg.cfg_effect[self._effectID]) then
        Log.exception(self._className, "effectID无效: ", tostring(self._effectID))
    end

    if (not self._flySpeed) and (not self._flyTime) then
        Log.exception(self._className, "flySpeed与flyTime不可同时为空")
    end

    self._degressiveCount = tonumber(paramList.degressiveCount) --销毁次数，该方向上有几个伤害就销毁
    self._directionType = tonumber(paramList.directionType) --方向类型，1为点选方向，2为点选方向左侧斜线，3为点选方向右侧斜线
    self._destroyEffectID = tonumber(paramList.destroyEffectID) --销毁的特效
    self._effectReduceSize = tonumber(paramList.effectReduceSize) --每造成一个伤害，特效减小的尺寸
end

function PlayCasterToPickupDirTrajectoryInstruction:GetCacheResource()
    local t = {}
    if self._effectID then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    if self._destroyEffectID and self._destroyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._destroyEffectID].ResPath, 1})
    end
    return t
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterToPickupDirTrajectoryInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local casterPos = casterEntity:GetPosition()

    local castertRenderGridPos = casterEntity:GetRenderGridPosition()

    local pickUpGridPos = phaseContext:GetCurGridPos()
    if not pickUpGridPos then
        ---@type RenderPickUpComponent
        local renderPickUpComponent = casterEntity:RenderPickUpComponent()
        if renderPickUpComponent then
            local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
            pickUpGridPos = pickUpGridArray[1]
        end
    end

    if not pickUpGridPos then
        Log.exception(self._className, "没有点选位置")
        return
    end

    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    -- local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    local world = casterEntity:GetOwnerWorld()
    ---@type BoardServiceRender
    local rbsvc = world:GetService("BoardRender")
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    local maxLen = utilData:GetCurBoardMaxLen()
    --中心点偏移方向
    local dirCenter = pickUpGridPos - castertRenderGridPos
    --飞行目标方向
    local dir = pickUpGridPos - castertRenderGridPos
    --这里的directionType 定义和 EffectType =111里的定义一致
    if self._directionType == DegressiveDamageDirection.PICKUP_POS then
    elseif self._directionType == DegressiveDamageDirection.PICKUP_LEFT_CORNER then
        if dir == Vector2.up then
            dirCenter = Vector2.New(-1, 1)
        elseif dir == Vector2.down then
            dirCenter = Vector2.New(1, -1)
        elseif dir == Vector2.left then
            dirCenter = Vector2.New(-1, -1)
        elseif dir == Vector2.right then
            dirCenter = Vector2.New(1, 1)
        end
    elseif self._directionType == DegressiveDamageDirection.PICKUP_RIGHT_CORNER then
        if dir == Vector2.up then
            dirCenter = Vector2.New(1, 1)
        elseif dir == Vector2.down then
            dirCenter = Vector2.New(-1, -1)
        elseif dir == Vector2.left then
            dirCenter = Vector2.New(-1, 1)
        elseif dir == Vector2.right then
            dirCenter = Vector2.New(1, -1)
        end
    elseif self._directionType == DegressiveDamageDirection.PICKUP_FRONT_LEFT then
        if dir == Vector2.up then
            dirCenter = Vector2.New(-1, 0)
        elseif dir == Vector2.down then
            dirCenter = Vector2.New(1, 0)
        elseif dir == Vector2.left then
            dirCenter = Vector2.New(0, -1)
        elseif dir == Vector2.right then
            dirCenter = Vector2.New(0, 1)
        end
    elseif self._directionType == DegressiveDamageDirection.PICKUP_FRONT_RIGHT then
        if dir == Vector2.up then
            dirCenter = Vector2.New(1, 0)
        elseif dir == Vector2.down then
            dirCenter = Vector2.New(-1, 0)
        elseif dir == Vector2.left then
            dirCenter = Vector2.New(0, 1)
        elseif dir == Vector2.right then
            dirCenter = Vector2.New(0, -1)
        end
    end

    castertRenderGridPos = pickUpGridPos + dirCenter

    --特效终点坐标  = 施法位置 + 添加方向偏移
    local targetGridPos = castertRenderGridPos + Vector2(dir.x * maxLen, dir.y * maxLen)

    --V2 转成 V3
    local targetPos = rbsvc:GridPos2RenderPos(targetGridPos)
    -- local beginGridPos = rbsvc:BoardRenderPos2GridPos(casterPos)

    ---@type EffectService
    local fxsvc = world:GetService("Effect")
    local eFx = fxsvc:CreateCommonGridEffect(self._effectID, castertRenderGridPos, dir)
    local curEffectSize = 1
    local curDegressiveCount = self._degressiveCount

    YIELD(TT)

    if (not eFx) or (not eFx:View()) then
        return
    end

    local flyTime = self._flyTime
    local dis = Vector3.Distance(casterPos, targetPos)
    if not flyTime then
        flyTime = dis * self._flySpeed -- 这里与已有的弹道保持一致，除法在配置上做好
    end

    local go = eFx:View():GetGameObject()
    local tsfm = go.transform
    local dotween = tsfm:DOMove(targetPos, flyTime * 0.001, false)

    if dotween then
        dotween:SetEase(DG.Tweening.Ease.InOutSine):OnComplete(
            function()
                go:SetActive(false)
                world:DestroyEntity(eFx)
            end
        )
    end

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            for i = 1, dis do
                --等待一个格子的飞行时间
                YIELD(TT, self._flySpeed)

                --到达新位置
                local posWork = castertRenderGridPos + Vector2(dir.x * i, dir.y * i)

                --检测是否有伤害
                ---@type SkillDamageEffectResult
                local damageResult = skillEffectResultContainer:GetEffectResultByPos(SkillEffectType.Damage, posWork)
                if damageResult then
                    curDegressiveCount = curDegressiveCount - 1
                    curEffectSize = curEffectSize - self._effectReduceSize
                    if curEffectSize <= 0 then
                        curEffectSize = 0
                    end

                    local scaleData = Vector3.New(curEffectSize, curEffectSize, curEffectSize)
                    tsfm:DOScale(scaleData, 0)
                end

                if curDegressiveCount == 0 or curEffectSize <= 0 then
                    local destroyEffectEntity =
                        fxsvc:CreateCommonGridEffect(self._destroyEffectID, posWork, Vector2(0, 0))
                    break
                end
            end

            -- YIELD(TT, flyTime)

            if not dotween then
                world:DestroyEntity(eFx)
            end
        end
    )
end
