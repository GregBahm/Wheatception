Shader "Unlit/WheatShader"
{
	Properties
	{
	}
	SubShader
	{
		Cull Off
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma target 5.0 
			
			#include "UnityCG.cginc"

			struct FixedWheatData
			{
				float2 PlanePos;
				float2 PlaneTangent;
			};

			struct VariableWheatData
			{
				float3 StalkNormal;
				float2 PlanarVelocity;
			};

			struct v2g
			{
				float4 BasePoint : TEXCOORD0;
				float2 PlaneTangent : TEXCOORD1;
				float4 StalkNormal : TEXCOORD2;
				float DistToEffector : TEXCOORD3;
				float PlaneDistToCenter: TEXCOORD4;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uvs : TEXCOORD0;
				float planeDistToCenter : TEXCOOR1;
				float distToEffector : TEXCOORD2;
			};

			StructuredBuffer<FixedWheatData> _FixedDataBuffer;
			StructuredBuffer<VariableWheatData> _VariableDataBuffer; 

			float _CardWidth;
			float2 _PlayspaceScale;
			float _CardHeight;
			float3 _HighColor;
			float3 _LowColor;
			float3 _DistanceColor;
			float3 _EffectorColor;

			float3 _EffectorPos;

			v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
			{
				FixedWheatData fixedData = _FixedDataBuffer[instanceId];
				VariableWheatData variableData = _VariableDataBuffer[instanceId];


				float4 basePoint = float4(fixedData.PlanePos.x, 0, fixedData.PlanePos.y, 1);
				basePoint.xz = (basePoint.xz - .5) * 2;
				basePoint.xz *= _PlayspaceScale;

				float4 stalkNormal = float4(variableData.StalkNormal * _CardHeight, 1);

				float distToEffector = length(basePoint.xyz - _EffectorPos);

				v2g o;
				o.BasePoint = basePoint;
				o.PlaneTangent = fixedData.PlaneTangent;
				o.StalkNormal = stalkNormal;
				o.DistToEffector = distToEffector;
				o.PlaneDistToCenter = length(fixedData.PlanePos - .5) * 2;
				return o;
			}

			[maxvertexcount(4)]
			void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
			{

				float2 card = p[0].PlaneTangent * _CardWidth;
				float4 topPointA = float4(-card.x, 0, -card.y, 0) + p[0].StalkNormal;
				float4 topPointB = float4(card.x, 0, card.y, 0) + p[0].StalkNormal;
				float4 bottomPointA = float4(-card.x, 0, -card.y, 0);
				float4 bottomPointB = float4(card.x, 0, card.y, 0);

				g2f o;
				o.distToEffector = p[0].DistToEffector;
				o.planeDistToCenter = p[0].PlaneDistToCenter;
				o.vertex = UnityObjectToClipPos(topPointA + p[0].BasePoint);
				o.uvs = float2(0, 1);
				triStream.Append(o);
				
				o.vertex = UnityObjectToClipPos(topPointB + p[0].BasePoint);
				o.uvs = float2(1, 1);
				triStream.Append(o);
				
				o.vertex = UnityObjectToClipPos(bottomPointA + p[0].BasePoint);
				o.uvs = float2(0, 0);
				triStream.Append(o);
				
				o.vertex = UnityObjectToClipPos(bottomPointB + p[0].BasePoint);
				o.uvs = float2(1, 0);
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target
			{
				float effectorLightPower = pow(saturate(1 - i.distToEffector / 5), 5);
				float3 effectorLight = _EffectorColor * effectorLightPower;
				float quadDistToCenter = 1 - length(i.uvs - .5) * 2;
				clip(quadDistToCenter - .01);
				float3 highColor = _HighColor + (_HighColor * i.planeDistToCenter);
				float3 color = lerp(_LowColor, highColor, pow(i.uvs.y, 2));
				color = lerp(color, _DistanceColor, saturate(i.planeDistToCenter));
				return float4(color + effectorLight, 1);
			}
			ENDCG
		}
	}
}
