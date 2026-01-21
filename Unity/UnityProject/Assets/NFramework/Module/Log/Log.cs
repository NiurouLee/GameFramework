using System;
using NFramework.Core.Collections;

namespace NFramework.Module.LogModule
{
    public interface ILog
    {
    }

    public class Error
    {
        public void Print(string inMsg)
        {
            UnityEngine.Debug.LogError(inMsg);
        }
    }

    public class Warning
    {
        public void Print(string inMsg)
        {
            UnityEngine.Debug.LogWarning(inMsg);
        }
    }

    public class Log
    {
        public void Print(string inMsg)
        {
            UnityEngine.Debug.Log(inMsg);
        }
    }


    public class LoggerM : FrameworkModule
    {
        public Error? Error { get; private set; }
        public Warning? Warning { get; private set; }
        public Log? Log { get; private set; }

        public BitField16 LogLevel = new BitField16(0);

        public override void Awake()
        {
            base.Awake();
            Error = new Error();
            Warning = new Warning();
            Log = new Log();
        }

        public void ErrStack(string inMsg)
        {
            UnityEngine.Debug.LogError(Environment.StackTrace);
            Err(inMsg);
        }

        public void LogMsg(string inMsg)
        {
            UnityEngine.Debug.Log(inMsg);
        }

        public void WarnMsg(string inMsg)
        {
            UnityEngine.Debug.LogWarning(inMsg);
        }

        public void Err(string inMsg)
        {
            UnityEngine.Debug.LogError(inMsg);
        }


        public void ExceptionMsg(System.Exception inMsg)
        {
            UnityEngine.Debug.LogError(Environment.StackTrace);
            throw inMsg;
        }
    }
}