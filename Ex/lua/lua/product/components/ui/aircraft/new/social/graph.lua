---@class graph_vertex:Object
_class("graph_vertex", Object)
graph_vertex = graph_vertex

function graph_vertex:Constructor(data)
    self.data = data -- 数据
    self.firstEdge = nil --邻接点链表头
    self.isVisited = false --访问标志:遍历时使用
end

---@class graph_node:Object
_class("graph_node", Object)
graph_node = graph_node

function graph_node:Constructor(vertex)
    self.adjvex = vertex -- 邻接点域
    self.next = nil -- 下一个邻接点域指针域
end

---@class graph:Object
_class("graph", Object)
graph = graph

function graph:Constructor()
    self.items = {}
end

function graph:GetItems()
    return self.items
end
--region 基本方法：为图中添加顶点、添加有向与无向边
function graph:AddVertex(data)
    if self:Contain(data) then
        Log.error("添加了重复的顶点")
        return
    end

    local newVertex = graph_vertex:New(data)
    table.insert(self.items, newVertex)
end

function graph:Clear()
    table.clear(self.items)
end

-- <summary>
-- 添加一条无向边
-- </summary>
-- <param name="from">头顶点data</param>
-- <param name="to">尾顶点data</param>
-- <param name="weight">权值</param>
function graph:AddEdge(from, to)
    local fromVertex = self:Find(from)
    if not fromVertex then
        Log.error("头顶点不存在！")
        return
    end

    local toVertex = self:Find(to)
    if not toVertex then
        Log.error("尾顶点不存在！")
        return
    end

    -- 无向图的两个顶点都需要记录边的信息
    self:_AddDirectedEdge(fromVertex, toVertex)
    self:_AddDirectedEdge(toVertex, fromVertex)
end
-- <summary>
-- 添加一条有向边
-- </summary>
-- <param name="from">头结点data</param>
-- <param name="to">尾节点data</param>
function graph:AddDirectedEdge(from, to)
    local fromVertex = self:Find(from)
    if not fromVertex then
        return nil
    end

    local toVertex = self:Find(to)
    if not toVertex then
        return nil
    end

    self:_AddDirectedEdge(fromVertex, toVertex)
end

function graph:_AddDirectedEdge(fromVertex, toVertex)
    if fromVertex.firstEdge == nil then
        fromVertex.firstEdge = graph_node:New(toVertex)
    else
        local temp = nil
        local node = fromVertex.firstEdge
        while node ~= nil do
            -- 检查是否添加了重复边
            if node.adjvex.data == toVertex.data then
                break
            end
            temp = node
            node = node.next
        end

        local newNode = graph_node:New(toVertex)
        temp.next = newNode
    end
end

function graph:Find(data)
    for index, vertex in ipairs(self.items) do
        if vertex.data == data then
            return vertex
        end
    end
    return nil
end

function graph:Contain(data)
    for index, vertex in ipairs(self.items) do
        if vertex.data == data then
            return true
        end
    end
    return false
end

function graph:GetGraphInfo(isDirectedGraph)
    local sb = ""
    for index, v in ipairs(self.items) do
        sb = sb .. tostring(v.data) .. ":"
        if v.firstEdge ~= nil then
            local temp = v.firstEdge
            while temp ~= nil do
                if isDirectedGraph then
                    sb = sb .. tostring(v.data) .. "→" .. tostring(temp.adjvex.data) .. " "
                else
                    sb = sb .. tostring(temp.adjvex.data)
                end
                temp = temp.next
            end
        end
        sb = sb .. "\r\n"
    end
    return sb
end

-- <summary>
-- 辅助方法：初始化顶点的visited标志为false
-- </summary>
function graph:InitVisited()
    for index, v in ipairs(self.items) do
        v.isVisited = false
    end
end
-- <summary>
-- 宽度优先遍历接口For连通图
-- </summary>
function graph:BFSTraverse(index)
    self:InitVisited() -- 首先初始化visited标志
    return self:BFS(self.items[index]) -- 从第一个顶点开始遍历
end

-- <summary>
-- 宽度优先遍历算法
-- </summary>
-- <param name="v">顶点</param>
function graph:BFS(v)
    local tbl = {}
    v.isVisited = true -- 首先将访问标志设为true标识为已访问
    -- Log.error(tostring(v.data) .. " ") -- 进行访问操作：这里是输出顶点data
    local verQueue = AircraftQueue:New() -- 使用队列存储
    verQueue:Enqueue(v)
    table.insert(tbl, v.data)
    while verQueue:Count() > 0 do
        local w = verQueue:Dequeue()
        local node = w.firstEdge
        -- 访问此顶点的所有邻接节点
        while node ~= nil do
            -- 如果邻接节点没有被访问过则访问它的边
            if node.adjvex.isVisited == false then
                node.adjvex.isVisited = true -- 设置为已访问
                -- Log.error(tostring(node.adjvex.data) .. " ") -- 访问
                table.insert(tbl, node.adjvex.data)
                verQueue:Enqueue(node.adjvex) -- 入队
            end
            node = node.next -- 访问下一个邻接点
        end
    end
    local str = ""
    for index, value in ipairs(tbl) do
        -- str = str .. "->" .. value
    end
    -- Log.error("[graph] .." .. str)
    return tbl
end

function graph.graphTraverseTest()
    local adjList = graph:New()
    adjList:Clear()
    -- 添加顶点
    adjList:AddVertex("A")
    adjList:AddVertex("B")
    adjList:AddVertex("C")
    -- 添加边
    adjList:AddDirectedEdge("A", "C")
    adjList:AddDirectedEdge("C", "A")
    adjList:AddDirectedEdge("B", "A")
    adjList:AddDirectedEdge("A", "B")

    Log.error("广度优先遍历：")
    -- BFS遍历
    local queue = adjList:BFSTraverse(1)
end
