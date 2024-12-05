#version 400 compatibility

uniform float viewWidth;
uniform float viewHeight;

out vec2 texcoord;

void main() {
	gl_Position = vec4((vec2(1.0, 0.5) * gl_Vertex.xy + vec2(-1.0, 0.0)), 0.0, 1.0);
	texcoord = gl_Vertex.xy;
}