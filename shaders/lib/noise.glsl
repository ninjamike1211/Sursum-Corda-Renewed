#ifndef NOISE
#define NOISE

// #include "/defines.glsl"

// Interleaved Gradient Noise, from LowellCamp#8190 with optimization from SixthSurge#3922
const ivec2 interleave_vec = ivec2(1125928, 97931);
const float interleaved_z = 52.9829189;
const float fixed2float = 1.0 / exp2(24.0);
const int ref_fixed_point = int(exp2(24.0));

float interleaved_gradient(ivec2 seed, int t) {
    ivec2 components = ivec2(seed + 5.588238 * t) * interleave_vec;
    int internal_modulus = (components.x + components.y) & (ref_fixed_point - 1);
    return fract(float(internal_modulus) * (fixed2float * interleaved_z));
}


// simplex noise, from here: https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
	return mod289(((x*34.0)+10.0)*x);
}

float snoise(vec2 v) {
	const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
											0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
										 -0.577350269189626,  // -1.0 + 2.0 * C.x
											0.024390243902439); // 1.0 / 41.0
// First corner
	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
	vec2 i1;
	//i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
	//i1.y = 1.0 - i1.x;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	// x0 = x0 - 0.0 + 0.0 * C.xx ;
	// x1 = x0 - i1 + 1.0 * C.xx ;
	// x2 = x0 - 1.0 + 2.0 * C.xx ;
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;

// Permutations
	i = mod289(i); // Avoid truncation effects in permutation
	vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	m = m*m ;
	m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}



//
//	FAST32_hash
//	A very fast hashing function.  Requires 32bit support.
//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
//
//	The 2D hash formula takes the form....
//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMELARGEFLOAT ) / SOMELARGEFLOAT
//	We truncate and offset the domain to the most interesting part of the noise.
//	SOMELARGEFLOAT should be in the range of 400.0->1000.0 and needs to be hand picked.  Only some give good results.
//	A 3D hash is achieved by offsetting the SOMELARGEFLOAT value by the Z coordinate
//
vec4 FAST32_hash_2D( vec2 gridcell )	//	generates a random number for each of the 4 cell corners
{
	//	gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const float SOMELARGEFLOAT = 951.135664;
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;	//	truncate the domain
	P += OFFSET.xyxy;								//	offset to interesting part of the noise
	P *= P;											//	calculate and return the hash
	return fract( P.xzxz * P.yyww * ( 1.0 / SOMELARGEFLOAT ) );
}
void FAST32_hash_2D( vec2 gridcell, out vec4 hash_0, out vec4 hash_1 )	//	generates 2 random numbers for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec2 SOMELARGEFLOATS = vec2( 951.135664, 642.949883 );
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	hash_0 = fract( P * ( 1.0 / SOMELARGEFLOATS.x ) );
	hash_1 = fract( P * ( 1.0 / SOMELARGEFLOATS.y ) );
}
void FAST32_hash_2D( 	vec2 gridcell,
						out vec4 hash_0,
						out vec4 hash_1,
						out vec4 hash_2	)	//	generates 3 random numbers for each of the 4 cell corners
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec3 SOMELARGEFLOATS = vec3( 951.135664, 642.949883, 803.202459 );
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	hash_0 = fract( P * ( 1.0 / SOMELARGEFLOATS.x ) );
	hash_1 = fract( P * ( 1.0 / SOMELARGEFLOATS.y ) );
	hash_2 = fract( P * ( 1.0 / SOMELARGEFLOATS.z ) );
}
vec4 FAST32_hash_2D_Cell( vec2 gridcell )	//	generates 4 different random numbers for the single given cell point
{
	//	gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 );
	const float DOMAIN = 71.0;
	const vec4 SOMELARGEFLOATS = vec4( 951.135664, 642.949883, 803.202459, 986.973274 );
	vec2 P = gridcell - floor(gridcell * ( 1.0 / DOMAIN )) * DOMAIN;
	P += OFFSET.xy;
	P *= P;
	return fract( (P.x * P.y) * ( 1.0 / SOMELARGEFLOATS.xyzw ) );
}

// Perlin noise, from here: https://github.com/BrianSharpe/GPU-Noise-Lib/blob/master/gpu_noise_lib.glsl

//
//	SimplexPerlin2D  ( simplex gradient noise )
//	Perlin noise over a simplex (triangular) grid
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2012/01/simplexperlinsample.jpg
//
//	Implementation originally based off Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//
float SimplexPerlin2D( vec2 P )
{
    //	simplex math constants
    const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
    const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
    const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle
    const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );		//	vertex info for simplex triangle

    //	establish our grid cell.
    P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
    vec2 Pi = floor( P + dot( P, vec2( SKEWFACTOR ) ) );

    //	calculate the hash.
    //	( various hashing methods listed in order of speed )
    vec4 hash_x, hash_y;
    FAST32_hash_2D( Pi, hash_x, hash_y );
    //SGPP_hash_2D( Pi, hash_x, hash_y );

    //	establish vectors to the 3 corners of our simplex triangle
    vec2 v0 = Pi - dot( Pi, vec2( UNSKEWFACTOR ) ) - P;
    vec4 v1pos_v1hash = (v0.x < v0.y) ? vec4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : vec4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
    vec4 v12 = vec4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;

    //	calculate the dotproduct of our 3 corner vectors with 3 random normalized vectors
    vec3 grad_x = vec3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999;
    vec3 grad_y = vec3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999;
    vec3 grad_results = inversesqrt( grad_x * grad_x + grad_y * grad_y ) * ( grad_x * vec3( v0.x, v12.xz ) + grad_y * vec3( v0.y, v12.yw ) );

    //	Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //	x = ( sqrt( 0.5 )/sqrt( 0.75 ) ) * 0.5
    //	NF = 1.0 / ( x * ( ( 0.5  x*x ) ^ 4 ) * 2.0 )
    //	http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 99.204334582718712976990005025589;

    //	evaluate the surflet, sum and return
    vec3 m = vec3( v0.x, v12.xz ) * vec3( v0.x, v12.xz ) + vec3( v0.y, v12.yw ) * vec3( v0.y, v12.yw );
    m = max(0.5 - m, 0.0);		//	The 0.5 here is SIMPLEX_TRI_HEIGHT^2
    m = m*m;
    return dot(m*m, grad_results) * FINAL_NORMALIZATION;
}

//
//	SimplexPerlin2D_Deriv
//	SimplexPerlin2D noise with derivatives
//	returns vec3( value, xderiv, yderiv )
//
vec3 SimplexPerlin2D_Deriv( vec2 P )
{
	//	simplex math constants
	const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
	const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
	const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle
	const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR );		//	vertex info for simplex triangle

	//	establish our grid cell.
	P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
	vec2 Pi = floor( P + dot( P, vec2( SKEWFACTOR ) ) );

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	vec4 hash_x, hash_y;
	FAST32_hash_2D( Pi, hash_x, hash_y );
	//SGPP_hash_2D( Pi, hash_x, hash_y );

	//	establish vectors to the 3 corners of our simplex triangle
	vec2 v0 = Pi - dot( Pi, vec2( UNSKEWFACTOR ) ) - P;
	vec4 v1pos_v1hash = (v0.x < v0.y) ? vec4(SIMPLEX_POINTS.xy, hash_x.y, hash_y.y) : vec4(SIMPLEX_POINTS.yx, hash_x.z, hash_y.z);
	vec4 v12 = vec4( v1pos_v1hash.xy, SIMPLEX_POINTS.zz ) + v0.xyxy;

	//	calculate the dotproduct of our 3 corner vectors with 3 random normalized vectors
	vec3 grad_x = vec3( hash_x.x, v1pos_v1hash.z, hash_x.w ) - 0.49999;
	vec3 grad_y = vec3( hash_y.x, v1pos_v1hash.w, hash_y.w ) - 0.49999;
	vec3 norm = inversesqrt( grad_x * grad_x + grad_y * grad_y );
	grad_x *= norm;
	grad_y *= norm;
	vec3 grad_results = grad_x * vec3( v0.x, v12.xz ) + grad_y * vec3( v0.y, v12.yw );

	//	evaluate the surflet
	vec3 m = vec3( v0.x, v12.xz ) * vec3( v0.x, v12.xz ) + vec3( v0.y, v12.yw ) * vec3( v0.y, v12.yw );
	m = max(0.5 - m, 0.0);		//	The 0.5 here is SIMPLEX_TRI_HEIGHT^2
	vec3 m2 = m*m;
	vec3 m4 = m2*m2;

	//	calc the deriv
	vec3 temp = 8.0 * m2 * m * grad_results;
	float xderiv = dot( temp, vec3( v0.x, v12.xz ) ) - dot( m4, grad_x );
	float yderiv = dot( temp, vec3( v0.y, v12.yw ) ) - dot( m4, grad_y );

	const float FINAL_NORMALIZATION = 99.204334582718712976990005025589;	//	scales the final result to a strict 1.0->-1.0 range

	//	sum the surflets and return all results combined in a vec3
	return vec3( dot( m4, grad_results ), xderiv, yderiv ) * FINAL_NORMALIZATION;
}

void Simplex3D_GetCornerVectors( 	vec3 P,					//	input point
                                    out vec3 Pi,			//	integer grid index for the origin
                                    out vec3 Pi_1,			//	offsets for the 2nd and 3rd corners.  ( the 4th = Pi + 1.0 )
                                    out vec3 Pi_2,
                                    out vec4 v1234_x,		//	vectors from the 4 corners to the intput point
                                    out vec4 v1234_y,
                                    out vec4 v1234_z )
{
    //
    //	Simplex math from Stefan Gustavson's and Ian McEwan's work at...
    //	http://github.com/ashima/webgl-noise
    //

    //	simplex math constants
    const float SKEWFACTOR = 1.0/3.0;
    const float UNSKEWFACTOR = 1.0/6.0;
    const float SIMPLEX_CORNER_POS = 0.5;
    const float SIMPLEX_PYRAMID_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex pyramid.

    P *= SIMPLEX_PYRAMID_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )

    //	Find the vectors to the corners of our simplex pyramid
    Pi = floor( P + dot( P, vec3( SKEWFACTOR) ) );
    vec3 x0 = P - Pi + dot(Pi, vec3( UNSKEWFACTOR ) );
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    Pi_1 = min( g.xyz, l.zxy );
    Pi_2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - Pi_1 + UNSKEWFACTOR;
    vec3 x2 = x0 - Pi_2 + SKEWFACTOR;
    vec3 x3 = x0 - SIMPLEX_CORNER_POS;

    //	pack them into a parallel-friendly arrangement
    v1234_x = vec4( x0.x, x1.x, x2.x, x3.x );
    v1234_y = vec4( x0.y, x1.y, x2.y, x3.y );
    v1234_z = vec4( x0.z, x1.z, x2.z, x3.z );
}

//
//	Calculate the weights for the 3D simplex surflet
//
vec4 Simplex3D_GetSurfletWeights( 	vec4 v1234_x,
                                    vec4 v1234_y,
                                    vec4 v1234_z )
{
    //	perlins original implementation uses the surlet falloff formula of (0.6-x*x)^4.
    //	This is buggy as it can cause discontinuities along simplex faces.  (0.5-x*x)^3 solves this and gives an almost identical curve

    //	evaluate surflet. f(x)=(0.5-x*x)^3
    vec4 surflet_weights = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
    surflet_weights = max(0.5 - surflet_weights, 0.0);		//	0.5 here represents the closest distance (squared) of any simplex pyramid corner to any of its planes.  ie, SIMPLEX_PYRAMID_HEIGHT^2
    return surflet_weights*surflet_weights*surflet_weights;
}

void FAST32_hash_3D( 	vec3 gridcell,
                        vec3 v1_mask,		//	user definable v1 and v2.  ( 0's and 1's )
                        vec3 v2_mask,
                        out vec4 hash_0,
                        out vec4 hash_1,
                        out vec4 hash_2	)		//	generates 3 random numbers for each of the 4 3D cell corners.  cell corners:  v0=0,0,0  v3=1,1,1  the other two are user definable
{
    //    gridcell is assumed to be an integer coordinate

    //	TODO: 	these constants need tweaked to find the best possible noise.
    //			probably requires some kind of brute force computational searching or something....
    const vec2 OFFSET = vec2( 50.0, 161.0 );
    const float DOMAIN = 69.0;
    const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
    const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );

    //	truncate the domain
    gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * ( 1.0 / DOMAIN )) * DOMAIN;
    vec3 gridcell_inc1 = step( gridcell, vec3( DOMAIN - 1.5 ) ) * ( gridcell + 1.0 );

    //	compute x*x*y*y for the 4 corners
    vec4 P = vec4( gridcell.xy, gridcell_inc1.xy ) + OFFSET.xyxy;
    P *= P;
    vec4 V1xy_V2xy = mix( P.xyxy, P.zwzw, vec4( v1_mask.xy, v2_mask.xy ) );		//	apply mask for v1 and v2
    P = vec4( P.x, V1xy_V2xy.xz, P.z ) * vec4( P.y, V1xy_V2xy.yw, P.w );

    //	get the lowz and highz mods
    vec3 lowz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz ) );
    vec3 highz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz ) );

    //	apply mask for v1 and v2 mod values
    v1_mask = ( v1_mask.z < 0.5 ) ? lowz_mods : highz_mods;
    v2_mask = ( v2_mask.z < 0.5 ) ? lowz_mods : highz_mods;

    //	compute the final hash
    hash_0 = fract( P * vec4( lowz_mods.x, v1_mask.x, v2_mask.x, highz_mods.x ) );
    hash_1 = fract( P * vec4( lowz_mods.y, v1_mask.y, v2_mask.y, highz_mods.y ) );
    hash_2 = fract( P * vec4( lowz_mods.z, v1_mask.z, v2_mask.z, highz_mods.z ) );
}

//
//	SimplexPerlin3D  ( simplex gradient noise )
//	Perlin noise over a simplex (tetrahedron) grid
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2012/01/simplexperlinsample.jpg
//
//	Implementation originally based off Stefan Gustavson's and Ian McEwan's work at...
//	http://github.com/ashima/webgl-noise
//
float SimplexPerlin3D(vec3 P)
{
    //	calculate the simplex vector and index math
    vec3 Pi;
    vec3 Pi_1;
    vec3 Pi_2;
    vec4 v1234_x;
    vec4 v1234_y;
    vec4 v1234_z;
    Simplex3D_GetCornerVectors( P, Pi, Pi_1, Pi_2, v1234_x, v1234_y, v1234_z );

    //	generate the random vectors
    //	( various hashing methods listed in order of speed )
    vec4 hash_0;
    vec4 hash_1;
    vec4 hash_2;
    FAST32_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
    //SGPP_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
    hash_0 -= 0.49999;
    hash_1 -= 0.49999;
    hash_2 -= 0.49999;

    //	evaluate gradients
    vec4 grad_results = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 ) * ( hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z );

    //	Normalization factor to scale the final result to a strict 1.0->-1.0 range
    //	x = sqrt( 0.75 ) * 0.5
    //	NF = 1.0 / ( x * ( ( 0.5  x*x ) ^ 3 ) * 2.0 )
    //	http://briansharpe.wordpress.com/2012/01/13/simplex-noise/#comment-36
    const float FINAL_NORMALIZATION = 37.837227241611314102871574478976;

    //	sum with the surflet and return
    return dot( Simplex3D_GetSurfletWeights( v1234_x, v1234_y, v1234_z ), grad_results ) * FINAL_NORMALIZATION;
}

//
//	SimplexPerlin3D_Deriv
//	SimplexPerlin3D noise with derivatives
//	returns vec3( value, xderiv, yderiv, zderiv )
//
vec4 SimplexPerlin3D_Deriv(vec3 P)
{
    //	calculate the simplex vector and index math
    vec3 Pi;
    vec3 Pi_1;
    vec3 Pi_2;
    vec4 v1234_x;
    vec4 v1234_y;
    vec4 v1234_z;
    Simplex3D_GetCornerVectors( P, Pi, Pi_1, Pi_2, v1234_x, v1234_y, v1234_z );

    //	generate the random vectors
    //	( various hashing methods listed in order of speed )
    vec4 hash_0;
    vec4 hash_1;
    vec4 hash_2;
    FAST32_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
    //SGPP_hash_3D( Pi, Pi_1, Pi_2, hash_0, hash_1, hash_2 );
    hash_0 -= 0.49999;
    hash_1 -= 0.49999;
    hash_2 -= 0.49999;

    //	normalize random gradient vectors
    vec4 norm = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 );
    hash_0 *= norm;
    hash_1 *= norm;
    hash_2 *= norm;

    //	evaluate gradients
    vec4 grad_results = hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z;

    //	evaluate the surflet f(x)=(0.5-x*x)^3
    vec4 m = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
    m = max(0.5 - m, 0.0);		//	The 0.5 here is SIMPLEX_PYRAMID_HEIGHT^2
    vec4 m2 = m*m;
    vec4 m3 = m*m2;

    //	calc the deriv
    vec4 temp = -6.0 * m2 * grad_results;
    float xderiv = dot( temp, v1234_x ) + dot( m3, hash_0 );
    float yderiv = dot( temp, v1234_y ) + dot( m3, hash_1 );
    float zderiv = dot( temp, v1234_z ) + dot( m3, hash_2 );

    const float FINAL_NORMALIZATION = 37.837227241611314102871574478976;	//	scales the final result to a strict 1.0->-1.0 range

    //	sum with the surflet and return
    return vec4( dot( m3, grad_results ), xderiv, yderiv, zderiv ) * FINAL_NORMALIZATION;
}


// cellular noise, from here: https://github.com/BrianSharpe/GPU-Noise-Lib/blob/master/gpu_noise_lib.glsl

//	convert a 0.0->1.0 sample to a -1.0->1.0 sample weighted towards the extremes
vec4 Cellular_weight_samples( vec4 samples )
{
    samples = samples * 2.0 - 1.0;
    //return (1.0 - samples * samples) * sign(samples);	// square
    return (samples * samples * samples) - sign(samples);	// cubic (even more variance)
}

//
//	Cellular Noise 2D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//	http://briansharpe.files.wordpress.com/2011/12/cellularsample.jpg
//
//	Speed up by using 2x2 search window instead of 3x3
//	produces a range of 0.0->1.0
//
float Cellular2D(vec2 P)
{
    //	establish our grid cell and unit position
    vec2 Pi = floor(P);
    vec2 Pf = P - Pi;

    //	calculate the hash.
    //	( various hashing methods listed in order of speed )
    vec4 hash_x, hash_y;
    FAST32_hash_2D( Pi, hash_x, hash_y );
    //SGPP_hash_2D( Pi, hash_x, hash_y );

    //	generate the 4 random points
#if 1
    //	restrict the random point offset to eliminate artifacts
    //	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
    const float JITTER_WINDOW = 0.25;	// 0.25 will guarentee no artifacts.  0.25 is the intersection on x of graphs f(x)=( (0.5+(0.5-x))^2 + (0.5-x)^2 ) and f(x)=( (0.5+x)^2 + x^2 )
    hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
    hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
#else
    //	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
    //	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
    const float JITTER_WINDOW = 0.4;
    hash_x = hash_x * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
    hash_y = hash_y * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

    //	return the closest squared distance
    vec4 dx = Pf.xxxx - hash_x;
    vec4 dy = Pf.yyyy - hash_y;
    vec4 d = dx * dx + dy * dy;
    d.xy = min(d.xy, d.zw);
    return min(d.x, d.y) * ( 1.0 / 1.125 );	//	scale return value from 0.0->1.125 to 0.0->1.0  ( 0.75^2 * 2.0  == 1.125 )
}


//	Cellular2D_Deriv
//	Cellular 2D noise with derivatives
//	returns vec3( value, xderiv, yderiv )
//
vec3 Cellular2D_Deriv(vec2 P)
{
    //	establish our grid cell and unit position
    vec2 Pi = floor(P);
    vec2 Pf = P - Pi;

    //	calculate the hash.
    //	( various hashing methods listed in order of speed )
    vec4 hash_x, hash_y;
    FAST32_hash_2D( Pi, hash_x, hash_y );
    //SGPP_hash_2D( Pi, hash_x, hash_y );

    //	generate the 4 random points
    //	restrict the random point offset to eliminate artifacts
    //	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
    const float JITTER_WINDOW = 0.25;	// 0.25 will guarentee no artifacts.  0.25 is the intersection on x of graphs f(x)=( (0.5+(0.5-x))^2 + (0.5-x)^2 ) and f(x)=( (0.5+x)^2 + x^2 )
    hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
    hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);

    //	return the closest squared distance ( + derivs )
    //  thanks to Jonathan Dupuy for the initial implementation
    vec4 dx = Pf.xxxx - hash_x;
    vec4 dy = Pf.yyyy - hash_y;
    vec4 d = dx * dx + dy * dy;
    vec3 t1 = d.x < d.y ? vec3( d.x, dx.x, dy.x ) : vec3( d.y, dx.y, dy.y );
    vec3 t2 = d.z < d.w ? vec3( d.z, dx.z, dy.z ) : vec3( d.w, dx.w, dy.w );
    return ( t1.x < t2.x ? t1 : t2 ) * vec3( 1.0, 2.0, 2.0 ) * ( 1.0 / 1.125 ); //	scale return value from 0.0->1.125 to 0.0->1.0  ( 0.75^2 * 2.0  == 1.125 )
}

//
//	SimplexCellular2D
//	cellular noise over a simplex (triangular) grid
//	Return value range of 0.0->~1.0
//	http://briansharpe.files.wordpress.com/2012/01/simplexcellularsample.jpg
//
//	TODO:  scaling of return value to strict 0.0->1.0 range
//
float SimplexCellular2D( vec2 P )
{
    //	simplex math based off Stefan Gustavson's and Ian McEwan's work at...
    //	http://github.com/ashima/webgl-noise

    //	simplex math constants
    const float SKEWFACTOR = 0.36602540378443864676372317075294;			// 0.5*(sqrt(3.0)-1.0)
    const float UNSKEWFACTOR = 0.21132486540518711774542560974902;			// (3.0-sqrt(3.0))/6.0
    const float SIMPLEX_TRI_HEIGHT = 0.70710678118654752440084436210485;	// sqrt( 0.5 )	height of simplex triangle.
    const float INV_SIMPLEX_TRI_HEIGHT = 1.4142135623730950488016887242097;	//	1.0 / sqrt( 0.5 )
    const vec3 SIMPLEX_POINTS = vec3( 1.0-UNSKEWFACTOR, -UNSKEWFACTOR, 1.0-2.0*UNSKEWFACTOR ) * INV_SIMPLEX_TRI_HEIGHT;		//	vertex info for simplex triangle

    //	establish our grid cell.
    P *= SIMPLEX_TRI_HEIGHT;		// scale space so we can have an approx feature size of 1.0  ( optional )
    vec2 Pi = floor( P + dot( P, vec2( SKEWFACTOR ) ) );

    //	calculate the hash.
    //	( various hashing methods listed in order of speed )
    vec4 hash_x, hash_y;
    FAST32_hash_2D( Pi, hash_x, hash_y );
    //SGPP_hash_2D( Pi, hash_x, hash_y );

    //	push hash values to extremes of jitter window
    const float JITTER_WINDOW = ( 0.10566243270259355887271280487451 * INV_SIMPLEX_TRI_HEIGHT );		// this will guarentee no artifacts.
    hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW;
    hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW;

    //	calculate sq distance to closest point
    vec2 p0 = ( ( Pi - dot( Pi, vec2( UNSKEWFACTOR ) ) ) - P ) * INV_SIMPLEX_TRI_HEIGHT;
    hash_x += p0.xxxx;
    hash_y += p0.yyyy;
    hash_x.yzw += SIMPLEX_POINTS.xyz;
    hash_y.yzw += SIMPLEX_POINTS.yxz;
    vec4 distsq = hash_x*hash_x + hash_y*hash_y;
    vec2 tmp = min( distsq.xy, distsq.zw );
    return min( tmp.x, tmp.y );
}

// Gerstner waves from Belmu#4066
float gerstnerWaves(vec2 coords, float time, float waveSteepness, float waveAmplitude, float waveLength, vec2 waveDir) {
	float k = TAU / waveLength;
	float w = sqrt(9.81 * k); // 9.81 is the gravitational constant for Earth

	float x = w * time - k * dot(waveDir, coords);
	return waveAmplitude * pow(sin(x) * 0.5 + 0.5, waveSteepness);
}

vec3 gerstnerWaves_normal(vec2 coords, float time, float waveSteepness, float waveAmplitude, float waveLength, vec2 waveDir) {
	float k = TAU / waveLength;
	float c = sqrt(9.8 / k);

	float f = k * (dot(waveDir, coords) - c * time);
	float a = waveSteepness / k;

	// vec3 tangent = vec3(
	// 	1.0 - waveDir.x * waveDir.x * waveSteepness * sin(f),
	// 	waveDir.x * waveSteepness * cos(f),
	// 	-waveDir.x * waveDir.y * waveSteepness * sin(f)
	// );

	// vec3 binormal = vec3(
	// 	-waveDir.x * waveDir.y * waveSteepness * sin(f),
	// 	waveDir.y * waveSteepness * cos(f),
	// 	1.0 - waveDir.y * waveDir.y * waveSteepness * sin(f)
	// );

	return normalize(vec3(
		waveDir.x * a * cos(f),
		a * sin(f),
		waveDir.y * a * cos(f)
	));
}

#endif