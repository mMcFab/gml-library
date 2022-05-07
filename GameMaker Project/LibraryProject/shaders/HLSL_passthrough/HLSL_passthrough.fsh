//
// Simple passthrough fragment shader
//
//Output From Vertex Shader
struct PixelShaderInput
{
    float4 pos : SV_POSITION;
    float4 color : COLOR0;
    float2 uv : TEXCOORD0;
};
//Main Program
float4 main(PixelShaderInput input) : SV_TARGET
{
    float4 vertColour = input.color;
    float4 texelColour = gm_BaseTextureObject.Sample(gm_BaseTexture, input.uv);
    float4 combinedColour = vertColour * texelColour;
    return combinedColour;
}
