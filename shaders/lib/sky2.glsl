#ifndef SKY
#define SKY

// #include "/defines.glsl"

#define AS_MAIN_SAMPLES 16 //Scattering steps
#define AS_LIGHT_SAMPLES 8 //Transmittance steps
#define AS_RENDER_SCALE 0.649 //Resolution multiplier

const vec3 hemisphereDirs[16] = vec3[](
   vec3( 0     ,    1.0000,    0),
   vec3(-0.2606,    0.9355,    0.2387),
   vec3( 0.0430,    0.8710,   -0.4895),
   vec3( 0.3598,    0.8065,    0.4693),
   vec3(-0.6602,    0.7419,   -0.1168),
   vec3( 0.6207,    0.6774,   -0.3948),
   vec3(-0.2051,    0.6129,    0.7631),
   vec3(-0.3854,    0.5484,   -0.7421),
   vec3( 0.8220,    0.4839,    0.3002),
   vec3(-0.8391,    0.4194,    0.3464),
   vec3( 0.3963,    0.3548,   -0.8468),
   vec3( 0.2864,    0.2903,    0.9131),
   vec3(-0.8429,    0.2258,   -0.4885),
   vec3( 0.9639,    0.1613,   -0.2119),
   vec3(-0.5724,    0.0968,    0.8142),
   vec3(-0.1284,    0.0323,   -0.9912)
);

/*
    Projection functions
    Thx Belmu/Kneemund
*/
vec2 projectSphere(in vec3 direction) {
    float longitude = atan(-direction.x, -direction.z);
    float latitude  = acos(direction.y);

    return vec2(longitude * (1.0 / TAU) + 0.5, latitude / PI);
}

vec3 unprojectSphere(in vec2 coord) {
    float longitude = coord.x * TAU;
    float latitude  = coord.y * PI;
    return vec3(vec2(sin(longitude), cos(longitude)) * sin(latitude), cos(latitude)).xzy;
}

vec3 skyLightSample(sampler2D skySampler) {
    vec3 skyColor = vec3(0.0);

	for(int i = 0; i < 16; i++) {
        skyColor += texture2D(skySampler, projectSphere(hemisphereDirs[i]) * AS_RENDER_SCALE).rgb;
    }

    // return skyColor * (sunAngle == shadowAngle ? 0.1 : 3.0);
    return 0.25 * skyColor /* * mix(3.0, 0.1, smoothstep(0.0, 0.1, sunHeight)) */;
    // return skyColor / mix(1.2, 10.0, smoothstep(-0.1, 0.1, sunAngle));
}

// vec3 sunLightSample(sampler2D skySampler, vec3 sunLightDir) {
//     float maxAngle = acos(0.9985);
//     vec2 angles = vec2(atan(sunLightDir.y / sunLightDir.x), sign(sunLightDir.x) * acos(sunLightDir.z));
//     int samples = 32;

//     vec3 skyColor = vec3(0.0);
// 	for(int i = 0; i < samples; i++) {
//         vec2 sampleAngles = angles + maxAngle * GetVogelDiskSample(i, samples, 0.0);
//         vec3 sampleDir = vec3(sin(sampleAngles.y) * cos(sampleAngles.x), sin(sampleAngles.y) * sin(sampleAngles.x), cos(sampleAngles.y));

//         skyColor += smoothstep(-0.034, 0.05, sampleDir.y) * texture2D(skySampler, projectSphere(sampleDir) * AS_RENDER_SCALE).rgb;
//     }

//     return skyColor / samples * mix(vec3(40.0, 22.0, 16.0), vec3(0.5), rainStrength);
    
//     // mix(1.0, 25.0, smoothstep(-0.030, -0.022, eyeDir.y) * smoothstep(0.9985, 0.9995, dot(normalize(viewPos), sunDirView)));
// }

vec3 sunLightSample(float sunHeight, float shadowHeight, float rainStrength, int moonPhase) {

    vec3 color;

    if(sunHeight == shadowHeight) {
        color = mix(5.0 * vec3(1.0, 0.45, 0.2), 5.0 * vec3(1.0, 0.89, 0.8), smoothstep(0.0, 0.4, shadowHeight)) * smoothstep(0.0, 0.2, shadowHeight);
        color *= mix(1.0, 0.1, rainStrength);
    }
    else {
        color = vec3(0.1, 0.2, 0.4) * (cos(0.25 * PI * moonPhase) * 0.25 + 0.75) * smoothstep(0.0, 0.3, shadowHeight);
        color *= mix(1.0, 0.3, rainStrength);
    }

    return color;

    // // return 8.0 * vec3(1.0, 0.89, 0.8);
    // // return vec3(0.0);

    // vec3 skyColor = texture2D(skySampler, projectSphere(sunLightDir) * AS_RENDER_SCALE).rgb;

    // // vec3 colorMult = (shadowAngle == sunAngle) ? vec3(40.0, 22.0, 16.0) : vec3(30.0, 28.0, 23.0);
    // vec3 colorMult = mix(vec3(30.0, 28.0, 23.0), vec3(40.0, 22.0, 16.0), smoothstep(0.0, 0.1, 0.0));

    // if(sunHeight != shadowHeight) {
    //     colorMult *= cos(0.25 * PI * moonPhase) * 0.4 + 0.6;
    // }

    // // return skyColor * mix(vec3(40.0, 22.0, 16.0), vec3(0.5), rainStrength) * smoothstep(0.0, 0.2, shadowAngle);
    // return skyColor * colorMult * smoothstep(0.0, 0.2, shadowHeight) * mix(1.0, 0.25, rainStrength);
}

/*
    Struct with data used in atmosphere scattering function
*/
struct as_data {
	float rPlanet; //Planet radius
    float rAtmos; //Atmosphere radius

	vec3 kRlh; //Rayleigh coefficient
    float shRlh; //Rayleigh scattering height
    
    vec3 kMie; //Mie coefficients
    float aMie; //Mie albedo
    float shMie; //Mie scattering height
    float gMie; //Mie anisotropy
    
	vec3 kOzo; //Ozone extinction coefficient

    mat2x3 kScattering; //Scattering coeff matrix
    mat3x3 kExtinction; //Extinction coeff matrix

    float iSun; //Sun illuminance
    float iMoon; //Moon illuminance
};

/*
    Rayleigh phase
*/
float phase_rayleigh(float VL) {
    return 3.0 * (1.0 + VL * VL) / (16.0 * PI);
}

/*
    Cornette-Shank Mie phase
    Thanks Jessie!
*/
float phase_cs_mie(float VL, float g_coeff) {
	float g_coeff_sqr = g_coeff * g_coeff;
	float p1 = 3.0 * (1.0 - g_coeff_sqr) * (1.0 / (PI * (2.0 + g_coeff_sqr)));
	float p2 = (1.0 + (VL * VL)) * (1.0/pow((1.0 + g_coeff_sqr - 2.0 * g_coeff * VL), 1.5));
    
	float phase = (p1 * p2);
	phase *= 1.0 / (PI * 9.0);
    
	return max(phase, 0.0);
}

/*
    Returns density of mie/rlh/ozo
*/
vec3 get_densities(float height, as_data atmosphere) {
    //Rayleigh density
    float densityRlh = exp(-height / atmosphere.shRlh);
    
    //Mie density
    float densityMie = 0.0;
    // if(rainStrength == 0.0)
        densityMie = exp(-height / atmosphere.shMie);
    // else
    //     densityMie = exp(-height / atmosphere.shMie) * mix(1.0, mix(80.0, 1.0, smoothstep(0.0, 7000.0, height)), rainStrength);
    
    //Ozone density
    float densityOzo = exp(-max(0.0, (35e3 - height) - atmosphere.rAtmos) / 5e3) * exp(-max(0.0, (height - 35e3) - atmosphere.rAtmos) / 15e3); 
    
    //Output
    return vec3(densityRlh, densityMie, densityOzo);
}

/*
    Ray sphere intersection function
*/
vec2 ray_sphere_intersection(vec3 position, vec3 direction, float radius) {
	float b = dot(position, direction);
	float c = dot(position, position) - radius * radius;
	
	float d = b * b - c;
    
	if (d < 0.0)
		return vec2(-1.0);

	d = sqrt(d);
	
	return vec2(-b - d, -b + d);
}



vec3 calculate_light_transmittance(vec3 position, vec3 light_direction, as_data atmosphere) {
    // Calculate the step size of the secondary (light) ray.
    float step_size = ray_sphere_intersection(position, light_direction, atmosphere.rAtmos).y / float(AS_LIGHT_SAMPLES);

    // Ray increment
    vec3 ray_increment = light_direction * step_size;

    // Initial ray position (we start from the centre)
    vec3 ray_position = position + ray_increment * 0.5;

    // Initialize transmittance accumulators for the secondary (light) ray.
    vec3 total_transmittance = vec3(1.0);
    
    // Sample the secondary ray.
    for (int i = 0; i < AS_LIGHT_SAMPLES; i++) 
    {
        // Calculate the height of the sample.
        float height = length(ray_position) - atmosphere.rPlanet;

        // Get densities.
        vec3 step_density = get_densities(height, atmosphere);
        
        // Get air mass
        vec3 step_air_mass = step_density * step_size;
        
        // Get optical depth
        vec3 step_optical_depth = atmosphere.kExtinction * step_air_mass;
        
        // Get transmittance
        vec3 step_transmittance = exp(-step_optical_depth);
        
        // Accumulate samples
        total_transmittance *= step_transmittance;

        // Increment the secondary ray time.
        ray_position += ray_increment;
    }
    return total_transmittance;
}

/*
    Atmospheric scattering function.
    Look into "Common" tab for more info.
*/
vec3 atmospheric_scattering(vec3 ray_origin, vec3 ray_direction, vec3 sun_direction, vec3 moon_direction, as_data atmosphere) {
    //Intersection
    vec2 atmosphereDists = ray_sphere_intersection(ray_origin, ray_direction, atmosphere.rAtmos);
    vec2 planetDists = ray_sphere_intersection(ray_origin, ray_direction, atmosphere.rPlanet-20.0); //Check that later

    //Logic
    bool planetIntersected = planetDists.y >= 0.0;
    bool atmosphereIntersected = atmosphereDists.y >= 0.0;
    vec2 sd = vec2((planetIntersected && planetDists.x < 0.0) ? planetDists.y : max(atmosphereDists.x, 0.0), (planetIntersected && planetDists.x > 0.0) ? planetDists.x : atmosphereDists.y);

    //Calculate step size
    float step_size = length(sd.y - sd.x) / float(AS_MAIN_SAMPLES);

    // Ray increment
    vec3 ray_increment = ray_direction * step_size;

    // Initial ray position
    vec3 ray_position = ray_direction * sd.x + (ray_increment * 0.5 + ray_origin);

    // Initialize accumulators for scattering and transmittance.
    vec3 total_scattering_sun = vec3(0.0);
    vec3 total_scattering_moon = vec3(0.0);
    vec3 total_transmittance = vec3(1.0);

    // Calculate the Rayleigh and Mie phases for day and night time
    float VL_sun = dot(ray_direction, sun_direction);
    float VL_moon = dot(ray_direction, moon_direction);    
    vec4 phases = vec4(phase_rayleigh(VL_sun), phase_cs_mie(VL_sun, atmosphere.gMie), phase_rayleigh(VL_moon), phase_cs_mie(VL_moon, atmosphere.gMie));
    
    // Sample the primary (view) ray.
    for (int i = 0; i < AS_MAIN_SAMPLES; i++) 
	{
        // Calculate the height of the sample.
        float height = length(ray_position) - atmosphere.rPlanet;

        // Get densities
        vec3 step_density = get_densities(height, atmosphere);
        
        // Get air mass
        vec3 step_air_mass = step_density * step_size;
        
        // Get optical depth
        vec3 step_optical_depth = atmosphere.kExtinction * step_air_mass;
        
        // Get transmittance
        vec3 step_transmittance = exp(-step_optical_depth);

 //Sun contribution
        // Calculate single scattering contribution
        vec3 scattering_sun = atmosphere.kScattering * (phases.xy * step_air_mass.xy) * calculate_light_transmittance(ray_position, sun_direction, atmosphere);

        // Calculate scattering integral (Frostbite)
        vec3 scattering_integral_sun = (scattering_sun - scattering_sun * step_transmittance) / max(vec3(1e-8), step_optical_depth);

 //Moon contribution
        // Calculate single scattering contribution
        vec3 scattering_moon = atmosphere.kScattering * (phases.zw * step_air_mass.xy) * calculate_light_transmittance(ray_position, moon_direction, atmosphere);

        // Calculate scattering integral (Frostbite)
        vec3 scattering_integral_moon = (scattering_moon - scattering_moon * step_transmittance) / max(vec3(1e-8), step_optical_depth);

        // Accumulate samples
        total_scattering_sun += scattering_integral_sun * total_transmittance; //Sun scattering
        total_scattering_moon += scattering_integral_moon * total_transmittance; //Moon scattering        
        total_transmittance *= step_transmittance; //Transmittance

        // Increment the primary ray time.
        ray_position += ray_increment;
    }

    // Add stuff together
    return (atmosphere.iSun * total_scattering_sun) + (atmosphere.iMoon * total_scattering_moon);
}

/*
    Atmospheric scattering function.
    Look into "Common" tab for more info.
*/
vec3 atmospheric_scattering_single(vec3 ray_origin, vec3 ray_direction, vec3 sun_direction, as_data atmosphere) {
    //Intersection
    vec2 atmosphereDists = ray_sphere_intersection(ray_origin, ray_direction, atmosphere.rAtmos);
    vec2 planetDists = ray_sphere_intersection(ray_origin, ray_direction, atmosphere.rPlanet-20.0); //Check that later

    //Logic
    bool planetIntersected = planetDists.y >= 0.0;
    bool atmosphereIntersected = atmosphereDists.y >= 0.0;
    vec2 sd = vec2((planetIntersected && planetDists.x < 0.0) ? planetDists.y : max(atmosphereDists.x, 0.0), (planetIntersected && planetDists.x > 0.0) ? planetDists.x : atmosphereDists.y);

    //Calculate step size
    float step_size = length(sd.y - sd.x) / float(AS_MAIN_SAMPLES);

    // Ray increment
    vec3 ray_increment = ray_direction * step_size;

    // Initial ray position
    vec3 ray_position = ray_direction * sd.x + (ray_increment * 0.5 + ray_origin);

    // Initialize accumulators for scattering and transmittance.
    vec3 total_scattering_sun = vec3(0.0);
    vec3 total_transmittance = vec3(1.0);

    // Calculate the Rayleigh and Mie phases for day and night time
    float VL_sun = dot(ray_direction, sun_direction);  
    vec2 phases = vec2(phase_rayleigh(VL_sun), phase_cs_mie(VL_sun, atmosphere.gMie));
    
    // Sample the primary (view) ray.
    for (int i = 0; i < AS_MAIN_SAMPLES; i++) 
	{
        // Calculate the height of the sample.
        float height = length(ray_position) - atmosphere.rPlanet;

        // Get densities
        vec3 step_density = get_densities(height, atmosphere);
        
        // Get air mass
        vec3 step_air_mass = step_density * step_size;
        
        // Get optical depth
        vec3 step_optical_depth = atmosphere.kExtinction * step_air_mass;
        
        // Get transmittance
        vec3 step_transmittance = exp(-step_optical_depth);

 //Sun contribution
        // Calculate single scattering contribution
        vec3 scattering_sun = atmosphere.kScattering * (phases.xy * step_air_mass.xy) * calculate_light_transmittance(ray_position, sun_direction, atmosphere);

        // Calculate scattering integral (Frostbite)
        vec3 scattering_integral_sun = (scattering_sun - scattering_sun * step_transmittance) / max(vec3(1e-8), step_optical_depth);

        // Accumulate samples
        total_scattering_sun += scattering_integral_sun * total_transmittance; //Sun scattering
        total_transmittance *= step_transmittance; //Transmittance

        // Increment the primary ray time.
        ray_position += ray_increment;
    }

    // Add stuff together
    return (atmosphere.iSun * total_scattering_sun);
}

/*
    You can make different function like this one
    for example a new one to simulate Mars atmosphere
*/
vec3 get_sky_color(vec3 ray_origin, vec3 ray_direction, vec3 sun_direction, vec3 moon_direction, float rainStrength, int moonPhase) {
    //Initialize data struct
    as_data atmosphere;
    
    //Planet
    atmosphere.rPlanet = 6370e3; //Planet radius
    atmosphere.rAtmos = 6471e3; //Atmosphere radius

    //Rayleigh
    atmosphere.kRlh = vec3(5.8e-6, 13.3e-6, 33.31e-6); //Rayleigh coefficient
    atmosphere.shRlh = 8e3; //Rayleigh height
    
    //Mie
    atmosphere.kMie = vec3(21e-6); //Mie coefficient
    atmosphere.aMie = 0.9; //0.9; //Mie albedo
    atmosphere.shMie = 1.9e3; //Mie height
    atmosphere.gMie = 0.8; //Mie anisotropy term
    
    //Ozone
    atmosphere.kOzo = vec3(3.426e-7, 8.298e-7, 0.356e-7); //Ozone absorption coefficient
    
    //Scattering matrix
    atmosphere.kScattering = mat2x3(atmosphere.kRlh, atmosphere.kMie);
    
    //Extinction matrix
    atmosphere.kExtinction[0] = atmosphere.kRlh; //Rayleigh
    atmosphere.kExtinction[1] = atmosphere.kMie / atmosphere.aMie; //Mie
    atmosphere.kExtinction[2] = atmosphere.kOzo; //Ozone
        

    //Sun intensity
    atmosphere.iSun = 10.5 * mix(1.0, 0.3, rainStrength);
   
    //Moon intensity
    atmosphere.iMoon = 0.5 * (cos(0.25 * PI * moonPhase) * 0.25 + 0.75);
       
    //Output
	return atmospheric_scattering(ray_origin, ray_direction, sun_direction, moon_direction, atmosphere);
}

vec3 get_sky_color_end(vec3 ray_origin, vec3 ray_direction, vec3 light_direction) {
    //Initialize data struct
    as_data atmosphere;
    
    //Planet
    atmosphere.rPlanet = 6370e3; //Planet radius
    atmosphere.rAtmos = 6471e3; //Atmosphere radius

    //Rayleigh
    atmosphere.kRlh = vec3(8.0e-6, 3.0e-6, 20.0e-6); //Rayleigh coefficient
    atmosphere.shRlh = 32e3; //Rayleigh height
    
    //Mie
    atmosphere.kMie = vec3(21e-6, 30e-6, 10e-6); //Mie coefficient
    atmosphere.aMie = 0.4; //Mie albedo
    atmosphere.shMie = 10.0e3; //Mie height
    atmosphere.gMie = 0.4; //Mie anisotropy term
    
    //Ozone
    atmosphere.kOzo = vec3(0.0); //Ozone absorption coefficient
    
    //Scattering matrix
    atmosphere.kScattering = mat2x3(atmosphere.kRlh, atmosphere.kMie);
    
    //Extinction matrix
    atmosphere.kExtinction[0] = atmosphere.kRlh; //Rayleigh
    atmosphere.kExtinction[1] = atmosphere.kMie / atmosphere.aMie; //Mie
    atmosphere.kExtinction[2] = atmosphere.kOzo; //Ozone
        

    //Sun intensity
    atmosphere.iSun = 1.5;
   
    //Moon intensity
    atmosphere.iMoon = 0.0;
       
    //Output
	return atmospheric_scattering_single(ray_origin, ray_direction, light_direction, atmosphere);
}

vec3 get_sky_color_nether(vec3 ray_origin, vec3 ray_direction, vec3 light_direction){
    //Initialize data struct
    as_data atmosphere;
    
    //Planet
    atmosphere.rPlanet = 6370e3; //Planet radius
    atmosphere.rAtmos = 6471e3; //Atmosphere radius

    //Rayleigh
    atmosphere.kRlh = vec3(50e-6, 2e-6, 1e-6); //Rayleigh coefficient
    atmosphere.shRlh = 16e3; //Rayleigh height
    
    //Mie
    atmosphere.kMie = vec3(5e-6, 40e-6, 45e-6); //Mie coefficient
    atmosphere.aMie = 0.7; //Mie albedo
    atmosphere.shMie = 5e4; //Mie height
    atmosphere.gMie = 0.2; //Mie anisotropy term
    
    //Ozone
    atmosphere.kOzo = vec3(0.0); //Ozone absorption coefficient
    
    //Scattering matrix
    atmosphere.kScattering = mat2x3(atmosphere.kRlh, atmosphere.kMie);
    
    //Extinction matrix
    atmosphere.kExtinction[0] = atmosphere.kRlh; //Rayleigh
    atmosphere.kExtinction[1] = atmosphere.kMie / atmosphere.aMie; //Mie
    atmosphere.kExtinction[2] = atmosphere.kOzo; //Ozone
        

    //Sun intensity
    atmosphere.iSun = 5;
   
    //Moon intensity
    atmosphere.iMoon = 0.0;
       
    //Output
	return atmospheric_scattering_single(ray_origin, ray_direction, light_direction, atmosphere);
}

#endif