--[[------------------------------------------------------------------------------------------
    MaterialFlashSystem_Render : 敌人在攻击范围内 通过材质颜色变化实现闪烁效果
]] --------------------------------------------------------------------------------------------

---@class MaterialFlashSystem_Render: ReactiveSystem
_class("MaterialFlashSystem_Render", ReactiveSystem)

function MaterialFlashSystem_Render:Constructor(world)
    self.world = world
    self.group = world:GetGroup(world.BW_WEMatchers.MaterialFlash)
    self.timeService = self.world:GetService("Time")
    ---@type table<Entity, table<int, UnityEngine.Material>>
    self.matDic = {}
    ---@type table<UnityEngine.Material, Color>
    self.OrgColrDic = {}

    self.FlashShaderColorNameDic = {}
    -- self.FlashShaderColorNameDic["GuYin/Toon_Outline_MatCap_Smooth"] = "_ColorScale"
    -- self.FlashShaderColorNameDic["GuYin/Toon_Outline_MatCap_Smooth_Scroll"] = "_ColorScale"
    self.FlashShaderColorNameDic["H3D/Actor/Matcap-Standard"] = "_Color"

    self._useDetail = "DETAIL_ON"

    self.flashColor = Color.white --Color.yellow
    self.flashColorRatio = 1
    self.towardMax = false
    self.flashColorRatioMax = 1
    self.flashColorRatioMin = 0.9
end

function MaterialFlashSystem_Render:GetTrigger(world)
    local c = Collector:New({world:GetGroup(world.BW_WEMatchers.MaterialFlash)}, {"AddedOrRemoved"})
    return c
end

---@param entity Entity
function MaterialFlashSystem_Render:Filter(entity)
    return true
end

function MaterialFlashSystem_Render:Execute()
    MaterialFlashSystem_Render.super.Execute(self)
    if self.towardMax then
        self.flashColorRatio = self.flashColorRatio + self.timeService:GetDeltaTime()
        if self.flashColorRatio >= self.flashColorRatioMax then
            self.flashColorRatio = self.flashColorRatioMax
            self.towardMax = false
        end
    else
        self.flashColorRatio = self.flashColorRatio - self.timeService:GetDeltaTime()
        if self.flashColorRatio <= self.flashColorRatioMin then
            self.flashColorRatio = self.flashColorRatioMin
            self.towardMax = true
        end
    end
    self.group:HandleForeach(self, self.HandleUpdateFlash)
end

function MaterialFlashSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local e = entities[i]
        self:HandleEntity(e)
    end
end

---entity新增及删除MaterialFlash组件
---@param e Entity
function MaterialFlashSystem_Render:HandleEntity(e)
    if e:HasMaterialFlash() then
        local matList = {}
        if e:HasView() then
            self:GetMatList(e, matList)
        end
        if matList and #matList > 0 then
            for i = 1, #matList do
                self.OrgColrDic[matList[i]] = matList[i]:GetColor(self.FlashShaderColorNameDic[matList[i].shader.name])
            end
            self.matDic[e] = matList
        end
    else
        local matList = self.matDic[e]
        if matList then
            for i = 1, #matList do
                local mat = matList[i]
                mat:SetColor(self.FlashShaderColorNameDic[mat.shader.name], self.OrgColrDic[mat])
                self.OrgColrDic[mat] = nil
                mat:DisableKeyword(self._useDetail)
            end
        end
        self:EnableBoundView(e, false)
        self.matDic[e] = nil
    end
end

function MaterialFlashSystem_Render:GetMatList(e, matList)
    local rendererList =
        e:View().ViewWrapper.GameObject:GetComponentsInChildren(typeof(UnityEngine.SkinnedMeshRenderer), true) --只拿SkinnedMeshRenderer而非Renderer，否则会拿到特效的renderer
    for i = 0, rendererList.Length - 1 do
        ---@type UnityEngine.Material[]
        local childMatList = nil
        local renderer = rendererList[i]
        local mat = self:GetMaterial(renderer)
        if string.find(mat.name, "Instance") then
            childMatList = renderer.sharedMaterials
        else
            childMatList = rendererList[i].materials
            renderer.sharedMaterials = childMatList
        end
        for j = 0, childMatList.Length - 1 do
            local matj = childMatList[j]
            if matj then
                local shaderName = matj.shader.name
                if self.FlashShaderColorNameDic[shaderName] then
                    matList[#matList + 1] = matj
                end
            end
        end
    end
end

function MaterialFlashSystem_Render:GetMaterial(render)
    if render.sharedMaterial then
        return render.sharedMaterial
    end
    return render.material
end

---entity更新MaterialFlash颜色
---@param e Entity
function MaterialFlashSystem_Render:HandleUpdateFlash(e)
    if not e:HasView() then
        return
    end
    local matList = self.matDic[e]
    if matList then
        for i = 1, #matList do
            local mat = matList[i]
            if mat then
                mat:SetColor(
                    self.FlashShaderColorNameDic[matList[i].shader.name],
                    self.flashColor * self.flashColorRatio
                )
                mat:EnableKeyword(self._useDetail)
            end
        end
    end
    self:EnableBoundView(e, true)
end

function MaterialFlashSystem_Render:EnableBoundView(e, isEnable)
    local view = e:View()
    if not view then
        return
    end
    local go = view.ViewWrapper.GameObject
    ---@type BoundView
    local boundView = BoundView.Get(go)
    if boundView then
        if boundView.enabled ~= isEnable then
            boundView.enabled = isEnable
        end
    end
end
