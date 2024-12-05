#version 400 compatibility

uniform float viewWidth;
uniform float viewHeight;

out vec2 texcoord;

void main() {
	gl_Position = vec4((vec2(0.0625, 0.03125) * gl_Vertex.xy + vec2(-1.0, 0.9375)), 0.0, 1.0);
	texcoord = gl_Vertex.xy;
}