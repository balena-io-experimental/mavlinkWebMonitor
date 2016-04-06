console.log('test')
# Create the chart
chart = new Highcharts.Chart(
	chart:
		renderTo: 'container'
		defaultSeriesType: 'spline'
		animation: false
	title:
		text: 'Live gyroscope'
	xAxis:
		type: 'datetime'
		tickPixelInterval: 10
		maxZoom: 20 * 1000
	yAxis:
		minPadding: 0.2
		maxPadding: 0.2
	plotOptions:
		series:
			animation: false
	series: [
		{
			name: 'pitch'
			data: []
		}
		{
			name: 'yaw'
			data: []
		}
		{
			name: 'roll'
			data: []
		}
	]
)

pubnub = PUBNUB(
	publish_key   : 'pub-c-80f9db95-6c63-4265-90c6-cc3ddc22dddf'
	subscribe_key : 'sub-c-28f51c78-fa8e-11e5-8679-02ee2ddab7fe'
)

# update = ->
	# pub()
	# setTimeout(update, 500)
pubnub.subscribe(
	channel : 'speed',
	message : (msg, envelope, channelOrGroup, time, channel) ->
		document.getElementById('speed').innerText = (1 / msg).toFixed(1) + 'Hz'
)
 
console.log("Subscribing..")
pubnub.subscribe(
	channel : 'gyroscope',
	message : (msg, envelope, channelOrGroup, time, channel) ->
		if not Array.isArray(msg)
			return

		[ x_series, y_series, z_series ] = chart.series
		[ t, x, y, z ] = msg

		# shift if the series is longer than 20
		shift = x_series.data.length > 40

		x_series.addPoint([t, x], true, shift)
		y_series.addPoint([t, y], true, shift)
		z_series.addPoint([t, z], true, shift)
	# connect: update
)
 

document.getElementById('button').addEventListener('click', ->
	console.log('publishing')
	pubnub.publish(
		channel : 'gyroscope'
		message : 'kill'
	)
)

document.getElementById('slower').addEventListener('click', ->
	console.log('publishing')
	pubnub.publish(
		channel : 'gyroscope'
		message : 'slower'
	)
)

document.getElementById('faster').addEventListener('click', ->
	console.log('publishing')
	pubnub.publish(
		channel : 'gyroscope'
		message : 'faster'
	)
)
