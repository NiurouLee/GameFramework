--[[-------------------------------------
    HPPosSystem_Render 血条刷新机制
    关于位置刷新
    1.每帧都会检测是否要计算血条的位置
    2.有两种时机需要计算，一个是场景主相机的推进拉远操作，一个是血条宿主的移动行为
    3.未来如果还有时机需要刷新血条位置的话，需要继续增加条件
    4.这个血条刷新是个纯表现的行为，在system的最后一波执行序列
    TODO：
    1.当前是通过查询其他组件状态，来决定是否要做计算行为
    2.理论上任何其他system里对HP组件中PosDirty字段的操作，都应该触发本system的执行
      因此假如通知血条刷新的地方比较多的话，可以考虑改为以system trigger的方式执行
--]] -------------------------------------
_class("HPPosSystem_Render", Object)
HPPosSystem_Render = HPPosSystem_Render

function HPPosSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._hpGroup = world:GetGroup(world.BW_WEMatchers.HP)

    ---@type ClientTimeService
    self._timeService = self._world:GetService("Time")
end

function HPPosSystem_Render:Execute()
    self:ExecuteEntities(self._hpGroup:GetEntities())
end

function HPPosSystem_Render:ExecuteEntities(entities)
    for i, e in ipairs(entities) do
        local refresh = self:_ShouldRefreshHPBarPos(e)
        if refresh then
            self:_UpdateHPPos(e)
        end

        ---@type HPComponent
        local hpCmpt = e:HP()
        local isDirty = hpCmpt:IsHPPosDirty()
        if isDirty then
            hpCmpt:SetHPPosDirty(false)
        end
    end
end

---是否要刷新血条位置
---@param e Entity 血条的宿主Entity
function HPPosSystem_Render:_ShouldRefreshHPBarPos(e)
    ---如果相机在变化中，需要无条件刷新血条位置
    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    if mainCameraCmpt then
        local isNormalState = mainCameraCmpt:IsNormalState()
        if not isNormalState then
            return true
        end
    end

    ---@type HPComponent
    local hpCmpt = e:HP()

    local isPosLocked = hpCmpt:IsPosLocked()
    if isPosLocked then
        Log.warn("HPPosSystem: HP bar position locked due to component data and may controlled by another logic. entity id: ", e:GetID())
        return false
    end

    --buff轮播
    local uiHpBuffInfoWidget = hpCmpt:GetUIHpBuffInfoWidget()
    if uiHpBuffInfoWidget then
        ---@type UIHPBuffInfo
        local uiHPBuffInfo = uiHpBuffInfoWidget:GetAllSpawnList()[1]
        if uiHPBuffInfo then
            local deltaTime = self._timeService:GetDeltaTime()
            uiHPBuffInfo:OnRefreshBuffTime(deltaTime)
            uiHPBuffInfo:OnCheckBuffAnimation()
        end
    end

    local isDirty = hpCmpt:IsHPPosDirty()
    return isDirty
end
---@param petEntity Entity
function HPPosSystem_Render:_UpdateHPPetPos(petEntity)
    if not petEntity:PetPstID() then
        return
    end

    if not self:_HasView(petEntity) then
        return
    end
    ---@type PetPstIDComponent
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
    --血条高度
    local hpOffset = petData:GetHPOffset()
    local hpOffSetV = Vector3(0, hpOffset, 0)
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    local slider_entity_id = teamEntity:HP():GetHPSliderEntityID()
    local slider_entity = self._world:GetEntityByID(slider_entity_id)
    local isInScreen = self:IsInScreen(petEntity)
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
    local IsVisible = self:IsVisible(teamEntity)
    ---@type HPComponent
    local hp = petEntity:HP()
    local viewEntity = petEntity
    if hp:IsUseTeamView() then
        ---@type HPComponent
        local hpCmpt = teamLeaderEntity:HP()
        local hp_offset = hpCmpt:GetHPOffset()
        hpOffSetV = hp_offset
        viewEntity = teamLeaderEntity
    end
    hp:ResetUseTeamViewState()
    self:__UpdateHPPos(slider_entity,IsVisible,isInScreen,hpOffSetV,viewEntity)
end

function HPPosSystem_Render:IsInScreen(e)
    local mainCamera = self._world:MainCamera():Camera()
    local isInScreen = true
    local v3RenderPos = e:GetPosition()
    if v3RenderPos then
        local viewpoint = mainCamera:WorldToViewportPoint(v3RenderPos)
        isInScreen = viewpoint.x > 0 and viewpoint.x < 1 and viewpoint.y > 0 and viewpoint.y < 1
    end
    return isInScreen
end

function HPPosSystem_Render:IsVisible(e)
    ---@type HPComponent
    local hpCmpt = e:HP()
    local isVisible = hpCmpt:IsShowHPSlider() and (not hpCmpt:IsHPBarTempHide())
    return isVisible
end

function HPPosSystem_Render:_UpdateHPPos_Other(e)
    local slider_entity_id = e:HP():GetHPSliderEntityID()
    local slider_entity = self._world:GetEntityByID(slider_entity_id)

    if not slider_entity then
        return
    end

    local isInScreen = self:IsInScreen(e)
    local isVisible = self:IsVisible(e)

    ---@type HPComponent
    local hpCmpt = e:HP()
    local hp_offset = hpCmpt:GetHPOffset()
    self:__UpdateHPPos(slider_entity,isVisible,isInScreen,hp_offset,e)
end
---套娃函数不知道叫啥
function HPPosSystem_Render:__UpdateHPPos(slider_entity,isVisible,isInScreen,hp_offset,e)
    if not slider_entity then
        return
    end
    if isVisible and isInScreen then
        local hasView = self:_HasView(e)
        if hasView then
            self:_RefreshGameObject(e, slider_entity, hp_offset)
        end

        slider_entity:View().ViewWrapper.GameObject:SetActive(isVisible)
    else
        slider_entity:View().ViewWrapper.GameObject:SetActive(false)
    end
end

---@param e Entity
function HPPosSystem_Render:_UpdateHPPos(e)
    if e:HasPetPstID() then
        self:_UpdateHPPetPos(e)
    else
        self:_UpdateHPPos_Other(e)
    end


    --local slider_entity_id = e:HP():GetHPSliderEntityID()
    --local slider_entity = self._world:GetEntityByID(slider_entity_id)
    --
    --if not slider_entity then
    --    return
    --end
    --
    --local mainCamera = self._world:MainCamera():Camera()
    --local isInScreen = true
    --local v3RenderPos = e:GetPosition()
    --if v3RenderPos then
    --    local viewpoint = mainCamera:WorldToViewportPoint(v3RenderPos)
    --    isInScreen = viewpoint.x > 0 and viewpoint.x < 1 and viewpoint.y > 0 and viewpoint.y < 1
    --end
    --
    -----@type HPComponent
    --local hpCmpt = e:HP()
    --local isVisible = hpCmpt:IsShowHPSlider() and (not hpCmpt:IsHPBarTempHide())
    --if isVisible and isInScreen then
    --    local hp_offset = hpCmpt:GetHPOffset()
    --    --Log.fatal("hpOffset:",hp_offset.x,hp_offset.y,hp_offset.z)
    --    local  entity = e
    --
    --    if e:HasTeam() and hpCmpt:IsUseTeamView() then
    --        local teamLeaderEntity = e:GetTeamLeaderPetEntity()
    --        entity = teamLeaderEntity
    --        hpCmpt:ResetUseTeamViewState()
    --    end
    --    local hasView = self:_HasView(entity)
    --    if hasView then
    --        local viewWrapper = entity:View().ViewWrapper
    --        self:_RefreshGameObject(entity, slider_entity, hp_offset,viewWrapper)
    --    end
    --
    --    slider_entity:View().ViewWrapper.GameObject:SetActive(isVisible)
    --else
    --    slider_entity:View().ViewWrapper.GameObject:SetActive(false)
    --end
end


---@param entity Entity
---@param slider_entity Entity
function HPPosSystem_Render:_RefreshGameObject(entity, slider_entity, hp_offset)
    local hasView = self:_HasView(entity)
    if hasView then
        ---@type RenderBattleService
        local renderBattleService = self._world:GetService("RenderBattle")
        local owner_entity_render_pos = renderBattleService:CalcHPBarPos(entity:View().ViewWrapper, hp_offset)

        local canvasTrans = slider_entity:View().ViewWrapper:FindChild("Root")
        canvasTrans.position = owner_entity_render_pos
    else
        --Log.notice("holder has no view")
    end
end

function HPPosSystem_Render:_HasView(e)
    local viewCmpt = e:View()
    if viewCmpt == nil then
        return false
    end

    local gameObj = viewCmpt:GetGameObject()
    if gameObj == nil then
        return false
    end

    return true
end



---@param viewWrapper UnityViewWrapper
function HPPosSystem_Render:_CalcSkinnedMeshPos(viewWrapper, hp_offset)
    local ownerObj = viewWrapper.GameObject
    local rootObj = nil
    local rootTransform = viewWrapper:FindChild("Root")
    if rootTransform then
        rootObj = rootTransform.gameObject
    else
        rootObj = viewWrapper.GameObject
    end

    local owner_entity_render_pos = rootObj.transform.position

    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    local skinnedMeshRender, meshExtents = renderBattleService:FindFirstSkinedMeshRender(rootObj)
    if skinnedMeshRender ~= nil then
        local skinnedMeshPosition = skinnedMeshRender.transform.position + hp_offset
        local convertExtents = Vector3(0, meshExtents.x * 2, 0)
        local targetPos = skinnedMeshPosition + convertExtents
        --Log.fatal("ownObj",ownerObj.name," pos",skinnedMeshPosition.x,skinnedMeshPosition.y,skinnedMeshPosition.z," meshExtents ",meshExtents.x," ",meshExtents.y," ",meshExtents.z)

        owner_entity_render_pos = renderBattleService:CalcGridHUDWorldPos(targetPos)
    else
        local meshRenderer = renderBattleService:GetMeshRendererInChildren(ownerObj)
        if meshRenderer then
            local meshPosition = owner_entity_render_pos + hp_offset
            owner_entity_render_pos = renderBattleService:CalcGridHUDWorldPos(meshPosition)
        else
            Log.fatal("ownerObj", ownerObj.name, "has no skinned mesh and mesh")
        end
    end

    return owner_entity_render_pos
end
