/*
*   Alex Rodríguez
*   @jxarco 
*/

/*
    Update bindings for GUI actions
*/
function updateKeyBindings(ctx)
{
  ctx.captureKeys(true);
  ctx.onkeydown = function(e)
  {
    if(e.keyCode === 82)
    {
      renderer.loadShaders("data/shaders.glsl", function(){
        showMessage("Shaders reloaded");
      }); 
    }
    if(e.keyCode === 27)
    {
        sphere.flags.visible = true;
        skybox.flags.visible = true;
        camera.lookAt( [0,0,5],[0,0,0],[0,1,0] );
    }
  }
  ctx.captureMouse(true);
  ctx.onmousemove = function(e)
  {
    var mouse = [e.canvasx, gl.canvas.height - e.canvasy];
    if (e.dragging && e.leftButton) {
        camera.orbit(-e.deltax * _dt * 0.1, RD.UP,  camera._target);
        camera.orbit(-e.deltay * _dt * 0.1, camera._right, camera._target );
    }
    if (e.dragging && e.rightButton) {
        camera.moveLocal([-e.deltax * 0.1 * _dt, e.deltay * 0.1 * _dt, 0]);
    }
  }
  ctx.onmousewheel = function(e)
  {
      if(!e.wheel)
        return;

      vec3.copy($temp.vec3, camera._target);
      var d = vec3.distance( camera._target, camera.position);
      camera.moveLocal( [0,0,  e.wheel < 0 ? _dt * 3.5 : -_dt * 3.5]);
      vec3.copy( camera._target, $temp.vec3);
  }
}

/*
    Update bindings for GUI actions
*/
function updateGUIBindings()
{
    gui.mesh.onChange(function(){
        changeSceneMesh( params_gui['Mesh'] );
    });

    gui.scene_sm.onChange(function() {
 
        showMessage("Loading scene");
        var index = parseInt( params_gui['Scene'][0] );

       switch( index )
       {
        case 1:
            setScene( "../textures/uffizi_probe.exr", true );
            break;
        case 2:
            setScene( "../textures/mausoleumFoyer.exr", true );
            break;
        case 3:
            setScene( "../textures/beverlyHills.exr", true );
            break;
       }
    });

    gui.scene_cm.onChange(function() {
 
        showMessage("Loading scene");
        var index = parseInt( params_gui['Example Scene'][0] );

       switch( index )
       {
        case 1:
            setScene( "../textures/TEST_UV.exr" );
            break;
        case 2:
            setScene( "../textures/cubemap.exr" );
            break;
       }
    });

    gui.show_texture.onFinishChange(function(){
        
        showingTex = (params_gui['Show texture'] === '') ? false:true;
    })
}

/*
    Update scene taking params stored in the GUI
*/
function updateSceneFromGUI()
{
    renderer._uniforms["u_exposure"] = params_gui['Exposure'];
    renderer._uniforms["u_offset"] = params_gui['Offset'];
    renderer._uniforms["u_gamma"] = params_gui['GammaCorrection'];
    EXRLoader.CUBE_MAP_SIZE = params_gui['Gen. CM size'];
}