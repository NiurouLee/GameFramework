--[[------------------------------------------------------------------------------------------
    LogicEntityService 处理实体的公共服务对象
    此对象也会封装一些创建类型Entity的函数
]] --------------------------------------------------------------------------------------------
require "entity_svc_l"
_class("LogicEntityServiceMaze", LogicEntityService)
---@class LogicEntityServiceMaze:LogicEntityService
LogicEntityServiceMaze = LogicEntityServiceMaze

---@param entity Entity
---@param petData Pet
function LogicEntityServiceMaze:_InitPetAttributes(entity, petData, maxCastPower)
    local maxhp = petData:GetPetHealth()
    local hp = petData:GetPetCurHealth()
    local attack = petData:GetPetAttack()
    local defense = petData:GetPetDefence()
    local power = petData:GetPetPower()
    local legendPower = petData:GetPetLegendPower()
    local afterDamage = petData:GetAfterDamage()
    local ready = 0
    if power == -1 then
        power = maxCastPower
    end
    if power == 0 then
        ready = 1
    end
    --装备提供的属性克制系数
    local exElementParam = petData:GetPropertyRestraint()

    ---@type AttributesComponent
    local attributeComponent = entity:Attributes()

    attributeComponent:Modify("Attack", attack)
    attributeComponent:Modify("Defense", defense)
    attributeComponent:Modify("MaxPower", maxCastPower)
    attributeComponent:Modify("Power", power)
    attributeComponent:Modify("LegendPower", legendPower)
    attributeComponent:Modify("Ready", ready)
    attributeComponent:Modify("HP", hp)
    attributeComponent:Modify("MaxHP", maxhp)
    attributeComponent:Modify("AfterDamage", afterDamage)
    attributeComponent:Modify("ExElementParam", exElementParam)

    --附加技出cd初始化
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraActiveSkill = petData:GetPetExtraActiveSkill()
    if extraActiveSkill and #extraActiveSkill > 0 then
        ---@type ConfigService
        local configService = self._configService
        for index, extraSkillID in ipairs(extraActiveSkill) do
            --附加技能
            ---@type SkillConfigData
            local activeSkillConfigData = configService:GetSkillConfigData(extraSkillID)
            if activeSkillConfigData then
                local skillTriggerType = activeSkillConfigData:GetSkillTriggerType()
                if skillTriggerType == SkillTriggerType.Energy then
                    local skillTriggerParam = activeSkillConfigData:GetSkillTriggerParam()
                    utilData:SetPetMaxPowerAttr(entity, skillTriggerParam, extraSkillID)
                    utilData:SetPetPowerAttr(entity, skillTriggerParam, extraSkillID)
                    local extraReady = 0
                    if skillTriggerParam == 0 then
                        extraReady = 1
                    end
                    utilData:SetPetSkillReadyAttr(entity, extraReady, extraSkillID)
                end
            end
        end
    end
    
    return hp,maxhp,defense
end
