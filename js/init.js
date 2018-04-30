/*
*   Alex Rodríguez
*   @jxarco 
*/

var LOAD_STEPS = 0;
var STEPS = 5;

var $temp = {
    vec2 : vec2.create(),
    vec3 : vec3.create(),
    vec4 : vec4.create(),
    mat3 : mat3.create(),
    mat4 : mat4.create()
}

var loader = new EXRLoader();

var push_msgs = 0;

// save all buffer files to avoid reading twice
var tmp = {};
var _dt = 0.0;
var showingTex = false;

var t1, t2, t;
var current_em = "";

function init()
{
    showLoading();
    var last = now = getTime();

    scene = new RD.Scene();

    var context = GL.create({width: window.innerWidth, height: window.innerHeight});

    renderer = new RD.Renderer(context, {
        shaders_file: "data/shaders.glsl",
        autoload_assets: true
    });
    
    rt = renderer.textures; 

    renderer.canvas.addEventListener("webglcontextlost", function(event) {
        event.preventDefault();
        console.warn('Context lost');
    }, false);

    document.body.appendChild(renderer.canvas); //attach

    document.body.ondragover = function(){ return false;}
    document.body.ondragend = function(){ return false;}
    document.body.ondrop = function( e )
    {
        e.preventDefault();
        
        var file = e.dataTransfer.files[0],
            name = file.name;

        var reader = new FileReader();
        reader.onload = function (event) {
            var data = event.target.result;
            var options = {
                filename: name,
                data: data
            }
            createWidgetsDialog( null, options );
        };

        reader.readAsArrayBuffer(file);
        return false;
    }

    camera = new RD.Camera();
    camera.perspective( 45, gl.canvas.width / gl.canvas.height, 0.01, 1000000 );
    camera.lookAt( [0,0,5],[0,0,0],[0,1,0] );

    // parseScene( scene );

    skybox = new RD.SceneNode();
    skybox.mesh = "cube";
    skybox.shader = "skyboxExpo";
    skybox.flags.depth_test = false;
    skybox.flags.flip_normals = true;
    skybox.flags.visible = false;
    skybox.render_priority = RD.PRIORITY_BACKGROUND;
    scene.root.addChild( skybox );

    sphere = new RD.SceneNode();
    sphere.position = [0,0,0];
    sphere.mesh = "assets/golden/golden.obj";
    sphere.shader = "pbr";
    sphere.flags.visible = false;
    scene.root.addChild(sphere);

    // update node uniforms
    sphere.textures['roughness'] = "assets/golden/roughness.png";
    sphere.textures['metalness'] = "assets/golden/metalness.png";
    sphere.textures['normal'] = "assets/golden/normal.png";
    sphere.textures['albedo'] = "assets/golden/albedo.png";

    // declare renderer uniforms
    renderer._uniforms["u_exposure"] = 0.0;
    renderer._uniforms["u_offset"] = 0.0;
    renderer._uniforms["u_brightMax"] = 18.0;
    
    // uniforms for material in case of no texture
    renderer._uniforms["u_albedo"] = vec3.fromValues(1.0, 0.0, 0.0);
    renderer._uniforms["u_roughness"] = 0.0;
    renderer._uniforms["u_metalness"] = 1.0;

    // draw all gui and return params to fill
    params_gui = drawGUI();

    var bg_color = vec4.fromValues(0.2,0.3,0.4,1);
    var amb = null;

    // Render FPS
    window.refresh_time = 250;
	window.last_fps = 0;
    window.last_time = 0;
    window.frames = 0;

    renderer.context.ondraw = function()
    {
        renderFPS();
        last = now;
        now = getTime();
        renderer.clear(bg_color);
        skybox.position = camera.position;
        renderer.render(scene, camera);

        if(showingTex && rt[params_gui['Show texture']])
            rt[params_gui['Show texture']].toViewport();
    }

    renderer.context.onupdate = function(dt)
    {
        _dt = dt;
        scene.update(dt);

        // Set scene params to params in GUI
        updateSceneFromGUI();
    }

    renderer.context.animate();

    // Update Bindings
    updateKeyBindings( renderer.context );
    updateGUIBindings();

    /*
        Precalculate stuff
    */
    
    Integrate_BRDF_EM(); // Environment BRDF (LUT)

    /*
        Load textures used
    */
    
    loadEXRTexture( "../textures/cubemap.exr", null, isReady);
    loadEXRTexture( "../textures/TEST_UV.exr", null, isReady);
    loadEXRTexture( "../textures/uffizi_probe.exr", { to_cubemap: true }, isReady);
    loadEXRTexture( "../textures/beverlyHills.exr", { to_cubemap: true }, isReady);
    loadEXRTexture( "../textures/mausoleumFoyer.exr", { to_cubemap: true }, isReady);
}

function isReady()
{
    LOAD_STEPS++;
    $("#progress").css("width", ((LOAD_STEPS/STEPS)*100 + "%") );

    if(LOAD_STEPS === STEPS)
        setScene( "../textures/uffizi_probe.exr", true );
}