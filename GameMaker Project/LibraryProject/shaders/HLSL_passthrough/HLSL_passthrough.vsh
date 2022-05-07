//
// Simple passthrough vertex shader
//
// See https://maddestudiosgames.com/hlsl11-passthrough-shader-for-gamemaker-studio-2/ for more things you can do with these, including MRTs 
//
//Input from Vertices
struct VertexShaderInput
{
	float3 pos : POSITION;
//	float3 norm : NORMAL;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};
//Output Struct to Pixel Shader
struct VertexShaderOutput
{
	float4 pos : SV_POSITION;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};
//Main Program
VertexShaderOutput main(VertexShaderInput input)
{
    VertexShaderOutput output;
    float4 pos = float4(input.pos, 1.0f);
    // Transform the vertex position into projected space.
    pos = mul(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION], pos);
    output.pos = pos;
    // Pass through the color
    output.color = input.color;
    // Pass through uv
    output.uv = input.uv;   
    return output;
}
