using Ez.UI;
using UnityEngine;
using UnityEngine.UI;
namespace Ez.UI
{
    public class GrayGroup : MonoBehaviour
    {
        private MaskableGraphic[] _maskableGraphics;

        [SerializeField]
        private bool _isGray = false;

        public bool IsGray
        {
            set
            {
                if (_isGray != value)
                {
                    _isGray = value;
                    Refresh();
                }
            }
            get
            {
                return _isGray;
            }
        }

        void Start()
        {
            Refresh();
        }

        void Refresh()
        {
            bool value = _isGray;
            if (_maskableGraphics == null)
            {
                _maskableGraphics = GetComponentsInChildren<MaskableGraphic>();
            }
            foreach (var mg in _maskableGraphics)
            {
                if (mg != null)
                {
                    mg.material = value ? UIManager.GetInstance().DefaultGrayMaterial : null;
                }
            }
        }
    }
}