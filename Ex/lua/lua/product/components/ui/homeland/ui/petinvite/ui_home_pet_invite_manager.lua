---@class HomelandPetInviteManager:Object
_class("HomelandPetInviteManager",Object)
HomelandPetInviteManager = HomelandPetInviteManager

--- @class PetInviteStateEnum
local PetInviteStateEnum = {
   Success = 1, -- 正常邀请
   AllBusy = 2, -- 所有都是忙碌状态
   AllInvite = 3, -- 所有都是邀請
   AllOut = 4, -- 所有都是撤下
   
}
_enum("PetInviteStateEnum", PetInviteStateEnum)

function HomelandPetInviteManager:Constructor()

end
---@param homelandClient HomelandClient
function HomelandPetInviteManager:Init(homelandClient)
   ---@type HomelandClient 
   self._homelandClient = homelandClient
   ---@type HomeBuildManager
   self._buildManager = self._homelandClient:BuildManager()
   ---@type PetModule
   self._petModule = GameGlobal.GetModule(PetModule)
   ---@type HomelandModule
   self._homelandModule = GameGlobal.GetModule(HomelandModule)
   ---@type HomelandCharacterManager
   self._characterManager = self._homelandClient:CharacterManager()
   ---@type SvrTimeModule
   self._timeModule = GameGlobal.GetModule(SvrTimeModule)
   ---@type HomelandTaskManager
   self._homelandTaskManager = self._homelandClient:GetHomelandTaskManager()
   ---@type HomelandPetManager
   self._homelandPetManager = self._homelandClient:PetManager()
   --邀请缓存列表 
   ---@type  table<HomelandPet>
   -- 新邀请的
   self._inviteEnterList = {}
   -- 返回到附近列表的
   self._inviteOutList = {}

   -- 正在互动的的列表
   self._interactingList = {}
   -- cd 队列
   self._cdQueue = {}

   self._CD = Cfg.cfg_homeland_global["PetInvinteCD"].IntValue*1000
   self._checkDistance = Cfg.cfg_homeland_global["PetInvinteRange"].IntValue 

   local cfg = Cfg.cfg_homeland_pet_behavior_lib{BehaviorType = HomelandPetBehaviorType.InteractingFurniture}
   self._buildCfgCheckDistance = cfg[1].Range

   self:StartTimer()

   self._dataChanged = false
   ---@type  HomelandPet
   self._lastOperatePet = nil 

   self._interactPointLimit = false --当前选中的交互点是否有光灵限制
   self._interactPointPets = {} --限制交互的光灵
   self._invitedPets = {} --当前选择的光灵和交互点绑定关系

   self._homelandPetInviteRefresh =  GameHelper:GetInstance():CreateCallback(self.RefreshInteractingList, self)
   GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnPetBehaviorInteractingFurniture, self._homelandPetInviteRefresh )

   self._onHomeInteractClose =  GameHelper:GetInstance():CreateCallback(self.OnHomePetInteractCloseForInivte, self)
   GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnHomePetInteractCloseForInivte, self._onHomeInteractClose )
end 

function HomelandPetInviteManager:Dispose()
   if self._homelandPetInviteRefresh then 
      GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnPetBehaviorInteractingFurniture, self._homelandPetInviteRefresh )
      self._homelandPetInviteRefresh = nil 
   end 

  if self._onHomeInteractClose then 
      GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnHomePetInteractCloseForInivte, self._onHomeInteractClose )
      self._onHomeInteractClose = nil 
   end 
   self:CancelTimer()
   self._homelandClient = nil 
   self._lastOperatePet = nil 
   self._interactPointLimit = false
   table.clear(self._interactPointPets)
   table.clear(self._invitedPets)
end

function HomelandPetInviteManager:SetOperateBuilding(building,inviteItemId)
   ---@type HomeBuilding
   self._building = building
   self._inviteItemId = 1 
   self._maxCapacity =  self._building:GetInteractingPetCountMax()
end

function HomelandPetInviteManager:GetOperateBuilding()
   return  self._building 
end

function HomelandPetInviteManager:GetCfg(petID)
   --  local cfgs = Cfg.cfg_homeland_event{PetID = petID,}
   --  Cfg.cfg_homeland_building_pet{PetID = petID,}
   --  local cfg_pet_skin = Cfg.cfg_pet_skin[petSkin]
   --  cfg = Cfg.cfg_item_architecture[architecture.asset_id]
end

function HomelandPetInviteManager:Update()

end 
-- 有状态变化
function HomelandPetInviteManager:HaveChange()
   local state = PetInviteStateEnum.Success
   self._dataChanged = false
   local buildid = self._building:InsID()
   -- 全部邀请
   if  #self._inviteEnterList > 0 and #self._inviteOutList == 0  then
      for i = 1, #self._inviteEnterList do
         if not self:CheckInInteractingList(self._inviteEnterList[i],buildid,self._inviteItemId) then
            self._dataChanged =  true 
            state = PetInviteStateEnum.AllInvite
            break
         end 
      end
      return self._dataChanged,state
   end 
   -- 全部撤下
   if  #self._inviteEnterList == 0 and #self._inviteOutList > 0  then
      for i = 1, #self._inviteOutList do
         if self:CheckInInteractingList(self._inviteOutList[i],buildid,self._inviteItemId) then
            self._dataChanged =  true 
            state = PetInviteStateEnum.AllOut
            break
         end 
      end
      return self._dataChanged,state
   end 
   local entercount =  self._inviteEnterList and #self._inviteEnterList or 0 
   local outcount = self._inviteOutList and #self._inviteOutList or 0 

   local haveChange = false 
   if entercount ~= outcount then
      haveChange = true
   else 
      --部分差异
      for index, value in ipairs(self._inviteOutList) do
         if not self:CheckInList(self._inviteEnterList,value ) then 
            haveChange = true 
            break
         end 
      end
   end 

   self._dataChanged = haveChange
   return self._dataChanged,state
end

function HomelandPetInviteManager:OnModeChanged(mode)
   self._mode = mode

   self._nearInviteEnablePet = {}
   self._inviteEnterList = {}
   self._inviteOutList = {}
  -- self._interactingList =  {}
end 

function HomelandPetInviteManager:GetLimitCD()
   return self._CD
end 

function HomelandPetInviteManager:GetContainerCount () 
   --return 1 
   return  self._maxCapacity
end 

function HomelandPetInviteManager._SortFun1(x,y)
   local xCfg = Cfg.cfg_pet[x:TemplateID()]
   local yCfg = Cfg.cfg_pet[y:TemplateID()]

   if xCfg.Star == yCfg.Star then 
      return  xCfg.ID < yCfg.ID 
   end 
   return  xCfg.Star < yCfg.Star 
end

function HomelandPetInviteManager._SortFun2(x,y)
   local xCfg = Cfg.cfg_pet[x:TemplateID()]
   local yCfg = Cfg.cfg_pet[y:TemplateID()]

   if xCfg.Star == yCfg.Star then 
      return  xCfg.ID > yCfg.ID 
   end 
   return  xCfg.Star > yCfg.Star 
end

function HomelandPetInviteManager:_RemoveFun(tb,pet)
   if tb ~= nil and pet ~= nil  then 
      for i=#tb ,1 ,-1 do
         if pet:TemplateID() == tb[i]:TemplateID() then
            table.remove(tb,i)
         end 
      end
   end
end

function HomelandPetInviteManager:_AddFun(tb,pet)
   if tb ~= nil and pet ~= nil  then 
      for i=#tb ,1 ,-1 do
         if pet:TemplateID() == tb[i]:TemplateID() then
            return 
         end 
      end
   end
   table.insert(tb,pet)
end 

-- 检测正在邀请的队列
function HomelandPetInviteManager:CheckInList(list,pet)
   if not list then
      return false  
   end 
   for key, value in pairs(list) do
      if value:TemplateID() == pet:TemplateID() then 
         return true 
      end 
   end
   return false  
end 

function HomelandPetInviteManager:GetInviteEnterList()
   return self._inviteEnterList
end 

function HomelandPetInviteManager:GetInviteOutList()
   return self._inviteOutList
end 

function HomelandPetInviteManager:CheckIsSwimming(pet)
   local isSwimming = false 
   if pet:GetPetBehavior():GetCurBehavior():GetBehaviorType() == HomelandPetBehaviorType.SwimmingPool then 
      local behaviorSwimmingPool =  pet:GetPetBehavior():GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
      isSwimming =  behaviorSwimmingPool
   end 
   return isSwimming
end 
-- 一個交换
function HomelandPetInviteManager:ExchangeInvitetingItem(pet,isAdd)
   local buildid = self._building:InsID()
   local interactingPet = self:GetInteractingList(buildid,self._inviteItemId)
   if #interactingPet > 0  then
      -- 忙碌中
      local isbusy = self:CheckIsBusy(interactingPet[1])
      -- 游泳状态
      --isbusy = isbusy or self:CheckIsSwimming(interactingPet[1])

      if isbusy then 
         ToastManager.ShowHomeToast(StringTable.Get("str_homeland_invite_item_busy"))
         return 
      end 
   end 
   if not self._inviteEnterList then 
      self._inviteEnterList = {}
   end 
   if not self._inviteEnterList then 
      self._inviteOutList = {}
   end 
   if isAdd then
      self._inviteEnterList[1] = pet
      self._inviteOutList = {}
      if #interactingPet > 0 and interactingPet[1]:TemplateID() ~= pet:TemplateID() then 
         self._inviteOutList[1] = interactingPet[1]
      end 
   else 
      if #self._inviteEnterList > 0  and self._inviteEnterList[1]:TemplateID()  == pet:TemplateID() then
         self._inviteEnterList = {}
         self._inviteOutList = {}
      else 
         self._inviteOutList[1] = pet
         self._inviteEnterList = {}
      end 
   end 
   self:HaveChange()
   GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetInvitePreview)
end 

-- 预演
function HomelandPetInviteManager:InviteEnterListPreview(pet,isAdd)
   if self:GetContainerCount() == 1  then 
      self:ExchangeInvitetingItem(pet,isAdd)
      self:HaveChange()
      GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetInvitePreview)
      return 
   end 
   -- full
   local data =  self:GetInvitedGroup()
   self._lastGroupData = data
   if isAdd and self:GetContainerCount() > 1 and #data >= self:GetContainerCount() then 
      ToastManager.ShowHomeToast(StringTable.Get("str_homeland_invite_item_full"))
      return 
   end 
   if isAdd then 
      self:_AddFun(self._inviteEnterList,pet)
      self:_RemoveFun(self._inviteOutList,pet)
   else 
      if self:CheckInList(self._inviteEnterList,pet) then
         self:_RemoveFun(self._inviteEnterList,pet) 
      end 
      self:_AddFun(self._inviteOutList,pet)
   end  
   self:HaveChange()
   GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetInvitePreview)
   Log.info("InviteEnterListPreview")
end 
-- 邀請成功清理
function HomelandPetInviteManager:ClearCache()
   self._inviteEnterList = {}
   self._inviteOutList = {}
end 

function HomelandPetInviteManager:GetInvitedGroup()
   local buildid = self._building:InsID()
   local endList =  {}
   local interactings = self:GetInteractingList(buildid,self._inviteItemId)
   for i = 1, #interactings do
      local pet = interactings[i]
      --self:_AddFun(endList,pet)
      local interactionAnimation = pet:GetPetBehavior():GetCurBehavior():GetComponent(HomelandPetComponentType.InteractionAnimation)
      if interactionAnimation and interactionAnimation.state == HomelandPetComponentState.Running then 
         self:_AddFun(endList,pet)
      end 
      
      if self:CheckIsSwimming(pet) then 
         local  swimmingpool = pet:GetPetBehavior():GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
         if swimmingpool._stage == HomelandPetSwimStage.Swimming then 
            self:_AddFun(endList,pet)
         end 
      end 
   end
   for i = 1, #self._inviteEnterList do
      local pet = self._inviteEnterList[i]
      self:_AddFun(endList,pet)
   end
   for i = 1, #self._inviteOutList do
      local pet = self._inviteOutList[i]
      self:_RemoveFun(endList,pet)
   end
   table.sort( endList,self._SortFun2)
   if self:GetContainerCount() == 1 and  #endList > 0 then 
      return {endList[#endList]}
   end 
   return  endList
end



function HomelandPetInviteManager:GetInteractingList(buildid,inviteItemId)
   if not self._interactingList[buildid] then 
      self._interactingList[buildid] = {}
   end 
   if not self._interactingList[buildid][inviteItemId] then 
      self._interactingList[buildid][inviteItemId] = {}
   end 
   return self._interactingList[buildid][inviteItemId]
end 

function HomelandPetInviteManager:CheckInInteractingList(checkpet,buildid,inviteItemId)
   if not self._interactingList[buildid][inviteItemId] then 
      return false 
   end 
   local tb = self._interactingList[buildid][inviteItemId]
   for i = 1, #tb do
      if tb[i]:TemplateID() == checkpet:TemplateID() then
         return true 
      end 
   end
   if not buildid then 
     for i, v in pairs(self._interactingList) do
         for k, l in pairs(v) do
            if v:TemplateID() == checkpet:TemplateID() then
               return true 
            end 
         end
     end
   end 
   return false 
end 

function HomelandPetInviteManager:ClearInteractingList(checkpet ,buildid,inviteItemId)
   for lastbuildid, v in pairs(self._interactingList) do
      for lastitemid, itemIds in pairs(v) do
         for index, pet in pairs(itemIds) do
            if pet:TemplateID() == checkpet:TemplateID() and (buildid ~= lastbuildid or inviteItemId ~= lastitemid) then
               table.remove(itemIds,lastitemid) 
            end 
         end
      end
   end
end 

function HomelandPetInviteManager:CheckIsLastInteract(checkpet )
   local buildid = self._building:InsID()
   for lastbuildid, v in pairs(self._interactingList) do
      for lastitemid, itemIds in pairs(v) do
         for index, pet in pairs(itemIds) do
            if pet:TemplateID() == checkpet:TemplateID() then
               return (lastbuildid == buildid and lastitemid == self._inviteItemId)
            end 
         end
      end
   end
   return  false
end 

function HomelandPetInviteManager:RefreshInteractingList(enter,pet,build,beSet,inviteItemId)
   if not build then
      return 
   end 
   if not inviteItemId then
      inviteItemId = 1 
   end 
   local buildid = build:InsID()
   if enter then 
      if beSet then 
         self:EnterCD(pet)
      end 
  
      self:_AddFun(self:GetInteractingList(buildid,inviteItemId),pet)
   else 
      self:RemoveCD(pet)
      pet:SetInvited(false)
      self:_RemoveFun(self:GetInteractingList(buildid,inviteItemId),pet)
   end 
   GameGlobal.EventDispatcher():Dispatch(GameEventType.OnPetInvitePreview,pet,enter)
end 

function HomelandPetInviteManager:OnHomePetInteractCloseForInivte(pet)

end 


-- 附近可交互的光灵 同状态按星级降序排序，同星级按id升序排序
function HomelandPetInviteManager:GetNearInviteEnablePetList()
   if not  self._building then 
      return 
   end 

   local buildid = self._building:InsID()
   local interactingList =  self:GetInteractingList(buildid,self._inviteItemId)

   local filterFunc = function (pet)
      if interactingList then
         for _, _pet in pairs(interactingList) do
            if _pet == pet then
               return false
            end
         end
      end
      return true
   end

   local allPet =  self._homelandPetManager:GetAllPets()
   self._nearInviteEnablePet = {}

   for key, pet in pairs(allPet) do
      if self:_AviliablePetsFilter( self._building, pet) and filterFunc(pet) then 
         table.insert(self._nearInviteEnablePet,pet)
      end 
   end  
   for i = #self._nearInviteEnablePet,1,-1 do
      local pet = self._nearInviteEnablePet[i]
      local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[self._building:GetBuildId()]
      if cfgSwimmingPool then 
         if  self:CheckIsSwimming(pet) then 
            local  swimmingpool = pet:GetPetBehavior():GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
            if swimmingpool._stage == HomelandPetSwimStage.Swimming then 
               self:_RemoveFun(self._nearInviteEnablePet,pet)
            end 
         end 
      else 
         if pet:GetInteractingBuilding() ~= nil and pet:GetInteractingBuilding():InsID() == self._building:InsID() then 
            local interactionAnimation = pet:GetPetBehavior():GetCurBehavior():GetComponent(HomelandPetComponentType.InteractionAnimation)
            if interactionAnimation and interactionAnimation.state == HomelandPetComponentState.Running then 
               self:_RemoveFun(self._nearInviteEnablePet,pet)
            end 
         end 
      end 
   end 

   for k = 1, #self._inviteEnterList do
      for i = #self._nearInviteEnablePet,1,-1 do
         local pet = self._inviteEnterList[i]
         self:_RemoveFun(self._nearInviteEnablePet,pet)
      end 
   end

   if self._inviteOutList then 
      for i = 1, #self._inviteOutList do
         local pet = self._inviteOutList[i]
         self:_AddFun( self._nearInviteEnablePet,pet)
      end
   end 

   local nearList = {}
   local other = {}
   for i = 1, #self._nearInviteEnablePet do
      if self:CheckIsNear(self._nearInviteEnablePet[i],self._building) and (not self:CheckIsBusy(self._nearInviteEnablePet[i],self._building)) then
         table.insert(nearList,self._nearInviteEnablePet[i])
      else
         table.insert(other,self._nearInviteEnablePet[i])
      end 
   end
    
   table.sort( nearList,self._SortFun2)
   table.sort( other,self._SortFun2)
   for i = 1, #other do
      table.insert( nearList,other[i])
   end
   self._nearInviteEnablePet = nearList
   return self._nearInviteEnablePet
end

function HomelandPetInviteManager:_CheckIsNpc(pet) 
   if not self._homelandTaskManager then 
      return false
   end
   return  self._homelandTaskManager:IsPetOccupiedAsNpc(pet:TemplateID())
end 

   -- 拥有角色、满足皮肤条件、已解锁交互动作
function HomelandPetInviteManager:_AviliablePetsFilter(building, pet)
    -- 距离
    -- if Vector3.Distance(pet:GetPosition(), building:Pos()) > self._checkDistance  then
    --    return false
    -- end
    --  任务Npc
    if self:_CheckIsNpc(pet) then
        return false
    end

    local unRestraint = false
    --这个建筑是泳池
    local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[building:GetBuildId()]
    if cfgSwimmingPool then
        ---@type HomelandPetBehavior
        local behavior = pet:GetPetBehavior()
        ---@type HomelandPetBehaviorSwimmingPool
        local behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
		if behaviorSwimmingPool then
			unRestraint = behaviorSwimmingPool:BuildingFilter(building,true)
		end
    else
        --建筑交互表现
        local cfgArchitecture = Cfg.cfg_item_architecture[building:GetBuildId()]
        if not cfgArchitecture or not cfgArchitecture.Interaction then
            return false
        end
        -- cfg_homeland_building_pet 条件限制配置 petID
        for _, value in pairs(cfgArchitecture.Interaction) do
            local cfgBuildingPet = Cfg.cfg_homeland_building_pet[value]
            if cfgBuildingPet then
               if cfgBuildingPet.BlackList then
                  if table.icontains(cfgBuildingPet.BlackList, pet:TemplateID()) or
                  table.icontains(cfgBuildingPet.BlackList, pet:SkinID()) then
                     unRestraint = false
                     return unRestraint
                  end
               end 
                if not cfgBuildingPet.petIDs then
                    -- 全部星灵可交互
                    unRestraint = true
                    break
                end
                local finishEventList = self._homelandModule:GetHomeLandEventInfo().finish_event_list
                local lockEvent = false
                if self:_IsUnLock(pet:TemplateID(), value, finishEventList) then
                    lockEvent = true
                end
                -- 需要检测 皮肤状态
                if
                    (table.icontains(cfgBuildingPet.petIDs, pet:TemplateID()) or
                        table.icontains(cfgBuildingPet.petIDs, pet:SkinID())) and
                        lockEvent
                 then
                    unRestraint = true
                    break
                end
            end
        end
    end

    return unRestraint
end

--	可互动角色列表
function HomelandPetInviteManager:GetInteractEnablePetList(building)
   if not building then 
      return 
   end 
   local data = {}
   local cfgArchitecture = Cfg.cfg_item_architecture[building:GetBuildId()]
   -- 没有设置交互
   local isSwimmingPool = false
   local cancheck = false 
   local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[building:GetBuildId()]
   if cfgSwimmingPool then
      cancheck = true 
      isSwimmingPool = true 
   end

   if not cancheck then
      if not cfgArchitecture or not cfgArchitecture.Interaction then
         return nil
      end
   end 
   
   
   ---@type UIHomePetInviteItemEnableInfo
   local checkInDataFun = function (data,petId)
      for key, value in pairs(data) do
         if value:GetPetId() == petId then 
            return value
         end 
      end
      return nil
   end
   if isSwimmingPool then
      local cfg = Cfg.cfg_homeland_swimming_pool[building:GetBuildId()]
      for index, value in ipairs(cfg.PetSkinIDs) do
         -- 检测光零配置
         local dataitem = nil 
         local skincfg = self:GetSkinByPrefabId(value)
         if skincfg then 
            local endValue =  checkInDataFun(data,skincfg[1].PetId)
            if not endValue then 
               dataitem = UIHomePetInviteItemEnableInfo:New(0,skincfg[1].PetId)
               dataitem:AddSkin(skincfg[1])
               table.insert(data,dataitem)
            else 
               dataitem = endValue
               dataitem:AddSkin(skincfg[1])
            end 
            dataitem:SetOriginalSkin("head1_"..skincfg[1].PetId)
            local pet = self._homelandPetManager:GetPet(skincfg[1].PetId)
            if pet then
               dataitem:SetUsingSkin("head1_"..pet:SkinID())
            end 
         end 
      end
   else 
      for _, value in pairs(cfgArchitecture.Interaction) do
         local cfgBuildingPet = Cfg.cfg_homeland_building_pet[value]
         if cfgBuildingPet then
               if not cfgBuildingPet.petIDs then
               -- 全部星灵可交互
                  return  nil
               end
             
               -- 需要检测 皮肤状态
               for index, value in ipairs(cfgBuildingPet.petIDs) do
                  -- 检测光零配置
                  local dataitem = nil 
                  local skincfg = self:GetSkinByPrefabId(value)
                  if skincfg then 
                     local endValue =  checkInDataFun(data,skincfg[1].PetId)
                     if not endValue then 
                        dataitem = UIHomePetInviteItemEnableInfo:New(cfgBuildingPet.ID,skincfg[1].PetId)
                        dataitem:AddSkin(skincfg[1])
                        table.insert(data,dataitem)
                     else 
                        dataitem = endValue
                        dataitem:AddSkin(skincfg[1])
                     end 
                     dataitem:SetOriginalSkin("head1_"..skincfg[1].PetId)
                     local pet = self._homelandPetManager:GetPet(skincfg[1].PetId)
                     if pet then
                        dataitem:SetUsingSkin("head1_"..pet:SkinID())
                     end 
                  end 
               end
               Log.fatal("GetInteractEnablePetList")
         end
      end
   end 
   
   
   return data
end 

function HomelandPetInviteManager:CheckInPetCfg(petId) 
   local cfg = Cfg.cfg_pet[petId]
   return cfg
end 
function HomelandPetInviteManager:GetSkinByPrefabId(petID)
   local cfg =  Cfg.cfg_pet_skin { Prefab = petID..".prefab"}
   return cfg
end


function HomelandPetInviteManager:_GetInteractionCfg(petid ,interactions)
    local cfg = nil
    local finishEventList =  self._homelandModule:GetHomeLandEventInfo().finish_event_list
    for _, id in pairs(interactions) do
        if self:_IsUnLock(petid, id, finishEventList) then
            local cfgBuildingPet = Cfg.cfg_homeland_building_pet[id]
            if cfgBuildingPet then
                if not cfgBuildingPet.petIDs or 
                table.icontains(cfgBuildingPet.petIDs, self._pet:TemplateID()) or 
                table.icontains(cfgBuildingPet.petIDs, self._pet:SkinID()) then
                    cfg = cfgBuildingPet
                    break
                end
            end
        end
    end
    return cfg
end

-- 事件解锁
function HomelandPetInviteManager:_IsUnLock(petID, interactionid, finishEventList)
   local cfgs = Cfg.cfg_homeland_event{PetID = petID}
   if not cfgs then
       return true 
   end
   for _, cfg in pairs(cfgs) do
       if cfg.RewardsInteractID and table.icontains(cfg.RewardsInteractID, interactionid) then
           for eventID, eventTime in pairs(finishEventList) do
               if eventID == cfg.ID then
                   return true
               end
           end
           return false
       end
   end
   return true
end

---@type HomelandPet
function HomelandPetInviteManager:CheckHadPet(petID)
   return  self._petModule:HasPet(petID)
end

function HomelandPetInviteManager:CheckEventFinish(interactId,petID)
   local cfgs = Cfg.cfg_homeland_event{PetID = petID}
   if not cfgs then
       return true
   end
   local homelandModule = GameGlobal.GetModule(HomelandModule)
   local finishEventList = homelandModule:GetHomeLandEventInfo().finish_event_list
   for _, cfg in pairs(cfgs) do
       if cfg.RewardsInteractID and table.icontains(cfg.RewardsInteractID, interactId) then
           for eventID, eventTime in pairs(finishEventList) do
               if eventID == cfg.ID then
                   return true
               end
           end
           return false
       end
   end
   return true
end

function HomelandPetInviteManager:CheckHadSkin(skinId)
   return  self._petModule:HaveSkin(skinId)
end

function HomelandPetInviteManager:CheckHaveEventPet(petID)
   return  self._petModule:HasPet(petID)
end

function HomelandPetInviteManager:CheckIsNear(pet,building)
   local isNear = false 
   if not building then 
      building = self._building
   end 
   -- 距离
   if Vector3.Distance(pet:GetPosition(), building:Pos()) <= self._checkDistance  then
      isNear =  true
   end
   return isNear
end 

---光灵是否能和指定交互点交互
---@param pet HomelandPet
---@return boolean 
function HomelandPetInviteManager:CheckCurInteractPoint(pet)
   if not self._interactPointLimit then
      return true
   end
   local id = pet:TemplateID()
   local skinId = pet:SkinID()
   for _, value in pairs(self._interactPointPets) do
      if value == id or value == skinId then
         return true
      end
   end
   return false
end

function HomelandPetInviteManager:SetInvite()
   self:TrueInvitePets()
   self._dataChanged = false 
end

   -- 	仅对忙碌中的光灵发出邀请
   -- 	有成功的邀请，但都是撤下操作
   -- 	有成功的邀请，不全是撤下操作
function HomelandPetInviteManager:CheckOnSend()
   local change, state =  self:HaveChange()
   local tipStr = "str_homeland_invite_sended"
   if state == PetInviteStateEnum.Success then
      tipStr =  "str_homeland_invite_sended"
   elseif  state == PetInviteStateEnum.AllOut then
      tipStr = "str_homeland_invite_remove"
   elseif  state == PetInviteStateEnum.AllInvite then 
      tipStr =  "str_homeland_invite_sended"
   end 
   -- local pets = self:GetInvitedGroup()
   -- if not pets then
   --    return tipStr
   -- end 
   -- local allBusy = true  
   -- for i = 1, #pets do
   --    if self:PetChangeInviteState(pets[i]) then 
   --       allBusy = false 
   --    end 
   -- end 
   -- if allBusy then
   --    tipStr = "str_homeland_invite_busy"
   -- end 
   return tipStr
end
-- 执行邀请
function HomelandPetInviteManager:TrueInvitePets()
    local buildid = self._building:InsID()
    ---@type HomelandPet[]
    local pets = self:GetInvitedGroup()
    if not pets then
        return
    end

   local buildholdpetlist = self._building:GetInteractingPetList()
   if self:GetContainerCount() == 1  then 
      if #buildholdpetlist > 0 then 
         for i = 1, #buildholdpetlist do
           -- buildholdpetlist[i]._behavior:RandomBehavior()
         end
      end 
   else
      local holdCount = #buildholdpetlist
      local cacheEnter = #self._inviteEnterList
      local add =  holdCount + cacheEnter - self:GetContainerCount()
      if holdCount + cacheEnter > self:GetContainerCount() then 
         for i = 1, add do
           -- buildholdpetlist[1]._behavior:RandomBehavior()
         end
      end 
   end  
   
    self._inviteEnterList = {}
    local cfgSwimmingPool = Cfg.cfg_homeland_swimming_pool[self._building:GetBuildId()]
    -- 撤下
    if self._inviteOutList and #self._inviteOutList > 0 then
      for i = 1, #self._inviteOutList do
            if self:CheckInInteractingList(self._inviteOutList[i], buildid, self._inviteItemId) then
               local pet = self._inviteOutList[i]
               if cfgSwimmingPool then
                  ---@type HomelandPetBehavior
                  local behavior = pet:GetPetBehavior()
                  ---@type HomelandPetBehaviorSwimmingPool
                  local behaviorSwimmingPool = behavior:GetHomelandPetBehavior(HomelandPetBehaviorType.SwimmingPool)
                  if behaviorSwimmingPool then
                    behaviorSwimmingPool:OnChangeSwimStage(HomelandPetSwimStage.Leaving)
                  end
               else
                  pet._behavior:RandomBehavior()
               end
            end
      end
   end
  self._inviteOutList =  {}
    for i = 1, #pets do
        if self:PetChangeInviteState(pets[i]) then
            local lastbuild = pets[i]:GetInteractingBuilding()
            if lastbuild == nil or  lastbuild:InsID() ~= self._building:InsID() then 
               if cfgSwimmingPool then
                  self:ClearInteractingList(pets[i])
                  pets[i]:ChangeBehavior(HomelandPetBehaviorType.SwimmingPool, self._building)
               else
                  self:ClearInteractingList(pets[i])
                  pets[i]:ChangeBehavior(HomelandPetBehaviorType.InteractingFurniture, self._building, true, self:GetInteractPointIndex(pets[i]))
               end
            end 
        end
    end
end

function HomelandPetInviteManager:PetChangeInviteState(pet)
      if not pet then
         return false
      end
      -- 是否是玩家交互
      local petstate = pet:GetPetBehavior():GetCurBehavior():GetBehaviorType()
      if
         petstate == HomelandPetBehaviorType.InteractingPlayer or petstate == HomelandPetBehaviorType.TreasureIdle or
               petstate == HomelandPetBehaviorType.StoryPlaying or
               petstate == HomelandPetBehaviorType.StoryWaitdingBuild or
               petstate == HomelandPetBehaviorType.StoryWaitingBuildStand or
               petstate == HomelandPetBehaviorType.StoryWaitingStand or
               petstate == HomelandPetBehaviorType.StoryWaitingWalk
         then
         return false
      end
      if petstate == HomelandPetBehaviorType.Following then
         self._homelandPetManager:OnHomeInteractFollow(false, pet)
      end
      if petstate == HomelandPetBehaviorType.FurnitureInvite then
         -- 新家具 位置判断
         local isLast = self:CheckIsLastInteract(pet)
         if isLast then
               return false
         end
      end
      return true
end

function HomelandPetInviteManager:CheckIsBusy(pet)
   if not pet then
        return
   end
    -- 是否是玩家交互
   local petstate = pet:GetPetBehavior():GetCurBehavior():GetBehaviorType()
   if  petstate == HomelandPetBehaviorType.InteractingPlayer or petstate == HomelandPetBehaviorType.TreasureIdle or
         petstate == HomelandPetBehaviorType.StoryPlaying or
         petstate == HomelandPetBehaviorType.StoryWaitingBuild or
         petstate == HomelandPetBehaviorType.StoryWaitingBuildStand or
         petstate == HomelandPetBehaviorType.StoryWaitingStand or
         petstate == HomelandPetBehaviorType.StoryWaitingWalk
   then
         return true
   end
   return false
end

function HomelandPetInviteManager:StartTimer()
   self._timerEvent =
   GameGlobal.Timer():AddEventTimes(
   1000,
   TimerTriggerCount.Infinite,
   function()
       self:TimerFun()
   end
)
end

function HomelandPetInviteManager:CancelTimer()
   if self._timerEvent then
      GameGlobal.Timer():CancelEvent(self._timerEvent)
      self._timerEvent = nil
   end
end 

function HomelandPetInviteManager:TimerFun()
   local nowTime = self._timeModule:GetServerTime() / 1000
   for key, value in pairs(self._cdQueue) do
      if value and nowTime >= value then
         self._cdQueue[key] = nil 
      end 
   end
end
function HomelandPetInviteManager:EnterCD(pet)
   if not self._cdQueue then
      self._cdQueue  = {}
   end 
   local nowTime = self._timeModule:GetServerTime() / 1000
   if not self._cdQueue[pet:TemplateID()] then
      self._cdQueue[pet:TemplateID()] = nowTime + self:GetLimitCD()
   end 
end 
function HomelandPetInviteManager:RemoveCD(pet)
   if not self._cdQueue then
     return 
   end 
   for key, value in pairs(self._cdQueue) do
      if pet:TemplateID() == key then 
         self._cdQueue[key] = nil 
         break
      end 
   end
end 

function HomelandPetInviteManager:CheckInInviteingCDTime(pet)
   local petId = pet:TemplateID()
   if  self._cdQueue[petId] then 
      return true 
   end 
   return false 
end

function HomelandPetInviteManager:CheckIsMax()
   local buildid = self._building:InsID()
   local pets = self:GetInteractingList(buildid,self._inviteItemId)
   if self:GetContainerCount() == 1 then
      return false 
   else 
      if #pets >=  self:GetContainerCount() then
         return true 
      end 
   end 
   return false 
end

function HomelandPetInviteManager:CheckIsBuildingBusy()
   local busyCount = 0
   local buildid = self._building:InsID()
   local pets = self:GetInteractingList(buildid,self._inviteItemId)
   for i = 1, #pets do
      if self:CheckIsGroupBusy(pets[i]) then
         busyCount = busyCount + 1 
      end 
   end
   return  busyCount >= self:GetContainerCount()
end

function HomelandPetInviteManager:CheckIsGroupBusy(pet)
   local buildid = self._building:InsID()
   local pets =  self:GetInteractingList(buildid,self._inviteItemId)
   local interactionAnimation = pet:GetPetBehavior():GetCurBehavior():GetComponent(HomelandPetComponentType.InteractionAnimation)
   for key, value in pairs(pets) do
      if pet:TemplateID() == value:TemplateID() and  (interactionAnimation and interactionAnimation.state == HomelandPetComponentState.Running) then 
         return true 
      end 
      if self:CheckIsSwimming(pet) then 
         return true 
      end 
   end
   return false  
end


function HomelandPetInviteManager.CanBuildingInteracting(build,inviteItemId)
   if  self:GetContainerCount() == 1 then
      local buildid = build:InsID()
      local pets  =self:GetInteractingList(buildid,inviteItemId)
      if #pets >=1 then 
         return false  
      end  
   end 
   return true  
end


function HomelandPetInviteManager:SetUIHomelandPetInteract(pet )
   self._lastOperatePet = pet
   self._lastBuilding = pet:GetInteractingBuilding()
end

function HomelandPetInviteManager:CheckUIHomelandPetInteract(pet)
   if not (self._lastOperatePet and  pet)  then 
      return false 
   end 
   if self._lastOperatePet:TemplateID() == pet:TemplateID() then 
      self._lastOperatePet = nil 
      return true 
   end 
   self._lastOperatePet = nil 
   return false
end

function HomelandPetInviteManager:GetUIHomelandPetInteract()
   return self._lastBuilding,self._lastOperatePet
end

function HomelandPetInviteManager:SetInteractPointLimit(isLimit, pets)
   self._interactPointLimit = isLimit
   self._interactPointPets = pets
end

---更新指定交互点的光灵
---@param index number 
---@param pet HomelandPet
function HomelandPetInviteManager:UpdateInvitedPets(index, pet)
   if pet then
      self._invitedPets[pet] = index
   else
      for _pet, _index in pairs(self._invitedPets) do
         if _index == index then
            self._invitedPets[_pet] = nil
            break
         end
      end
   end
end

---@param pet HomelandPet
function HomelandPetInviteManager:GetInteractPointIndex(pet)
   for _pet, _index in pairs(self._invitedPets) do
      if pet == _pet then
         return _index
      end
   end
   return 1
end