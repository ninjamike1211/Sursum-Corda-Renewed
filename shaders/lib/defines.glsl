#ifndef DEFINES
#define DEFINES

/*
		Buffer Constants

const int colortex0Format = RGBA16F;
const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const bool colortex0MipmapEnabled = true;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const int colortex2Format  = RGB32UI;
const int colortex3Format  = RGB8;
const int colortex3Format  = RGB10_A2;
const int colortex5Format  = R32F;
const int colortex6Format  = RG16_SNORM;
const int colortex7Format  = RGB16F;
const int colortex8Format  = RGB8;
const int colortex9Format  = R8;
const int colortex10Format = RGB16F;
const int colortex11Format = RGB16F;
const int colortex12Format = RGBA8;
const bool colortex12Clear = false;
const int colortex14Format = R16F;
const bool colortex14Clear = false;
const int colortex15Format = RGBA16F;
const bool colortex15Clear = false;
const int shadowcolor0Format = RGBA16F;
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


// Lighting Constants
	#define netherAmbientLight 	vec3(0.4, 0.02, 0.01)
	#define netherDirectLight 	(fogColor * 5.0)
	#define endAmbientLight 	vec3(1.0, 0.8, 1.1)
	#define endDirectLight 		vec3(0.15, 0.08, 0.3)


// Temporal Anti-aliasing
	#define TAA // Temporal anti-alliasing, smooths edges and improves visual quality, sometimes causes ghosting
	#define TAA_NEIGHBORHOOD_SIZE 1


// Shadows
	const int 	shadowMapResolution = 	2048;	// Resolution of shadow map, higher resolution means sharper shadows but less performance [512 1024 2048 4096]
	const float shadowDistance = 		120;	// Distance to render shadows at, higher numbers mean farther shadows but lower quality overall [90 120 160 200 240]

	#define Shadow_Distort_Factor 	0.1
	#define Shadow_Bias 			0.0001
	#define ShadowSamples 			32 		// Number of samples used calculating shadow blur [4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 56 64 72 80 88 96 112 128]
	#define ShadowBlockSamples 		16 		// Number of samples used for PCSS blocking [2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 36 40 44 48 56 64]
	#define ShadowBlurScale 		0.20 	// Scale of shadow blur [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75]
	#define ShadowMinBlur 			0.00020 // Maximum shadow blur with PCSS [0.00000 0.00002 0.00004 0.00006 0.00008 0.00010 0.00012 0.00014 0.00016 0.00018 0.00020 0.00025 0.00030 0.00040 0.00050]
	#define ShadowMaxBlur 			0.020 	// Maximum shadow blur with PCSS [0.00 0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050]
	#define ShadowNoiseAnimated 			// When enabled move noise with each frame, allowing for lower shadow samples at the cost of noise "moving"
	#define Shadow_LeakFix


// Water
	// #define Water_Flat
	// #define Water_Noise
	#define Water_Direction  0
	#define Water_Depth 	 0.4


// Volumetric Effects
	#define VolFog								// Volumetric fog, fog that is affected by lighting and shadows, large performance impact
	// #define VolFog_Colored
	// #define VolFog_SmoothShadows				// Uses smooth shadows for fog, large performance impact
	#define VolFog_Steps 				16 		// Number of samples used for volumetric fog [8 12 16 20 24 32 48 64 96 128]
	#define VolFog_SmoothShadowSamples 	4 		// Number of samples used for smooth shadows in volumetric fog [1 2 4 6 8 10 12 14 16 20 24 32]
	#define VolFog_SmoothShadowBlur 	0.002 	// Amount of blur applied ot shadows in volumetric fog [0.000 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010 0.015 0.020]

	#define VolWater						// Volumetric fog in water, looks good but large performance impact
	#define VolWater_Steps 		16			// Number of samples in fog [4 6 8 12 16 20 24 28 32 48 64]
	#define VolWater_LightSteps 8			// Number of samples in light [2 4 6 8 10 12 16 20 24 28 32]
	#define VolWater_Colored
	// #define VolWater_SmoothShadows		// Uses smooth shadows for fog, large performance impact
	#define VolWater_SmoothShadowSamples 4 	// Number of samples used for smooth shadows in volumetric water [1 2 4 6 8 10 12 14 16 20 24 32]
	#define VolWater_SmoothShadowBlur 0.003 // Amount of blur applied ot shadows in volumetric water [0.000 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010 0.015 0.020]


// Ambient Occlusion
	#define SSAO				// Screen space ambient occlusion, adds shadows between blocks and entites, medium performance impact
	#define SSAO_Radius 	0.5 // Radius of SSAO. Higher values causes ao to be more spread out. Lower values will concentrate shadows more in corners. [0.125 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 3.0 4.0 5.0]
	#define SSAO_Strength 	1.0 // Strength of ambient shadows. 0 means no shadows. Higher numbers mean darker shadows. [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]


// Screen Space Reflections
	#define SSR					// Screen space reflections, adds reflections to shiney surfaces, including water
	#define SSR_Steps 		64	// Steps to use in main SSR loop [16 20 24 28 32 40 48 64 72]
	#define SSR_BinarySteps 4	// Binary refinement steps in SSR loop [1 2 4 6 8 12 16]

#define SSS	// Sub-surface scattering


// Clouds
	#define cloudsEnable				// Enables flat clouds in sky
	#define lowCloudHeight 		1000	// Lower cloud layer height
	#define highCloudHeight		3000	// Upper cloud layer height
	#define lowCloudRadius 		100000	// Lower cloud layer curve radius
	#define highCloudRadius		500000	// Upper cloud layer curve radius
	#define lowCloudNormalMult 	0.5		// Lower cloud layer normal multiplier
	#define highCloudNormalMult 0.004	// Upper cloud layer normal multiplier
	// #define cloudDualLayer			// Uses second layer for lower clouds to create parallax effect
	#ifdef cloudDualLayer
		#define lowCloud2Height 1050	// Dual cloud layer height
		#define lowCloud2Radius 100000	// Dual cloud layer curve radius
	#endif

	#define netherCloudHeight 1000		// Nether cloud height
	#define netherCloudRadius 100000	// Nether cloud curve radius


// Parallax Mapping
	#define POM
	// #define POM_Variable_Layer		// Uses a variable number of layers when calculating POM based on view direction
	#define POM_SlopeNormals			// Overwrites normals on the edges of POM with direction the edge faces instead of the texture normal
	#define POM_Shadow					// POM self shadowing, fairly expensive.
	#define POM_PDO						// POM pixel depth offset, writes to the depth buffer to after POM for slightly more accurate depth information at a slight performance cost (sometimes breaks resource packs)
	#define POM_Depth 			1.0 	// Depth of POM in blocks. Lower values decreases effect. Appealing values may depend on resource pack [0.2 0.4 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.6 1.8 2.0 3.0 4.0]
	#define POM_Layers 			50 		// Quality of POM. Higher values are better quality with more performance cost [5 10 20 30 40 50 75 100 200]
	#define POM_Shadow_Layers 	50 		// Quality of POM shadows. Higher values are better quality with more performance cost [5 10 20 30 40 50 75 100 200]
	#define POM_Distance 		16.0	// Distance at which POM stops rendering, lower values increase performance [8.0 12.0 16.0 24.0 32.0 36.0 40.0 44.0 48.0 56.0 64.0 96.0]
	#define POM_FadeWidth 		8.0		// Width of the blend at the edge of POM rendering
	#define POM_Filter			0		// POM Heightmap interpolation type. nearest neightbor : blocky, fastest. bilinear : smooth, very fast. bicubic : smoothest, slow. [0 1 2]

	#define Water_POM
	#define Water_POM_Layers 30


// Bloom
	#define Bloom				// A light-blurring effect that makes bright objects appear more visually bright
	#define Bloom_Bicubic		// Uses bicubic filtering when sampling bloom, higher quality with only a slight performance hit
	#define Bloom_Strength 	1.0 // Strength of Bloom [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define Bloom_Tiles		6	// Number of bloom tiles, more means higher quality at higher performance cost
 

#define LensFlare	// A lens flare effect caused by looking at the sun


// Directional and Hand lighting
	#define DirectionalLightmap
	#define DirectionalLightmap_Strength 0.5	// Strength of directional lightmap [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

	#define HandLight
	#define HandLight_Colors
	#define HandLight_Shadows


// Motion Blur
	#define MotionBlur
	#define MotionBlur_Samples 16
	#define MotionBlur_Strength 1.0		// Strength of motion blur [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]


// Depth of Field
	#define DOF							// Depth of Field effect, makes very close or far objects appear blurry
	#define DOF_HandBlur				// Enables blurring of handheld items, which can sometimes looks strange
	#define DOF_NearBlur				// Enables blurring of objects closer than the point of focus
	#define DOF_VariableSampleCount		// Enables variable sample count, where the number of samples depends on the size of the blur
	#define DOF_NearTransitionBlur		// Blurs the DOF CoC buffer so that near objects blur better onto in-focus objects
	#define DOF_ConstSamples 	128		// The sample count used when DOF_VariableSampleCount is disabled [8 12 16 24 32 48 64 96 128 192 256 320 384 448 512]
	#define DOF_SampleDensity 	1.0		// The density (roughly samples/pixel) used when DOF_VariableSampleCount is enabled [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.4 2.6 2.8 3.0 3.5 4.0]
	#define DOF_MaxSamples 		512		// Maximum samples when DOF_VariableSampleCount is enabled [16 24 32 48 64 96 128 192 256 320 384 448 512 640 768 1024]
	#define DOF_MinSamples 		32		// Minimum samples when DOF_VariableSampleCount is enabled [4 6 8 12 16 20 24 32 38 64 72 80 88 96 112 128]
	#define DOF_BlurAmount		1.0		// Mutliplier for DOF blur radius, effectively a DOF amount slider [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define DOF_FocusSpeed		7.5		// Speed of focus change [-1.0 1.0 2.0 3.0 4.0 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 13.0 14.0 15.0]
	#define DOF_MaxRadius		0.05	// Maximum radius of blur
	#define DOF_ImageDistance 	0.01	// Internal value, distance between image plane and lens


#define EmissiveStrength 1.0 // Strength of texture emissives [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.4 2.6 2.8 3.0 3.5 4.0]


// Waving objects and wind
	#define wavingPlants

	#define Wind_AngleSpeed			0.05
	#define Wind_AmplitudeSpeed		0.2
	#define Wind_MinAmp				0.1
	#define Wind_MaxAmp				0.25
	#define Wind_MinAmpRain			0.5
	#define Wind_MaxAmpRain			1.0
	#define Wind_Phase_Slope 		15.0
	#define Wind_Phase_Offset		0.0

	#define Wind_Leaf_YFactor		0.5
	#define Wind_Leaf_Wavelength   	0.75
	#define Wind_Leaf_Offset 		0.1
	#define Wind_Leaf_WaveStrength	0.07

	#define Wind_Plant_Wavelength 	2.0
	#define Wind_Plant_Offset		0.3
	#define Wind_Plant_Wavestrength	0.1

	#define Wind_Vine_YWavelength 	1.0
	#define Wind_Vine_XZWavelength 	0.25
	#define Wind_Vine_Offset		0.1
	#define Wind_Vine_Wavestrength 	0.1


// Nether settings
#ifdef inNether
	// #define Nether_CloudFog
#endif

#endif