---@class HomeStoryEntityType
HomeStoryEntityType = {
    Invalid = 0,
    Dialog = 1,
    Spine = 2,
    Picture = 3,
    Effect = 4,
    Sound = 5,
    SpineSlice = 6,
    Text = 7,
    PostProcessing = 8,
    Model = 9,--模型
    CameraVC = 10,--虚拟机位
}
_enum("HomeStoryEntityType", HomeStoryEntityType)
--虚拟机位类型
---@class CameraVCSubType
CameraVCSubType = {
    Normal = 0,--普通
    Cart = 1,--轨道
}
_enum("CameraVCSubType", CameraVCSubType)