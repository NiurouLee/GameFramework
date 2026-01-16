---@class HomePetInteractCameraState
HomePetInteractCameraState = {
    None = 0,--空
    RotatePetAndMoveCamera = 1,--星灵转身，移动焦点
    RoatateCameraAndZ = 2,--转相机，调整Z
    PlayStory = 3,--播剧情
    RotatePetAndRevertInteractCamera = 4,--结束星灵转身
    EndInteract = 5,--交互镜头还原
    RevertStoryCamera = 6,--剧情镜头还原
    GetRewards = 7,--领奖
    OpenTouch = 8,--开启交互
    EndStory = 9,--结束
}
_enum("HomePetInteractCameraState", HomePetInteractCameraState)
--虚拟机位类型
---@class HomePetInteractState
HomePetInteractState = {
    None = 0,--空
    BeginInteract = 1,--开始交互
    EndInteract = 2,--结束交互
    BeginStory = 3,--开始剧情
    Storying = 4,--剧情中
    EndStory = 5,--结束交互
    Close = 6,--关闭
}
_enum("HomePetInteractState", HomePetInteractState)