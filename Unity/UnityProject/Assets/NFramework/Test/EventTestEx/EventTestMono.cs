using System;
using NFramework.Module.EventModule;
using UnityEngine;

namespace NFramework.Test.EventTestEx
{
    public class EventTestMono : MonoBehaviour
    {
        private void Start()
        {
            var register = new RegisterEx();
            // register.TestRegister();
            // register.TestRegisterChannel();
            // register.TestRegisterFilter();
            // var fire = new FireEx();
            // fire.FireNormal();
            // fire.FireChannel();
            // register.TestUnRegister();
            // register.TestUnRegisterChannel();
            // register.TestUnRegisterFilter();

            register.TestRegisterRecords();
            register.TestRegisterRecordsChannel();
            register.TestRegisterRecordsFilter();
            register.LogCount();

            // register.TestUnRegisterRecords();
            // register.LogCount();

            // register.TestUnRegisterRecordsChannel();
            register.TestUnRegisterAllRecords();
            register.LogCount();

            // register.TestUnRegisterRecordsFilter();
            register.LogCount();


        }
    }
}