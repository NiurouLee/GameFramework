using System.Collections.Generic;
using UnityEngine;

namespace Ez.UI
{
    [RequireComponent(typeof(UnityEngine.UI.Image))]
    public class SpriteSwitcher : MonoBehaviour
    {
        [SerializeField]
        List<SpriteKeyValue> m_Sprites;

        private UnityEngine.UI.Image m_Image;
        // Start is called before the first frame update
        void Start()
        {

        }

        public void SwichToIndex(int index)
        {
            if (!IsValid())
                return;

            if (index >= 0 && index < m_Sprites.Count)
            {
                Image.sprite = m_Sprites[index].sprite;
            }
            else
            {
                Game.DevDebuger.LogWarning("SpriteSwitcher", $"invalid index: {index}");
            }
        }

        public void ToKey(string key)
        {
            if (!IsValid())
                return;

            foreach (SpriteKeyValue kv in m_Sprites)
            {
                if (kv.key == key)
                {
                    Image.sprite = kv.sprite;
                    break;
                }
            }
        }

        public UnityEngine.UI.Image Image
        {
            get
            {
                if (m_Image == null)
                {
                    m_Image = GetComponent<UnityEngine.UI.Image>();
                }
                return m_Image;
            }
        }

        public bool IsValid()
        {
            return m_Image != null && m_Sprites != null;
        }
    }

    [System.Serializable]
    public class SpriteKeyValue
    {
        public string key;
        public Sprite sprite;
    }
}
