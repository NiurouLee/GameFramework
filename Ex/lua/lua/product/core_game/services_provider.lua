--region 服务定位器

_class("ServicesProvider", Object)
---@class ServicesProvider:Object
ServicesProvider = ServicesProvider
---@private
function ServicesProvider:Constructor()
end

---添加服务
---@public
---@param name string 服务名称
---@param service table 服务实例
---@return Services
function ServicesProvider:AddService(name, service)
    self[name] = service
    return self
end

function ServicesProvider:InitServices()
    for name, service in pairs(self) do
        if service.Initialize then
            service:Initialize()
        end
    end
    --防止初始化依赖
    for name, service in pairs(self) do
        if service.InitOver then
            service:InitOver()
        end
    end
end

---获取服务
---@public
---@param name string 服务名称
---@param service table 服务实例
---@return service
function ServicesProvider:GetService(name)
    return self[name]
end

---释放资源
function ServicesProvider:Dispose()
    for k, v in pairs(self) do
        local service = v
        if service.Dispose then
            service:Dispose()
        end
    end
end
