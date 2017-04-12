
_ = require 'lodash'

request = require 'request'

parseXmlString = require('xml2js').parseString


module.exports = ({forecast_key, use_cache})->

  out_all = {}

  out_all.getRiverLocations = (lat, lng, {bounds_lat_delta=0.4144, bounds_lng_delta=1.4447}, callback)->

    lat0 = lat - bounds_lat_delta
    lat1 = lat + bounds_lat_delta
    lng0 = lng - bounds_lng_delta
    lng1 = lng + bounds_lng_delta

    url_river_locations = "https://www.weatherforyou.com/reports/getriverlocs.php?lat1=#{lat0}&lon1=#{lng0}&lat2=#{lat1}&lon2=#{lng1}"

    console.log "fetching #{url_river_locations}", 999

    request url_river_locations, (err, response, xml)->
      if err
        callback err
        return

      parseXmlString xml, (err, result)->
        if err
          callback err
          return

        out = _.map result.riverlocations.loc, '$'

        out = _.reject out, (obj)->
          if parseInt(obj.stageCode, 10) == -1
            return true
          if parseInt(obj.stage, 10) == -999
            return true
          return false

        callback null, out

  # alert when its about to rain
  out_all.getForecastForLatLng = (lat, lng, callback)->
    if use_cache
      if use_cache is 'rain'
        out = require('./rain_example.json')
      else
        out = require('./forecast_example.json')
      callback null, out
      return

    url = "https://api.darksky.net/forecast/#{forecast_key}/#{lat},#{lng}"

    request url, (err, response, json)->
      if err
        callback err
        return

      out = JSON.parse(json)
      callback null, out

    return

  out_all.getWindDirectionStr = (wind_bearing)->
    wind_directions = ['\u2191N', '\u2197NE', '\u2192E', '\u2198SE', '\u2193S', '\u2199SW', '\u2190W', '\u2196NW']

    bearing_index = (wind_bearing + 22.5) // 45
    out = wind_directions[bearing_index]
    return out

  out_all.getEmojiForIcon = (icon)->
    emojis =
      'clear-day': '\u2600'
      'clear-night': '\ud83c\udf19'
      'rain': '\ud83c\udf27'
      'snow': '\u2744'
      'sleet': 'sleet'
      'wind': '\ud83d\udca8'
      'fog': '\ud83c\udf2b'
      'cloudy': '\u2601'
      'partly-cloudy-day': '\ud83c\udf24'
      'partly-cloudy-night': 'night clouds'

    out = emojis[icon] ? ''
    return out


  return out_all