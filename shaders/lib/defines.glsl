#ifndef DEFINES
#define DEFINES


// Buffer formats

/*
const int colortex0Format = RGB16F;
const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const int colortex1Format  = RGBA16F;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const int colortex3Format  = RG16;
const int colortex5Format  = RG16;
const int colortex6Format  = R8UI;
const int colortex7Format  = RGB8;
const int colortex10Format = RGB16F;
const int colortex12Format = R8_SNORM;
const int colortex15Format = RGBA16F;
const bool colortex15Clear = false;
*/

// Constants
	#define EPS	1e-4

	#define HALF_PI	1.57079632
	#define PI		3.14159265
	#define TAU		6.28318530
	#define RCP_PI	0.31830988
	#define RCP_TAU	0.15915494

	#define GOLDEN_RATIO 1.61803398
	#define GOLDEN_ANGLE 2.39996322


// Shadows
	#define Shadow_Type 3					// Type of shadow mapping. 0 = off. 1 = no filtering. 2 = pcf. 3 = pcss [0 1 2 3]
	// #define Shadow_HardwareSampler
	#define Shadow_Transparent 2			// Controls shadows for transparent shadows. 0 = off. 1 = full shadow. 2 = colored shadow [0 1 2]

    const bool shadowHardwareFiltering = true;
	const bool shadowtex0Nearest = false;
	const bool shadowtex1Nearest = false;
	const bool shadowcolor0Nearest = false;
	const int shadowMapResolution =	2048;	// Resolution of shadow map, higher resolution means sharper shadows but less performance [512 1024 2048 4096 8192]
    #define Shadow_Distort_Factor 0.10      // Distortion factor for the shadow map. Has no effect when shadow distortion is disabled. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
    #define Shadow_Bias 5.0                	// Increase this if you get shadow acne. Decrease this if you get peter panning. [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.60 0.70 0.80 0.90 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 6.00 7.00 8.00 9.00 10.00]
    #define Shadow_NormalBias               // Offsets the shadow sample position by the surface normal instead of towards the sun
	#define Shadow_PCF_Samples 12			// Number of samples used calculating shadow blur [4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 56 64 72 80 88 96 112 128]
	#define Shadow_PCF_BlurRadius 0.00025	// Blur radius for non-PCSS PCF shadow filtering [0.00000 0.00005 0.00010 0.00015 0.00020 0.00025 0.00030 0.00035 0.00040 0.00045 0.00050]
	#define Shadow_PCSS_BlurScale 0.05 		// Scale of shadow blur [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75]
	#define Shadow_PCSS_MaxBlur 0.0050		// Maximum shadow blur with PCSS [0.00 0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050]
	#define Shadow_PCSS_BlockSamples 8		// Number of samples used for PCSS blocking [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 56 64]
	#define Shadow_PCSS_BlockRadius Shadow_PCSS_MaxBlur
	#define Shadow_NoiseAnimated 			// When enabled move noise with each frame, allowing for lower shadow samples at the cost of noise "moving"

	#define DirectionalLightmap
	#define DirectionalLightmap_Strength 1.0
	const float ambientOcclusionLevel = 0.0;
	// #define Texture_AO
	#define Texture_AO_Strength 1.0			// Strength of labPBR texture AO, applies only to ambient lighting [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

	const float sunPathRotation = -20;

// DOF
	// #define DOF

// TAA
	#define TAA

// Reflections
	#define Reflections 2					// The type of reflections used [0 1 2]

// Lighting
	#define EmissiveStrength 10.0

// Parallax
	#define Parallax
	#define Parallax_Shadows
	#define Parallax_TraceToEdge
	#define Parallax_EdgeNormals
	#define Parallax_DepthOffset
	#define Parallax_DiscardEdge
	#define Parallax_Depth 1.0				// Parallax Depth multiplier (default is 1.0 which is 1/4 block depth) [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

// Voxelization
	// #define UseVoxelization

// MCEntity
	#define MCEntity_Leaves 10001
	#define MCEntity_Grass 10002
	#define MCEntity_TallGrass_Bottom 10003
	#define MCEntity_TallGrass_Top 10004
	#define MCEntity_Lilypad 10005
	#define MCEntity_Vine 10006
	#define MCEntity_Chain_Vertical 10007
	#define MCEntity_Lantern_Hanging 10008
	#define MCEntity_Water 10010
	#define MCEntity_Lava 10011
	#define MCEntity_EndPortal 10020
	#define MCEntity_Cauldron_Water 10030
	#define MCEntity_Cauldron_Lava 10031

// BitMask
	#define Mask_Water 128
	#define Mask_Hand 64

#ifdef Parallax_EdgeNormals
#endif
#ifdef Shadow_Transparent
#endif
#ifdef Reflections
#endif

#endif