---@class HomelandRoad:Object
_class("HomelandRoad", Object)
HomelandRoad = HomelandRoad

function HomelandRoad:Constructor()
    ---@type HomelandBrick[]
    self._brick = {}
    ---@type HomelandBrickConnect
    self._connect = {}
    self:Init()
end

function HomelandRoad:Init()
    -- local parent = UnityEngine.GameObject.Instantiate(UnityEngine.Resources.Load("Brick"))
    -- parent.transform.eulerAngles = Vector3(0, 10, 0)
    --测试
    for i = 1, 10 do
        local go = UnityEngine.GameObject.Instantiate(UnityEngine.Resources.Load("Brick"))
        go.transform.position = Vector3(i, 0, 0)
        if i < 4 then
            go.transform.eulerAngles = Vector3(0, 1,0)
        end
        local left = HomelandBrickEdge:New(go.transform:Find("Left").gameObject)
        local right = HomelandBrickEdge:New(go.transform:Find("Right").gameObject)
        local forward = HomelandBrickEdge:New(go.transform:Find("Forward").gameObject)
        local after = HomelandBrickEdge:New(go.transform:Find("After").gameObject)
        local brick = HomelandBrick:New(go, forward, after, left, right)
        self:AddBrick(brick)
    end
    ---@type HomelandBrick
    local brick = self._brick[7]
    self:RemoveBrick(self._brick[7])
    UnityEngine.GameObject.Destroy(brick._build)
end

---@param brick HomelandBrick
function HomelandRoad:AddBrick(brick)
    for i = 1, #self._brick do
        if brick:Equal(self._brick[i]) then
            return
        end
    end
    --处理联通情况
    for i = 1, #self._brick do
        ---@type HomelandBrick
        local tmp = self._brick[i]
        local isConnect, firstEdge, secondEdge = tmp:IsConnect(brick)
        if isConnect then
            self._connect[#self._connect + 1] = HomelandBrickConnect:New(tmp, firstEdge, brick, secondEdge)
        end
    end
    --增加砖块
    self._brick[#self._brick + 1] = brick
end

---@param brick HomelandBrick
function HomelandRoad:RemoveBrick(brick)
    for i = #self._connect, 1, -1 do
        ---@type HomelandBrickConnect
        local connect = self._connect[i]
        if(connect:Contain(brick)) then
            connect:Destroy()
            table.remove(self._connect, i)
        end
    end
    for i = 1, #self._brick do
        if brick:Equal(self._brick[i]) then
            brick:Destroy()
            table.remove(self._brick, i)
            return
        end
    end
end

---@param brick HomelandBrick
function HomelandRoad:ChangeBrick(brick)
    --先移除连通
    for i = #self._connect, 1, -1 do
        ---@type HomelandBrickConnect
        local connect = self._connect[i]
        if(connect:Contain(brick)) then
            connect:Destroy()
            table.remove(self._connect, i)
        end
    end
    --判断连通
    for i = 1, #self._brick do
        ---@type HomelandBrick
        local tmp = self._brick[i]
        if not tmp:Equal(brick) then
            local isConnect, firstEdge, secondEdge = tmp:IsConnect(brick)
            if isConnect then
                self._connect[#self._connect + 1] = HomelandBrickConnect:New(tmp, firstEdge, brick, secondEdge)
            end
        end
    end
end
