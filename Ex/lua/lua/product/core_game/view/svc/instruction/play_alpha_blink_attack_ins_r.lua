require("base_ins_r")
---@class PlayAlphaBlinkAttackInstruction : BaseInstruction
_class("PlayAlphaBlinkAttackInstruction", BaseInstruction)
PlayAlphaBlinkAttackInstruction = PlayAlphaBlinkAttackInstruction

function PlayAlphaBlinkAttackInstruction:Constructor(paramList)
    --消失特效
    self._disappearEffID = tonumber(paramList.disappearEffID)
    self._firstDisappearTime = tonumber(paramList.firstDisappearTime) or 0
    self._appearEffID = tonumber(paramList.appearEffID)
    self._attackAni = paramList.attackAni
    self._attackEffID = tonumber(paramList.attackEffID)
    self._attackEffID2 = tonumber(paramList.attackEffID2)
    self._attackTime = tonumber(paramList.attackTime) or 0
    self._secondDisappearTime = tonumber(paramList.secondDisappearTime) or 0
end

function PlayAlphaBlinkAttackInstruction:GetCacheResource()
    local t = {}
    if self._disappearEffID and self._disappearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._disappearEffID].ResPath, 1 })
    end
    if self._appearEffID and self._appearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._appearEffID].ResPath, 1 })
    end
    if self._attackEffID and self._attackEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._attackEffID].ResPath, 1 })
    end
    if self._attackEffID2 and self._attackEffID2 > 0 then
        table.insert(t, { Cfg.cfg_effect[self._attackEffID2].ResPath, 1 })
    end
    return t
end

---@param casterEntity Entity
function PlayAlphaBlinkAttackInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectAlphaBlinkAttackResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.AlphaBlinkAttack)
    if not result then
        return
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    local trapIDList = result:GetTrapIDList()
    if trapIDList then
        local trapEntityList = {}
        for _, trapEntityID in ipairs(trapIDList) do
            local trapEntity = world:GetEntityByID(trapEntityID)
            if trapEntity then
                table.insert(trapEntityList, trapEntity)
            end
        end
        trapServiceRender:ShowTraps(TT, trapEntityList, true)
    end

    ---@type EffectService
    local effectService = world:GetService("Effect")

    ---@type RideServiceRender
    local rideRenderSvc = world:GetService("RideRender")
    if casterEntity:HasRideRender() then
        ---@type RideRenderComponent
        local rideRenderCmpt = casterEntity:RideRender()
        rideRenderSvc:RemoveRideRender(casterEntity:GetID(), rideRenderCmpt:GetMountID())
    end

    --检测是否需要第一次闪烁
    local oldPos = result:GetOldPos()
    local attackPos = result:GetAttackPos()
    local attackDir = result:GetAttackDir()
    local height = result:GetHeight()
    if oldPos ~= attackPos then
        self:Blink(TT, casterEntity, oldPos, attackPos, attackDir, self._firstDisappearTime, height)
    end

    --攻击动作及攻击特效
    casterEntity:SetAnimatorControllerTriggers({ self._attackAni })
    if self._attackEffID and self._attackEffID ~= 0 then
        effectService:CreateEffect(self._attackEffID, casterEntity)
    end
    if self._attackEffID2 and self._attackEffID2 ~= 0 then
        effectService:CreateEffect(self._attackEffID2, casterEntity)
    end
    --延时
    YIELD(TT, self._attackTime)

    --后撤
    local teleportPos = result:GetTeleportPos()
    self:Blink(TT, casterEntity, attackPos, teleportPos, attackDir, self._secondDisappearTime, height)

    if casterEntity:HasRide() then
        ---@type RideComponent
        local rideCmpt = casterEntity:Ride()
        local mountID = rideCmpt:GetMountID()
        ---@type Entity
        local mountEntity = world:GetEntityByID(mountID)
        if mountEntity:HasTrapRender() then
            rideRenderSvc:RideTrap(casterEntity:GetID(), mountID)
        elseif mountEntity:HasMonsterID() then
            rideRenderSvc:RideMonster(casterEntity:GetID(), mountID)
        end
    end
end

function PlayAlphaBlinkAttackInstruction:Blink(TT, casterEntity, oldPos, newPos, newDir, time, height)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectSvc = world:GetService("Effect")
    ---@type PlaySkillInstructionService
    local playSkillInstructionSvc = world:GetService("PlaySkillInstruction")
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")

    effectSvc:CreateWorldPositionEffect(self._disappearEffID, oldPos)

    local colorOld = utilDataSvc:FindPieceElement(oldPos)
    ---@type SkillEffectResult_Teleport
    local teleportSkillRes = SkillEffectResult_Teleport:New(
        casterEntity:GetID(),
        oldPos,
        colorOld,
        newPos,
        newDir,
        1
    )
    --消失
    playSkillInstructionSvc:Teleport(TT, casterEntity, RoleShowType.TeleportHide, false, teleportSkillRes)
    --瞬移
    playSkillInstructionSvc:Teleport(TT, casterEntity, RoleShowType.TeleportMove, false, teleportSkillRes)
    --延时
    YIELD(TT, time)
    --出现
    playSkillInstructionSvc:Teleport(TT, casterEntity, RoleShowType.TeleportShow, false, teleportSkillRes)
    --出现特效
    effectSvc:CreateWorldPositionEffect(self._appearEffID, newPos)
    --设置高度
    casterEntity:SetLocationHeight(height)
end
