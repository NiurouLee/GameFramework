--[[
    MakePhantom = 69, --制造幻象
]]
---@class SkillEffectCalc_MakePhantom: Object
_class("SkillEffectCalc_MakePhantom", Object)
SkillEffectCalc_MakePhantom = SkillEffectCalc_MakePhantom

function SkillEffectCalc_MakePhantom:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MakePhantom:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillMakePhantomParam
    local skillParam = skillEffectCalcParam.skillEffectParam

    ---@type Entity
    local caster = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    --幻象的位置
    local pos = self:FindLocationsForPhantom(caster)
    ---@type AttributesComponent
    local attrCmpt = caster:Attributes()

    --幻象按百分比继承血量
    local hpPercent = caster:Attributes():GetCurrentHP() / attrCmpt:CalcMaxHp()

    return SkillMakePhantomEffectResult:New(
        skillEffectCalcParam.casterEntityID,
        hpPercent,
        skillParam:GetTargetID(),
        pos,
        caster:GridLocation():GetGridDir()
    )
end

--幽灵幻象专用位置搜索算法  靳策添加
---@param caster Entity 主身
function SkillEffectCalc_MakePhantom:FindLocationsForPhantom(caster)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    local bodyArea = caster:BodyArea():GetArea()
    local pos = caster:GetGridPosition()
    local comparer = function(pos1, pos2)
        local dis1 = math.abs(pos1.x - pos.x) + math.abs(pos1.y - pos.y)
        local dis2 = math.abs(pos2.x - pos.x) + math.abs(pos2.y - pos.y)
        if dis1 > dis2 then
            return 1
        else
            return -1
        end
    end
    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()
    --过滤触发型机关
    local validPos = {}
    for x = 1, boardMaxX do
        for y = 1, boardMaxY do
            local cur = Vector2(x, y)
            --多格怪，bodyArea中每个格子都不能踩到机关
            --分身与本体bodyarea一致
            local bodyAreaCheckOk = true
            for index, bodyOff in ipairs(bodyArea) do
                local bodyPos = cur + bodyOff
                if boardServiceLogic:IsPosBlock(bodyPos, BlockFlag.SummonTrap) then
                    bodyAreaCheckOk = false
                end
            end
            if bodyAreaCheckOk then
                validPos[#validPos + 1] = cur
            end
        end
    end

    --第1优先级：根据BodyArea过滤同行同列
    ---@type Heap
    local heap = Heap:New(Heap.CPM_CUSTOM, comparer)
    local filter = {}
    filter.X = {} --行
    filter.Y = {} --列
    for _, area in ipairs(bodyArea) do
        local p = pos + area
        filter.X[p.x] = true
        filter.Y[p.y] = true
    end
    for _, p in ipairs(validPos) do
        local valid = true
        for __, area in ipairs(bodyArea) do
            local _temp = p + area
            if filter.X[_temp.x] or filter.Y[_temp.y] or not table.icontains(validPos, _temp) then
                valid = false
                break
            end
        end
        if valid then
            heap:Enqueue(p)
        end
    end
    local target = heap:Peek()
    if target then
        return target
    end

    --第2优先级：pos不在同行同列
    heap = Heap:New(Heap.CPM_CUSTOM, comparer)
    for _, p in ipairs(validPos) do
        if not filter.X[p.x] and not filter.Y[p.y] and table.icontains(validPos, p) then
            heap:Enqueue(p)
        end
    end
    target = heap:Peek()
    if target then
        return target
    end

    --第3优先级：不过滤同行同列
    heap = Heap:New(Heap.CPM_CUSTOM, comparer)
    for _, p in ipairs(validPos) do
        heap:Enqueue(p)
    end
    target = heap:Peek()
    if target then
        return target
    end
    Log.fatal("[幽灵] 找不到幻象生成位置")
    return nil
end