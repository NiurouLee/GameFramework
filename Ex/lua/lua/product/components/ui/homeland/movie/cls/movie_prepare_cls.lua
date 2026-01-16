_class("MoviePrepareData", Singleton)
---@class MoviePrepareData : Singleton
MoviePrepareData = MoviePrepareData

function MoviePrepareData:Constructor()
    ---@type number
    self.movieId = 101 --电影Id
    ---@type MoviePrepareTarget
    self.prepareTarget = nil --准备目标
    self.pstId = 0  --pstID
    ---@type BuildBase 
    self._build = nil --建筑对象
    ---@type Architecture[]
    self.arch_list = nil --自由摆放建筑数据
    ---@type boolean
    self._isRoast = true  --回放是否开启吐槽
    ---@type MoviceRecord
    self._playbackData = nil   --回放信息

    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
end

function MoviePrepareData:Clear()
    self.movieId = 0
    self.prepareTarget = nil
    self._build = nil
end

function MoviePrepareData:EnsurePrepareArchList()
    self.arch_list = self.mUIHomeland:GetFreeChildren(self._build)
end

---@param prepareType MoviePrepareType 
function MoviePrepareData:ClearData(prepareType)
    if prepareType == MoviePrepareType.PT_Scene then
        self.mUIHomeland:ClearWallAndFloorInScene(self._build)
    elseif prepareType == MoviePrepareType.PT_Prop then
        --todo:
    elseif prepareType == MoviePrepareType.PT_Furniture then
        self.mUIHomeland:ClearFreeChildrenInScene(self._build)
    elseif prepareType == MoviePrepareType.PT_Actor then
        --todo:
    end
end

----------------set---------------------

function MoviePrepareData:SetMovieData(movieId, pstId,build)
    --self:Clear()
    self.movieId = movieId
    self.pstId = pstId
    self._build = build
end
 
function MoviePrepareData:SetReplayData(fatherBuilding,isRoast,arch_list,playbackData)
    --self:Clear()
    self._build = fatherBuilding
    self._isRoast = isRoast
    self._playbackData = playbackData
    self.arch_list = arch_list
    self.movieId = playbackData.movice_id
    self.pstId = playbackData.pstid
end

function MoviePrepareData:SetOpenTease(isRoast)
    self._isRoast = isRoast
end

----------------get---------------------

---@returnHomeBuildingFather
function MoviePrepareData:GetFatherBuild()
    return self._build
end

function MoviePrepareData:GetPstId()
    return self.pstId
end

function MoviePrepareData:GetMovieId()
    return self.movieId
end

function MoviePrepareData:GetPlayBackData()
    return self._playbackData
end

--返回自由摆放建筑列表
---@type  Architecture[]
function MoviePrepareData:GetPrepareArchList()
    return self.arch_list
end

function MoviePrepareData:GetOpenTease()
    return self._isRoast
end