_class("HomelandNavmeshTool", Singleton)
---@class HomelandNavmeshTool:Singleton
HomelandNavmeshTool = HomelandNavmeshTool

--圆内随机
---@param sRadius float 半径
---@param center Vector3 圆心坐标
---@return Vector3
function HomelandNavmeshTool:GetRandomPositionCircle(sRadius, center)
    for i = 1, 10 do
        local radius = UnityEngine.Random.Range(0, sRadius)
        local radian = UnityEngine.Random.Range(0, 360) * Mathf.Deg2Rad;
        local x = Mathf.Cos(radian) * radius + center.x;
        local y = center.y;
        local z = Mathf.Sin(radian) * radius + center.z;
        ---@type UnityEngine.AI.NavMeshHit
        local hit, navMeshHit = UnityEngine.AI.NavMesh.SamplePosition(Vector3(x, y, z), nil, 100, 1)
        if hit then
            return navMeshHit.position
        end
    end
    return center
end

--环内随机 
---@param sRadius float 小圆半径
---@param bRadius float 大圆半径
---@param center Vector3 圆心坐标
---@return Vector3
function HomelandNavmeshTool:GetRandomPositionRing(sRadius, bRadius, center)
    local radius = UnityEngine.Random.Range(sRadius, bRadius)
    local radian = UnityEngine.Random.Range(0, 360) * Mathf.Deg2Rad;
    local x = Mathf.Cos(radian) * radius + center.x;
    local y = center.y;
    local z = Mathf.Sin(radian) * radius + center.z;
    local hit, navMeshHit = UnityEngine.AI.NavMesh.SamplePosition(Vector3(x, y, z), nil, 100, 1)
    if hit then
        return navMeshHit.position
    end
    return center
end

--全地图随机
---@return Vector3
function HomelandNavmeshTool:GetRandomPositionMap()
    local triangulation = UnityEngine.AI.NavMesh.CalculateTriangulation();
    local t = math.random(0, triangulation.indices.Length - 3)
    local point = Vector3.Lerp(triangulation.vertices[triangulation.indices[t]], triangulation.vertices[triangulation.indices[t + 1]], math.random());
    point = Vector3.Lerp(point, triangulation.vertices[triangulation.indices[t + 2]], math.random());
    return point
end

--坐标是否在导航面上
---@return boolean
function HomelandNavmeshTool:PositionReachable(position)
    return UnityEngine.AI.NavMesh.SamplePosition(position, nil, 100, 1)
end

--两点之间是否联通
---@return boolean
function HomelandNavmeshTool:PositionConnected(sourcePosition, targetPosition)
    if EDITOR then
        UnityEngine.Debug.DrawLine(sourcePosition, targetPosition, Color.yellow, 60);
    end
    ---@type UnityEngine.AI.NavMeshPath
    local path = UnityEngine.AI.NavMeshPath:New()
    local connected = UnityEngine.AI.NavMesh.CalculatePath(sourcePosition, targetPosition, 1, path)
    if EDITOR then
        if connected then
            for i = 0, path.corners.Length - 2 do
                UnityEngine.Debug.DrawLine(path.corners[i], path.corners[i + 1], Color.red, 60);
            end
        end
    end
    return connected and path.status == UnityEngine.AI.NavMeshPathStatus.PathComplete
end

--获取指定位置的可达坐标点
---@param position Vector3 指定位置
---@return Vector3
function HomelandNavmeshTool:GetReachablePosition(position)
    local hit, navMeshHit = UnityEngine.AI.NavMesh.SamplePosition(position, nil, 100, 1)
    if hit then
        return navMeshHit.position
    else
        return position
    end
end