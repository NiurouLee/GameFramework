--
---@class UIMedalGroupApply : UIController
_class("UIMedalGroupApply", UIController)
UIMedalGroupApply = UIMedalGroupApply

function UIMedalGroupApply:Constructor() 
end
--初始化
function UIMedalGroupApply:OnShow(uiParams)
    self:InitWidget()
    self:CreateData()
    self:OnValue()
end
--获取所有有的套组配置
function UIMedalGroupApply.GetAllCollectAnyGroup()
    local cfgs = Cfg.cfg_item_medal_group{}
    local loginModule = GameGlobal.GetModule(LoginModule)
    local svrTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime()*0.001
    
    local allHaveGroup = {}

    for key, value in pairs(cfgs) do
        local insert = true
        if value.UnLockTime then
            local type = value.TimeTransform
            local timeType = Enum_DateTimeZoneType.E_ZoneType_ServerTimeZone
            if type and type == 0 then
                timeType = Enum_DateTimeZoneType.E_ZoneType_GMT
            end
            local openTime = loginModule:GetTimeStampByTimeStr(value.UnLockTime,timeType)
            if svrTime<openTime then
                insert = false
            end
        end
        if insert then
            if UIMedalGroupApply.CheckGroupCollect(value) then
                table.insert(allHaveGroup,value)
            end
        end
    end
    return allHaveGroup
end
--获取勋章获取
function UIMedalGroupApply.CheckGroupCollect(cfg)
    local haveBgNum = UIMedalGroupApply.CheckBgCollect(cfg)
    local haveMedalNum = UIMedalGroupApply.CheckMedalListCollect(cfg)
    return haveBgNum>0 or haveMedalNum>0
end
function UIMedalGroupApply.CheckBgCollect(data)
    local itemModule = GameGlobal.GetModule(ItemModule)
    local boardid = data.BoardID
    local bg_items = itemModule:GetItemByTempId(boardid)
    local bg_have = (bg_items and next(bg_items))
    if bg_have then
        return 1
    end
    return 0
end
function UIMedalGroupApply.CheckMedalListCollect(data)
    local medals = data.MedalIDList
    local haveCount = 0
    for key, value in pairs(medals) do
        local medalid = value[1]
        local have = UIMedalGroupApply.CheckMedalCollect(medalid)
        if have then
            haveCount=haveCount+1
        end
    end
    return haveCount
end
function UIMedalGroupApply.CheckMedalCollect(id)
    local itemModule = GameGlobal.GetModule(ItemModule)
    local items = itemModule:GetItemByTempId(id)
    if items and next(items) then
        return true
    end
    return false
end
function UIMedalGroupApply:CreateData()
    self._allHaveGroup = UIMedalGroupApply.GetAllCollectAnyGroup()
    table.sort(self._allHaveGroup,function(a,b)
        return a.Sort<b.Sort
    end)
end
function UIMedalGroupApply:OnValue()    
    self.pool:SpawnObjects("UIMedalGroupApplyItem",#self._allHaveGroup)
    ---@type UIMedalGroupApplyItem[]
    local pools = self.pool:GetAllSpawnList()
    for i = 1, #self._allHaveGroup do
        local item = pools[i]
        local data = self._allHaveGroup[i]
        item:SetData(i,data,function(idx)
            self:ItemOnClick(idx)
        end,self.atlas)
    end
end
function UIMedalGroupApply:ItemOnClick(idx)
    local data = self._allHaveGroup[idx]
    --检查拥有board
    local haveBgNum = UIMedalGroupApply.CheckBgCollect(data)
    local bgid = nil
    if haveBgNum and haveBgNum>0 then
        bgid = data.BoardID
    end
    --检查拥有list
    local list = {}
    for index, value in ipairs(data.MedalIDList) do
        local id = value[1]
        local have = UIMedalGroupApply.CheckMedalCollect(id)
        if have then
            table.insert(list,value)
        end
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMedalGroupApply,data.ID,list,bgid)
    ToastManager.ShowToast(StringTable.Get("str_medal_group_apply_succ"))
    self:CloseDialog()
end
--获取ui组件
function UIMedalGroupApply:InitWidget()
    self.atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)

    self.pool = self:GetUIComponent("UISelectObjectPath", "Content")

    local topButton = self:GetUIComponent("UISelectObjectPath", "topbtn")
    ---@type UICommonTopButton
    self.topButtonWidget = topButton:SpawnObject("UICommonTopButton")
    self.topButtonWidget:SetData(
        function()
            self:CloseDialog()
        end,nil,nil,true
    )
end
function UIMedalGroupApply:BgOnClick(go)
    self:CloseDialog()
end