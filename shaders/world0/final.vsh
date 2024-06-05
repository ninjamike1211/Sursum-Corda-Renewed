#version 430 compatibility


// ------------------------ File Contents -----------------------
    // Standard fullscreen post-process vertex shader


/*

*/

out vec2 texcoord;

void main() {
    // gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    // texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // Procedurally generates a single triangle that covers the screen
    int id = gl_VertexID;
    ivec2 uv = id & ivec2(1, 2);
    gl_Position = vec4(uv * ivec2(4, 2) - 1, 0.0, 1.0);

    texcoord = gl_Position.xy * 0.5 + 0.5;
}