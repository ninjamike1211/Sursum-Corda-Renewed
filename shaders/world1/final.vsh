#version 430 compatibility

out vec2 texcoord;

void main() {
   gl_Position = ftransform();
   texcoord = gl_MultiTexCoord0.st;
}
