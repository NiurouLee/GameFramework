--[[
    EnterMirage = 193, --N2Boss：开启幻境
]]
---@class SkillEffectCalc_EnterMirage: Object
_class("SkillEffectCalc_EnterMirage", Object)
SkillEffectCalc_EnterMirage = SkillEffectCalc_EnterMirage

function SkillEffectCalc_EnterMirage:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EnterMirage:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)

    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    --开启幻境
    mirageSvc:SetMirageOpen()

    --设置子弹机关刷新ID：随机或固定___TODO
    ---@type SkillEffectEnterMirageParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local trapRefreshID = param:GetTrapRefreshID()
    mirageSvc:SetTrapRefreshID(trapRefreshID)
    mirageSvc:SetMirageBossEntityID(casterEntityID)

    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    local initAttributes = {}
    local inheritAttributeList = param:GetInheritAttribute()
    local isUseAttribute = param:GetUseAttribute()
    local inheritCount = (inheritAttributeList == nil) and -1 or table.count(inheritAttributeList)
    local attributeCmpt = casterEntity:Attributes()
    local bHasMonsterId = casterEntity:HasMonsterID()
    -- 如果是继承母体基础属性的召唤怪 首先按照母体基础属性设置三围 如果没有MONSTERID 就按照当前三围设置
    if (inheritCount > 0) and (bHasMonsterId or attributeCmpt ~= nil) then
        local nAttack = nil
        local nDefense = nil
        local nMaxHP = nil
        if bHasMonsterId and isUseAttribute == 0 then
            local nCasterMonsterId = casterEntity:MonsterID():GetMonsterID()
            nAttack, nDefense, nMaxHP = monsterCreationSvc:GetCreateADH(nCasterMonsterId)
        else
            nAttack = attributeCmpt:GetAttribute("Attack")
            nDefense = attributeCmpt:GetAttribute("Defense")
            nMaxHP = attributeCmpt:CalcMaxHp()
        end
        if inheritAttributeList.Attack and nAttack ~= nil then
            initAttributes["Attack"] = nAttack * inheritAttributeList.Attack
        end
        if inheritAttributeList.Defense and nDefense ~= nil then
            initAttributes["Defense"] = nDefense * inheritAttributeList.Defense
        end
        if inheritAttributeList.MaxHP and nMaxHP ~= nil then
            initAttributes["MaxHP"] = nMaxHP * inheritAttributeList.MaxHP
            initAttributes["HP"] = nMaxHP * inheritAttributeList.MaxHP
        end
    end
    -- 母体属性继承
    local inheritElement = param:GetInheritElement()
    if inheritElement then
        ---@type Entity
        local oriEntity = casterEntity
        if casterEntity:HasSuperEntity() then
            oriEntity = casterEntity:GetSuperEntity()
        end
        if oriEntity:HasAttributes() then
            ---@type AttributesComponent
            local attrCmpt = oriEntity:Attributes()
            initAttributes["Element"] = attrCmpt:GetAttribute("Element")
        end
    end

    mirageSvc:SetMirageTrapInheritAttributes(initAttributes)

    local result = SkillEffectEnterMirageResult:New()
    return result
end
