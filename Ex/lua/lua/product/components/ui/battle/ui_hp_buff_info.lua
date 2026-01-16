---@class UIHPBuffInfo : UICustomWidget
_class("UIHPBuffInfo", UICustomWidget)
UIHPBuffInfo = UIHPBuffInfo

function UIHPBuffInfo:Constructor()
    self._entityId = nil
    --是否是大血条（UIBattle下 不是HUD）
    self._isBigHPSlider = false

    --轮换周期2秒
    self._show_buff_interval_time = 2
    --渐隐渐显加起来的时间
    self._show_buff_fade_time = 0.2
    --左对齐的时间
    self._show_buff_move_time = 0.5
    --动画移动距离
    self._show_buff_move_distance = 38
    --当前记录的时间
    self._show_buff_delta_time = 0

    --正在播放中
    self._onPlay = false
    self._buffViewInstanceList = {}
    --当前页数
    self._curPage = 1
    --最大页数
    self._pageMax = 1
    --一页有几个buff
    self._pageBuffCount = 4

    --当前页最初和最后的索引
    self.curPageEndIndex = self._pageBuffCount
    self.curPageStartIndex = 1
    self.backPreviousPage = false
    self.removeIndex = 1

    --可以播放动画的 创建出的组件
    self._buffAnimationList = {}
    --正在播放
    self._buffPlayingList = {}

    self._shieldLayer = 0

    self._onShow = true
end

function UIHPBuffInfo:Dispose()
    self._onShow = false
    if self.__playRefreshPageTask then
        TaskManager:GetInstance():KillTask(self.__playRefreshPageTask)
        self.__playRefreshPageTask = nil
    end
end

function UIHPBuffInfo:OnShow()
    ---@type UnityEngine.RectTransform
    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")

    --MSG56458
    if not self._isBoss then
        self._pageBuffCount = (self._rectTransform.rect.width + BattleConst.HUDHPSliderBuffIconFullWidthOffset) // BattleConst.HUDHPSliderBuffIconWidth
    end

    self:_OnCreateBuffItemList()

    --护盾特效
    self._shieldRoot = self:GetGameObject("ShieldRoot")
    if self._shieldRoot then
        self._shieldRootPath = self:GetUIComponent("UISelectObjectPath", "ShieldRoot")
    end

    --破碎特效
    self._brokenRoot = self:GetGameObject("BrokenRoot")
    if self._brokenRoot then
        self._brokenRootPath = self:GetUIComponent("UISelectObjectPath", "BrokenRoot")
        self._brokenRoot:SetActive(false)
    end

    --自爆提示
    self._bombRoot = self:GetGameObject("BombRoot")
    if self._bombRoot then
        self._bombTransform = self._bombRoot:GetComponent("RectTransform")
        self._textBomb = self:GetUIComponent("UILocalizationText", "TextBomb")
    end

    --反制玩家主动技
    self._antiRoot = self:GetGameObject("AntiRoot")
    if self._antiRoot then
        self._antiTransform = self._antiRoot:GetComponent("RectTransform")
        self._textAnti = self:GetUIComponent("UILocalizationText", "TextAnti")
    end
	
    --棋子血条
    local parent = self._rectTransform.transform.parent.parent
    local chessHP = parent.transform:Find("chessHP")
    if chessHP then
        self._chessHPTransform = chessHP
        self._chessHPRoot = chessHP.gameObject
    end

    self:AttachEvent(GameEventType.ChangeBuff, self.OnChangeBuff)
    self:AttachEvent(GameEventType.HPSliderBroken, self.OnHPSliderBroken)
    self:AttachEvent(GameEventType.HPBombLayer, self.OnRefreshHPBombLayer)
    self:AttachEvent(GameEventType.UpdateAntiActiveSkill, self.UpdateAntiActiveSkill)
end

function UIHPBuffInfo:_OnCreateBuffItemList()
    self._buffRootPath = self:GetUIComponent("UISelectObjectPath", "BuffRoot")
    ---@type UIHPBuffItem
    self._buffRootPath:SpawnObjects("UIHPBuffItem", self._pageBuffCount)
    self._buffItemList = self._buffRootPath:GetAllSpawnList()

    self._buffAnimationRootPath = self:GetUIComponent("UISelectObjectPath", "BuffAnimationRoot")
    ---@type UIHPBuffItem
    self._buffAnimationRootPath:SpawnObjects("UIHPBuffItem", self._pageBuffCount)
    self._buffAnimationList = self._buffAnimationRootPath:GetAllSpawnList()

    if self._isBigHPSlider then
    end
end

function UIHPBuffInfo:OnHide()
    self:DetachEvent(GameEventType.ChangeBuff, self.OnChangeBuff)
    self:DetachEvent(GameEventType.HPSliderBroken, self.OnHPSliderBroken)
    self:DetachEvent(GameEventType.UpdateAntiActiveSkill, self.UpdateAntiActiveSkill)
end

function UIHPBuffInfo:OnOnwerEntityDead()
    self._entityId = nil
    self._buffViewInstanceList = {}
    self:_OnPlayCurPage()
end

function UIHPBuffInfo:SetData(entityId)
    self._buffViewInstanceList = {}
    self._entityId = entityId
end

function UIHPBuffInfo:SetBossData(entityId)
    self._entityId = entityId
    self._isBigHPSlider = true
    self._show_buff_interval_time = 9999999

    self._isBoss = true
    self._pageBuffCount = 16

    self._buffViewInstanceList = {}
    self:_OnPlayCurPage()
    self:_OnCreateBuffItemList()

    self:OnChangeBuff()
end

function UIHPBuffInfo:OnChangeBuff()
    --没有初始化
    if not self._entityId then
        return
    end

    -- if InnerGameHelperRender.IsEntityDead(self._entityId) then
    --     return
    -- end

    --entity上最新的buffView
    local viewInstanceArray = InnerGameHelperRender.GetUIBuffViewArray(self._entityId, true)
    local viewInstanceIDArray = {}
    for i, buffView in ipairs(viewInstanceArray) do
        table.insert(viewInstanceIDArray, buffView:BuffID())
    end

    local addBuffViewList = {}
    local removeBuffViewList = {}
    --上一次显示的buffView

    --遍历老的
    for i, buffView in ipairs(self._buffViewInstanceList) do
        --不在新的里面  是删除
        if not table.intable(viewInstanceIDArray, buffView:BuffID()) then
            table.insert(removeBuffViewList, buffView)
        end
    end

    --不在删除的里  就是新加的
    for i, buffView in ipairs(viewInstanceArray) do
        if not table.intable(removeBuffViewList, buffView) then
            table.insert(addBuffViewList, buffView)
        end
    end

    --比对 添加删除调用不同的处理
    for i, buffView in ipairs(addBuffViewList) do
        self:_OnRefreshBuff(true, buffView)
    end

    for i, buffView in ipairs(removeBuffViewList) do
        self:_OnRefreshBuff(false, buffView)
    end

    --旧表现有护盾  新的显示列表里没有  卸载护盾表现
    if self._layerShieldViewInstance and not table.intable(viewInstanceArray, self._layerShieldViewInstance) then
        self:_ShowShieldBuff(true)
    end

    -- OnChangeBuffValue
    --     --如果是层数0的时候添加进来   但是0层不显示  没有添加数据
    -- --1层的时候更新  检查没有添加过 则添加
    -- if not table.icontains(self._buffViewInstanceList, buffViewInstance) then
    --     self:_OnUpdateBuffData(true, buffViewInstance)

    --     self:_OnPlayBuff(true)
    -- end

    local t = {}
    ---@param v BuffViewInstance
    for _, v in ipairs(viewInstanceArray) do
        t[v:BuffID()] = v:GetLayerCount() or 0
    end
    InnerGameHelperRender.UISetHPBuffIcon(self._entityId, t)
end

---@param isAdd boolean 是否是添
---@param buffViewInstance BuffViewInstance
function UIHPBuffInfo:_OnRefreshBuff(isAdd, buffViewInstance)
    --特殊显示 层数护盾
    if self:_OnSpecialBuffShow(buffViewInstance, not isAdd) then
        return
    end

    self:_OnUpdateBuffData(isAdd, buffViewInstance)
    self:_OnPlayBuff(isAdd)
end

---特殊显示情况
---@param buffViewInstance BuffViewInstance
function UIHPBuffInfo:_OnSpecialBuffShow(buffViewInstance, remove)
    if buffViewInstance:GetBuffEffectType() == BuffEffectType.LayerShield then
        self:_ShowShieldBuff(remove)
        return true
    end

    return false
end

---@param isAdd boolean 是否是添
---@param buffViewInstance BuffViewInstance
function UIHPBuffInfo:_OnUpdateBuffData(isAdd, buffViewInstance)
    self.removeIndex = 1
    local oldBuffView
    --检索旧的buff中 id和新传进来一样的
    for i = 1, #self._buffViewInstanceList do
        if buffViewInstance:BuffID() == self._buffViewInstanceList[i]:BuffID() then
            oldBuffView = self._buffViewInstanceList[i]
            self.removeIndex = i
            break
        end
    end

    --更新数据
    if isAdd then
        --只有龙女给怪挂的BUFF  有层数属性 层数是0的时候不显示
        if buffViewInstance:GetLayerCount() == 0 and buffViewInstance:GetBuffEffectType() == BuffEffectType.DragonMark then
            return
        end

        if not oldBuffView or not table.icontains(self._buffViewInstanceList, oldBuffView) then
            table.insert(self._buffViewInstanceList, buffViewInstance)
        else
            self._buffViewInstanceList[self.removeIndex] = buffViewInstance
        end
    else
        if oldBuffView then
            --当前页最初和最后的索引
            self.curPageEndIndex = self._curPage * self._pageBuffCount
            self.curPageStartIndex = (self._curPage - 1) * self._pageBuffCount + 1
            self.backPreviousPage = false

            table.removev(self._buffViewInstanceList, oldBuffView)
        end
    end
    --排序
    self._buffViewInstanceList = self:OnSortBuffArray(self._buffViewInstanceList)

    self:_GetPageCount()
end

---@param isAdd boolean 是否是添
function UIHPBuffInfo:_OnPlayBuff(isAdd)
    --表现
    if isAdd then --如果是添加   因为添加没有动画   所以直接显示
        self:_OnPlayCurPage()
    else --删除有动画显示
        self.backPreviousPage = self.curPageStartIndex > (self._curPage * self._pageBuffCount)

        --如果是0   当前页切换成上一页
        if #self._buffViewInstanceList == 0 or self.backPreviousPage then
            -- if #self._buffViewInstanceList <= self._pageBuffCount then
            self:_OnPlayCurPage()
            return
        end

        -- local removeIndex = 1
        -- --当前页最初和最后的索引
        -- local curPageEndIndex = self._curPage * self._pageBuffCount
        -- local curPageStartIndex = (self._curPage - 1) * self._pageBuffCount + 1

        -- for i = 1, #self._buffViewInstanceList do
        --     if buffInstance == self._buffViewInstanceList[i] then
        --         removeIndex = i
        --         break
        --     end
        -- end

        --如果删除的是  前页 或者当前页  会有动画
        if self.removeIndex <= self.curPageEndIndex then
            -- 判断 是从1开始  还是从中开始
            local startIndex = 1
            --如果改变索引  大于本页开始  那么从中间某一个开始
            if self.removeIndex > self.curPageStartIndex then
                startIndex = self.removeIndex - self.curPageStartIndex + 1
            end

            --当前页的数量和 拥有的 取一个最小值
            local minCount = math.min(self._pageBuffCount, #self._buffViewInstanceList)

            --先把不改变的关闭
            if minCount + 1 <= self._pageBuffCount then
                for i = minCount + 1, self._pageBuffCount do
                    local buffItem = self._buffItemList[i]
                    buffItem:OnHide()
                end
            end

            --从当前到最后一个
            for i = startIndex, minCount do
                TaskManager:GetInstance():CoreGameStartTask(
                    function(TT)
                        ---@type UIHPBuffItem
                        local buffItem = self._buffItemList[i]
                        buffItem:OnHide()

                        ---@type UIHPBuffItem
                        local animationItem = self:_GetEmptyBuffAnimationItem()
                        local endPos = buffItem:GetGameObject():GetComponent("Transform").localPosition
                        local startPos = endPos + Vector3(self._show_buff_move_distance, 0, 0)

                        buffItem:SetTargetData(self._buffViewInstanceList[i])

                        animationItem:DoMoveTween(
                            self._buffViewInstanceList[i],
                            startPos,
                            endPos,
                            self._show_buff_move_time
                        )
                        YIELD(TT, (self._show_buff_move_time * 1000))

                        buffItem:RefreshData()
                    end
                )
            end
        else --翻页返回
            self:_OnPlayCurPage()
        end
    end
end

function UIHPBuffInfo:_GetPageCount()
    self._pageMax = math.ceil(#self._buffViewInstanceList / self._pageBuffCount)

    --如果变化后 数量小于一页的数量  立刻设置为第一页
    if self._pageMax == 1 then
        self._curPage = 1
    end
end

--获得一个创建出来 没有动画的组件
function UIHPBuffInfo:_GetEmptyBuffAnimationItem()
    for i, item in ipairs(self._buffAnimationList) do
        ---@type UIHPBuffItem
        if not item:IsInMoveTween() then
            return item
        end
    end
    return self._buffAnimationList[#self._buffAnimationList]
end

--播放当前页数据
function UIHPBuffInfo:_OnPlayCurPage()
    --计时重启
    self._show_buff_delta_time = 0

    for i = 1, #self._buffItemList do
        local index = (self._curPage - 1) * self._pageBuffCount + i
        ---@type UIHPBuffItem
        local buffItem = self._buffItemList[i]

        if index <= #self._buffViewInstanceList then
            buffItem:SetData(self._buffViewInstanceList[index])
        else
            buffItem:OnHide()
        end
    end
end

function UIHPBuffInfo:OnRefreshBuffTime(deltaTime)
    --小等于4
    if #self._buffViewInstanceList <= self._pageBuffCount then
        return
    end

    self._show_buff_delta_time = self._show_buff_delta_time + deltaTime
    if self._show_buff_delta_time > self._show_buff_interval_time + self._show_buff_fade_time then
        self._show_buff_delta_time =
            self._show_buff_delta_time - self._show_buff_interval_time - self._show_buff_fade_time

        self:_PlayRefreshPage()
    end
end

--播放翻页
function UIHPBuffInfo:_PlayRefreshPage()
    if self.__playRefreshPageTask then
        TaskManager:GetInstance():KillTask(self.__playRefreshPageTask)
    end

    self.__playRefreshPageTask = TaskManager:GetInstance():CoreGameStartTask(
        function(TT)
            for i = 1, #self._buffItemList do
                local buffItem = self._buffItemList[i]
                ---@type UIHPBuffItem
                buffItem:DoFadeTween(0, self._show_buff_fade_time / 2)
            end
            for i = 1, #self._buffAnimationList do
                local buffItem = self._buffAnimationList[i]
                ---@type UIHPBuffItem
                buffItem:DoFadeTween(0, self._show_buff_fade_time / 2)
            end

            YIELD(TT, (self._show_buff_fade_time / 2 * 1000))

            self:_GetPageCount()

            --判断  是否翻页
            if self._pageMax > 1 then
                self._curPage = self._curPage + 1
                if self._curPage > self._pageMax then
                    self._curPage = 1
                end
            else
                self._curPage = 1
            end

            self:_OnPlayCurPage()

            for i = 1, #self._buffItemList do
                local buffItem = self._buffItemList[i]
                ---@type UIHPBuffItem
                buffItem:DoFadeTween(1, self._show_buff_fade_time / 2)
            end
        end
    )
end

function UIHPBuffInfo:_ShowShieldBuff(remove)
    if not self._shieldRoot then
        return
    end

    local shieldLayer = 0
    ---@type BuffViewInstance
    self._layerShieldViewInstance =
        InnerGameHelperRender.GetSingleBuffByBuffEffect(self._entityId, BuffEffectType.LayerShield)

    if self._layerShieldViewInstance then
        shieldLayer = self._layerShieldViewInstance:GetLayerCount() or 0
    end

    if remove then
        shieldLayer = 0
    end

    if shieldLayer == self._shieldLayer then
        return
    end

    if shieldLayer < self._shieldLayer then
        if shieldLayer == 0 then
            --删除到0
            self._rootAnim:Play("113")
            GameGlobal.TaskManager():CoreGameStartTask(self._delayHideShield, self)

            --移除view
            InnerGameHelperRender.RemoveBuffViewInstance(self._entityId, self._layerShieldViewInstance)
        else
            --修改 减少
            self._rootAnim:Play("112")
        end
    else
        --添加  创建
        if self._shieldRoot.transform.childCount == 0 then
            self._shieldRootPath:SpawnObject(nil)
        end

        if not self._textGo then
            self._textGo = GameObjectHelper.FindChild(self._shieldRoot.transform, "Number")
            self._textShield = self._textGo.gameObject:GetComponent("Text")
        end
        if not self._rootAnimGo then
            self._rootAnimGo = self._shieldRoot.transform:GetChild(0)
            self._rootAnim = self._rootAnimGo.gameObject:GetComponent("Animation")
        end

        self._shieldRoot:SetActive(true)
        self._rootAnim:Play("111")
    end

    self._textShield.text = shieldLayer

    self._shieldLayer = shieldLayer
    InnerGameHelperRender.UISetHPLayerShieldCount(self._entityId, shieldLayer)
    self:_OnSortShieldAndBombPos()
end

function UIHPBuffInfo:_delayHideShield(TT)
    YIELD(TT, 500)
    if self._shieldRoot and self._onShow and self._rootAnim:IsPlaying("111") == false then
        self._shieldRoot:SetActive(false)
    end
    self:_OnSortShieldAndBombPos()
end

function UIHPBuffInfo:OnCheckBuffAnimation()
    if self._initAnimation then
        return
    end

    if not self._rootAnim then
        return
    end

    if self._rootAnim:IsPlaying("111") then
        self._initAnimation = true
        GameGlobal.TaskManager():CoreGameStartTask(self._WaitAnimationInit, self)
    end
end

function UIHPBuffInfo:_WaitAnimationInit(TT)
    self._shieldRoot:SetActive(false)
    self._rootAnim:Stop()

    YIELD(TT)

    if self._shieldRoot then
        self._shieldRoot:SetActive(true)
        self._rootAnim:Play("111")
    end
    self:_OnSortShieldAndBombPos()
end

---血条破坏效果（圣物裂解水晶特效）
function UIHPBuffInfo:OnHPSliderBroken(entityID)
    if self._entityId ~= entityID then
        return
    end

    if not self._brokenRoot then
        return
    end

    --添加  创建
    if self._brokenRoot.transform.childCount == 0 then
        self._brokenRootPath:SpawnObject(nil)
    end

    self._brokenRoot:SetActive(true)
end

---排序 BuffViewInstance数组
function UIHPBuffInfo:OnSortBuffArray(buffViewArray)
    table.sort(
        buffViewArray,
        function(a, b)
            --id相同
            if a:BuffID() == b:BuffID() then
                return a:BuffSeq() < b:BuffSeq()
            end
            --id 小在前
            return a:BuffID() < b:BuffID()
        end
    )

    return buffViewArray
end

---刷新血量自爆显示层数
function UIHPBuffInfo:OnRefreshHPBombLayer(entityID, layerCount)
    if self._entityId ~= entityID then
        return
    end

    if not self._bombRoot then
        return
    end

    self._bombRoot:SetActive(layerCount > 0)
    self._textBomb.text = layerCount

    -- self:_OnSortShieldAndBombPos()

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            --等待一帧 activeSelf
            YIELD(TT)
            self:_OnSortShieldAndBombPos()
        end
    )
end

---排序层数护盾和炸弹的坐标
function UIHPBuffInfo:_OnSortShieldAndBombPos()
    if self._bombRoot and self._bombRoot.gameObject and self._bombRoot.gameObject.activeSelf then
        local pos =
            (self._textShield and self._shieldRoot.gameObject.activeSelf) and Vector2(135, -25) or Vector2(90, -25)
        self._bombTransform.anchoredPosition = pos
    end

    if self._antiRoot and self._antiRoot.gameObject and self._antiRoot.gameObject.activeSelf then
        local posAnti = Vector2(90, -25)
        if self._shieldRoot.gameObject.activeSelf and self._textShield then
            posAnti = posAnti + Vector2(45, 0)
        end
        if self._bombRoot.gameObject.activeSelf then
            posAnti = posAnti + Vector2(45, 0)
        end
        self._antiTransform.anchoredPosition = posAnti
    end
	
    if self._chessHPRoot and self._chessHPRoot.activeSelf and self._shieldRoot then
        self._shieldRoot.transform.anchoredPosition = Vector2(50, 25)
    end
end

---刷新反制光灵主动技信息
function UIHPBuffInfo:UpdateAntiActiveSkill(entityID, showCD)
    if entityID ~= self._entityId then
        return
    end
    if not self._antiRoot then
        return
    end

    local antiSkillEnabled = InnerGameHelperRender.GetEntityAttribute(entityID, "AntiSkillEnabled")
    local maxCount = InnerGameHelperRender.GetEntityAttribute(entityID, "MaxAntiSkillCountPerRound")
    local antiCD = InnerGameHelperRender.GetEntityAttribute(entityID, "WaitActiveSkillCount")
    -- (本回合剩余>0 and 激活状态) or 传了强制显示的数值
    local show = (maxCount ~= 0 and antiSkillEnabled == 1) or showCD ~= nil
    self._antiRoot.gameObject:SetActive(show)

    local originalCount = InnerGameHelperRender.GetEntityAttribute(entityID, "OriginalWaitActiveSkillCount")
    --初始是1的不显示（max也是1的）,从321这种递减的在1的时候显示
    self._textAnti.gameObject:SetActive(originalCount ~= 1)
    --用于一个buff表现中刷新2次的显示，强制传1来让实际0的时候显示为1
    if showCD then
        antiCD = showCD
    end
    self._textAnti:SetText(antiCD)

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            --等待一帧 activeSelf
            YIELD(TT)
            self:_OnSortShieldAndBombPos()
        end
    )
end
