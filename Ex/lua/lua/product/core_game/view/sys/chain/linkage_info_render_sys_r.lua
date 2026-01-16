--[[----------------------------------------------------------
    连线信息system
]] ------------------------------------------------------------
---@class LinkageInfoRenderSystem_Render:ReactiveSystem
_class("LinkageInfoRenderSystem_Render", ReactiveSystem)
LinkageInfoRenderSystem_Render=LinkageInfoRenderSystem_Render


---@param world World
function LinkageInfoRenderSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function LinkageInfoRenderSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PreviewChainPath)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function LinkageInfoRenderSystem_Render:Filter(entity)
    --return entity:HasChainPath()
    return false
end

function LinkageInfoRenderSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:RenderChainPath(entities[i])
    end
end

---@param e Entity
function LinkageInfoRenderSystem_Render:RenderChainPath(e)
    --取出所有当前划的线，比较是否还在当前划线队列里，不在的要删除
    ---@type PreviewChainPathComponent
    local chain_path_cmpt = e:PreviewChainPath()
    local chain_path = chain_path_cmpt:GetPreviewChainPath()
    if chain_path == nil then 
        return 
    end

    ---@type LinkageRenderService
    local linkageRenderService = self.world:GetService("LinkageRender")
    linkageRenderService:ShowLinkageInfo(chain_path,chain_path_cmpt:GetPreviewPieceType())
end