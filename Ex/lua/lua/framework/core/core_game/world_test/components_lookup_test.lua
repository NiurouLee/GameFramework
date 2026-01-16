--[[------------------------------------------------------------------------------------------
    WorldEntity组件
]]--------------------------------------------------------------------------------------------
---@class WEComponents_Test
_autoEnum("WEComponents_Test", {       
    -- Logic:
    --//////////////////////////////////////////////////////////     
    "CommandReceiver",    
    "CommandSender",      
    "Attributes",         
    "Location",                       
    "Movement",           
    "Spawn",              
    "MainFSM",            
    "Abilities",          
    -- Render:
    --//////////////////////////////////////////////////////////
    "Asset",              
    "View",                     
    --Count:     
    --////////////////////////////////////////////////////////// 
    "TotalComponents",    
})


--[[------------------------------------------------------------------------------------------
    WorldUnique组件
]]--------------------------------------------------------------------------------------------
---@class WUniqueComponentsEnum_Test
_autoEnum("WUniqueComponentsEnum_Test", {       
    --Logic    
    "SpawnMng",    
    --Count      
    "TotalComponents",    
})


--[[------------------------------------------------------------------------------------------
    WorldEntity 筛选器全定义在这，不可以在代码中直接使用 Matcher:New
]]--------------------------------------------------------------------------------------------

---@class BW_WEMatchers_Test
_enum("BW_WEMatchers_Test", {
    Asset = Matcher:New({WEComponents_Test.Asset}, {}, {}),
    Location = Matcher:New({WEComponents_Test.Location}, {}, {}),
    Spawn = Matcher:New({WEComponents_Test.Spawn}, {}, {}),
    View = Matcher:New({WEComponents_Test.View}, {}, {}),
    CanMove = Matcher:New({WEComponents_Test.Movement, WEComponents_Test.Location}, {}, {}),
    CommandReceiver = Matcher:New({WEComponents_Test.CommandReceiver}, {}, {}),
    CommandSender = Matcher:New({WEComponents_Test.CommandSender}, {}, {}),
    MainFSM = Matcher:New({WEComponents_Test.MainFSM}, {}, {}),
})
