using System;
using DG.Tweening;
using Ez.Core;
using UnityEngine;
using Random = UnityEngine.Random;

namespace Game
{
    public class MultiSegmentFlyComponent : MonoBehaviour
    {
        private Vector3 startpos;
        private Vector3 endpos;
        private Vector3 vec1;
        private Vector3 vec2;

        //第一段位移
        public void FlyToOne(float flyTime, float toScale, Vector2 rangeX, Vector2 rangeY)
        {
            startpos = transform.position;
            float randomX, randomY;
            randomX = Random.Range(rangeX.x, rangeX.y);
            randomY = Random.Range(rangeY.x, rangeY.y);
            vec1 = startpos + new Vector3(randomX, randomY, 0);
            this.gameObject.ExSetActive(true);
            this.gameObject.transform.DOScale(toScale * Vector3.one, flyTime).SetTarget(this);
            this.gameObject.transform.DOMove(vec1, flyTime).SetTarget(this);
        }
    
        //第二段位移
        public void FlyToTwo(Vector3 targetPos, float flyTime, Vector2 toScale, string prefabName, Action reachTargetCallback)
        {
            endpos = targetPos;
            vec2 = endpos;
            this.gameObject.transform.localScale = toScale.x * Vector3.one;
            this.gameObject.transform.DOScale(toScale.y * Vector3.one, flyTime).SetTarget(this);
            this.gameObject.transform.DOMove(vec2, flyTime).SetTarget(this).OnStepComplete(() =>
            {
                if (string.IsNullOrEmpty(prefabName))
                {
                    Destroy(this.gameObject);
                }
                else
                {
                    GameObjectPoolEx.Instance.Recycle(prefabName, this.gameObject);
                }
                reachTargetCallback?.Invoke();
            });
        }
        
    }
}
