#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;
uniform int entityId;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	color *= texture2D(lightmap, lmcoord);

	if(entityId == 1)
		color = vec4(1.0, 0.0, 0.0, 1.0);
	else if(entityId == 65535)
		color = vec4(0.0, 1.0, 0.0, 1.0);
	else if(entityId == -1)
		color = vec4(0.0, 0.0, 1.0, 1.0);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}