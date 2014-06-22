var map;
var layer_mapnik;
var layer_tah;
var layer_markers;
var PI = Math.PI;
var latfield = '';
var lonfield = '';
var latfield_id='';
var lonfield_id='';
var centerlon = 10;
var centerlat = 52;
var zoom = 6;

function lon2merc(lon) {
    return 20037508.34 * lon / 180;
}

function lat2merc(lat) {
	lat = Math.log(Math.tan( (90 + lat) * PI / 360)) / PI;
	return 20037508.34 * lat;
}

function merc2lon(lon) {
	return lon*180/20037508.34;
};

function merc2lat(lat) {
	return Math.atan(Math.exp(lat*PI/20037508.34))*360/PI-90;
};

OpenLayers.Control.Click = OpenLayers.Class(OpenLayers.Control, {
	defaultHandlerOptions: {
		'single': true,
		'double': false,
		'pixelTolerance': 0,
		'stopSingle': false,
		'stopDouble': false
	},

	initialize: function(options) {
		this.handlerOptions = OpenLayers.Util.extend(
			{}, this.defaultHandlerOptions
		);
		OpenLayers.Control.prototype.initialize.apply(
			this, arguments
		);
			this.handler = new OpenLayers.Handler.Click(
				this, {
					'click': this.trigger
			}, this.handlerOptions
		);
	}, 

	trigger: function(e) {
    //if(document.body.style.cursor == 'default') 
    {
      var lonlat = map.getLonLatFromViewPortPx(e.xy);	
      lat=merc2lat(lonlat.lat);
      lon=merc2lon(lonlat.lon);
      if(parent.document.getElementById(latfield_id)==null){
        latfield=document.getElementById('osmlat');
      }else{
        latfield=parent.document.getElementById(latfield_id);
      }
      if(parent.document.getElementById(lonfield_id)==null){
        lonfield=document.getElementById('osmlon');
      }else{
        lonfield=parent.document.getElementById(lonfield_id);
      }
      latfield.value = lat;
      lonfield.value = lon;		
      drawmarker(lonlat.lon,lonlat.lat);		
		}
		//layer_markers.map = map;
    //layer_markers.moveTo(lonlat)	;
		layer_markers.redraw()
		//map.setCenter(new OpenLayers.LonLat(map.getCenter().lat, map.getCenter().lon), zoom);		
		//map.setCenter(new OpenLayers.LonLat(map.getCenter().lat, map.getCenter().lon), zoom);		
		//map.render();	
	}
});

function init(){			
	var field = window.name.substring(0, window.name.lastIndexOf("."));
	if(parent.document.getElementById(field+".latfield")!=null){
		latfield_id = parent.document.getElementById(field+".latfield").value;	
		document.getElementById('osm').style.display="none";
	}
	if(parent.document.getElementById(field+".lonfield")!=null){
		lonfield_id = parent.document.getElementById(field+".lonfield").value;
	}
	if(parent.document.getElementById(field+".centerlat")!=null){
		centerlat =parseFloat(parent.document.getElementById(field+".centerlat").value);
	}
	if(parent.document.getElementById(field+".centerlon")!=null){
		centerlon = parseFloat(parent.document.getElementById(field+".centerlon").value);
	}
	if(parent.document.getElementById(field+".zoom")!=null){
		zoom = parseFloat(parent.document.getElementById(field+".zoom").value);
	}
}

function drawmap() {
	OpenLayers.Lang.setCode('de'); 
	mapdiv=document.getElementById('map');
	mapdiv.style.height=( window.innerHeight ? window.innerHeight : document.documentElement.clientHeight )+"px";
	mapdiv.style.width=( window.innerWidth? window.innerWidth: document.documentElement.clientWidth )+"px";
	map = new OpenLayers.Map('map', {
		projection: new OpenLayers.Projection("EPSG:900913"),
		displayProjection: new OpenLayers.Projection("EPSG:4326"),
		controls: [
			new OpenLayers.Control.Navigation(),
			new OpenLayers.Control.PanZoomBar()],
		maxExtent:
			new OpenLayers.Bounds(-20037508.34,-20037508.34, 20037508.34, 20037508.34),
		numZoomLevels: 18,
		maxResolution: 156543,
		minResolution: 1,
		units: 'meters'
	});

	layer_mapnik = new OpenLayers.Layer.OSM.Mapnik("Mapnik");

	map.addLayers([layer_mapnik]);
	var y =lat2merc(centerlat);
	var x =lon2merc(centerlon);
	map.setCenter(new OpenLayers.LonLat(x, y), zoom);
	
	// Check for geolocation support if default
	if((centerlat=52 && centerlat==10) && navigator.geolocation){
		navigator.geolocation.getCurrentPosition(function(position){
			var y =lat2merc(position.coords.latitude);
			var x =lon2merc(position.coords.longitude);

      drawmarker(x,y);
			map.setCenter(new OpenLayers.LonLat(x, y), '17');
		});
	}
  drawmarker(x,y);
	var click = new OpenLayers.Control.Click();
	map.addControl(click);
	click.activate();
}

function drawmarker(x,y) {
  var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
  var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection	
  var position       = new OpenLayers.LonLat(x, y); //.transform( fromProjection, toProjection);
  if(layer_markers) layer_markers.clearMarkers();
  layer_markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(layer_markers);
  layer_markers.addMarker(new OpenLayers.Marker(position));
}