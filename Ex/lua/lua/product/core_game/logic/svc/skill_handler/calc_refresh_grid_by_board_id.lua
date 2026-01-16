--[[
    RefreshGridByBoardID = 205, ---N30Boss_斐桀洛 三技能：根据配置的地板ID来刷新格子，并删除镂空机关
]]
---@class SkillEffectCalc_RefreshGridByBoardID: Object
_class("SkillEffectCalc_RefreshGridByBoardID", Object)
SkillEffectCalc_RefreshGridByBoardID = SkillEffectCalc_RefreshGridByBoardID

function SkillEffectCalc_RefreshGridByBoardID:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_RefreshGridByBoardID:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectRefreshGridByBoardIDParam
    local param = skillEffectCalcParam.skillEffectParam
    local boardID = param:GetBoardID()

    ---@type SkillEffectRefreshGridByBoardIDResult
    local result = SkillEffectRefreshGridByBoardIDResult:New()

    ---获取所有的机关，并销毁
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, trap in ipairs(trapGroup:GetEntities()) do
        if not trap:HasDeadMark() then
            trap:Attributes():Modify("HP", 0)

            --关闭死亡技能
            local disableDieSkill = true
            trapSvc:AddTrapDeadMark(trap, disableDieSkill)

            result:AddDestroyTrapEntityIDList(trap:GetID())
        end
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type LogicEntityService
    local logicEntitySvc = self._world:GetService("LogicEntity")
    logicEntitySvc:GenerateBoardDataByID(boardID, teamEntity)

    ---取格子数据
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local gridPieceData = utilDataSvc:GetReplicaGridEntityData()
    result:SetGridPieceData(gridPieceData)

    ---计数
    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()
    battleFlags:AddSceneChangeTimes(1)
    local changeTimes = battleFlags:GetSceneChangeTimes()
    result:SetSceneChangeTimes(changeTimes)
    
    return { result }
end
