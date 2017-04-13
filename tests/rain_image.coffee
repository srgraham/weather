

weather = require('../index')({use_cache: 'rain'})


weather.getForecastForLatLng 0,0,(err, data)->

  weather.drawRainForHour data.minutely.data, (err, stream)->
    stream.toFile 'test.png', ->
    console.log 9999, arguments