// Load the 2021 ULEZ boundary (replace with your actual asset path)
var zone_2021 = ee.FeatureCollection("projects/western-reason-478113-s5/assets/InnerUltraLowEmissionZone");

// Load the 2023 ULEZ boundary (replace with your actual asset path)
var zone_2023 = ee.FeatureCollection("projects/western-reason-478113-s5/assets/Ultra_Low_Emission_Zone_");
Map.addLayer(zone_2021, {color: 'blue'}, 'ULEZ 2021 Boundary');
Map.addLayer(zone_2023, {color: 'red'}, 'ULEZ 2023 Boundary');

// Load London boundary (replace with your actual asset path)
var london = ee.FeatureCollection("users/qianyeshi0506/London_gla");
Map.addLayer(london, {color: 'white'}, 'London Boundary');

var outer_london = ee.FeatureCollection([
  ee.Feature(london.geometry().difference(zone_2023.geometry(), 1))
]);


// The expanded portion is obtained (2023 boundary minus 2021 boundary).
var geom_2021 = zone_2021.geometry();
var geom_2023 = zone_2023.geometry();

var expansion_geom = geom_2023.difference(geom_2021, 1); 

var expansion_zone = ee.FeatureCollection([ee.Feature(expansion_geom)]);

// Show expansion area boundaries
//Map.addLayer(expansion_zone.style({color: 'purple', fillColor: '00000000'}), {}, 'ULEZ 2023 Expansion Only');

// Cropping NO2 to the expanded area
var no2 = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
    .select('tropospheric_NO2_column_number_density')
    .filterDate('2022-08-01', '2023-08-31')
    .mean();

var no2_expansion = no2.clip(expansion_zone);
Map.addLayer(no2_expansion, {
  min: 0,
  max: 0.0002,
  palette: ['black', 'blue', 'purple', 'cyan', 'green', 'yellow', 'red']
}, 'NO2 in 2023 Expansion Zone');

// Set map center point
Map.setCenter(-0.12, 51.51, 10);

// import site location
var rawData = ee.FeatureCollection("users/qianyeshi0506/Site_Location");
var pointsFC = rawData
  .filter(ee.Filter.notNull(['@Latitude', '@Longitude']))
  .filter(ee.Filter.neq('@Latitude', ''))
  .filter(ee.Filter.neq('@Longitude', ''))
  .map(function(feature) {
    var siteCode = feature.get('@SiteCode');
    var latitude = ee.Number.parse(feature.get('@Latitude'));
    var longitude = ee.Number.parse(feature.get('@Longitude'));
    var pointGeometry = ee.Geometry.Point([longitude, latitude]);
    return ee.Feature(pointGeometry, {
      'SiteCode': siteCode,
      'Latitude': latitude,
      'Longitude': longitude,
    });
  });
  
  var pointsInsideExpansion = pointsFC.filterBounds(expansion_geom);

Map.addLayer(pointsInsideExpansion, {color: 'green', pointRadius: 5, strokeWidth: 1}, 'Sites inside Expansion Zone');

// ========== Outer London（with 30 SiteCode) ==========
var outer_london_geom = outer_london.geometry();
var scale = 1000;
var maskImage = ee.Image.constant(1).toByte()
    .paint(outer_london_geom, 1)
    .rename('mask')
    .selfMask();
var rawPts = maskImage.sample({
  region: outer_london_geom,
  scale: scale,
  numPixels: 30,
  seed: 1234,
  geometries: true
});
var ptsList = rawPts.toList(rawPts.size());
var indices = ee.List.sequence(0, rawPts.size().subtract(1));
var ptsWithCode = ee.FeatureCollection(
  indices.map(function(index) {
    var feature = ee.Feature(ptsList.get(index));
    var lat = feature.geometry().coordinates().get(1);
    var lon = feature.geometry().coordinates().get(0);
    var siteCode = ee.String('random').cat(ee.Number(index).add(1).format());
    return feature.set({
      'SiteCode': siteCode,
      'Latitude': ee.Number(lat),
      'Longitude': ee.Number(lon)
    });
  })
);
Map.addLayer(ptsWithCode, {color: 'red'}, 'External random points (with SiteCode)');
