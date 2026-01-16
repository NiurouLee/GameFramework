--[[
    Transport = 66, --运送实体
]]
---@class SkillEffectCalc_Transport: Object
_class("SkillEffectCalc_Transport", Object)
SkillEffectCalc_Transport = SkillEffectCalc_Transport

function SkillEffectCalc_Transport:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalc_Transport
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Transport:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}
    ---@type SkillEffectTransportParam
    local paramSkillEffect = skillEffectCalcParam.skillEffectParam
    local times = paramSkillEffect:GetTimes()
    local isLoop = paramSkillEffect:GetIsLoop()
    local offsetPos = paramSkillEffect:GetOffsetPos()
    local offsetBodyAreaTimes = paramSkillEffect:GetOffsetBodyAreaTimes()

    local transportor = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    --次数
    for i = 1, times do
        --1次内的传送是一个结果，在一次播放
        local result = SkillEffectTransportResult:New()
        --需要同时多个格子，扩充身形
        for j = 1, offsetBodyAreaTimes do
            local offsetWorkPos = offsetPos * (j - 1)
            --1.构建环境
            local envList = self:_CalcTransportEnvList(transportor, offsetWorkPos)
            --2.传送一步+触发机关
            self:_TransportOneStep(result, envList, isLoop)
        end
        results[#results + 1] = result
    end

    return results
end

--计算传送环境
function SkillEffectCalc_Transport:_CalcTransportEnvList(transportor, offsetWorkPos)
    local posTransportor = transportor:GetGridPosition()
    local bodyAreaTransportor = transportor:BodyArea():GetArea()
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()

    local filter = function(e)
        return e ~= transportor and e:HasBlockFlag() and not e:HasDeadMark()
    end
    --计算传送格子位置上的实体
    local envList = {}
    for i, area in ipairs(bodyAreaTransportor) do
        local pos = posTransportor + area + offsetWorkPos
        local posIdx = Vector2.Pos2Index(pos)
        local pieceType = boardCmpt:GetPieceType(pos)
        local es = boardCmpt:GetPieceEntities(pos, filter)
        local isPrism = boardCmpt:IsPrismPiece(pos)
        local prismEntityID = boardCmpt:GetPrismEntityIDAtPos(pos)
        local isTeam = false
        local FixBlock = {} --不能传送且阻挡传送
        local FixNoBlock = {} --不能传送且无阻挡
        local FloatBlock = {} --可传送且有阻挡
        local FloatNoBlock = {} --可传送且无阻挡
        for _, e in ipairs(es) do
            local blockFlag = e:BlockFlag():GetBlockFlag()
            if blockFlag & BlockFlag.Transport ~= 0 then --阻挡传送，此对象不能被传送
                if blockFlag & BlockFlag.LinkLine ~= 0 then --阻挡划线，其他对象不能穿过他
                    FixBlock[#FixBlock + 1] = e
                else
                    FixNoBlock[#FixNoBlock + 1] = e
                end
            else
                if e:HasTeam() or (blockFlag & BlockFlag.LinkLine ~= 0) then
                    FloatBlock[#FloatBlock + 1] = e
                else
                    FloatNoBlock[#FloatNoBlock + 1] = e
                end
            end
            if e:HasTeam() then
                isTeam = true
            end
        end
        local envIndex = #envList + 1
        envList[envIndex] = {
            index = envIndex,
            pos = pos,
            pieceType = pieceType,
            FixBlock = FixBlock,
            FixNoBlock = FixNoBlock,
            FloatBlock = FloatBlock,
            FloatNoBlock = FloatNoBlock,
            isPrism = isPrism,
            prismEntityID = prismEntityID,
            isTeam = isTeam,
            isBlock = #FixBlock > 0
        }
    end

    return envList
end

--传送一步
---@param result SkillEffectTransportResult
function SkillEffectCalc_Transport:_TransportOneStep(result, envList, isLoop)
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local cBoard = self._world:GetBoardEntity():Board()
    ---@type RandomServiceLogic
    local sRandom = self._world:GetService("RandomLogic")
    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")

    local lastTransportDir
    --收集可触发的机关信息
    local toTriggerTraps = {}
    for i, env in ipairs(envList) do
        --后面一个位置
        local nextEnv = self:_GetNeighboringEnv(envList, env, 1, isLoop)

        if not nextEnv then
            --移除传送带范围的格子也需要添加移动结果
            --result:AddTransportPiece(env.pos, env.pos + lastTransportDir)
            break
        end

        --传送格子
        result:AddTransportPiece(env.pos, nextEnv.pos)
        lastTransportDir = nextEnv.pos - env.pos

        --格子转色
        local pieceType = env.pieceType
        if self:_CheckNextBlock(env, envList, isLoop, env) then
            if env.isTeam then
                pieceType = sRandom:LogicRand(1, 4)
            end
            if nextEnv.isTeam then
                pieceType = PieceType.None
            end
        end
        --if pieceType ~= nextEnv.pieceType then
        result:AddConvertColor(nextEnv.pos, nextEnv.pieceType, pieceType)
        --转色生效
        sBoard:SetPieceTypeLogic(pieceType, nextEnv.pos)
        --end
        --棱镜
        if env.isPrism then
            --下个位置有挡住的team就踩掉棱镜
            if self:_CheckNextBlock(env, envList, isLoop, env) and nextEnv.isTeam then
                --下个位置为空就删除棱镜
                result:AddTransportPrism(env.pos, nil, env.prismEntityID)
            else
                result:AddTransportPrism(env.pos, nextEnv.pos, env.prismEntityID)
            end
        end

        --可传送阻挡实体
        local efb = env.FloatBlock[1]
        if efb then
            if not self:_CheckNextBlock(env, envList, isLoop, env) then
                --传送entity结果
                result:AddTransportEntity(efb:GetID(), env.pos, nextEnv.pos)
                --修改棋盘数据
                efb:SetGridPosition(nextEnv.pos)
                sBoard:UpdateEntityBlockFlag(efb, env.pos, nextEnv.pos)
                --队伍位置更新
                if efb:HasTeam() then
                    local pets = efb:Team():GetTeamPetEntities()
                    for i, e in ipairs(pets) do
                        e:SetGridPosition(nextEnv.pos)
                    end
                end
                --通知传送带传送一次
                sTrigger:Notify(NTTransportEachMoveEnd:New(efb, env.pos, nextEnv.pos))

                --判断下个位置的不可传送无阻挡机关被触发
                if #nextEnv.FixNoBlock > 0 then
                    toTriggerTraps[#toTriggerTraps + 1] = { nextEnv.FixNoBlock, efb }
                end
            end
        end

        --可传送无阻挡实体
        local es = env.FloatNoBlock
        if #es > 0 then
            for i, e in ipairs(es) do
                result:AddTransportEntity(e:GetID(), env.pos, nextEnv.pos)
                --修改棋盘数据
                e:SetGridPosition(nextEnv.pos)
                sBoard:UpdateEntityBlockFlag(e, env.pos, nextEnv.pos)
            end
            --下个位置的阻挡实体触发传送过去的机关
            if nextEnv.isBlock then
                local ne = nextEnv.FixBlock[1] or nextEnv.FloatBlock[1]
                if ne then
                    toTriggerTraps[#toTriggerTraps + 1] = { es, ne }
                end
            end
        end
    end

    --棱镜处理
    for i, v in ipairs(result:GetTransportPrisms()) do
        cBoard:RemovePrismPiece(v[1])
    end
    for i, v in ipairs(result:GetTransportPrisms()) do
        if v[2] then
            cBoard:AddPrismPiece(v[2], v[3])
        end
    end

    result:SetIsLoop(isLoop)
    --不循环的传送，需要创建新的
    if isLoop == 0 then
        local envIndexFirst = envList[1]
        local envIndexSecond = envList[2]
        local moveDir = envIndexSecond.pos - envIndexFirst.pos
        --划入第一个格子的坐标
        local envIndexZeroPos = envIndexFirst.pos - moveDir
        ---计算出要填充的列表
        local pieceFillTable = sBoard:SupplyPieceList({ envIndexFirst.pos })
        ---连线最后一个点是角色将要站立的目标点
        local pieceType = pieceFillTable[1].color

        if pieceType ~= envIndexFirst.pieceType then
            result:AddConvertColor(envIndexFirst.pos, envIndexFirst.pieceType, pieceType)
            --转色生效
            sBoard:SetPieceTypeLogic(pieceType, envIndexFirst.pos)
        end

        --result:AddTransportPiece(envIndexZeroPos, envIndexFirst.pos)
    end

    --触发机关
    for i, v in ipairs(toTriggerTraps) do
        self:_TriggerTraps(result, v[1], v[2])
    end
end

--触发机关
---@param result SkillEffectTransportResult
function SkillEffectCalc_Transport:_TriggerTraps(result, traps, triggerEntity)
    --机关不能触发机关
    if triggerEntity:HasTrapID() then
        return
    end

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")

    for _, e in ipairs(traps) do
        if e:HasTrapID() then
            local triggerTraps, triggerResults = trapSvc:CalcTrapTriggerSkill(e, triggerEntity)
            if triggerTraps then
                for i, trap in ipairs(triggerTraps) do
                    local skillResult = triggerResults[i]
                    result:AddTrapSkillResult(trap:GetID(), skillResult, triggerEntity:GetID())
                end
            end
        end
    end
end

--检查env的下个位置是否阻挡传送
function SkillEffectCalc_Transport:_CheckNextBlock(env, envList, isLoop, start)
    local nextEnv = self:_GetNeighboringEnv(envList, env, 1, isLoop)

    --没有下个格子被阻挡
    if not nextEnv then
        return true
    end

    if nextEnv == start then
        return false
    end

    --下个位置有阻挡信息
    if nextEnv.isBlock then
        if #env.FloatBlock > 0 then
            env.isBlock = true
        end
        return true
    end

    if #nextEnv.FloatBlock > 0 then
        return self:_CheckNextBlock(nextEnv, envList, isLoop, start)
    end

    return false
end

--拿到前后offset个格子的env
function SkillEffectCalc_Transport:_GetNeighboringEnv(envList, env, offset, isLoop)
    local total = #envList
    local envIdx = env.index
    local idx = envIdx + offset
    if idx > total and isLoop == 1 then
        idx = 1
    end

    local neighboringEnv = envList[idx]
    return neighboringEnv
end
