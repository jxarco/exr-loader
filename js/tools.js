/*
*   Alex Rodríguez
*   @jxarco 
*/

/*
    Precalculate first PBR sum for different roughness values 
*/
function PREFILTER_EM( file, options )
{
    var tex_name = getTexName( file );
    var tex = renderer.textures[tex_name];
    
    var f = function(tex)
    {
        var roughness_range = [0.2, 0.4, 0.6, 0.8, 1];

        // prefilter texture 5 times to get some blurred samples
        for( var i = 0; i < roughness_range.length; i++ )
        {
            // update roughness for prefilter sample
            let a = roughness_range[i];
            // prefilter
            var out = applyBlur( tex, null, {roughness: a} );
            // store
            var out_name = "_prem_"+i+"_" + tex_name;
            renderer.textures[ out_name ] = out;
        }

        if(options.callback)
            options.callback();
    }

    if(!tex)
    {
        console.warn("No texture. Loading file ["+file+"]");
        loadEXRTexture( file, options, f );        
    }
    else
        f( tex );
}

/*
    Environment BRDF (Store it in a 2D LUT)
*/
function Integrate_BRDF_EM( callback )
{
    var tex_name = '_brdf_integrator';
    var tex = renderer.textures[tex_name];
    
    if(!tex)
        tex = new GL.Texture(128,128, { texture_type: gl.TEXTURE_2D, minFilter: gl.NEAREST, magFilter: gl.LINEAR });

    var f = function()
    {
        tex.drawTo(function(texture, face) {
            renderer.shaders['brdfIntegrator'].uniforms({}).draw(Mesh.getScreenQuad(), gl.TRIANGLES);
            return;
        });
    
        renderer.textures[tex_name] = tex;
        window.aux = tex;

        // update node uniforms 
        sphere.textures['brdf'] = "_brdf_integrator";
        
        if(callback)
            callback();
    };
    
    if(!renderer.shaders['brdfIntegrator'])
        renderer.loadShaders("data/shaders.glsl", f);

    else
        f();
    
}

/*
    read exr file and run the EXRLoader
*/
function loadEXRTexture( file, options, callback)
{
    var tex_name = getTexName( file );

    var xhr = new XMLHttpRequest();
    xhr.open( "GET", file, true );
    xhr.responseType = "arraybuffer";

    var onread = function( buffer, options )
    {
        options = options || {};

        t1 = getTime();

        var texture = null;
        var texData = loader.parse(buffer),
            texParams = loader.getTextureParams(texData);

        if(options.to_texture2D)
            texParams.to_texture2D = true;
        texture = loader.generateTex(texParams, options.to_cubemap);

       if(options.to_texture2D)
            renderer.textures["_2D_"+tex_name] = texture;
        else
            renderer.textures[tex_name] = texture;
        
        t2 = getTime();
        t = Math.round(t2-t1);
        console.warn( "Texture [" + tex_name + "] parsed in: " + t + "ms" );

        if(callback)
            callback(texture);
    }

    xhr.onload = function( e ) {
        onread( this.response, options, callback );
    };

    xhr.send();
}

/*
    
*/
function applyBlur( tex, output, options )
{
  var size = tex.height || 512;
  options = options || {};

  var roughness = options.roughness || 0.0;

  //save state
  var current_fbo = gl.getParameter( gl.FRAMEBUFFER_BINDING );
  var viewport = gl.getViewport();

  var fb = gl.createFramebuffer();
  gl.bindFramebuffer( gl.FRAMEBUFFER, fb );
  gl.viewport(0,0, size, size);

  var shader = renderer.shaders["cubemapBlur"];
  tex.bind(0);
  var mesh = Mesh.getScreenQuad();
  mesh.bindBuffers( shader );
  shader.bind();

  //Texture.setUploadOptions( EXRLoader.cubemap_upload_options );

  var result = output;
  if(!output)
          result = new GL.Texture( size, size, { format: tex.format, texture_type: GL.TEXTURE_CUBE_MAP, type: gl.FLOAT } );

  var rot_matrix = GL.temp_mat3;
  var cams = GL.Texture.cubemap_camera_parameters;

  for(var i = 0; i < 6; i++)
  {
      gl.framebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, result.handler, 0);
      var face_info = cams[i];

      mat3.identity( rot_matrix );
      rot_matrix.set( face_info.right, 0 );
      rot_matrix.set( face_info.up, 3 );
      rot_matrix.set( face_info.dir, 6 );

      var uniforms = {
                      'u_rotation': rot_matrix,
                      'u_roughness': roughness
                  };

      shader.uniforms( uniforms );
      gl.drawArrays( gl.TRIANGLES, 0, 6 );
  }

  mesh.unbindBuffers( shader );

  //restore previous state
  gl.setViewport(viewport); //restore viewport
  gl.bindFramebuffer( gl.FRAMEBUFFER, current_fbo ); //restore fbo
  gl.bindTexture(result.texture_type, null); //disable

  return result;
}

/*
    
*/
function renderFPS()
{
    var now = getTime();
	var elapsed = now - window.last_time;

	window.frames++;

	if(elapsed > window.refresh_time)
	{
        window.last_fps = window.frames;
        $("#fps").html( "FPS: " + window.last_fps * (1000 / window.refresh_time) );
		window.frames = 0;
        window.last_time = now;
    }
}

/*
 Given an index and Nº of samples
 output: vec2 containing spherical coordinates of the sample
*/
function Fib( index, numSamples )
{
		 var d_phiAux = Math.PI * (3.0 - Math.sqrt(5.0));
		 var phiAux = 0.0;
		 var d_zAux = 1.0 / numSamples;
		 var zAux = 1.0 - (d_zAux / 2.0);
		 var thetaDir;
		 var phiDir;

		zAux -= d_zAux * index;
		phiAux += d_phiAux * index;
		thetaDir = Math.acos(zAux);
		phiDir = phiAux % (2.0 * Math.PI);

    return vec2.fromValues(thetaDir, phiDir);
}

/*
    Download texture
*/
function downloadTex( name )
{
    var tex = renderer.textures[name];
    if(!tex)
        return;
    
    var canvas = tex.toCanvas();
    var a = document.createElement("a");
    a.download = name + ".png";
    a.href = canvas.toDataURL();
    a.title = "Download file";
    a.appendChild(canvas);
    var new_window = window.open();
    new_window.document.title.innerHTML = "Download texture";
    new_window.document.body.appendChild(a);
    new_window.focus();
}

/*
    Remove path to get only file name
*/
function getTexName( file )
{
    var tokens = file.split("/");
    return tokens[ tokens.length-1 ];
}

function isPowerOfTwo(v)
{
	return ((Math.log(v) / Math.log(2)) % 1) == 0;
}