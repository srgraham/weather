
_ = require 'lodash'

request = require 'request'

parseXmlString = require('xml2js').parseString

sharp = require 'sharp'


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

    bearing_index = (wind_bearing + 22.5 + 180) // 45 %% 360
    out = wind_directions[bearing_index]
    return out

  out_all.getEmojiForIcon = (icon)->
    emojis =
      'clear-day': '\u2600\ufe0f'
      'clear-night': '\ud83c\udf19'
      'rain': '\ud83c\udf27'
      'snow': '\u2744\ufe0f'
      'sleet': ''
      'wind': '\ud83d\udca8'
      'fog': '\ud83c\udf2b'
      'cloudy': '\u2601\ufe0f'
      'partly-cloudy-day': '\ud83c\udf24'
      'partly-cloudy-night': '\u2601\ufe0f'

    out = emojis[icon] ? ''
    return out

  out_all.drawRainForHour = (minutely_data, callback)->
    height = 160
    width = 320

    padding_bottom = 0
    padding_right = 0

    interval_line_height = 10

    graph_height = height - padding_bottom
    graph_width = width - padding_right

    max_precip_intensity = _.max _.map minutely_data, 'precipIntensity'

    precip_height = _.max [max_precip_intensity, .3]

    points = _.map minutely_data, (obj, index)->

      x = (graph_width / 60) * index
      y = (1 - (obj.precipIntensity / precip_height)) * graph_height
      out = [Math.round(x), Math.round(y)].join ','
      return out

    points.push [graph_width, graph_height]
    points.push [0, graph_height]

    lines_intervals = _.map [10, 20, 30, 40, 50], (val)->
      x = Math.round (graph_width / 60) * val
      y = graph_height

      out = """
        <path d="M #{x} #{y} L #{x} #{y - interval_line_height}" stroke="black" />
      """
      return out


    getDashedLine = (x1, y1, x2, y2)->
      out = """
        <path d="M #{x1} #{y1} L #{x2} #{y2}" stroke="rgba(0, 0, 0, 0.7)" stroke-dasharray="2,2" />
      """
      return out
      
    dotted_lines = _.map [0.1, 0.2], (val)->
      y = (1 - (val / precip_height)) * graph_height
      out = getDashedLine(0, y, graph_width, y)
      return out

    texts = _.map [10,30,50], (minute)->
      x = x = Math.round (graph_width / 60) * minute
      y = height
      out = """
        <text text-anchor="middle" x="#{x}" y="#{y - interval_line_height * 1.5}" style="font-family: Lato">#{minute}min</text>
      """
      return out

    svg = new Buffer """
      <svg width="#{width}" height="#{height}" viewPort="0 0 #{width} #{height}" xmlns="http://www.w3.org/2000/svg">
        <polygon fill="rgba(85, 136, 204, 0.7)" stroke-width="0" points="#{points.join(' ')}" />
        #{lines_intervals.join '\n'}
        #{dotted_lines.join '\n'}
        #{texts.join '\n'}
      </svg>
    """

    png_stream = sharp(svg).resize(width, height).png()
    callback null, png_stream
    return

  return out_all

