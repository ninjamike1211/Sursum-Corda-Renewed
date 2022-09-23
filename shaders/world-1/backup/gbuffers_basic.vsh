#version 400 compatibility

out vec4 glColor;
flat out vec3 glNormal;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    glColor = gl_Color;
    glNormal = (gl_ModelViewMatrix * vec4(gl_Normal, 0.0)).xyz;
}