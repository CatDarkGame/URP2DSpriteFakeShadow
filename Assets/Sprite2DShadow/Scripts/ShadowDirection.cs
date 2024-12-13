using UnityEngine;

namespace CatDarkGame.Sprite2DShadow
{
    [RequireComponent(typeof(Transform))]
    [ExecuteInEditMode]
    public class ShadowDirection : MonoBehaviour
    {
        private static class ShaderPropertyID
        {
            public static readonly int lightDirection = Shader.PropertyToID("_SpriteShadowLightDirection");
            public static readonly int shadowColor = Shader.PropertyToID("_ShadowColor");
            public static string enableKeyword = "SPRITE2DSHADOW_ON";
        }
        
        [SerializeField] private Color shadowColor = new Color(0.0f, 0.0f, 0.0f, 0.52f);
        private Transform _transformCache;
        
        private void OnEnable()
        {
            _transformCache = transform;
            Shader.EnableKeyword(ShaderPropertyID.enableKeyword);
        }

        private void OnDisable()
        {
            _transformCache = null;
            Shader.DisableKeyword(ShaderPropertyID.enableKeyword);
        }
        
        private void Update()
        {
            if (!enabled || !_transformCache) return;
            Vector3 lightDir = _transformCache.forward;
            Shader.SetGlobalVector(ShaderPropertyID.lightDirection, new Vector4(lightDir.x, lightDir.y, lightDir.z, 1.0f));
            Shader.SetGlobalColor(ShaderPropertyID.shadowColor, shadowColor);
        }

        public void SetShadowColor(Color color)
        {
            shadowColor = color;
        }

        public Color GetShadowColor()
        {
            return shadowColor;
        }
        
        public void SetShadowAlpha(float alpha)
        {
            alpha = Mathf.Clamp(alpha, 0.0f, 1.0f);
            shadowColor.a = alpha;
        }

        public float GetShadowAlpha()
        {
            return shadowColor.a;
        }
        
    #if UNITY_EDITOR
        private void OnDrawGizmos()
        {
            if (!enabled) return;
            Color arrowColor = Color.yellow;
            float cylinderRadius = 0.15f;   
            float cylinderLength = 0.62f;   
            Gizmos.color = arrowColor;
            
            Vector3 startPosition = transform.position;
            Vector3 cylinderEndPosition = startPosition + transform.forward * cylinderLength;
            DrawCylinder(startPosition, cylinderEndPosition, cylinderRadius);
        }

        private void DrawCylinder(Vector3 start, Vector3 end, float radius)
        {
            int segments = 16;
            Vector3 direction = (end - start).normalized;
            Quaternion rotation = Quaternion.LookRotation(direction);

            for (int i = 0; i < segments; i++)
            {
                float angle1 = (i * 360f / segments) * Mathf.Deg2Rad;
                float angle2 = ((i + 1) * 360f / segments) * Mathf.Deg2Rad;

                Vector3 point1 = start + rotation * new Vector3(Mathf.Cos(angle1) * radius, Mathf.Sin(angle1) * radius, 0);
                Vector3 point2 = start + rotation * new Vector3(Mathf.Cos(angle2) * radius, Mathf.Sin(angle2) * radius, 0);
                Vector3 point1End = point1 + direction * (end - start).magnitude;
            
                Gizmos.DrawLine(point1, point2);
                Gizmos.DrawLine(point1, point1End);
            }
        }
    #endif
    }

}

