#version 430 compatibility

/*
const bool colortex0MipmapEnabled = true;
*/

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/bloomTile.glsl"


// ------------------------ File Contents -----------------------
    // Calculate and output unfiltered bloom tiles to colortex11


/* RENDERTARGETS: 11*/
layout(location = 0) out vec4 bloomOut;

in vec2 texcoord;

void main() {

// ------------------------- Bloom Tiles ------------------------
    int mipmap;
    vec2 samplecoord;
    getTileCoordStore(texcoord, 1.0 / vec2(viewWidth, viewHeight), Bloom_Tiles, mipmap, samplecoord);

    if(mipmap == -1)
        bloomOut.rgb = vec3(0.0);
    else {
        // samplecoord -= 0.25 * exp(-mipmap+1) / vec2(viewWidth, viewHeight);

        bloomOut.rgb = textureLod(colortex0, samplecoord, mipmap+1).rgb;

        bloomOut.rgb *= smoothstep(0.3, 1.0, luminance(bloomOut.rgb));

        // bloomOut.rgb *= 0.5 * (-float(mipmap+1) / 8.0 + 1.0);
        bloomOut.rgb *= 0.5 / (0.5 * mipmap + 1);

        // vec4 specMap = texelFetch(colortex4, ivec2(samplecoord * vec2(viewWidth, viewHeight)), 0);
        // // vec4 specMap = textureLod(colortex4, samplecoord, 0);
        // float emissiveness = specMap.a > 254.5/255.0 ? 0.0 : specMap.a * EmissiveStrength;
        // bloomOut.rgb += bloomOut.rgb * emissiveness * 10.0;

        // bloomOut.rgb = vec3(emissiveness);

        // bloomOut.rgb = vec3(0.0);
    }
}