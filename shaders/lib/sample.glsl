#ifndef SAMPLE
#define SAMPLE

// Vogel Disk sample function, from Tech#2594 (https://www.shadertoy.com/view/NdBGDR)
vec2 GetVogelDiskSample(int sampleIndex, int sampleCount, float phi) 
{
	const float goldenAngle = 2.399963;
	float sampleIndexF = float(sampleIndex);
	float sampleCountF = float(sampleCount);
	
	float r = sqrt((sampleIndexF + 0.5) / sampleCountF);
	float theta = sampleIndexF * goldenAngle + phi;
	
	float sine = sin(theta);
	float cosine = cos(theta);
	
	return vec2(cosine, sine) * r;
}

/*
    Texture Bicubic provided by swr#1793
*/
vec4 cubic(float v) {
    vec4 n  = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s  = pow(n, vec4(3.0));
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) / 6.0;
}
 
vec4 textureBicubic(sampler2D tex, vec2 texCoords) {
    vec2 texSize    = textureSize(tex, 0);
    vec2 invTexSize = 1.0 / texSize;
 
    texCoords = texCoords * texSize - 0.5;
 
    vec2 fxy   = fract(texCoords);
    texCoords -= fxy;
 
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
 
    vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
 
    vec4 s      = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
 
    offset *= invTexSize.xxyy;
 
    vec4 sample0 = texture2D(tex, offset.xz);
    vec4 sample1 = texture2D(tex, offset.yz);
    vec4 sample2 = texture2D(tex, offset.xw);
    vec4 sample3 = texture2D(tex, offset.yw);
 
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
 
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

vec4 textureBicubicWrap(sampler2D tex, vec2 texCoords, vec4 bounds) {
    vec2 texSize    = textureSize(tex, 0);
    vec2 invTexSize = 1.0 / texSize;
 
    texCoords = texCoords * texSize - 0.5;
 
    vec2 fxy   = fract(texCoords);
    texCoords -= fxy;
 
    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);
 
    vec4 c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;
 
    vec4 s      = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4(xcubic.yw, ycubic.yw) / s;
 
    offset *= invTexSize.xxyy;

	vec2 boundSize = bounds.zw - bounds.xy;
	offset = mod(offset - bounds.xxyy, boundSize.xxyy) + bounds.xxyy;
 
    vec4 sample0 = texture2D(tex, offset.xz);
    vec4 sample1 = texture2D(tex, offset.yz);
    vec4 sample2 = texture2D(tex, offset.xw);
    vec4 sample3 = texture2D(tex, offset.yw);
 
    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);
 
    return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

#endif