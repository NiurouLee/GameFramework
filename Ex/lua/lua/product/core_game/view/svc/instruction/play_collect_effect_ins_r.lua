require("base_ins_r")

---收集时的飞行特效，与收集文本更新
---@class PlayCollectEffectInstruction: BaseInstruction
_class("PlayCollectEffectInstruction", BaseInstruction)
PlayCollectEffectInstruction = PlayCollectEffectInstruction

function PlayCollectEffectInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCollectEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local arrResult = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddCollectDropNum)
    if not arrResult or not casterEntity:View() then
        return
    end
    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local maxCollect = levelConfigData:GetLevelCollectItem() --提取当前关卡的掉落胜利数

    for index, value in ipairs(arrResult) do
        local dropWorldPos = casterEntity:View():GetGameObject().transform.position
        local dropUIWorldPos = self:_CalcUIWorldPos(world, dropWorldPos + Vector3(0, 0.5, 0))
        world:EventDispatcher():Dispatch(GameEventType.ShowCollectDropInfo, dropUIWorldPos)
    end
end

---@param world MainWorld
function PlayCollectEffectInstruction:_CalcUIWorldPos(world, dropPos)
    local camera = world:MainCamera():Camera()
    local screenPos = camera:WorldToScreenPoint(dropPos)
    local uiCam = GameGlobal.UIStateManager():GetControllerCamera("UIBattle")
    local UIWorldPos = uiCam:ScreenToWorldPoint(screenPos)
    return Vector2(UIWorldPos.x, UIWorldPos.y)
end
