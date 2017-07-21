Shader "Unlit/GroundPlaneMat"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float3 _LowColor;
			float3 _DistanceColor;
			float3 _EffectorPos;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uvs : TEXCOORD0;
			};

			struct v2f
			{
				float2 uvs : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos: TEXCOORD1;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvs = v.uvs;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{ 
				float distToEffector = length(i.worldPos - _EffectorPos);
				float effectorLight = pow(saturate(1 - distToEffector / 5), 5);

				float distToCenter = 1 - length(i.uvs - .5) * 2;
				float3 color = lerp(_DistanceColor, _LowColor, distToCenter);

				return float4(color + effectorLight, 1);
			}
			ENDCG
		}
	}
}
