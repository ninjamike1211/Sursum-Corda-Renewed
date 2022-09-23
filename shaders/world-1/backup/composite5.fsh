#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform float viewWidth;
uniform float viewHeight;

#include "/defines.glsl"
#include "/bloomTile.glsl"
#include "/kernels.glsl"

/* RENDERTARGETS: 11*/
layout(location = 0) out vec4 bloomOut;

in vec2 texcoord;

void main() {
    
    int mipmap;
    vec2 samplecoord;
    getTileCoordStore(texcoord, 1.0 / vec2(viewWidth, viewHeight), Bloom_Tiles, mipmap, samplecoord);

    if(mipmap == -1)
        bloomOut.rgb = vec3(0.0);
    else {
        bloomOut.rgb = textureLod(colortex0, samplecoord, mipmap+1).rgb / float(mipmap+1) * 1.3;

        vec4 specMap = texelFetch(colortex4, ivec2(samplecoord * vec2(viewWidth, viewHeight)), 0);
        float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * 0.6;
        bloomOut.rgb += bloomOut.rgb * emissiveness * 10.0;
    }
}