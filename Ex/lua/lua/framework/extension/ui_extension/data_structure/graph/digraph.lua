--region Digraph 有向图
---@class Digraph : Object
---@field vertexCount number 顶点数
---@field edgeCount number 边数
---@field indegree table 入度表 key-顶点id value-该顶点对应的入度顶点id列表
---@field adj table 邻接表 key-顶点id value-该顶点指向的顶点id列表
---@field marked number 深搜临时标记表
_class("Digraph", Object)
Digraph = Digraph

function Digraph:Constructor()
    self.vertexCount = 0
    self.edgeCount = 0
    self.indegree = {}
    self.adj = {}
    self.marked = {}
end

---加边
---@param v number 顶点id
---@param w number 顶点id
function Digraph:AddEdge(v, w)
    if not self.adj[v] then
        self.adj[v] = {}
    end
    table.insert(self.adj[v], w)

    if not self.indegree[w] then
        self.indegree[w] = {}
    end
    table.insert(self.indegree[w], v)

    self.edgeCount = self.edgeCount + 1 --边数自增
end

---@param v number 顶点id
---@return number[] 获取顶点v的邻接表
function Digraph:Adj(v)
    return self.adj[v]
end
---@param v number 顶点id
---@return number[] 获取顶点v的入度顶点id列表
function Digraph:Indegree(v)
    return self.indegree[v]
end
---@param v number 顶点id
---@return number 获取顶点v的入度数
function Digraph:IndegreeCount(v)
    local indegree = self:Indegree(v)
    return indegree and table.count(indegree) or 0
end

--region 遍历
---全图深度优先遍历
---@param callback function 回调
function Digraph:DFTAll(callback)
    self.marked = {}
    for v, vadj in pairs(self.adj) do
        self:InternalDFS(v, callback)
    end
end
---局部深度优先遍历，从顶点v开始
---@param v number 起始顶点id
---@param callback function 回调
function Digraph:DFT(v, callback)
    self.marked = {}
    self:InternalDFS(v, callback)
end
---@private
function Digraph:InternalDFS(v, callback)
    if not self.marked[v] then
        self.marked[v] = true
        if callback then
            callback(v)
        end
    end
    local adj = self:Adj(v)
    if adj then
        for _, w in pairs(adj) do
            if not self.marked[w] then
                self:InternalDFS(w)
            end
        end
    end
end
--endregion
--endregion
