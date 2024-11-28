Shader "Custom/TeleportationDissolve" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        _MetallicGlossMap("Metallic", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        [Gamma]_Metallic ("Metallic", Range(0,1)) = 0.0
        _OcclusionMap("Occlusion", 2D) = "white" {}
        _EmissionMap("Emission Map", 2D) = "white" {}
        [HDR]_EmissionColor("Emission Color", Color) = (1,1,1,1)
        _DissolveAmount("Dissolve amount", Range(-3,3)) = 0
        _Direction("Direction", vector) = (0, 1, 0, 0)
        [HDR]_DissolveColor("Dissolve Color", Color) = (1,1,1,1)
        _NoiseSize("Noise size", float ) = 1      
    }
    SubShader {
        Tags { "RenderType"="Opaque" "DisableBatching" = "True"}
        LOD 200
        Cull Off
 
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow 
 
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
 
        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _MetallicGlossMap;
        sampler2D _OcclusionMap;
        sampler2D _EmissionMap;
 
        struct Input {
            float2 uv_MainTex;
            float3 worldPosAdj;
        };
 
        fixed4 _Color;
        float _DissolveAmount;
        fixed4 _EmissionColor, _DissolveColor;
        float3 _Direction;
        float _NoiseSize;
        half _Glossiness, _Metallic;
 
        float random (float2 input) { 
            return frac(sin(dot(input, float2(12.9898,78.233)))* 43758.5453123);
        }
 
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.worldPosAdj =  mul (unity_ObjectToWorld, v.vertex.xyz);
            half test = ((dot(o.worldPosAdj, float3(0, -1, 0)) + 1) / 2) - _DissolveAmount;
            float squaresStep = step(test, random(floor(o.uv_MainTex * _NoiseSize) * _DissolveAmount));
            v.vertex.xyz += _Direction * squaresStep * random(v.vertex.xy) * abs(test);
        }
 
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
 
 
        void surf (Input IN, inout SurfaceOutputStandard o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            half4 MetallicSmooth = tex2D (_MetallicGlossMap, IN.uv_MainTex);
            //Clipping
            half test = ((dot(IN.worldPosAdj, float3(0, 1, 0)) + 1) / 2) - _DissolveAmount;
            float squares = random(floor(IN.uv_MainTex * _NoiseSize));
            float squaresStep = step(squares * _DissolveAmount, test);
            clip(squaresStep - 0.01);
            //Emission noise
            half emissionRing = step(squares, _DissolveAmount);
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
            o.Albedo = c.rgb;
            o.Emission = tex2D (_EmissionMap, IN.uv_MainTex) * _EmissionColor + _DissolveColor * emissionRing;
            o.Metallic = MetallicSmooth.r * _Metallic;
			o.Smoothness = MetallicSmooth.a * _Glossiness;
            o.Occlusion = tex2D (_OcclusionMap, IN.uv_MainTex).r;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}