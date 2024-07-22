#define DOF_ImageDistance 0.01
#define DOF_MaxRadius 0.05
#define DOF_MinRadius 0.001

float getCoCFromDepth(float depthLinear, float centerDepthLinear) {
    float focalLength = 1.0 / (1.0 / centerDepthLinear + 1.0 / DOF_ImageDistance);
    float CoC = (focalLength * (depthLinear - centerDepthLinear)) / (depthLinear * (centerDepthLinear - focalLength));

    CoC = clamp(CoC, -DOF_MaxRadius, DOF_MaxRadius);

    return CoC / DOF_MaxRadius;
}