---@class PlayEffectWithChainMoveType
local PlayEffectWithChainMoveType = {
    Normal = 1, ---默认 菲雅
    Zhongxu = 2,---仲胥
}
_enum("PlayEffectWithChainMoveType",PlayEffectWithChainMoveType)

_class("BuffPlayEffectWithChainMoveZhongxuViewParam", Object)
---@class BuffPlayEffectWithChainMoveZhongxuViewParam : Object
BuffPlayEffectWithChainMoveZhongxuViewParam = BuffPlayEffectWithChainMoveZhongxuViewParam

function BuffPlayEffectWithChainMoveZhongxuViewParam:Constructor(cfgTb)
    if cfgTb then
        self._transAudioID = cfgTb.transAudioID

        self._transAnim = cfgTb.transAnim
        self._revertAnim = cfgTb.revertAnim

        self._transEffectID = cfgTb.transEffectID
        self._transMatAnim = cfgTb.transMatAnim
        self._revertEffectID = cfgTb.revertEffectID
        self._revertMatAnim = cfgTb.revertMatAnim

        self._catShowEffectID = cfgTb.catShowEffectID
        self._catShowMatAnim = cfgTb.catShowMatAnim
        self._catHideEffectID = cfgTb.catHideEffectID
        self._catHideMatAnim = cfgTb.catHideMatAnim
    end
end

--[[
    连线移动中释放技能，菲雅的划水表现
]]
---@class BuffLogicPlayEffectWithChainMove:BuffLogicBase
_class("BuffLogicPlayEffectWithChainMove", BuffLogicBase)
BuffLogicPlayEffectWithChainMove = BuffLogicPlayEffectWithChainMove

function BuffLogicPlayEffectWithChainMove:Constructor(buffInstance, logicParam)
    self._permanentEffectID = logicParam.permanentEffectID --永久特效
    self._pieceType = logicParam.pieceType

    self._normalEffectID = logicParam.normalEffectID --普通的移动每个格子的特效
    self._specialEffectID = logicParam.specialEffectID --转向时候的特效

    --仲胥复用 连线变猫（特效） 作为队长时开始和结束有切换表现
    self._useType = logicParam.useType or PlayEffectWithChainMoveType.Normal
    if self._useType == PlayEffectWithChainMoveType.Zhongxu then
        self._zhongxuSpecialParam = BuffPlayEffectWithChainMoveZhongxuViewParam:New(logicParam.zhongxuSpecialParam)
    end
end

function BuffLogicPlayEffectWithChainMove:DoLogic(notify)
    local notifyType = notify:GetNotifyType()
    if self._useType == PlayEffectWithChainMoveType.Zhongxu then
        --临时处理 黑拳赛敌方连线会触发本地队伍的变猫
        if self._world:GetGameTurn() == GameTurnType.RemotePlayerTurn then
            return
        end
    end
    if notifyType == NotifyType.PlayerMoveStart then
        return self:_OnPlayerMoveStart(notify)
    end
    if
        notifyType ~= NotifyType.PlayerEachMoveStart and notifyType ~= NotifyType.PlayerEachMoveEnd and
            notifyType ~= NotifyType.PetChainMoveBegin
     then
        return
    end
    local typeParam = {}
    local e = self._buffInstance:Entity()
    ---@type Entity
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPath = logicChainPathCmpt:GetLogicChainPath()

    local notifyPos = notify:GetPos()
    
    local pieceType = notify:GetPosPieceType()
    local chainPathIndex = notify:GetChainIndex()

    local isStart = (notifyPos == chainPath[1])
    local isEnd = (notifyPos == chainPath[#chainPath])

    local isMatch = self:_CheckMatchType(chainPath)
    if not isMatch then 
        return
    end
    if self._useType == PlayEffectWithChainMoveType.Normal then
        ---@type BuffComponent
        local buffComp = e:BuffComponent()
        local normalSkillBeforeMove = buffComp:GetBuffValue("NormalSkillBeforeMove")
        if not normalSkillBeforeMove then
            return
        end
    end

    local isSpecial = false
    local moveEffectID = self._normalEffectID
    if chainPathIndex > 1 and chainPathIndex < table.count(chainPath) then
        --上一步移动到当前这步的朝向
        local lastPos = chainPath[chainPathIndex - 1]
        local lastDir = notifyPos - lastPos

        --真实的下个坐标
        local nextPos = chainPath[chainPathIndex + 1]
        local curDir = nextPos - notifyPos

        local diffAngle = Vector2.Angle(lastDir, curDir)
        --四舍五入取整 精度问题
        diffAngle = math.floor(diffAngle + 0.5)

        if diffAngle >= 90 then
            isSpecial = true
            moveEffectID = self._specialEffectID
        end
    end
    --仲胥 作为队长有特殊表现
    if self._useType == PlayEffectWithChainMoveType.Zhongxu then
        if notifyType == NotifyType.PetChainMoveBegin then
            --逻辑上每个光灵开始移动会通知一次，表现上播的时候通知使用的entity都是队长，避免重复
            if notify:GetEntityID() ~= e:GetID() then
                return
            end
        else
            if notify:GetEntityID() ~= e:GetID() then--临时处理 trigger 之后改成3
                return
            end
        end
        ---@type TeamComponent
        local teamCmpt = teamEntity:Team()
        local isTeamLeader = teamCmpt:IsTeamLeaderByEntityId(e:GetID())
        typeParam.isTeamLeader = isTeamLeader
        typeParam.chainPathCount = #chainPath
        typeParam.specialParam = self._zhongxuSpecialParam
    end

    local buffResult =
        BuffResultPlayEffectWithChainMove:New(
        notifyType,
        notifyPos,
        isStart,
        isEnd,
        self._permanentEffectID,
        moveEffectID,
        self._useType,
        typeParam
    )
    return buffResult
end

function BuffLogicPlayEffectWithChainMove:_CheckMatchType(chainPath)
    if not self._pieceType then
        return true
    end
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    for index = 1,#chainPath do 
        local pos = chainPath[index]
        local gridPieceType = boardCmpt:GetPieceType(pos)
        if gridPieceType == self._pieceType then
            return true
        end
    end

    return false
end
function BuffLogicPlayEffectWithChainMove:_OnPlayerMoveStart(notify)
    local notifyType = notify:GetNotifyType()
    local typeParam = {}
    local e = self._buffInstance:Entity()
    ---@type Entity
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    local notifyPos = chainPath[1]
    local isStart = true
    local isEnd = (notifyPos == chainPath[#chainPath])
    local moveEffectID = self._normalEffectID
    --仲胥 作为队长有特殊表现
    if self._useType == PlayEffectWithChainMoveType.Zhongxu then
        ---@type TeamComponent
        local teamCmpt = teamEntity:Team()
        local isTeamLeader = teamCmpt:IsTeamLeaderByEntityId(e:GetID())
        typeParam.isTeamLeader = isTeamLeader
        typeParam.chainPathCount = #chainPath
        typeParam.specialParam = self._zhongxuSpecialParam
        local buffResult =
            BuffResultPlayEffectWithChainMove:New(
            notifyType,
            notifyPos,
            isStart,
            isEnd,
            self._permanentEffectID,
            moveEffectID,
            self._useType,
            typeParam
        )
        return buffResult
    end
end