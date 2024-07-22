#version 400 compatibility

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = gl_Position.xy * 0.5 + 0.5;
}