#version 430 compatibility

in vec4 starData;

layout(location = 0) out vec4 color;

void main() {
    if(starData.a > 0.5)
        discard;
    color = vec4(0.0);
}