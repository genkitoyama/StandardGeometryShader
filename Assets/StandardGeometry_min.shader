// Standard geometry shader example
// https://github.com/keijiro/StandardGeometryShader

Shader "Standard Geometry Shader Example Min"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Albedo", 2D) = "white" {}

        [Space]
        _LocalTime("Animation Time", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM

            // Geometry Shaderを使うために4.0に設定
            #pragma target 4.0

            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment

            #include "UnityCG.cginc"
            #include "UnityStandardUtils.cginc"

            // Shader uniforms
            float4 _Color;
            sampler2D _MainTex;
            float _LocalTime;

            // Vertex Shader → Geometry Shader に渡すための構造体
            struct Attributes
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
            };

            // Geometry Shader → Fragment Shader に渡すための構造体
            struct Varyings
            {
                float4 position : SV_POSITION;
                float3 normal : NORMAL;
            };

            //
            // Vertex shader
            //
            Attributes Vertex(Attributes input)
            {
                // Only do object space to world space transform.
                input.position = mul(unity_ObjectToWorld, input.position);
                input.normal = UnityObjectToWorldNormal(input.normal);
                return input;
            }

            // Geometry Shaderの出力用の構造体を用意するための関数
            Varyings VertexOutput(float3 wpos, half3 wnrm)
            {
                Varyings o;
                o.position = UnityWorldToClipPos(float4(wpos, 1));
                o.normal = wnrm;
                return o;
            }


            // 3点から法線ベクトルを求めるための関数
            float3 ConstructNormal(float3 v1, float3 v2, float3 v3)
            {
                return normalize(cross(v2 - v1, v3 - v1));
            }

            //
            // Geometry shader
            //
            [maxvertexcount(15)]
            void Geometry(triangle Attributes input[3], uint pid : SV_PrimitiveID, inout TriangleStream<Varyings> outStream)
            {
                // Vertex inputs
                float3 wp0 = input[0].position.xyz;
                float3 wp1 = input[1].position.xyz;
                float3 wp2 = input[2].position.xyz;

                // Extrusion amount
                float ext = saturate(0.4 - cos(_LocalTime * UNITY_PI * 2) * 0.41);
                ext *= 1 + 0.3 * sin(pid * 832.37843 + _LocalTime * 88.76);

                // Extrusion points
                float3 offs = ConstructNormal(wp0, wp1, wp2) * ext;
                float3 wp3 = wp0 + offs;
                float3 wp4 = wp1 + offs;
                float3 wp5 = wp2 + offs;

                // Cap triangle
                float3 wn = ConstructNormal(wp3, wp4, wp5);
                float np = saturate(ext * 10);
                //各頂点での法線を再計算
                float3 wn0 = lerp(input[0].normal, wn, np);
                float3 wn1 = lerp(input[1].normal, wn, np);
                float3 wn2 = lerp(input[2].normal, wn, np);
                outStream.Append(VertexOutput(wp3, wn0));
                outStream.Append(VertexOutput(wp4, wn1));
                outStream.Append(VertexOutput(wp5, wn2));
                outStream.RestartStrip();

                // Side faces
                wn = ConstructNormal(wp3, wp0, wp4);
                outStream.Append(VertexOutput(wp3, wn));
                outStream.Append(VertexOutput(wp0, wn));
                outStream.Append(VertexOutput(wp4, wn));
                outStream.Append(VertexOutput(wp1, wn));
                outStream.RestartStrip();

                wn = ConstructNormal(wp4, wp1, wp5);
                outStream.Append(VertexOutput(wp4, wn));
                outStream.Append(VertexOutput(wp1, wn));
                outStream.Append(VertexOutput(wp5, wn));
                outStream.Append(VertexOutput(wp2, wn));
                outStream.RestartStrip();

                wn = ConstructNormal(wp5, wp2, wp3);
                outStream.Append(VertexOutput(wp5, wn));
                outStream.Append(VertexOutput(wp2, wn));
                outStream.Append(VertexOutput(wp3, wn));
                outStream.Append(VertexOutput(wp0, wn));
                outStream.RestartStrip();
            }

            //
            // Fragment shader
            //
            float4 Fragment(Varyings input) : COLOR
            {
                float4 col = _Color;
                col.rgb *= input.normal;
                return col;
            }

            ENDCG
        }
    }
}
