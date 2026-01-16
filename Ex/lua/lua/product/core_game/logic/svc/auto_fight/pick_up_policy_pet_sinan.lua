require("pick_up_policy_base")

_class("PickUpPolicy_PetSinan", PickUpPolicy_Base)
---@class PickUpPolicy_PetSinan: PickUpPolicy_Base
PickUpPolicy_PetSinan = PickUpPolicy_PetSinan

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetSinan:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GetGridPosition()

    local spColor =  PieceType.Blue

    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标


    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()
    local leftRow,leftColorCount,leftDis,leftPickPos,leftGridCount
    local rightRow,rightColorCount,rightDis,rightPickPos,rightGridCount

    for i = 1, boardMaxX do
        leftRow,leftColorCount,leftDis,leftPickPos,leftGridCount = casterPos.x + (-1 * i),0,1000,Vector2(0,0),0
        rightRow,rightColorCount,rightDis,rightPickPos,rightGridCount = casterPos.x + i,0,1000,Vector2(0,0),0
        for i = 1, boardMaxY do
            local leftPos = Vector2(leftRow,i)
            local rightPos = Vector2(rightRow,i)
            local leftColor =boardServiceLogic:GetPieceType(leftPos)
            if leftColor and leftColor ~= PieceType.None then
                leftGridCount = leftGridCount + 1
                if leftColor == spColor then
                    leftColorCount = leftColorCount + 1
                end
                if Vector2.Distance(leftPos,casterPos) < leftDis then
                    leftDis = Vector2.Distance(leftPos,casterPos)
                    leftPickPos = leftPos
                end
            end
            local rightColor =boardServiceLogic:GetPieceType(rightPos)
            if rightColor and rightColor ~= PieceType.None then
                rightGridCount = rightGridCount + 1
                if rightColor == spColor then
                    rightColorCount = rightColorCount + 1
                end
                if Vector2.Distance(rightPos,casterPos) < rightDis then
                    rightDis = Vector2.Distance(rightPos,casterPos)
                    rightPickPos = rightPos
                end
            end
        end
        ---当左右两边全是水格子就扩大范围。
        if (leftGridCount~=leftColorCount) or rightGridCount~=rightColorCount then
            --当左右两边格子数量和颜色数量都不一致时，取数量多的一边
            if  (leftGridCount~=leftColorCount) and rightGridCount~=rightColorCount then
                if leftColorCount > rightColorCount then
                    table.insert(pickPosList,leftPickPos )
                    break
                ---当左右两边数量一致时取更近的
                elseif leftColorCount == rightColorCount then
                    if leftDis<= rightDis then
                        table.insert(pickPosList,leftPickPos )
                        break
                    else
                        table.insert(pickPosList,rightPickPos )
                        break
                    end
                else
                    table.insert(pickPosList,rightPickPos )
                    break
                end
            end
            ---当只有一边不是全水格子时就选那一边
            if leftGridCount~=leftColorCount then
                table.insert(pickPosList,leftPickPos )
            end
            if rightGridCount ~= rightColorCount then
                table.insert(pickPosList,rightPickPos )
            end
            break
        end
    end
    return pickPosList,pickPosList,{}
end
