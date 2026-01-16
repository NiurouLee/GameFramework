--[[
    变身的逻辑与表现
]]
---@class PlayTransformationInstruction:BaseInstruction
_class("PlayTransformationInstruction", BaseInstruction)
PlayTransformationInstruction = PlayTransformationInstruction

function PlayTransformationInstruction:Constructor(paramList)
end

function PlayTransformationInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Transformation)

    for i = 1, #resultArray do
        ---@type SkillTransformationEffectResult
        local result = resultArray[i]

        local caster = world:GetEntityByID(result:GetCaster())
        local elementType = result:GetElementType()
        if not caster then
            Log.fatal("没有施法者，变身失败")
            return
        end

        ---@type ConfigService
        local cfgService = world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        local monsterResPath = monsterConfigData:GetMonsterResPath(result:GetMonsterID())
        local newPos = result:GetNewPos()
        if newPos then
            caster:SetPosition(newPos)
        end
        --换模型
        caster:ReplaceAsset(NativeUnityPrefabAsset:New(monsterResPath, true))

        --显示固定特效
        ---@type MonsterShowRenderService
        local sMonsterShowRender = world:GetService("MonsterShowRender")
        sMonsterShowRender:CreateMonsterEffect(casterEntity, result:GetMonsterID())

        --血量变化
        local transformationHp = result:GetTransformationHp()
        if transformationHp ~= 0 then
            local transformationHpMax = result:GetTransformationHpMax()
            caster:ReplaceRedAndMaxHP(transformationHp, transformationHpMax)
        end

        --血条 元素
        local sliderEntityID = caster:HP():GetHPSliderEntityID()
        local sliderEntity = world:GetEntityByID(sliderEntityID)
        TaskManager:GetInstance():CoreGameStartTask(
            InnerGameHelperRender:GetInstance().SetHpSliderElementIcon,
            InnerGameHelperRender:GetInstance(),
            sliderEntity,
            elementType
        )
        ---@type UtilDataServiceShare
        local utilDataSvc =  world:GetService("UtilData")
        local hpBarType = utilDataSvc:GetHPBarTypeByEntity(caster)
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.UpdateBossNameAndElement,
            result:GetMonsterID(),
            hpBarType,
            caster:GetID()
        )
		
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossElement, elementType, caster:GetID())
    end
end
