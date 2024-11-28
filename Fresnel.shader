Shader "Custom/Fresnel_PBR"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        _MetallicGlossMap("Metallic", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        [HDR] _Emission ("Emission", color) = (0,0,0)
        [Header(Fresnel)]
	    //[Toggle(USE_FRESNEL)] _UseFresnel ("Use Fresnel", float) = 0
		[HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        //_FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
		[PowerSlider(4)] _FresnelExponent ("Fresnel Exponent", Range(0, 10)) = 1
        _Speed("Fresnel Speed", float) = 1
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200
        Cull Off

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alphatest:_Cutoff

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #pragma shader_feature USE_FRESNEL

        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _MetallicGlossMap;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
			float3 viewDir;
			INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        half3 _Emission;
        fixed4 _Color;

        float3 _FresnelColor;
		float _FresnelExponent;
        float _Speed;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            float4 metalSmooth = tex2D(_MetallicGlossMap, IN.uv_MainTex);
            o.Metallic = metalSmooth.r * _Metallic;
            o.Smoothness = metalSmooth.b * _Glossiness;
            //o.Occlusion = metalSmooth.g;
            o.Alpha = c.a;		
            // NormalMap 
            float3 normalMap = UnpackNormal (tex2D (_BumpMap, IN.uv_MainTex));
            o.Normal = normalMap;
            // Fresnel
			float fresnel = dot(normalMap, normalize(IN.viewDir));
			fresnel = saturate(1 - fresnel);
			fresnel = pow(fresnel, _FresnelExponent);	
            float3 fresnelColor = fresnel * _FresnelColor;
            //apply the fresnel value to the emission
            //o.Emission = _Emission;
            //o.Emission = _Emission + fresnelColor;
            o.Emission = _Emission + fresnelColor * abs(sin(_Time.y * _Speed));
            //#ifdef USE_FRESNEL
                //o.Emission = _Emission + fresnelColor;
                //Add time blink
			    //o.Emission = _Emission + fresnelColor * abs(sin(_Time.y * _Speed));
                //o.Emission = lerp(_Emission, _FresnelColor, fresnel * (abs(sin(_Time.y * _Speed))));
            //#endif
        }
        ENDCG
    }
    FallBack "Diffuse"
}
