using System;
using NFramework.Core.Collections;

namespace NFramework.Module.LogModule
{

    public interface ILog
    {
    }

    public class Error
    {

    }

    public class Warning
    {

    }

    public class Log
    {
        public void E(string inMsg)
        {
        }

    }


    public class LoggerM : IFrameWorkModule
    {
        public Error? Error { get; private set; }
        public Warning? Warning { get; private set; }
        public Log? Log { get; private set; }

        public BitField16 LogLevel = new BitField16(0);
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