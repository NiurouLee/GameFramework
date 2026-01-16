using NFramework.Module.ConfigModule;
using NFramework.Module.EngineWrapper;
using NFramework.Module.EntityModule;
using NFramework.Module.EventModule;
using NFramework.Module.GameModule;
using NFramework.Module.IDGeneratorModule;
using NFramework.Module.LogModule;
using NFramework.Module.ObjectPoolModule;
using NFramework.Module.ResModule;
using NFramework.Module.TimeInfoModule;
using NFramework.Module.TimerModule;
using NFramework.Module.UIModule;
using UnityEngine;

namespace NFramework
{
    public class FWLauncher : MonoBehaviour
    {
        void Awake()
        {
            Framework.CreateInstance();
            Framework.Instance.Awake();
            Framework.Instance.AddModel<EngineWrapperM>();
            Framework.Instance.AddModel<LoggerM>();
            Framework.Instance.AddModel<ResM>();
            Framework.Instance.AddModel<EventM>();
            Framework.Instance.AddModel<ObjectPoolM>();
            Framework.Instance.AddModel<EntityPoolM>();
            Framework.Instance.AddModel<UIM>();
            Framework.Instance.AddModel<TimerM>();
            Framework.Instance.AddModel<TimeInfoM>();
            Framework.Instance.AddModel<EntitySystemM>();
            Framework.Instance.AddModel<IDGeneratorM>();
            Framework.Instance.AddModel<ConfigM>();
            Framework.Instance.AddModel<GameModuleM>();

            Framework.Instance.OpenAll();
            Framework.Instance.RegisterMainLoop();
        }
    }
}