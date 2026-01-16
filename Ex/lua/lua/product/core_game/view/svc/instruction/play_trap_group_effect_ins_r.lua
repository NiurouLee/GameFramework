require("base_ins_r")

---播放组合机关组合标记的特效
---@class PlayTrapGroupEffectInstruction: BaseInstruction
_class("PlayTrapGroupEffectInstruction", BaseInstruction)
PlayTrapGroupEffectInstruction = PlayTrapGroupEffectInstruction

function PlayTrapGroupEffectInstruction:Constructor(paramList)
    self._effId = tonumber(paramList["effId"])
    local strRotate = paramList["rotate"]
    if strRotate then
        self._rotate = tonumber(strRotate) == 1
    else
        self._rotate = false
    end
end

function PlayTrapGroupEffectInstruction:GetCacheResource()
    local t = {}
    if self._effId and self._effId > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effId].ResPath, 1})
    end
    return t
end

---@param casterEntity Entity
function PlayTrapGroupEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type TrapRenderComponent
    local trapRenderCmpt = casterEntity:TrapRender()
    if not trapRenderCmpt then
        Log.fatal("### casterEntity is not Trap.")
        return
    end
    local groupId = trapRenderCmpt:GetGroupID()
    local mod = groupId % 10 --机关GroupID的个位数表示组合标记数，在弩车上，mod为1表示显示【Ⅰ】，2显示【Ⅱ】，3显示【Ⅲ】
    ---@type EffectService
    local effectService = world:GetService("Effect")
    local e = effectService:CreateEffect(self._effId, casterEntity)
    YIELD(TT)
    local cView = e:View()
    local go = cView:GetGameObject()
    ---@type UnityEngine.Animation
    local animation = go:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not animation then
        Log.fatal("### PlayTrapGroupEffectInstruction cant find Animation.EffectId=", self._effId)
        return
    end
    --获取前缀
    local revStr = string.reverse(animation.clip.name)
    local _, i = string.find(revStr, "_")
    local m = string.len(revStr) - i + 1
    local prefix = string.sub(animation.clip.name, 1, m)
    animation:Play(prefix .. mod)
    if self._rotate then
        self:RotateEffect(casterEntity, go)
    end
end

---@param casterEntity Entity
---@param go UnityEngine.GameObject
function PlayTrapGroupEffectInstruction:RotateEffect(casterEntity, go)
    local cGridLocation = casterEntity:GridLocation()
    local dir = cGridLocation.Direction
    if dir == Vector2(0, -1) or dir == Vector2(1, 0) then --朝下右
        go.transform.localRotation = Quaternion.Euler(0, 180, 0)
    else --朝上左
    end
end
