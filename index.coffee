api = require './lib/api'



lat = 35.79000241666874
lng = -78.782958984375

#api.getRiverLocations lat, lng, {}, (err, result)->
api.getForecastForLatLng lat, lng, (err, result)->
  if err
    console.error err
    process.exit 1

  console.log 111, JSON.stringify result
  process.exit 0


