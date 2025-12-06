//================= Region Definition and Processing ======================
//Import boundaries
var innerULEZ = ee.FeatureCollection("projects/animated-tracer-478120-q3/assets/InnerUltraLowEmissionZone");
var ulez2023 = ee.FeatureCollection("projects/animated-tracer-478120-q3/assets/Ultra_Low_Emission_Zone");
var london = ee.FeatureCollection("projects/animated-tracer-478120-q3/assets/gla");

// Calculate the Extended Borough and Outer London
var expansion_zone = ee.FeatureCollection([
  ee.Feature(ulez2023.geometry().difference(innerULEZ.geometry(), 1))
]);
var outer_london = ee.FeatureCollection([
  ee.Feature(london.geometry().difference(ulez2023.geometry(), 1))
]);

// import site location
var rawData = ee.FeatureCollection("projects/animated-tracer-478120-q3/assets/convertcsv");
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
Map.addLayer(pointsFC, {color: '#FF6B6B', pointRadius: 5, strokeWidth: 1}, '内部点');

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
Map.addLayer(ptsWithCode, {color: 'red'}, '外部随机点（带SiteCode）');

// ================== Set time window ==================
var startDate = '2022-08-29';
var endDate = '2024-08-28';
var days = ee.List.sequence(
  0, 
  ee.Date(endDate).difference(ee.Date(startDate), 'day').subtract(1)
);

// ============ Load NO2、Cloud and ERA5-Land ===========
// precipitation is "total_precipitation_sum"var no2Collection = ee.ImageCollection('COPERNICUS/S5P/OFFL/L3_NO2')
  .select(['tropospheric_NO2_column_number_density', 'cloud_fraction']);
var era5Collection = ee.ImageCollection('ECMWF/ERA5_LAND/DAILY_AGGR')
  .select([
    'temperature_2m', 
    'u_component_of_wind_10m',
    'v_component_of_wind_10m',
    'surface_pressure',
    'dewpoint_temperature_2m',
    'total_precipitation_sum', 
    //'monin_obukhov_length'
  ]);

// ==========Extract all indicators daily ==========
var extractBandValues = function(date) {
  var currentDate = ee.Date(startDate).advance(date, 'day');
  var nextDate = currentDate.advance(1, 'day');
  
  // NO2 and cloud_fraction
  var no2Image = no2Collection
    .filterDate(currentDate, nextDate)
    .mean()
    .rename(['NO2', 'CloudFraction']);

  // ERA5-Land
  var era5Day = era5Collection
    .filterDate(currentDate, nextDate)
    .mean()
    .rename([
      'Temperature', 'u_wind', 'v_wind', 'Pressure',
      'Dewpoint', 'Precipitation', //'MoninObukhov'
    ]);
  
  // Windspeed
  var windSpeed = era5Day.select('u_wind').pow(2)
    .add(era5Day.select('v_wind').pow(2))
    .sqrt()
    .rename('WindSpeed');
  // Winddir°)
  var windDirRad = era5Day.select('u_wind')
    .atan2(era5Day.select('v_wind')).add(Math.PI)
    .multiply(180/Math.PI);
  var windDirection = windDirRad.rename('WindDirection');
  // humidity
  var tempC   = era5Day.select('Temperature').subtract(273.15);
  var dewC    = era5Day.select('Dewpoint').subtract(273.15);
  var rh = dewC.expression(
    '100*exp((a*dew)/(b+dew)-(a*temp)/(b+temp))',
    {
      'dew': dewC,
      'temp': tempC,
      'a': 17.625,
      'b': 243.04
    }
  ).rename('RH');
  
  // ========================merge all bands=====================
  var combinedImage = no2Image
    .addBands(era5Day)
    .addBands(windSpeed)
    .addBands(windDirection)
    .addBands(rh);
  
  var extractPoints = function(points) {
    return combinedImage.reduceRegions({
      collection: points,
      reducer: ee.Reducer.first(),
      scale: 1000,
      tileScale: 4
    }).map(function(feature) {
      return feature.set({
        'Date': currentDate.format('yyyy-MM-dd'),
        'Region': points === pointsFC ? 'Inner' : 'Outer'
      });
    });
  };
  var innerPointsData = extractPoints(pointsFC);
  var outerPointsData = extractPoints(ptsWithCode);
  return innerPointsData.merge(outerPointsData);
};

var allData = ee.FeatureCollection(
  days.map(extractBandValues)
).flatten();

// =========== Export table to Drive ===============
Export.table.toDrive({
  collection: allData,
  description: 'NO2_Meteo_ALL_Data_2022-2024',
  folder: 'GEE_Exports',
  fileFormat: 'CSV',
  selectors: [
    'SiteCode', 'Latitude', 'Longitude', 'Date', 'Region',
    'NO2', 'CloudFraction',
    'Temperature', 'u_wind', 'v_wind', 'WindSpeed', 'WindDirection',
    'Pressure', 'RH', 'Precipitation', //'MoninObukhov'
  ]
});

Map.addLayer(allData, {color: 'blue'}, 'All points daily attributes');
