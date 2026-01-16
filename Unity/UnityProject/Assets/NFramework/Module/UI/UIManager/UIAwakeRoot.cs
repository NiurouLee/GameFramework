using System.Numerics;
using System;
using System.Collections.Generic;
using GameObject = UnityEngine.GameObject;
using Vector3 = UnityEngine.Vector3;
using UnityEngine;
using UnityEngine.EventSystems;
using Unity.VisualScripting;
using UnityEngine.UI;

namespace NFramework.Module.UIModule
{
    public partial class UIM
    {
        private GameObject uiRoot;
        public Camera UICamera { get; private set; }
        private Canvas uiCanvas;
        private Transform uiCanvasTrf;
        private EventSystem eventSystem;
        private CanvasScaler scaler;


        public override void Awake()
        {
            base.Awake();
        }

        public override void Open()
        {
            var _go = UnityEngine.Resources.Load<GameObject>("UIROOT");
            var _root = UnityEngine.Object.Instantiate(_go);
            this.AwakeRoot(_root);
            this.AwakeLayer(uiCanvas);
        }

        public void AwakeRoot(GameObject inRoot)
        {
            uiRoot = inRoot;
            uiRoot.transform.localPosition = new Vector3(0, 1000, 0);
            uiRoot.name = "[UIROOT]";
            UnityEngine.GameObject.DontDestroyOnLoad(uiRoot);
            UICamera = uiRoot.GetOrAddComponent<Camera>();
            uiCanvasTrf = uiRoot.transform.Find("Canvas");
            uiCanvas = uiCanvasTrf.GetComponent<Canvas>();
            eventSystem = uiRoot.GetComponentInChildren<EventSystem>();
            scaler = this.uiCanvas.GetOrAddComponent<CanvasScaler>();
        }

    }
}