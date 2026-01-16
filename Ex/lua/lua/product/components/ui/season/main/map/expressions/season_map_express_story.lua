---@class SeasonMapExpressStory:SeasonMapExpressBase
_class("SeasonMapExpressStory", SeasonMapExpressBase)
SeasonMapExpressStory = SeasonMapExpressStory

function SeasonMapExpressStory:Constructor(cfg, eventPoint)
    self._content = self._cfg.StoryID
end

function SeasonMapExpressStory:Update(deltaTime)
end

function SeasonMapExpressStory:Dispose()
end

--播放表现内容
function SeasonMapExpressStory:Play(param)
    SeasonMapExpressStory.super.Play(self, param)
    if self._content then
        local storyID = self._content
        self._state = SeasonExpressState.Playing
        UISeasonHelper.PlayStoryInSeasonScence(
            storyID,
            function()
                self._state = SeasonExpressState.Over
                self:_Next()
            end
        )
    end
end