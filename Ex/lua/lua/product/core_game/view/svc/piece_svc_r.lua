--[[------------------------------------------------------------------------------------------
    PieceServiceRender 格子相关Service 
]] --------------------------------------------------------------------------------------------
_class("PieceServiceRender", Object)
---@class PieceServiceRender:Object
PieceServiceRender = PieceServiceRender

function PieceServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._pieceAnim = {}
    self._pieceEffect = {} --格子的材质类型(Normal/Prism/PrismEffect)

    ---@type table<number, PieceAnimationData>
    self._pieceAnimData = {}
    self._pieceAnimData[PieceEffectType.Normal] = PieceAnimationData:New()
    self._pieceAnimData[PieceEffectType.Prism] = PrismPieceAnimationData:New()

    ---通过代码使用的动画名称
    self._animNameNormal = "Normal"
    self._animNameDark = "Dark"
end

function PieceServiceRender:Initialize()
end
function PieceServiceRender:InitPieceAnim()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieces = utilData:GetReplicaBoardPieces()
    for x, row in pairs(pieces) do
        for y, grid in pairs(row) do
            if not self._pieceAnim[x] then
                self._pieceAnim[x] = {}
                self._pieceEffect[x] = {}
            end
            self._pieceAnim[x][y] = self._animNameNormal
        end
    end
end

function PieceServiceRender:RefreshMonsterAreaOutLine(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local round = utilDataSvc:GetStatCurWaveTotalRoundCount()
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        ---逻辑死亡 or 还没出生表现 就不刷了
        if not e:HasDeadFlag() and e:View() then
            renderEntityService:DestroyMonsterAreaOutLineEntity(e)
        end
    end
    YIELD(TT)

    for _, e in ipairs(monsterGroup:GetEntities()) do
        ---逻辑死亡 or 还没出生表现 就不刷了  存在有MonsterID没有AI的东西（虚影）所以要判断一下
        if not e:HasGhost() and not e:HasGuideGhost() and not e:HasDeadFlag() then 
            if e:View() and not utilDataSvc:IsAIAttachState(e, round) then
                if e:MonsterID():IsNeedOutLine() then
                    renderEntityService:CreateMonsterAreaOutlineEntity(e)
                end
            end
        end

    end
end

--怪物脚下的阴影坐标
function PieceServiceRender:GetMonsterShadowPosList()
    local shadowPosList = {}

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local round = utilDataSvc:GetStatCurWaveTotalRoundCount()

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        --其他棋盘面的不显示压暗
        if not e:HasOutsideRegion() and not e:HasGhost() and not e:HasGuideGhost() then
            local monsterGridPos = e:GetGridPosition()
            if e:HasBodyArea() then
                ---@type MonsterIDComponent
                local monsterIDCmpt = e:MonsterID()
                if not utilDataSvc:IsAIAttachState(e, round) and monsterIDCmpt:IsNeedGridDown() then
                    ---@type BodyAreaComponent
                    local bodyAreaCmpt = e:BodyArea()
                    local areaArray = bodyAreaCmpt:GetArea()
                    for i = 1, #areaArray do
                        local curAreaPos = areaArray[i]
                        --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
                        shadowPosList[#shadowPosList + 1] = monsterGridPos + curAreaPos
                    end
                end
            else
                shadowPosList[#shadowPosList + 1] = monsterGridPos
            end
        end
    end
    return shadowPosList
end

--机关脚下的阴影坐标
function PieceServiceRender:GetTrapShadowPosList()
    local shadowPosList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        local trapGridPos = e:GetGridPosition()
        if e:HasBodyArea() then
            ---@type TrapRenderComponent
            local trapRender = e:TrapRender()
            if trapRender:IsNeedGridDown() then
                ---@type BodyAreaComponent
                local bodyAreaCmpt = e:BodyArea()
                local areaArray = bodyAreaCmpt:GetArea()
                for i = 1, #areaArray do
                    local curAreaPos = areaArray[i]
                    shadowPosList[#shadowPosList + 1] = trapGridPos + curAreaPos
                end
            end
        else
            shadowPosList[#shadowPosList + 1] = trapGridPos
        end
    end
    return shadowPosList
end

--棋子光灵怪物
function PieceServiceRender:GetChessPetShadowPosList()
    local shadowPosList = {}
    local chessPetGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPetRender)
    for _, e in ipairs(chessPetGroup:GetEntities()) do
        local chessPetGridPos = e:GetGridPosition()
        if e:HasBodyArea() then
            ---@type BodyAreaComponent
            local bodyAreaCmpt = e:BodyArea()
            local areaArray = bodyAreaCmpt:GetArea()
            for i = 1, #areaArray do
                local curAreaPos = areaArray[i]
                --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
                shadowPosList[#shadowPosList + 1] = chessPetGridPos + curAreaPos
            end
        else
            shadowPosList[#shadowPosList + 1] = chessPetGridPos
        end
    end
    return shadowPosList
end

function PieceServiceRender:RefreshPieceAnim()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    --生成怪物脚下阴影
    local shadowPosList = {}
    local monsterShadowPosList = self:GetMonsterShadowPosList()
    table.appendArray(shadowPosList, monsterShadowPosList)

    local trapShadowPosList = self:GetTrapShadowPosList()
    table.appendArray(shadowPosList, trapShadowPosList)

    local chessPetShadowPosList = self:GetChessPetShadowPosList()
    table.appendArray(shadowPosList, chessPetShadowPosList)

    self:HandleTeamPlayerPiece(shadowPosList)
end

-- 处理队伍的脚底阴影
function PieceServiceRender:HandleTeamPlayerPiece(shadowPosList)
    local localTeamPos = nil
    local e = self._world:Player():GetLocalTeamEntity()
    if e ~= nil then
        localTeamPos = e:GetGridPosition()
    end

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type PieceMultiServiceRender
    local pieceMultiServiceRender = self._world:GetService("PieceMulti")

    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()

        --多面棋盘的其他面要压暗
        if e:HasOutsideRegion() then
            ---@type OutsideRegionComponent
            local outsideRegion = e:OutsideRegion()
            local boardIndex = outsideRegion:GetBoardIndex()
            pieceMultiServiceRender:SetPieceAnimDown(boardIndex, pos)
        end

        if localTeamPos and pos == localTeamPos then
            goto CONTINUE
        end

        if table.icontains(shadowPosList, pos) then
            self:SetPieceAnimDown(pos)
            trapServiceRender:ShowHideTrapAtPos(pos, false)
        else
            self:SetPieceAnimNormal(pos)
            trapServiceRender:ShowHideTrapAtPos(pos, true)
        end
        ::CONTINUE::
    end
end

---全部格子正常显示
function PieceServiceRender:SetAllPieceNormal()
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()
        self:SetPieceAnimNormal(pos)
    end
end

---全部格子压暗
function PieceServiceRender:SetAllPieceDark()
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()
        self:SetPieceAnimDark(pos)
    end
end

function PieceServiceRender:SetPieceAnimation(pos, anim, pieceType)
    local col = self._pieceAnim[pos.x]
    if not col then
        Log.fatal("###  no pos.x in _pieceAnim. pos=", pos, " ", Log.traceback())
        return
    end
    local curAnim = col[pos.y]
    if curAnim == anim then
        return
    end
    self._pieceAnim[pos.x][pos.y] = anim

    local e = self:FindPieceEntity(pos)
    if e ~= nil then
        --e:SetAnimatorControllerBools(self:GetPieceStatusTable(anim))
        self:_PlayGridAnimation(e, anim)
    else
        --Log.fatal("grid error,can not find grid", pos, Log.traceback())
    end
end

---@param pos Vector2
function PieceServiceRender:ResetPieceAnimation(pos)
    local curAnim = self._pieceAnim[pos.x][pos.y]

    local e = self:FindPieceEntity(pos)
    if e and curAnim then
        self:_PlayGridAnimation(e, curAnim)
    end
end

function PieceServiceRender:GetPieceAnimation(pos)
    if not self._pieceAnim[pos.x] then
        return
    end

    local curAnim = self._pieceAnim[pos.x][pos.y]
    return curAnim
end

---@param entity Entity 格子
function PieceServiceRender:SetPieceEntityBirth(pieceEntity)
    self:_PlayGridAnimation(pieceEntity, "Birth", "Normal")
end

function PieceServiceRender:_PlayGridAnimationNoEffect(e, anim, ...)
    local animList = {}
    animList[#animList + 1] = self:GetAnimResName(e, anim, true)

    local animArgs = {...}
    if #animArgs > 0 then
        for _, v in ipairs(animArgs) do
            animList[#animList + 1] = self:GetAnimResName(e, v)
        end
    end

    self:_PlayPieceU3DAnimation(animList, e)
end
---@param e Entity 格子
---@param anim string 动画名称
---@param ... table 变长的动画列表
function PieceServiceRender:_PlayGridAnimation(e, anim, ...)
    local animList = {}
    animList[#animList + 1] = self:GetAnimResName(e, anim)

    local animArgs = {...}
    if #animArgs > 0 then
        for _, v in ipairs(animArgs) do
            animList[#animList + 1] = self:GetAnimResName(e, v)
        end
    end

    self:_PlayPieceU3DAnimation(animList, e)
end
---@param e Entity
---@return UnityEngine.Animation
function PieceServiceRender:GetUnityAnimation(e)
    ---@type LegacyAnimationComponent
    local legacyAnimCmpt = e:LegacyAnimation()
    local u3dAnimCmpt = legacyAnimCmpt:GetU3DAnimationCmpt()
    if not u3dAnimCmpt then
        ---@type UnityEngine.GameObject
        local gridGameObj = e:View().ViewWrapper.GameObject

        ---@type UnityEngine.Animation 动画组件
        u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        if not u3dAnimCmpt then
            Log.fatal("Can not find animation component")
            return
        end
        legacyAnimCmpt:SetU3DAnimationCmpt(u3dAnimCmpt)
    end
    return u3dAnimCmpt
end

---@param e Entity
function PieceServiceRender:_PlayPieceU3DAnimation(animList, e)
    ---@type LegacyAnimationComponent
    local legacyAnimCmpt = e:LegacyAnimation()
    local u3dAnimCmpt = legacyAnimCmpt:GetU3DAnimationCmpt()
    if not u3dAnimCmpt then
        ---@type UnityEngine.GameObject
        local gridGameObj = e:View().ViewWrapper.GameObject

        ---@type UnityEngine.Animation 动画组件
        u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        if not u3dAnimCmpt then
            Log.fatal("Can not find animation component")
            return
        end
      
        legacyAnimCmpt:SetU3DAnimationCmpt(u3dAnimCmpt)
    end
    local gameObject = e:View().ViewWrapper.GameObject
    if gameObject.transform.position.y==  BattleConst.CacheHeight then
        if #animList > 1 then
            for _, v in ipairs(animList) do
                Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..v, Log.traceback())
            end 
        else
            local curAnim = animList[1]
            Log.exception("位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..curAnim, Log.traceback())
        end
    end
  
    if #animList > 1 then
        for _, v in ipairs(animList) do
            u3dAnimCmpt:PlayQueued(v, UnityEngine.QueueMode.CompleteOthers)
        end
    else
        --[[
        ---@type UnityEngine.GameObject
        local gridGameObj = e:View().ViewWrapper.GameObject

        local gridPos = e:GridLocation().Position
        if gridPos.x == 3 and gridPos.y == 1 then 
            Log.fatal("PlayAnimationSystem:",curAnim,";gridPos:",gridPos,";isActive:",gridGameObj.activeSelf,";frameCount:",UnityEngine.Time.frameCount,Log.traceback())
        end
        --]]
        ---有时候会发现PlayQueued会出现播放不完成的问题，还没找出是啥原因
        local curAnim = animList[1]
        u3dAnimCmpt:Play(curAnim)
    end
end

---@param e Entity
---@param anim string
function PieceServiceRender:GetAnimResName(e, anim, notUseEffect)
    local pos = e:GetGridPosition()
    local curEff = self._pieceEffect[pos.x][pos.y] or PieceEffectType.Normal

    if curEff == PieceEffectType.Prism then
        --基础格子动画棱镜和特效棱镜在 pieceEffect中都是 PieceEffectType.Prism

        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        local prismEffectTrap = trapServiceRender:GetPrismEffectTrap(pos)
        if prismEffectTrap then
            --如果在改位置能找到特效棱镜机关 格子动画不刷新成棱镜模式 还是使用普通动画。因为格子棱镜的层级比特效棱镜的层级还高
            notUseEffect = true

            trapServiceRender:OnPrismEffectTrapPlayAnimWithPieceAnim(prismEffectTrap, anim)
        end
    end

    if notUseEffect then
        curEff = PieceEffectType.Normal
    end
    local effAnimTable = self._pieceAnimData[curEff]

    local animResName = effAnimTable:GetAnimationName(anim)
    if not animResName then
        Log.fatal("不存在" .. anim .. "对应的格子动画资源！格子位置：" .. tostring(anim) .. " 格子特效类型：" .. curEff)
    end
    return animResName
end

function PieceServiceRender:GetEffAnimTableData(e)
    local pos = e:GetGridPosition()
    local curEff = self._pieceEffect[pos.x][pos.y] or PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]
    return effAnimTable
end

function PieceServiceRender:GetPiecePlayingAnimationName(e)
    ---@type PieceAnimationData
    local effAnimTable = self:GetEffAnimTableData(e)
    local animTable = effAnimTable:GetAnimationNameList()
    ---@type UnityEngine.Animation
    local u3dAnimCmpt = self:GetUnityAnimation(e)
    for animName, animResName in pairs(animTable) do
        if u3dAnimCmpt:IsPlaying(animResName) then
            return animName
        end
    end
end

function PieceServiceRender:GetAnimNameByResName(e, animResName)
    local pos = e:GetGridPosition()
    local curEff = self._pieceEffect[pos.x][pos.y] or PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]
    local animName = effAnimTable:GetAnimationNameByResName(animResName)
    return animName
end

function PieceServiceRender:GetNormalAnimName()
    local curEff = PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]

    local animResName = effAnimTable:GetAnimationName("Normal")
    if not animResName then
        Log.fatal("不存在对应的格子动画资源！Normal 格子位置： 格子特效类型：" .. curEff)
    end
    return animResName
end

---@param gameObject UnityEngine.GameObject
function PieceServiceRender:PlayDefaultNormal(gameObject, animName)
    if not animName then
        animName = "Normal"
    end
    local curEff = PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]

    local animResName = effAnimTable:GetAnimationName(animName)
    if not animResName then
        Log.fatal("not find normal res")
        return
    end

    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = gameObject:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then
        Log.fatal("Can not find animation component")
        return
    end
    -- if gameObject.transform.position.y== BattleConst.CacheHeight  then
    --     Log.exception("PlayDefaultNormal:".. "位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..animResName, Log.traceback())
    -- end
    u3dAnimCmpt:Play(animResName)
    return animResName
end


function PieceServiceRender:PlayNormalForUnload(gameObject)
    local animName = "OffScreenNormal"
    local curEff = PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]

    local animResName = effAnimTable:GetAnimationName(animName)
    if not animResName then
        Log.fatal("not find normal res")
        return
    end

    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = gameObject:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then
        Log.fatal("Can not find animation component")
        return
    end
    if gameObject.transform.position.y ~= BattleConst.CacheHeight  then
        Log.exception("PlayNormalForUnload:".. "位置:("..gameObject.transform.position.x..","..gameObject.transform.position.y..","..gameObject.transform.position.z..") 播放动画名称:"..animResName, Log.traceback())
    end
    u3dAnimCmpt:Play(animResName)
    return animResName
end

function PieceServiceRender:GetPieceStatusTable(curstate)
    local statetable = {
        Up = false,
        Down = false,
        Dark = false,
        Normal = false,
        LinkIn = false,
        LinkOut = false,
        LinkDone = false,
        MoveDone = false,
        Black = false,
        Sliver = false,
        Gray = false,
        Color = false,
        AtkColor = false,
        Invalid = false
    }
    statetable[curstate] = true

    return statetable
end
function PieceServiceRender:SetPieceAnimUp(pos)
    self:SetPieceAnimation(pos, "Up")
end

function PieceServiceRender:SetPieceAnimDown(pos)
    self:SetPieceAnimation(pos, "Down")
end

function PieceServiceRender:SetPieceAnimDark(pos)
    self:SetPieceAnimation(pos, "Dark")
end

function PieceServiceRender:SetPieceAnimNormal(pos, pieceType)
    self:SetPieceAnimation(pos, "Normal", pieceType)
end

function PieceServiceRender:SetPieceAnimLinkIn(pos)
    self:SetPieceAnimation(pos, "LinkIn")
end

function PieceServiceRender:SetPieceAnimLinkOut(pos)
    self:SetPieceAnimation(pos, "LinkOut")
end

function PieceServiceRender:SetPieceAnimLinkDone(pos)
    self:SetPieceAnimation(pos, "LinkDone")
end

function PieceServiceRender:SetPieceAnimMoveDone(pos)
    self:SetPieceAnimation(pos, "MoveDone")
end

---预览效果中使用的亮黑色格子
function PieceServiceRender:SetPieceAnimBlack(pos)
    self:SetPieceAnimation(pos, "Black")
end

---预览效果中使用的亮灰色格子
function PieceServiceRender:SetPieceAnimSliver(pos)
    self:SetPieceAnimation(pos, "Sliver")
end

---预览效果中使用的灰色格子
function PieceServiceRender:SetPieceAnimGray(pos)
    self:SetPieceAnimation(pos, "Gray")
end

---单独转色
function PieceServiceRender:SetPieceAnimColor(pos)
    self:SetPieceAnimation(pos, "Color")
    --Log.fatal("SetPieceAnimColor:",pos,";frameCount:",UnityEngine.Time.frameCount,Log.traceback())
end

---攻击转色
function PieceServiceRender:SetPieceAnimAtkColor(pos)
    self:SetPieceAnimation(pos, "AtkColor")
end

---点选无效
function PieceServiceRender:SetPieceAnimInvalid(pos)
    self:SetPieceAnimation(pos, "Invalid")
end

---加成
function PieceServiceRender:SetPieceAnimAdd(pos)
    self:SetPieceAnimation(pos, "Add")
end

---洗版
function PieceServiceRender:SetPieceAnimReflash(pos)
    self:SetPieceAnimation(pos, "Reflash")
end

---设置指定Entity的normal动画
function PieceServiceRender:SetPieceEntityAnimNormal(pieceEntity)
    ---@type Vector2
    local pos = pieceEntity:GetGridPosition()
    self._pieceAnim[pos.x][pos.y] = "Normal"
    self:_PlayGridAnimation(pieceEntity, "Normal")
end

function PieceServiceRender:SetPieceEntityDark(pieceEntity)
    ---@type Vector2
    local pos = pieceEntity:GetGridPosition()
    local curAnim = self._pieceAnim[pos.x][pos.y]
    if curAnim == self._animNameDark then
        return
    end

    self._pieceAnim[pos.x][pos.y] = self._animNameDark
    self:_PlayGridAnimation(pieceEntity, self._animNameDark)
end

function PieceServiceRender:SetPieceRenderEffect(pos, effectType)
    local oldPieceEffect = self._pieceEffect[pos.x][pos.y]
    if oldPieceEffect == effectType then
        return
    end

    self._pieceEffect[pos.x][pos.y] = effectType
    self:ResetPieceAnimation(pos)
end

function PieceServiceRender:GetPieceEffectType(pos)
    return self._pieceEffect[pos.x][pos.y]
end

function PieceServiceRender:ResetPieceAnimatorState(pos)
    if self._pieceAnim[pos.x] and self._pieceAnim[pos.x][pos.y] then
        self._pieceAnim[pos.x][pos.y] = nil
    end
end

function PieceServiceRender:ReplaceGridMaterial(entity, assetPath)
    ---@type ResourcesPoolService
    local respool = self._world.BW_Services.ResourcesPool
    local mat = respool:LoadMaterial(assetPath)

    if (not mat) or (not (mat.Obj)) then
        Log.fatal("Cannot load target material: ", assetPath)
        return
    end

    local gridGameObj = entity:View().ViewWrapper.GameObject
    self:ReplaceGridGameObjectMaterial(gridGameObj, mat)
end

function PieceServiceRender:ReplaceGridGameObjectMaterial(gameObject, mat)
    local meshRenderer = gameObject:GetComponentInChildren(typeof(UnityEngine.MeshRenderer))

    if not meshRenderer then
        Log.warn("[PieceServiceRender] no MeshRenderer")
        return
    end

    meshRenderer.sharedMaterials = {mat.Obj}
end

function PieceServiceRender:ShouldPosPlayDownAim(checkPos)
    return false
    -----@type PreviewEnvComponent
    --    local env = self._world:GetPreviewEntity():PreviewEnv()
    --    local es = env:GetEntitiesAtPos(checkPos,function(e)
    --        return e:HasMonsterID()
    --    end)
    --    return #es>0

    -- local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    -- for _, e in ipairs(monsterGroup:GetEntities()) do
    --     local monsterGridPos = e:GetGridPosition()
    --     if e:HasBodyArea() then
    --         ---@type BodyAreaComponent
    --         local bodyAreaCmpt = e:BodyArea()
    --         local areaArray = bodyAreaCmpt:GetArea()
    --         for i = 1, #areaArray do
    --             local curAreaPos = areaArray[i]
    --             --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
    --             local curPos = monsterGridPos + curAreaPos
    --             if curPos == checkPos then
    --                 return true
    --             end
    --         end
    --     else
    --         if monsterGridPos == checkPos then
    --             return true
    --         end
    --     end
    -- end
    --return false
end

function PieceServiceRender:IsPieceAnimDark(pos)
    local curEff = self._pieceEffect[pos.x][pos.y] or PieceEffectType.Normal
    ---@type PieceAnimationData
    local animDataObj = self._pieceAnimData[curEff]

    local animName = animDataObj:GetAnimationName("Dark")
    local curAnimName = self._pieceAnim[pos.x][pos.y]
    return animName == curAnimName
end

function PieceServiceRender:RemovePrismAt(pos)
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    local pieceEntity = self:FindPieceEntity(pos)
    if not pieceEntity then
        return
    end

    self:SetPieceRenderEffect(pos, PieceEffectType.Normal)
end

---@return Entity
function PieceServiceRender:FindPieceEntity(pos)
    -- local piece_group = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    -- for _, piece_entity in ipairs(piece_group:GetEntities()) do
    --     if piece_entity:GetGridPosition() == pos then
    --         return piece_entity
    --     end
    -- end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    return renderBoardCmpt:GetGridRenderEntity(pos)
end
---@param targetEntity Entity
function PieceServiceRender:RefreshMonsterPiece(targetEntity, bUp)
    local renderPos = targetEntity:GetRenderGridPosition()
    local area = targetEntity:BodyArea():GetArea()
    for i, p in ipairs(area) do
        local posWork = renderPos + p
        if bUp then
            --在这里再做一次是为了做一次矫正，由于AI执行GridMove顺序不同，而使得隐藏机关在显示机关之前执行，由此出现该隐藏的机关没隐藏的问题
            self:SetPieceAnimUp(posWork)
        else
            self:SetPieceAnimDown(posWork)
        end
    end
end

---@param gridEntity Entity
function PieceServiceRender:InitializeGridU3DCmpt(gridEntity)
    ---@type UnityEngine.GameObject
    local gridGameObj = gridEntity:View().ViewWrapper.GameObject

    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then
        Log.fatal("Can not find animation component")
        return
    end

    ---@type LegacyAnimationComponent
    local legacyAnimCmpt = gridEntity:LegacyAnimation()
    legacyAnimCmpt:SetU3DAnimationCmpt(u3dAnimCmpt)
end

function PieceServiceRender:RefreshPieceAnimForChessMode()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local round = utilDataSvc:GetStatCurWaveTotalRoundCount()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    --生成怪物脚下阴影
    local shadowPosList = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPetRender)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local chessPetGridPos = e:GetGridPosition()
        if e:HasBodyArea() then
            ---@type BodyAreaComponent
            local bodyAreaCmpt = e:BodyArea()
            local areaArray = bodyAreaCmpt:GetArea()
            for i = 1, #areaArray do
                local curAreaPos = areaArray[i]
                --Log.fatal("monsterPos:",monsterGridPos.x," ",monsterGridPos.y," area",curAreaPos.x," ",curAreaPos.y)
                shadowPosList[#shadowPosList + 1] = chessPetGridPos + curAreaPos
            end
        else
            shadowPosList[#shadowPosList + 1] = chessPetGridPos
        end
    end

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, e in ipairs(pieceGroup:GetEntities()) do
        local pos = e:GetGridPosition()
        if table.icontains(shadowPosList, pos) then
            self:SetPieceAnimDown(pos)
            trapServiceRender:ShowHideTrapAtPos(pos, false)
        else
            self:SetPieceAnimNormal(pos)
            trapServiceRender:ShowHideTrapAtPos(pos, true)
        end
    end
end
---@param gameObj UnityEngine.GameObject
function PieceServiceRender:RevertPieceShowRangeByGameObj(gameObj)
    ---@type UnityEngine.MeshRenderer
    local meshRenderer = gameObj:GetComponentInChildren(typeof(UnityEngine.MeshRenderer))
    -----@type UnityEngine.MaterialPropertyBlock
    --local _mpb = UnityEngine.MaterialPropertyBlock:New()
    ---_mpb:SetVector("_H3DGZ_SelfClipParams",Vector4(-1000,1000,-1000,1000));
    meshRenderer:SetPropertyBlock(nil)
    --Log.fatal("Revert GameObj:",gameObj:GetInstanceID())
end

function PieceServiceRender:RevertPieceShowRange(entity)
    local gridGameObj = entity:View().ViewWrapper.GameObject
    self:RevertPieceShowRangeByGameObj(gridGameObj)
end
---@param entity Entity
function PieceServiceRender:SetPieceShowRange(entity,pos)
    local gridGameObj = entity:View().ViewWrapper.GameObject
    ---@type UnityEngine.MeshRenderer
    local meshRenderer = gridGameObj:GetComponentInChildren(typeof(UnityEngine.MeshRenderer))
    ---@type UnityEngine.MaterialPropertyBlock
    local _mpb = UnityEngine.MaterialPropertyBlock:New()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local renderPos = boardServiceRender:GridPosition2LocationPos(pos,entity)
    local posV4  = Vector4(renderPos.x-0.5,renderPos.x+0.5,renderPos.z-0.5,renderPos.z+0.5)
    _mpb:SetVector("_H3DGZ_SelfClipParams",Vector4(renderPos.x-0.5,renderPos.x+0.5,renderPos.z-0.5,renderPos.z+0.5));
    meshRenderer:SetPropertyBlock(_mpb)
    --Log.fatal("Set GameObj:",gridGameObj:GetInstanceID()," Entity:",entity:GetID()," Pos：", tostring(pos)," SetValue:", tostring(posV4))
end

--region BoardSplice
function PieceServiceRender:FindPieceFakeEntity(pos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardSpliceComponent
    local renderBoardSpliceComponent = renderBoardEntity:RenderBoardSplice()
    local gridEntity = renderBoardSpliceComponent:GetGridRenderEntity(pos)
    return gridEntity
end
--endregion BoardSplice
