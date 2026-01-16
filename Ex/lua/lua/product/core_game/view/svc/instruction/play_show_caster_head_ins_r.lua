require("base_ins_r")
---将施法星灵的头像拉出来
---@class PlayShowCasterHeadInstruction: BaseInstruction
_class("PlayShowCasterHeadInstruction", BaseInstruction)
PlayShowCasterHeadInstruction = PlayShowCasterHeadInstruction

function PlayShowCasterHeadInstruction:Constructor(paramList)
    self._isShow = paramList["isShow"]
end

---@param casterEntity Entity
function PlayShowCasterHeadInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local petPstId = 0
    --现在buff放主动技时会创建一个临时entity，来释放技能，但是要移动祖宗的头像，所以用superentity存祖宗的id
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        petPstId = casterEntity:GetSuperEntity():PetPstID():GetPstID()
    else
        petPstId = casterEntity:PetPstID():GetPstID()
    end
    if self._isShow == "1" then
        world:EventDispatcher():Dispatch(GameEventType.InOutQueue, petPstId, true)
    else
        world:EventDispatcher():Dispatch(GameEventType.InOutQueue, petPstId, false)
    end
end
