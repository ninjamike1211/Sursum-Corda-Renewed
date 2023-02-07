#version 420 compatibility


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader


out vec2 texcoord;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}