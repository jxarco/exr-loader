/*
*   Alex Rodríguez
*   @jxarco 
*/

/*
    
*/
function drawGUI()
{
  var params_gui = {

        'Exposure': renderer._uniforms["u_exposure"],
        'Offset': renderer._uniforms["u_offset"],
        'GammaCorrection': true,

        'Show texture': "Write tex name",
        'Gen. CM size': EXRLoader.CUBE_MAP_SIZE,

        'Mesh': "Golden",
        'Scene': "1. Uffizzi",
        'Example Scene': "Select",

        'Reload shaders': function() {
          renderer.loadShaders("data/shaders.glsl");
          showMessage("Shaders reloaded");
        },
        'Sample brdf LUT': function() {
            renderer.textures["_brdf_integrator"] = "data/brdfLUT.png";
            sphere.textures['brdf'] = "data/brdfLUT.png";
        },
        'Created brdf LUT': function() {
            renderer.textures["_brdf_integrator"] = window.aux;
            sphere.textures['brdf'] = "_brdf_integrator";
        }
  };

  gui = new dat.GUI();
  
 
  var f1 = gui.addFolder("Example scenes (Bad hdr)");
  gui.scene_cm = f1.add( params_gui, 'Example Scene', ["Select", "1. TestUV", "2. Desert"]);
  var f3 = gui.addFolder("From sphere maps");
  gui.scene_sm = f3.add( params_gui, 'Scene', ["Select", "1. Uffizzi", "2. Foyer", "3. B. Hills"]);
  f3.add( params_gui, 'Gen. CM size', [64, 128, 256, 512, 1024] );
  var f4 = gui.addFolder("Rendered object");
  gui.mesh = f4.add( params_gui, 'Mesh', ["Golden", "Cerberus", "Primitive (Sphere)", "Matrix"] );
  var f5 = gui.addFolder("Render options");
  f5.add( params_gui, 'Reload shaders' );
  f5.add( params_gui, 'Sample brdf LUT' );
  f5.add( params_gui, 'Created brdf LUT' );
  f5.add( params_gui, 'GammaCorrection' );
  f5.add( params_gui, 'Exposure', -5, 5, 0.05 );
  f5.add( params_gui, 'Offset', -0.5, 0.5, 0.001 );
  gui.show_texture = f5.add( params_gui, 'Show texture');

  gui.open(); f1.open(); f3.open(); f4.open(); f5.open();
  
  return params_gui;
}

/*
    
*/
function createWidgetsDialog( id, options )
{   
    id = id || "EXR Loader"
    options = options || {};
    
    var dialog_id = id.replace(" ", "-").toLowerCase();
    // remove old dialogs
    if( document.getElementById( dialog_id ) )
        $("#"+dialog_id).remove();
        
    var w = 400;
    var dialog = new LiteGUI.Dialog( {id: dialog_id, parent: "body", title: id, close: true, width: w, scroll: true, draggable: true });
    dialog.show('fade');

    var widgets = new LiteGUI.Inspector();
    
    window._vars_dialog = {
        data: options.data,
        filename: options.filename,
        to_cubemap: false,
        show_texture: false,
        gen_cubemap_size: 512
    };

    widgets.on_refresh = function(){

        widgets.clear();

        widgets.addSection("Texture");
        widgets.addString( "File", options.filename );
        widgets.addCheckbox( "Convert to cube map", false,{name_width: "33.33%", callback: function(v) {      
            window._vars_dialog["to_cubemap"] = v;
        }});
        widgets.addCombo( "Generated CM size", "512",{values: ["64","128","256","512","1024"], name_width: "33.33%", callback: function(v) {      
            window._vars_dialog["gen_cubemap_size"] = parseInt(v);
        }});
        widgets.addSection("Scene");
        widgets.addCombo( "Configuration", null,{values: ["Environment map", "Show texture"], name_width: "33.33%", callback: function(v) {      
            
            window._vars_dialog["show_texture"] = (v === "Show texture") ? true : false;
        }});
        widgets.addSeparator();
        widgets.addButton( null, "Load", {width: "100%", name_width: "50%", callback: function(){
            $("#"+dialog_id).remove();
            showMessage("Processing scene...");
            // load( null, window._vars_dialog );
        }});
    }

    widgets.on_refresh();
    dialog.add(widgets);  
    dialog.setPosition( renderer.canvas.width-190*4, 200 );
}

/*
    
*/
function showMessage( text, duration )
{
  text = text || EXRLoader.STRINGS["Help"];
  duration = duration || 2000;

  var id = "msg-"+(push_msgs++);

    var msg = `
        <div id="`+id+`" style="padding: 20px; margin: 25px; height: 70px; background-color: rgba(255, 255, 255, 0.75);">
			<p style="color: dodgerblue; font-size: 20px; font-family: monospace;">
				` + text + `
			</p>
		</div>
    `;

  $("#push").prepend( msg );

  setTimeout(function(){
    $("#"+id).fadeOut();
  }, duration);
}

function showLoading()
{
  $("#modal").html(`
    <img src="data/loading.gif" style="border-radius: 10px; width: 20%; margin-top: 30vh; opacity: 0.85;">
    `);
  $("#modal").fadeIn();
}

function removeLoading()
{
  $("#modal").fadeOut();
};

var q = removeLoading;