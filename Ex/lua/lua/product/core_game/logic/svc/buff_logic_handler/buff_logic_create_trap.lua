---@class BuffLogicCreateTrap:BuffLogicBase 创建陷阱的buff
_class("BuffLogicCreateTrap", BuffLogicBase)
BuffLogicCreateTrap = BuffLogicCreateTrap

function BuffLogicCreateTrap:Constructor(buffInstance, logicParam)
    self.trapID = logicParam.trapID
    self.entity = buffInstance:Entity()
    self._buffInstance.trapIDs = {}
    ---连线经过的特殊格子数量
    self._newGridCount = logicParam.newGridCount or 0
    ---连线需要经过的格子类型
    self._gridType = logicParam.gridType or nil
    ---优先生成个格子类型
    self._priGridType = logicParam.priGridType or nil
    self._ignorePieceTypeCheck = logicParam.ignorePieceTypeCheck == 1
    self._perGridCreateCount = logicParam.perGridCreateCount or nil
end

function BuffLogicCreateTrap:DoLogic(notify)
    Log.debug("[BuffLogic] create trap: ", self.trapID)
    local world = self._buffInstance:World()

    local notifyType = notify:GetNotifyType()
    local trapEntity = nil
    local eIds = {}
    local pos = nil
    ---@type TrapServiceLogic
    local trapServiceLogic = world:GetService("TrapLogic")
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    if notifyType == NotifyType.MonsterMoveOneFinish or notifyType == NotifyType.PlayerFirstMoveEnd then
		local blockFlag = 0
        --创建机关的时机是 怪物移动每一格 或者 玩家移动第一格
        for _, grid in ipairs(notify:GetCreateTrapGrids()) do
            if trapServiceLogic:CanSummonTrapOnPos(grid, self.trapID, blockFlag) then
                trapEntity = trapServiceLogic:CreateTrap(self.trapID, grid, self.entity:GridLocation():GetGridDir(), false,nil, self.entity)
                if trapEntity then
                    table.insert(eIds, trapEntity:GetID())
                end
            end
        end
        pos = notify:GetCreateTrapGrids()
    elseif notifyType == NotifyType.BuffLoad then
        ---连线后
        --创建机关的时机是 buff 挂载的时候

        --空格子上创建机关
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local pieces = utilScopeSvc:GetEmptyPieces()

        local r = randomSvc:LogicRand(1, #pieces)
        local dropPos = pieces[r]

        if trapServiceLogic:CanSummonTrapOnPos(dropPos, self.trapID) then
            trapEntity = trapServiceLogic:CreateTrap(self.trapID, dropPos, Vector2(0, 1), false,nil, self.entity)
            if trapEntity then
                table.insert(eIds, trapEntity:GetID())
            end
        end
    elseif notifyType == NotifyType.RefreshGridOnPetMoveDone then
        ---@type table<Vector2,PieceType>
        local oldGridList = notify:GetOldChainPathGrid()
        ---@type table<number,Vector2,PieceType>
        local newGridList = notify:GetNewChainPathGrid()
        local oldPieceCount = 0
        for pos, pieceType in pairs(oldGridList) do--不能改ipairs
            if pieceType == self._gridType then
                oldPieceCount = oldPieceCount + 1
            end
        end
        ---最终生成机关数量
        local trapCount = math.floor(oldPieceCount / self._newGridCount)
        ---@type Vector2
        local usePos = {}
        if trapCount > 0 then
            ---是否优先在特定属性上生成机关
            if self._priGridType then
                for index, v in ipairs(newGridList) do
                    if trapCount > 0 then
                        if v.pieceType == self._priGridType then
                            if trapServiceLogic:CanSummonTrapOnPos(v.pos, self.trapID) then
                                trapEntity = trapServiceLogic:CreateTrap(self.trapID, v.pos, Vector2(0, 1), false,nil,self.entity)
                                if trapEntity then
                                    table.insert(eIds, trapEntity:GetID())
                                    trapCount = trapCount - 1
                                    usePos[#usePos + 1] = v.pos
                                end
                            end
                        end
                    else
                        break
                    end
                end
            end
            if trapCount > 0 then
                while trapCount > 0 and #newGridList>0 do
                    local index = randomSvc:LogicRand(1, #newGridList)
                    local data = newGridList[index]
                    if not table.icontains(usePos, data.pos) then
                        if trapServiceLogic:CanSummonTrapOnPos(data.pos, self.trapID) then
                            trapEntity = trapServiceLogic:CreateTrap(self.trapID, data.pos, Vector2(0, 1), false,nil,self.entity)
                            if trapEntity then
                                table.insert(eIds, trapEntity:GetID())
                                trapCount = trapCount - 1
                                usePos[#usePos + 1] = data.pos
                            end
                        end
                    end
                    table.remove(newGridList, index)
                end
            end
        else
            return
        end
    elseif notifyType == NotifyType.ResetGridElement then
        ---@type SkillEffectResult_ResetGridData[]
        local resetGridList = notify:GetResetGridDataList()
        local newTrapCount = math.floor(#resetGridList / self._newGridCount)
        local posList = {}
        for _, data in ipairs(resetGridList) do
            table.insert(posList, Vector2(data.m_nX, data.m_nY))
        end
        if newTrapCount > 0 then
            while newTrapCount > 0 do
                local index = randomSvc:LogicRand(1, #posList)
                local pos = posList[index]
                if trapServiceLogic:CanSummonTrapOnPos(Vector2(pos.x, pos.y), self.trapID) then
                    trapEntity = trapServiceLogic:CreateTrap(self.trapID, Vector2(pos.x, pos.y), Vector2(0, 1), false,nil, self.entity)
                    if trapEntity then
                        table.insert(eIds, trapEntity:GetID())
                        table.remove(posList, index)
                        newTrapCount = newTrapCount - 1
                    end
                end
            end
        else
            return
        end
    elseif notifyType == NotifyType.MonsterDeadStart then
        local entity = notify:GetNotifyEntity()
        local area = entity:BodyArea():GetArea()
        local pos = entity:GetGridPosition()
        local posList = {}
        for _, value in ipairs(area) do
            local wordPos = pos + value
            table.insert(posList, wordPos)
        end
        local index = randomSvc:LogicRand(1, #posList)
        local randPos = posList[index]
        local blockFlag = 0
        if trapServiceLogic:CanSummonTrapOnPos(Vector2(randPos.x, randPos.y), self.trapID, blockFlag) then
            trapEntity = trapServiceLogic:CreateTrap(self.trapID, Vector2(randPos.x, randPos.y), Vector2(0, 1), false,nil, self.entity)
            if trapEntity then
                table.insert(eIds, trapEntity:GetID())
            end
        end
    elseif notifyType == NotifyType.GridConvert then
        ---@type NTGridConvert_ConvertInfo[]
        local convertInfoArray = notify:GetConvertInfoArray()
        for _, info in ipairs(convertInfoArray) do
            if (self._ignorePieceTypeCheck) or (info:GetBeforePieceType() ~= info:GetAfterPieceType()) then
                if trapServiceLogic:CanSummonTrapOnPos(info:GetPos(), self.trapID) then
                    local e = trapServiceLogic:CreateTrap(self.trapID, info:GetPos(), Vector2.New(0, 1), false, nil, self.entity)
                    if e then
                        table.insert(eIds, e:GetID())
                    end
                end
            end
        end
    elseif notifyType == NotifyType.SuperGridTriggerEnd then
        pos = notify:GetTriggerPos()
        if trapServiceLogic:CanSummonTrapOnPos(pos, self.trapID) then
            trapEntity = trapServiceLogic:CreateTrap(self.trapID, pos, Vector2.up, false,nil, self.entity)
            if trapEntity then
                table.insert(eIds, trapEntity:GetID())
            end
        end
    elseif notifyType == NotifyType.TeamNormalAttackStart then
        ---@type Vector2[]
        local chanPathData = notify:GetChainPath()
        local count = 0
        for index, pos in ipairs(chanPathData) do
            local needSummon =(index%self._perGridCreateCount) == 0
            if needSummon and trapServiceLogic:CanSummonTrapOnPos(pos, self.trapID) then
                trapEntity = trapServiceLogic:CreateTrap(self.trapID, pos, Vector2(0, 1), false,nil, self.entity)
                if trapEntity then
                    table.insert(eIds, trapEntity:GetID())
                end
            end
        end
    end
    local result = BuffResultCreateTrap:New(eIds, pos)
    return result
end
