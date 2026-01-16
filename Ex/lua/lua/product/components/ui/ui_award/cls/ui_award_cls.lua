--region Award define
---@class Award:Object
_class("Award", Object)
Award = Award

function Award:Constructor()
    self.id = 0
    self.name = ""
    self.icon = ""
    self.color = 1
    self.count = 0
    self.is3Star = false
    ---@type StageAwardType
    self.type = StageAwardType.Normal
    --
    self._cfg = Cfg.cfg_item
    self.randomType = nil
end
function Award:Init(id)
    self.id = id
    local cfg = self._cfg[id]
    if cfg then
        self.name = StringTable.Get(cfg.Name)
        self.icon = cfg.Icon
        self.color = cfg.Color
    end
end
function Award:InitWithCount(id, count, randomType)
    self:Init(id)
    self.count = count
    self.randomType = randomType
end

function Award:Flush3Star(is3Star)
    self.is3Star = is3Star
end

---@param type StageAwardType
function Award:FlushType(type)
    self.type = type
end

--- @class StageAwardType
local StageAwardType = {
    First = 1, --首通
    Star = 2, --三星
    Normal = 3, --普通
    Activity = 4, --活动
    HasGen = 5  --已经获得
}
_enum("StageAwardType", StageAwardType)
--endregion
