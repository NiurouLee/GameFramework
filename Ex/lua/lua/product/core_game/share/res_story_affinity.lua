_class("ResStoryAffinity", Object)
ResStoryAffinity = ResStoryAffinity

function ResStoryAffinity:Constructor()
    self:Init()
end

--cfg_story_affinity.lua表格资源
--优化引用
function ResStoryAffinity:Init()
    self._Res = {}
    self._ResOption = {}
    self._ResIds = {}

    local cfg = Cfg.cfg_story_affinity {}
    for k, v in pairs(cfg) do
        --4个字段得到唯一id
        if self._Res[v.StoryID] == nil then
            self._Res[v.StoryID] = {}
        end
        if self._Res[v.StoryID][v.ParagraphID] == nil then
            self._Res[v.StoryID][v.ParagraphID] = {}
        end
        if self._Res[v.StoryID][v.ParagraphID][v.SectionID] == nil then
            self._Res[v.StoryID][v.ParagraphID][v.SectionID] = {};
        end
        
        self._Res[v.StoryID][v.ParagraphID][v.SectionID][v.OptionID] = v


        --3个字段确定不同选项的id
        if self._ResOption[v.StoryID] == nil then
            self._ResOption[v.StoryID] = {}
        end
        if self._ResOption[v.StoryID][v.ParagraphID] == nil then
            self._ResOption[v.StoryID][v.ParagraphID] = {}
        end
        if self._ResOption[v.StoryID][v.ParagraphID][v.SectionID] == nil then
            self._ResOption[v.StoryID][v.ParagraphID][v.SectionID] = {};
        end

        self._ResOption[v.StoryID][v.ParagraphID][v.SectionID][v.ID] = v

        --story对应几行
        if self._ResIds[v.StoryID] == nil then
            self._ResIds[v.StoryID] = {}
        end

        self._ResIds[v.StoryID][v.ID] = v

    end
end

--获取 cfg_story_affinity 行级数据
---@return cfg_story_affinity某一行
function ResStoryAffinity:GetCfgID(StoryID, ParagraphID, SectionID, OptionID)
    
    if self._Res[StoryID] == nil then
        Log.error("ResStoryAffinity:GetCfg StoryID error ", StoryID)
        return nil
    end

    if self._Res[StoryID][ParagraphID] == nil then
        Log.error("ResStoryAffinity:GetCfg StoryID ParagraphID error ", StoryID, ParagraphID)
        return nil
    end

    if self._Res[StoryID][ParagraphID][SectionID] == nil then
        Log.error("ResStoryAffinity:GetCfg StoryID ParagraphID SectionID error ", StoryID, ParagraphID, SectionID)
        return nil
    end


    local cfg = self._Res[StoryID][ParagraphID][SectionID][OptionID]
    if cfg == nil then
        Log.error("ResStoryAffinity:GetCfg StoryID ParagraphID SectionID OptionID error ", StoryID, ParagraphID, SectionID)
        return nil
    end
    return cfg
end

--获取 story 有几行数据
function ResStoryAffinity:GetStoryIds(StoryID)
    return self._ResIds[StoryID]
end

--获取 story 3个相同字段，但不同选项的id
function ResStoryAffinity:GetStoryOptionIds(StoryID, ParagraphID, SectionID)
    if self._ResOption[StoryID] == nil then
        Log.error("ResStoryAffinity:GetStoryOptionIds StoryID error ", StoryID)
        return nil
    end

    if self._ResOption[StoryID][ParagraphID] == nil then
        Log.error("ResStoryAffinity:GetStoryOptionIds StoryID ParagraphID error ", StoryID, ParagraphID)
        return nil
    end

    if self._ResOption[StoryID][ParagraphID][SectionID] == nil then
        Log.error("ResStoryAffinity:GetStoryOptionIds StoryID ParagraphID SectionID error ", StoryID, ParagraphID, SectionID)
        return nil
    end

    return self._ResOption[StoryID][ParagraphID][SectionID]
end

---同上
function ResStoryAffinity:GetStoryOptionIdsById(cfgID)
    local cfg = Cfg.cfg_story_affinity[cfgID]
    if cfg == nil then
        Log.error("ResStoryAffinity:GetStoryOptionIdsById error ", cfgID)
        return nil
    end

    return self:GetStoryOptionIds(cfg.StoryID, cfg.ParagraphID, cfg.SectionID)
end