require("play_grid_range_convert_ins_r")

_class("PlayConvertFlyEffectInstruction", PlayGridRangeConvertInstruction)
PlayConvertFlyEffectInstruction = PlayConvertFlyEffectInstruction

function PlayConvertFlyEffectInstruction:Constructor(paramList)
    self._flyEffectID = tonumber(paramList["flyEffectID"])
    self._flySpeed = tonumber(paramList["flySpeed"])
    if paramList["flyTime"] then
        self._flyTime = tonumber(paramList["flyTime"])
    end
    self._flyTrace = tonumber(paramList["flyTrace"])

    self._offsetX = tonumber(paramList["offsetx"]) or 0
    self._offsetY = tonumber(paramList["offsety"]) or 0
    self._offsetZ = tonumber(paramList["offsetz"]) or 0
    self._flyEaseType = paramList["flyEaseType"]
    self._pickUpPosAsTarget = tonumber(paramList.pickUpPosAsTarget) == 1
    self._targetPos = ""
    if paramList["targetPos"] then
        self._targetPos = paramList["targetPos"]
    end
    self._originalBoneName = ""
    if paramList["originalBoneName"] then
        self._originalBoneName = paramList["originalBoneName"]
    end

    --是否是阻塞技能
    self._isBlock = tonumber(paramList["isBlock"]) or 1
    self._convertEffectID = tonumber(paramList.convertEffectID)
    self._jumpPower = tonumber(paramList["jumpPower"])
end

function PlayConvertFlyEffectInstruction:_Convert(world, gridPos, newGridType, flushTraps, casterEntity, TT)
    --洗机关，直接删除
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    for _, trap in ipairs(flushTraps) do
        trapServiceRender:DestroyTrap(trap)
    end

    --执行转色
    if newGridType and newGridType >= PieceType.None and newGridType <= PieceType.Any then
        --创建点位置
        local tran = casterEntity:View():GetGameObject().transform
        local castPos = tran:TransformPoint(Vector3(self._offsetX, self._offsetY, self._offsetZ))

        ---@type BoardServiceRender
        local boardServiceRender = casterEntity:GetOwnerWorld():GetService("BoardRender")
        local targetPos = boardServiceRender:GridPos2RenderPos(gridPos)
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

        local go = effectEntity:View():GetGameObject()
        local jumpPower = self._jumpPower or math.sqrt(distance)
        flyTime = self._flyTime or flyTime
        ---@type DG.Tweening.Tweener
        local dotween = go.transform:DOJump(targetPos, jumpPower, 1, flyTime * 0.001, false)

        dotween:OnComplete(
            function ()
                if self._isBlock == 1 then
                    self:_TaskFlying(TT, flyTime, world, effectEntity, gridPos, newGridType)
                else
                    GameGlobal.TaskManager():CoreGameStartTask(
                        self._TaskFlying,
                        self,
                        flyTime, 
                        world, 
                        effectEntity, 
                        gridPos,
                        newGridType
                    )
                end
            end
        )

        if self._isBlock == 1 then
            YIELD(TT, flyTime)
        end
        -- if self._isBlock == 1 then
        --     self:_TaskFlying(TT, flyTime, world, effectEntity, gridPos, newGridType)
        -- else
        --     GameGlobal.TaskManager():CoreGameStartTask(
        --         self._TaskFlying,
        --         self,
        --         flyTime * 0.9, 
        --         world, 
        --         effectEntity, 
        --         gridPos,
        --         newGridType
        --     )
        -- end
    end
end

function PlayConvertFlyEffectInstruction:_TaskFlying(TT, flyTime, world, effectEntity, gridPos, newGridType)
    ---@type BoardServiceRender
    local boardServiceR = world:GetService("BoardRender")
    ---@type Entity
    local newGridEntity = boardServiceR:ReCreateGridEntity(newGridType, gridPos)
    --破坏格子后 不会创建新格子
    if newGridEntity then
        ---@type PieceServiceRender
        local pieceSvc = world:GetService("Piece")
        pieceSvc:SetPieceEntityAnimNormal(newGridEntity)

        if self._convertEffectID then
            ---@type EffectService
            local fxsvc = world:GetService("Effect")
            fxsvc:CreateWorldPositionEffect(self._convertEffectID, gridPos)
        end
    end

    world:DestroyEntity(effectEntity)
end

function PlayConvertFlyEffectInstruction:GetCacheResource()
    local t = {}
    if self._flyEffectID and self._flyEffectID > 0 and Cfg.cfg_effect[self._flyEffectID] then
        table.insert(t, {Cfg.cfg_effect[self._flyEffectID].ResPath, 1})
    end
    if self._convertEffectID and self._convertEffectID > 0 and Cfg.cfg_effect[self._convertEffectID] then
        table.insert(t, {Cfg.cfg_effect[self._convertEffectID].ResPath, 1})
    end
    return t
end