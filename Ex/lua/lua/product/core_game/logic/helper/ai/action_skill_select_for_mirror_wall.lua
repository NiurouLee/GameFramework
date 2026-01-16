--[[------------------------------------------------
    ActionSkillSelectForMirrorWall 根据回合数选择技能 映镜BOSS的墙壁特制Ai！！！ 不同位置的墙壁死亡后选择不同技能预览
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionSkillSelectForMirrorWall:AINewNode
_class("ActionSkillSelectForMirrorWall", AINewNode)
ActionSkillSelectForMirrorWall = ActionSkillSelectForMirrorWall

function ActionSkillSelectForMirrorWall:Constructor()
    self._skillListIndex = 1
    self._skillID = 0
    self.m_nDefaultSkillIndex = 0
    self.m_nSkillListCount = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionSkillSelectForMirrorWall:InitializeNode(cfg, context, parentNode, configData)
    ActionSkillSelectForMirrorWall.super.InitializeNode(self, cfg, context, parentNode, configData)
    --检查的buff
    self._buffID = configData[1]

    --目标AI
    self._targetAI = configData[2]

    --目标坐标
    self._targetPos = configData[3]
end
function ActionSkillSelectForMirrorWall:Update()
    local vecSkillList = self:GetConfigSkillList()

    local buffCmp = self.m_entityOwn:BuffComponent()
    local buffInstance = buffCmp:GetBuffById(self._buffID)
    if buffInstance then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()

        --获取存活目标
        local targetGroupEntities = {}
        local targetMonsterPos = {}
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)

        for _, e in ipairs(monsterGroup:GetEntities()) do
            local monsterID = e:MonsterID():GetMonsterID()
            local monsterAIIDList = monsterConfigData:GetMonsterAIID(monsterID)
            if monsterAIIDList[1][1] == self._targetAI and not e:HasDeadMark() and not e:HasDeadMark() then
                table.insert(targetGroupEntities, e)
                table.insert(targetMonsterPos, e:GetGridPosition())
            end
        end

        --4个墙都存活
        if #targetGroupEntities == 4 then
            self._skillID = vecSkillList[1][1]
        else
            --那个位置的墙死亡 使用2-几的技能
            local deadMonsterIndex = 0

            for i = 1, #self._targetPos do
                local pos = self._targetPos[i]
                local hadThisPos = false
                for _, monsterPos in ipairs(targetMonsterPos) do
                    if monsterPos.x == pos.x and monsterPos.y == pos.y then
                        hadThisPos = true
                        break
                    end
                end

                if hadThisPos == false then
                    deadMonsterIndex = i
                    break
                end
            end

            self._skillID = vecSkillList[2][deadMonsterIndex]
        end
    else
        --没有buff的显示不带范围的技能
        self._skillID = vecSkillList[3][1]
    end

    return AINewNodeStatus.Success
end

function ActionSkillSelectForMirrorWall:GetActionSkillID()
    return self._skillID
end
