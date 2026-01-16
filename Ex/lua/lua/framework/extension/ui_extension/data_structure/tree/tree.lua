--region Tree
---@class Tree : Object
---@field head TreeNode
_class("Tree", Object)
Tree = Tree

function Tree:Constructor(head)
    self.head = head
end

---@param name string 查找内容
---@return TreeNode 目标结点
function Tree:DFS(id)
    local head = self.head
    local temp = nil
    if head then
        if id == head.id then
            temp = head
        else
            for i = 1, head:GetChildCount() do
                if not temp then
                    temp = self:DFS(id)
                end
            end
        end
    end
    return temp
end

---@param func function 遍历到某结点的回调
function Tree:BFT(func)
    local head = self.head
    local node = nil
    local queue = {}
    head.level = 0
    table.insert(queue, head)
    while (table.count(queue) ~= 0) do
        node = queue[1]
        table.remove(queue, 1)
        for i = 1, node:GetChildCount() do
            local child = node.children[i]
            child.level = node.level + 1
            table.insert(queue, child)
            if func then
                func(child)
            end
        end
    end
end

function Tree:Free(head)
    if (head ~= nil) then
        head = nil
    end
end
--endregion

--region TreeNode
---@class TreeNode : Object
---@field id number 结点id
---@field level number 该结点在多叉树中的层数
---@field parent TreeNode 父结点
---@field children TreeNode[] 子结点列表
_class("TreeNode", Object)
TreeNode = TreeNode

function TreeNode:Constructor(id)
    self.id = id
    self.level = 0
    self.parent = nil
    self.children = {}
end

---@param child TreeNode 子结点
function TreeNode:AddChild(child)
    child.parent = self
    table.insert(self.children, child)
end

function TreeNode:GetChildCount()
    return table.count(self.children)
end
--endregion
