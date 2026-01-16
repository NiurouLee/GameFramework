require("base_ins_r")
---@class PlayCasterChangeToMonsterInstruction: BaseInstruction
_class("PlayCasterChangeToMonsterInstruction", BaseInstruction)
PlayCasterChangeToMonsterInstruction = PlayCasterChangeToMonsterInstruction

function PlayCasterChangeToMonsterInstruction:Constructor(paramList)
    self._monsterID = tonumber(paramList["monsterID"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterChangeToMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type ConfigService
    local configService = world:GetService("Config")

    --替换模型
    local resPath = configService:GetMonsterConfigData():GetMonsterResPath(self._monsterID)
    casterEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath, true))

    casterEntity:SetLocation(
        casterEntity:GetGridPosition() + casterEntity:GetGridOffset(),
        casterEntity:GetGridDirection()
    )

    --显示固定特效
    ---@type MonsterShowRenderService
    local sMonsterShowRender = world:GetService("MonsterShowRender")
    sMonsterShowRender:CreateMonsterEffect(casterEntity, self._monsterID)
end
