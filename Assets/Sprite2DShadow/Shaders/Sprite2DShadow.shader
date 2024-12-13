Shader "Hidden/CatDarkGame/Sprite2DShadow"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Cutoff ("Shadow Cutoff", Range(0,1)) = 0.5
        
        _HeightOffset("Height Offset", Float) = 0.0

        // Legacy properties. They're here so that materials using this shader can gracefully fallback to the legacy sprite shader.
        [HideInInspector] _Color ("Tint", Color) = (1,1,1,1)
        [HideInInspector] PixelSnap ("Pixel snap", Float) = 0 
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _AlphaTex ("External Alpha", 2D) = "white" {}
        [HideInInspector] _EnableExternalAlpha ("Enable External Alpha", Float) = 0
    }
     
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

        Pass
        {
            Tags { "LightMode" = "Universal2D" }

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #if defined(DEBUG_DISPLAY)
            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/InputData2D.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/SurfaceData2D.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging2D.hlsl"
        #endif

            #pragma vertex UnlitVertex
            #pragma fragment UnlitFragment

            #pragma multi_compile _ DEBUG_DISPLAY SKINNED_SPRITE
            #pragma multi_compile _ SPRITE2DSHADOW_ON

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float4 color        : COLOR;
                float2 uv           : TEXCOORD0;
                UNITY_SKINNED_VERTEX_INPUTS
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4  positionCS  : SV_POSITION;
                float2  uv          : TEXCOORD0;
            #if defined(DEBUG_DISPLAY)
                float3  positionWS  : TEXCOORD2;
            #endif
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            UNITY_TEXTURE_STREAMING_DEBUG_VARS_FOR_TEX(_MainTex);

            float4 _SpriteShadowLightDirection;
            half4 _ShadowColor;
            
            CBUFFER_START(UnityPerMaterial)
                float _HeightOffset;
            CBUFFER_END

            // Ref - https://github.com/ozlael/PlannarShadowForUnity/blob/master/ProjectPlanarShadow/Assets/ShaderAndMtrl/PlanarShadowBase.cginc
            float4 GetPlaneShadowPositionHClip(float4 positionWS, float3 lightDir, float heightOffset)
            {
                float3 lightDirNormalized = SafeNormalize(lightDir);
                float height = heightOffset;
                
                float opposite = positionWS.y - height;
	            float cosTheta = -lightDir.y;	
	            float hypotenuse = opposite / cosTheta;
	            float3 vPos = positionWS.xyz + (lightDirNormalized * hypotenuse );

                return mul(UNITY_MATRIX_VP, float4(vPos.x, height, vPos.z, 1.0f));  
            }

            Varyings UnlitVertex(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_SKINNED_VERTEX_COMPUTE(v);

                float4 positionOS = float4(UnityFlipSprite(v.positionOS.xyz, unity_SpriteProps.xy), 1.0f);
                float4 positionWS = mul(unity_ObjectToWorld, positionOS);
                float4 positionCS = GetPlaneShadowPositionHClip(positionWS, _SpriteShadowLightDirection.xyz, _HeightOffset);
                
                o.positionCS = positionCS;

            #if !defined(SPRITE2DSHADOW_ON)
               o.positionCS = float4(0, 0, 0, sqrt(-1));    // 비활성화 상태에서 버텍스를 카메라 뒤로 이동. 
            #endif
            #if defined(DEBUG_DISPLAY)
                o.positionWS = TransformObjectToWorld(positionOS.xyz);
            #endif
                o.uv.xy = v.uv.xy;
                return o;
            }
            
            half4 UnlitFragment(Varyings i) : SV_Target
            {
            #if !defined(SPRITE2DSHADOW_ON)
                return 0.0f;
            #endif
                
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

            #if defined(DEBUG_DISPLAY)
                return 0.0h;
            #endif

                half4 finalColor = half4(_ShadowColor.rgb, mainTex.a * _ShadowColor.a);
                return finalColor;
            }
            ENDHLSL
        }

     

    }
}
