---@class UnityEngine.SceneManagement.SceneManager : object
---@field sceneCount int
---@field sceneCountInBuildSettings int
local m = {}
---@return UnityEngine.SceneManagement.Scene
function m.GetActiveScene() end
---@param scene UnityEngine.SceneManagement.Scene
---@return bool
function m.SetActiveScene(scene) end
---@param scenePath string
---@return UnityEngine.SceneManagement.Scene
function m.GetSceneByPath(scenePath) end
---@param name string
---@return UnityEngine.SceneManagement.Scene
function m.GetSceneByName(name) end
---@param buildIndex int
---@return UnityEngine.SceneManagement.Scene
function m.GetSceneByBuildIndex(buildIndex) end
---@param index int
---@return UnityEngine.SceneManagement.Scene
function m.GetSceneAt(index) end
---@overload fun(sceneName:string):UnityEngine.SceneManagement.Scene
---@param sceneName string
---@param parameters UnityEngine.SceneManagement.CreateSceneParameters
---@return UnityEngine.SceneManagement.Scene
function m.CreateScene(sceneName, parameters) end
---@param sourceScene UnityEngine.SceneManagement.Scene
---@param destinationScene UnityEngine.SceneManagement.Scene
function m.MergeScenes(sourceScene, destinationScene) end
---@param go UnityEngine.GameObject
---@param scene UnityEngine.SceneManagement.Scene
function m.MoveGameObjectToScene(go, scene) end
---@overload fun(sceneName:string):void
---@overload fun(sceneName:string, parameters:UnityEngine.SceneManagement.LoadSceneParameters):UnityEngine.SceneManagement.Scene
---@overload fun(sceneBuildIndex:int, mode:UnityEngine.SceneManagement.LoadSceneMode):void
---@overload fun(sceneBuildIndex:int):void
---@overload fun(sceneBuildIndex:int, parameters:UnityEngine.SceneManagement.LoadSceneParameters):UnityEngine.SceneManagement.Scene
---@param sceneName string
---@param mode UnityEngine.SceneManagement.LoadSceneMode
function m.LoadScene(sceneName, mode) end
---@overload fun(sceneBuildIndex:int):UnityEngine.AsyncOperation
---@overload fun(sceneBuildIndex:int, parameters:UnityEngine.SceneManagement.LoadSceneParameters):UnityEngine.AsyncOperation
---@overload fun(sceneName:string, mode:UnityEngine.SceneManagement.LoadSceneMode):UnityEngine.AsyncOperation
---@overload fun(sceneName:string):UnityEngine.AsyncOperation
---@overload fun(sceneName:string, parameters:UnityEngine.SceneManagement.LoadSceneParameters):UnityEngine.AsyncOperation
---@param sceneBuildIndex int
---@param mode UnityEngine.SceneManagement.LoadSceneMode
---@return UnityEngine.AsyncOperation
function m.LoadSceneAsync(sceneBuildIndex, mode) end
---@overload fun(sceneName:string):UnityEngine.AsyncOperation
---@overload fun(scene:UnityEngine.SceneManagement.Scene):UnityEngine.AsyncOperation
---@overload fun(sceneBuildIndex:int, options:UnityEngine.SceneManagement.UnloadSceneOptions):UnityEngine.AsyncOperation
---@overload fun(sceneName:string, options:UnityEngine.SceneManagement.UnloadSceneOptions):UnityEngine.AsyncOperation
---@overload fun(scene:UnityEngine.SceneManagement.Scene, options:UnityEngine.SceneManagement.UnloadSceneOptions):UnityEngine.AsyncOperation
---@param sceneBuildIndex int
---@return UnityEngine.AsyncOperation
function m.UnloadSceneAsync(sceneBuildIndex) end
UnityEngine = {}
UnityEngine.SceneManagement = {}
UnityEngine.SceneManagement.SceneManager = m
return m