--[[------------------------------------------------------------------------------------------
    AssetComponent
]]
--------------------------------------------------------------------------------------------
---@class AssetComponent:Object
_class("AssetComponent", Object)
AssetComponent = AssetComponent

function AssetComponent:Constructor(detail)
    self.AssetDetail = detail
end

function AssetComponent:Dispose()
    self.AssetDetail = nil
end

function AssetComponent:GetResPath()
    return self.AssetDetail:GetResPath()
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return AssetComponent
function Entity:Asset()
    return self:GetComponent(self.WEComponentsEnum.Asset)
end

function Entity:HasAsset()
    return self:HasComponent(self.WEComponentsEnum.Asset)
end

function Entity:AddAsset(detail)
    local index = self.WEComponentsEnum.Asset
    local component = AssetComponent:New(detail)
    self:AddComponent(index, component)
end

function Entity:ReplaceAsset(detail)
    local index = self.WEComponentsEnum.Asset
    local component = AssetComponent:New(detail)
    self:ReplaceComponent(index, component)
    self:AddViewSync()
end

function Entity:RemoveAsset()
    if self:HasAsset() then
        self:RemoveComponent(self.WEComponentsEnum.Asset)
    end
end

---@param e Entity
function Entity:AddViewSync()
    local world = self:GetOwnerWorld()
    ---@type ResourcesPoolService
    local resServ = world.BW_Services.ResourcesPool
    if self:HasView() then
        resServ:DestroyView(self:View().ViewWrapper)
    end
    self:Asset().AssetDetail:GenerateView(resServ, Entity.OnViewCreated, self, self)
end

---@param e Entity
---@param viewWrapper UnityViewWrapper
function Entity:OnViewCreated(e, viewWrapper)
    if viewWrapper then
        e:ReplaceView(viewWrapper)
        local world = self:GetOwnerWorld()
        ---@type TrapServiceRender
        local trapRenderSvc = world:GetService("TrapRender")

        ---@type EntityTypeComponent
        local entityTypeCmp = e:EntityType()
        if entityTypeCmp and not trapRenderSvc:IsRuneTrap(e) then
            local entityType = entityTypeCmp.Value
            if EntityTypeHelper:GetInstance():IsBulletTimeEffectEntity(entityType) then
                local fadeMonoCmpt = viewWrapper.GameObject:GetComponent(typeof(FadeComponent))
                if not fadeMonoCmpt then
                    viewWrapper.GameObject:AddComponent(typeof(FadeComponent))
                end
            end

            local isMonsterNeedMaterialAnimation = self:CheckMaterialAnimationCmptByEntityProperty(e)
            if EntityTypeHelper:GetInstance():NeedMaterialAnimation(entityType)
                and isMonsterNeedMaterialAnimation then
                local matAnimMonoCmpt = viewWrapper.GameObject:GetComponent(typeof(MaterialAnimation))
                if matAnimMonoCmpt then
                    UnityEngine.Object.Destroy(matAnimMonoCmpt)
                end
                matAnimMonoCmpt = viewWrapper.GameObject:AddComponent(typeof(MaterialAnimation))

                ---关闭某些材质动画的应用标记
                local disable = self:NeedDisableMaterialAnimationFlag(e)
                if disable then
                    matAnimMonoCmpt.isApplyAllRenders = false
                end

                e:RemoveMaterialAnimationComponent()

                --通用材质动画
                ---@type ResourcesPoolService
                local resServ = world.BW_Services.ResourcesPool
                local container = resServ:LoadAsset("globalShaderEffects.asset")
                assert(container)
                e:AddMaterialAnimationComponent(container, matAnimMonoCmpt)
                --特殊配置的材质动画
                local shaderEffect = self:OnGetSpecialShaderEffect(e)
                if shaderEffect then
                    local containerShaderEffect = resServ:LoadAsset(shaderEffect)
                    if not containerShaderEffect then
                        local respool = world.BW_Services.ResourcesPool
                        respool:CacheAsset(shaderEffect, 1)
                        containerShaderEffect = resServ:LoadAsset(shaderEffect)
                    end
                    assert(containerShaderEffect, shaderEffect)
                    e:MaterialAnimationComponent():LoadContainer(containerShaderEffect)
                end
                local subShaderEffect = self:OnGetSubSpecialShaderEffect(e)
                if subShaderEffect then
                    for _, effCfg in ipairs(subShaderEffect) do
                        local nodeName = effCfg.node
                        local nodeGo = nil
                        ---@type UnityEngine.Transform
                        local nodeRect = GameObjectHelper.FindChild(viewWrapper.GameObject.transform, nodeName)
                        --local nodeRect = viewWrapper:FindChild(nodeName)
                        if nodeRect then
                            nodeGo = nodeRect.gameObject
                        end
                        if nodeGo then
                            local matAnimMonoCmpt = nodeGo:GetComponent(typeof(MaterialAnimation))
                            if matAnimMonoCmpt then
                                UnityEngine.Object.Destroy(matAnimMonoCmpt)
                            end
                            matAnimMonoCmpt = nodeGo:AddComponent(typeof(MaterialAnimation))

                            local resName = effCfg.res
                            local containerShaderEffect = resServ:LoadAsset(resName)
                            if not containerShaderEffect then
                                local respool = world.BW_Services.ResourcesPool
                                respool:CacheAsset(resName, 1)
                                containerShaderEffect = resServ:LoadAsset(resName)
                            end
                            assert(containerShaderEffect)
                            e:MaterialAnimationComponent():AddSubMaterialAnimation(nodeName, matAnimMonoCmpt)
                            e:MaterialAnimationComponent():SubLoadContainer(nodeName, containerShaderEffect)
                        end
                    end
                end
            end

            if APPVER130 then
                if entityType == EntityType.Monster or entityType == EntityType.CutsceneMonster then
                    ---QA：MSG57883 精英词缀显示效果优化
                    ---精英词条没配置特效列表，则使用原精英材质动画
                    local eliteEffIDList = self:OnGetEliteEffIDList(e)
                    if #eliteEffIDList == 0 then
                        --特殊配置的材质动画
                        local trailEffect = self:OnGetTrailEffect(e)
                        -- local trailEffect = "eff_jingying_01.asset"

                        local trailEffectExCmpt =
                            viewWrapper.GameObject.transform:Find("Root").gameObject:GetComponent(
                                typeof(TrailsFX.TrailEffectEx)
                            )
                        if trailEffectExCmpt then
                            UnityEngine.Object.Destroy(trailEffectExCmpt)
                        end
                        e:RemoveTrailEffectEx()

                        if trailEffect then
                            trailEffectExCmpt =
                                viewWrapper.GameObject.transform:Find("Root").gameObject:AddComponent(
                                    typeof(TrailsFX.TrailEffectEx)
                                )

                            local resServ = world.BW_Services.ResourcesPool
                            local containerTrailEffect = resServ:LoadAsset(trailEffect)
                            if not containerTrailEffect then
                                resServ:CacheAsset(trailEffect, 1)
                                containerTrailEffect = resServ:LoadAsset(trailEffect)
                            end
                            assert(containerTrailEffect)

                            e:AddTrailEffectEx(containerTrailEffect, trailEffectExCmpt)
                        end
                    end
                end
            end
            if e:HasMonsterID() and self._world:MatchType() == MatchType.MT_Chess then
                local resServ = world.BW_Services.ResourcesPool
                local containerN15MateEffect = resServ:LoadAsset(BattleConst.N15MaterialAnimAsset)
                if not containerN15MateEffect then
                    resServ:CacheAsset(BattleConst.N15MaterialAnimAsset, 1)
                    containerN15MateEffect = resServ:LoadAsset(BattleConst.N15MaterialAnimAsset)
                end
                assert(containerN15MateEffect)
                e:MaterialAnimationComponent():AddContainer(containerN15MateEffect)
                ---@type OutlineComponent
                local outlineCmpt = viewWrapper.GameObject:GetComponent(typeof(OutlineComponent))
                if not outlineCmpt then
                    outlineCmpt = viewWrapper.GameObject:AddComponent(typeof(OutlineComponent))
                end

                outlineCmpt.enabled = false
            end
        end
    else
        e:RemoveView()
    end
end

function Entity:OnGetSpecialShaderEffect(e)
    local shaderEffect = nil
    if e:HasPetPstID() then
        local templateid = e:PetPstID():GetTemplateID()
        local cfg_pet = Cfg.cfg_pet[templateid]
        shaderEffect = cfg_pet.ShaderEffect
    elseif e:HasMonsterID() and not e:HasGhost() and not e:HasGuideGhost() then
        local cfg_monster = Cfg.cfg_monster[e:MonsterID():GetMonsterID()]
        local cfg_monster_class = Cfg.cfg_monster_class[cfg_monster.ClassID]
        shaderEffect = cfg_monster_class.ShaderEffect
    elseif e:TrapRender() then
        local cfg_trap = Cfg.cfg_trap[e:TrapRender():GetTrapID()]
        shaderEffect = cfg_trap.ShaderEffect
    end

    return shaderEffect
end

function Entity:OnGetSubSpecialShaderEffect(e)
    local shaderEffect = nil
    if e:HasPetPstID() then
        local templateid = e:PetPstID():GetTemplateID()
        local cfg_pet = Cfg.cfg_pet[templateid]
        shaderEffect = cfg_pet.SubShaderEffect
    elseif e:HasMonsterID() and not e:HasGhost() and not e:HasGuideGhost() then
        local cfg_monster = Cfg.cfg_monster[e:MonsterID():GetMonsterID()]
        local cfg_monster_class = Cfg.cfg_monster_class[cfg_monster.ClassID]
        shaderEffect = cfg_monster_class.SubShaderEffect
    elseif e:Trap() then
        local cfg_trap = Cfg.cfg_trap[e:TrapRender():GetTrapID()]
        shaderEffect = cfg_trap.SubShaderEffect
    end
    return shaderEffect
end

function Entity:OnGetTrailEffect(e)
    local trailEffect = nil
    if e:HasMonsterID() and not e:HasGhost() and not e:HasGuideGhost() then
        local cfg_monster = Cfg.cfg_monster[e:MonsterID():GetMonsterID()]
        local cfg_monster_class = Cfg.cfg_monster_class[cfg_monster.ClassID]
        local eliteIDs = cfg_monster.EliteID
        if eliteIDs and table.count(eliteIDs) > 0 then
            trailEffect = cfg_monster_class.TrailEffect
        end
    end

    return trailEffect
end

---@param e Entity
function Entity:OnGetEliteEffIDList(e)
    local idList = {}
    if e:HasMonsterID() and not e:HasGhost() and not e:HasGuideGhost() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = e:MonsterID()
        if monsterIDCmpt then
            local eliteIDs = monsterIDCmpt:GetEliteIDArray()
            for _, eliteID in ipairs(eliteIDs) do
                local cfgElite = Cfg.cfg_monster_elite[eliteID]
                if cfgElite and cfgElite.EffectID then
                    table.insert(idList, cfgElite.EffectID)
                end
            end
        end
    end

    return idList
end

---@param e Entity 关闭材质动画标记
function Entity:NeedDisableMaterialAnimationFlag(e)
    ---@type MonsterIDComponent
    local monsterIDCmpt = e:MonsterID()
    if monsterIDCmpt then
        local monsterClassID = monsterIDCmpt:GetMonsterClassID()
        local needDisable = table.icontains(BattleConst.DisableMonsterClassIDList, monsterClassID)
        return needDisable
    end

    return false
end

function Entity:CheckMaterialAnimationCmptByEntityProperty(e)
    ---@type MonsterIDComponent
    local monsterIDCmpt = e:MonsterID()
    if not monsterIDCmpt then
        return true
    end

    local monsterClassID = monsterIDCmpt:GetMonsterClassID()
    local inList = table.icontains(BattleConst.MonsterDontNeedMaterialAnimationClassIDList, monsterClassID)
    if inList then
        return false
    else
        return true
    end
end
