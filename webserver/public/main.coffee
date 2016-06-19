# Create the chart
chart = new Highcharts.Chart(
	chart:
		renderTo: 'gyroscope'
		defaultSeriesType: 'spline'
		animation: false
		zoomType: 'x'
	title:
		text: ''
		style:
			display: 'none'
	xAxis:
		type: 'datetime'
		tickPixelInterval: 10
	yAxis:
		minPadding: 0.2
		maxPadding: 0.2
		maxZoom: 4
	plotOptions:
		series:
			animation: false
	series: [
		{
			name: 'pitch'
			color: 'red'
			data: []
		}
		{
			name: 'yaw'
			color: 'green'
			data: []
		}
		{
			name: 'roll'
			color: 'blue'
			data: []
		}
	]
)

pubnub = PUBNUB(
	publish_key   : 'pub-c-80f9db95-6c63-4265-90c6-cc3ddc22dddf'
	subscribe_key : 'sub-c-28f51c78-fa8e-11e5-8679-02ee2ddab7fe'
	ssl: true
)

# update = ->
	# pub()
	# setTimeout(update, 500)
pubnub.subscribe(
	channel : 'speed',
	message : (msg, envelope, channelOrGroup, time, channel) ->
		document.getElementById('speed').innerText = (1 / msg).toFixed(1) + 'Hz'
)

pubnub.subscribe(
	channel : 'status',
	message : (msg, envelope, channelOrGroup, time, channel) ->
		[ t, event ] = msg
		if event is 'start'
			chart.xAxis[0].addPlotLine(
				value: t
				color: 'green'
				width: 2
			)
		if event is 'stop'
			chart.xAxis[0].addPlotLine(
				value: t
				color: 'red'
				width: 2
			)
)

stop = false

console.log("Subscribing..")
pubnub.subscribe(
	channel : 'gyroscope',
	message : (msg, envelope, channelOrGroup, time, channel) ->
		if not Array.isArray(msg)
			return

		if stop
			return

		[ x_series, y_series, z_series ] = chart.series
		[ t, x, y, z ] = msg

		# shift if the series is longer than 20
		shift = x_series.data.length > 100

		x_series.addPoint([t, x], true, shift)
		y_series.addPoint([t, y], true, shift)
		z_series.addPoint([t, z], true, shift)
	# connect: update
)

document.getElementById('stop').addEventListener('click', ->
	stop = not stop
)
