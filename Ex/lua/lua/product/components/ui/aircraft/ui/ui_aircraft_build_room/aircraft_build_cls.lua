--region AircrafBuildData 风船建筑类
---@class AircrafBuildData:Object
_class("AircrafBuildData", Object)
AircrafBuildData = AircrafBuildData

function AircrafBuildData:Constructor()
    --建筑ID
    self._id = 0
    --房间类型
    self._roomType = 0
    --等级
    self._lv = 0
    --名字
    self._name = ""
    --图片
    self._icon = ""
    --描述
    self._des = nil
    --入住星灵数量上限
    self._petCount = 0
    --心情变化速度（每小时）
    self._moodSpeed = 0
    --上一级ID
    self._upLvID = 0
    --下一级ID
    self._downLvID = 0
    --需要建筑类型
    self._needBuildCondition = {}
    --建造升级消耗
    self._upLvCost = {}
    --降级拆除返还
    self._downLvReturn = {}
    --占用能量
    self._needPower = 0
    --升级时间(分钟)
    self._upLvTime = 0
    --已经建造数量
    self._nCount = 0
    --建造上限
    self._uCount = 0
end

function AircrafBuildData:Init(
    id,
    roomType,
    lv,
    name,
    icon,
    des,
    petCount,
    moodSpeed,
    upLvID,
    downLvID,
    needBuildCondition,
    upLvCost,
    downLvReturn,
    needPower,
    upLvTime,
    nCount,
    uCount)
    self._id = id
    self._roomType = roomType
    self._lv = lv
    self._name = name
    self._icon = icon
    self._des = des
    self._petCount = petCount
    self._moodSpeed = moodSpeed
    self._upLvID = upLvID
    self._downLvID = downLvID
    self._needBuildCondition = needBuildCondition
    self._upLvCost = upLvCost
    self._downLvReturn = downLvReturn
    self._needPower = needPower
    self._upLvTime = upLvTime
    self._nCount = nCount
    self._uCount = uCount
end
