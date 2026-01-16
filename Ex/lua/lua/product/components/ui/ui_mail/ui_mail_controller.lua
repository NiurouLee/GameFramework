---@class UIMailController:UIController
_class("UIMailController", UIController)
UIMailController = UIMailController

function UIMailController:OnShow(uiParams)
    self.InitedMailList = false
    --获取组件
    self._mailCountLabel = self:GetUIComponent("UILocalizationText", "MailCount")
    self._unReadMailCountLabel = self:GetUIComponent("UILocalizationText", "UnReadMailCount")
    self._unReadMailCountTitleGo = self:GetGameObject("UnReadMailCountTitle")
    self._mailEmptyIconGo = self:GetGameObject("MailEmptyIcon")
    self._scrollView = self:GetUIComponent("UIDynamicScrollView", "MailList")

    --获取组件
    local backBtns = self:GetUIComponent("UISelectObjectPath", "BackBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end
    )
    self._mailModule = GameGlobal.GetModule(MailModule)
    self._currentTimeEvent =
        GameGlobal.RealTimer():AddEventTimes(1000, TimerTriggerCount.Infinite, self.OnOneMinusUpdate, self)
    self:AttachEvent(GameEventType.ModuleMailNotifyNewMail, self._ReceiveNewMail)
    self:AttachEvent(GameEventType.ModuleMailNotifyExpiredMail, self._MailExpired)
    --初始化数据
    self:_RefreshMailData()
    self:_RefreshMailInfoPanel()
    self:_InitScrollView()
    self:_RefreshMailEmptyIconStatus()
    --缓存星灵数据
    self:_CachePetIdList()
end

function UIMailController:_RefreshMailEmptyIconStatus()
    if self._mailCount <= 0 then
        self._mailEmptyIconGo:SetActive(true)
    else
        self._mailEmptyIconGo:SetActive(false)
    end
end

function UIMailController:_CachePetIdList()
    local petModule = GameGlobal.GetModule(PetModule)
    petModule:GetAllPetsSnapshoot()
end

function UIMailController:_ReceiveNewMail()
    GameGlobal.TaskManager():StartTask(self._SendLoadAllMailDatasMsg, self)
end

function UIMailController:_SendLoadAllMailDatasMsg(TT)
    local ack, resMailData = self._mailModule:LoadAllMails(TT)
    if not ack:GetSucc() then
        ToastManager.ShowToast("receive mail data error")
    end
    self:_Refresh()
end

function UIMailController:_MailExpired()
    ToastManager.ShowToast(StringTable.Get("str_mail_has_expire"))
    self:_Refresh()
end

function UIMailController:LoadDataOnEnter(TT, res, uiParams)
    local mailModule = GameGlobal.GetModule(MailModule)
    local ack, resMailData = mailModule:LoadAllMails(TT)
    if ack:GetSucc() then
        res:SetSucc(true)
    else
        res:SetSucc(false)
        ToastManager.ShowToast("receive mail data error")
    end
end

function UIMailController:OnOneMinusUpdate()
    if not self._mailDatas then
        return
    end
    for k, v in pairs(self._mailDatas) do
        v.remainSeconds = v.remainSeconds - 1
        if v.remainSeconds <= 0 then
            v.remainSeconds = 0
        end
    end
end

function UIMailController:OnHide()
    if self._currentTimeEvent then
        GameGlobal.RealTimer():CancelEvent(self._currentTimeEvent)
        self._currentTimeEvent = nil
    end
    self:DetachEvent(GameEventType.ModuleMailNotifyNewMail, self._ReceiveNewMail)
    self:DetachEvent(GameEventType.ModuleMailNotifyExpiredMail, self._MailExpired)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshMailStatus)
end

--领取刷新邮件数据 只在领取时调用
function UIMailController:_RecvRefreshMailData(mail_id, isGain, isRead, isExpired)
    self._maxMailCount = Cfg.cfg_global["MailLimitNum"].IntValue
    local delete_index = nil
    local isNotFind = true
    for i, v in ipairs(self._mailDatas) do
        if v.id == mail_id then
            isNotFind = false
            if isExpired then
                delete_index = i
                break
            end
            if isGain then -- 领取直接设置为查看
                v.isGain = true
                isRead = true
            end
            if isRead then
                v.isRead = true
            end
            break
        end
    end
    if isExpired and delete_index ~= nil then
        table.remove(self._mailDatas, delete_index)
    end
    Log.debug("_________________isNotFind:", isNotFind)
    if isNotFind then
        self:_RefreshMailData()
    end
    self:_CalMailData()
end

--刷新邮件数据
function UIMailController:_RefreshMailData()
    self._maxMailCount = Cfg.cfg_global["MailLimitNum"].IntValue
    self._mailDatas = {}
    --数据类型说明
    --[[
        mailData.id = 1 --邮件ID，全局唯一
        mailData.isGain = true --邮件附件是否已领取true已领取false未领取
        mailData.isRead = false --邮件附件是否已读true已读false未读
        mailData.title = "邮件标题"
        mailData.content = "邮件内容"
        mailData.senderName = "发送者名字"
        mailData.createTime = "2020-01-12" --邮件创建时间
        mailData.remainSeconds = 1000 ---邮件剩余时间
        mailData.mailIcon = "icon_item_3100014" --邮件图标
        mailData.rewards = {
            [1] = {reward.assetid = 3000001, reward.count = 10}
        }
        mailData.hasReward = true
    ]]
    local allMailData = self._mailModule:GetAllMailData()
    local mailCount = table.count(allMailData)
    for i = 1, mailCount do
        local mailInfo = allMailData[i]
        table.insert(self._mailDatas, self:_GetMailData(mailInfo))
    end
    self:_CalMailData()
end

function UIMailController:_GetMailData(mailInfo)
    local mailData = {}
    mailData.id = mailInfo.mail_id
    mailData.isGain = mailInfo.is_gain
    mailData.isRead = mailInfo.is_read
    mailData.mailIcon = mailInfo.sender_icon_id
    if mailInfo.mail_type == MailType.MAIL_TYPE_GM_SYSTEM_NOTICE then
        mailData.title = mailInfo.title_id
        mailData.content = mailInfo.content_id
        mailData.senderName = mailInfo.sender_nick
    elseif mailInfo.mail_type == MailType.MAIL_TYPE_ITEM_CONVER then
        mailData.title = StringTable.Get(mailInfo.title_id)
        mailData.senderName = StringTable.Get(mailInfo.sender_nick)
        local content_id_ext = mailInfo.content_id_ext
        if content_id_ext and content_id_ext.assetid > 0 then
            local tb = Cfg.cfg_item[content_id_ext.assetid]
            if tb then
                local converId = tb.ConverId
                if converId and converId > 0 then
                    local converIdCfg = Cfg.cfg_item[converId]
                    if converIdCfg then
                        mailData.content = StringTable.Get(mailInfo.content_id, StringTable.Get(tb.Name),
                            content_id_ext.count, StringTable.Get(converIdCfg.Name))
                    else
                        mailData.content = StringTable.Get(mailInfo.content_id, StringTable.Get(tb.Name),
                            content_id_ext.count)
                    end
                else
                    mailData.content = StringTable.Get(mailInfo.content_id, StringTable.Get(tb.Name),
                        content_id_ext.count)
                end
            else
                mailData.content = StringTable.Get(mailInfo.content_id)
            end
        else
            mailData.content = StringTable.Get(mailInfo.content_id)
        end
    elseif mailInfo.mail_type == MailType.MAIL_TYPE_FIX_ITEM then
        mailData.title = StringTable.Get(mailInfo.title_id)
        local contentParams = mailInfo.content_param
        local paramTab = {}
        for i = 1, #contentParams do
            if i % 3 == 1 then
                local itemid = tonumber(contentParams[i])
                local cfg_item = Cfg.cfg_item[itemid]
                if not cfg_item then
                    Log.error("###[mail] cfg_item is nil ! id --> ", itemid)
                end
                local itemName = StringTable.Get(cfg_item.Name) or ""
                table.insert(paramTab, itemName)
            else
                table.insert(paramTab, contentParams[i])
            end
        end
        mailData.content = StringTable.Get(mailInfo.content_id, table.unpack(paramTab))
        mailData.senderName = StringTable.Get(mailInfo.sender_nick)
    elseif mailInfo.mail_type == MailType.MAIL_TYPE_TOWER_COMPENTSATE then
        mailData.title = StringTable.Get(mailInfo.title_id)
        mailData.content = StringTable.Get(mailInfo.content_id, table.unpack(mailInfo.content_param))
        mailData.senderName = StringTable.Get(mailInfo.sender_nick)
    elseif mailInfo.mail_type == MailType.MAIL_TYPE_TEXT_CONVER then --赛季道具转化
        mailData.title = StringTable.Get(mailInfo.title_id)
        mailData.senderName = StringTable.Get(mailInfo.sender_nick)
        local contentParams = mailInfo.content_param
        --服务器下发的参数4个一组 格式为{[1]=源道具ID,[2]=源道具数量,[3]=目标道具ID,[4]=目标道具数量}
        --赛季最终的转化关系只支持两种:a转化为b或者a、b转化成c、d
        if contentParams and #contentParams % 4 == 0 then
            local groupCount = #contentParams / 4
            local from, to = {}, {} --key是id value是数量
            for i = 1, groupCount do
                local group     = i - 1
                local fromID    = tonumber(contentParams[group * 4 + 1])
                local fromCount = tonumber(contentParams[group * 4 + 2])
                local toID      = tonumber(contentParams[group * 4 + 3])
                local toCount   = tonumber(contentParams[group * 4 + 4])
                if from[fromID] then
                    from[fromID] = from[fromID] + fromCount
                else
                    from[fromID] = fromCount
                end
                if to[toID] then
                    to[toID] = to[toID] + toCount
                else
                    to[toID] = toCount
                end
            end

            local params = {}
            local strKey
            if table.count(from) == 1 and table.count(to) == 1 then
                for id, count in pairs(from) do
                    local name = StringTable.Get(Cfg.cfg_item[id].Name)
                    table.insert(params, name)
                    table.insert(params, count)
                    break --只有1个
                end
                for id, count in pairs(to) do
                    local name = StringTable.Get(Cfg.cfg_item[id].Name)
                    table.insert(params, name)
                    table.insert(params, count)
                    break
                end
                strKey = mailInfo.content_id .. "_1" --策划只能配1个key 根据数量拼出来key
            elseif table.count(from) == 2 and table.count(to) == 2 then
                for id, count in pairs(from) do
                    local name = StringTable.Get(Cfg.cfg_item[id].Name)
                    table.insert(params, name)
                    table.insert(params, count)
                end
                for id, count in pairs(to) do
                    local name = StringTable.Get(Cfg.cfg_item[id].Name)
                    table.insert(params, name)
                    table.insert(params, count)
                end
                strKey = mailInfo.content_id .. "_2" --策划只能配1个key 根据数量拼出来key
            else
                Log.exception("赛季邮件参数错误2", echo(contentParams))
            end
            mailData.content = StringTable.Get(strKey, table.unpack(params))
        else
            Log.exception("赛季邮件参数错误1", echo(contentParams))
        end
    else
        mailData.title = StringTable.Get(mailInfo.title_id)
        mailData.content = StringTable.Get(mailInfo.content_id)
        mailData.senderName = StringTable.Get(mailInfo.sender_nick)
    end
    mailData.createTimeSeconds = mailInfo.create_time
    mailData.createTime = TimeToDate(mailInfo.create_time, "day") --邮件创建时间
    mailData.remainSeconds = mailInfo.remain_time
    mailData.rewards = mailInfo.appendix
    if mailData.rewards ~= nil and table.count(mailData.rewards) > 0 then
        mailData.hasReward = true
    end
    return mailData
end

function UIMailController:_CalMailData()
    self._mailDatas = self:_SortMailData(self._mailDatas)
    self._mailCount = table.count(self._mailDatas)
    self._unReadMailCount = 0
    for i = 1, self._mailCount do
        local mailData = self._mailDatas[i]
        if mailData.isRead == false then
            self._unReadMailCount = self._unReadMailCount + 1
        end
    end
end

function UIMailController:_SortMailData(mailDatas)
    table.sort(
        mailDatas,
        function(a, b)
            if a.isRead ~= b.isRead then
                return b.isRead                         -- 未读优先
            end
            local isGainA = not a.hasReward or a.isGain -- [true] = 不包含奖励 或者 包含奖励并且已领取，即【已领取奖励】
            local isGainB = not b.hasReward or b.isGain
            if isGainA ~= isGainB then
                return isGainB -- 未领取优先
            end
            if a.createTimeSeconds ~= b.createTimeSeconds then
                return a.createTimeSeconds > b.createTimeSeconds -- 创建时间更靠后优先
            end
            return a.id < b.id                                   --全都相同 按id排
        end
    )
    return mailDatas
end

--刷新邮件信息面板
function UIMailController:_RefreshMailInfoPanel()
    self._mailCountLabel.text = "<color=#ffd300>" .. self._mailCount .. "</color>" .. " / " .. self._maxMailCount
    self._unReadMailCountLabel.text = self._unReadMailCount
end

function UIMailController:_SetListItemCount()
    self._scrollView:SetListItemCount(self._mailCount, false)
end

function UIMailController:_InitScrollView()
    self._scrollView:InitListView(
        self._mailCount,
        function(scrollview, index)
            return self:_OnGetMailItem(scrollview, index)
        end,
        self:GetScrollViewParam()
    )
    self.InitedMailList = true
end

function UIMailController:GetScrollViewParam()
    local param = UIDynamicScrollViewInitParam:New()
    param.mItemDefaultWithPaddingSize = 240
    return param
end

function UIMailController:_OnGetMailItem(scrollView, index)
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIMailItem", 1)
    end
    local rowList = rowPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    if itemWidget then
        local itemIndex = index + 1
        if itemIndex > self._mailCount then
            itemWidget:GetGameObject():SetActive(false)
        else
            self:_RefreshMailItemInfo(itemWidget, itemIndex)
        end
    end
    UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end

function UIMailController:_RefreshMailItemInfo(itemWidget, index)
    -- index 从1开始
    itemWidget:Refresh(self, self._mailDatas[index])
end

function UIMailController:_Refresh()
    self:_RefreshMailData()
    self:_SetListItemCount()
    self._scrollView:RefreshAllShownItem()
    self:_RefreshMailInfoPanel()
    self:_RefreshMailEmptyIconStatus()
end

-- 改函数是为了防止重新拉取数据导致邮件剩余时间重置
function UIMailController:_RecvRefresh(mail_id, isGain, isRead, isExpired)
    self:_RecvRefreshMailData(mail_id, isGain, isRead, isExpired)
    self:_SetListItemCount()
    self._scrollView:RefreshAllShownItem()
    self:_RefreshMailInfoPanel()
    self:_RefreshMailEmptyIconStatus()
end

-- ============================================ 点击事件 =========================================

--删除所有已读的邮件
function UIMailController:BtnDeleteAllReadedMailOnClick(go)
    self:Lock("DeleteAllReadedMailLock")
    GameGlobal.TaskManager():StartTask(self._SendDeleteAllReadedMailMsg, self)
end

function UIMailController:_SendDeleteAllReadedMailMsg(TT)
    local res = self._mailModule:RequestBatchDeleteMail(TT)
    self:UnLock("DeleteAllReadedMailLock")
    if res.m_result == MailErrorCode.MAIL_SUCC then
        self:_Refresh()
        return
    end
end

--领取所有奖励
function UIMailController:BtnCollectedRewardOnClick(go)
    self:Lock("CollectedAllRewardsLock")
    GameGlobal.TaskManager():StartTask(self._SendCollectedAllRewardsMsg, self)
end

function UIMailController:_SendCollectedAllRewardsMsg(TT)
    local res, rewards = self._mailModule:RequestBatchReceiveAppendix(TT)
    self:UnLock("CollectedAllRewardsLock")
    if res.m_result == MailErrorCode.MAIL_SUCC then
        if rewards then
            self:_ShowRewards(rewards)
        end
    end
    self:_Refresh()
end

function UIMailController:_ShowRewards(rewards, callback)
    UiMailHelper.ShowUIGetRewards(rewards, callback)
    do
        return
    end
    -- local petIdList = {}
    -- local petModule = GameGlobal.GetModule(PetModule)
    -- for _, reward in pairs(rewards) do
    --     if petModule:IsPetID(reward.assetid) then
    --         table.insert(petIdList, reward)
    --     end
    -- end
    -- if table.count(petIdList) > 0 then
    --     self:ShowDialog(
    --         "UIPetObtain",
    --         petIdList,
    --         function()
    --             self:Manager():CloseDialog("UIPetObtain")
    --             self:ShowDialog(
    --                 "UIGetItemController",
    --                 rewards,
    --                 function()
    --                     if callback then
    --                         callback()
    --                     end
    --                 end
    --             )
    --         end
    --     )
    --     return
    -- end
    -- self:ShowDialog(
    --     "UIGetItemController",
    --     rewards,
    --     function()
    --         if callback then
    --             callback()
    --         end
    --     end
    -- )
end

--============================================ 对外接口 ===========================================

function UIMailController:ReadMail(mailData)
    if not mailData then
        return
    end
    self:Lock("ReadMailLock")
    GameGlobal.TaskManager():StartTask(self._SendReadMailMsg, self, mailData)
end

function UIMailController:_SendReadMailMsg(TT, mailData)
    local res = self._mailModule:RequestReadMail(TT, mailData.id)
    self:UnLock("ReadMailLock")
    Log.debug("_______________________res.m_result:", res.m_result)
    if res.m_result == MailErrorCode.MAIL_SUCC or res.m_result == MailErrorCode.MAIL_ALREADY_READ then
        self:ShowDialog("UIMailContentController", mailData, self)
        self:_RecvRefresh(mailData.id, false, true, false)
        return
    elseif res.m_result == MailErrorCode.MAIL_ERR_MAIL_EXPIRED then
        ToastManager.ShowToast(StringTable.Get("str_mail_has_expire"))
        self:_RecvRefresh(mailData.id, false, true, true) -- 过期邮件删除
        return
    end

    self:_Refresh()
end

function UIMailController:CollectedReward(mailData, callback)
    if not mailData then
        return
    end
    self:Lock("CollectedMailLock")
    GameGlobal.TaskManager():StartTask(self._SendCollectedRewardMsg, self, mailData, callback)
end

function UIMailController:_SendCollectedRewardMsg(TT, mailData, callback)
    local res, rewards = self._mailModule:RequestReceiveAppendix(TT, mailData.id)
    self:UnLock("CollectedMailLock")
    if res.m_result == MailErrorCode.MAIL_SUCC then
        self:_RecvRefresh(mailData.id, true, true, false)
        --self:_Refresh()
        mailData.isGain = true
        mailData.isRead = true
        if rewards then
            self:_ShowRewards(
                rewards,
                function()
                    if callback then
                        callback(true)
                    end
                end
            )
        end
        return
    end
    if res.m_result == MailErrorCode.MAIL_ERR_MAIL_EXPIRED then
        if callback then
            callback(false)
        end
        ToastManager.ShowToast(StringTable.Get("str_mail_has_expire"))
        self:_RecvRefresh(mailData.id, true, true, true) -- 过期邮件删除
        return
    elseif res.m_result == MailErrorCode.MAIL_ERR_PHY_IS_LIMIT then
        ToastManager.ShowToast(StringTable.Get("str_physicalpower_error_phy_add_full"))
        return
    elseif res.m_result == MailErrorCode.MAIL_ERR_ASSET_DOUBLE_RES_LIMIT then
        ToastManager.ShowToast(StringTable.Get("str_mail_maxcarrier_tip"))
        return
    end
    --self:_RecvRefresh(mailData.id, true, true)
    self:_Refresh()
end

function UIMailController:DeleteMail(mailData, callback)
    if not mailData then
        return
    end
    self:Lock("DeleteMailLock")
    GameGlobal.TaskManager():StartTask(self._SendDeleteMailMsg, self, mailData, callback)
end

function UIMailController:_SendDeleteMailMsg(TT, mailData, callback)
    local res = self._mailModule:RequestDeleteMail(TT, mailData.id)
    self:UnLock("DeleteMailLock")
    if res.m_result == MailErrorCode.MAIL_SUCC then
        self:_Refresh()
        if callback then
            callback(true)
        end
        return
    end
    if res.m_result == MailErrorCode.MAIL_ERR_MAIL_HAVE_APPENDIX then
        ToastManager.ShowToast(StringTable.Get("str_mail_has_reward_ungain"))
    end
    if callback then
        callback(false)
    end
end

--=================================================================================================
