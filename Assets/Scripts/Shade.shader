Shader "Custom/Shade"
{
	Properties
	{
		_Color("Color", COLOR) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_AmbientColor("Ambient Color", COLOR) = (1,1,1,1)
		_DiffuseColor("Diffuse Color", COLOR) = (1,1,1,1)
		_SpecularColor("Specular Color", COLOR) = (1,1,1,1)
		_AmbientVal("AmbientVal", Range(0,10)) = 0.0
		_DiffuseVal("DiffuseVal", Range(0,10)) = 0.5
		_SpecVal("SpecVal", Range(0,10)) = 0.5
		_Shininess("Shininess", Range(0,100)) = 1.0
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

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 color:COLOR0;
			};

			float4x4 transpose(float4x4 m) {
				return float4x4(
					m[0][0], m[1][0], m[2][0], m[3][0],
					m[0][1], m[1][1], m[2][1], m[3][1],
					m[0][2], m[1][2], m[2][2], m[3][2],
					m[0][3], m[1][3], m[2][3], m[3][3]
				);
			}

			float4x4 inverse(float4x4 m) {
				float
					a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3],
					a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3],
					a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3],
					a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3],

					b00 = a00 * a11 - a01 * a10,
					b01 = a00 * a12 - a02 * a10,
					b02 = a00 * a13 - a03 * a10,
					b03 = a01 * a12 - a02 * a11,
					b04 = a01 * a13 - a03 * a11,
					b05 = a02 * a13 - a03 * a12,
					b06 = a20 * a31 - a21 * a30,
					b07 = a20 * a32 - a22 * a30,
					b08 = a20 * a33 - a23 * a30,
					b09 = a21 * a32 - a22 * a31,
					b10 = a21 * a33 - a23 * a31,
					b11 = a22 * a33 - a23 * a32,

					det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

				return float4x4(
					a11 * b11 - a12 * b10 + a13 * b09,
					a02 * b10 - a01 * b11 - a03 * b09,
					a31 * b05 - a32 * b04 + a33 * b03,
					a22 * b04 - a21 * b05 - a23 * b03,
					a12 * b08 - a10 * b11 - a13 * b07,
					a00 * b11 - a02 * b08 + a03 * b07,
					a32 * b02 - a30 * b05 - a33 * b01,
					a20 * b05 - a22 * b02 + a23 * b01,
					a10 * b10 - a11 * b08 + a13 * b06,
					a01 * b08 - a00 * b10 - a03 * b06,
					a30 * b04 - a31 * b02 + a33 * b00,
					a21 * b02 - a20 * b04 - a23 * b00,
					a11 * b07 - a10 * b09 - a12 * b06,
					a00 * b09 - a01 * b07 + a02 * b06,
					a31 * b01 - a30 * b03 - a32 * b00,
					a20 * b03 - a21 * b01 + a22 * b00) / det;
			}



			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float4x4 mvp;
			float4x4 mv;
			float4x4 view;
			float4 lightPos;
			float4 _Color;
			float4 _AmbientColor;
			float4 _DiffuseColor;
			float4 _SpecularColor;
			float _AmbientVal;
			float _DiffuseVal;
			float _SpecVal;
			float _Shininess;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				// phong reflection shader

				// https://www.opengl.org/sdk/docs/tutorials/ClockworkCoders/lighting.php
				// https://en.wikipedia.org/wiki/Phong_reflection_model
				float3 N = mul(transpose(inverse(mv)), float4(v.normal, 1)); // normal matrix x vertex normal
				float3 lightVec = mul(view, lightPos); // viewmatrix x light position
				float3 V = mul(mv, o.vertex);
				float3 L = normalize(lightVec - V);

				float3 E = normalize(-V);
				float3 R = normalize(-reflect(L, N));

				float diffuseVal = _DiffuseVal;
				float diff = diffuseVal * max(dot(N, L), 0.0);
				diff = clamp(diff, 0.0, 1.0);

				// calculate Specular
				float specVal = _SpecVal;
				float shininess = _Shininess;
				float spec = specVal * pow(max(dot(R, E), 0.0), 0.3*shininess);
				spec = clamp(spec, 0.0, 1.0);

				float4 ambient = _AmbientVal * _AmbientColor;
				o.color = ambient +(_DiffuseColor * diff)+ (_SpecularColor*spec);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv)*i.color;
				return col;
			}
			ENDCG
		}
	}
}
