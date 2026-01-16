require("base_ins_r")
---@class PlayCasterLineToPickGridEffInstruction: BaseInstruction
_class("PlayCasterLineToPickGridEffInstruction", BaseInstruction)
PlayCasterLineToPickGridEffInstruction = PlayCasterLineToPickGridEffInstruction

function PlayCasterLineToPickGridEffInstruction:Constructor(paramList)
    --连线相关
    self._lineOnCaster = paramList["lineOnCaster"]
    self._lineOnEffect = paramList["lineOnEffect"]
    self._lineEffectID = tonumber(paramList["lineEffectID"])
    self._lineEffectDelay = tonumber(paramList["lineEffectDelay"])
    self._lineEffectDuration = tonumber(paramList["lineEffectDuration"])


    --格子特效相关
    self._gridEffectID = tonumber(paramList["gridEffectID"])
    self._pickUpIndex = tonumber(paramList["pickUpIndex"])
    self._pickEffDirX = 0
    self._pickEffDirY = 1
    if paramList["pickEffDirX"] then
        self._pickEffDirX = tonumber(paramList["pickEffDirX"])
    end
    if paramList["pickEffDirY"] then
        self._pickEffDirY = tonumber(paramList["pickEffDirY"])
    end

    self._dirOnPickup = tonumber(paramList["dirOnPickup"]) or 0
end

---@param casterEntity Entity
function PlayCasterLineToPickGridEffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")

    --播格子特效
    local gridEff = self:_PlayGridEffect(casterEntity)
    if not gridEff then
        return
    end
    --等待一帧才有View()
    --YIELD(TT)

    --连线点 施法者身上的绑点
    local targetRoot = GameObjectHelper.FindChild(casterEntity:View().ViewWrapper.GameObject.transform, self._lineOnCaster)
    if not targetRoot then
        return
    end
    do
        local entity = gridEff
        ---@type EffectLineRendererComponent
        local effectLineRenderer = entity:EffectLineRenderer()
        entity:SetViewVisible(true)
        --if entity:IsViewVisible() then
        if true then
            local entityViewRoot = entity:View().ViewWrapper.GameObject.transform
            local curRoot = GameObjectHelper.FindChild(entityViewRoot, self._lineOnEffect)

            --找的到目标点菜添加组件
            if curRoot then
                --添加EffectLineRenderer组件
                if not effectLineRenderer then
                    entity:AddEffectLineRenderer()
                    effectLineRenderer = entity:EffectLineRenderer()
                end

                ---@type EffectHolderComponent
                local effectHolderCmpt = entity:EffectHolder()
                if not effectHolderCmpt then
                    entity:AddEffectHolder()
                    effectHolderCmpt = entity:EffectHolder()
                end

                local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[self._lineEffectID]
                local effect
                if effectEntityIdList then
                    effect = world:GetEntityByID(effectEntityIdList[1])
                end

                if not effect then
                    --需要创建连线特效
                    effect = effectService:CreateEffect(self._lineEffectID, entity)
                    effectHolderCmpt:AttachPermanentEffect(effect:GetID())
                end

                --等待一帧才有View()
                --YIELD(TT)

                --获取特效GetGameObject上面的LineRenderer组件
                local go = effect:View():GetGameObject()
                local renderers
                renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)
                for i = 0, renderers.Length - 1 do
                    local line = renderers[i]
                    if line then
                        line.gameObject:SetActive(true)
                    end
                end

                effectLineRenderer:InitEffectLineRenderer(
                    casterEntity:GetID(),
                    curRoot,
                    targetRoot,
                    entityViewRoot,
                    renderers,
                    effect:GetID()
                )
                effectLineRenderer:SetIgnoreEntityViewRootPos(true)
                YIELD(TT,self._lineEffectDelay)
                effectLineRenderer:SetEffectLineRendererShow(casterEntity:GetID(), true)
                YIELD(TT,self._lineEffectDuration)
                effectLineRenderer:SetEffectLineRendererShow(casterEntity:GetID(), false)
                local lineEffectID = effectLineRenderer:GetEffectLineRendererEffectID(casterEntity:GetID())
                if effectHolderCmpt then
                    local effectList = effectHolderCmpt:GetPermanentEffect()
                    for i, eff in ipairs(effectList) do
                        if lineEffectID and lineEffectID == eff then
                            local e = world:GetEntityByID(eff)
                            if e and e:HasView() then
                                local go = e:View():GetGameObject()
                                local renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)
                                for i = 0, renderers.Length - 1 do
                                    local line = renderers[i]
                                    if line then
                                        line.gameObject:SetActive(false)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

---@param casterEntity Entity
function PlayCasterLineToPickGridEffInstruction:_PlayGridEffect(casterEntity)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local sEffect = world:GetService("Effect")
    local dir = Vector2(self._pickEffDirX, self._pickEffDirY)

    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    if not renderPickUpComponent then
        return
    end
    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local v2PickupPos = pickUpGridArray[self._pickUpIndex]

    if self._dirOnPickup ~= 0 then
        dir = v2PickupPos - casterEntity:GetGridPosition()
    end

    local effectEntity = sEffect:CreateWorldPositionDirectionEffect(self._gridEffectID, v2PickupPos, dir)
    return effectEntity
end
