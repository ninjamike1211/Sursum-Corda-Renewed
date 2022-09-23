#version 400 compatibility

uniform sampler2D texture;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 2,4 */
layout(location = 0) out vec4 albedo;
layout(location = 1) out vec4 specMapOut;

void main() {
	// vec2 localTexcoord = (texcoord - textureBounds.xy) / (textureBounds.zw - textureBounds.xy);
	// if(vec2(clamp(texcoord.x, 0.35, 0.4063), clamp(texcoord.y, 0.0, 0.99)) != texcoord)
	// 	discard;

	albedo = texture2D(texture, texcoord) * glcolor;

	// if(albedo.r < 0.1)
	// 	discard;

	albedo.rgb = vec3(albedo.r);

	specMapOut = vec4(0.0, 0.0, 0.0, 254.0/255.0);
}