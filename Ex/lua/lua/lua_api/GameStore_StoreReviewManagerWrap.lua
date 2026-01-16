---@class GameStore.StoreReviewManager : object
local m = {}
---@param storeID string
function m:RequestSystemBasedReview(storeID) end
---@param storeID string
function m:RequestStoreBasedReview(storeID) end
GameStore = {}
GameStore.StoreReviewManager = m
return m