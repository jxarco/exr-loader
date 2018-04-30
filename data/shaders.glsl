\shaders

tex default.vs tex.fs
exposure default.vs exposure.fs
skybox default.vs skybox.fs
skyboxExpo default.vs skyboxExpo.fs
sphereMap default.vs sphereMap.fs

copy screen_shader.vs copy.fs
mirroredSphere default.vs mirroredSphere.fs

cubemapBlur cubemapBlur.vs cubemapBlur.fs
brdfIntegrator brdfIntegrator.vs brdfIntegrator.fs
pbr pbr.vs pbr.fs
pbrMat pbr.vs pbrMatrix.fs

//
// Default vertex shader for "almost" every fragment shader
//

\default.vs

	precision highp float;
    attribute vec3 a_vertex;
	attribute vec3 a_normal;
    attribute vec2 a_coord;
	varying vec3 v_wPosition;
	varying vec3 v_wNormal;
    varying vec2 v_coord;
    uniform mat4 u_mvp;
    uniform mat4 u_model;
    void main() {
		v_wPosition = (u_model * vec4(a_vertex, 1.0)).xyz;
		v_wNormal = (u_model * vec4(a_normal, 0.0)).xyz;
        v_coord = a_coord;
        gl_Position = u_mvp * vec4(a_vertex, 1.0);
    }

//
// Basic texture shader
//

\tex.fs
	precision highp float;
	varying vec3  v_wNormal;
	varying vec2  v_coord;
	uniform sampler2D u_color_texture;
	
	void main(){
		gl_FragColor = texture2D(u_color_texture, v_coord);
		// gl_FragColor = vec4(v_wNormal, 1.0);
	}

//
// Screen shader used in copyTo
//

\screen_shader.vs

	precision highp float;
	attribute vec3 a_vertex;
	attribute vec2 a_coord;
	varying vec2 v_coord;
	void main() {
		v_coord = a_coord;
		gl_Position = vec4(a_coord * 2.0 - 1.0, 0.0, 1.0);
	}


//
// Exposure shader used only in 2D textures
//

\exposure.fs

	precision highp float;
    varying vec2 v_coord;
    uniform vec4 u_color;
    uniform float u_exposure;
    uniform float u_brightMax;
    uniform sampler2D u_color_texture;
    void main() {
        vec4 color = texture2D(u_color_texture, v_coord);
        //float YD = u_exposure * (u_exposure / u_brightMax + 1.0) / (u_exposure + 1.0);
        color *= pow( 2.0, u_exposure );
        gl_FragColor = color;
    }

//
// Shader used to show skybox from cubemap
//

\skybox.fs

	precision highp float;
	varying vec3 v_wPosition;
	varying vec3 v_wNormal;
	varying vec2 v_coord;
	uniform vec4 u_color;
	uniform vec4 background_color;
	uniform vec3 u_camera_position;
	uniform samplerCube u_color_texture;
	void main() {
	    vec3 E = v_wPosition - u_camera_position;
	    E = normalize(E);
	    vec4 color = textureCube(u_color_texture, -E);
	    gl_FragColor = color;
	}

//
// Shader used to show skybox from cubemap (+ Exposure)
//

\skyboxExpo.fs

	precision highp float;
	varying vec3 v_wPosition;
	varying vec3 v_wNormal;
	varying vec2 v_coord;
	uniform float u_exposure;
	uniform float u_offset;
	uniform float u_brightMax;
    uniform bool u_gamma;
	uniform vec4 u_color;
	uniform vec4 background_color;
	uniform vec3 u_camera_position;
	uniform samplerCube u_color_texture;
	void main() {
	    vec3 E = v_wPosition - u_camera_position;
	    E = normalize(E);

	    vec4 color = textureCube(u_color_texture, -E);
        
        // gamma correction (linearization)
        if( u_gamma )
            color = pow(color, vec4(2.2));
        
		color *= pow(2.0, u_exposure);
		color += vec4(u_offset);
        
        // degamma (delinearization)
        if( u_gamma )
            color = pow(color, vec4(1.0/2.2));
        
	    gl_FragColor = color;
	}

//
// Shader used to convert spheremap to cubemap
//

\copy.fs

		precision highp float;
		varying vec2 v_coord;
		uniform float u_exposure;
		uniform float u_brightMax;
		uniform vec4 u_color;
		uniform vec4 background_color;
		uniform vec3 u_camera_position;
		uniform sampler2D u_color_texture;
		uniform mat3 u_rotation;

		vec2 getSphericalUVs(vec3 dir)
		{
			dir = normalize(dir);

            float d = sqrt(dir.x * dir.x + dir.y * dir.y);
			float r = 0.0;

			if(d > 0.0)
				r = 0.159154943 * acos(dir.z) / d;

	    	float u = 0.5 + dir.x * r;
			float v = 0.5 + dir.y * r;

			return vec2(u, v);
		}

		void main() {

			vec2 uv = vec2( v_coord.x, 1.0 - v_coord.y );
			vec3 dir = vec3( uv - vec2(0.5), 0.5 );
			dir = u_rotation * dir;

			// use dir to calculate spherical uvs
			vec2 spherical_uv = getSphericalUVs( dir );

			vec4 color = texture2D(u_color_texture, spherical_uv);
		    gl_FragColor = color;
		}

//
// Shader used to show skybox from sphere map (+ Exposure)
//

\sphereMap.fs

	precision highp float;
	varying vec3 v_wPosition;
	varying vec3 v_wNormal;
	varying vec2 v_coord;
	uniform float u_exposure;
	uniform float u_brightMax;
	uniform vec4 u_color;
	uniform vec4 background_color;
	uniform vec3 u_camera_position;
	uniform sampler2D u_color_texture;
	void main() {
	    vec3 E = v_wPosition - u_camera_position;
	    E = normalize(E);

	    E.x *= -1.0;
	    E.y *= -1.0;

	    float d = sqrt(E.x * E.x + E.y * E.y);
		float r = 0.0;

		if(d > 0.0)
			r = 0.159154943 * acos(E.z) / d;

	    float u = 0.5 + E.x * r;
		float v = 0.5 + E.y * r;

	    vec2 spherical_uv = vec2(u, v);
	    vec4 color = texture2D(u_color_texture, spherical_uv);

	    // apply exposure to sphere map
        //float YD = u_exposure * (u_exposure / u_brightMax + 1.0) / (u_exposure + 1.0);
        color *= pow( 2.0, u_exposure );

	    gl_FragColor = color;
	}

//
// Reflect environment to an sphere (+ Exposure)
//

\mirroredSphere.fs

		precision highp float;
		varying vec3 v_wPosition;
		varying vec3 v_wNormal;
		varying vec2 v_coord;
		uniform float u_exposure;
        uniform bool u_gamma;
		uniform float u_brightMax;
		uniform vec4 u_color;
		uniform vec4 background_color;
		uniform vec3 u_camera_position;
		uniform samplerCube u_color_texture;
		void main() {

		    vec3 E = v_wPosition - u_camera_position;
		    E = normalize(E);

			// r = 2n(n · v) − v
			vec3 n = normalize(v_wNormal);

			vec3 w0 = E;
			vec3 wr = 2.0 * dot(n, w0) * n;
			wr -= w0;
			wr = normalize(wr);

		    vec4 color = textureCube(u_color_texture, wr);
            
            // gamma correction
            if( u_gamma )
                color = pow(color, vec4(2.2));
            
	        //float YD = u_exposure * (u_exposure / u_brightMax + 1.0) / (u_exposure + 1.0);
	        color *= pow( 2.0, u_exposure );

            // gamma correction
            if( u_gamma )
                color = pow(color, vec4(1.0/2.2));
            
		    gl_FragColor = u_color * color;
		}

//
// Blur cubemap depending on the roughness
//

\cubemapBlur.vs

	precision highp float;
    attribute vec2 a_coord;

	varying vec3 v_dir;

	void main() {
		vec2 uv = vec2( a_coord.x, 1.0 - a_coord.y );
		v_dir = vec3( uv - vec2(0.5), 0.5 );
		gl_Position = vec4(vec3(a_coord * 2.0 - 1.0, 0.5), 1.0);
	}

\cubemapBlur.fs

	precision highp float;

	varying vec3 v_dir;

	uniform samplerCube u_color_texture;
	uniform mat3 u_rotation;
	uniform float u_roughness;

	#import "fibonacci.inc"
	#import "importanceSampleGGX.inc"
	#define SAMPLES 2048

	void main() {

		float roughness = u_roughness;

		float PI = 3.1415926535897932384626433832795;
		vec3 V = normalize(u_rotation * v_dir);
		vec3 N = V;

		vec4 prefiltered = vec4(0.0);
		float TotalWeight = 0.0;

		for(int i = 0; i < SAMPLES; i++) {

			// get spherical cx
			vec2 polar_i = Fib( i, SAMPLES );

			// get [0,1] sample (lambert)
			vec2 Xi = vec2(polar_i.y / (2.0 * PI), cos(polar_i.x));

			// get 3d vector
			vec3 H = (importanceSampleGGX(Xi, roughness, N));

			// its an hemisphere so only vecs with pos NdotH
			float NdotH = clamp( dot(H, N), 0.0, 1.0);

			// get pixel color from direction H and add it
			if(NdotH > 0.0) {
	            prefiltered += NdotH * textureCube(u_color_texture, H);
				TotalWeight += NdotH;
        	}
		}

		// promedio
		gl_FragColor = prefiltered / TotalWeight;
	}

//
// Get BRDF Texture (red/green)
//

\brdfIntegrator.vs

	precision highp float;

	attribute vec3 a_vertex;
	attribute vec3 a_normal;
	attribute vec2 a_coord;

	varying vec2 v_coord;
	varying vec3 v_vertex;

	void main(){
		v_vertex = a_vertex;
		v_coord  = a_coord;
		vec3 pos = v_vertex * 2.0 - vec3(1.0);
		gl_Position = vec4(pos, 1.0);
	}

\brdfIntegrator.fs

	precision highp float;

	varying vec2 v_coord;
	varying vec3 v_vertex;

	#import "fibonacci.inc"
	#import "importanceSampleGGX.inc"
	#import "ggx.inc"

	#define SAMPLES 1024

	void main() {

		float roughness = v_coord.y;
		float NdotV = v_coord.x;

		float PI = 3.1415926535897932384626433832795;
		vec3 V = vec3( sqrt(1.0 - NdotV * NdotV), 0.0, NdotV );
		vec3 N = vec3(0.0, 0.0, 1.0);

		float A = 0.0;
		float B = 0.0;

		for(int i = 0; i < SAMPLES; i++) {

			vec2 polar_i = Fib( i, SAMPLES );
			vec2 Xi = vec2(polar_i.y / (2.0 * PI), cos(polar_i.x));
			vec3 H = importanceSampleGGX(Xi, roughness, N);
			vec3 L = 2.0 * dot( V, H ) * H - V;

			float NdotL = clamp( L.z, 0.0, 1.0);
			float NdotH = clamp( H.z, 0.0, 1.0);
			float VdotH = clamp( dot(V, H), 0.0, 1.0);

			if(NdotL > 0.0) {
				float G = G_Smith( roughness, NdotV, NdotL );
	            float G_vis = G * VdotH / (NdotH * NdotV);
				float Fc = pow( 1.0 - VdotH, 5.0 );

				A += ( 1.0 - Fc ) * G_vis;
				B += ( Fc ) * G_vis;
        	}
		}

		vec2 result = vec2(A, B)/ float(SAMPLES);
		gl_FragColor = vec4(result, 0.0, 1.0);
	}

//
// PBR Illumination 
//

\pbr.vs

	precision highp float;
    attribute vec3 a_vertex;
	attribute vec3 a_normal;
    attribute vec2 a_coord;
	varying vec3 v_wPosition;
	varying vec3 v_wNormal;
    varying vec2 v_coord;
    uniform mat4 u_mvp;
    uniform mat4 u_model;
    void main() {
		v_wPosition = (u_model * vec4(a_vertex, 1.0)).xyz;
		v_wNormal = (u_model * vec4(a_normal, 0.0)).xyz;
        v_coord = a_coord;
        gl_Position = u_mvp * vec4(a_vertex, 1.0);
    }

\pbr.fs
    
    #extension GL_OES_standard_derivatives : enable
	precision highp float;

    varying vec3 v_wPosition;
    varying vec3 v_wNormal;
    varying vec2 v_coord;
    
    uniform float u_exposure;
	uniform float u_offset;
    uniform float u_brightMax;
    uniform bool u_gamma;
    uniform vec4 u_color;
    uniform vec4 background_color;
    uniform vec3 u_camera_position;

    uniform sampler2D u_brdf_texture;
    uniform samplerCube u_env_texture;
    uniform samplerCube u_env_1_texture;
    uniform samplerCube u_env_2_texture;
    uniform samplerCube u_env_3_texture;
    uniform samplerCube u_env_4_texture;
    uniform samplerCube u_env_5_texture;
    
    uniform sampler2D u_albedo_texture;
	uniform sampler2D u_normal_texture;
    uniform sampler2D u_roughness_texture;
    uniform sampler2D u_metalness_texture;

    uniform vec3 u_albedo;
    uniform float u_roughness;
    uniform float u_metalness;
    
	#import "bump.inc"
    
    struct Material{
        // vec3 emission;
        vec3 albedo;
        float roughness;
        float metalness;
        vec3 F0;
    };

	#define GAMMA 2.2
    #define SAMPLES 2048
	#define PI 3.1415926535897932384626433832795
    
    vec3 prem(vec3 R, float roughness) {
    
        float a = roughness * 5.0;

        if(a < 1.0) return mix(textureCube(u_env_texture, R).rgb, textureCube(u_env_1_texture, R).rgb, a);
        if(a < 2.0) return mix(textureCube(u_env_1_texture, R).rgb, textureCube(u_env_2_texture, R).rgb, a - 1.0);
        if(a < 3.0) return mix(textureCube(u_env_2_texture, R).rgb, textureCube(u_env_3_texture, R).rgb, a - 2.0);
        if(a < 4.0) return mix(textureCube(u_env_3_texture, R).rgb, textureCube(u_env_4_texture, R).rgb, a - 3.0);
        if(a < 5.0) return mix(textureCube(u_env_4_texture, R).rgb, textureCube(u_env_5_texture, R).rgb, a - 4.0);

        return textureCube(u_env_5_texture, R).xyz;
    }

    vec3 SPLIT_BRDF(vec3 R, vec3 N, vec3 V, vec2 BRDF, Material mat) {
    
        // Diffuse Term
        vec3 diffTerm = prem(-N, 1.0) / vec3(PI);
		if( u_gamma )
			diffTerm = pow( diffTerm, vec3(2.2));
		diffTerm *= mat.albedo;

        // Specular Term
        vec3 Li = prem(R, mat.roughness);
		if( u_gamma )
			Li = pow( Li, vec3(2.2));
        vec3 specTerm = Li * (mat.F0 * BRDF.x + BRDF.y);

        vec3 finalBRDF = diffTerm + specTerm;
        finalBRDF *= pow( 2.0, u_exposure );
        
        return finalBRDF;
    }

	void main() {

        // Init used variables

        vec3 V = v_wPosition - u_camera_position; // E in other shaders
	    V = normalize(V);

		// get texture normals
		vec3 normal_map = texture2D(u_normal_texture, v_coord).xyz;
        vec3 N = v_wNormal;
		N = normalize( perturbNormal( N, -V, v_coord, normal_map ) );

        // https://github.com/KhronosGroup/glTF-WebGL-PBR/blob/master/shaders/pbr-frag.glsl
		float NdotV = abs(dot(N, V)) + 0.001;
		vec3 R = reflect(-V, N);
        vec3 finalColor = vec3(0.0);
        
        // Get material
        
        vec3 albedo = u_albedo;
		albedo = texture2D(u_albedo_texture, v_coord).xyz;
        float roughness = u_roughness;
        roughness = texture2D(u_roughness_texture, v_coord).x;
        float metalness = u_metalness;
        metalness = texture2D(u_metalness_texture, v_coord).x;

        Material mat = Material( albedo, roughness, metalness, vec3(0.0) );
        
        // Get values from brdf texture
        
        vec2 brdf_coords = vec2(NdotV, mat.roughness);
        vec2 BRDF = texture2D(u_brdf_texture, brdf_coords).xy;
        
        // Avoid common errors
        
		if( u_gamma )
        	mat.albedo = pow(mat.albedo, vec3(2.2)); // Albedo has to be corrected with gamma (float or tex)
        mat.roughness = max(mat.roughness, 0.01);
        mat.metalness = min(mat.metalness, 0.99);
        
        // Table albedo/metalness properties
        
        mat.F0 = mix(vec3(0.04), mat.albedo, mat.metalness);
        mat.albedo = mix(mat.albedo, vec3(0.0), mat.metalness);
        
        // Calculate Point Light contribution
        // TODO

        // Calculate Environment Light Contribution
        finalColor = SPLIT_BRDF(R, N, V, BRDF, mat);
		finalColor += vec3(u_offset);

        // Apply gamma correction finally
		if( u_gamma )
        	finalColor = pow(finalColor, vec3(1.0/2.2));
        gl_FragColor = vec4( finalColor, 1.0);
	}

\pbrMatrix.fs
    
    #extension GL_OES_standard_derivatives : enable
	precision highp float;

    varying vec3 v_wPosition;
    varying vec3 v_wNormal;
    varying vec2 v_coord;
    
    uniform float u_exposure;
	uniform float u_offset;
    uniform float u_brightMax;
    uniform bool u_gamma;
    uniform vec4 u_color;
    uniform vec4 background_color;
    uniform vec3 u_camera_position;

    uniform sampler2D u_brdf_texture;
    uniform samplerCube u_env_texture;
    uniform samplerCube u_env_1_texture;
    uniform samplerCube u_env_2_texture;
    uniform samplerCube u_env_3_texture;
    uniform samplerCube u_env_4_texture;
    uniform samplerCube u_env_5_texture;

    uniform vec3 u_albedo;
    uniform float u_roughness;
    uniform float u_metalness;
    
    #import "fibonacci.inc"
	#import "importanceSampleGGX.inc"
	#import "ggx.inc"
	#import "bump.inc"
    
    struct Material{
        // vec3 emission;
        vec3 albedo;
        float roughness;
        float metalness;
        vec3 F0;
    };

	#define GAMMA 2.2
    #define SAMPLES 2048
	#define PI 3.1415926535897932384626433832795
    
    vec3 prem(vec3 R, float roughness) {
    
        float a = roughness * 5.0;

        if(a < 1.0) return mix(textureCube(u_env_texture, R).rgb, textureCube(u_env_1_texture, R).rgb, a);
        if(a < 2.0) return mix(textureCube(u_env_1_texture, R).rgb, textureCube(u_env_2_texture, R).rgb, a - 1.0);
        if(a < 3.0) return mix(textureCube(u_env_2_texture, R).rgb, textureCube(u_env_3_texture, R).rgb, a - 2.0);
        if(a < 4.0) return mix(textureCube(u_env_3_texture, R).rgb, textureCube(u_env_4_texture, R).rgb, a - 3.0);
        if(a < 5.0) return mix(textureCube(u_env_4_texture, R).rgb, textureCube(u_env_5_texture, R).rgb, a - 4.0);

        return textureCube(u_env_5_texture, R).xyz;
    }

    vec3 SPLIT_BRDF(vec3 R, vec3 N, vec3 V, vec2 BRDF, Material mat) {
    
        // Diffuse Term
        vec3 diffTerm = prem(-N, 1.0) / vec3(PI);
		if( u_gamma )
			diffTerm = pow( diffTerm, vec3(2.2));
		diffTerm *= mat.albedo;

        // Specular Term
        vec3 Li = prem(R, mat.roughness);
		if( u_gamma )
			Li = pow( Li, vec3(2.2));
        vec3 specTerm = Li * (mat.F0 * BRDF.x + BRDF.y);

        vec3 finalBRDF = diffTerm + specTerm;
        finalBRDF *= pow( 2.0, u_exposure );
        
        return finalBRDF;
    }

	void main() {

        // Init used variables

        vec3 V = v_wPosition - u_camera_position; // E in other shaders
	    V = normalize(V);

        vec3 N = v_wNormal;

        float NdotV = abs(dot(N, V)) + 0.001;//, 0.0, 1.0);
		vec3 R = reflect(-V, N);
        vec3 finalColor = vec3(0.0);
        
        // Get material
        Material mat = Material( u_albedo, u_roughness, u_metalness, vec3(0.0) );
        
        // Get values from brdf texture
        vec2 brdf_coords = vec2(NdotV, mat.roughness);
        vec2 BRDF = texture2D(u_brdf_texture, brdf_coords).xy;
        
        // Avoid common errors
        mat.roughness = max(mat.roughness, 0.01);
        mat.metalness = min(mat.metalness, 0.99);
        
        // Table albedo/metalness properties
        
        mat.F0 = mix(vec3(0.04), mat.albedo, mat.metalness);
        mat.albedo = mix(mat.albedo, vec3(0.0), mat.metalness);

        // Calculate Environment Light Contribution
        finalColor = SPLIT_BRDF(R, N, V, BRDF, mat);
		finalColor += vec3(u_offset);

        gl_FragColor = vec4( finalColor, 1.0);
	}


//
// Returns a sample based in fibonacci distribution
//

\fibonacci.inc

	// Given an index and Nº of samples
	// output: vec2 containing spherical coordinates of the sample
	vec2 Fib( const in int index, const in int numSamples ) {

		float PI = 3.1415926535897932384626433832795;

		float d_phiAux = PI * (3.0 - sqrt(5.0));
		float phiAux = 0.0;
		float d_zAux = 1.0 / float(numSamples);
		float zAux = 1.0 - (d_zAux / 2.0);
		float thetaDir;
		float phiDir;

		zAux -= d_zAux * float(index);
		phiAux += d_phiAux * float(index);

		thetaDir = acos(zAux);
		phiDir = mod(phiAux, (2.0 * PI));

		return vec2(thetaDir, phiDir);
	}

\importanceSampleGGX.inc

	// Given a sample in [0, 1] coordinates
	// output: vec3 containing 3d direction of the sample (??)
	vec3 importanceSampleGGX( vec2 Xi, float Roughness, vec3 N ) {

		float PI = 3.1415926535897932384626433832795;
	    float a = Roughness * Roughness;

	    float Phi = 2.0 * PI * Xi.x;

	    float CosTheta = sqrt( (1.0 - Xi.y) / ( 1.0 + (a * a - 1.0) * Xi.y ) );
	    float SinTheta = sqrt( 1.0 - CosTheta * CosTheta );

	    vec3 H;
	    H.x = SinTheta * cos( Phi );
	    H.y = SinTheta * sin( Phi );
	    H.z = CosTheta;

	    vec3 UpVector = abs(N.z) < 0.999999 ? vec3(0.0,0.0,1.0) : vec3(1.0,0.0,0.0);
	    vec3 TangentX = normalize( cross( UpVector, N ) );
	    vec3 TangentY = cross( N, TangentX );

	    // Tangent to world space
	    return normalize(TangentX * H.x + TangentY * H.y + N * H.z);
	}

\ggx.inc

	// ---------------------------------------------------------------
	// Geometry Term : Geometry masking / shadowing due to microfacets
	// ---------------------------------------------------------------
	float GGX(float NdotV, float k){
		return NdotV / (NdotV * (1.0 - k) + k);
	}
	float G_Smith(float roughness, float NdotV, float NdotL){
		float k = (roughness )*(roughness ) / 2.0;
		return GGX(NdotL, k) * GGX(NdotV, k);
	}

\bump.inc
	//Javi Agenjo Snipet for Bump Mapping
	mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv){
		// get edge vectors of the pixel triangle
		vec3 dp1 = dFdx( p );
		vec3 dp2 = dFdy( p );
		vec2 duv1 = dFdx( uv );
		vec2 duv2 = dFdy( uv );

		// solve the linear system
		vec3 dp2perp = cross( dp2, N );
		vec3 dp1perp = cross( N, dp1 );
		vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;

		// construct a scale-invariant frame
		float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
		return mat3( T * invmax, B * invmax, N );
	}

	vec3 perturbNormal( vec3 N, vec3 V, vec2 texcoord, vec3 normal_pixel ){
		#ifdef USE_POINTS
		return N;
		#endif

		// assume N, the interpolated vertex normal and
		// V, the view vector (vertex to eye)
		//vec3 normal_pixel = texture2D(normalmap, texcoord ).xyz;
		normal_pixel = normal_pixel * 255./127. - 128./127.;
		mat3 TBN = cotangent_frame(N, V, texcoord);
		return normalize(TBN * normal_pixel);
	}