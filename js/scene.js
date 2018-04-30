/*
*   Alex Rodríguez
*   @jxarco 
*/

function parseScene()
{

}

function setScene( filename, to_cubemap )
{
    var tex_name = getTexName( filename );
    current_em = tex_name;

    var f = function()
    {
        // load all prefiltered EMS
        if(renderer.textures[current_em])
        {
            sphere.textures['env'] = current_em;
            sphere.textures['env_1'] = "_prem_0_" + current_em;
            sphere.textures['env_2'] = "_prem_1_" + current_em;
            sphere.textures['env_3'] = "_prem_2_" + current_em;
            sphere.textures['env_4'] = "_prem_3_" + current_em;
            sphere.textures['env_5'] = "_prem_4_" + current_em;
        }

        // config scene
        skybox.texture = current_em;
        skybox.flags.visible = true;
        drawSphereMatrix(current_em, params_gui["Mesh"] == "Matrix");

        setTimeout(function(){
            sphere.flags.visible = (params_gui["Mesh"] != "Matrix");
            $("#progress").css("width", "0%");
            removeLoading();
        }, 200);
    }

    // not prefiltered tex
    if(!renderer.textures[ "_prem_0_" + current_em ])
    {
        showMessage("Prefiltering", 3000);
        PREFILTER_EM( filename, {to_cubemap: to_cubemap, callback: f} );
    }
    else
        f();
    
}

function changeSceneMesh( name )
{
    showMessage("Changing mesh/es");
    // remove matrix
    removeByName( 'matrix_node' );
    
    if(name === "Matrix")
    {
        sphere.flags.visible = false;
        camera.lookAt( [0,10,25],[10,0,10],[0,1,0] );
        drawSphereMatrix( current_em );
        return;
    }
    if(name === "Primitive (Sphere)")
        return (sphere.mesh = "sphere");
    if(name === "Cerberus")
        camera.lookAt( [1,0.5,-1],[0,0,-0.5],[0,1,0] );
    else
    camera.lookAt( [0,0,5],[0,0,0],[0,1,0] );

    var name_lc = name.toLowerCase(),
        mesh = "assets/" + name_lc + "/" + name_lc + ".obj";

    // update node mesh
    sphere.mesh = mesh;
    
    // update node uniforms
    sphere.textures['roughness'] = "assets/"+ name_lc +"/roughness.png";
    sphere.textures['metalness'] = "assets/"+ name_lc +"/metalness.png";
    sphere.textures['albedo'] = "assets/"+ name_lc +"/albedo.png";
    sphere.textures['normal'] = "assets/"+ name_lc +"/normal.png";
    sphere.flags.visible = true;
}

function removeByName( name )
{
    for(var i = 0; i < scene.root.children.length; i++)
    {
        if(scene.root.children[i].name == name)
            scene.root.children[i].destroy();
    }
}

function drawSphereMatrix( em, visible )
{
    // remove previous
    removeByName( 'matrix_node' );
    var values = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
    for(var i =0; i < 10; i++)
    {
        for(var j = 0; j < 10; j++)
        {
            var mn = new RD.SceneNode();
            mn.mesh = "sphere";
            mn.name = "matrix_node";
            mn.position = [i*2,0,j*2];
            mn.flags.visible = visible;
            mn._uniforms["u_albedo"] = vec3.fromValues( 1.0, 1.0, 1.0);
            // mn._uniforms["u_albedo"] = vec3.fromValues( values[i], 0.0, values[j]);
            mn._uniforms["u_roughness"] = values[i];
            mn._uniforms["u_metalness"] = values[j];
            mn.textures['brdf'] = "_brdf_integrator";
            mn.textures['env'] = em;
            mn.textures['env_1'] = "_prem_0_"+em;
            mn.textures['env_2'] = "_prem_1_"+em;
            mn.textures['env_3'] = "_prem_2_"+em;
            mn.textures['env_4'] = "_prem_3_"+em;
            mn.textures['env_5'] = "_prem_4_"+em;
            mn.shader = "pbrMat";
            scene.root.addChild(mn);
        }
    }
}