/*
var collection = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
  .select('tropospheric_NO2_column_number_density')
  .filterDate('2019-06-01', '2019-06-06');//Choose a range of date

//define the color of layers
var band_viz = {
  min: 0,
  max: 0.0002,
  palette: ['black', 'blue', 'purple', 'cyan', 'green', 'yellow', 'red']
};

//Create new layer：calculate the average during the range of date from 2019-06-01 to 2019-06-06
Map.addLayer(collection.mean(), band_viz, 'S5P N02');

//define the center point and scale
Map.setCenter(65.27, 24.11, 4);


var collection = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')

//select this band
  .select('tropospheric_NO2_column_number_density')
  .filterDate('2019-06-01', '2019-06-06');

var band_viz = {
  min: 0,
  max: 0.0002,
  palette: ['black', 'blue', 'purple', 'cyan', 'green', 'yellow', 'red']
};

Map.addLayer(collection.mean(), band_viz, 'S5P N02');
Map.setCenter(-0.12, 51.51, 10);
*/


// Load the 2021 ULEZ boundary (replace with your actual asset path)
var zone_2021 = ee.FeatureCollection("projects/western-reason-478113-s5/assets/InnerUltraLowEmissionZone");

// Load the 2023 ULEZ boundary (replace with your actual asset path)
var zone_2023 = ee.FeatureCollection("projects/western-reason-478113-s5/assets/Ultra_Low_Emission_Zone_");
Map.addLayer(zone_2021, {color: 'blue'}, 'ULEZ 2021 Boundary');
Map.addLayer(zone_2023, {color: 'red'}, 'ULEZ 2023 Boundary');

// Load London boundary (replace with your actual asset path)
var london = ee.FeatureCollection("users/qianyeshi0506/gla");
Map.addLayer(london, {color: 'white'}, 'London Boundary');


// The expanded portion is obtained (2023 boundary minus 2021 boundary).
var geom_2021 = zone_2021.geometry();
var geom_2023 = zone_2023.geometry();

var expansion_geom = geom_2023.difference(geom_2021, 1); // 1为缓冲距离，防止缝隙问题

var expansion_zone = ee.FeatureCollection([ee.Feature(expansion_geom)]);

// Show expansion area boundaries
//Map.addLayer(expansion_zone.style({color: 'purple', fillColor: '00000000'}), {}, 'ULEZ 2023 Expansion Only');

// Cropping NO2 to the expanded area
var no2 = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
    .select('tropospheric_NO2_column_number_density')
    .filterDate('2023-08-01', '2023-08-31')
    .mean();

var no2_expansion = no2.clip(expansion_zone);
Map.addLayer(no2_expansion, {
  min: 0,
  max: 0.0002,
  palette: ['black', 'blue', 'purple', 'cyan', 'green', 'yellow', 'red']
}, 'NO2 in 2023 Expansion Zone');

// Set map center point
Map.setCenter(-0.12, 51.51, 10);

var start_pre = '2022-08-29';
var end_pre = '2023-08-28';
var start_post = '2023-08-29';
var end_post = '2024-08-28';

var no2 = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
  .select('tropospheric_NO2_column_number_density');



// Get all days within a specified time period
var days_pre = ee.List.sequence(0, ee.Date(end_pre).difference(ee.Date(start_pre), 'day').subtract(1));
var days_post = ee.List.sequence(0, ee.Date(end_post).difference(ee.Date(start_post), 'day').subtract(1));

// Encapsulate the daily average function
var getDailyMean = function(startDate, days) {
  return days.map(function(d) {
    var date = ee.Date(startDate).advance(d, 'day');
    var img = no2.filterDate(date, date.advance(1, 'day')).mean();
    var mean = img.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: expansion_zone.geometry(),
      scale: 1000,
      maxPixels: 1e9
    });
    return ee.Feature(null, {
      'date': date.format('YYYY-MM-dd'),
      'NO2': mean.get('tropospheric_NO2_column_number_density')
    });
  });
};

var features_pre = ee.FeatureCollection(getDailyMean(start_pre, days_pre));
var features_post = ee.FeatureCollection(getDailyMean(start_post, days_post));
var all_features = features_pre.merge(features_post);

//CSV file
Export.table.toDrive({
  collection: all_features,
  description: 'ULEZ_Expansion_NO2_DailyMeans_2022-2024',
  fileFormat: 'CSV'
});




// Calculate the outer perimeter (excluding the ULEZ area): London boundary minus ULEZ boundary
var outside_geom = london.geometry().difference(zone_2023.geometry(), 1); // 1为缓冲距离，防止缝隙问题

var outer_london = ee.FeatureCollection([ee.Feature(outside_geom)]);
Map.addLayer(outer_london, {color: 'green'}, 'Outer London Control Area');

var no2 = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
    .select('tropospheric_NO2_column_number_density')
    .filterDate('2022-08-29', '2024-08-28'); // Same dates as treatment

// Example: grid-based daily average in control area, analogous to treatment code
var days_all = ee.List.sequence(0, ee.Date('2024-08-28').difference(ee.Date('2022-08-29'), 'day').subtract(1));

// Encapsulated function for daily mean
var getDailyMean = function(startDate, days, zone) {
  return days.map(function(d) {
    var date = ee.Date(startDate).advance(d, 'day');
    var img = no2.filterDate(date, date.advance(1, 'day')).mean();
    var mean = img.reduceRegion({
      reducer: ee.Reducer.mean(),
      geometry: zone.geometry(),
      scale: 1000,
      maxPixels: 1e9
    });
    return ee.Feature(null, {
      'date': date.format('YYYY-MM-dd'),
      'NO2': mean.get('tropospheric_NO2_column_number_density')
    });
  });
};

// Get daily means for control area
var outer_london = ee.FeatureCollection(getDailyMean('2022-08-29', days_all, outer_london));

// Export to CSV
Export.table.toDrive({
  collection: outer_london,
  description: 'OuterLondon_Control_NO2_DailyMeans_2022-2024',
  fileFormat: 'CSV'
});
