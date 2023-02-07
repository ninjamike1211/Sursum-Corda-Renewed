#include "/lib/defines.glsl"


layout (triangles) in;
layout(triangle_strip, max_vertices = 3) out;


in VertexData {
    vec2 texcoord;
    vec4 glColor;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 scenePos;
    vec3 tbnPos;
    flat mat3 tbn;
    flat vec4 textureBounds;
    flat vec3 glNormal;
    flat vec3 skyAmbient;
    flat vec3 skyDirect;
    flat int  entity;

    #ifdef inNether
        flat vec3 lightDir;
        flat vec3 lightDirView;
    #endif

    // #ifdef POM_TexSizeFix
        vec2 localTexcoord;
    // #endif

    #if defined TAA || defined MotionBlur
        vec4 oldClipPos;
        vec4 newClipPos;
    #endif

} dataIn[];

out GeomData {
    flat vec3 lightmapBlockDir;
    flat vec3 lightmapSkyDir;

    vec2 texcoord;
    vec4 glColor;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 scenePos;
    vec3 tbnPos;
    flat mat3 tbn;
    flat vec4 textureBounds;
    flat vec3 glNormal;
    flat vec3 skyAmbient;
    flat vec3 skyDirect;
    flat int  entity;

    #ifdef inNether
        flat vec3 lightDir;
        flat vec3 lightDirView;
    #endif

    // #ifdef POM_TexSizeFix
        vec2 localTexcoord;
    // #endif

    #if defined TAA || defined MotionBlur
        vec4 oldClipPos;
        vec4 newClipPos;
    #endif

} dataOut;


void main() {

    float len01 = distance(dataIn[0].localTexcoord, dataIn[1].localTexcoord);
    float len12 = distance(dataIn[1].localTexcoord, dataIn[2].localTexcoord);
    float len20 = distance(dataIn[2].localTexcoord, dataIn[0].localTexcoord);

    float sideLen = min(min(len01, len12), len20);

    int cornerVertex = (len01 > sideLen) ? 2 : (len12 > sideLen ? 0 : 1);

    vec4 lightTangentDir = vec4(0.0);

    for(int i = 0; i < 3; i++) {
        if(i != cornerVertex) {
            lightTangentDir += (dataIn[i].localTexcoord - dataIn[cornerVertex].localTexcoord).xyxy * (dataIn[i].lmcoord - dataIn[cornerVertex].lmcoord).xxyy;
        }
    }

    vec3 blockDir = dataIn[0].tbn * vec3(normalize(lightTangentDir.xy), 0.0);
    vec3 skyDir   = dataIn[0].tbn * vec3(normalize(lightTangentDir.zw), 0.0);


    for(int i = 0; i < 3; i++) {

        gl_Position = gl_in[i].gl_Position;

        dataOut.lightmapBlockDir = blockDir;
        dataOut.lightmapSkyDir   = skyDir;

        dataOut.texcoord      = dataIn[i].texcoord;
        dataOut.glColor       = dataIn[i].glColor;
        dataOut.lmcoord       = dataIn[i].lmcoord;
        dataOut.viewPos       = dataIn[i].viewPos;
        dataOut.scenePos      = dataIn[i].scenePos;
        dataOut.tbnPos        = dataIn[i].tbnPos;
        dataOut.tbn           = dataIn[i].tbn;
        dataOut.textureBounds = dataIn[i].textureBounds;
        dataOut.glNormal      = dataIn[i].glNormal;
        dataOut.skyAmbient    = dataIn[i].skyAmbient;
        dataOut.skyDirect     = dataIn[i].skyDirect;
        dataOut.entity        = dataIn[i].entity;

        #ifdef inNether
            dataOut.lightDir     = dataIn[i].lightDir;
            dataOut.lightDirView = dataIn[i].lightDirView;
        #endif

        #ifdef POM_TexSizeFix
            dataOut.localTexcoord = dataIn[i].localTexcoord;
        #endif

        #if defined TAA || defined MotionBlur
            dataOut.oldClipPos = dataIn[i].oldClipPos;
            dataOut.newClipPos = dataIn[i].newClipPos;
        #endif

        EmitVertex();

    }

    EndPrimitive();
}