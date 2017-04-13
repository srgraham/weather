

weather = require('../index')({use_cache: 'rain'})


weather.getForecastForLatLng 0,0,(err, data)->

  weather.drawRainForHour data.minutely.data, ()->
    console.log 9999, arguments