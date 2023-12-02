#version 400 compatibility

flat out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	glcolor  = gl_Color;
}